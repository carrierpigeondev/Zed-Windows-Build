# Zed Windows Build
A simple script that builds the Zed code editor from the GitHub source for Windows.

# Prerequisites

### PowerShell
This requires PowerShell, which *should* be preinstalled on Windows machines. This script is aimed toward building for Windows with Windows.

### Visual Studio
This script will NOT install Visual Studio or related build tools, which are necessary to build Zed for Windows. To quote:
 > Install [Visual Studio](https://visualstudio.microsoft.com/downloads/) with optional component `MSVC v*** - VS YYYY C++ x64/x86 build tools` and install Windows 11 or 10 SDK depending on your system


# Steps
The following steps will be taken in the script. View `zed_build_script+Windows.ps1` for the source.

# Sources
See the original GitHub repository here: https://github.com/zed-industries/zed

See the original guide this script is based off here: https://github.com/zed-industries/zed/blob/main/docs/src/development/windows.md

# Support
This script works as of https://github.com/zed-industries/zed/pull/13251.
