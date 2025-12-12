# Visual Studio Build Fix for CUDA 13.1

## Problem
The build was failing with error:
```
error MSB4019: Das importierte Projekt "CUDA 11.1.props" wurde nicht gefunden
```

This means Visual Studio was trying to import CUDA 11.1 properties but you have CUDA 13.1 installed.

## Solution Applied

Updated `VanitySearch.vcxproj` with the following changes:

### 1. CUDA Version Update
**Before:**
```xml
<Import Project="$(VCTargetsPath)\BuildCustomizations\CUDA 11.1.props" />
...
<Import Project="$(VCTargetsPath)\BuildCustomizations\CUDA 11.1.targets" />
```

**After:**
```xml
<Import Project="$(VCTargetsPath)\BuildCustomizations\CUDA 13.1.props" />
...
<Import Project="$(VCTargetsPath)\BuildCustomizations\CUDA 13.1.targets" />
```

### 2. Compute Capability Update for RTX 5090
**Before:**
```xml
<CodeGeneration Condition="'$(Configuration)|$(Platform)'=='Release|x64'">
  compute_50,sm_50;compute_52,sm_52;compute_60,sm_60;compute_61,sm_61;
  compute_70,sm_70;compute_75,sm_75;compute_80,sm_80;compute_86,sm_86;
</CodeGeneration>
```

**After:**
```xml
<CodeGeneration Condition="'$(Configuration)|$(Platform)'=='Release|x64'">
  compute_50,sm_50;compute_52,sm_52;compute_60,sm_60;compute_61,sm_61;
  compute_70,sm_70;compute_75,sm_75;compute_80,sm_80;compute_86,sm_86;
  compute_89,sm_89;compute_90,sm_90;
</CodeGeneration>
```

Added:
- `compute_89,sm_89` - RTX 40-series support
- `compute_90,sm_90` - **RTX 5090 support**

### 3. Debug Configuration Update
**Before:**
```xml
<CodeGeneration Condition="'$(Configuration)|$(Platform)'=='Debug|x64'">
  compute_30,sm_30
</CodeGeneration>
```

**After:**
```xml
<CodeGeneration Condition="'$(Configuration)|$(Platform)'=='Debug|x64'">
  compute_90,sm_90
</CodeGeneration>
```

### 4. Platform Toolset Update
**Before:**
```xml
<PlatformToolset>v141</PlatformToolset>  <!-- Visual Studio 2017 -->
<PlatformToolset>v142</PlatformToolset>  <!-- Visual Studio 2019 -->
```

**After:**
```xml
<PlatformToolset>v143</PlatformToolset>  <!-- Visual Studio 2022 -->
```

### 5. Added WITHGPU to Debug Configuration
Ensured Debug configuration also has GPU support defined:
```xml
<PreprocessorDefinitions>WITHGPU;_CRT_SECURE_NO_WARNINGS;WIN32;WIN64;_DEBUG;_CONSOLE;%(PreprocessorDefinitions)</PreprocessorDefinitions>
```

## How to Build Now

### Option 1: Visual Studio GUI
1. Open `VanitySearch.sln` in Visual Studio 2022
2. Select **Release** configuration and **x64** platform
3. Build ? Build Solution (F7)
4. Executable will be in `x64\Release\VanitySearch.exe`

### Option 2: MSBuild Command Line
```cmd
REM Open "x64 Native Tools Command Prompt for VS 2022"
cd C:\Users\Ryzen\source\repos\ev1ls33d\VanitySearch-PocX

REM Clean previous build
msbuild VanitySearch.sln /t:Clean

REM Build Release version
msbuild VanitySearch.sln /p:Configuration=Release /p:Platform=x64

REM Run
x64\Release\VanitySearch.exe -v
```

### Option 3: Debug Build
```cmd
msbuild VanitySearch.sln /p:Configuration=Debug /p:Platform=x64
```

## Verification Steps

After building successfully, verify the setup:

```cmd
cd x64\Release

REM Check version
VanitySearch.exe -v

REM List CUDA devices (should show your RTX 5090)
VanitySearch.exe -l

REM Run self-check
VanitySearch.exe -check

REM Test PoCX address generation
VanitySearch.exe -cp 0x0000000000000000000000000000000000000000000000000000000000000001

REM Quick GPU test
VanitySearch.exe -gpu -stop pocx1T
```

## What if CUDA 13.1 Props Are Missing?

If you still get an error about CUDA 13.1 props not found, you have two options:

### Option A: Install CUDA 13.1 VS Integration
1. Download CUDA 13.1 from NVIDIA
2. Run the installer
3. Make sure to select "Visual Studio Integration" during installation

### Option B: Use Different CUDA Version
If you have a different CUDA version installed (e.g., 12.x), update the project file to match:

```xml
<!-- For CUDA 12.6 -->
<Import Project="$(VCTargetsPath)\BuildCustomizations\CUDA 12.6.props" />
...
<Import Project="$(VCTargetsPath)\BuildCustomizations\CUDA 12.6.targets" />
```

To find which CUDA versions are installed:
```cmd
dir "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA"
dir "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VC\v170\BuildCustomizations\CUDA*.props"
```

## Compute Capability Reference

| GPU Model | Compute Capability | Already Included? |
|-----------|-------------------|-------------------|
| RTX 5090 | 9.0 | ? Yes |
| RTX 5080 | 9.0 | ? Yes |
| RTX 4090 | 8.9 | ? Yes |
| RTX 4080 | 8.9 | ? Yes |
| RTX 3090 | 8.6 | ? Yes |
| RTX 3080 | 8.6 | ? Yes |
| RTX 2080 Ti | 7.5 | ? Yes |

## Troubleshooting

### Error: "Platform Toolset v143 not installed"
**Solution**: Install Visual Studio 2022 C++ build tools or change to:
- `v142` for VS 2019
- `v141` for VS 2017

### Error: "CUDA compiler not found"
**Solution**: 
1. Verify CUDA is installed: `nvcc --version`
2. Add to PATH: `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1\bin`
3. Restart Visual Studio

### Error: "compute_90,sm_90 not supported"
**Solution**: Your CUDA version is too old (needs 12.0+)
- Upgrade to CUDA 12.x or 13.x
- Or remove `compute_90,sm_90` from the CodeGeneration tags (will lose RTX 50-series support)

## Next Steps

After successful build:
1. Test basic functionality: `VanitySearch.exe -v`
2. Test GPU detection: `VanitySearch.exe -l`
3. Test PoCX generation: `VanitySearch.exe -gpu -stop pocx1Test`
4. Read `QUICKSTART.md` for usage examples
5. Read `POCX_README.md` for PoCX-specific features

## Summary

? **Fixed**: CUDA 11.1 ? CUDA 13.1
? **Added**: Compute capability 9.0 for RTX 5090
? **Added**: Compute capability 8.9 for RTX 40-series  
? **Updated**: Platform toolset to v143 (VS 2022)
? **Ensured**: GPU support in all configurations

The project should now build successfully on Windows with Visual Studio 2022 and CUDA 13.1!
