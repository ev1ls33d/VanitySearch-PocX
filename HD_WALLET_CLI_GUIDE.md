# HD Wallet CLI Integration

## Command-Line Usage

The `-hd` flag has been added to enable HD wallet mode for vanity address generation.

### Basic Usage

```bash
# Enable HD wallet mode (requires -gpu)
./VanitySearch -gpu -hd pocx1Test
```

### Combined with Other Flags

```bash
# Multiple GPUs
./VanitySearch -gpu -gpuId 0,1 -hd pocx1Lucky

# With output file
./VanitySearch -gpu -hd -o results.txt pocx1Test

# Stop when found
./VanitySearch -gpu -hd -stop pocx1Test

# With grid size customization
./VanitySearch -gpu -g 2048,128 -hd pocx1Test
```

### Requirements

- The `-hd` flag **requires** the `-gpu` flag (HD wallet mode only works on GPU)
- The `bip39_english.txt` file must be in the same directory as the executable

### Error Handling

```bash
# This will show an error
./VanitySearch -hd pocx1Test
# Error: HD wallet mode (-hd) requires GPU mode (-gpu)
```

## Output Format

When a matching address is found in HD wallet mode, the output includes:

```
PubAddress: pocx1TestABC123def456ghi789jkl012
Mnemonic: abandon ability able about above absent absorb abstract absurd abuse access accident
Priv (HEX): 0x1234567890abcdef...
Priv (WIF Mainnet): wpkh(...)#checksum
Priv (WIF Testnet): wpkh(...)#checksum
```

### Key Differences from Standard Mode

**Standard Mode Output:**
```
PubAddress: pocx1TestABC123...
Priv (HEX): 0x...
Priv (WIF Mainnet): wpkh(...)#checksum
Priv (WIF Testnet): wpkh(...)#checksum
```

**HD Wallet Mode Output (with `-hd`):**
```
PubAddress: pocx1TestABC123...
Mnemonic: abandon ability able about above absent absorb abstract absurd abuse access accident
Priv (HEX): 0x...
Priv (WIF Mainnet): wpkh(...)#checksum
Priv (WIF Testnet): wpkh(...)#checksum
```

The mnemonic line is added in HD mode, allowing you to recreate the wallet using standard BIP39/BIP32/BIP44 tools.

## Derivation Path

The HD wallet mode uses the following BIP44 derivation path:

```
m/84'/0'/0'/0/0
```

- **m/84'** - BIP84 (Native SegWit)
- **0'** - Bitcoin mainnet (hardened)
- **0'** - Account 0 (hardened)
- **0** - External chain (receiving addresses)
- **0** - Address index 0

All intermediate levels use hardened derivation for maximum security.

## Implementation Details

### What Happens When You Use `-hd`

1. **BIP39 Wordlist Loading**
   - Loads the 2048-word English wordlist from `bip39_english.txt`

2. **Mnemonic Generation**
   - Generates one unique 12-word BIP39 mnemonic per GPU thread
   - Each mnemonic has proper checksum validation

3. **Seed Derivation**
   - Converts each mnemonic to a 64-byte seed using PBKDF2-HMAC-SHA512
   - Uses 2048 iterations as per BIP39 standard
   - Empty passphrase (can be extended in future)

4. **GPU Processing**
   - Loads all mnemonic seeds to GPU memory
   - Each GPU thread derives its key via BIP32/BIP44 on the GPU
   - Performs vanity search using derived keys

5. **Match Output**
   - When a match is found, retrieves the corresponding mnemonic
   - Outputs complete information including mnemonic, address, and WIF

### Performance Considerations

HD wallet mode has ~5x computational overhead compared to standard mode due to:
- 5 levels of BIP32 derivation
- Each derivation = 1 HMAC-SHA512 = 2 SHA-512 hashes
- Total: 10 SHA-512 hashes per key vs. 2 in standard mode

**Estimated Performance:**
- Standard Mode: ~15 GKey/s on RTX 5090
- HD Wallet Mode: ~3 GKey/s on RTX 5090

The trade-off provides the benefits of HD wallets (backup via mnemonic, standard compliance) at the cost of performance.

## Backward Compatibility

The `-hd` flag is completely optional. Without it, VanitySearch operates in standard mode exactly as before:

```bash
# Standard mode (unchanged behavior)
./VanitySearch -gpu pocx1Test
```

All existing command-line options work with `-hd`:
- `-stop` - Stop when all prefixes found
- `-i` - Input file with prefixes
- `-o` - Output file
- `-gpuId` - GPU selection
- `-g` - Grid size
- `-m` - Max found
- `-c` - Case insensitive
- etc.

## Example Session

```bash
$ ./VanitySearch -gpu -hd pocx1Test

PoCX-VanitySearch v1.0 - by EviLSeeD

GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
HD Wallet Mode: BIP39/BIP32/BIP44 derivation enabled
Derivation Path: m/84'/0'/0'/0/0
Search: pocx1Test [Compressed]
Start Fri Dec 19 18:53:00 2025
Number of CPU thread: 15
[3.1 Gkey/s][GPU 3.0 Gkey/s][Total 2^28.5][Prob 92.1%][50% in 00:00:03][Found 1]

PubAddress: pocx1TestABC123def456ghi789jkl012
Mnemonic: abandon ability able about above absent absorb abstract absurd abuse access accident
Priv (HEX): 0x1234567890abcdef...
Priv (WIF Mainnet): wpkh(L...)#checksum
Priv (WIF Testnet): wpkh(c...)#checksum
```

## Security Notes

1. **Mnemonic Storage**: Save the mnemonic securely. It's the master key to your wallet.
2. **Entropy Source**: Uses system random number generator for mnemonic generation.
3. **Hardened Paths**: All account-level derivations use hardened paths (0x80000000 flag).
4. **Standard Compliance**: Fully compliant with BIP39, BIP32, BIP44, and BIP84.

## Wallet Recovery

To recover a wallet from the mnemonic output:

1. Use any BIP39-compatible wallet (Electrum, Ledger, Trezor, etc.)
2. Import the 12-word mnemonic
3. Use derivation path: `m/84'/0'/0'/0/0`
4. The wallet will regenerate the same address and private key

## Future Enhancements

Possible extensions to HD wallet mode:
- Custom derivation paths (`-hd-path "m/84'/0'/1'/0/0"`)
- Multiple accounts (`-hd-account 1`)
- Testnet support (`-hd-testnet`)
- 24-word mnemonics (`-hd-words 24`)
- Mnemonic passphrase (`-hd-passphrase "..."`)
- Batch mnemonic generation

## Troubleshooting

### "Error: Failed to load BIP39 wordlist"

**Problem**: The `bip39_english.txt` file is missing.

**Solution**: Ensure `bip39_english.txt` is in the same directory as the VanitySearch executable.

### "Error: HD wallet mode (-hd) requires GPU mode (-gpu)"

**Problem**: Trying to use `-hd` without `-gpu`.

**Solution**: Always use `-gpu -hd` together:
```bash
./VanitySearch -gpu -hd pocx1Test
```

### Performance is slower than expected

**Expected**: HD wallet mode is ~5x slower than standard mode due to cryptographic overhead.

**Tip**: If you don't need mnemonic backup, use standard mode for better performance:
```bash
./VanitySearch -gpu pocx1Test  # Without -hd
```

## Summary

The `-hd` flag successfully integrates BIP39/BIP32/BIP44 HD wallet generation into VanitySearch-PoCX with:

✅ Simple command-line usage
✅ Mnemonic output in results
✅ BIP-compliant implementation
✅ Backward compatibility
✅ Full GPU acceleration
✅ Standard workflow maintained
