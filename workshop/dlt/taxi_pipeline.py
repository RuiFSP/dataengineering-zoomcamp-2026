"""Pipeline to ingest NYC taxi trips from the zoomcamp custom API."""

from collections.abc import Iterator
from typing import Any

import dlt
import requests

BASE_URL = "https://us-central1-dlthub-analytics.cloudfunctions.net/data_engineering_zoomcamp_api"


def fetch_taxi_pages() -> Iterator[list[dict[str, Any]]]:
    """Yield API pages until an empty page is returned."""
    page = 1
    while True:
        response = requests.get(BASE_URL, params={"page": page}, timeout=60)
        response.raise_for_status()
        rows = response.json()

        if not rows:
            break

        yield rows
        page += 1


@dlt.resource(name="taxi_trips", write_disposition="replace")
def taxi_trips() -> Iterator[list[dict[str, Any]]]:
    """NYC taxi trips resource."""
    yield from fetch_taxi_pages()


if __name__ == "__main__":
    pipeline = dlt.pipeline(
        pipeline_name="taxi_pipeline",
        destination="duckdb",
        dataset_name="taxi_data",
        progress="log",
    )

    load_info = pipeline.run(taxi_trips())
    print(load_info)
