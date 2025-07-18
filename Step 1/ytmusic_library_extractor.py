from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
import chromedriver_autoinstaller
import time
import os
import signal
import subprocess
import sys
import re

# Install matching chromedriver
chromedriver_autoinstaller.install()

# Cleanup function
def run_cleanup():
    """Run the cleanup script"""
    try:
        cleanup_script = os.path.join(os.path.dirname(__file__), "cleanup.sh")
        if os.path.exists(cleanup_script):
            print("\nRunning cleanup script...")
            subprocess.run(["bash", cleanup_script], check=False)
        else:
            print(f"\nCleanup script not found: {cleanup_script}")
    except Exception as e:
        print(f"Error running cleanup script: {e}")

# Signal handler for Ctrl+C
def signal_handler(sig, frame):
    print("\nCtrl+C detected!")
    run_cleanup()
    os._exit(130)  # Standard exit code for SIGINT

# Register signal handler
signal.signal(signal.SIGINT, signal_handler)

def extract_and_save_urls(page_source):
    """Extract channel and playlist URLs from the page source"""
    
    # Parse HTML with BeautifulSoup
    soup = BeautifulSoup(page_source, 'html.parser')
    
    # Find the contents div
    contents_div = soup.find('div', {'id': 'contents', 'class': 'style-scope ytmusic-section-list-renderer'})
    
    if not contents_div:
        print("Warning: Could not find the expected contents div. Searching entire document...")
        contents_div = soup  # Search entire document as fallback
    
    # Find all links
    all_links = contents_div.find_all('a', href=True)
    
    # Sets to store unique URLs
    channel_urls = set()
    playlist_urls = set()
    
    # Regular expressions for matching (without leading slash)
    channel_pattern = re.compile(r'channel/[A-Za-z0-9_-]+')
    browse_pattern = re.compile(r'browse/[A-Za-z0-9_-]+')
    playlist_pattern = re.compile(r'playlist\?list=[A-Za-z0-9_-]+')
    
    # Extract and categorize URLs
    for link in all_links:
        href = link.get('href', '')
        
        # Check for channel URLs
        if channel_pattern.search(href):
            # Extract just the channel part
            match = channel_pattern.search(href)
            channel_url = match.group()
            channel_urls.add(channel_url)
        
        # Check for browse URLs (playlists)
        elif browse_pattern.search(href):
            match = browse_pattern.search(href)
            browse_url = match.group()
            playlist_urls.add(browse_url)
        
        # Check for playlist URLs
        elif playlist_pattern.search(href):
            match = playlist_pattern.search(href)
            playlist_url = match.group()
            playlist_urls.add(playlist_url)
    
    # Convert sets to sorted lists
    channel_urls = sorted(list(channel_urls))
    playlist_urls = sorted(list(playlist_urls))
    
    # Save channel URLs
    with open('channels.txt', 'w', encoding='utf-8') as f:
        for url in channel_urls:
            # Write full URL
            full_url = f"https://youtube.com/{url}"
            f.write(f"{full_url}\n")
    
    print(f"\nSaved {len(channel_urls)} unique channel URLs to channel.txt")
    if channel_urls:
        print("Sample channels:")
        for url in channel_urls[:3]:
            print(f"  - {url}")
    
    # Save playlist URLs
    with open('playlist.txt', 'w', encoding='utf-8') as f:
        for url in playlist_urls:
            # Write full URL
            full_url = f"https://music.youtube.com/{url}"
            f.write(f"{full_url}\n")
    
    print(f"\nSaved {len(playlist_urls)} unique playlist URLs to playlist.txt")
    if playlist_urls:
        print("Sample playlists:")
        for url in playlist_urls[:3]:
            print(f"  - {url}")
    
    # Additional statistics
    print(f"\nTotal links found: {len(all_links)}")
    print(f"Channel URLs: {len(channel_urls)}")
    print(f"Playlist URLs: {len(playlist_urls)}")

# Set up Chrome options with cloned profile
driver_options = Options()
driver_options.add_argument("--user-data-dir=/home/julian/.config/google-chrome/SeleniumProfile")

# Launch Chrome
driver = webdriver.Chrome(options=driver_options)

try:
    # Navigate to YouTube Music Library
    url = "https://music.youtube.com/library"
    print(f"Opening {url}...")
    driver.get(url)
    
    # Wait for page to load - wait for a common element that appears when library is loaded
    wait = WebDriverWait(driver, 10)
    try:
        # Wait for the main content to be present
        wait.until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "ytmusic-library-landing-page-renderer, ytmusic-app"))
        )
        print("Page loaded successfully")
    except Exception as e:
        print(f"Warning: Could not confirm page load ({type(e).__name__}), continuing anyway...")
    
    # Additional wait to ensure dynamic content loads
    time.sleep(3)
    
    # Scroll down to load more content if needed
    print("Scrolling to load all content...")
    last_height = driver.execute_script("return document.body.scrollHeight")
    
    while True:
        # Scroll down to bottom
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        
        # Wait to load page
        time.sleep(2)
        
        # Calculate new scroll height and compare with last scroll height
        new_height = driver.execute_script("return document.body.scrollHeight")
        if new_height == last_height:
            break
        last_height = new_height
    
    print("Finished scrolling")
    
    # Get the page source
    page_source = driver.page_source
    
    # Optional: Save the source code for debugging
    with open('youtube_music_library_source.txt', 'w', encoding='utf-8') as f:
        f.write(page_source)
    print("Source code also saved to: youtube_music_library_source.txt")
    
    # Extract and save URLs
    extract_and_save_urls(page_source)
    
    print("\nProcess completed successfully!")
    
    # Keep browser open for a moment to verify
    print("\nClosing browser in 3 seconds...")
    time.sleep(3)

except Exception as e:
    print(f"Script crashed: {e}")
    run_cleanup()
    os._exit(1)  # Force exit after cleanup

finally:
    # Close the browser
    try:
        driver.quit()
        print("Browser closed successfully")
    except:
        pass
