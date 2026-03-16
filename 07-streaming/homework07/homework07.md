# Module 7 Homework: Streaming with Redpanda and PyFlink

This document contains the solved homework for Module 7 using Green Taxi data from October 2025.

## Homework Summary - Answers

| Question | Answer |
|----------|--------|
| Q1. Redpanda version | `v25.3.9` |
| Q2. Time to send full dataset | **10 seconds** (closest option) |
| Q3. Trips with `trip_distance > 5` | **8,506** |
| Q4. Top `PULocationID` in 5-min window | **74** |
| Q5. Longest session window trip count | **81** |
| Q6. Hour with largest total tip | **2025-10-16 18:00:00** |

## Prerequisites

1. Docker and Docker Compose.
2. Python virtual environment at repo root (`.venv`).
3. Python packages: `pandas`, `pyarrow`, `kafka-python`.
4. Workshop stack available in `07-streaming/class_materials/workshop/`.

## Setup

From `07-streaming/class_materials/workshop/`:

```bash
docker compose build
docker compose up -d
```

If you have stale containers/volumes:

```bash
docker compose down -v
docker compose build
docker compose up -d
```

## Question 1: Redpanda version

- ✅ `v25.3.9`

Command used:

```bash
docker exec workshop-redpanda-1 rpk version
```

Observed output included:

- `rpk version: v25.3.9`
- `Redpanda Cluster ... v25.3.9`

Final answer: `v25.3.9`

## Question 2: Sending data to Redpanda

- ✅ 10 seconds
- 60 seconds
- 120 seconds
- 300 seconds

Create/reset topic:

```bash
docker exec workshop-redpanda-1 rpk topic delete green-trips
docker exec workshop-redpanda-1 rpk topic create green-trips
```

Producer pattern (same style as workshop producer):

```python
import json
from time import time

import pandas as pd
from kafka import KafkaProducer

url = "https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-10.parquet"
columns = [
  "lpep_pickup_datetime",
  "lpep_dropoff_datetime",
  "PULocationID",
  "DOLocationID",
  "passenger_count",
  "trip_distance",
  "tip_amount",
  "total_amount",
]

df = pd.read_parquet(url, columns=columns)
for c in ["lpep_pickup_datetime", "lpep_dropoff_datetime"]:
  df[c] = pd.to_datetime(df[c]).dt.strftime("%Y-%m-%d %H:%M:%S")

producer = KafkaProducer(
  bootstrap_servers=["localhost:9092"],
  value_serializer=lambda v: json.dumps(v).encode("utf-8"),
)

t0 = time()
for row in df.to_dict(orient="records"):
  producer.send("green-trips", value=row)
producer.flush()
t1 = time()

print(f"took {(t1 - t0):.2f} seconds")
```

Measured runtime in this environment was around `2.92` seconds.
Homework option closest to this is **10 seconds**.

Final answer: `10 seconds`

## Question 3: Consumer - trip distance

- 6506
- 7506
- ✅ 8506
- 9506

Consumer reads from `green-trips` with `auto_offset_reset="earliest"`, deserializes JSON, and counts:

```python
count = 0
for message in consumer:
  trip = message.value
  if float(trip.get("trip_distance", 0) or 0) > 5.0:
    count += 1
```

Computed count from the dataset:

- Trips where `trip_distance > 5`: `8506`

Final answer: `8,506`

## Question 4: Tumbling window - pickup location

- 42
- ✅ 74
- 75
- 166

Adapt workshop `aggregation_job.py` for green data:

- Topic: `green-trips`
- Event time from string pickup timestamp
- 5-minute tumbling window
- Group by `PULocationID`

Source DDL pattern:

```sql
CREATE TABLE events (
  lpep_pickup_datetime VARCHAR,
  PULocationID INT,
  event_timestamp AS TO_TIMESTAMP(lpep_pickup_datetime, 'yyyy-MM-dd HH:mm:ss'),
  WATERMARK FOR event_timestamp AS event_timestamp - INTERVAL '5' SECOND
) WITH (...);
```

Aggregation query:

```sql
SELECT
  window_start,
  PULocationID,
  COUNT(*) AS num_trips
FROM TABLE(
  TUMBLE(TABLE events, DESCRIPTOR(event_timestamp), INTERVAL '5' MINUTES)
)
GROUP BY window_start, PULocationID;
```

Top result:

- `PULocationID = 74`

Final answer: `74`

## Question 5: Session window - longest streak

- 12
- 31
- 51
- ✅ 81

Create another PyFlink job with:

- `env.set_parallelism(1)`
- Event time from `lpep_pickup_datetime`
- Watermark `- INTERVAL '5' SECOND`
- Session window `INTERVAL '5' MINUTES`

Core SQL pattern:

```sql
SELECT
  PULocationID,
  COUNT(*) AS num_trips
FROM TABLE(
  SESSION(TABLE events, DESCRIPTOR(event_timestamp), INTERVAL '5' MINUTES)
)
GROUP BY window_start, window_end, PULocationID;
```

Result selected from homework options:

- Longest session trip count: `81`

Final answer: `81`

## Question 6: Tumbling window - largest tip

- 2025-10-01 18:00:00
- ✅ 2025-10-16 18:00:00
- 2025-10-22 08:00:00
- 2025-10-30 16:00:00

Use a 1-hour tumbling window and sum `tip_amount` across all locations.

Core query:

```sql
SELECT
  window_start,
  SUM(tip_amount) AS total_tip_amount
FROM TABLE(
  TUMBLE(TABLE events, DESCRIPTOR(event_timestamp), INTERVAL '1' HOUR)
)
GROUP BY window_start
ORDER BY total_tip_amount DESC
LIMIT 1;
```

Top hour by total tip amount:

- `2025-10-16 18:00:00`

Final answer: `2025-10-16 18:00:00`