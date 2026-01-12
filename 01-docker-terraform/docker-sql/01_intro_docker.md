# Docker Commands Reference

A comprehensive guide to Docker basics, from installation verification to advanced volume mounting.

---

## 🔍 Installation & Setup

### Check Docker Version
```bash
docker --version
```

---

## 🚀 Running Containers

### Create and Run an Interactive Container
```bash
# Download and run Ubuntu container in interactive mode
docker run -it ubuntu
```

**Inside the container:**
```bash
# Update package list and install Python
apt-get update && apt install python3

# Verify Python installation
python3 -V

# Exit the container
exit  # or press Ctrl+D
```

---

## 🔧 Container Management

### Access Running Containers
```bash
# Execute commands in a running container
docker exec -it <container_id> /bin/bash
docker exec -it <container_name> /bin/bash
```

### Monitor Container Status
```bash
# List all containers (running and stopped)
docker ps -a
```

### Control Container Lifecycle
```bash
# Stop a running container
docker stop <container_id>

# Start a stopped container
docker start <container_id>

# Remove a container
docker rm <container_id>
```

### Batch Container Removal
```bash
# List all container IDs
docker ps -aq

# Remove all containers
docker rm $(docker ps -aq)
# or
docker rm `docker ps -aq`
```

---

## 💾 Data Persistence with Volumes

> **⚠️ Important:** Docker containers are stateless by default. When you remove a container, all data inside it is lost. Use volumes to persist data between container lifecycles.

### Creating a Volume Mount

**Step 1:** Determine the host directory path
```bash
echo $(pwd)/01-docker-terraform/docker-sql/test
```

**Step 2:** Run container with volume mount
```bash
docker run -it \
  --rm \
  --entrypoint=bash \
  -v $(pwd)/01-docker-terraform/docker-sql/test:/app/test \
  python:3.13.11-slim
```

### Command Breakdown

| Flag | Description |
|------|-------------|
| `docker run -it` | Run container in **i**nteractive mode with **t**erminal |
| `--rm` | Automatically remove container when it exits |
| `--entrypoint=bash` | Override default entrypoint to use bash shell |
| `-v <host_path>:<container_path>` | Mount host directory to container directory |
| `python:3.13.11-slim` | Use the Python slim image |

### Volume Mapping Example
```
Host Path:      $(pwd)/01-docker-terraform/docker-sql/test
                    ↓ maps to ↓
Container Path: /app/test
```

> **💡 Tip:** Omitting the `--rm` flag allows the container to persist after exit. You can restart it later using `docker start <container_id>`.

---

## 📝 Quick Reference

| Task | Command |
|------|---------|
| Run container | `docker run -it <image>` |
| List containers | `docker ps -a` |
| Stop container | `docker stop <container_id>` |
| Start container | `docker start <container_id>` |
| Remove container | `docker rm <container_id>` |
| Execute in container | `docker exec -it <container_id> /bin/bash` |
| Mount volume | `docker run -v <host>:<container> <image>` |

---

**Last Updated:** January 2026