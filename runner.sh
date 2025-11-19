#!/bin/bash

# Define variables
#REPO_URL="https://github.com/grunch/rana.git"
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