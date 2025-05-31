# Yuzu Automated Build Guide for Windows

This guide provides instructions on how to compile a customized version of the Yuzu Nintendo Switch emulator on Windows 10/11 using Visual Studio 2022, leveraging the provided automation scripts.

## Overview

The build process is broken down into several steps, each facilitated by one or more scripts:

1.  **Install Prerequisites**: Installs essential tools like Visual Studio 2022, CMake, Vulkan SDK, and Git.
2.  **Setup MSYS2 Environment**: Configures MSYS2 and installs MinGW packages needed for some Yuzu dependencies.
3.  **Clone Yuzu Source Code**: Downloads the Yuzu source code and its submodules.
4.  **Configure CMake**: Generates the Visual Studio project files for Yuzu.
5.  **Build Yuzu**: Compiles the Yuzu executable.

## Scripts Provided

The following scripts are provided to automate the build process:

*   `install_prerequisites.ps1`: PowerShell script to install core development tools (Visual Studio, CMake, Vulkan SDK, Git) and add them to PATH.
*   `setup_msys2.sh`: Bash script to set up MSYS2, install dependencies via pacman, and configure PATH within MSYS2.
*   `clone_yuzu.sh`: Bash script to clone the Yuzu repository and initialize its submodules.
*   `configure_cmake.bat`: Windows Batch script to run CMake and generate the Visual Studio solution (`yuzu.sln`).
*   `build_yuzu.ps1`: PowerShell script to compile Yuzu using MSBuild, with logic to handle common issues like the Unicorn library build.
*   `TROUBLESHOOTING_AND_CUSTOMIZATION.md`: Provides solutions for common errors and guidance for custom modifications.

## Step-by-Step Instructions

### Step 1: Install Prerequisites

1.  Open PowerShell **as Administrator**.
2.  Navigate to the directory where you saved the scripts.
3.  Run the `install_prerequisites.ps1` script:
    ```powershell
    .\install_prerequisites.ps1
    ```
4.  This script will use `winget` to download and install Visual Studio 2022 Community (with C++ workload), CMake, Vulkan SDK, and Git for Windows. It will also attempt to update your system PATH. You might need to restart your terminal or PC for all PATH changes to take effect.

### Step 2: Setup MSYS2 Environment

1.  **Install MSYS2**: If you haven't already, download and install MSYS2 from [https://www.msys2.org/](https://www.msys2.org/). Follow their installation instructions.
2.  **Run the Script**: Open an MSYS2 MinGW 64-bit terminal.
3.  Navigate to the directory where you saved the `setup_msys2.sh` script.
4.  Make the script executable (if needed) and run it:
    ```bash
    chmod +x setup_msys2.sh
    ./setup_msys2.sh
    ```
5.  This script will update MSYS2, install necessary MinGW packages, and configure the PATH within your MSYS2 environment by modifying `~/.bashrc`.
6.  After the script finishes, **close and reopen your MSYS2 terminal** or source the `.bashrc` file (`source ~/.bashrc`) for the changes to take effect.

### Step 3: Clone Yuzu Source Code

1.  Open an MSYS2 MinGW 64-bit terminal (or Git Bash, or any terminal where `git` is in the PATH).
2.  Navigate to the directory where you want to download the Yuzu source code.
3.  Copy `clone_yuzu.sh` to this directory or provide the full path to it.
4.  Make the script executable (if needed) and run it:
    ```bash
    chmod +x clone_yuzu.sh
    ./clone_yuzu.sh
    ```
5.  This will clone the Yuzu repository into a `yuzu` subdirectory and initialize all its submodules.

### Step 4: Configure CMake for Yuzu

1.  **Open a Developer Command Prompt for VS 2022**. This is important as it sets up the necessary environment variables for Visual Studio, including the compiler. (Alternatively, ensure your standard Command Prompt or PowerShell has the MSVC compiler, CMake, etc., in its PATH correctly).
2.  Navigate to the `yuzu` directory created in Step 3.
3.  Copy `configure_cmake.bat` into this `yuzu` directory.
4.  Run the script:
    ```batch
    .\configure_cmake.bat
    ```
5.  This will create a `build` subdirectory inside `yuzu` and run CMake to generate the `yuzu.sln` Visual Studio solution file and other project files within it.
6.  If CMake fails, check the `build\CMakeFiles\CMakeError.log` and `build\CMakeFiles\CMakeOutput.log` files for details.

### Step 5: Build Yuzu

1.  You can build Yuzu directly in Visual Studio 2022 by opening `yuzu\build\yuzu.sln`, selecting the `yuzu` (or `yuzu-cmd`) project as the startup project, choosing the `Release` configuration, and building.
2.  Alternatively, use the provided PowerShell script for a command-line build:
    *   Open PowerShell (a regular one is fine, does not need to be admin unless PATH issues persist).
    *   Navigate to the `yuzu` repository root.
    *   Copy `build_yuzu.ps1` into this `yuzu` directory.
    *   Run the script:
        ```powershell
        .\build_yuzu.ps1
        ```
    *   To build `yuzu-cmd` (the command-line version):
        ```powershell
        .\build_yuzu.ps1 -TargetProject "yuzu-cmd"
        ```
3.  The script uses MSBuild to compile the project in `Release` mode. It also includes logic to try and build the `unicorn-build` target first if common errors related to it occur.

## Output Files

*   **Compiled Executables**:
    *   `yuzu.exe` (GUI version) or `yuzu-cmd.exe` (command-line version) will be located in the `yuzu\build\bin\Release\` directory after a successful build.
*   **Build Logs**:
    *   CMake logs: `yuzu\build\CMakeFiles\CMakeError.log` and `yuzu\build\CMakeFiles\CMakeOutput.log`.
    *   MSBuild output is shown in the console. The `build_yuzu.ps1` script may save temporary logs (`msbuild_output.log`, `msbuild_error.log`) in the `yuzu\build` directory if it attempts the Unicorn fallback build.

## Required DLLs for Running Yuzu

If you intend to run the compiled `yuzu.exe` or `yuzu-cmd.exe` on a system that doesn't have the full development environment or all dependencies installed system-wide, you might need to copy some DLLs into the same directory as the executable (`yuzu\build\bin\Release\`).

The Yuzu build system, particularly when using `YUZU_USE_BUNDLED_VCPKG=ON`, is designed to minimize external dependencies or package them correctly. Vcpkg often copies required DLLs to the output directory.

Commonly required libraries (many of which vcpkg should handle):
*   **Vulkan**: `vulkan-1.dll`. This is typically installed with your graphics drivers and the Vulkan SDK. Ensure your system has up-to-date graphics drivers.
*   **SDL2**: `SDL2.dll`.
*   **Qt5**: If building the GUI version (`yuzu.exe`), various Qt DLLs like `Qt5Core.dll`, `Qt5Gui.dll`, `Qt5Widgets.dll`, and platform plugins (e.g., `platforms\qwindows.dll`) might be needed. Vcpkg usually places these in the output directory.
*   **FFmpeg**: `avcodec-XX.dll`, `avformat-XX.dll`, `avutil-XX.dll`, etc. (where XX is a version number).
*   **Microsoft Visual C++ Redistributable**: `VCRUNTIME140.dll`, `MSVCP140.dll`, etc. The target machine should have the "Visual C++ Redistributable for Visual Studio 2015-2022" installed. The `install_prerequisites.ps1` script for VCRUNTIME140_1.dll (via winget) might cover this, or you can download it from [Microsoft's website](https://aka.ms/vs/17/release/vc_redist.x64.exe).

**Recommendation**: After building, check the `yuzu\build\bin\Release\` directory. Many necessary DLLs provided by vcpkg (like those for SDL2, Qt5, FFmpeg, Boost, etc.) should be automatically copied there by the build process. For others like Vulkan and MSVC runtime, system-wide installation is preferred.

## Troubleshooting

Refer to `TROUBLESHOOTING_AND_CUSTOMIZATION.md` for common build errors, their solutions, and guidance on applying custom modifications.
