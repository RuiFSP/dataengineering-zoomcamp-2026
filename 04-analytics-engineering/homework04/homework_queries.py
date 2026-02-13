"""
Module 4 Homework: Analytics Engineering with dbt
Data Engineering Zoomcamp 2026

This script answers homework questions by querying BigQuery tables created by dbt models.
"""

from google.cloud import bigquery
from google.oauth2 import service_account
import os


def setup_bigquery_client():
    """Set up BigQuery client with service account credentials."""
    # Use relative path from homework04 directory
    key_path = os.path.join(
        os.path.dirname(__file__), 
        "..", 
        "gcp-infrastructure", 
        "terraform", 
        "keys", 
        "dbt-sa-key.json"
    )
    
    # Alternative: Use environment variable
    # key_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', key_path)
    
    if not os.path.exists(key_path):
        raise FileNotFoundError(
            f"Service account key not found at: {key_path}\n"
            "Please ensure the key file exists or set GOOGLE_APPLICATION_CREDENTIALS environment variable."
        )
    
    credentials = service_account.Credentials.from_service_account_file(key_path)
    return bigquery.Client(credentials=credentials, project="ny-taxi-dbt-zoomcamp", location="EU")


def question_1():
    """
    Question 1: dbt Lineage and Execution
    
    Given a dbt project with int_trips_unioned depending on stg_green_tripdata and stg_yellow_tripdata,
    if you run `dbt run --select int_trips_unioned`, what models will be built?
    
    Options:
    - stg_green_tripdata, stg_yellow_tripdata, and int_trips_unioned (upstream dependencies)
    - Any model with upstream and downstream dependencies to int_trips_unioned
    - int_trips_unioned only
    - int_trips_unioned, int_trips, and fct_trips (downstream dependencies)
    """
    print("=" * 80)
    print("QUESTION 1: dbt Lineage and Execution")
    print("=" * 80)
    print("\nGiven a dbt project with int_trips_unioned depending on stg_green_tripdata")
    print("and stg_yellow_tripdata, if you run `dbt run --select int_trips_unioned`,")
    print("what models will be built?")
    print("\nAnswer: int_trips_unioned only")
    print("\nExplanation:")
    print("- The `--select` flag without modifiers selects only the specified model")
    print("- To include upstream dependencies, you'd use `--select +int_trips_unioned`")
    print("- To include downstream dependencies, you'd use `--select int_trips_unioned+`")
    print("- To include both, you'd use `--select +int_trips_unioned+`")
    print()


def question_2():
    """
    Question 2: dbt Tests
    
    You've configured an accepted_values test for payment_type with values [1, 2, 3, 4, 5].
    A new value 6 now appears in the source data.
    What happens when you run `dbt test --select fct_trips`?
    
    Options:
    - dbt will skip the test because the model didn't change
    - dbt will fail the test, returning a non-zero exit code
    - dbt will pass the test with a warning about the new value
    - dbt will update the configuration to include the new value
    """
    print("=" * 80)
    print("QUESTION 2: dbt Tests")
    print("=" * 80)
    print("\nYou've configured an accepted_values test for payment_type with [1, 2, 3, 4, 5].")
    print("A new value 6 now appears in the source data.")
    print("What happens when you run `dbt test --select fct_trips`?")
    print("\nAnswer: dbt will fail the test, returning a non-zero exit code")
    print("\nExplanation:")
    print("- The accepted_values test checks that all values in the column are in the list")
    print("- If a value (6) appears that's not in the accepted list [1,2,3,4,5], the test fails")
    print("- dbt returns exit code 1, indicating test failure")
    print("- You can set severity: warn to make it pass with a warning instead of failing")
    print()


def question_3(client):
    """
    Question 3: Counting Records in fct_monthly_zone_revenue
    
    After running your dbt project, query the fct_monthly_zone_revenue model.
    What is the count of records?
    
    Options: 12,998, 14,120, 12,184, 15,421
    """
    print("=" * 80)
    print("QUESTION 3: Counting Records in fct_monthly_zone_revenue")
    print("=" * 80)
    
    query = """
    SELECT COUNT(*) as total_records
    FROM `ny-taxi-dbt-zoomcamp.dbt_prod_core.fct_monthly_zone_revenue`
    """
    
    result = client.query(query).to_dataframe()
    total_records = result['total_records'][0]
    
    print(f"\nQuery:")
    print(query)
    print(f"\nAnswer: {total_records:,} records")
    print()


def question_4(client):
    """
    Question 4: Best Performing Zone for Green Taxis (2020)
    
    Using fct_monthly_zone_revenue, find the pickup zone with the highest
    total revenue for Green taxi trips in 2020.
    
    Options: East Harlem North, Morningside Heights, East Harlem South, Washington Heights South
    """
    print("=" * 80)
    print("QUESTION 4: Best Performing Zone for Green Taxis (2020)")
    print("=" * 80)
    
    # Query only the zones listed in the homework options
    query = """
    SELECT 
        revenue_zone,
        SUM(revenue_monthly_total_amount) as total_revenue,
        SUM(total_monthly_trips) as total_trips
    FROM `ny-taxi-dbt-zoomcamp.dbt_prod_core.fct_monthly_zone_revenue`
    WHERE service_type = 'Green'
      AND EXTRACT(YEAR FROM revenue_month) = 2020
      AND revenue_zone IN ('East Harlem North', 'Morningside Heights', 
                           'East Harlem South', 'Washington Heights South')
    GROUP BY revenue_zone
    ORDER BY total_revenue DESC
    """
    
    result = client.query(query).to_dataframe()
    
    print(f"\nQuery:")
    print(query)
    print("\nGreen Taxi Zones by Revenue in 2020 (from given options):")
    print("-" * 80)
    print(f"{'Zone':<40} {'Total Revenue':>15} {'Total Trips':>12}")
    print("-" * 80)
    for _, row in result.iterrows():
        print(f"{row['revenue_zone']:<40} ${row['total_revenue']:>14,.2f} {row['total_trips']:>12,}")
    
    print(f"\nAnswer: {result.iloc[0]['revenue_zone']}")
    print()


def question_5(client):
    """
    Question 5: Green Taxi Trip Counts (October 2019)
    
    Using fct_monthly_zone_revenue, what is the total number of trips
    for Green taxis in October 2019?
    
    Options: 500,234, 350,891, 384,624, 421,509
    """
    print("=" * 80)
    print("QUESTION 5: Green Taxi Trip Counts (October 2019)")
    print("=" * 80)
    
    query = """
    SELECT 
        SUM(total_monthly_trips) as total_trips,
        COUNT(DISTINCT revenue_zone) as num_zones
    FROM `ny-taxi-dbt-zoomcamp.dbt_prod_core.fct_monthly_zone_revenue`
    WHERE service_type = 'Green'
      AND revenue_month = '2019-10-01'
    """
    
    result = client.query(query).to_dataframe()
    total_trips = result['total_trips'][0]
    num_zones = result['num_zones'][0]
    
    print(f"\nQuery:")
    print(query)
    print(f"\nGreen taxi trips in October 2019: {total_trips:,}")
    print(f"Number of pickup zones: {num_zones:,}")
    print(f"\nAnswer: {total_trips:,} trips")
    print()


def question_6(client):
    """
    Question 6: Build a Staging Model for FHV Data
    
    Create a staging model for FHV trip data for 2019.
    What is the count of records in stg_fhv_tripdata after filtering
    out records where dispatching_base_num IS NULL?
    
    Options: 42,084,899, 43,244,693, 22,998,722, 44,112,187
    """
    print("=" * 80)
    print("QUESTION 6: Build a Staging Model for FHV Data")
    print("=" * 80)
    
    # First check if the staging model exists
    query_check = """
    SELECT table_name
    FROM `ny-taxi-dbt-zoomcamp.dbt_prod_staging.INFORMATION_SCHEMA.TABLES`
    WHERE table_name = 'stg_fhv_tripdata'
    """
    
    try:
        check_result = client.query(query_check).to_dataframe()
        if len(check_result) == 0:
            print("\nstg_fhv_tripdata model not yet created.")
            print("\nSteps to complete:")
            print("1. Load FHV 2019 data into BigQuery (nytaxi.fhv_tripdata)")
            print("2. Create models/staging/stg_fhv_tripdata.sql")
            print("3. Run: dbt run --target prod --select stg_fhv_tripdata")
            print()
            return
        
        # If model exists, count records
        query = """
        SELECT COUNT(*) as total_records
        FROM `ny-taxi-dbt-zoomcamp.dbt_prod_staging.stg_fhv_tripdata`
        """
        
        result = client.query(query).to_dataframe()
        total_records = result['total_records'][0]
        
        print(f"\nQuery:")
        print(query)
        print(f"\nAnswer: {total_records:,} records")
        print()
        
    except Exception as e:
        print(f"\nError querying stg_fhv_tripdata: {e}")
        print("\nThis model needs to be created. See steps above.")
        print()


def main():
    """Run all homework questions."""
    print("\n" + "=" * 80)
    print("MODULE 4 HOMEWORK: Analytics Engineering with dbt")
    print("Data Engineering Zoomcamp 2026")
    print("=" * 80)
    print()
    
    # Set up BigQuery client
    client = setup_bigquery_client()
    
    # Run all questions
    question_1()
    question_2()
    question_3(client)
    question_4(client)
    question_5(client)
    question_6(client)
    
    print("=" * 80)
    print("HOMEWORK COMPLETE")
    print("=" * 80)
    print()


if __name__ == "__main__":
    main()
