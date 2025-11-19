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
  git checkout meshmate 2>/dev/null || git checkout -b meshmate github-c03rad0r/meshmate || { echo "Failed to checkout meshmate branch"; exit 1; }
  git reset --hard github-c03rad0r/meshmate || { echo "Failed to reset to github-c03rad0r/meshmate"; exit 1; }
else
  echo "Cloning Rana repository..."
  git clone "$REPO_URL" "$REPO_DIR" || { echo "Failed to clone repository"; exit 1; }
  cd "$REPO_DIR" || { echo "Failed to change directory to $REPO_DIR"; exit 1; }
  git fetch --all || { echo "Failed to fetch from all remotes"; exit 1; }
  git checkout -b meshmate github-c03rad0r/meshmate || { echo "Failed to checkout meshmate branch"; exit 1; }
fi

# 2. Build the project
echo "Building Rana..."
cargo build --release || { echo "Failed to build Rana"; exit 1; }

# 3. Run the miner with the lowest priority in the background
echo "Starting Rana miner with vanity prefix: $VANITY_PREFIX"
nice -n 19 target/release/rana --vanity-n-prefix="$VANITY_PREFIX" >> "$OUTPUT_FILE" 2>&1 &
echo "Rana miner started with PID $! and lowest priority (nice value: 19)"