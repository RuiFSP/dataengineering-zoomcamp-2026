"""Module 6 Homework solver for Data Engineering Zoomcamp 2026.

Computes answers for Spark batch-processing homework questions using local files.
"""

from __future__ import annotations

from pathlib import Path
from urllib.parse import urlparse
import shutil

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


Q2_OPTIONS_MB = [6.0, 25.0, 75.0, 100.0]
Q3_OPTIONS = [62610, 102340, 162604, 225768]
Q4_OPTIONS_HOURS = [22.7, 58.2, 90.6, 134.5]
Q6_OPTIONS = [
    "Governor's Island/Ellis Island/Liberty Island",
    "Arden Heights",
    "Rikers Island",
    "Jamaica Bay",
]


def closest_option(value: float, options: list[float]) -> float:
    """Return the closest option value; in a tie pick the smaller one."""
    return min(options, key=lambda x: (abs(x - value), x))


def get_ui_port(ui_url: str | None) -> int | None:
    """Extract Spark UI port from URL."""
    if not ui_url:
        return None
    parsed = urlparse(ui_url)
    return parsed.port


def parquet_part_files(output_dir: Path) -> list[Path]:
    """Return parquet part files only (exclude metadata files)."""
    return sorted(p for p in output_dir.rglob("*.parquet") if p.is_file())


def main() -> None:
    base_dir = Path(__file__).resolve().parent
    input_parquet = base_dir / "yellow_tripdata_2025-11.parquet"
    input_zones_csv = base_dir / "taxi_zone_lookup.csv"
    q2_output_dir = base_dir / "yellow_2025_11_repartitioned_4"

    if not input_parquet.exists():
        raise FileNotFoundError(f"Missing input parquet file: {input_parquet}")
    if not input_zones_csv.exists():
        raise FileNotFoundError(f"Missing zone lookup CSV file: {input_zones_csv}")

    spark = (
        SparkSession.builder.master("local[*]")
        .appName("de-zoomcamp-2026-homework06")
        .getOrCreate()
    )

    print("=" * 80)
    print("MODULE 6 HOMEWORK: Batch Processing with Spark")
    print("=" * 80)

    # Q1
    spark_version = spark.version
    print("\nQ1 - Spark Version")
    print(f"Spark version: {spark_version}")

    # Read main dataset once and reuse.
    df = spark.read.parquet(str(input_parquet))

    # Q2
    print("\nQ2 - Average parquet part-file size after repartition(4)")
    if q2_output_dir.exists():
        shutil.rmtree(q2_output_dir)
    df.repartition(4).write.mode("overwrite").parquet(str(q2_output_dir))

    part_files = parquet_part_files(q2_output_dir)
    if not part_files:
        raise RuntimeError("No parquet part files found in Q2 output directory")

    file_sizes_mb = [p.stat().st_size / (1024 * 1024) for p in part_files]
    avg_size_mb = sum(file_sizes_mb) / len(file_sizes_mb)
    q2_closest = closest_option(avg_size_mb, Q2_OPTIONS_MB)

    print(f"Parquet part files created: {len(part_files)}")
    print("Part file sizes (MB):", ", ".join(f"{size:.2f}" for size in file_sizes_mb))
    print(f"Average size (MB): {avg_size_mb:.2f}")
    print(f"Closest option: {q2_closest:.0f}MB")

    # Q3
    print("\nQ3 - Trips that started on 2025-11-15")
    trips_nov_15 = (
        df.filter(F.to_date(F.col("tpep_pickup_datetime")) == F.lit("2025-11-15")).count()
    )
    q3_closest = int(closest_option(float(trips_nov_15), [float(x) for x in Q3_OPTIONS]))

    print(f"Exact trip count: {trips_nov_15:,}")
    print(f"Closest option: {q3_closest:,}")

    # Q4
    print("\nQ4 - Longest trip in hours")
    duration_hours_col = (
        (
            F.unix_timestamp(F.col("tpep_dropoff_datetime"))
            - F.unix_timestamp(F.col("tpep_pickup_datetime"))
        )
        / F.lit(3600.0)
    )
    max_duration_hours = (
        df.select(duration_hours_col.alias("duration_hours"))
        .agg(F.max("duration_hours").alias("max_duration_hours"))
        .collect()[0]["max_duration_hours"]
    )
    q4_closest = closest_option(float(max_duration_hours), Q4_OPTIONS_HOURS)

    print(f"Max duration (hours): {max_duration_hours:.2f}")
    print(f"Closest option: {q4_closest:.1f}")

    # Q5
    print("\nQ5 - Spark UI port")
    ui_url = spark.sparkContext.uiWebUrl
    ui_port = get_ui_port(ui_url)
    q5_default_port = 4040
    print(f"Spark UI URL: {ui_url}")
    print(f"Spark UI port: {ui_port}")
    print(f"Default Spark UI port (homework answer): {q5_default_port}")

    # Q6
    print("\nQ6 - Least frequent pickup location zone")
    zones_df = (
        spark.read.option("header", True)
        .option("inferSchema", True)
        .csv(str(input_zones_csv))
        .withColumn("LocationID", F.col("LocationID").cast("int"))
    )

    zone_counts_df = (
        df.groupBy("PULocationID")
        .count()
        .join(zones_df, df.PULocationID == zones_df.LocationID, "left")
        .filter(F.col("Zone").isNotNull())
        .select("Zone", "count")
    )

    min_count = zone_counts_df.agg(F.min("count").alias("min_count")).collect()[0]["min_count"]
    least_zones = [
        row["Zone"]
        for row in zone_counts_df.filter(F.col("count") == F.lit(min_count))
        .select("Zone")
        .distinct()
        .orderBy("Zone")
        .collect()
    ]

    selected_option = next((zone for zone in least_zones if zone in Q6_OPTIONS), least_zones[0])

    print(f"Minimum pickup count: {min_count}")
    print("Least frequent zone(s):", "; ".join(least_zones))
    print(f"Selected valid option: {selected_option}")

    print("\n" + "=" * 80)
    print("FINAL ANSWERS (with closest-option mapping where needed)")
    print("=" * 80)
    print(f"Q1: Spark version = {spark_version}")
    print(f"Q2: Average parquet size = {avg_size_mb:.2f} MB -> {q2_closest:.0f}MB")
    print(f"Q3: Trips on 2025-11-15 = {trips_nov_15:,} -> {q3_closest:,}")
    print(f"Q4: Longest trip = {max_duration_hours:.2f} hours -> {q4_closest:.1f}")
    print(
        f"Q5: Spark UI default port = {q5_default_port} "
        f"(observed session port: {ui_port})"
    )
    print(f"Q6: Least frequent pickup zone = {selected_option}")

    spark.stop()


if __name__ == "__main__":
    main()
