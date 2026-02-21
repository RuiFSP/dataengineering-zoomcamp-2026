"""@bruin

name: ingestion.trips
connection: duckdb-default

materialization:
  type: table
  strategy: append
image: python:3.11

columns:
  - name: pickup_datetime
    type: timestamp
    description: When the meter was engaged
  - name: dropoff_datetime
    type: timestamp
    description: When the meter was disengaged

@bruin"""

import os
import json
from io import BytesIO
from datetime import datetime

import pandas as pd
import requests
import pyarrow.parquet as pq
from dateutil.parser import parse as parse_dt
from dateutil.relativedelta import relativedelta


def _iterate_months(start_dt: datetime, end_dt: datetime):
    curr = datetime(start_dt.year, start_dt.month, 1)
    end_month = datetime(end_dt.year, end_dt.month, 1)
    while curr <= end_month:
        yield curr.year, curr.month
        curr += relativedelta(months=1)


def materialize():
    """Download parquet files from TLC public endpoint and return a concatenated DataFrame.

    Expects the following environment variables provided by Bruin:
    - BRUIN_START_DATE (ISO date string)
    - BRUIN_END_DATE (ISO date string)
    - BRUIN_VARS (JSON string with key `taxi_types`, e.g. {"taxi_types": ["yellow"]})
    """

    # Parse dates
    start_raw = os.environ.get("BRUIN_START_DATE")
    end_raw = os.environ.get("BRUIN_END_DATE")
    if not start_raw or not end_raw:
        raise RuntimeError("BRUIN_START_DATE and BRUIN_END_DATE must be set")

    start_dt = parse_dt(start_raw)
    end_dt = parse_dt(end_raw)

    # Parse taxi types from BRUIN_VARS (fall back to BRUIN_VAR_TAXI_TYPES)
    taxi_types = ["yellow"]
    vars_raw = os.environ.get("BRUIN_VARS") or os.environ.get("BRUIN_VAR_TAXI_TYPES")
    if vars_raw:
        try:
            if vars_raw.strip().startswith("{"):
                parsed = json.loads(vars_raw)
                taxi_types = parsed.get("taxi_types", taxi_types)
            else:
                # If a simple JSON array string was provided
                taxi_types = json.loads(vars_raw)
        except Exception:
            # Keep default on parse failure
            print("Warning: failed to parse taxi types from BRUIN_VARS; using default ['yellow']")

    base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data/"
    frames = []

    for year, month in _iterate_months(start_dt, end_dt):
        month_s = f"{month:02d}"
        for taxi in taxi_types:
            fname = f"{taxi}_tripdata_{year}-{month_s}.parquet"
            url = base_url + fname
            print(f"Fetching {url}")
            try:
                resp = requests.get(url, timeout=30)
                if resp.status_code == 200:
                    table = pq.read_table(BytesIO(resp.content))
                    df = table.to_pandas()
                    # Normalize common pickup/dropoff and location column names across taxi types
                    # timestamp names: tpep_pickup_datetime / lpep_pickup_datetime -> pickup_datetime
                    #                 tpep_dropoff_datetime / lpep_dropoff_datetime -> dropoff_datetime
                    # location ids: pu_location_id -> pickup_location_id, do_location_id -> dropoff_location_id
                    rename_map = {}
                    if "tpep_pickup_datetime" in df.columns:
                        rename_map["tpep_pickup_datetime"] = "pickup_datetime"
                    if "lpep_pickup_datetime" in df.columns:
                        rename_map["lpep_pickup_datetime"] = "pickup_datetime"
                    if "tpep_dropoff_datetime" in df.columns:
                        rename_map["tpep_dropoff_datetime"] = "dropoff_datetime"
                    if "lpep_dropoff_datetime" in df.columns:
                        rename_map["lpep_dropoff_datetime"] = "dropoff_datetime"
                    if "pu_location_id" in df.columns:
                        rename_map["pu_location_id"] = "pickup_location_id"
                    if "do_location_id" in df.columns:
                        rename_map["do_location_id"] = "dropoff_location_id"

                    if rename_map:
                        df = df.rename(columns=rename_map)

                    # Coerce timestamp columns to datetime if present
                    if "pickup_datetime" in df.columns:
                        df["pickup_datetime"] = pd.to_datetime(df["pickup_datetime"], errors="coerce")
                    if "dropoff_datetime" in df.columns:
                        df["dropoff_datetime"] = pd.to_datetime(df["dropoff_datetime"], errors="coerce")

                    # Drop legacy/original source columns if they still exist
                    legacy_cols = [
                        "tpep_pickup_datetime",
                        "lpep_pickup_datetime",
                        "tpep_dropoff_datetime",
                        "lpep_dropoff_datetime",
                        "pu_location_id",
                        "do_location_id",
                    ]
                    for c in legacy_cols:
                        if c in df.columns:
                            df.drop(columns=[c], inplace=True)

                    df["taxi_type"] = taxi
                    frames.append(df)
                else:
                    print(f"Warning: {url} returned status {resp.status_code}")
            except Exception as e:
                print(f"Warning: error fetching {url}: {e}")

    if frames:
        final_dataframe = pd.concat(frames, ignore_index=True)
    else:
        final_dataframe = pd.DataFrame()

    return final_dataframe
