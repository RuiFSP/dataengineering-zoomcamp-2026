# Changing Python Version in UV Environment

Initially i was using python 3.12 in my UV environment. However, I needed to upgrade to python 3.13 to use some newer packages.


## Update Python Version to 3.13

To change your UV environment from Python 3.12 to Python 3.13 and update all packages:

### Step 1: Pin Python Version
```bash
uv python pin 3.13
```

### Step 2: Sync Environment
```bash
uv sync
```