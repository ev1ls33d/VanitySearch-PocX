@echo off
REM Build script for VanitySearch with PoCX support on Windows
REM For GTX 5090 with CUDA 13.1

echo Building VanitySearch with PoCX support...
echo.

REM Check if Visual Studio is available
if exist "VanitySearch.sln" (
    echo Visual Studio solution found.
    echo.
    echo To build in Visual Studio:
    echo 1. Open VanitySearch.sln
    echo 2. Set Configuration to "Release"
    echo 3. Update CUDA paths in project properties if needed:
    echo    - CUDA Toolkit: C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1
    echo    - Compute Capability: sm_90
    echo 4. Build Solution
    echo.
    echo Or use MSBuild from command line:
    echo msbuild VanitySearch.sln /p:Configuration=Release /p:Platform=x64
    goto :end
)

REM Check if WSL is available for Linux-style build
where wsl >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo WSL detected. Building using Linux toolchain...
    wsl make gpu=1 CCAP=9.0 all
    goto :end
)

echo.
echo ERROR: No suitable build environment found.
echo.
echo Options:
echo 1. Install Visual Studio 2017 or newer with C++ and CUDA support
echo 2. Install WSL2 with Ubuntu and build tools
echo 3. Use vcpkg or another Windows C++ package manager
echo.
echo For WSL2 installation:
echo   - Install WSL2: wsl --install
echo   - Install Ubuntu: wsl --install -d Ubuntu
echo   - Inside WSL: sudo apt-get install build-essential cuda-toolkit-13-1
echo.

:end
pause
