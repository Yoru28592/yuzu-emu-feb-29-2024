@echo off
setlocal

REM --- Script Start ---
echo ----------------------------------------
echo Starting CMake configuration for Yuzu...
echo ----------------------------------------
echo.

REM 1. Navigate to Yuzu Directory (Script assumes it's in the Yuzu repo root)
REM    No explicit cd needed if script is in yuzu repo root, commands will run relative to it.
REM    To be safe, let's ensure we are in the script's directory.
cd /D "%~dp0"
echo Current directory: %CD%
echo.

REM 2. Create Build Directory
echo Creating build directory (if it doesn't exist)...
if not exist build (
    mkdir build
    if errorlevel 1 (
        echo ERROR: Failed to create build directory.
        goto :error_exit
    )
    echo Build directory created.
) else (
    echo Build directory already exists.
)
echo.

echo Changing to build directory...
cd build
if errorlevel 1 (
    echo ERROR: Failed to change to build directory.
    goto :error_exit
)
echo Current directory: %CD%
echo.

REM 3. Run CMake
echo Running CMake configuration...
echo Command: cmake .. -G "Visual Studio 17 2022" -A x64 -DYUZU_USE_BUNDLED_VCPKG=ON -DYUZU_TESTS=OFF
echo.
cmake .. -G "Visual Studio 17 2022" -A x64 -DYUZU_USE_BUNDLED_VCPKG=ON -DYUZU_TESTS=OFF

REM 4. Error Handling for CMake
if errorlevel 1 (
    echo ----------------------------------------
    echo ERROR: CMake configuration failed!
    echo ----------------------------------------
    echo Please check the messages above for details.
    echo Review CMakeError.log and CMakeOutput.log in the '%CD%' directory for more information.
    goto :error_exit
)

echo.
echo ----------------------------------------
echo CMake configuration completed successfully!
echo ----------------------------------------
echo You can now open the Yuzu.sln file in the '%CD%' directory with Visual Studio 2022
echo or build from the command line using: msbuild Yuzu.sln /p:Configuration=Release /p:Platform=x64
echo.
goto :end_script

:error_exit
echo.
echo Script finished with errors.
echo.
pause
exit /b 1

:end_script
echo.
echo Script finished successfully.
echo.
pause
exit /b 0
