#!/bin/bash

# Create a temporary directory for our test
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Create mock git and cargo scripts
MOCK_DIR="$TEST_DIR/mocks"
mkdir -p "$MOCK_DIR"

cat > "$MOCK_DIR/git" << 'EOF'
#!/bin/bash
echo "Mock git called with: $*" >> "$HOME/git_calls.log"
if [[ "$1" == "clone" ]]; then
  mkdir -p "$2"
  echo "Cloned $1 to $2" >> "$HOME/git_calls.log"
elif [[ "$1" == "pull" ]]; then
  echo "Pulled latest changes" >> "$HOME/git_calls.log"
fi
EOF

cat > "$MOCK_DIR/cargo" << 'EOF'
#!/bin/bash
echo "Mock cargo called with: $*" >> "$HOME/cargo_calls.log"
if [[ "$1" == "build" ]]; then
  echo "Built project" >> "$HOME/cargo_calls.log"
fi
EOF

chmod +x "$MOCK_DIR/git" "$MOCK_DIR/cargo"

# Set the PATH to include our mock scripts
export PATH="$MOCK_DIR:$PATH"

# Set HOME to our test directory to avoid modifying the real home directory
export HOME="$TEST_DIR"

# Create a copy of runner.sh in the test directory
cp runner.sh "$TEST_DIR/"

# Run the runner.sh script
cd "$TEST_DIR"
./runner.sh

# Check the results
echo "Checking results..."
if [[ -f "$TEST_DIR/rana" ]]; then
  echo "Rana directory created."
fi

if [[ -f "$HOME/git_calls.log" ]]; then
  echo "Git calls:"
  cat "$HOME/git_calls.log"
fi

if [[ -f "$HOME/cargo_calls.log" ]]; then
  echo "Cargo calls:"
  cat "$HOME/cargo_calls.log"
fi

# Clean up
rm -rf "$TEST_DIR"