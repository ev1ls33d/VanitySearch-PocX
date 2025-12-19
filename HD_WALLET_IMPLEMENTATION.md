# HD Wallet Implementation for VanitySearch-PoCX

## Overview
This document describes the HD wallet (BIP39/BIP32/BIP44) implementation added to VanitySearch-PoCX. The implementation allows the GPU to generate and derive hierarchical deterministic wallet keys according to BIP39, BIP32, and BIP44 standards.

## Architecture

### GPU-Based Implementation
All cryptographic operations for HD wallet generation run on the GPU for maximum performance:

1. **SHA-512 Implementation** - Full SHA-512 hash function implemented as CUDA device functions
2. **HMAC-SHA512** - HMAC-SHA512 for BIP32 key derivation
3. **BIP32 Child Key Derivation** - Hardened child key derivation on GPU
4. **BIP44 Path Derivation** - Support for m/84'/coinType'/account'/0/0 derivation path

### Components

#### GPU/GPUEngine.cu
Contains the main CUDA kernel implementations:

- `_SHA512Transform()` - SHA-512 block transform
- `_SHA512_Small()` - Optimized SHA-512 for small fixed-size inputs
- `_HMAC_SHA512_BIP32()` - HMAC-SHA512 optimized for BIP32 use
- `_DeriveChildKeyHardened()` - BIP32 hardened child key derivation
- `_DeriveHDKeyFromSeed()` - Complete BIP44 path derivation from mnemonic seed
- `comp_keys_hd` - Main GPU kernel that generates HD keys and searches for vanity addresses

#### GPU/GPUEngine.h
Extended GPUEngine class with:

- `SetHDWalletMode()` - Enable HD wallet mode with coin type and account parameters
- `SetMnemonicSeeds()` - Load BIP39 mnemonic seeds for processing
- HD wallet mode flags and parameters

#### BIP39.h / BIP39.cpp
Host-side BIP39 implementation:

- Load BIP39 English wordlist (2048 words)
- Generate 12-word mnemonics
- Mnemonic validation
- Mnemonic to seed conversion (PBKDF2-HMAC-SHA512)

#### BIP32.h / BIP32.cpp
Host-side BIP32 implementation:

- Master key derivation from seed
- Child key derivation (CPU implementation for reference/testing)
- Path parsing and derivation

## BIP44 Derivation Path

The implementation uses the following derivation path for PoCX:

```
m/84'/coinType'/account'/0/0
```

Where:
- **84'** - BIP84 (Native SegWit)
- **coinType'** - 0 for Bitcoin mainnet, 1 for testnet
- **account'** - Account index (default 0)
- **0** - External chain (receiving addresses)
- **0** - Address index

The ' symbol indicates hardened derivation.

## How It Works

### HD Wallet Mode Flow

1. **Enable HD Mode**
   ```cpp
   gpuEngine.SetHDWalletMode(true, coinType, account);
   ```

2. **Generate Mnemonic Seeds**
   - Host generates BIP39 mnemonics (12 words)
   - Converts mnemonics to 64-byte seeds using PBKDF2-HMAC-SHA512
   - One seed per GPU thread

3. **Load Seeds to GPU**
   ```cpp
   gpuEngine.SetMnemonicSeeds(seeds, count);
   ```

4. **GPU Kernel Execution**
   - Each GPU thread receives one mnemonic seed
   - Derives master key using HMAC-SHA512("Bitcoin seed", seed)
   - Performs BIP32 hardened derivation: m → m/84' → m/84'/0' → m/84'/0'/0' → m/84'/0'/0'/0 → m/84'/0'/0'/0/0
   - Converts final key to public key point
   - Generates address and checks against prefix

5. **Match Found**
   - When a match is found, the GPU returns the thread ID
   - Host retrieves the corresponding mnemonic
   - Outputs the mnemonic that generated the matching address

## GPU Optimizations

### SHA-512 Implementation
- Custom CUDA implementation optimized for BIP32 use cases
- Unrolled loops for message schedule expansion
- Inline helper functions for rotate and bitwise operations
- Single-block optimization for small inputs (< 112 bytes)

### Memory Efficiency
- Reuses existing inputKey GPU memory for mnemonic seeds
- Each thread processes independently (no synchronization needed)
- Constant memory for SHA-512 round constants

### Performance Considerations
- HD derivation adds overhead compared to random key generation
- 5 levels of BIP32 derivation per key
- Each derivation requires one HMAC-SHA512 (two SHA-512 hashes)
- Trade-off: HD wallet benefits vs. performance impact

## Integration with Existing Code

The HD wallet implementation integrates seamlessly with the existing vanity search:

- When `hdWalletMode = false`: Uses original key generation
- When `hdWalletMode = true`: Uses `comp_keys_hd` kernel
- Same prefix matching logic and output handling
- Compatible with P2PKH, P2SH, BECH32, and POCX address types

## File Changes

### New Files
- `BIP39.h` / `BIP39.cpp` - BIP39 implementation
- `BIP32.h` / `BIP32.cpp` - BIP32 implementation  
- `GPU/GPUHDWallet.h` - GPU HD wallet header
- `bip39_english.txt` - BIP39 English wordlist (2048 words)

### Modified Files
- `GPU/GPUEngine.cu` - Added HD wallet kernels
- `GPU/GPUEngine.h` - Added HD wallet methods
- `Makefile` - Added BIP39.o and BIP32.o

## Security Considerations

### Secure Key Generation
- Uses BIP39 standard for mnemonic generation
- PBKDF2-HMAC-SHA512 with 2048 iterations for seed derivation
- BIP32 hardened derivation for all account-level keys

### GPU Random Number Generation
- For production use, ensure high-quality entropy source
- CPU generates initial entropy and mnemonics
- GPU performs deterministic derivation only

### Private Key Protection
- Mnemonics should be stored securely
- GPU memory contains sensitive key material during operation
- Clear GPU memory after use in production environments

## Future Enhancements

### Pending Implementation
- [ ] Full PBKDF2-HMAC-SHA512 on GPU (currently done on CPU)
- [ ] BIP39 checksum calculation on GPU
- [ ] Support for 24-word mnemonics
- [ ] Non-hardened derivation for change addresses
- [ ] Mnemonic passphrase support
- [ ] Multi-account search

### Possible Optimizations
- Batch HMAC-SHA512 computation
- Precompute intermediate derivation levels
- Cache derivation results for multiple indices
- Parallel derivation of multiple accounts

## Usage Example

```cpp
// Enable HD wallet mode for Bitcoin mainnet, account 0
gpuEngine.SetHDWalletMode(true, 0, 0);

// Generate BIP39 mnemonics and convert to seeds
uint8_t seeds[nbThread * 64];
for (int i = 0; i < nbThread; i++) {
    std::string mnemonic = BIP39::GenerateMnemonic12();
    BIP39::MnemonicToSeed(mnemonic, "", &seeds[i * 64]);
}

// Load seeds to GPU
gpuEngine.SetMnemonicSeeds(seeds, nbThread);

// Run vanity search with HD wallet derivation
gpuEngine.Launch(prefixFound);

// When match found, retrieve corresponding mnemonic
// The mnemonic at index threadId generated the matching address
```

## Testing

### Unit Tests Needed
- [ ] SHA-512 correctness (test vectors)
- [ ] HMAC-SHA512 correctness (test vectors)
- [ ] BIP32 derivation correctness (test vectors)
- [ ] BIP39 mnemonic generation
- [ ] End-to-end HD wallet derivation

### Integration Tests Needed
- [ ] HD wallet mode with vanity search
- [ ] Multiple coin types
- [ ] Multiple accounts
- [ ] Performance benchmarks vs. standard mode

## References

- [BIP39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki) - Mnemonic code for generating deterministic keys
- [BIP32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) - Hierarchical Deterministic Wallets
- [BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki) - Multi-Account Hierarchy for Deterministic Wallets
- [BIP84](https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki) - Derivation scheme for P2WPKH

## License

This implementation is part of VanitySearch-PoCX and is licensed under GPLv3.
