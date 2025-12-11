# Building VanitySearch-PoCX on Windows with GTX 5090

## Prerequisites

### Required Software

1. **Visual Studio 2019/2022** with:
   - Desktop development with C++
   - C++ CMake tools for Windows
   - Windows 10/11 SDK

2. **CUDA Toolkit 13.1** (Already installed)
   - Verify installation: `"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1\bin\nvcc.exe" --version`

3. **NVIDIA GPU Driver** (Latest for RTX 50-series)

## Option 1: Visual Studio Build (Recommended for Windows)

### Step 1: Update Visual Studio Project

1. Open `VanitySearch.sln` in Visual Studio
2. Right-click on the `VanitySearch` project ? Properties
3. Navigate to: **CUDA C/C++** ? **Device** ? **Code Generation**
4. Update to: `compute_90,sm_90` (for GTX 5090)

### Step 2: Update CUDA Path (if needed)

In Project Properties:
- **VC++ Directories** ? **Include Directories**: Add `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1\include`
- **VC++ Directories** ? **Library Directories**: Add `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1\lib\x64`

### Step 3: Build

1. Set configuration to **Release** and platform to **x64**
2. Build ? Build Solution (or press F7)
3. Executable will be in: `x64\Release\VanitySearch.exe`

### Step 4: Update GPUEngine.cu Properties

If you get CUDA compilation errors:
1. Right-click `GPU\GPUEngine.cu` ? Properties
2. **CUDA C/C++** ? **Device** ? **Code Generation**: `compute_90,sm_90`
3. **CUDA C/C++** ? **Common** ? **Generate Relocatable Device Code**: Yes
4. **CUDA C/C++** ? **Host** ? **Additional Compiler Options**: `/std:c++14`

## Option 2: MSBuild Command Line

```batch
REM Open "x64 Native Tools Command Prompt for VS 2022"
cd C:\Users\Ryzen\source\repos\ev1ls33d\VanitySearch-PocX

REM Build
msbuild VanitySearch.sln /p:Configuration=Release /p:Platform=x64 /p:CudaArchitecture=compute_90,sm_90

REM Run
x64\Release\VanitySearch.exe -v
```

## Option 3: WSL2 (Windows Subsystem for Linux)

### Setup WSL2

```powershell
# Install WSL2 (run as Administrator)
wsl --install -d Ubuntu

# Restart computer
# Launch Ubuntu from Start menu
```

### Inside WSL Ubuntu

```bash
# Update and install build tools
sudo apt-get update
sudo apt-get install -y build-essential g++ make

# Install CUDA Toolkit in WSL (if GPU passthrough enabled)
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-13-1

# Build VanitySearch
cd /mnt/c/Users/Ryzen/source/repos/ev1ls33d/VanitySearch-PocX
make gpu=1 CCAP=9.0 CUDA=/usr/local/cuda-13.1 all

# Run
./VanitySearch -v
```

## Option 4: CMake Build (Alternative)

Create `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.18)
project(VanitySearch CUDA CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CUDA_ARCHITECTURES 90)

find_package(CUDAToolkit REQUIRED)

file(GLOB SOURCES "*.cpp" "hash/*.cpp" "GPU/*.cpp")
file(GLOB CUDA_SOURCES "GPU/*.cu")

add_executable(VanitySearch ${SOURCES} ${CUDA_SOURCES})

target_include_directories(VanitySearch PRIVATE ${CUDAToolkit_INCLUDE_DIRS})
target_link_libraries(VanitySearch CUDA::cudart)
target_compile_definitions(VanitySearch PRIVATE WITHGPU)
```

Then build:
```batch
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release
```

## Troubleshooting

### Error: "nvcc not found"

**Solution**: Add CUDA to PATH
```batch
setx PATH "%PATH%;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1\bin"
```

### Error: "compute_90,sm_90 not supported"

**Solution**: Update CUDA Toolkit to 12.0 or later
- RTX 50-series requires CUDA 12.x or 13.x
- Download from: https://developer.nvidia.com/cuda-downloads

### Error: "LNK2001: unresolved external symbol"

**Solution**: Ensure CUDA libraries are linked
1. Project Properties ? Linker ? Input ? Additional Dependencies
2. Add: `cudart.lib`
3. Verify Library Path includes: `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1\lib\x64`

### Error: "MSB3721: command nvcc.exe exited with code 1"

**Solution**: 
1. Check CUDA Compute Capability in project settings
2. Ensure it matches your GPU: `compute_90,sm_90` for RTX 5090
3. Clean solution and rebuild

### Warning: C4819 (codepage)

**Solution**: Add to project properties:
- C/C++ ? Command Line ? Additional Options: `/utf-8`

## Verification

After building successfully:

```batch
cd x64\Release

REM Check version
VanitySearch.exe -v

REM List GPUs
VanitySearch.exe -l

REM Run self-check
VanitySearch.exe -check

REM Test PoCX
VanitySearch.exe -gpu -stop pocx1Test

REM Generate key pair
VanitySearch.exe -s "test" -kp
```

## Performance Optimization

### In Visual Studio:

1. **Configuration Properties** ? **C/C++** ? **Optimization**:
   - Optimization: Maximum Optimization (/O2)
   - Inline Function Expansion: Any Suitable (/Ob2)
   - Enable Intrinsic Functions: Yes (/Oi)
   - Favor Size Or Speed: Favor fast code (/Ot)

2. **CUDA C/C++** ? **Device**:
   - Code Generation: `compute_90,sm_90`
   - Max Register Count: 0 (auto)

3. **CUDA C/C++** ? **Optimization**:
   - Optimization: O2

## Building for Distribution

To create a standalone executable:

1. Build in **Release** mode
2. Copy required DLLs:
   ```batch
   copy "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1\bin\cudart64_130.dll" x64\Release\
   ```
3. Test on clean system or VM

## Alternative: Pre-built Binaries

If building fails, consider:
1. Using Windows Subsystem for Linux (WSL2)
2. Downloading pre-compiled CUDA binaries
3. Building in Docker with Windows containers

## Docker on Windows (Advanced)

```dockerfile
# Use Windows Server Core with CUDA
FROM nvidia/cuda:13.1.0-devel-windowsservercore-ltsc2022

# Build VanitySearch
COPY . C:\\VanitySearch
WORKDIR C:\\VanitySearch
RUN msbuild VanitySearch.sln /p:Configuration=Release /p:Platform=x64
```

## Support

For Windows-specific issues:
1. Check Visual Studio output window for detailed errors
2. Verify CUDA installation: `nvcc --version`
3. Check GPU: `nvidia-smi`
4. Try WSL2 if native Windows build fails

## Next Steps

After successful build:
1. Read `QUICKSTART.md` for usage examples
2. Read `POCX_README.md` for PoCX-specific features
3. Test with short prefixes first
4. Monitor GPU temperature and power usage
