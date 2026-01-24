#!/usr/bin/env python
# coding: utf-8

"""
Run SQL queries for homework01 Questions 3-6
"""

import pandas as pd
from sqlalchemy import create_engine

# Database connection parameters
DB_USER = 'postgres'
DB_PASS = 'postgres'
DB_HOST = 'localhost'
DB_PORT = 5433  # Host-mapped port
DB_NAME = 'ny_taxi'

def run_query(engine, question_num, description, query):
    """Execute a query and print results"""
    print("\n" + "=" * 80)
    print(f"Question {question_num}: {description}")
    print("=" * 80)
    print(f"\nSQL Query:")
    print("-" * 80)
    print(query)
    print("-" * 80)
    
    result = pd.read_sql(query, engine)
    print(f"\nResult:")
    print(result)
    print("\n")
    
    return result

def main():
    # Create database engine
    engine = create_engine(f'postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}')
    
    # Question 3: Count trips with distance <= 1 mile
    q3 = """
    SELECT COUNT(*) as trip_count
    FROM green_taxi_data
    WHERE lpep_pickup_datetime >= '2025-11-01'
      AND lpep_pickup_datetime < '2025-12-01'
      AND trip_distance <= 1;
    """
    run_query(engine, 3, "Counting short trips (distance <= 1 mile)", q3)
    
    # Question 4: Longest trip for each day
    q4 = """
    SELECT DATE(lpep_pickup_datetime) as pickup_date,
           MAX(trip_distance) as max_distance
    FROM green_taxi_data
    WHERE trip_distance < 100
    GROUP BY DATE(lpep_pickup_datetime)
    ORDER BY max_distance DESC
    LIMIT 1;
    """
    run_query(engine, 4, "Day with longest trip distance", q4)
    
    # Question 5: Pickup zone with largest total_amount on Nov 18
    q5 = """
    SELECT z."Zone",
           SUM(g.total_amount) as total_sum
    FROM green_taxi_data g
    JOIN zones z ON g."PULocationID" = z."LocationID"
    WHERE DATE(g.lpep_pickup_datetime) = '2025-11-18'
    GROUP BY z."Zone"
    ORDER BY total_sum DESC
    LIMIT 5;
    """
    run_query(engine, 5, "Pickup zone with largest total_amount on Nov 18", q5)
    
    # Question 6: Dropoff zone with largest tip for pickups in East Harlem North
    q6 = """
    SELECT do_zone."Zone" as dropoff_zone,
           MAX(g.tip_amount) as max_tip
    FROM green_taxi_data g
    JOIN zones pu_zone ON g."PULocationID" = pu_zone."LocationID"
    JOIN zones do_zone ON g."DOLocationID" = do_zone."LocationID"
    WHERE pu_zone."Zone" = 'East Harlem North'
      AND DATE(g.lpep_pickup_datetime) >= '2025-11-01'
      AND DATE(g.lpep_pickup_datetime) < '2025-12-01'
    GROUP BY do_zone."Zone"
    ORDER BY max_tip DESC
    LIMIT 5;
    """
    run_query(engine, 6, "Dropoff zone with largest tip from East Harlem North", q6)

if __name__ == '__main__':
    main()
