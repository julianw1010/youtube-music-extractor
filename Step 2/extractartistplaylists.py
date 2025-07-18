from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver import ActionChains
from selenium.webdriver.common.keys import Keys
import chromedriver_autoinstaller
import time
import re
import sys
import os
import signal
import subprocess
import atexit

# Install matching chromedriver
chromedriver_autoinstaller.install()

# Check for command line argument
if len(sys.argv) != 2:
    print("Usage: python extractartistplaylists.py <youtube_channel_url>")
    print("Example: python extractartistplaylists.py https://youtube.com/channel/UC0c4bK_92XYr0YtASqqWOJg")
    sys.exit(1)

channel_url = sys.argv[1]

# Processed URLs tracking
processed_urls_file = "processed_urls.txt"

def load_processed_urls():
    """Load the list of processed URLs"""
    if os.path.exists(processed_urls_file):
        with open(processed_urls_file, 'r', encoding='utf-8') as f:
            return set(line.strip() for line in f if line.strip())
    return set()

def add_processed_url(url):
    """Add URL to processed list"""
    with open(processed_urls_file, 'a', encoding='utf-8') as f:
        f.write(f"{url}\n")

# Check if URL already processed
processed_urls = load_processed_urls()
if channel_url in processed_urls:
    print(f"URL {channel_url} already processed - skipping")
    sys.exit(0)

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

# Register signal handler (but not exit handler for normal completion)
signal.signal(signal.SIGINT, signal_handler)

# Set up Chrome options with cloned profile
driver_options = Options()
driver_options.add_argument("--user-data-dir=/home/julian/.config/google-chrome/SeleniumProfile")

# Launch Chrome
driver = webdriver.Chrome(options=driver_options)

try:
    # Navigate to YouTube channel
    driver.get(channel_url)
    # Wait before clicking View All
    time.sleep(1)

    # Get the page title for filename
    page_title = driver.title
    # Remove " - YouTube" and " - Topic" from the title and clean for filename
    clean_title = page_title.replace(" - YouTube", "").replace(" - Topic", "")
    safe_title = re.sub(r'[<>:"/\\|?*]', '_', clean_title)

    # Create subfolder if it doesn't exist
    subfolder = "artistplaylists"
    os.makedirs(subfolder, exist_ok=True)

    # Create filepath in subfolder
    filename = os.path.join(subfolder, f"{safe_title}.txt")

    print(f"Will save to: {filename}")

    # Try to find "View all" button
    wait = WebDriverWait(driver, 5)  # Reduced timeout for faster fallback
    try:
        view_all = wait.until(
            EC.element_to_be_clickable((By.XPATH, "//button[.//span[text()='View all']]"))
        )
        print("Found 'View all' button - using popup method")
        view_all.click()
        time.sleep(1)

        # Wait for popup dialog to appear
        dialog = wait.until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, "ytd-popup-container tp-yt-paper-dialog"))
        )
        time.sleep(1)

        # Locate scroll container in popup
        scroll_box = dialog.find_element(
            By.CSS_SELECTOR,
            "ytd-item-section-renderer div#contents.style-scope.ytd-item-section-renderer"
        )
        print("Using popup scroll container")
        time.sleep(1)

        # Make container focusable
        driver.execute_script("arguments[0].setAttribute('tabindex','0');", scroll_box)
        time.sleep(1)

        # Visible scroll by scrolling to last item until no new items
        prev_total = 0
        while True:
            # Get current items
            items = scroll_box.find_elements(By.CSS_SELECTOR, "ytd-grid-playlist-renderer")
            count = len(items)
            print(f"Loaded items: {count}")

            # Stop if no new items appear
            if count == prev_total:
                print("No more new items; scroll complete.")
                break
            
            # Scroll to the last item to trigger loading more
            if items:
                driver.execute_script("arguments[0].scrollIntoView();", items[-1])
            
            prev_total = count
            time.sleep(2)

        # Extract playlist titles and URLs from popup
        playlists = scroll_box.find_elements(By.CSS_SELECTOR, "ytd-grid-playlist-renderer a#video-title")
        print(f"Total playlists extracted from popup: {len(playlists)}")
        
        # Debug: check what we actually found
        print("Debug - First 3 playlist elements:")
        for i, pl in enumerate(playlists[:3]):
            href = pl.get_attribute('href')
            title = pl.get_attribute('title')
            text = pl.text.strip()
            print(f"  Element {i+1}:")
            print(f"    href: {href}")
            print(f"    title: {title}")
            print(f"    text: {text}")
            print(f"    has watch in href: {href and '/watch' in href if href else False}")

    except Exception as e:
        print(f"'View all' button not found ({type(e).__name__}) - checking for horizontal list")
        
        # Look for playlists in horizontal list directly
        try:
            horizontal_list = driver.find_element(By.CSS_SELECTOR, "yt-horizontal-list-renderer")
            print("Found horizontal list - extracting playlists directly")
            
            # Get the actual playlist title links, not the badge links
            playlists = horizontal_list.find_elements(By.CSS_SELECTOR, "yt-lockup-metadata-view-model a[href*='/watch']")
            
            # If that doesn't work, try alternative selectors for playlist titles
            if not playlists:
                playlists = horizontal_list.find_elements(By.CSS_SELECTOR, ".yt-lockup-metadata-view-model-wiz__title[href*='/watch']")
            
            if not playlists:
                playlists = horizontal_list.find_elements(By.CSS_SELECTOR, "h3 a[href*='/watch']")
            
            print(f"Total playlists extracted from horizontal list: {len(playlists)}")
            
            # Debug: print some found elements
            print("Debug - Found playlist elements:")
            for i, pl in enumerate(playlists[:3]):  # Show first 3 for debugging
                href = pl.get_attribute('href')
                title = pl.get_attribute('title') or pl.text.strip()
                print(f"  {i+1}: {title} -> {href}")
            
        except Exception as e2:
            print(f"No horizontal list found ({type(e2).__name__}) - trying alternative selectors")
            
            # Try alternative selectors for newer YouTube layouts
            alternative_selectors = [
                "yt-lockup-metadata-view-model a[href*='/watch']",
                ".yt-lockup-metadata-view-model-wiz__title[href*='/watch']", 
                "h3 a[href*='/watch']",
                "a.yt-lockup-metadata-view-model-wiz__title[href*='/watch']"
            ]
            
            playlists = []
            for selector in alternative_selectors:
                try:
                    found_playlists = driver.find_elements(By.CSS_SELECTOR, selector)
                    if found_playlists:
                        print(f"Found {len(found_playlists)} playlists with selector: {selector}")
                        playlists = found_playlists
                        break
                except:
                    continue
            
            if not playlists:
                print("No playlists found with any selector")
                # Debug: save page source to investigate
                with open(f"debug_page_source_{safe_title}.html", "w", encoding="utf-8") as f:
                    f.write(driver.page_source)
                print(f"Saved page source to debug_page_source_{safe_title}.html for investigation")

    # Pause before extraction
    time.sleep(1)

    # Write to file with tab-separated values
    with open(filename, 'w', encoding='utf-8') as f:
        playlist_count = 0
        for pl in playlists:
            href = pl.get_attribute('href')
            if href and '/watch' in href:  # Look for video links instead of playlist links
                # Try multiple ways to get the title
                title = (pl.get_attribute('title') or 
                        pl.get_attribute('aria-label') or 
                        pl.text.strip() or 
                        "Unknown Playlist")
                
                # Clean up the title (remove extra whitespace and newlines)
                title = ' '.join(title.split())
                
                # Write tab-separated values
                f.write(f"{title}\t{href}\n")
                print(f"Saved: {title}")
                playlist_count += 1
        
        print(f"Total playlists saved: {playlist_count}")

    print(f"Playlists saved to: {filename}")

    # Mark URL as processed
    add_processed_url(channel_url)
    print(f"Marked {channel_url} as processed")

except Exception as e:
    print(f"Script crashed: {e}")
    run_cleanup()
    os._exit(1)  # Force exit after cleanup
