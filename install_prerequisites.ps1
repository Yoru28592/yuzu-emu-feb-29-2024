#Requires -RunAsAdministrator

# Function to check if a command exists
function Test-CommandExists {
    param (
        [string]$command
    )
    return (Get-Command $command -ErrorAction SilentlyContinue) -ne $null
}

# Function to add a directory to the system PATH if it's not already there
function Add-ToSystemPath {
    param (
        [string]$directory
    )
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    if (-not ($currentPath -split ';' -contains $directory)) {
        Write-Host "Adding $directory to system PATH..."
        $newPath = "$currentPath;$directory"
        [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        Write-Host "$directory added to system PATH. Please restart your terminal for changes to take effect."
    } else {
        Write-Host "$directory is already in the system PATH."
    }
}

# --- Script Start ---
Write-Host "Starting prerequisite installation script..."

# 1. Administrator Check
Write-Host "Checking for administrator privileges..."
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Administrator privileges are required to run this script. Please re-run as Administrator."
    exit 1
}
Write-Host "Running with administrator privileges."

# 2. Visual Studio 2022 Community Installation
Write-Host "Attempting to install Visual Studio 2022 Community..."
try {
    winget install Microsoft.VisualStudio.2022.Community --override "--add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended" --accept-package-agreements --accept-source-agreements
    if ($?) {
        Write-Host "Visual Studio 2022 Community installation command executed. Winget will handle actual installation/update."
    } else {
        Write-Warning "Winget command for Visual Studio 2022 Community might have failed or it was already installed."
    }
} catch {
    Write-Warning "An error occurred during Visual Studio 2022 Community installation: $($_.Exception.Message)"
}

# 3. CMake Installation
Write-Host "Attempting to install CMake..."
try {
    winget install Kitware.CMake --accept-package-agreements --accept-source-agreements
    if ($?) {
        Write-Host "CMake installation command executed. Winget will handle actual installation/update."
        # Find CMake installation path and add to PATH
        # Common paths, try Program Files first, then Program Files (x86)
        $cmakePath варианты = @(
            "${env:ProgramFiles}\CMake\bin",
            "${env:ProgramW6432}\CMake\bin",
            "${env:LOCALAPPDATA}\Programs\CMake\bin"
        )
        $cmakeBinDir = $null
        foreach ($path_variant in $cmakePath варианты) {
            if (Test-Path $path_variant) {
                $cmakeBinDir = $path_variant
                break
            }
        }

        if ($cmakeBinDir) {
            Write-Host "CMake found at $cmakeBinDir"
            Add-ToSystemPath -directory $cmakeBinDir
        } else {
            Write-Warning "Could not automatically find CMake installation directory to add to PATH. Please add it manually if needed."
        }
    } else {
        Write-Warning "Winget command for CMake might have failed or it was already installed."
    }
} catch {
    Write-Warning "An error occurred during CMake installation: $($_.Exception.Message)"
}

# 4. Vulkan SDK Installation
Write-Host "Attempting to install Vulkan SDK..."
try {
    winget install LunarG.VulkanSDK --accept-package-agreements --accept-source-agreements
    if ($?) {
        Write-Host "Vulkan SDK installation command executed. Winget will handle actual installation/update."
        # Find Vulkan SDK installation path and add Bin directory to PATH
        # Vulkan SDK path often includes the version number, e.g., C:\VulkanSDK\1.3.261.1
        $vulkanBaseDir = "C:\VulkanSDK"
        if (Test-Path $vulkanBaseDir) {
            $sdkVersions = Get-ChildItem -Path $vulkanBaseDir -Directory | Sort-Object Name -Descending
            if ($sdkVersions) {
                $latestSdkDir = $sdkVersions[0].FullName
                $vulkanBinDir = Join-Path -Path $latestSdkDir -ChildPath "Bin"
                if (Test-Path $vulkanBinDir) {
                    Write-Host "Vulkan SDK Bin directory found at $vulkanBinDir"
                    Add-ToSystemPath -directory $vulkanBinDir
                } else {
                     Write-Warning "Could not find Bin directory in $latestSdkDir. Please add Vulkan SDK's Bin directory to PATH manually."
                }
            } else {
                Write-Warning "Could not find any versioned Vulkan SDK directory in $vulkanBaseDir. Please add Vulkan SDK's Bin directory to PATH manually."
            }
        } else {
             Write-Host "'C:\VulkanSDK' not found. This is the expected base installation directory for Vulkan SDK. If installed elsewhere, please add its Bin directory to PATH manually."
        }
    } else {
        Write-Warning "Winget command for Vulkan SDK might have failed or it was already installed."
    }
} catch {
    Write-Warning "An error occurred during Vulkan SDK installation: $($_.Exception.Message)"
}

# 5. Git for Windows Installation
Write-Host "Attempting to install Git for Windows..."
try {
    winget install Git.Git --accept-package-agreements --accept-source-agreements
    if ($?) {
        Write-Host "Git for Windows installation command executed. Winget typically handles PATH setup for Git."
    } else {
        Write-Warning "Winget command for Git for Windows might have failed or it was already installed."
    }
} catch {
    Write-Warning "An error occurred during Git for Windows installation: $($_.Exception.Message)"
}

Write-Host "Prerequisite installation script finished."
Write-Host "Important: You may need to restart your terminal or system for all PATH changes to take full effect."
