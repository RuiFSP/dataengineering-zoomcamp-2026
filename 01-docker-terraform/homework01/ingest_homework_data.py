#!/usr/bin/env python
# coding: utf-8

"""
Ingest NYC Green Taxi data (parquet) and zone lookup (CSV) into PostgreSQL
for homework01 queries.
"""

import pandas as pd
from sqlalchemy import create_engine
from time import time

# Database connection parameters
DB_USER = 'postgres'
DB_PASS = 'postgres'
DB_HOST = 'localhost'
DB_PORT = 5433  # Host-mapped port from docker-compose
DB_NAME = 'ny_taxi'

def main():
    # Create database engine
    engine = create_engine(f'postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}')
    
    print("=" * 60)
    print("Loading Green Taxi data from parquet file...")
    print("=" * 60)
    
    # Read parquet file
    t_start = time()
    df_green = pd.read_parquet('green_tripdata_2025-11.parquet')
    t_end = time()
    
    print(f"✓ Loaded {len(df_green):,} rows in {t_end - t_start:.2f} seconds")
    print(f"\nColumns: {list(df_green.columns)}")
    print(f"\nData types:\n{df_green.dtypes}")
    print(f"\nFirst few rows:\n{df_green.head()}")
    
    # Insert green taxi data
    print("\n" + "=" * 60)
    print("Inserting into green_taxi_data table...")
    print("=" * 60)
    
    t_start = time()
    df_green.to_sql(name='green_taxi_data', con=engine, if_exists='replace', index=False)
    t_end = time()
    
    print(f"✓ Inserted {len(df_green):,} rows in {t_end - t_start:.2f} seconds")
    
    # Load zone lookup data
    print("\n" + "=" * 60)
    print("Loading taxi zone lookup from CSV...")
    print("=" * 60)
    
    df_zones = pd.read_csv('taxi_zone_lookup.csv')
    print(f"✓ Loaded {len(df_zones):,} zones")
    print(f"\nZone data:\n{df_zones.head()}")
    
    # Insert zone data
    print("\n" + "=" * 60)
    print("Inserting into zones table...")
    print("=" * 60)
    
    df_zones.to_sql(name='zones', con=engine, if_exists='replace', index=False)
    print(f"✓ Inserted {len(df_zones):,} zones")
    
    print("\n" + "=" * 60)
    print("✓ Data ingestion complete!")
    print("=" * 60)
    print("\nYou can now connect to pgAdmin at http://localhost:8080")
    print("  Email: pgadmin@pgadmin.com")
    print("  Password: pgadmin")
    print("\nServer connection in pgAdmin:")
    print("  Host: db (or postgres)")
    print("  Port: 5432")
    print("  Username: postgres")
    print("  Password: postgres")
    print("  Database: ny_taxi")

if __name__ == '__main__':
    main()
