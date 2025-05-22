<#
.SYNOPSIS
    Automates the process of cloning/updating the yuzu source, configuring with CMake, and building using MSBuild.
.DESCRIPTION
    This script helps automate parts of the native Windows build process for the yuzu emulator.
    It handles:
    1. Cloning the yuzu repository (if it doesn't exist) or updating an existing repository.
    2. Configuring the project using CMake with recommended settings.
    3. Building the project using MSBuild (or cmake --build).

    IMPORTANT: This script ASSUMES you have already installed all necessary prerequisites
    as detailed in the BUILDING_WINDOWS.md guide. This includes:
    - Visual Studio (2019 or 2022) with "Desktop development with C++" workload and C++ CMake tools.
    - Git for Windows.
    - CMake (standalone, if not using VS version).
    - Vulkan SDK.
.NOTES
    Author: AI Assistant
    Date: $(Get-Date -Format yyyy-MM-dd)
#>

# Strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop" # Stop on first error

# --- Introduction and Disclaimer ---
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "yuzu Native Windows Build Automation Script" -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "This script will guide you through cloning/updating yuzu, configuring with CMake, and building it."
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Magenta
Write-Host "Please ensure you have installed all prerequisites as outlined in BUILDING_WINDOWS.md."
Write-Host "This includes Visual Studio, Git, CMake, and the Vulkan SDK."
Write-Host "This script does NOT install these for you."
Write-Host ""
try {
    Read-Host "Press Enter to continue if you have all prerequisites installed, or Ctrl+C to exit"
} catch [System.Management.Automation.ActionPreferenceStopException] {
    Write-Host "Script aborted by user."
    exit 2
}
Write-Host ""

# --- Helper Functions ---
function Test-GitInstalled {
    try {
        git --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-CMakeInstalled {
    try {
        cmake --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

# --- Prerequisite Checks ---
Write-Host "Checking for essential tools (Git and CMake)..."
if (-not (Test-GitInstalled)) {
    Write-Error "Git does not appear to be installed or accessible in your PATH. Please install Git for Windows from https://git-scm.com/download/win and ensure it's added to your PATH."
    exit 1
} else {
    Write-Host "Git found." -ForegroundColor Green
}

if (-not (Test-CMakeInstalled)) {
    Write-Error "CMake does not appear to be installed or accessible in your PATH. Please install CMake from https://cmake.org/download/ and ensure it's added to your PATH (or that Visual Studio's CMake is in PATH)."
    exit 1
} else {
    Write-Host "CMake found." -ForegroundColor Green
}
Write-Host ""


# --- User Inputs ---

# 1. Source Directory
$defaultSourceDir = Join-Path $PSScriptRoot "yuzu" # Suggest a directory named 'yuzu' where the script is located
$sourceDirPrompt = "Enter the directory for yuzu source code (Default: '$defaultSourceDir')"
$sourceDir = Read-Host $sourceDirPrompt
if ([string]::IsNullOrWhiteSpace($sourceDir)) {
    $sourceDir = $defaultSourceDir
}

# Attempt to resolve the path. If it's relative, make it absolute.
try {
    $sourceDir = Resolve-Path $sourceDir -ErrorAction SilentlyContinue
    if (-not $sourceDir) { # If path is invalid or doesn't exist yet (for cloning)
        $sourceDir = [System.IO.Path]::GetFullPath((Join-Path $PWD.Path $sourceDir))
    }
} catch {
    # If Resolve-Path fails for a non-existent path, construct it based on current PWD
    $sourceDir = [System.IO.Path]::GetFullPath((Join-Path $PWD.Path (Read-Host $sourceDirPrompt))) # Re-ask if initial input was problematic
     if ([string]::IsNullOrWhiteSpace($sourceDir)) { $sourceDir = $defaultSourceDir }
     $sourceDir = [System.IO.Path]::GetFullPath((Join-Path $PWD.Path $sourceDir))

}


if (Test-Path -Path $sourceDir -PathType Container) {
    Write-Host "Source directory '$sourceDir' exists."
    if (Test-Path -Path (Join-Path $sourceDir ".git") -PathType Container) {
        Write-Host "Found existing Git repository. Attempting to pull latest changes..."
        try {
            Push-Location $sourceDir
            Write-Host "Running: git pull --recurse-submodules"
            git pull --recurse-submodules
            Write-Host "Running: git submodule update --init --recursive"
            git submodule update --init --recursive
            Write-Host "Repository updated successfully." -ForegroundColor Green
            Pop-Location
        } catch {
            Write-Warning "Failed to update Git repository: $($_.Exception.Message)"
            Write-Warning "Please check for errors above. You might need to resolve merge conflicts manually or clean the directory."
            # Optionally, offer to delete and re-clone, or exit
            # exit 1 # Decided not to exit here, user might want to proceed with existing state or fix manually
        }
    } else {
        Write-Error "Directory '$sourceDir' exists but does not appear to be a Git repository (missing .git folder)."
        $choice = Read-Host "Do you want to (D)elete its contents and clone fresh, or (A)bort? (D/A)"
        if ($choice -eq 'D' -or $choice -eq 'd') {
            Write-Warning "Deleting contents of directory '$sourceDir'..."
            Get-ChildItem -Path $sourceDir -Recurse -Force | Remove-Item -Recurse -Force
            # Proceed to clone
        } else {
            Write-Host "Aborting script. Please specify a valid git repository or an empty/non-existent directory."
            exit 1
        }
        # Ensure the directory exists for cloning after deletion
        if (-not (Test-Path -Path $sourceDir -PathType Container)) {
            New-Item -Path $sourceDir -ItemType Directory -Force | Out-Null
        }
    }
}

if (-not (Test-Path -Path (Join-Path $sourceDir ".git") -PathType Container)) {
    Write-Host "Cloning yuzu into '$sourceDir'..."
    try {
        # Ensure parent directory exists if $sourceDir itself is the target for cloning (e.g. yuzu_source into C:\)
        $parentDir = Split-Path $sourceDir
        if ($parentDir -and (-not (Test-Path $parentDir))) {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }
        git clone --recursive https://github.com/yuzu-emu/yuzu.git $sourceDir
        Write-Host "yuzu cloned successfully into '$sourceDir'." -ForegroundColor Green
    } catch {
        Write-Error "Failed to clone yuzu: $($_.Exception.Message)"
        exit 1
    }
}

# 2. Build Directory
$defaultBuildDir = Join-Path $sourceDir "build"
$buildDir = Read-Host "Enter the directory for build files (Default: '$defaultBuildDir')"
if ([string]::IsNullOrWhiteSpace($buildDir)) {
    $buildDir = $defaultBuildDir
}
$buildDir = Resolve-Path $buildDir -ErrorAction SilentlyContinue # Normalize path if it exists
if (-not $buildDir) { # If path is invalid or doesn't exist yet
    $buildDir = [System.IO.Path]::GetFullPath((Join-Path $sourceDir "build")) # Sensible default if input was odd
}


if (-not (Test-Path -Path $buildDir -PathType Container)) {
    Write-Host "Build directory '$buildDir' does not exist. Creating..."
    try {
        New-Item -Path $buildDir -ItemType Directory -Force | Out-Null
        Write-Host "Build directory created successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to create build directory '$buildDir': $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "Using existing build directory '$buildDir'."
}

# 3. Visual Studio Version (for CMake Generator)
$vsVersions = @{
    "2022" = "Visual Studio 17 2022"
    "2019" = "Visual Studio 16 2019"
}
$vsYearDefault = "2022" 
$vsYear = $vsYearDefault

# Check for available VS instances (optional advanced check)
# $vsInstances = try { & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion } catch { Write-Warning "vswhere.exe not found or failed."; "" }
# if ($vsInstances -match "^17\.") { $vsYear = "2022" } elseif ($vsInstances -match "^16\.") { $vsYear = "2019" }

$vsChoicePrompt = "Enter Visual Studio year for CMake generator (2019 or 2022, Default: $vsYear)"
$vsChoice = Read-Host $vsChoicePrompt
if ($vsVersions.ContainsKey($vsChoice)) {
    $vsYear = $vsChoice
} elseif (-not [string]::IsNullOrWhiteSpace($vsChoice)) {
    Write-Warning "Invalid selection '$vsChoice'. Using default VS $vsYear."
}
$cmakeGenerator = $vsVersions[$vsYear]

Write-Host "Using CMake generator: '$cmakeGenerator'"
Write-Host ""

# --- CMake Configuration ---
Write-Host "---------------------" -ForegroundColor Cyan
Write-Host "Configuring CMake..." -ForegroundColor Cyan
Write-Host "---------------------" -ForegroundColor Cyan

Push-Location $buildDir

$cmakeArgs = @(
    "..", # Source directory relative to build directory
    "-G", $cmakeGenerator,
    "-A", "x64", # Specify x64 platform
    "-DYUZU_USE_BUNDLED_VCPKG=ON",
    "-DENABLE_QT=ON", 
    "-DYUZU_USE_BUNDLED_QT=ON",
    "-DYUZU_USE_BUNDLED_SDL2=ON",
    "-DYUZU_USE_BUNDLED_FFMPEG=ON",
    "-DYUZU_TESTS=OFF" # Typically disable tests for a user build
    # Consider adding: -DCMAKE_BUILD_TYPE=Release (though usually set at build time)
)

Write-Host "Running CMake in '$((Get-Location).Path)' with arguments:"
Write-Host "cmake $($cmakeArgs -join ' ')"

try {
    if (-not (Test-Path Env:VULKAN_SDK)) {
        Write-Warning "VULKAN_SDK environment variable not found. CMake configuration might fail if Vulkan is not found by other means."
        Write-Warning "Please ensure the Vulkan SDK is installed and its 'Bin' directory (or equivalent) is in your PATH, or VULKAN_SDK is set."
    }

    cmake $cmakeArgs
    Write-Host "CMake configuration successful." -ForegroundColor Green
} catch {
    Write-Error "CMake configuration failed: $($_.Exception.Message)"
    Write-Warning "Ensure Visual Studio C++ workload (MSVC) and Vulkan SDK are correctly installed."
    Write-Warning "You can check detailed logs in '$buildDir\CMakeFiles\CMakeOutput.log' and '$buildDir\CMakeFiles\CMakeError.log'."
    Pop-Location
    exit 1
}
Write-Host ""

# --- Build Execution ---
Write-Host "-----------------" -ForegroundColor Cyan
Write-Host "Building yuzu..." -ForegroundColor Cyan
Write-Host "-----------------" -ForegroundColor Cyan

$startBuildChoice = Read-Host "Do you want to start the build now? (Y/N, Default: Y)"
if ($startBuildChoice -ne "N" -and $startBuildChoice -ne "n") {
    Write-Host "Starting build (Release configuration)... This may take a long time."
    $buildStartTime = Get-Date
    try {
        # Using cmake --build is generally preferred
        Write-Host "Running: cmake --build . --config Release -- /m"
        cmake --build . --config Release -- /m 
        # The "/m" switch is passed to MSBuild for parallel compilation.

        $buildEndTime = Get-Date
        $buildDuration = $buildEndTime - $buildStartTime
        Write-Host "Build completed successfully in $($buildDuration.ToString())!" -ForegroundColor Green
        $exePath = Join-Path $buildDir 'bin\Release\yuzu.exe'
        Write-Host "Executable should be available at: '$exePath'"
        if (-not (Test-Path $exePath)) {
             Write-Warning "yuzu.exe not found at the expected location. Check build output for errors."
        }
    } catch {
        Write-Error "Build failed: $($_.Exception.Message)"
        Write-Error "Check the output above for specific compilation errors. If it mentions missing SDKs or tools, ensure your Visual Studio installation is complete."
        Pop-Location
        exit 1
    }
} else {
    Write-Host "Build skipped. You can manually build by:"
    Write-Host "1. Opening '$buildDir\yuzu.sln' in Visual Studio $vsYear and building the 'yuzu' project (Release configuration)."
    Write-Host "2. Or running the command: cmake --build . --config Release"
    Write-Host "   from the '$buildDir' directory in a command prompt that has MSBuild in its PATH (e.g., Developer Command Prompt for VS $vsYear)."
}

Pop-Location
Write-Host ""
Write-Host "Script finished." -ForegroundColor Green
Write-Host "If the build was successful, you can find yuzu.exe in '$buildDir\bin\Release\'"
Write-Host "Ensure all runtime dependencies (like Vulkan, MSVC Runtimes) are installed on any system where you run this custom build."
Write-Host "The bundled options used in this script should minimize external DLL issues for yuzu's direct dependencies."

# End of Script
```
