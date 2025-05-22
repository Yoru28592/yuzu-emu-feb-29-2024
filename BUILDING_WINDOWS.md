# Building yuzu on Windows

## Introduction

This document provides instructions for building the yuzu emulator on Windows. yuzu uses CMake as its build system and can be compiled using Microsoft Visual Studio.

While an official guide exists on the [yuzu GitHub Wiki](https://github.com/yuzu-emu/yuzu/wiki/Building-for-Windows), this guide is based on direct inspection of the yuzu build system and aims to provide a comprehensive overview for users who prefer to build from source.

## Prerequisites

Before you begin, ensure you have the following software installed:

*   **Visual Studio:**
    *   Visual Studio 2019 or 2022 (Community Edition is sufficient).
    *   Install the "Desktop development with C++" workload.
    *   Ensure the following components are included:
        *   The latest MSVC v142 - VS 2019 C++ x64/x86 build tools (or MSVC v143 for VS 2022).
        *   C++ CMake tools for Windows.
    *   The Debug Interface Access (DIA) SDK is required for Breakpad crash reporting. This is typically included with the C++ workload.
*   **Git for Windows:**
    *   Download and install from [git-scm.com](https://git-scm.com/download/win).
    *   This is required for cloning the yuzu repository and its submodules.
*   **CMake:**
    *   The latest stable version is recommended.
    *   While Visual Studio's C++ workload may include a version of CMake, a standalone installation from [cmake.org](https://cmake.org/download/) is also fine and sometimes preferred for using the CMake GUI.
*   **Vulkan SDK:**
    *   Download and install the Vulkan SDK from [LunarG](https://www.lunarg.com/vulkan-sdk/).
    *   A specific version like 1.3.250.1 has been noted in yuzu's build scripts, but the latest version from LunarG should generally work. If you encounter issues, you can try installing this specific version.
*   **Python (Optional):**
    *   While not strictly required for building, Python (version 3.x) is useful for various utility scripts that may be part of the development process or for troubleshooting. Download from [python.org](https://www.python.org/downloads/).

## Cloning the Repository

1.  Open Git Bash (or your preferred command-line interface with Git).
2.  Navigate to the directory where you want to clone the yuzu repository.
3.  Run the following command to clone yuzu and its submodules:

    ```bash
    git clone --recursive https://github.com/yuzu-emu/yuzu.git
    ```
    The `--recursive` flag is crucial as it initializes and clones all necessary submodules (like `dynarmic`, `mFAST`, etc.). If you forget this flag, you can initialize submodules later by running `git submodule update --init --recursive` from within the `yuzu` directory.

## Configuring with CMake

CMake is used to generate the Visual Studio solution files. You can use either the CMake GUI or the command-line interface.

**Using CMake GUI:**

1.  Launch CMake GUI.
2.  **"Where is the source code":** Browse to the directory where you cloned yuzu (e.g., `C:/path/to/yuzu`).
3.  **"Where to build the binaries":** Create a new directory for the build files. It's good practice to create a separate build directory (e.g., `C:/path/to/yuzu/build` or `C:/path/to/yuzu-build`).
4.  Click **"Configure"**.
5.  A dialog will appear asking you to specify the generator for this project. Select your Visual Studio version:
    *   For Visual Studio 2019: "Visual Studio 16 2019"
    *   For Visual Studio 2022: "Visual Studio 17 2022"
    *   Ensure "x64" is selected for the platform if available as a separate option, or that the generator name implies it.
6.  Leave "Optional toolset to use" empty unless you have specific reasons to change it.
7.  Click **"Finish"**.
8.  CMake will process the `CMakeLists.txt` file and display various options. For a standard Windows build, the following default options are generally recommended:
    *   `YUZU_USE_BUNDLED_VCPKG=ON`: This tells CMake to use yuzu's internal vcpkg instance to automatically download and build most external dependencies. This greatly simplifies dependency management.
    *   `YUZU_USE_BUNDLED_QT=ON`: Uses a bundled version of Qt.
    *   `YUZU_USE_BUNDLED_SDL2=ON`: Uses a bundled version of SDL2.
    *   `YUZU_USE_BUNDLED_FFMPEG=ON`: Uses a bundled version of FFmpeg.
9.  The first time you configure, CMake (via vcpkg) will download and build several libraries. This process can take a significant amount of time and requires an internet connection. Subsequent configurations will be much faster.
10. Once the initial configuration is done and all options are set, click **"Generate"**. This will create the `yuzu.sln` file and associated project files in your specified build directory.

**Using Command-Line CMake:**

1.  Open Git Bash, Command Prompt, or PowerShell.
2.  Navigate to your yuzu source directory.
3.  Create a build directory and navigate into it:
    ```bash
    mkdir build
    cd build
    ```
4.  Run CMake, specifying the generator and pointing to the parent directory (source):
    *   For Visual Studio 2019:
        ```bash
        cmake .. -G "Visual Studio 16 2019" -A x64
        ```
    *   For Visual Studio 2022:
        ```bash
        cmake .. -G "Visual Studio 17 2022" -A x64
        ```
    *   You can also set CMake options directly using `-D<OPTION_NAME>=<VALUE>`:
        ```bash
        cmake .. -G "Visual Studio 17 2022" -A x64 -DYUZU_USE_BUNDLED_VCPKG=ON -DYUZU_USE_BUNDLED_QT=ON
        ```
        (Though the bundled options are typically ON by default on Windows).
5.  CMake will configure the project. As with the GUI method, the first run will bootstrap vcpkg and download dependencies, which can take time.

## Building with Visual Studio

1.  Navigate to your CMake build directory (e.g., `C:/path/to/yuzu/build`).
2.  Open the `yuzu.sln` file with Visual Studio.
3.  Select the desired build configuration from the dropdown menu in the toolbar (usually near the "Start" button):
    *   **Release:** For an optimized build, suitable for general use.
    *   **Debug:** For a build with debugging symbols, useful for development or troubleshooting.
4.  In the Solution Explorer (usually on the right-hand side), find the target you want to build:
    *   `yuzu`: Builds the yuzu emulator executable.
    *   `ALL_BUILD`: Builds all targets in the solution. This is a common choice.
5.  Right-click on the desired target and select **"Build"**.
6.  Visual Studio will compile the source code. This may take some time, especially for the first build.
7.  Once the build is complete, you can find the executables in a subdirectory corresponding to your build configuration within the `bin` folder of your build directory:
    *   Example: `C:/path/to/yuzu/build/bin/Release/yuzu.exe`
    *   Example: `C:/path/to/yuzu/build/bin/Debug/yuzu.exe`

## Troubleshooting (Optional)

Here are a few common issues and how to address them:

*   **Missing Submodules:**
    *   **Symptom:** CMake errors related to missing directories or files from submodules (e.g., `dynarmic`, `mFAST`, `renderdoc_app.h`).
    *   **Solution:** Ensure you cloned the repository with `git clone --recursive`. If you forgot, navigate to the yuzu source directory and run `git submodule update --init --recursive`.
*   **Vulkan SDK Not Found:**
    *   **Symptom:** CMake error messages like "Could NOT find Vulkan (missing: VULKAN_LIBRARY VULKAN_INCLUDE_DIR)".
    *   **Solution:**
        *   Ensure you have installed the Vulkan SDK from LunarG.
        *   Verify that the `VULKAN_SDK` environment variable is set correctly (the installer usually does this). You might need to restart CMake GUI or your command prompt after installation.
        *   If CMake still can't find it, you can manually specify `VULKAN_INCLUDE_DIR` and `VULKAN_LIBRARY` in CMake, but this is usually not necessary.
*   **CMake Errors During Configuration:**
    *   **Symptom:** Various errors during the "Configure" step in CMake.
    *   **Solution:**
        *   Read the error message carefully; it often provides clues.
        *   Ensure all prerequisites are installed correctly.
        *   If vcpkg fails to download or build a dependency, check your internet connection and try configuring again. Sometimes, temporary network issues or server outages can cause problems.
        *   Delete the CMake cache (`CMakeCache.txt` in the build directory) and the `CMakefiles` directory, then try configuring again from scratch.
*   **Build Failures in Visual Studio:**
    *   **Symptom:** Errors in the "Error List" window in Visual Studio during compilation.
    *   **Solution:**
        *   Check that your Visual Studio installation is up to date and has all the required C++ components.
        *   Ensure you have enough disk space.
        *   If the error is related to a specific library, it might indicate an issue with how that dependency was built by vcpkg or a problem with the yuzu source code itself. Try cleaning the specific project or the entire solution (`Build > Clean Solution`) and rebuilding.
        *   Look for similar issues on the yuzu GitHub issue tracker.

This guide should help you get yuzu compiled on your Windows system. Happy building!
