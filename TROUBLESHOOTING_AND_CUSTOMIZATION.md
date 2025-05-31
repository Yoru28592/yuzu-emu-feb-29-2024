# Yuzu Build Troubleshooting and Customization Guide

This guide provides solutions to common issues encountered when building Yuzu and offers suggestions for applying custom modifications.

## Common Build Errors and Solutions

### 1. Missing Dependencies / Submodule Issues
*   **Symptom**: CMake errors related to missing headers or libraries, build failures for specific components.
*   **Solution**:
    *   Ensure all Git submodules are initialized and updated. After cloning Yuzu, or if you suspect submodule issues, run the following commands in the Yuzu repository root:
        ```bash
        git submodule update --init --recursive
        ```
    *   The `clone_yuzu.sh` script handles this automatically.
    *   Make sure you are using the `-DYUZU_USE_BUNDLED_VCPKG=ON` flag when running CMake. This tells Yuzu to use its bundled vcpkg instance to download and build many dependencies. The `configure_cmake.bat` script includes this.

### 2. Vulkan Errors
*   **Symptom**: CMake errors related to Vulkan, Yuzu fails to start with Vulkan errors, or graphics issues.
*   **Solution**:
    *   **Verify Vulkan SDK Installation**: Ensure the Vulkan SDK is correctly installed. The `install_prerequisites.ps1` script automates this. You can download it from [https://vulkan.lunarg.com/](https://vulkan.lunarg.com/).
    *   **glslangValidator in PATH**: The `glslangValidator.exe` (part of the Vulkan SDK) must be in your system's PATH. The `install_prerequisites.ps1` (for system PATH) and `setup_msys2.sh` (for MSYS2 PATH) scripts attempt to configure this. You can verify by opening a command prompt and typing `glslangValidator --version`.
    *   **Test with Yuzu**: After installation, open Yuzu, go to `Emulation > Configure > Graphics`, select `Vulkan` as the API, and see if your GPU is listed and no errors appear.

### 3. VCRUNTIME140_1.dll Missing
*   **Symptom**: Error message "The code execution cannot proceed because VCRUNTIME140_1.dll was not found." when trying to run Yuzu.
*   **Solution**: Install the latest Microsoft Visual C++ Redistributable (x64). Download it from [https://aka.ms/vs/17/release/vc_redist.x64.exe](https://aka.ms/vs/17/release/vc_redist.x64.exe).

### 4. Shader-Related Issues in Yuzu
*   **Symptom**: Graphics glitches, incorrect rendering, or shader compilation errors within Yuzu.
*   **Solution**: Ensure Yuzu is configured to use Vulkan:
    1.  Open Yuzu.
    2.  Go to `Emulation > Configure > Graphics`.
    3.  Set the `API` to `Vulkan`.
    4.  Ensure the correct `Device` (your GPU) is selected.

### 5. CMake Configuration Fails
*   **Symptom**: The `configure_cmake.bat` script fails, or running CMake manually results in errors.
*   **Solution**:
    *   Open the `CMakeError.log` and `CMakeOutput.log` files located in the `yuzu/build/CMakeFiles/` directory. These logs contain detailed error messages from CMake that can help pinpoint the issue.
    *   **Common Causes**:
        *   **Missing Tools**: CMake, a C++ compiler (from Visual Studio), or Git might not be correctly installed or added to the PATH. The `install_prerequisites.ps1` script aims to handle this. Ensure you run it as administrator.
        *   **Submodule Issues**: As mentioned in point 1, ensure submodules are up to date.
        *   **Incorrect Generator**: Ensure the CMake generator (`-G "Visual Studio 17 2022"`) matches your Visual Studio version.
        *   **Environment**: Try running `configure_cmake.bat` from a "Developer Command Prompt for VS 2022" to ensure all Visual Studio-related environment variables are set.

### 6. Build Fails (Especially `unicorn.a` or `unicorn.lib` not found)
*   **Symptom**: The build process (using `build_yuzu.ps1` or Visual Studio) fails with errors like "cannot open input file 'unicorn.lib'", "LNK1181", or messages about missing `unicorn.a`.
*   **Solution**:
    *   The `unicorn` library is a submodule that needs to be compiled first.
    *   The `build_yuzu.ps1` script attempts to automatically handle this by first building the `unicorn-build` target and then retrying the main Yuzu build.
    *   **Manual Fix (Visual Studio)**:
        1.  Open `yuzu.sln` in Visual Studio 2022.
        2.  In the Solution Explorer, find the `unicorn-build` project.
        3.  Right-click on `unicorn-build` and select `Build`.
        4.  Once it completes successfully, right-click on the `yuzu` (or `yuzu-cmd`) project and select `Build` or `Rebuild`.

## Customization Support

This section provides guidance on how to apply custom modifications to your Yuzu build.

### 1. Applying Patches
If you have custom changes in the form of `.patch` files:
1.  Navigate to the Yuzu repository root in your terminal/command prompt.
2.  Ensure the patch file is in a location accessible by your terminal.
3.  Apply the patch using Git:
    ```bash
    git apply /path/to/your/patchfile.patch
    ```
4.  If the patch applies cleanly, you can proceed to configure and build Yuzu as usual. If there are conflicts, you may need to resolve them manually.
5.  To incorporate this into the automated scripts, you could add the `git apply` command to `clone_yuzu.sh` after the submodules are updated, or create a new script that applies patches before running `configure_cmake.bat`.

### 2. Modifying Build Scripts for Custom Changes
The provided scripts (`configure_cmake.bat`, `build_yuzu.ps1`) can be modified:
*   **CMake Flags**: To add custom CMake definitions (e.g., for experimental features or different optimizations), modify the `cmake ..` line in `configure_cmake.bat`.
*   **Pre-build Steps**: If you need to run custom scripts or commands before compilation (like applying patches), add them to `build_yuzu.ps1` before the MSBuild commands.

### 3. Suggested Optimizations (Advanced)

*   **Enable AVX-512 (or other CPU-specific instructions)**:
    *   This requires a CPU that supports these instruction sets.
    *   You might be able to pass CPU architecture flags via CMake to the compiler. For example, you could try adding something like `-DCMAKE_CXX_FLAGS="-march=native"` or specific AVX flags to the `cmake` command in `configure_cmake.bat`.
    *   **Caution**: This can make the compiled binary less portable (it might not run on CPUs without AVX-512). This is an advanced modification and requires understanding compiler flags. The Yuzu project may already have options for this or it might be managed by the dynarmic submodule.

*   **Modifying the Shader Decompiler**:
    *   This is a highly advanced task requiring in-depth knowledge of Yuzu's source code, GPU shader languages, and reverse engineering.
    *   If you intend to make such modifications, you would typically:
        1.  Identify the relevant source files within Yuzu (likely in the `video_core` or `shader_recompiler` directories).
        2.  Make your code changes.
        3.  Recompile Yuzu using the provided build scripts or Visual Studio.
    *   This level of customization is beyond simple script changes and involves direct C++ development.

Remember to always test thoroughly after applying custom modifications.
