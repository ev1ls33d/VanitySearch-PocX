# VanitySearch-PoCX

**Bitcoin & PoCX Vanity Address Generator with GPU Acceleration**

This is a fork of [VanitySearch](https://github.com/JeanLucPons/VanitySearch) with added support for **PoCX (Proof of Capacity X)** addresses.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CUDA](https://img.shields.io/badge/CUDA-13.1-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![C++](https://img.shields.io/badge/C++-14-blue.svg)](https://isocpp.org/)

## ?? What's New

- ? **PoCX Address Support** - Generate vanity addresses for PoCX cryptocurrency
- ? **CUDA 13.1 Support** - Updated for latest NVIDIA GPUs (RTX 50-series)
- ? **Compute Capability 9.0** - Optimized for GTX 5090 and newer
- ? **Full Backward Compatibility** - All Bitcoin features still work
- ? **Windows & Linux** - Complete build instructions for both platforms

## ?? Features

### Address Types Supported

| Type | Prefix | Example | Status |
|------|--------|---------|--------|
| Bitcoin P2PKH | `1` | 1Test123... | ? Supported |
| Bitcoin P2SH | `3` | 3Test123... | ? Supported |
| Bitcoin BECH32 | `bc1q` | bc1qtest... | ? Supported |
| **PoCX** | `p` | **pocx1Test...** | **? NEW!** |

### Core Features

- ?? **GPU Acceleration** - CUDA-optimized kernels for 100x+ speedup
- ?? **Multi-GPU Support** - Utilize multiple GPUs simultaneously
- ?? **Pattern Matching** - Use wildcards (`?` and `*`) in searches
- ?? **Split-Key Generation** - Safe vanity address for third parties
- ?? **Batch Processing** - Search multiple prefixes from file
- ? **CPU Multi-threading** - Efficient CPU utilization
- ?? **Endomorphism Optimization** - 3x speedup using curve properties

## ?? Quick Start

### Generate a PoCX Vanity Address

```bash
# Simple search (CPU only)
./VanitySearch pocx1Lucky

# With GPU acceleration (recommended)
./VanitySearch -gpu pocx1Lucky

# Stop when found
./VanitySearch -gpu -stop pocx1Lucky

# Case insensitive
./VanitySearch -gpu -c -stop pocx1lucky
```

### Example Output

```
VanitySearch v1.19
Difficulty: 656356768
Search: pocx1Lucky [Compressed]
Start Mon Jan 20 14:30:00 2025
Base Key: DA12E013325F12D6B68520E327847218128B788E6A9F2247BC104A0EE2818F44
Number of CPU thread: 15
GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
[12.5 Gkey/s][GPU 12.4 Gkey/s][Total 2^33.2][Prob 45.2%][50% in 00:00:42][Found 1]

PubAddress: pocx1LuckyABC123def456ghi789
Priv (WIF): pocx:Kxs4iWcqYHGBfzVpH4K94STNMHHz72DjaCuNdZeM5VMiP9zxMg15
Priv (HEX): 0x310DBFD6AAB6A63FC71CAB1150A0305ECABBE46819641D2594155CD41D081AF1
```

## ??? Building

### Linux (GTX 5090 with CUDA 13.1)

```bash
# Clone repository
git clone https://github.com/ev1ls33d/VanitySearch-PocX
cd VanitySearch-PocX

# Build with GPU support
make gpu=1 CCAP=9.0 CUDA=/usr/local/cuda-13.1 all

# Run
./VanitySearch -gpu pocx1Test
```

### Windows (Visual Studio 2019/2022)

1. Open `VanitySearch.sln`
2. Update CUDA compute capability to `compute_90,sm_90`
3. Build ? Build Solution (F7)

**Detailed Instructions**: See [`WINDOWS_BUILD.md`](WINDOWS_BUILD.md)

### Compute Capability Reference

| GPU Series | Model | CCAP | Build Command |
|------------|-------|------|---------------|
| RTX 50 | 5090, 5080 | 9.0 | `make gpu=1 CCAP=9.0 all` |
| RTX 40 | 4090, 4080 | 8.9 | `make gpu=1 CCAP=8.9 all` |
| RTX 30 | 3090, 3080 | 8.6 | `make gpu=1 CCAP=8.6 all` |
| RTX 20 | 2080 Ti | 7.5 | `make gpu=1 CCAP=7.5 all` |

## ?? Documentation

| Document | Description |
|----------|-------------|
| [`QUICKSTART.md`](QUICKSTART.md) | Quick reference guide |
| [`POCX_README.md`](POCX_README.md) | PoCX implementation details |
| [`BUILD_GUIDE.md`](BUILD_GUIDE.md) | Linux build instructions |
| [`WINDOWS_BUILD.md`](WINDOWS_BUILD.md) | Windows build guide |
| [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md) | Technical details |

## ?? Usage Examples

### Basic Search

```bash
# Search for prefix
./VanitySearch -gpu pocx1Test

# Case insensitive
./VanitySearch -gpu -c pocx1test

# Stop when found
./VanitySearch -gpu -stop pocx1Test
```

### Pattern Matching

```bash
# Wildcard: ? = any char, * = any chars
./VanitySearch -gpu "pocx1???Test"
./VanitySearch -gpu "pocx1*coin"
```

### Batch Search

```bash
# Create prefix list
echo "pocx1Test" > prefixes.txt
echo "pocx1Lucky" >> prefixes.txt

# Search all
./VanitySearch -gpu -i prefixes.txt
```

### Key Management

```bash
# Generate key pair
./VanitySearch -s "MySecret" -kp

# Show all address types
./VanitySearch -cp 0x1234...
# Outputs Bitcoin (P2PKH, P2SH, BECH32) + PoCX

# Convert WIF private key
./VanitySearch -cp Kxs4iWcq...
```

### Split-Key (Safe Third-Party Generation)

```bash
# Step 1: Requester generates key pair
./VanitySearch -s "AliceSecret" -kp

# Step 2: Searcher finds vanity (using public key)
./VanitySearch -sp 03FC71AE... -gpu -stop pocx1Alice

# Step 3: Requester reconstructs final key
./VanitySearch -rp L4U2Ca2w... keyinfo.txt
```

## ?? Performance

### Expected Performance (GTX 5090)

| Prefix Length | Difficulty | Estimated Time |
|---------------|------------|----------------|
| pocx1T | 58 | Instant |
| pocx1Te | 3,364 | < 1 second |
| pocx1Tes | 195K | ~1 second |
| pocx1Test | 11.3M | ~45 seconds |
| pocx1Test1 | 656M | ~40 minutes |
| pocx1Test12 | 38B | ~3 days |

*At ~15 GKey/s on GTX 5090*

### Performance Tips

1. Always use `-gpu` for GPU acceleration
2. Adjust grid size with `-g` for your specific GPU
3. Use `-t` to balance CPU/GPU workload
4. Monitor temps and boost clocks
5. Close other GPU applications

## ?? Security

### Best Practices

? **DO**:
- Use `-ps` flag for extra entropy when generating keys
- Keep private keys offline and encrypted
- Verify addresses before using
- Test with small amounts first

? **DON'T**:
- Share private keys (only share public keys for split-key)
- Use predictable seeds
- Run on compromised systems
- Trust third parties with full private keys

## ?? Testing

Run the compatibility check:

```bash
chmod +x test_pocx.sh
./test_pocx.sh
```

This verifies:
- PoCX address generation works
- All address types are supported
- GPU acceleration is functional
- CUDA libraries are properly linked

## ?? Contributing

Contributions are welcome! Areas for improvement:

- [ ] PoCX Bech32 addresses (`pocx1q...`)
- [ ] Testnet support
- [ ] BIP39 mnemonic integration
- [ ] Hardware wallet support
- [ ] Performance optimizations

## ?? Requirements

### Minimum

- GCC/G++ 7.3+ (C++14 support)
- CUDA Toolkit 10.0+ (for GPU)
- Linux or Windows
- NVIDIA GPU (for GPU acceleration)

### Recommended

- GCC/G++ 11+
- CUDA Toolkit 12.0+ or 13.1+
- RTX 40/50-series GPU
- 16GB+ RAM for large prefix lists

## ?? Troubleshooting

### "No CUDA devices found"
```bash
# Check GPU
nvidia-smi

# Verify CUDA
nvcc --version

# Check drivers
nvidia-smi --query-gpu=driver_version --format=csv
```

### "Compute capability not supported"
```bash
# Rebuild with correct CCAP
make clean
make gpu=1 CCAP=<your_version> all
```

### "Address checksum error"
- Verify you're using PoCX prefix (starts with 'p')
- Ensure PoCX support compiled correctly
- Run: `./VanitySearch -check`

## ?? License

GPLv3 - See [LICENSE](LICENSE) file

This project maintains the original GPLv3 license from VanitySearch.

## ?? Credits

### Original Project

- **VanitySearch**: [Jean Luc PONS](https://github.com/JeanLucPons/VanitySearch)
- **License**: GPLv3
- **Discussion**: [BitcoinTalk Thread](https://bitcointalk.org/index.php?topic=5112311.0)

### PoCX Support

- **PoCX Project**: Proof of Capacity Consortium
- **Implementation**: Based on PoCX-Reference specification
- **This Fork**: [ev1ls33d](https://github.com/ev1ls33d)

### Special Thanks

- Original VanitySearch contributors
- PoCX development team
- Bitcoin cryptography community

## ?? Links

- **Original VanitySearch**: https://github.com/JeanLucPons/VanitySearch
- **PoCX Project**: (Add link when available)
- **CUDA Toolkit**: https://developer.nvidia.com/cuda-toolkit
- **Bitcoin Wiki**: https://en.bitcoin.it/wiki/Vanitygen

## ?? Support

- **Issues**: Open an issue on GitHub
- **PoCX Questions**: See [POCX_README.md](POCX_README.md)
- **Build Help**: See [BUILD_GUIDE.md](BUILD_GUIDE.md) or [WINDOWS_BUILD.md](WINDOWS_BUILD.md)

## ?? Disclaimer

This software is provided "as is", without warranty of any kind. Always verify addresses and private keys before using them. The authors are not responsible for any loss of funds due to improper use.

---

**Made with ?? for the crypto community**

*Star ? this repo if you find it useful!*
