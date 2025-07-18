#!/bin/bash

# Check if the download script exists
if [ ! -f "download_one_artist.sh" ]; then
    echo "Error: download_one_artist.sh not found!"
    echo "Please ensure the download script is in the same directory."
    exit 1
fi

# Check if prepare/artistplaylists directory exists
ARTIST_DIR="../Step 2/artistplaylists"
if [ ! -d "$ARTIST_DIR" ]; then
    echo "Error: Directory '$ARTIST_DIR' not found!"
    echo "Please ensure the artist playlist files are in prepare/artistplaylists/"
    exit 1
fi

# Check if there are any .txt files
txt_files=("$ARTIST_DIR"/*.txt)
if [ ! -f "${txt_files[0]}" ]; then
    echo "Error: No .txt files found in '$ARTIST_DIR'"
    echo "Please add artist playlist files to the directory."
    exit 1
fi

echo "Starting batch download of all artists..."
echo "Source directory: $ARTIST_DIR"
echo "================================================"

# Count total files for progress
total_files=$(ls -1 "$ARTIST_DIR"/*.txt 2>/dev/null | wc -l)
current_file=0
successful_downloads=0
failed_downloads=0

# Process each .txt file in the directory
for artist_file in "$ARTIST_DIR"/*.txt; do
    # Skip if no files match (shouldn't happen due to earlier check)
    [ ! -f "$artist_file" ] && continue
    
    ((current_file++))
    
    # Extract artist name from filename
    artist_name=$(basename "$artist_file" .txt)
    
    echo ""
    echo "[$current_file/$total_files] Processing artist: $artist_name"
    echo "File: $artist_file"
    echo "---------------------------------------------------"
    
    # Run the download script
    ./download_one_artist.sh "$artist_file"
    exit_code=$?
    
    # Check result
    if [ $exit_code -eq 0 ]; then
        echo "✓ Successfully processed: $artist_name"
        ((successful_downloads++))
    else
        echo "✗ Failed to process: $artist_name (exit code: $exit_code)"
        ((failed_downloads++))
    fi
    
    echo "---------------------------------------------------"
done

echo ""
echo "================================================"
echo "Batch download complete!"
echo "Total artists processed: $total_files"
echo "Successful downloads: $successful_downloads"
echo "Failed downloads: $failed_downloads"
echo ""
echo "Results saved in: artists/"

# Show final directory structure
if [ -d "artists" ]; then
    echo ""
    echo "Final directory structure:"
    tree artists -L 2 2>/dev/null || find artists -type d | head -20
fi
