# PoCX Support in VanitySearch

This fork adds support for PoCX (Proof of Capacity X) addresses to VanitySearch.

## What is PoCX?

PoCX is a cryptocurrency that uses the same elliptic curve cryptography (secp256k1) as Bitcoin, but with different address prefixes.

## PoCX Address Formats

### Base58 Addresses
- **Mainnet**: Addresses start with 'p' (version byte 0x55)
- Uses the same RIPEMD160(SHA256(pubkey)) scheme as Bitcoin

### Bech32 Addresses (Future)
- **HRP**: "pocx" instead of "bc" for Bitcoin
- Format: pocx1q... (witness version 0)

## Usage Examples

### Search for PoCX address prefix:
```bash
# Search for address starting with "pocx1"
./VanitySearch -gpu pocx1

# Search for specific prefix with compression
./VanitySearch -gpu -stop pocx1MyPrefix
```

### Generate PoCX key pair:
```bash
./VanitySearch -s "My Seed Phrase" -kp
```

### Compute PoCX address from public key:
```bash
./VanitySearch -ca 03FC71AE1E88F143E8B05326FC9A83F4DAB93EA88FFEACD37465ED843FCC75AA81
# Will show Bitcoin (P2PKH, P2SH, BECH32) and PoCX addresses
```

## Building with CUDA 12.x/13.x and Compute Capability 9.0

For NVIDIA RTX 50-series GPUs (like RTX 5090):

```bash
# Build with GPU support
make gpu=1 CCAP=9.0 all

# Specify CUDA installation path if needed
make gpu=1 CCAP=9.0 CUDA=/usr/local/cuda-13.1 all
```

### Compute Capability Reference
- RTX 50-series (5090, 5080): CCAP=9.0
- RTX 40-series (4090, 4080): CCAP=8.9
- RTX 30-series (3090, 3080): CCAP=8.6
- RTX 20-series (2080 Ti): CCAP=7.5

## Implementation Details

### Changes Made:
1. **Address Type Support**: Added `POCX` as a new address type (value 3)
2. **Version Byte**: PoCX mainnet uses version byte `0x55` (addresses start with 'p')
3. **Prefix Recognition**: The tool now recognizes 'p' as a valid prefix for PoCX addresses
4. **Backward Compatibility**: All existing Bitcoin address functionality remains unchanged

### Technical Specifications:
- **Curve**: secp256k1 (same as Bitcoin)
- **Hash**: SHA256 + RIPEMD160 (same as Bitcoin)
- **Compression**: Supports both compressed and uncompressed public keys
- **Split-key**: Supports vanity address generation for third parties
- **GPU Acceleration**: Full CUDA support for faster address generation

## Differences from Bitcoin

| Feature | Bitcoin | PoCX |
|---------|---------|------|
| P2PKH Version Byte | 0x00 (starts with '1') | 0x55 (starts with 'p') |
| Bech32 HRP | "bc" | "pocx" |
| Elliptic Curve | secp256k1 | secp256k1 ? |
| Hash Algorithm | SHA256+RIPEMD160 | SHA256+RIPEMD160 ? |

## Example Output

```
VanitySearch v1.19
Difficulty: 15318045009
Search: pocx1TryMe [Compressed]
Start Mon Jan 20 12:34:56 2025
Base Key: DA12E013325F12D6B68520E327847218128B788E6A9F2247BC104A0EE2818F44
Number of CPU thread: 7
GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)

PubAddress: pocx1TryMeJT7cfs4M6csEyhWVQJPAPmJ4NGw
Priv (WIF): pocx:Kxs4iWcqYHGBfzVpH4K94STNMHHz72DjaCuNdZeM5VMiP9zxMg15
Priv (HEX): 0x310DBFD6AAB6A63FC71CAB1150A0305ECABBE46819641D2594155CD41D081AF1
```

## Compatibility

- Works with all existing VanitySearch features:
  - CPU multi-threading
  - GPU acceleration (CUDA)
  - Pattern matching with wildcards
  - Split-key generation
  - Case-insensitive search (for Base58 addresses)

## Credits

- Original VanitySearch: Jean Luc PONS
- PoCX Support: Added based on PoCX-Reference implementation
- PoCX Project: Proof of Capacity Consortium
