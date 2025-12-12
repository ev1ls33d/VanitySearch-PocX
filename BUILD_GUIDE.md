# Build Instructions for GTX 5090 with CUDA 13.1

## Prerequisites

1. **CUDA Toolkit 13.1** (already installed)
2. **GCC/G++ 11 or newer** (C++14 compatible)
3. **Make**

## Build Commands

### For GTX 5090 (Compute Capability 9.0)

```bash
# Clean any previous builds
make clean

# Build with GPU support for GTX 5090
make gpu=1 CCAP=9.0 CUDA=/usr/local/cuda-13.1 all
```

### Alternative: If CUDA is in default location

```bash
make gpu=1 CCAP=9.0 all
```

### CPU-Only Build (No GPU)

```bash
make all
```

## Verification

After building, test the installation:

```bash
# List CUDA devices
./VanitySearch -l

# Check functionality
./VanitySearch -check

# Generate a test key pair
./VanitySearch -s "test" -kp
```

## Testing PoCX Support

```bash
# Test PoCX address generation
./VanitySearch -gpu -stop pocx1Test

# Generate PoCX addresses from a private key
./VanitySearch -cp 0x0000000000000000000000000000000000000000000000000000000000000001

# This should output:
# - Bitcoin P2PKH address (starts with '1')
# - Bitcoin P2SH address (starts with '3')
# - Bitcoin BECH32 address (starts with 'bc1')
# - PoCX address (starts with 'p')
```

## Common Issues

### Issue: CUDA version mismatch
**Solution**: Ensure CUDA path points to your 13.1 installation:
```bash
export CUDA_HOME=/usr/local/cuda-13.1
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

### Issue: Compute capability not supported
**Error**: "no kernel image is available for execution on the device"
**Solution**: Verify your GPU's compute capability and rebuild with correct CCAP:
```bash
nvidia-smi --query-gpu=compute_cap --format=csv
make clean
make gpu=1 CCAP=<your_ccap> all
```

### Issue: G++ version too old
**Solution**: Install newer G++:
```bash
# Ubuntu/Debian
sudo apt-get install g++-11

# Update Makefile to use specific version
make CXX=g++-11 gpu=1 CCAP=9.0 all
```

## Performance Tips

1. **Grid Size Optimization**: The tool auto-detects, but you can manually specify:
   ```bash
   ./VanitySearch -gpu -g 1024,128 pocx1Prefix
   ```

2. **Multiple GPUs**: If you have multiple GPUs:
   ```bash
   ./VanitySearch -gpu -gpuId 0,1 pocx1Prefix
   ```

3. **CPU + GPU**: Use both for maximum performance:
   ```bash
   ./VanitySearch -gpu -t 6 pocx1Prefix
   # -t 6 uses 6 CPU threads + GPU
   ```

## Docker Build (Optional)

If you prefer Docker:

```bash
# Build Docker image
docker build -f docker/cuda/Dockerfile \
  --build-arg CUDA=13.1 \
  --build-arg CCAP=9.0 \
  -t vanitysearch:pocx .

# Run
docker run --gpus all vanitysearch:pocx -gpu pocx1Test
```

## Troubleshooting

### Check CUDA Installation
```bash
nvcc --version
nvidia-smi
```

### Check Compiler
```bash
g++ --version
# Should be 7.3.0 or newer for C++14 support
```

### Test Without GPU First
```bash
make clean
make all
./VanitySearch -check
./VanitySearch pocx1Test
```

If CPU version works, then rebuild with GPU support.

## Expected Performance

For GTX 5090 searching for "pocx1Test":
- **Expected**: ~10-15 GKey/s (depending on GPU boost clocks)
- **CPU Contribution**: ~50-100 MKey/s per core

Compare with Bitcoin "1Test" for reference performance.

## Support

For issues specific to:
- **PoCX Implementation**: Check POCX_README.md
- **CUDA/GPU Issues**: Original VanitySearch issues on GitHub
- **Build Problems**: Verify CUDA and GCC versions match requirements
