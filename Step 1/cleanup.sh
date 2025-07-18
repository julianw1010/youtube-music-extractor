#!/bin/bash
echo "Killing all Chrome/Chromium/ChromeDriver processes..."
pkill -f chromedriver
pkill -f chrome
pkill -f chromium
sleep 2
pkill -9 -f "chrome|chromium|chromedriver"
echo "Cleanup complete!"
