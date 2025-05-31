#!/bin/bash

# Function for logging
log_message() {
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

# --- Script Start ---
log_message "Starting MSYS2 setup script..."

# 1. Update MSYS2
log_message "Updating MSYS2 (first pass)..."
pacman -Syu --noconfirm
if [ $? -ne 0 ]; then
    echo "Error during first MSYS2 update. Please check the output."
    # It's often recommended to close the terminal and restart if pacman -Syu updates pacman itself.
    # However, for a script, we'll proceed, but note the potential issue.
fi

log_message "Updating MSYS2 (second pass)..."
pacman -Syu --noconfirm
if [ $? -ne 0 ]; then
    echo "Error during second MSYS2 update. Please check the output."
fi

# 2. Install Dependencies
log_message "Installing dependencies..."
# mingw-w64-x86_64-toolchain includes gcc, g++, etc.
# autoconf, libtool, automake-wrapper are for projects using autotools
pacman -S --needed --noconfirm \
    git \
    make \
    mingw-w64-x86_64-SDL2 \
    mingw-w64-x86_64-cmake \
    mingw-w64-x86_64-python-pip \
    mingw-w64-x86_64-qt5 \
    mingw-w64-x86_64-toolchain \
    autoconf \
    libtool \
    automake-wrapper

if [ $? -ne 0 ]; then
    echo "Error during dependency installation. Please check the output."
else
    log_message "Dependencies installation command executed."
fi

# 3. Configure PATH in .bashrc
log_message "Configuring PATH in ~/.bashrc..."

BASHRC_FILE="$HOME/.bashrc"

# Add MinGW binaries to PATH
if ! grep -q 'export PATH=/mingw64/bin:$PATH' "$BASHRC_FILE"; then
    echo "Adding MinGW to PATH in $BASHRC_FILE..."
    echo '' >> "$BASHRC_FILE" # Add a newline for separation
    echo '# Add MinGW MINGW64 environment PATH' >> "$BASHRC_FILE"
    echo 'export PATH=/mingw64/bin:$PATH' >> "$BASHRC_FILE"
else
    echo "MinGW PATH already configured in $BASHRC_FILE."
fi

# Add Vulkan SDK's glslangValidator to PATH
# Using a more robust way to handle the Vulkan SDK path, expecting it at /c/VulkanSDK/<version>/Bin
# The single quotes around the `export` command are crucial to defer evaluation of $() and $PATH
VULKAN_PATH_LINE='export PATH=$(find /c/VulkanSDK -maxdepth 2 -type d -name "Bin" -print -quit 2>/dev/null):$PATH'
# Check if a similar line for Vulkan SDK already exists. This check is basic.
if ! grep -q 'VulkanSDK.*Bin' "$BASHRC_FILE"; then
    echo "Adding Vulkan SDK (glslangValidator) to PATH in $BASHRC_FILE..."
    echo '' >> "$BASHRC_FILE" # Add a newline for separation
    echo '# Add Vulkan SDK glslangValidator to PATH (typically C:\VulkanSDK\<version>\Bin)' >> "$BASHRC_FILE"
    echo "$VULKAN_PATH_LINE" >> "$BASHRC_FILE"
else
    echo "Vulkan SDK PATH seems to be already configured in $BASHRC_FILE."
fi

log_message "MSYS2 setup script finished."
echo "Please source your ~/.bashrc or open a new MSYS2 terminal for changes to take effect:"
echo "  source ~/.bashrc"
