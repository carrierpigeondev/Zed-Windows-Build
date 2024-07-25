<#
Build script for Zed for Windows
#>

#Requires -RunAsAdministrator

# check if Git is installed
Write-Host "Checking if Git is installed."
if (Get-Command git.exe -ErrorAction SilentlyContinue) {
    Write-Host "Git has been found."
} else {
    Write-Host "Git has not been found or is not in PATH and will not be accessible by the script."

    # ask the user if they want to install git
    $installGitResponse = Read-Host "Install git? (y/n): "
    if ($installGitResponse.ToLower() -eq "y") {
        # get the latest version of git from the api, download it to temp, run the installer, then remove the installer from the temp dir
        Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -Headers @{ "User-Agent" = "PowerShell" } |
            ForEach-Object { $_.assets | Where-Object { $_.name -like "*64-bit.exe" } | Select-Object -ExpandProperty browser_download_url } |
            ForEach-Object {
                $installerPath = "$env:TEMP\Git-Installer.exe"
                Invoke-WebRequest -Uri $_ -OutFile $installerPath
                Start-Process -FilePath $installerPath -ArgumentList "/SILENT" -Wait
                Remove-Item $installerPath
            }
    }
    else {
        exit  # leave the script as it cannot continue without git
        # no bypass for this error has the script NEEDS access to the git.exe command
    }
}

# check if Visual Studio is installed alongside the proper build tools
# this will not install them, only tell the user to install theme
Write-Host "Checking if Visual Studio and MSVC build tools for x86/64 are installed."
$vswherePath = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-path $vswherePath) {
    # run the vswhere command and capture the outputs
    $x64Paths = & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -products * -utf8 -all -legacy -find "VC\\Tools\\MSVC\\**\\bin\\Hostx64\\x64\\*"
    $x86Paths = & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -products * -utf8 -all -legacy -find "VC\\Tools\\MSVC\\**\\bin\\Hostx86\\x86\\*"

    # if nothing was output, the paths
    if (-not $x64Paths -and -not $x86Paths) {
        Write-Host "No MSVC tools found for x64 and x86 architectures. Ensure you have them installed."

        # allow the user to bypass this error as something may have gone wrong
        $bypassNoMSVCBuildToolsResponse = Read-Host "Do you want to bypass this error? (y/n): "
        if ($bypassNoMSVCBuildToolsResponse.ToLower() -eq "n") {
            exit
        }
    }

    Write-Host "Visual Studio and MSVC build tools for x86/64 have been found."
} else {
    Write-Host "Visual Studio not installed or something is wrong with the installation."
    Write-Host "Ensure the following path is valid: 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'"

    # allow the user to bypass this error as something may have gone wrong
    $bypassNoVisualStudioResponse = Read-Host "Do you want to bypass this error? (y/n): "
    if ($bypassNoVisualStudioResponse.ToLower() -eq "n") {
        exit
    }
}

# check if Rust is installed
Write-Host "Checking if Rust, rustup, cargo, etc. is installed."
if (Get-Command rustup.exe -ErrorAction SilentlyContinue) {
    Write-Host "Rust, rustup, cargo, etc. have been found."
} else {
    Write-Host "Rust, rustup, cargo, etc. have not been found or are not in PATH and will not be accessible by the script."

    # ask the user if they want to install rust and it's
    $installRustResponse = Read-Host "Install Rust and its components? (y/n): "
    if ($installRustResponse.ToLower() -eq "y") {
        # download the latest rustup init, save it to temp, run it VERY silently, then remove it,
        Invoke-WebRequest -Uri "https://sh.rustup.rs" -OutFile "$env:TEMP\rustup-init.exe"
        Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT" -Wait
        Remove-Item "$env:TEMP\rustup-init.exe"

    } else {
        exit  # leave the script as it cannot continue without Rust
        # no bypass for this error has the script NEEDS access to commands such as rustup.exe and cargo.exe
    }
}

# define the path for the zed repository, then tell the user where it is
Write-Host "Checking if the Zed repository has already been cloned."
$zedRepoPath = "$env:TEMP\zed_repo"
if (Test-Path $zedRepoPath) {
    Write-Host "The Zed repository path located at: $zedRepoPath, however, it is already full of content."
    Write-Host "The directory must be deleted to clone the repository. If the repository has already been cloned, choose the appropriate option."
    $optionZedRepoPathResponse = Read-Host @"
1) Delete $zedRepoPath and clone Zed repository at the path.
2) Do not delete the $zedRepoPath and continue without cloning.
3) Exit without making any changes to the filesystem.

"@
    switch ($optionZedRepoPathResponse) {
        "1" {
            Write-Host "Removing $zedRepoPath"
            Remove-Item $zedRepoPath -Recurse -Force

            Write-Host "Cloning Zed repository to $zedRepoPath"
            git.exe clone https://github.com/zed-industries/zed.git $zedRepoPath
        }
        "2" {
            Write-Host "Continuing without deleting the directory or cloning the repository."
            continue
        }
        "3" {
            Write-Host "Exiting without making any changes to the filesystem."
            exit
        }
        default {
            Write-Host "Invalid choice. Exiting without making any changes to the filesystem."
            exit
        }
    }
} else {
    Write-Host "Cloning Zed repository to $zedRepoPath"
    git.exe clone https://github.com/zed-industries/zed.git $zedRepoPath
}

# update rust, even if it was just installed
Write-Host "Updating rustup"
rustup.exe update

# add the target even if it already exists so it can possibly be updated
Write-Host "Adding wasm32-wasi target to rustup."
rustup.exe target add wasm32-wasi

# skipping the "Backend dependencies" section as it is still in development

# change the directory, cd is an alias for Set-Location in PowerShell and is not convention
Write-Host "Changed current working directory to $zedRepoPath"
Set-Location $zedRepoPath

# choose the proper cargo command to run
Write-Host "Choose the appropriate option for your use."
$cargoOptionResponse = Read-Host @"
1) Test Zed once, using cargo run.
2) Build Zed, using cargo build --release, move the executable to C:\Program Files\Zed\zed.exe, and add it to PATH.

"@
switch ($cargoOptionResponse) {
    "1" {
        cargo.exe run
    }
    "2" {
        cargo.exe build --release

        $programFilesZedPath = "C:\Program Files\Zed"
        $programFilesZedExePath = "C:\Program Files\Zed\zed.exe"
        Write-Host "Moving the compiled zed.exe file to Program Files to $programFilesZedExePath"
        if (-not (Test-Path $programFilesZedPath)) {
            New-Item -ItemType Directory -Path $programFilesZedPath
        }
        Move-Item .\target\release\zed.exe $programFilesZedExePath

        Write-Host "Adding $programFilesZedExePath to PATH."
        $currentPATH = [Environment]::GetEnvironmentVariable("Path", "User")
        [Environment]::SetEnvironmentVariable("Path", "$currentPATH;$programFilesZedPath", "User")
    }
    default {
        Write-Host "Invalid choice. Exiting without running anything. Navigate to $zedRepoPath and run the command manually."
        exit
    }
}