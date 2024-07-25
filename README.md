# Zed Windows Build
A simple script that builds the Zed code editor from the GitHub source for Windows.

# Prerequisites

### PowerShell
This requires PowerShell, which *should* be preinstalled on Windows machines. This script is aimed toward building for Windows with Windows.

### Visual Studio
This script will NOT install Visual Studio or related build tools, which are necessary to build Zed for Windows. To quote:
 > Install [Visual Studio](https://visualstudio.microsoft.com/downloads/) with optional component `MSVC v*** - VS YYYY C++ x64/x86 build tools` and install Windows 11 or 10 SDK depending on your system
For example, I use `MSVC v143 - VS 2022 C++ x64/86 build tools`.

# Steps
The following steps will be taken in the script. View `zed_build_script+Windows.ps1` for the source.

## 1) Check if the user is running as administrator, exit if not.

## 2) Check if `git` is installed on the system / added to PATH.
- If it is not, allow the user to install the latest version, using the GitHub API to get the latest release version.
- Save the installer for the latest version in the environment temp directory, then run the install silently (`/SILENT`).
- Remove the install once it is done installing.
- Exit the script if the user chooses not to install the `git`.

## 3) Check if Microsoft Visual Studio and associated build tools are installed.
- This will check if `vswhere.exe` is available in the default location, which is automatically installed with Visual Studio.
- If it is not available, the script will allow the user to bypass this error (if they are confident MSVC is actually installed) as there is no option to install MSVC.
- If it is available, it will save the output of the command(s) (with different arguments) to check if the build tools are installed.
- If they are not, the script will allow the user to bypass this error (if they are confident the build tools are actually installed) as there is no option to install them.
- If they are available, just continue.

## 4) Check if Rust and components (rustc, rustup, and cargo) are installed / added to PATH.
- It checks for the `rustup` command, as it requires `rustc` and automatically installs `cargo` alongside it.
- If it is not available, use `https://sh.rustup.rs` to download a `rustup-init.exe` file to the environment temp directory.
- Run the installer VERY silently (`/VERYSILENT`) and remove it when done.

## 5) Check if the git repository (`https://github.com/zed-industries/zed.git`) has already been cloned.
- If it does exist, ask the user if they want to A) remove it and clone it again, B) continue without removing or cloning, or C) exit.
- Default choice is to exit.
- The repository will clone to a `zed-repo` directory in the environment temp directory.

## 6) Pre-build commands.
- Update Rust with `rustup update`.
- Add the wasm32 target with `rustup target add wasm32-wasi`.
- (Skip the step on "Back dependencies")
- Change the CWD to the `zed-repo` directory.

## 7) Build choices.
- Ask the user if they want to just do `cargo run`, or go through a more complex build process.
- The complex build process consists of running `cargo build --release`, moving the `zed.exe` file in `.\target\release` to `C:\Program Files\Zed`, and then add that `Zed` directory to PATH.
- Default choice is to exit and tell the user to run the cargo commands manually.

# Sources
See the original GitHub repository here: https://github.com/zed-industries/zed\
See the original guide this script is based off here: https://github.com/zed-industries/zed/blob/main/docs/src/development/windows.md

# Support
This script works as of https://github.com/zed-industries/zed/pull/13251.
