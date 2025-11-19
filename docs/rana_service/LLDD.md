# Low-Level Design Document: Rana Service

## 1. Runner Script (`runner.sh`)

This script will be responsible for the core logic of the service.

```bash
#!/bin/bash

# Define variables
REPO_URL="https://github.com/grunch/rana.git"
REPO_DIR="$HOME/rana"
VANITY_PREFIX="meshmate"
OUTPUT_FILE="$HOME/$VANITY_PREFIX.md"

# 1. Clone or update the repository
if [ -d "$REPO_DIR" ]; then
  echo "Rana repository found. Pulling latest changes..."
  cd "$REPO_DIR" || { echo "Failed to change directory to $REPO_DIR"; exit 1; }
  git fetch origin || { echo "Failed to fetch from origin"; exit 1; }
  git reset --hard origin/main || { echo "Failed to reset to origin/main"; exit 1; }
else
  echo "Cloning Rana repository..."
  git clone "$REPO_URL" "$REPO_DIR" || { echo "Failed to clone repository"; exit 1; }
  cd "$REPO_DIR" || { echo "Failed to change directory to $REPO_DIR"; exit 1; }
fi

# 2. Build the project
echo "Building Rana..."
cargo build --release || { echo "Failed to build Rana"; exit 1; }

# 3. Run the miner with the lowest priority
echo "Starting Rana miner with vanity prefix: $VANITY_PREFIX"
nice -n 19 target/release/rana --vanity-n-prefix="$VANITY_PREFIX" >> "$OUTPUT_FILE" || { echo "Rana miner failed"; exit 1; }
```

### Error Handling

- The script will redirect the output of the `rana` miner, which includes the generated keypairs, to a file in the user's home directory named `~/[VANITY_PREFIX].md`.
- If any command fails, the script will log an error message and exit with a non-zero status.

## 2. Systemd Service Unit (`rana.service`)

This service unit will manage the `runner.sh` script. It should be placed in `/etc/systemd/system/`.

```ini
[Unit]
Description=Rana Nostr Miner Service
After=network.target

[Service]
User=c03rad0r
Group=c03rad0r
ExecStart=/bin/bash /home/c03rad0r/rana/runner.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Configuration

- `User` and `Group` should be set to the appropriate user and group.
- `ExecStart` should point to the correct path of the `runner.sh` script.

### Installation

To install and enable the service, the user will need to run the following commands:

```bash
sudo cp rana.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rana.service
sudo systemctl start rana.service
```
  cd "$REPO_DIR"
fi

# 2. Build the project
echo "Building Rana..."
cargo build --release

# 3. Run the miner with the lowest priority
echo "Starting Rana miner with vanity prefix: $VANITY_PREFIX"
nice -n 19 target/release/rana --vanity-n-prefix="$VANITY_PREFIX"
```

### Error Handling

- The `set -e` command at the beginning of the script ensures that the script will exit immediately if any command fails.
- We will add more specific error handling and logging in the implementation phase.

## 2. Systemd Service Unit (`rana.service`)

This service unit will manage the `runner.sh` script. It should be placed in `/etc/systemd/system/`.

```ini
[Unit]
Description=Rana Nostr Miner Service
After=network.target

[Service]
User={{USERNAME}}
Group={{GROUP}}
ExecStart=/bin/bash /path/to/runner.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Configuration

- `{{USERNAME}}` and `{{GROUP}}` should be replaced with the appropriate user and group.
- `/path/to/runner.sh` should be replaced with the actual path to the `runner.sh` script.

### Installation

To install and enable the service, the user will need to run the following commands:

```bash
sudo cp rana.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rana.service
sudo systemctl start rana.service