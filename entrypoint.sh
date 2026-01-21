#!/bin/bash
set -e

# Check if TEST_PATH is set
if [ -z "$TEST_PATH" ]; then
    echo "Error: TEST_PATH environment variable is not set"
    echo "Usage: docker run -e TEST_PATH=/path/to/tests <image>"
    exit 1
fi

# Check if TEST_PATH directory exists
if [ ! -d "$TEST_PATH" ]; then
    echo "Error: TEST_PATH directory '$TEST_PATH' does not exist"
    exit 1
fi

# Find all .side files in TEST_PATH
SIDE_FILES=$(find "$TEST_PATH" -type f -name "*.side" 2>/dev/null)

if [ -z "$SIDE_FILES" ]; then
    echo "Warning: No .side files found in $TEST_PATH"
    exit 0
fi

# Count files for reporting
FILE_COUNT=$(echo "$SIDE_FILES" | wc -l)
echo "Found $FILE_COUNT .side file(s) in $TEST_PATH"
echo ""

# Build selenium-side-runner command with optional base URL
SELENIUM_CMD="selenium-side-runner"
if [ -n "$BASE_URL" ]; then
    echo "Using base URL: $BASE_URL"
    SELENIUM_CMD="$SELENIUM_CMD --base-url $BASE_URL"
fi

# Run each .side file
FAILED_TESTS=0
PASSED_TESTS=0

for side_file in $SIDE_FILES; do
    echo "=========================================="
    echo "Running: $side_file"
    echo "=========================================="
    
    if $SELENIUM_CMD "$side_file"; then
        echo "✓ PASSED: $side_file"
        ((PASSED_TESTS++))
    else
        echo "✗ FAILED: $side_file"
        ((FAILED_TESTS++))
    fi
    echo ""
done

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total tests: $FILE_COUNT"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo "=========================================="

# Exit with error if any tests failed
if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
fi

exit 0
