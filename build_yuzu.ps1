#Requires -Version 5.1

<#
.SYNOPSIS
    Builds the Yuzu project (or a specified target) using MSBuild.
    This script should be run after configure_cmake.bat has successfully generated yuzu.sln in the build directory.

.PARAMETER TargetProject
    The MSBuild target to build. Defaults to "yuzu". Can be set to "yuzu-cmd" or other valid targets.
#>
[CmdletBinding()]
param (
    [string]$TargetProject = "yuzu"
)

# Function to find MSBuild.exe using vswhere
function Get-MSBuildPath {
    try {
        $vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (-not (Test-Path $vswherePath)) {
            Write-Warning "vswhere.exe not found at $vswherePath. MSBuild might not be found."
            return $null
        }

        $vsInstallationPath = & $vswherePath -latest -property installationPath -prerelease -format Value
        if (-not $vsInstallationPath) {
            Write-Warning "Visual Studio installation path not found by vswhere."
            return $null
        }

        $msbuildPath = Join-Path -Path $vsInstallationPath -ChildPath "MSBuild\Current\Bin\MSBuild.exe"
        if (Test-Path $msbuildPath) {
            Write-Host "MSBuild found at $msbuildPath"
            return $msbuildPath
        } else {
            # Fallback for older VS versions or different MSBuild locations if Current isn't there
            $msbuildPath = Join-Path -Path $vsInstallationPath -ChildPath "MSBuild\15.0\Bin\MSBuild.exe" # VS 2017
            if (Test-Path $msbuildPath) {
                Write-Host "MSBuild found at $msbuildPath (VS 2017 location)"
                return $msbuildPath
            }
            Write-Warning "MSBuild.exe not found in common MSBuild paths within $vsInstallationPath."
            return $null
        }
    }
    catch {
        Write-Warning "An error occurred while trying to find MSBuild: $($_.Exception.Message)"
        return $null
    }
}

# --- Script Start ---
Write-Host "Starting Yuzu build script..."
Write-Host "Target project: $TargetProject"
Write-Host "This script assumes 'configure_cmake.bat' has been run and 'build/yuzu.sln' exists."
Write-Host ""

# 1. Locate MSBuild
Write-Host "Locating MSBuild.exe..."
$Global:MSBuildPath = Get-MSBuildPath
if (-not $Global:MSBuildPath) {
    Write-Error "MSBuild.exe could not be located. Please ensure Visual Studio with C++ build tools is installed."
    exit 1
}
Write-Host "Using MSBuild: $Global:MSBuildPath"
Write-Host ""

# 2. Navigate to Build Directory
$yuzuRootPath = $PSScriptRoot # Assumes the script is in the yuzu repository root
$buildDir = Join-Path -Path $yuzuRootPath -ChildPath "build"

if (-not (Test-Path $buildDir)) {
    Write-Error "Build directory not found at '$buildDir'. Please run the CMake configuration script first."
    exit 1
}

Write-Host "Changing to build directory: $buildDir"
try {
    Set-Location -Path $buildDir -ErrorAction Stop
}
catch {
    Write-Error "Failed to navigate to build directory '$buildDir': $($_.Exception.Message)"
    exit 1
}
Write-Host "Current directory: $(Get-Location)"
Write-Host ""

# 3. Build the Project
$solutionFile = "yuzu.sln"
if (-not (Test-Path $solutionFile)) {
    Write-Error "Solution file '$solutionFile' not found in '$buildDir'. Please run CMake configuration."
    exit 1
}

function Invoke-MSBuild {
    param(
        [string]$MsBuildTarget,
        [switch]$CaptureOutput
    )
    Write-Host "Attempting to build target: '$MsBuildTarget' with MSBuild..."
    Write-Host "Command: & `"$Global:MSBuildPath`" `"$solutionFile`" /t:$MsBuildTarget /p:Configuration=Release /p:Platform=x64"

    $msbuildArgs = @(
        "`"$solutionFile`"",
        "/t:$MsBuildTarget",
        "/p:Configuration=Release",
        "/p:Platform=x64",
        "/m" # Enable multi-processor build
    )

    if ($CaptureOutput) {
        $process = Start-Process -FilePath $Global:MSBuildPath -ArgumentList $msbuildArgs -Wait -NoNewWindow -PassThru -RedirectStandardOutput "msbuild_output.log" -RedirectStandardError "msbuild_error.log"
        $exitCode = $process.ExitCode
        $outputLog = Get-Content "msbuild_output.log" -ErrorAction SilentlyContinue
        $errorLog = Get-Content "msbuild_error.log" -ErrorAction SilentlyContinue
        return @{ ExitCode = $exitCode; Output = $outputLog; Error = $errorLog }
    } else {
        & $Global:MSBuildPath $msbuildArgs
        $exitCode = $LASTEXITCODE
        return @{ ExitCode = $exitCode; Output = $null; Error = $null }
    }
}

$buildResult = Invoke-MSBuild -MsBuildTarget $TargetProject -CaptureOutput

# 4. Error Handling and Unicorn Fallback
if ($buildResult.ExitCode -ne 0) {
    Write-Warning "Initial build for target '$TargetProject' failed with exit code $($buildResult.ExitCode)."
    Write-Host "Checking for Unicorn library issues..."

    $outputString = ($buildResult.Output | Out-String) + ($buildResult.Error | Out-String)

    # Check for common unicorn link errors
    $unicornErrorPattern = "unicorn\.a|LNK1181.+cannot open input file 'unicorn\.lib'|LNK2019.+symbol.+_uc_open"
    if ($outputString -match $unicornErrorPattern) {
        Write-Warning "Detected a potential Unicorn library issue. Attempting to build 'unicorn-build' target first."

        # Try building unicorn-build
        $unicornBuildResult = Invoke-MSBuild -MsBuildTarget "unicorn-build"
        if ($unicornBuildResult.ExitCode -eq 0) {
            Write-Host "'unicorn-build' target built successfully."
            Write-Host "Retrying to build target '$TargetProject'..."
            $buildResult = Invoke-MSBuild -MsBuildTarget $TargetProject # Don't need to capture full output again unless debugging
        } else {
            Write-Error "'unicorn-build' target also failed to build with exit code $($unicornBuildResult.ExitCode). Cannot proceed with '$TargetProject' build."
            Write-Host "Please check the build logs in '$buildDir'."
            exit 1
        }
    } else {
        Write-Host "No specific Unicorn library issue detected in the output, or it was another error."
    }
}

# Final check of build result
if ($buildResult.ExitCode -eq 0) {
    Write-Host ""
    Write-Host "----------------------------------------"
    Write-Host "Build for target '$TargetProject' completed successfully!"
    Write-Host "----------------------------------------"
    Write-Host "Output can be found in '$buildDir\bin\Release\' (or similar, depending on target)."
} else {
    Write-Error "Build for target '$TargetProject' failed with exit code $($buildResult.ExitCode)."
    Write-Host "Please check the build logs in '$buildDir' (msbuild_output.log, msbuild_error.log if captured)."
    exit 1
}

Write-Host "Yuzu build script finished."
Set-Location $yuzuRootPath # Return to original script path
Write-Host "Returned to directory: $(Get-Location)"
