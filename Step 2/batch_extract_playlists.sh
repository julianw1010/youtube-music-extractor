#!/bin/bash

# Define the path to channels.txt (one folder above, then in Step 1 subfolder)
CHANNELS_FILE="../Step 1/channels.txt"

# Check if channels.txt exists
if [ ! -f "$CHANNELS_FILE" ]; then
    echo "Error: channels.txt file not found at $CHANNELS_FILE!"
    echo "Please ensure the channels.txt file exists in the ../Step 1/ directory."
    exit 1
fi

# Check if the Python script exists
if [ ! -f "extractartistplaylists.py" ]; then
    echo "Error: extractartistplaylists.py not found!"
    echo "Please ensure the Python script is in the same directory."
    exit 1
fi

# Check if processed_urls exists
if [ ! -f "processed_urls.txt" ]; then
    echo "Error: processed_urls.txt not found!"
    echo "Please ensure the txt is in the same directory."
    exit 1
fi

# Trap SIGINT (Ctrl+C) to exit gracefully
trap 'echo -e "\n\nBatch processing interrupted by user. Exiting..."; exit 130' SIGINT

echo "Starting batch playlist extraction..."
echo "Reading channels from: $CHANNELS_FILE"
echo "=================================="

# Read each line from channels.txt and process it
line_number=1
while IFS= read -r url; do
    # Skip empty lines and lines starting with #
    if [[ -z "$url" || "$url" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Remove any trailing whitespace
    url=$(echo "$url" | xargs)
    
    echo "Processing line $line_number: $url"
    echo "-----------------------------------"
    
    # Run the Python script with the URL
    python3 extractartistplaylists.py "$url"
    exit_code=$?
    
    # Check exit code to determine what happened
    if [ $exit_code -eq 0 ]; then
        echo "✓ Successfully processed: $url"
    elif [ $exit_code -eq 1 ]; then
        echo "✗ Failed to process: $url"
    elif [ $exit_code -eq 130 ]; then
        echo "✗ User interrupted processing: $url"
        echo -e "\nBatch processing stopped by user interrupt."
        exit 130
    else
        echo "✗ Unexpected exit code $exit_code for: $url"
    fi
    
    echo ""
    ((line_number++))
    
done < "$CHANNELS_FILE"

echo "=================================="
echo "Batch processing complete!"
echo "Check the 'artistplaylists' folder for results."
