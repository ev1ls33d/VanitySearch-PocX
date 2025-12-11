# Quick Start Guide - VanitySearch with PoCX Support

## Basic Usage

### Search for PoCX Vanity Address

```bash
# Simple search
./VanitySearch pocx1Test

# With GPU acceleration
./VanitySearch -gpu pocx1Test

# Stop when found
./VanitySearch -gpu -stop pocx1Test

# Case insensitive
./VanitySearch -gpu -c -stop pocx1test
```

### Address Type Examples

| Prefix | Type | Example Command |
|--------|------|-----------------|
| `1` | Bitcoin P2PKH | `./VanitySearch -gpu 1Test` |
| `3` | Bitcoin P2SH | `./VanitySearch -gpu 3Test` |
| `bc1q` | Bitcoin Bech32 | `./VanitySearch -gpu bc1qtest` |
| `p` | **PoCX** | `./VanitySearch -gpu pocx1Test` |

## Pattern Matching

```bash
# Wildcard: ? = any single character, * = any characters
./VanitySearch -gpu "pocx1???Test"
./VanitySearch -gpu "pocx1*coin"

# Multiple patterns from file
echo "pocx1Test" > prefixes.txt
echo "pocx1Lucky" >> prefixes.txt
./VanitySearch -gpu -i prefixes.txt
```

## Key Generation

```bash
# Generate key pair with seed
./VanitySearch -s "MySecretSeed" -kp

# With additional random entropy
./VanitySearch -ps "MySecretSeed" -kp
```

## Address Conversion

```bash
# From private key (hex)
./VanitySearch -cp 0x1234567890abcdef...

# From WIF private key
./VanitySearch -cp L1234567890abcdef...

# From public key
./VanitySearch -ca 03FC71AE1E88F143E8B05326FC9A83F4DAB93EA88FFEACD37465ED843FCC75AA81
```

## Performance Tuning

```bash
# Specify CPU threads
./VanitySearch -gpu -t 8 pocx1Test

# Custom GPU grid size
./VanitySearch -gpu -g 1024,128 pocx1Test

# Multiple GPUs
./VanitySearch -gpu -gpuId 0,1 pocx1Test

# Maximum found items per kernel
./VanitySearch -gpu -m 65536 pocx1Test
```

## Output Options

```bash
# Save results to file
./VanitySearch -gpu -o results.txt pocx1Test

# Continue search after finding (don't stop)
./VanitySearch -gpu pocx1Test

# Stop after finding all prefixes
./VanitySearch -gpu -stop -i prefixes.txt
```

## Split-Key Vanity (For Third Party)

### Step 1: Requester generates key pair
```bash
./VanitySearch -s "AliceSecret" -kp
# Output:
# Priv : L4U2Ca2wyo721n7j9nXM9oUWLzCj19nKtLeJuTXZP3AohW9wVgrH
# Pub  : 03FC71AE1E88F143E8B05326FC9A83F4DAB93EA88FFEACD37465ED843FCC75AA81
```

### Step 2: Searcher finds partial key
```bash
./VanitySearch -sp 03FC71AE1E88F143E8B05326FC9A83F4DAB93EA88FFEACD37465ED843FCC75AA81 \
               -gpu -stop -o keyinfo.txt pocx1Alice
```

### Step 3: Requester reconstructs final key
```bash
./VanitySearch -rp L4U2Ca2wyo721n7j9nXM9oUWLzCj19nKtLeJuTXZP3AohW9wVgrH keyinfo.txt
```

## Difficulty Estimates

| Prefix Length | Approx. Difficulty | Time (GTX 5090) |
|---------------|-------------------|-----------------|
| pocx1T | 58^1 ? 58 | Instant |
| pocx1Te | 58^2 ? 3,364 | < 1 second |
| pocx1Tes | 58^3 ? 195K | ~1 second |
| pocx1Test | 58^4 ? 11.3M | ~1 minute |
| pocx1Test1 | 58^5 ? 656M | ~1 hour |
| pocx1Test12 | 58^6 ? 38B | ~3 days |

*Estimates are approximate and depend on hardware*

## Common Options Reference

| Option | Description |
|--------|-------------|
| `-gpu` | Enable GPU acceleration |
| `-stop` | Stop when all prefixes found |
| `-c` | Case insensitive search |
| `-t N` | Use N CPU threads |
| `-o file` | Output to file |
| `-i file` | Read prefixes from file |
| `-s seed` | Specify seed |
| `-g X,Y` | GPU grid size |
| `-gpuId N` | Select GPU N |
| `-m N` | Max found items |
| `-r N` | Rekey every N MKeys |
| `-u` | Search uncompressed |
| `-b` | Search both compressed/uncompressed |

## Tips

1. **Start Simple**: Begin with short prefixes to verify everything works
2. **Use GPU**: Always use `-gpu` for significantly faster search
3. **Monitor Progress**: The tool shows current key rate and probability
4. **Save Results**: Use `-o` to avoid losing found keys
5. **Batch Search**: Use `-i` for multiple prefixes efficiently

## Security Notes

?? **IMPORTANT**:
- Keep private keys secure
- Use `-ps` for additional entropy when generating keys
- Verify addresses before using them
- For split-key: Requester must keep their private key secret
- Test with small amounts first

## Example Session

```bash
# Full example: Search for PoCX vanity address
./VanitySearch -gpu -stop -o my_pocx_address.txt pocx1Lucky

# Example output:
# VanitySearch v1.19
# Difficulty: 656356768
# Search: pocx1Lucky [Compressed]
# Start Mon Jan 20 14:30:00 2025
# Base Key: DA12E013325F12D6B68520E327847218128B788E6A9F2247BC104A0EE2818F44
# Number of CPU thread: 15
# GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
# [12.5 Gkey/s][GPU 12.4 Gkey/s][Total 2^33.2][Prob 45.2%][50% in 00:00:42][Found 1]
#
# PubAddress: pocx1LuckyABC123...
# Priv (WIF): pocx:Kxs4iWcqYHGBfzVpH4K94STNMHHz72DjaCuNdZeM5VMiP9zxMg15
# Priv (HEX): 0x310DBFD6AAB6A63FC71CAB1150A0305ECABBE46819641D2594155CD41D081AF1
```

## Getting Help

```bash
# Show help
./VanitySearch -h

# Show version
./VanitySearch -v

# List CUDA devices
./VanitySearch -l

# Check CPU/GPU
./VanitySearch -check
```

## Further Reading

- `POCX_README.md` - PoCX implementation details
- `BUILD_GUIDE.md` - Building for GTX 5090
- `README.md` - Original VanitySearch documentation
