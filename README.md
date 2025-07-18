# YouTube Music Library Extractor & Downloader

A comprehensive automation tool to extract your entire YouTube Music library and download it as MP3 files, organized by artist and playlist.

## Features

- **Automated Library Extraction**: Extracts all channels and playlists from your YouTube Music library
- **Artist Playlist Discovery**: Finds all playlists from each artist channel
- **Cookie Authentication**: Extracts cookies for authenticated downloads
- **Batch Downloading**: Downloads all music with proper organization
- **Resume Support**: Tracks downloaded files to avoid re-downloads
- **Parallel Processing**: Downloads multiple playlists simultaneously

## Prerequisites

- **Operating System**: Linux (tested on Fedora)
- **Python 3.x** with pip
- **Google Chrome/Chromium** browser
- **yt-dlp** (for downloading music)
- **Chrome Profile**: A Chrome profile logged into YouTube Music

### Required Python Packages
- `selenium`
- `beautifulsoup4`
- `chromedriver-autoinstaller`

### System Dependencies
```bash
# Install yt-dlp
sudo pip install yt-dlp

# Install tree (optional, for viewing directory structure)
sudo dnf install tree  # Fedora/RHEL
sudo apt install tree  # Debian/Ubuntu
```

## Quick Start

1. **Clone the repository**:
```bash
git clone https://github.com/YOUR_USERNAME/youtube-music-extractor.git
cd youtube-music-extractor
```

2. **Configure Chrome Profile**:
   - Edit the Chrome profile path in all Python scripts
   - Default: `/home/julian/.config/google-chrome/SeleniumProfile`
   - Change to your actual Chrome profile path

3. **Run the complete pipeline**:
```bash
./masterscript.sh
```

## Project Structure

```
.
├── masterscript.sh          # Main orchestration script
├── Step 1/                  # Library extraction
│   ├── trigger_scrape.sh
│   ├── ytmusic_library_extractor.py
│   ├── cleanup.sh
│   └── Output: channels.txt, playlist.txt
├── Step 2/                  # Artist playlist extraction
│   ├── batch_extract_playlists.sh
│   ├── extractartistplaylists.py
│   ├── cleanup.sh
│   └── artistplaylists/     # Output directory
├── Step 3/                  # Cookie extraction
│   ├── extract_cookies.py
│   └── cookies.txt          # Output
├── Step 4/                  # Music downloading
│   ├── download_all_artists.sh
│   ├── download_bestof.sh
│   ├── download_one_artist.sh
│   └── bestof.txt           # Your custom playlist URLs
└── music/                   # Downloaded music
    ├── artists/
    │   └── [Artist Name]/
    │       └── [Playlist Name]/
    └── bestof/
        └── [Playlist Name]/
```

## Configuration

### Chrome Profile Path
All Selenium scripts use a Chrome profile. Update the path in these files:
- `Step 1/ytmusic_library_extractor.py`
- `Step 2/extractartistplaylists.py`
- `Step 3/extract_cookies.py`

Look for this line and update it:
```python
driver_options.add_argument("--user-data-dir=/home/julian/.config/google-chrome/SeleniumProfile")
```

### Custom Playlists (bestof.txt)
Add YouTube Music playlist URLs to `Step 4/bestof.txt`, one per line:
```
https://music.youtube.com/playlist?list=PLxxxxxx
https://music.youtube.com/playlist?list=PLyyyyyy
```

## Step-by-Step Usage

### Individual Step Execution

**Step 1: Extract Library**
```bash
cd "Step 1"
./trigger_scrape.sh
```
- Outputs: `channels.txt`, `playlist.txt`

**Step 2: Extract Artist Playlists**
```bash
cd "Step 2"
./batch_extract_playlists.sh
```
- Reads: `../Step 1/channels.txt`
- Outputs: `artistplaylists/*.txt`

**Step 3: Extract Cookies**
```bash
cd "Step 3"
python3 extract_cookies.py
```
- Outputs: `cookies.txt`

**Step 4: Download Music**
```bash
cd "Step 4"
# Download custom playlists
./download_bestof.sh

# Download all artist playlists
./download_all_artists.sh

# Or download specific artist
./download_one_artist.sh "../Step 2/artistplaylists/Artist Name.txt"
```

## Troubleshooting

### Chrome Profile Issues
- **Error**: "Chrome profile already in use"
  - **Solution**: Close all Chrome instances or use a different profile

### Selenium Issues
- **Error**: "ChromeDriver version mismatch"
  - **Solution**: The scripts auto-install matching ChromeDriver, but ensure Chrome is updated

### Download Failures
- **Error**: "403 Forbidden" or "Video unavailable"
  - **Solution**: Check if cookies.txt exists and is recent (cookies expire)
  - Re-run Step 3 to refresh cookies

### Missing Playlists
- YouTube frequently changes their layout
- Check `Step 2/debug_page_source_*.html` files for debugging
- The script tries multiple selectors but may need updates

## Resume & Retry

The system maintains state to avoid re-processing:
- **Step 2**: `processed_urls.txt` tracks completed channels
- **Step 4**: Archive files track downloaded songs

To force re-processing:
- Delete `processed_urls.txt` to re-extract artist playlists
- Delete archive files to re-download songs

## Advanced Usage

### Download Specific Artists
```bash
cd "Step 4"
./download_one_artist.sh "../Step 2/artistplaylists/Daft Punk.txt"
```

### Customize Download Quality
Edit `download_one_artist.sh` or `download_bestof.sh`:
```bash
--audio-quality 0      # Best quality (default)
--audio-quality 320k   # 320 kbps
--audio-format opus    # Different format
```

### Parallel Downloads
The master script runs bestof and artist downloads in parallel. To run sequentially, modify `masterscript.sh`.

## Important Notes

1. **Legal**: Only download music you have rights to access
2. **Storage**: Ensure sufficient disk space (each song ~5-10MB)
3. **Time**: Full library download can take hours/days
4. **Bandwidth**: Consider your internet bandwidth and data caps
5. **Rate Limiting**: YouTube may rate limit; the scripts handle this gracefully

## Known Limitations

- Requires specific Chrome profile setup
- YouTube layout changes may break extraction
- Some region-locked content may not download
- Live recordings and videos might not extract audio properly

## License

This project is for personal use. Respect YouTube's Terms of Service and copyright laws.

## Contributing

Feel free to submit issues and enhancement requests!

## Support

If you encounter issues:
1. Check the troubleshooting section
2. Look at debug output files
3. Ensure all dependencies are installed
4. Check if YouTube's layout has changed
