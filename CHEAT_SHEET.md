# Quick Commands Cheat Sheet

## Building

```bash
# Linux
make gpu=1 CCAP=9.0 CUDA=/usr/local/cuda-13.1 all

# Clean first (if rebuilding)
make clean && make gpu=1 CCAP=9.0 all
```

## Testing

```bash
# Version
./VanitySearch -v

# List GPUs
./VanitySearch -l

# Self-check
./VanitySearch -check

# Compatibility test
chmod +x test_pocx.sh && ./test_pocx.sh
```

## Basic PoCX Search

```bash
# Simple (instant find)
./VanitySearch -gpu -stop pocx1T

# Real vanity (few seconds)
./VanitySearch -gpu -stop pocx1Test

# Case insensitive
./VanitySearch -gpu -c -stop pocx1test
```

## Generating Keys

```bash
# Key pair with seed
./VanitySearch -s "MySecret" -kp

# Show all address types
./VanitySearch -cp 0x0000000000000000000000000000000000000000000000000000000000000001

# Convert WIF
./VanitySearch -cp Kxs4iWcqYHGBfzVpH4K94STNMHHz72DjaCuNdZeM5VMiP9zxMg15
```

## Advanced Usage

```bash
# Pattern matching
./VanitySearch -gpu "pocx1???Test"
./VanitySearch -gpu "pocx1*lucky"

# Multiple prefixes
echo "pocx1Test" > prefixes.txt
echo "pocx1Lucky" >> prefixes.txt
./VanitySearch -gpu -i prefixes.txt

# Custom grid size
./VanitySearch -gpu -g 1024,128 pocx1Test

# Multiple GPUs
./VanitySearch -gpu -gpuId 0,1 pocx1Test

# CPU threads
./VanitySearch -gpu -t 8 pocx1Test
```

## Troubleshooting

```bash
# Check CUDA
nvcc --version

# Check GPU
nvidia-smi

# Check libs
ldd ./VanitySearch | grep cuda

# Rebuild clean
make clean
rm -rf obj
make gpu=1 CCAP=9.0 all
```

## Performance Monitoring

```bash
# Watch GPU usage
watch -n 1 nvidia-smi

# Benchmark (run 60 seconds)
timeout 60 ./VanitySearch -gpu pocx1Test

# Expected: ~10-15 GKey/s on GTX 5090
```

## Quick Validation

```bash
# Test PoCX generation
./VanitySearch -s "test123" -kp > test_key.txt
cat test_key.txt

# Generate PoCX from private key 1
./VanitySearch -cp 0x0000000000000000000000000000000000000000000000000000000000000001 | grep POCX

# Should show: Addr (POCX): p[...]
```

## Common Error Solutions

```bash
# "No CUDA devices"
nvidia-smi  # Check GPU is visible
export LD_LIBRARY_PATH=/usr/local/cuda-13.1/lib64:$LD_LIBRARY_PATH

# "Compute capability not supported"
make clean
make gpu=1 CCAP=9.0 all  # Use correct CCAP for your GPU

# "nvcc not found"
export PATH=/usr/local/cuda-13.1/bin:$PATH
```

## Documentation

- Full guide: `README_POCX.md`
- Quick start: `QUICKSTART.md`
- Build: `BUILD_GUIDE.md` (Linux) or `WINDOWS_BUILD.md` (Windows)
- PoCX details: `POCX_README.md`
- Complete tech: `IMPLEMENTATION_SUMMARY.md`
