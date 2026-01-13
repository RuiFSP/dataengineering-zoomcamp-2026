import sys

# when we are executing this file directly, we can see the arguments passed to it
# for example uv run 01-docker-terraform/docker-sql/pipeline/pipeline.py 12
print('arguments:', sys.argv)

# the first argument is always the file name
# the second argument is the first argument passed to the script
# arguments: ['01-docker-terraform/docker-sql/pipeline/pipeline.py', '12']

# so in this case, sys.argv[1] will be '12'
print('\nfirst argument:', sys.argv[1])

month = int(sys.argv[1])
print(f"\nRunning pipeline for month {month}")


# lets use pandas
import pandas as pd

df = pd.DataFrame({
    'month': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    'num_passengers': [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120]
})

print('\nDataframe:')
print(df.head())

# filter the dataframe for the given month
df_month = df[df['month'] == month]
print(f'\nDataframe for month {month}:')
print(df_month)


# saving to parquet file inside pipeline folder
df.to_parquet(f"01-docker-terraform/docker-sql/pipeline/output_{month}.parquet")