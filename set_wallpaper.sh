#!/bin/bash

# Replace with your Unsplash API key
API_KEY="ls7g4qUtBDMVmMZotn2J_K0djGCEE3MPi6sSDXt23BY"

# Directory to store the wallpaper
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Query parameters
QUERY="nature wallpaper"  # Search for nature wallpapers
ORIENTATION="landscape"   # Only landscape orientation
IMAGE_PATH="$WALLPAPER_DIR/temp_wallpaper.jpg"

# Fetch a random image from Unsplash with query parameters
IMAGE_URL=$(curl -s -G "https://api.unsplash.com/photos/random" \
                 --data-urlencode "client_id=$API_KEY" \
                 --data-urlencode "query=$QUERY" \
                 --data-urlencode "orientation=$ORIENTATION" | jq -r '.urls.full')

# Download the image
curl -o "$IMAGE_PATH" "$IMAGE_URL"

# Set the wallpaper using feh
feh --bg-fill "$IMAGE_PATH"
