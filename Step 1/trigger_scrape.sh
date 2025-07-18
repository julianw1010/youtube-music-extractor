#!/bin/bash

# Script to run YouTube Music Library Extractor

echo "YouTube Music Library URL Extractor"
echo "==================================="
echo ""

# Check if the Python script exists
if [ ! -f "ytmusic_library_extractor.py" ]; then
    echo "Error: ytmusic_library_extractor.py not found!"
    echo "Please ensure the Python script is in the current directory."
    exit 1
fi

# Check for required Python packages
echo "Checking required Python packages..."
python3 -c "import selenium" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Warning: selenium not installed. Installing..."
    pip install selenium
fi

python3 -c "import bs4" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Warning: beautifulsoup4 not installed. Installing..."
    pip install beautifulsoup4
fi

python3 -c "import chromedriver_autoinstaller" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Warning: chromedriver-autoinstaller not installed. Installing..."
    pip install chromedriver-autoinstaller
fi

echo ""
echo "Starting YouTube Music extraction..."
echo "-----------------------------------"

# Run the Python script
python ytmusic_library_extractor.py

# Check exit status
if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Extraction completed successfully!"
    echo ""
    echo "Generated files:"
    [ -f "channels.txt" ] && echo "  - channels.txt ($(wc -l < channels.txt) channels)"
    [ -f "playlist.txt" ] && echo "  - playlist.txt ($(wc -l < playlist.txt) playlists)"
    [ -f "youtube_music_library_source.txt" ] && echo "  - youtube_music_library_source.txt"
else
    echo ""
    echo "✗ Extraction failed!"
    exit 1
fi

echo ""
echo "Done!"
