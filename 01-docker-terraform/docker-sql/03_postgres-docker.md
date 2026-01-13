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



