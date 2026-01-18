Now we want to do real data engineering. Let's use a Postgres database for that.

You can run a containerized version of Postgres that doesn't require any installation steps. You only need to provide a few environment variables to it as well as a volume for storing data.

lets first build a docker image using a docker file. Create a file named `Dockerfile` with the following content:

```Dockerfile
# the base image
FROM python:3.13.11-slim

RUN pip install pandas pyarrow

WORKDIR /code
COPY pipeline.py .
```

This Dockerfile uses the official Python slim image as a base, installs the necessary Python packages, sets the working directory to `/code`, and copies the `pipeline.py` file into the container.

to build the image run the following command in the terminal:

```bash
docker build -t test:pandas .
```

This command builds the Docker image and tags it as `test:pandas`.
where test is the name of the image and pandas is the tag.

now lets run our image:

```bash
docker run -it --rm --entrypoint=bash test:pandas
```

This command runs the Docker image in an interactive terminal mode.
-it stands for interactive terminal
--rm stands for remove the container after it exits
--entrypoint=bash sets the entrypoint to bash so you can interact with the container's shell.
test:pandas is the name of the image we want to run.

but we don't want to run the image and then execute the command inside the container. We want to run the command directly when we start the container.

we can add to teh docker image 
ENTRYPOINT [ "python", "pipeline.py" ]

to the dockerfile so it looks like this:

```Dockerfile
# the base image
FROM python:3.13.11-slim

RUN pip install pandas pyarrow

WORKDIR /code
COPY pipeline.py .

ENTRYPOINT [ "python", "pipeline.py" ]
```

Now when we run the container it will execute the pipeline.py script directly.
Now we can run the container and pass the month argument directly:

```bash
docker run -it --rm test:pandas 12
```

but we want to use also uv to run the containerized pipeline.
we need to change the Docker file to:

```Dockerfile
# the base image
FROM python:3.13.11-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

WORKDIR /code
ENV PATH="/code/.venv/bin:$PATH"

COPY pyproject.toml .python-version uv.lock ./
RUN uv sync --locked

COPY pipeline.py .

ENTRYPOINT [ "python", "pipeline.py" ]
```

Note: This Dockerfile assumes you're building from the project root with the `-f` flag, so the `COPY pipeline.py .` will correctly copy from `01-docker-terraform/docker-sql/pipeline/pipeline.py` due to the build context.

we use `ENV` to set the PATH to include the `.venv/bin` folder where uv creates the virtual environment.

### Build Context Issue

I made my setup more complex because the `uv.lock` and other dependency files are in the project root, but the Dockerfile is in a subdirectory (`01-docker-terraform/docker-sql/pipeline/`).

**Solution:** Build from the project root directory using the `-f` flag to specify the Dockerfile path.
### Building the Image

Now we can build the image from the project root:

```bash
docker build -t test:pandas -f 01-docker-terraform/docker-sql/pipeline/Dockerfile .
```

**Flags explained:**
- `-t test:pandas`: Tags the image with name `test` and tag `pandas`
- `-f`: Specifies the path to the Dockerfile (useful when Dockerfile is in a subdirectory)
- `.`: The build context (current directory - the project root where `pyproject.toml`, `uv.lock`, and `.python-version` are located)

**Important:** Run this command from the project root directory where your `pyproject.toml` and `uv.lock` files are located.

### Running the Container

After building the image, you can run the container:

```bash
docker run -it --rm test:pandas 12
```

**Flags explained:**
- `-it`: Interactive terminal mode (allows you to see output and interact with the container)
- `--rm`: Automatically removes the container when it exits (keeps your system clean)
- `test:pandas`: The image name and tag to run
- `12`: Arguments passed to the `pipeline.py` script (in this case, the month)

### Why Use UV in Docker?

- **Reproducibility**: `uv.lock` ensures the exact same dependencies are installed every time
- **Performance**: UV is faster than pip, making Docker builds quicker
- **Virtual Environment**: UV creates an isolated `.venv` directory with all dependencies
- **Project Portability**: The Docker image contains your exact project environment

## Running PostgreSQL in a Container
Now lets run a Postgress image, instead of installling in my computer. we are going to use a docker image of postgress

```bash
docker run -it --rm \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  postgres:18
```
# explanation of the command:
- `docker run -it --rm`: Run a Docker container in interactive mode and remove it after it exits
- `-e POSTGRES_USER="root"`: Set the Postgres username to "root"
- `-e POSTGRES_PASSWORD="root"`: Set the Postgres password to "root"
- `-e POSTGRES_DB="ny_taxi"`: Set the default database name to "ny_taxi"
- `-v ny_taxi_postgres_data:/var/lib/postgresql`: Create a Docker volume named `ny_taxi_postgres_data` to persist Postgres data 
- `-p 5432:5432`: Map port 5432 of the container to port 5432 on the host machine
- `postgres:18`: Use the official Postgres image with tag 18

This command will start a Postgres database server in a Docker container. You can connect to it using any Postgres client with the provided credentials. The data will be persisted in the Docker volume even if the container is removed.

The tags mean:
- `-e`: environment variable
- `-v`: volume
- `-p`: port mapping

Once the container is running, you can connect to the Postgres database  lets connect with teh database using cli tool called `pgcli`

ofr thsiw e need to install it first
```python
uv add --dev pgcli
```
we are adding --dev because we only need it for development purposes. so wehn we are building the docker image for production we won't include it, becaue thare are not part of the main dependencies of the project.

```DOCKERFILE
RUN uv sync --locked
```

Now to connect to the database we need to get inside the container. we can do that using the following command:

```bash
uv run pgcli -h localhost -p 5432 -u root -d ny_taxi
```
This command uses `uv run` to execute `pgcli` with the following parameters:
- `-h localhost`: Hostname of the Postgres server (localhost since it's running on the same machine)
- `-p 5432`: Port number of the Postgres server
- `-u root`: Username to connect to the database
- `-d ny_taxi`: Database name to connect to

This will open an interactive terminal where you can run SQL commands against the `ny_taxi` database.

### Important: Environment-Specific Setup

The approach for running PostgreSQL differs depending on your development environment:

#### GitHub Codespaces / Cloud Environments
In GitHub Codespaces, the PostgreSQL container and your development tools run in the **same container environment**. You can use the `-it --rm` flags and PostgreSQL will use "trust" authentication for local connections.

When connecting with `pgcli`, you can simply enter "root" when prompted for the password:
```bash
docker run -it --rm \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  postgres:18
```

Then connect:
```bash
uv run pgcli -h localhost -p 5432 -u root -d ny_taxi
```

#### Windows + WSL Development
This is the most important distinction for Windows users! On WSL, there's a **network boundary** between your WSL environment and Docker Desktop (which runs in a Hyper-V VM). This affects how you connect from WSL to containers.

**The critical difference:** You **must use `host.docker.internal`** instead of `localhost` when connecting from WSL to a Docker container.

**Why?** `localhost` in WSL refers to the WSL environment itself, not the Docker Desktop host. `host.docker.internal` is a special DNS name that Docker provides to reach the host machine.

**Rule of thumb for WSL users:**
- **Connecting FROM WSL TO a Docker container?** → Use `host.docker.internal`
- **Executing a command INSIDE the container** (with `docker exec`)? → Use `localhost` (or just use the tool directly inside the container)

**Example with pgcli:**
```bash
# This WON'T work on WSL:
uv run pgcli -h localhost -p 5432 -u root -d ny_taxi

# This WILL work on WSL:
uv run pgcli -h host.docker.internal -p 5432 -u root -d ny_taxi
```

**Example with SQLAlchemy (in a Jupyter notebook or Python script):**
```python
from sqlalchemy import create_engine

# For WSL, use host.docker.internal
engine = create_engine("postgresql://root:root@host.docker.internal:5432/ny_taxi")

# You can then use this engine to query or write data
df.to_sql('yellow_taxi_data', con=engine, if_exists='replace')
print(pd.io.sql.get_schema(df, name='yellow_taxi_data', con=engine))
```

**Avoiding Password Prompts with PGPASSWORD**
For scripting and automation, you can provide the password via the `PGPASSWORD` environment variable to avoid interactive prompts:

```bash
# With pgcli
PGPASSWORD=root uv run pgcli -h host.docker.internal -p 5432 -u root -d ny_taxi

# With psql
PGPASSWORD=root psql -h host.docker.internal -U root -d ny_taxi
```

This is especially useful for:
- Automated scripts and data pipelines
- CI/CD environments
- Docker containers running unattended

**Important: Container-to-Container Communication**
If you have multiple containers that need to communicate with each other (e.g., a Python pipeline container talking to PostgreSQL), they use the **container name** as the hostname on the same Docker network, NOT `host.docker.internal`:

```python
# Inside a container, connecting to another container:
engine = create_engine("postgresql://root:root@postgres_ny_taxi:5432/ny_taxi")
```

This works because Docker's internal DNS resolves container names to their IPs on the same network.

#### Local / WSL Development - Alternative: Using docker exec
On local machines or WSL, the PostgreSQL container and your CLI tools are **separate systems**. PostgreSQL 18 has authentication issues with remote TCP/IP connections from WSL. The solution is to use `docker exec` to connect from inside the container.

**Run the PostgreSQL container using either:**

**Option 1: Interactive mode `-it --rm` (see logs in real-time, dedicated terminal)**

```bash
docker run -it --rm --name postgres_ny_taxi \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  postgres:18
```

Wait for "database system is ready to accept connections", then in another terminal, connect using:
```bash
docker exec -it postgres_ny_taxi psql -U root -d ny_taxi
```

**Note:** Adding `--name` with `-it --rm` gives you a known container name while it's running, making it easier to connect. When you Ctrl+C, the container is automatically removed.

**Option 2: Detached mode `-d` (runs in background) - RECOMMENDED for easier connection**

```bash
docker run -d --name postgres_ny_taxi \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  postgres:18
```

Then connect using the container name:
```bash
docker exec -it postgres_ny_taxi psql -U root -d ny_taxi
```

**Why use `-d` with `--name`?** It's simpler - you always know the container name is `postgres_ny_taxi` so you can easily connect, check logs, stop/start it without having to look up random names or IDs.

**Important notes for WSL:**
- **Cannot use `pgcli` or `psql` directly from WSL** due to PostgreSQL 18 authentication issues
- Must use `docker exec` to connect from inside the container
- Volume path is `/var/lib/postgresql` (PostgreSQL 18 creates subdirectories automatically)
- To view logs in detached mode: `docker logs postgres_ny_taxi`
- To stop the container: `docker stop postgres_ny_taxi` (or Ctrl+C in interactive mode)
- To restart: `docker start postgres_ny_taxi`

**Useful SQL commands once connected:**
- `\dt` - List all tables
- `\q` - Quit
- `SELECT version();` - Check PostgreSQL version

## now after we are able to have a container with postgress running and able to run it with docker exec command. we can able to run sql commands inside the container.

for example

```sql
-- List tables
\dt

-- Create a test table
CREATE TABLE test (id INTEGER, name VARCHAR(50));

-- Insert data
INSERT INTO test VALUES (1, 'Hello Docker');

-- Query data
SELECT * FROM test;

-- Exit
\q
```

this data will be persisted in the volume we created even if we stop or remove the container.