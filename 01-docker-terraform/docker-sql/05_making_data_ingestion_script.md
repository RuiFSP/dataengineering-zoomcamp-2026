# Ingestion Script (CLI)

We operationalized the notebook ingestion into a reusable CLI script ready for Dockerization.

> 📚 **Learning Path**: This shows running a Python script from your WSL/host machine. Later exercises will containerize this (06) and eventually orchestrate multiple services with Docker Compose.

## Script: pipeline/ingest_data.py

### What it does
- Downloads NYC Yellow Taxi CSV (gzip) for a given year/month.
- Uses explicit `dtype` and `parse_dates` to enforce schema.
- Streams in chunks with `tqdm` progress.
- Creates table on first chunk, then appends the rest.

### CLI options
- `--pg-user`, `--pg-pass`, `--pg-host`, `--pg-port`, `--pg-db`: DB connection (defaults: `root/root/host.docker.internal/5432/ny_taxi`).
- `--year`, `--month`: dataset selection (defaults: 2021/1).
- `--target-table`: destination table (default: `yellow_taxi_data`).
- `--chunksize`: rows per chunk (default: 100000).

### Run locally (WSL example)
```bash
uv run python ingest_data.py \
	--pg-host host.docker.internal \
	--pg-user root --pg-pass root --pg-db ny_taxi \
	--year 2021 --month 01 \
	--target-table yellow_taxi_data \
	--chunksize 100000
```

### Key implementation points
- **Chunked ingest** to avoid OOM: `pd.read_csv(..., iterator=True, chunksize=...)`.
- **First-chunk schema create**: `df_chunk.head(0).to_sql(if_exists='replace')`, then append.
- **Explicit types**: nullable `Int64`, `string`, parsed timestamps.
- **Progress**: `tqdm` around the iterator.
- **WSL networking**: `host.docker.internal` for connecting to Docker Desktop PostgreSQL.
- **CLI with click**: argument parsing, defaults, and help are handled by `click`, keeping the script single-file and friendly for `docker run` overrides.

### Ready for Docker
- Entrypoint can be `python ingest_data.py ...` with args passed at `docker run` time.
- Keep `pyproject.toml/uv.lock` in build context to install deps via `uv sync`.

---

## Why This Approach (Host → Container)?

**This exercise demonstrates host-to-container communication:**
- Your Python script runs on WSL/host
- Connects to PostgreSQL container via `host.docker.internal`
- Shows the complexity of WSL networking

**Next steps in the learning path:**
- **06_dockerizing_ingestion.md**: Run ingestion as container on same network (simpler!)
- **07_pgadmin.md**: Add pgAdmin for visual database management
- **Docker Compose** (future): Start all services (PostgreSQL + pgAdmin + ingestion) together

**When to use each approach:**

| Approach | Use Case | Complexity |
|----------|----------|------------|
| **Script on host** (this exercise) | Quick development/testing | Medium (WSL networking) |
| **Containerized script** (06) | Production pipelines | Low (same network) |
| **Docker Compose** (next) | Multi-service applications | Lowest (automated) |
