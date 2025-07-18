#!/bin/bash

# Check if artist file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <artist_file.txt>"
    echo "Example: $0 artistplaylists/K_DA.txt"
    exit 1
fi

ARTIST_FILE="$1"

# Check if cookies file exists
COOKIES_FILE=""../Step 3/cookies.txt""
if [ ! -f "$COOKIES_FILE" ]; then
    echo "Warning: Cookies file not found at $COOKIES_FILE"
    echo "Continuing without cookies (some content may not be accessible)"
    COOKIES_OPTION=""
else
    echo "Using cookies file: $COOKIES_FILE"
    COOKIES_OPTION="--cookies $COOKIES_FILE"
fi

# Check if file exists
if [ ! -f "$ARTIST_FILE" ]; then
    echo "Error: File '$ARTIST_FILE' not found!"
    exit 1
fi

# Extract artist name from filename (remove path and .txt extension)
ARTIST_NAME=$(basename "$ARTIST_FILE" .txt)

# Create base directories
BASE_DIR="../music/artists"
ARTIST_DIR="$BASE_DIR/$ARTIST_NAME"

mkdir -p "$ARTIST_DIR"

echo "Starting download for artist: $ARTIST_NAME"
echo "Artist directory: $ARTIST_DIR"
echo "================================================"

# Counter for progress
total_playlists=$(wc -l < "$ARTIST_FILE")
current_playlist=0

# Read each line from the artist file
while IFS=$'\t' read -r playlist_name playlist_url; do
    # Skip empty lines
    if [[ -z "$playlist_name" || -z "$playlist_url" ]]; then
        continue
    fi
    
    ((current_playlist++))
    
    echo "[$current_playlist/$total_playlists] Processing: $playlist_name"
    echo "URL: $playlist_url"
    
    # Clean playlist name for folder (remove invalid characters)
    clean_playlist_name=$(echo "$playlist_name" | sed 's/[<>:"/\\|?*]/_/g')
    playlist_folder="$ARTIST_DIR/$clean_playlist_name"
    playlist_archive="$playlist_folder/${clean_playlist_name}_archive.txt"
    
    # Create playlist folder directly under artist folder
    mkdir -p "$playlist_folder"
    
    # Download playlist with yt-dlp
    echo "Downloading to: $playlist_folder"
    echo "Archive: $playlist_archive"
    yt-dlp \
        $COOKIES_OPTION \
        --embed-thumbnail \
        --add-metadata \
        --extract-audio \
        --audio-format mp3 \
        --audio-quality 0 \
        --output "$playlist_folder/%(title)s.%(ext)s" \
        --download-archive "$playlist_archive" \
        --ignore-errors \
        --no-overwrites \
        "$playlist_url"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully downloaded: $playlist_name"
    else
        echo "✗ Failed to download: $playlist_name"
    fi
    
    echo "---"
    
done < "$ARTIST_FILE"

echo "================================================"
echo "Download complete for artist: $ARTIST_NAME"
echo "Files saved to: $ARTIST_DIR"
echo "Archive file: $ARCHIVE_FILE"

# Show summary
total_files=$(find "$ARTIST_DIR" -name "*.mp3" -o -name "*.m4a" -o -name "*.webm" | wc -l)
echo "Total audio files downloaded: $total_files"

# Show folder structure
echo ""
echo "Folder structure:"
tree "$ARTIST_DIR" -L 2 2>/dev/null || find "$ARTIST_DIR" -type d | head -10
