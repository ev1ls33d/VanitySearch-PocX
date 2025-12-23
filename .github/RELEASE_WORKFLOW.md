# Release Workflow Documentation

This document explains how to use the GitHub Actions release workflow for VanitySearch-PoCX.

## Overview

The release workflow automatically builds VanitySearch-PoCX for three platforms:

- **Windows** with CUDA support - Standalone binary
- **Linux** with CUDA support - Standalone binary
- **macOS** CPU-only (CUDA not available on macOS) - Standalone binary

**All binaries are statically linked and require no external dependencies or runtime installations.**

## Triggering a Release

There are two ways to trigger the release workflow:

### 1. Creating a Git Tag (Recommended)

Push a version tag to trigger an automatic release:

```bash
# Create and push a tag
git tag v1.0.0
git push origin v1.0.0
```

The workflow will automatically:
1. Build for all three platforms
2. Create release artifacts
3. Create a GitHub release with the tag name
4. Upload all build artifacts to the release

### 2. Manual Workflow Dispatch

Alternatively, you can manually trigger the workflow from the GitHub Actions UI:

1. Go to **Actions** tab in the repository
2. Select **Release Build** workflow
3. Click **Run workflow**
4. Enter a version tag (e.g., `v1.0.0`)
5. Click **Run workflow**

## Build Details

### Windows Build

- **Runner**: `windows-latest`
- **CUDA Version**: 12.6.2
- **Build Tool**: MSBuild (Visual Studio)
- **Compute Capability**: 5.0-9.0 (supports GTX 900-series through RTX 50-series)
- **Static Linking**: Yes - C/C++ runtime and CUDA runtime statically linked (`/MT` flag)
- **Output**: `VanitySearch-Windows-CUDA.zip`
- **Contents**: 
  - `VanitySearch.exe` (standalone, no DLL dependencies)
  - `LICENSE.txt`
  - `README.md`

**Note**: The workflow patches the Visual Studio project to use CUDA 12.6 instead of CUDA 13.1. The resulting executable is fully standalone and does not require CUDA runtime installation.

### Linux Build

- **Runner**: `ubuntu-20.04`
- **CUDA Version**: 12.6.2
- **Build Tool**: GNU Make + GCC
- **Compute Capability**: All architectures (via `--gpu-architecture=all`)
- **Static Linking**: Yes - CUDA runtime, libgcc, and libstdc++ statically linked
- **Output**: `VanitySearch-Linux-CUDA.tar.gz`
- **Contents**: 
  - `VanitySearch` (standalone executable, no shared library dependencies)
  - `LICENSE.txt`
  - `README.md`

**Note**: The Makefile compiles for all CUDA architectures, ensuring broad GPU compatibility. No CUDA runtime installation required on target systems.

### macOS Build

- **Runner**: `macos-latest`
- **CUDA Version**: N/A (CPU-only)
- **Build Tool**: GNU Make + GCC 13
- **Static Linking**: Yes - libgcc and libstdc++ statically linked
- **Output**: `VanitySearch-macOS.tar.gz`
- **Contents**: 
  - `VanitySearch` (standalone executable, no shared library dependencies)
  - `LICENSE.txt`
  - `README.md`

**Note**: macOS does not support NVIDIA CUDA. This is a CPU-only build without GPU acceleration, but is fully standalone.

## Workflow Steps

The workflow consists of four jobs:

1. **build-windows**: Builds Windows version with CUDA
2. **build-linux**: Builds Linux version with CUDA
3. **build-macos**: Builds macOS version (CPU-only)
4. **create-release**: Downloads all artifacts and creates a GitHub release

All build jobs run in parallel. The release job runs only after all builds complete successfully.

## Static Linking

All binaries produced by this workflow are **fully standalone** with no external dependencies:

### Implementation Details

**Windows:**
- Uses `/p:RuntimeLibrary=MultiThreaded` MSBuild flag
- Statically links C/C++ runtime and CUDA runtime
- Result: Single `.exe` file with no DLL dependencies

**Linux:**
- Uses `-lcudart_static -ldl -lrt -static-libgcc -static-libstdc++` linker flags
- Statically links CUDA runtime, libgcc, and libstdc++
- Result: Single binary with no shared library dependencies

**macOS:**
- Uses `-static-libgcc -static-libstdc++` linker flags
- Statically links libgcc and libstdc++
- Result: Single binary with no shared library dependencies

### Benefits

- **No installation required**: Users can run binaries immediately after download
- **No CUDA runtime needed**: CUDA libraries are embedded in the binary
- **No version conflicts**: Each binary contains its own runtime
- **Portable**: Copy and run on any compatible system

### Trade-offs

- **Larger file size**: Binaries are 2-5MB larger than dynamically linked versions
- **Update complexity**: Security updates require rebuilding and redistributing binaries

## Customizing the Build

### Changing CUDA Version

To use a different CUDA version, modify the `CUDA_VERSION` environment variable in `.github/workflows/release.yml`:

```yaml
env:
  CUDA_VERSION: '12.6.2'  # Change to desired version
```

**Note**: Ensure the selected version is available in the [cuda-toolkit GitHub Action](https://github.com/Jimver/cuda-toolkit).

### Building for Different GPU Architectures

The Linux build uses `--gpu-architecture=all` in the Makefile, which compiles for all supported NVIDIA GPU architectures. This ensures maximum compatibility across different GPU generations.

If you need to target specific architectures only (to reduce binary size), modify the Makefile's NVCC flags:

```makefile
# In Makefile, change:
--gpu-architecture=all

# To specific compute capabilities:
--gpu-architecture=sm_86,sm_89,sm_90
```

### Adding More Platforms

To add support for additional platforms:

1. Add a new job in `.github/workflows/release.yml`
2. Configure the build steps for that platform
3. Add the new artifact to the `create-release` job

## Troubleshooting

### Build Fails on Windows

- Ensure the Visual Studio project file is compatible with CUDA 12.6
- Check that MSBuild can find the CUDA toolkit
- Verify compute capability settings in the project file

### Build Fails on Linux

- Ensure the Makefile uses the correct CUDA path (`/usr/local/cuda`)
- Verify GCC version is compatible with CUDA 12.6 (GCC 11 recommended)
- The Makefile compiles for all GPU architectures using `--gpu-architecture=all`

### Build Fails on macOS

- macOS builds are CPU-only - ensure no CUDA flags are used
- Verify GCC is available via Homebrew
- Check that the Makefile handles CPU-only builds correctly

### Release Not Created

- Ensure the workflow has `contents: write` permission
- Verify `GITHUB_TOKEN` is available
- Check that at least one build job succeeded

## Testing the Workflow

To test the workflow without creating a release:

1. Comment out the `create-release` job
2. Trigger a manual workflow run
3. Download artifacts from the workflow run page
4. Verify each platform's build works correctly

## Version Numbering

Follow semantic versioning (SemVer):
- `vMAJOR.MINOR.PATCH` (e.g., `v1.0.0`)
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

## Release Notes

The workflow automatically generates release notes including:
- Download links for each platform
- Platform-specific details (CUDA version, requirements)
- Usage instructions link

To customize release notes, edit the `body` section in the `Create Release` step.

## Security Considerations

- The workflow uses GitHub's built-in `GITHUB_TOKEN` for creating releases
- No external credentials are required
- All builds run in isolated GitHub-hosted runners
- CUDA toolkit is downloaded from official NVIDIA sources

## Support

For issues with the release workflow:
1. Check the Actions tab for detailed error logs
2. Review this documentation
3. Open an issue in the repository

For issues with the built binaries:
1. Verify CUDA runtime is installed (Windows/Linux)
2. Check GPU compute capability compatibility
3. See the main README.md for usage instructions
