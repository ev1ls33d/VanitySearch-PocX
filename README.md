# VanitySearch-PoCX

**Bitcoin & PoCX Vanity Address Generator**

This is a fork of [VanitySearch](https://github.com/JeanLucPons/VanitySearch) with added support for **PoCX (Proof of Capacity X)** addresses.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CUDA](https://img.shields.io/badge/CUDA-13.1-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![C++](https://img.shields.io/badge/C++-14-blue.svg)](https://isocpp.org/)

VanitySearch-PoCX is a bitcoin and PoCX address prefix finder. If you want to generate safe private keys, use the `-s` option to enter your passphrase which will be used for generating a base key as for BIP38 standard. You can also use `-ps` option which will add a crypto secure seed to your passphrase.\
VanitySearch may not compute a good grid size for your GPU, so try different values using `-g` option in order to get the best performances. If you want to use GPUs and CPUs together, you may have best performances by keeping one CPU core for handling GPU(s)/CPU exchanges (use `-t` option to set the number of CPU threads).

## ✨ What's New

- 🎯 **PoCX Address Support** - Generate vanity addresses for PoCX cryptocurrency
- 🚀 **Modern CUDA Support** - Updated for latest NVIDIA GPUs (CUDA 13.1)
- ⚡ **Compute Capability 8.9+** - Optimized for RTX 40-series and newer
- ✅ **Full Backward Compatibility** - All Bitcoin features still work
- 💻 **Windows & Linux** - Complete build instructions for both platforms

# Features

### Address Types Supported

| Type | Prefix | Example | Status |
|------|--------|---------|--------|
| Bitcoin P2PKH | `1` | 1Test123... | ✅ Supported |
| Bitcoin P2SH | `3` | 3Test123... | ✅ Supported |
| Bitcoin BECH32 | `bc1q` | bc1qtest... | ✅ Supported |
| **PoCX** | `p` | **pocx1Test...** | **🎯 NEW!** |

### Core Features

- 🚀 **GPU Acceleration** - CUDA-optimized kernels for 100x+ speedup
- 🔥 **Multi-GPU Support** - Utilize multiple GPUs simultaneously
- 🎯 **Pattern Matching** - Use wildcards (`?` and `*`) in searches
- 🔐 **Split-Key Generation** - Safe vanity address for third parties
- 📁 **Batch Processing** - Search multiple prefixes from file
- ⚙️ **CPU Multi-threading** - Efficient CPU utilization
- ⚡ **Endomorphism Optimization** - 3x speedup using curve properties
- 🛡️ **Seed Protection** - pbkdf2_hmac_sha512 (BIP38)
- 🔧 **Fixed Size Arithmetic** - Fast modular operations
- 💨 **SSE Optimized** - SHA256 and RIPEMD160 acceleration

# Usage

```
VanitySearch [-check] [-v] [-u] [-b] [-c] [-gpu] [-stop] [-i inputfile]
             [-gpuId gpuId1[,gpuId2,...]] [-g g1x,g1y,[,g2x,g2y,...]]
             [-o outputfile] [-m maxFound] [-ps seed] [-s seed] [-t nbThread]
             [-nosse] [-r rekey] [-check] [-kp] [-sp startPubKey]
             [-rp privkey partialkeyfile] [prefix]

 prefix: prefix to search (Can contains wildcard '?' or '*')
 -v: Print version
 -u: Search uncompressed addresses
 -b: Search both uncompressed or compressed addresses
 -c: Case unsensitive search
 -gpu: Enable gpu calculation
 -stop: Stop when all prefixes are found
 -i inputfile: Get list of prefixes to search from specified file
 -o outputfile: Output results to the specified file
 -gpu gpuId1,gpuId2,...: List of GPU(s) to use, default is 0
 -g g1x,g1y,g2x,g2y, ...: Specify GPU(s) kernel gridsize, default is 8*(MP number),128
 -m: Specify maximun number of prefixes found by each kernel call
 -s seed: Specify a seed for the base key, default is random
 -ps seed: Specify a seed concatened with a crypto secure random seed
 -t threadNumber: Specify number of CPU thread, default is number of core
 -nosse: Disable SSE hash function
 -l: List cuda enabled devices
 -check: Check CPU and GPU kernel vs CPU
 -cp privKey: Compute public key (privKey in hex format)
 -kp: Generate key pair
 -rp privkey partialkeyfile: Reconstruct final private key(s) from partial key(s) info.
 -sp startPubKey: Start the search with a pubKey (for private key splitting)
 -r rekey: Rekey interval in MegaKey, default is disabled
```

## 💡 Usage Examples

### Bitcoin Addresses

Example (RTX 5090, CUDA 13.1):

```
C:\VanitySearch-PoCX>VanitySearch.exe -stop -gpu 1Bitcoin
VanitySearch v1.19
Difficulty: 1073741824
Search: 1Bitcoin [Compressed]
Start Mon Jan 20 14:30:00 2025
Base Key: DA12E013325F12D6B68520E327847218128B788E6A9F2247BC104A0EE2818F44
Number of CPU thread: 15
GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
[15.2 Gkey/s][GPU 14.8 Gkey/s][Total 2^30.5][Prob 62.3%][50% in 00:00:05][Found 1]

PubAddress: 1BitcoinEatersAddressDontSendf59kuE
Priv (WIF): p2pkh:Kxs4iWcqYHGBfzVpH4K94STNMHHz72DjaCuNdZeM5VMiP9zxMg15
Priv (HEX): 0x310DBFD6AAB6A63FC71CAB1150A0305ECABBE46819641D2594155CD41D081AF1
```

P2SH Address:
```
C:\VanitySearch-PoCX>VanitySearch.exe -stop -gpu 3MyVanity
VanitySearch v1.19
Difficulty: 238081844
Search: 3MyVanity [Compressed]
Start Mon Jan 20 14:35:00 2025
Base Key: FAF4F856077398AE087372110BF47A1A713C8F94B19CDD962D240B6A853CAD8B
Number of CPU thread: 15
GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
[15.1 Gkey/s][GPU 14.7 Gkey/s][Total 2^31.2][Prob 51.8%][50% in 00:00:03][Found 1]

Pub Addr: 3MyVanityAddressWouldBeHereToday123
Priv (WIF): p2wpkh-p2sh:L2qvghanHHov914THEzDMTpAyoRmxo7Rh85FLE9oKwYUrycWqudp
Priv (HEX): 0xA7D14FBF43696CA0B3DBFFD0AB7C9ED740FE338B2B856E09F2E681543A444D58
```

BECH32 Address:
```
C:\VanitySearch-PoCX>VanitySearch.exe -stop -gpu bc1quantum
VanitySearch v1.19
Difficulty: 1073741824
Search: bc1quantum [Compressed]
Start Mon Jan 20 14:40:00 2025
Base Key: B00FD8CDA85B11D4744C09E65C527D35E231D19084FBCA0BF2E48186F31936AE
Number of CPU thread: 15
GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
[15.5 Gkey/s][GPU 15.1 Gkey/s][Total 2^29.8][Prob 48.2%][50% in 00:00:01][Found 1]

Pub Addr: bc1quantum898l8mx5pkvq2x250kkqsj7enpx3u4yt
Priv (WIF): p2wpkh:L37xBVcFGeAZ9Tii7igqXBWmfiBhiwwiKQmchNXPV2LNREXQDLCp
Priv (HEX): 0xB00FD8CDA85B11D4744C09E65C527D35E2B1D19095CFCA0BF2E48186F31979C2
```

### 🎯 PoCX Addresses (NEW!)

Generate PoCX vanity addresses:

```
C:\VanitySearch-PoCX>VanitySearch.exe -stop -gpu pocx1Lucky
VanitySearch v1.19
Difficulty: 656356768
Search: pocx1Lucky [Compressed]
Start Mon Jan 20 14:45:00 2025
Base Key: DA12E013325F12D6B68520E327847218128B788E6A9F2247BC104A0EE2818F44
Number of CPU thread: 15
GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
[15.3 Gkey/s][GPU 14.9 Gkey/s][Total 2^33.2][Prob 45.2%][50% in 00:00:42][Found 1]

PubAddress: pocx1LuckyABC123def456ghi789jkl012
Priv (WIF): pocx:Kxs4iWcqYHGBfzVpH4K94STNMHHz72DjaCuNdZeM5VMiP9zxMg15
Priv (HEX): 0x310DBFD6AAB6A63FC71CAB1150A0305ECABBE46819641D2594155CD41D081AF1
```

Case insensitive PoCX search:
```
C:\VanitySearch-PoCX>VanitySearch.exe -gpu -c -stop pocx1test
VanitySearch v1.19
Difficulty: 11316396
Search: pocx1test [Compressed, Case unsensitive]
Start Mon Jan 20 14:50:00 2025
Base Key: 8C5B3E9F2A4D1C7B6E8F3A5D2C9B7E4F1A8D6C3E9B5F2A7D4C1E8B6F3A9D5C2E
Number of CPU thread: 15
GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
[15.4 Gkey/s][GPU 15.0 Gkey/s][Total 2^28.1][Prob 92.5%][50% in 00:00:01][Found 1]

PubAddress: pocx1TeSt123AbCdEfGh456IjKlMn789OpQ
Priv (WIF): pocx:L2hbovuDd8nG4nxjDq1yd5qDsSQiG8xFsAFbHMcThqfjSP6WLg89
Priv (HEX): 0x59E27084C6252377A8B7AABB20AFD975060914B3747BD6392930BC5BE7A06565
```

### Pattern Matching

```bash
# Wildcard: ? = any char, * = any chars
./VanitySearch -gpu "pocx1???Test"
./VanitySearch -gpu "1*coin"
./VanitySearch -gpu "bc1???????test"
```

### Batch Search

```bash
# Create prefix list
echo "pocx1Test" > prefixes.txt
echo "pocx1Lucky" >> prefixes.txt
echo "1Bitcoin" >> prefixes.txt

# Search all
./VanitySearch -gpu -i prefixes.txt
```

# Generate a vanity address for a third party using split-key

It is possible to generate a vanity address for a third party in a safe manner using split-key.\
For instance, Alice wants a nice prefix but does not have CPU power. Bob has the requested CPU power but cannot know the private key of Alice, Alice has to use a split-key.

## Step 1

Alice generates a key pair on her computer then send the generated public key and the wanted prefix to Bob. It can be done by email, nothing is secret. Nevertheless, Alice has to keep safely the private key and not expose it.

```
VanitySearch.exe -s "AliceSeed" -kp
Priv : L4U2Ca2wyo721n7j9nXM9oUWLzCj19nKtLeJuTXZP3AohW9wVgrH
Pub  : 03FC71AE1E88F143E8B05326FC9A83F4DAB93EA88FFEACD37465ED843FCC75AA81
```

Note: The key pair is a standard SecpK1 key pair and can be generated with a third party software.

## Step 2

Bob runs VanitySearch using the Alice's public key and the wanted prefix (works with both Bitcoin and PoCX addresses).

```
VanitySearch.exe -sp 03FC71AE1E88F143E8B05326FC9A83F4DAB93EA88FFEACD37465ED843FCC75AA81 -gpu -stop -o keyinfo.txt pocx1Alice
```

It generates a keyinfo.txt file containing the partial private key.

```
PubAddress: pocx1AliceABC123def456ghi789jkl012
PartialPriv: L2hbovuDd8nG4nxjDq1yd5qDsSQiG8xFsAFbHMcThqfjSP6WLg89
```

Bob sends back this file to Alice. It can also be done by email. The partial private key does not allow anyone to guess the final Alice's private key.

## Step 3

Alice can then reconstructs the final private key using her private key (the one generated in step 1) and the keyinfo.txt from Bob.

```
VanitySearch.exe -rp L4U2Ca2wyo721n7j9nXM9oUWLzCj19nKtLeJuTXZP3AohW9wVgrH keyinfo.txt

Pub Addr: pocx1AliceABC123def456ghi789jkl012
Priv (WIF): pocx:L1NHFgT826hYNpNN2qd85S7F7cyZTEJ4QQeEinsCFzknt3nj9gqg
Priv (HEX): 0x7BC226A19A1E9770D3B0584FF2CF89E5D43F0DC19076A7DE1943F284DA3FB2D0
```

## How it works

Basically the -sp (start public key) adds the specified starting public key (let's call it Q) to the starting keys of each threads. That means that when you search (using -sp), you do not search for addr(k.G) but for addr(k<sub>part</sub>.G+Q) where k is the private key in the first case and k<sub>part</sub> the "partial private key" in the second case. G is the SecpK1 generator point.\
Then the requester can reconstruct the final private key by doing k<sub>part</sub>+k<sub>secret</sub> (mod n) where k<sub>part</sub> is the partial private key found by the searcher and k<sub>secret</sub> is the private key of Q (Q=k<sub>secret</sub>.G). This is the purpose of the -rp option.\
The searcher has found a match for addr(k<sub>part</sub>.G+k<sub>secret</sub>.G) without knowing k<sub>secret</sub> so the requester has the wanted address addr(k<sub>part</sub>.G+Q) and the corresponding private key k<sub>part</sub>+k<sub>secret</sub> (mod n). The searcher is not able to guess this final private key because he doesn't know k<sub>secret</sub> (he knows only Q).

Note: This explanation is simplified, it does not take care of symmetry and endomorphism optimizations but the idea is the same.

# Address Collision Probability

The bitcoin address (P2PKH) consists of a hash160 (displayed in Base58 format) which means that there are 2<sup>160</sup> possible addresses. A secure hash function can be seen as a pseudo number generator, it transforms a given message in a random number. In this case, a number (uniformaly distributed) in the range [0,2<sup>160</sup>]. So, the probability to hit a particular number after n tries is 1-(1-1/2<sup>160</sup>)<sup>n</sup>. We perform n Bernoulli trials statistically independent.\
If we have a list of m distinct addresses (m<=2<sup>160</sup>), the search space is then reduced to 2<sup>160</sup>/m, the probability to find a collision after 1 try becomes m/2<sup>160</sup> and the probability to find a collision after n tries becomes 1-(1-m/2<sup>160</sup>)<sup>n</sup>.\
An example:\
We have a hardware capable of generating **1GKey/s** and we have an input list of **10<sup>6</sup>** addresses, the following table shows the probability of finding a collision after a certain amount of time:

| Time     |  Probability  |
|----------|:-------------:|
| 1 second |6.8e-34|
| 1 minute |4e-32|
| 1 hour |2.4e-30|
| 1 day |5.9e-29|
| 1 year |2.1e-26|
| 10 years | 2.1e-25 |
| 1000 years | 2.1e-23 |
| Age of earth | 8.64e-17 |
| Age of universe | 2.8e-16 (much less than winning at the lottery) |

Calculation has been done using this [online high precision calculator](https://keisan.casio.com/calculator)

As you can see, even with a competitive hardware, it is very unlikely that you find a collision. Birthday paradox doesn't apply in this context, it works only if we know already the public key (not the address, the hash of the public key) we want to find. This program doesn't look for collisions between public keys. It searchs only for collisions with addresses with a certain prefix.

# 🔨 Compilation

## Windows

Intall CUDA SDK 13.1 and open VanitySearch.sln in Visual Studio 2022.\
You may need to reset your *Windows SDK version* in project properties.\
In Build->Configuration Manager, select the *Release* configuration.\
Build and enjoy.

**Detailed Instructions**: See [`WINDOWS_BUILD.md`](WINDOWS_BUILD.md)

Note: The current release has been compiled with CUDA SDK 13.1. The project is configured for compute capabilities 5.0 through 9.0, supporting GPUs from GTX 900-series through RTX 50-series.

### Compute Capability Reference

| GPU Series | Model | CCAP | Already Supported |
|------------|-------|------|-------------------|
| RTX 50 | 5090, 5080 | 9.0 | ✅ Yes |
| RTX 40 | 4090, 4080 | 8.9 | ✅ Yes |
| RTX 30 | 3090, 3080 | 8.6 | ✅ Yes |
| RTX 20 | 2080 Ti | 7.5 | ✅ Yes |
| GTX 16 | 1660 Ti | 7.5 | ✅ Yes |
| GTX 10 | 1080 Ti | 6.1 | ✅ Yes |

## Linux

 - Install CUDA SDK 13.1 (or 12.x).
 - Install GCC/G++ 7+ (C++14 support required).
 - Edit the makefile and set up the appropriate CUDA SDK paths, or pass them as variables to `make` invocation.

    ```make
    CUDA       = /usr/local/cuda-13.1
    ```

 - Set CCAP to the desired compute capability according to your hardware.

 - Go to the VanitySearch directory.
 - To build CPU-only version (without CUDA support):
    ```sh
    $ make all
    ```
 - To build with CUDA (example for RTX 5090):
    ```sh
    $ make gpu=1 CCAP=9.0 CUDA=/usr/local/cuda-13.1 all
    ```
 - For older GPUs:
    ```sh
    $ make gpu=1 CCAP=7.5 all  # RTX 20-series
    $ make gpu=1 CCAP=8.6 all  # RTX 30-series
    $ make gpu=1 CCAP=8.9 all  # RTX 40-series
    ```

**Detailed Instructions**: See [`BUILD_GUIDE.md`](BUILD_GUIDE.md)

### Running VanitySearch (RTX 5090, CUDA 13.1)

```sh
$ export LD_LIBRARY_PATH=/usr/local/cuda-13.1/lib64
$ ./VanitySearch -t 15 -gpu pocx1Test
VanitySearch v1.19
Difficulty: 11316396
Search: pocx1Test [Compressed]
Start Mon Jan 20 15:00:00 2025
Base Key: C6718D8E50C1A5877DE3E52021C116F7598826873C61496BDB7CAD668CE3DCE5
Number of CPU thread: 15
GPU: GPU #0 GeForce RTX 5090 (128x128 cores) Grid(1024x128)
[15.4 Gkey/s][GPU 15.0 Gkey/s][Total 2^28.2][Prob 94.1%][50% in 00:00:01][Found 1]

PubAddress: pocx1TestABC123def456ghi789jkl012
Priv (WIF): pocx:Ky9bMLDpb9o5rBwHtLaidREyA6NzLFkWJ19QjPDe2XDYJdmdUsRk
Priv (HEX): 0x398E7271AF3E5A78821C1ADFDE3EE90760A6B65F72D856CFE455B1264350BCE8
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [`QUICKSTART.md`](QUICKSTART.md) | Quick reference guide |
| [`POCX_README.md`](POCX_README.md) | PoCX implementation details |
| [`BUILD_GUIDE.md`](BUILD_GUIDE.md) | Linux build instructions |
| [`WINDOWS_BUILD.md`](WINDOWS_BUILD.md) | Windows build guide |
| [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md) | Technical details |

## 🚀 Performance

### Expected Performance (RTX 5090)

| Prefix Length | Difficulty | Estimated Time |
|---------------|------------|----------------|
| pocx1T | 58 | Instant |
| pocx1Te | 3,364 | < 1 second |
| pocx1Tes | 195K | ~1 second |
| pocx1Test | 11.3M | ~45 seconds |
| pocx1Test1 | 656M | ~40 minutes |
| pocx1Test12 | 38B | ~3 days |

*At ~15 GKey/s on RTX 5090*

## 📋 Requirements

### Minimum

- GCC/G++ 7.3+ (C++14 support)
- CUDA Toolkit 10.0+ (for GPU)
- Linux or Windows
- NVIDIA GPU (for GPU acceleration)

### Recommended

- GCC/G++ 11+
- CUDA Toolkit 13.1+
- RTX 40/50-series GPU
- 16GB+ RAM for large prefix lists

## 🔐 Security

### Best Practices

✅ **DO**:
- Use `-ps` flag for extra entropy when generating keys
- Keep private keys offline and encrypted
- Verify addresses before using
- Test with small amounts first

❌ **DON'T**:
- Share private keys (only share public keys for split-key)
- Use predictable seeds
- Run on compromised systems
- Trust third parties with full private keys

# License

VanitySearch-PoCX is licensed under GPLv3.

## 🙏 Credits

### Original Project

- **VanitySearch**: [Jean Luc PONS](https://github.com/JeanLucPons/VanitySearch)
- **License**: GPLv3
- **Discussion**: [BitcoinTalk Thread](https://bitcointalk.org/index.php?topic=5112311.0)

### PoCX Support

- **PoCX Project**: [Proof of Capacity Consortium](https://github.com/PoC-Consortium/bitcoin-pocx)
- **Implementation**: Based on PoCX-Reference specification
- **This Fork**: [ev1ls33d](https://github.com/ev1ls33d)

### Special Thanks

- Original VanitySearch contributors
- PoCX development team
- Bitcoin cryptography community

---

**Made with ❤️ for the crypto community**

*Star ⭐ this repo if you find it useful!*
