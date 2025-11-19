#!/bin/bash

# Define variables
REPO_URL="https://github.com/c03rad0r/rana.git"
REPO_DIR="$HOME/rana"
VANITY_PREFIX="meshmate"
OUTPUT_FILE="$HOME/$VANITY_PREFIX.md"

# 1. Clone or update the repository
if [ -d "$REPO_DIR" ]; then
  echo "Rana repository found. Pulling latest changes..."
  cd "$REPO_DIR" || { echo "Failed to change directory to $REPO_DIR"; exit 1; }
  git fetch --all || { echo "Failed to fetch from all remotes"; exit 1; }
  git checkout meshmate 2>/dev/null || git checkout -b meshmate origin/meshmate || { echo "Failed to checkout meshmate branch"; exit 1; }
  git reset --hard origin/meshmate || { echo "Failed to reset to origin/meshmate"; exit 1; }
else
  echo "Cloning Rana repository..."
  git clone "$REPO_URL" "$REPO_DIR" || { echo "Failed to clone repository"; exit 1; }
  cd "$REPO_DIR" || { echo "Failed to change directory to $REPO_DIR"; exit 1; }
  git fetch --all || { echo "Failed to fetch from all remotes"; exit 1; }
  git checkout -b meshmate origin/meshmate || { echo "Failed to checkout meshmate branch"; exit 1; }
fi

# 2. Build the project
echo "Building Rana..."
cargo build --release || { echo "Failed to build Rana"; exit 1; }

# 3. Start the systemd service
echo "Starting Rana service..."
sudo systemctl start rana.service || { echo "Failed to start rana.service"; exit 1; }
echo "Rana service started"