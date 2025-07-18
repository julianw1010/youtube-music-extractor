#!/bin/bash

# Master script to run the complete YouTube Music extraction pipeline
# This script should be placed in the parent directory containing Step 1, Step 2, Step 3, and Step 4

echo "YouTube Music Complete Pipeline"
echo "==============================="
echo ""
echo "This will run:"
echo "  1. Step 1: Extract channels and playlists from YouTube Music Library"
echo "  2. Step 2: Extract artist playlists from channels"
echo "  3. Step 3: Extract cookies from YouTube Music"
echo "  4. Step 4: Download best-of playlist AND all artist playlists (simultaneously)"
echo ""
echo "Press Ctrl+C at any time to cancel."
echo ""

# Function to check if a script exists and is executable
check_script() {
    local script_path="$1"
    if [ ! -f "$script_path" ]; then
        echo "Error: $script_path not found!"
        return 1
    fi
    if [ ! -x "$script_path" ]; then
        echo "Warning: $script_path is not executable. Making it executable..."
        chmod +x "$script_path"
    fi
    return 0
}

# Function to run a step
run_step() {
    local step_num="$1"
    local step_name="$2"
    local script_path="$3"
    
    echo ""
    echo "============================================"
    echo "STEP $step_num: $step_name"
    echo "============================================"
    echo "Running: $script_path"
    echo ""
    
    cd "Step $step_num" || {
        echo "Error: Cannot enter Step $step_num directory!"
        return 1
    }
    
    # Extract just the script name for execution
    local script_name=$(basename "$script_path")
    
    # Check if it's a Python script
    if [[ "$script_name" == *.py ]]; then
        python3 "$script_name"
    else
        ./"$script_name"
    fi
    
    local exit_code=$?
    
    cd ..
    
    if [ $exit_code -ne 0 ]; then
        echo ""
        echo "Error: Step $step_num failed with exit code $exit_code"
        return $exit_code
    fi
    
    echo ""
    echo "✓ Step $step_num completed successfully!"
    return 0
}

# Check if all required directories exist
for i in 1 2 3 4; do
    if [ ! -d "Step $i" ]; then
        echo "Error: Step $i directory not found!"
        echo "Please ensure you're running this script from the parent directory containing Step 1, Step 2, Step 3, and Step 4."
        exit 1
    fi
done

# Check if all required scripts exist
echo "Checking required scripts..."
check_script "Step 1/trigger_scrape.sh" || exit 1
check_script "Step 2/batch_extract_playlists.sh" || exit 1
check_script "Step 3/extract_cookies.py" || exit 1
check_script "Step 4/download_bestof.sh" || exit 1
check_script "Step 4/download_all_artists.sh" || exit 1
echo "✓ All required scripts found!"

# Start the pipeline
echo ""
echo "Starting pipeline..."
start_time=$(date +%s)

# Step 1: Extract channels and playlists
run_step 1 "Extract YouTube Music Library" "trigger_scrape.sh" || {
    echo "Pipeline aborted due to Step 1 failure."
    exit 1
}

# Step 2: Extract artist playlists
run_step 2 "Extract Artist Playlists" "batch_extract_playlists.sh" || {
    echo "Pipeline aborted due to Step 2 failure."
    exit 1
}

# Step 3: Extract cookies
run_step 3 "Extract Cookies" "extract_cookies.py" || {
    echo "Pipeline aborted due to Step 3 failure."
    exit 1
}

# Step 4: Download playlists (run both simultaneously)
echo ""
echo "============================================"
echo "STEP 4: Download Playlists"
echo "============================================"
echo "Running download_bestof.sh and download_all_artists.sh simultaneously..."
echo ""

cd "Step 4" || {
    echo "Error: Cannot enter Step 4 directory!"
    exit 1
}

# Run both download scripts in parallel
./download_bestof.sh &
bestof_pid=$!
echo "Started download_bestof.sh (PID: $bestof_pid)"

./download_all_artists.sh &
all_artists_pid=$!
echo "Started download_all_artists.sh (PID: $all_artists_pid)"

echo ""
echo "Waiting for both download scripts to complete..."
echo "(This may take a while depending on the number of playlists)"
echo ""

# Wait for both processes to complete
wait $bestof_pid
bestof_exit=$?

wait $all_artists_pid
all_artists_exit=$?

cd ..

# Check if both completed successfully
if [ $bestof_exit -eq 0 ] && [ $all_artists_exit -eq 0 ]; then
    echo ""
    echo "✓ Step 4 completed successfully!"
else
    echo ""
    echo "Warning: Step 4 had issues:"
    [ $bestof_exit -ne 0 ] && echo "  - download_bestof.sh failed with exit code $bestof_exit"
    [ $all_artists_exit -ne 0 ] && echo "  - download_all_artists.sh failed with exit code $all_artists_exit"
fi

# Calculate total time
end_time=$(date +%s)
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))

echo ""
echo "============================================"
echo "PIPELINE COMPLETE!"
echo "============================================"
echo "Total time: ${minutes}m ${seconds}s"
echo ""
echo "Results:"
echo "  - Step 1: Channels and playlists extracted"
echo "  - Step 2: Artist playlists extracted to Step 2/artistplaylists/"
echo "  - Step 3: Cookies extracted to Step 3/cookies.txt"
echo "  - Step 4: Downloads completed (check Step 4 for downloaded files)"
echo ""
echo "Done!"
