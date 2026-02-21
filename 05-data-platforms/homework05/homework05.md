# Module 5 Homework: Data Platforms with Bruin

In this homework, we'll use Bruin to build a complete data pipeline, from ingestion to reporting.

## 📋 Homework Summary - Answers

| Question | Answer |
|----------|--------|
| Question 1 | `.bruin.yml` and `pipeline/` with `pipeline.yml` and `assets/` |
| Question 2 | `time_interval` - incremental based on a time column |
| Question 3 | `bruin run --var 'taxi_types=["yellow"]'` |
| Question 4 | `bruin run --select ingestion.trips+` |
| Question 5 | `name: not_null` |
| Question 6 | `bruin lineage` |
| Question 7 | `--full-refresh` |

---

### Question 1. Bruin Pipeline Structure

In a Bruin project, what are the required files/directories?

- `bruin.yml` and `assets/`
- `.bruin.yml` and `pipeline.yml` (assets can be anywhere)
- ✅ `.bruin.yml` and `pipeline/` with `pipeline.yml` and `assets/`
- `pipeline.yml` and `assets/` only

**Answer:** `.bruin.yml` and `pipeline/` with `pipeline.yml` and `assets/`

**Explanation:** Bruin expects a `.bruin.yml` config file and a `pipeline/` directory containing `pipeline.yml` and asset files. This structure is required for proper pipeline execution.

---

### Question 2. Materialization Strategies

You're building a pipeline that processes NYC taxi data organized by month based on `pickup_datetime`. Which incremental strategy is best for processing a specific interval period by deleting and inserting data for that time period?

- `append` - always add new rows
- `replace` - truncate and rebuild entirely
- ✅ `time_interval` - incremental based on a time column
- `view` - create a virtual table only

**Answer:** `time_interval` - incremental based on a time column  
[Materialization docs](https://getbruin.com/docs/bruin/assets/materialization)

**Explanation:** The `time_interval` strategy processes data for a specific interval, deleting and inserting for that period. Ideal for monthly taxi data based on `pickup_datetime`.

---

### Question 3. Pipeline Variables

You have the following variable defined in `pipeline.yml`:

```yaml
variables:
  taxi_types:
    type: array
    items:
      type: string
    default: ["yellow", "green"]
```

How do you override this when running the pipeline to only process yellow taxis?

- `bruin run --taxi-types yellow`
- `bruin run --var taxi_types=yellow`
- ✅ `bruin run --var 'taxi_types=["yellow"]'`
- `bruin run --set taxi_types=["yellow"]`

**Answer:** `bruin run --var 'taxi_types=["yellow"]'`  
[Pipeline variables docs](https://getbruin.com/docs/bruin/getting-started/pipeline-variables)

**Explanation:** To override the default variable, use `--var` with a JSON array. This ensures only yellow taxis are processed.

---

### Question 4. Running with Dependencies

You've modified the `ingestion/trips.py` asset and want to run it plus all downstream assets. Which command should you use?

- `bruin run ingestion.trips --all`
- `bruin run ingestion/trips.py --downstream`
- `bruin run pipeline/trips.py --recursive`
- ✅ `bruin run --select ingestion.trips+`

**Answer:** `bruin run --select ingestion.trips+`

**Explanation:** The `+` selects the asset and all downstream dependencies, running everything affected by the change.

---

### Question 5. Quality Checks

You want to ensure the `pickup_datetime` column in your trips table never has NULL values. Which quality check should you add to your asset definition?

- `name: unique`
- ✅ `name: not_null`
- `name: positive`
- `name: accepted_values, value: [not_null]`

**Answer:** `name: not_null`  
[Quality checks docs](https://getbruin.com/docs/bruin/quality/overview)

**Explanation:** The `not_null` quality check ensures the column never contains NULL values.

---

### Question 6. Lineage and Dependencies

After building your pipeline, you want to visualize the dependency graph between assets. Which Bruin command should you use?

- `bruin graph`
- `bruin dependencies`
- ✅ `bruin lineage`
- `bruin show`

**Answer:** bruin lineage  
[Lineage command docs](https://getbruin.com/docs/bruin/commands/lineage)

**Explanation:** `bruin lineage` visualizes the dependency graph between assets in your pipeline.

---

### Question 7. First-Time Run

You're running a Bruin pipeline for the first time on a new DuckDB database. What flag should you use to ensure tables are created from scratch?

- `--create`
- `--init`
- ✅ `--full-refresh`
- `--truncate`

**Answer:** `--full-refresh`

**Explanation:** Use `--full-refresh` to ensure tables are created from scratch on a new DuckDB database.

---