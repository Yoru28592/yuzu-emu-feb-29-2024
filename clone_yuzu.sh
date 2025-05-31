#!/bin/bash

# Function for logging
log_message() {
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

# Function to handle errors
handle_error() {
    echo "Error: $1"
    echo "Exiting script."
    exit 1
}

# --- Script Start ---
log_message "Starting Yuzu repository clone script..."

# 1. Clone Yuzu Repository
log_message "Cloning Yuzu repository (https://github.com/yuzu-emu/yuzu.git)..."
git clone https://github.com/yuzu-emu/yuzu.git
if [ $? -ne 0 ]; then
    handle_error "Failed to clone the Yuzu repository."
fi
log_message "Repository cloned successfully."

# Change directory into the cloned repository
log_message "Changing directory to 'yuzu'..."
cd yuzu
if [ $? -ne 0 ]; then
    # This error is less likely if clone succeeded but good practice to check
    handle_error "Failed to change directory to 'yuzu'. Make sure the repository was cloned correctly."
fi
log_message "Successfully changed directory to 'yuzu'."

# 2. Initialize Submodules
log_message "Initializing and updating submodules..."
git submodule update --init --recursive
if [ $? -ne 0 ]; then
    handle_error "Failed to initialize and update submodules."
fi
log_message "Submodules initialized and updated successfully."

log_message "Yuzu repository clone script finished successfully."
echo "Current directory: $(pwd)"
echo "You are now in the yuzu repository directory with submodules initialized."
