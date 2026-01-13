# Virtual Environments and Data Pipelines with UV

UV is a fast Python package installer and resolver that simplifies dependency management and environment creation.

## Changing Python Version in UV Environment

Initially I was using Python 3.12 in my UV environment. However, I needed to upgrade to Python 3.13 to use some newer packages.

### Why Upgrade Python?
- New packages may require Python 3.13+
- Python 3.13 has performance improvements and new features
- Keeping your environment up-to-date ensures compatibility

### Update Python Version to 3.13

To change your UV environment from Python 3.12 to Python 3.13 and update all packages:

#### Step 1: Pin Python Version
```bash
uv python pin 3.13
```
This command updates your `.python-version` file to specify Python 3.13.

#### Step 2: Sync Environment
```bash
uv sync
```
This command updates your virtual environment to use Python 3.13 and resolves all dependencies for the new Python version.

#### Step 3: Verify the Update
To confirm the Python version has been updated:
```bash
python --version
```
You should see `Python 3.13.x` in the output.

#### Step 4: Update VS Code Interpreter (Optional)
If using VS Code:
1. Open the Command Palette: `Ctrl+Shift+P`
2. Search for **Python: Select Interpreter**
3. Choose the Python 3.13 interpreter from your UV environment
4. Reload the window if needed: **Developer: Reload Window**