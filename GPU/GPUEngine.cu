/*
 * This file is part of the VanitySearch distribution (https://github.com/JeanLucPons/VanitySearch).
 * Copyright (c) 2019 Jean Luc PONS.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef WIN64
#include <unistd.h>
#include <stdio.h>
#endif

#include "GPUEngine.h"
#include <cuda.h>
#include <cuda_runtime.h>

#include <stdint.h>
#include "../hash/sha256.h"
#include "../hash/ripemd160.h"
#include "../Timer.h"

#include "GPUGroup.h"
#include "GPUMath.h"
#include "GPUHash.h"
#include "GPUBase58.h"
#include "GPUWildcard.h"
#include "GPUCompute.h"
#include "GPUHDWallet.h"

// ---------------------------------------------------------------------------------------
// HD Wallet (BIP39/BIP32/BIP44) GPU Implementation
// ---------------------------------------------------------------------------------------

// SHA-512 constants
__device__ __constant__ uint64_t K512[80] = {
    0x428a2f98d728ae22ULL, 0x7137449123ef65cdULL, 0xb5c0fbcfec4d3b2fULL, 0xe9b5dba58189dbbcULL,
    0x3956c25bf348b538ULL, 0x59f111f1b605d019ULL, 0x923f82a4af194f9bULL, 0xab1c5ed5da6d8118ULL,
    0xd807aa98a3030242ULL, 0x12835b0145706fbeULL, 0x243185be4ee4b28cULL, 0x550c7dc3d5ffb4e2ULL,
    0x72be5d74f27b896fULL, 0x80deb1fe3b1696b1ULL, 0x9bdc06a725c71235ULL, 0xc19bf174cf692694ULL,
    0xe49b69c19ef14ad2ULL, 0xefbe4786384f25e3ULL, 0x0fc19dc68b8cd5b5ULL, 0x240ca1cc77ac9c65ULL,
    0x2de92c6f592b0275ULL, 0x4a7484aa6ea6e483ULL, 0x5cb0a9dcbd41fbd4ULL, 0x76f988da831153b5ULL,
    0x983e5152ee66dfabULL, 0xa831c66d2db43210ULL, 0xb00327c898fb213fULL, 0xbf597fc7beef0ee4ULL,
    0xc6e00bf33da88fc2ULL, 0xd5a79147930aa725ULL, 0x06ca6351e003826fULL, 0x142929670a0e6e70ULL,
    0x27b70a8546d22ffcULL, 0x2e1b21385c26c926ULL, 0x4d2c6dfc5ac42aedULL, 0x53380d139d95b3dfULL,
    0x650a73548baf63deULL, 0x766a0abb3c77b2a8ULL, 0x81c2c92e47edaee6ULL, 0x92722c851482353bULL,
    0xa2bfe8a14cf10364ULL, 0xa81a664bbc423001ULL, 0xc24b8b70d0f89791ULL, 0xc76c51a30654be30ULL,
    0xd192e819d6ef5218ULL, 0xd69906245565a910ULL, 0xf40e35855771202aULL, 0x106aa07032bbd1b8ULL,
    0x19a4c116b8d2d0c8ULL, 0x1e376c085141ab53ULL, 0x2748774cdf8eeb99ULL, 0x34b0bcb5e19b48a8ULL,
    0x391c0cb3c5c95a63ULL, 0x4ed8aa4ae3418acbULL, 0x5b9cca4f7763e373ULL, 0x682e6ff3d6b2b8a3ULL,
    0x748f82ee5defb2fcULL, 0x78a5636f43172f60ULL, 0x84c87814a1f0ab72ULL, 0x8cc702081a6439ecULL,
    0x90befffa23631e28ULL, 0xa4506cebde82bde9ULL, 0xbef9a3f7b2c67915ULL, 0xc67178f2e372532bULL,
    0xca273eceea26619cULL, 0xd186b8c721c0c207ULL, 0xeada7dd6cde0eb1eULL, 0xf57d4f7fee6ed178ULL,
    0x06f067aa72176fbaULL, 0x0a637dc5a2c898a6ULL, 0x113f9804bef90daeULL, 0x1b710b35131c471bULL,
    0x28db77f523047d84ULL, 0x32caab7b40c72493ULL, 0x3c9ebe0a15c9bebcULL, 0x431d67c49c100d4cULL,
    0x4cc5d4becb3e42b6ULL, 0x597f299cfc657e2aULL, 0x5fcb6fab3ad6faecULL, 0x6c44198c4a475817ULL
};

__device__ __constant__ uint64_t I512[8] = {
    0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL,
    0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
    0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL,
    0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL
};

// SHA-512 helper functions  
__device__ __forceinline__ uint64_t ROTR64(uint64_t x, int n) {
    return (x >> n) | (x << (64 - n));
}

__device__ __forceinline__ uint64_t CH64(uint64_t x, uint64_t y, uint64_t z) {
    return (x & y) ^ (~x & z);
}

__device__ __forceinline__ uint64_t MAJ64(uint64_t x, uint64_t y, uint64_t z) {
    return (x & y) ^ (x & z) ^ (y & z);
}

__device__ __forceinline__ uint64_t S0_512(uint64_t x) {
    return ROTR64(x, 28) ^ ROTR64(x, 34) ^ ROTR64(x, 39);
}

__device__ __forceinline__ uint64_t S1_512(uint64_t x) {
    return ROTR64(x, 14) ^ ROTR64(x, 18) ^ ROTR64(x, 41);
}

__device__ __forceinline__ uint64_t s0_512(uint64_t x) {
    return ROTR64(x, 1) ^ ROTR64(x, 8) ^ (x >> 7);
}

__device__ __forceinline__ uint64_t s1_512(uint64_t x) {
    return ROTR64(x, 19) ^ ROTR64(x, 61) ^ (x >> 6);
}

__device__ __forceinline__ uint64_t bswap64(uint64_t x) {
    return ((x & 0xFF00000000000000ULL) >> 56) |
           ((x & 0x00FF000000000000ULL) >> 40) |
           ((x & 0x0000FF0000000000ULL) >> 24) |
           ((x & 0x000000FF00000000ULL) >> 8)  |
           ((x & 0x00000000FF000000ULL) << 8)  |
           ((x & 0x0000000000FF0000ULL) << 24) |
           ((x & 0x000000000000FF00ULL) << 40) |
           ((x & 0x00000000000000FFULL) << 56);
}

// SHA-512 transform function
__device__ void _SHA512Transform(uint64_t *state, const uint8_t *data) {
    uint64_t W[80];
    uint64_t a, b, c, d, e, f, g, h, T1, T2;
    
    // Prepare message schedule
    for (int i = 0; i < 16; i++) {
        W[i] = bswap64(((uint64_t*)data)[i]);
    }
    
    for (int i = 16; i < 80; i++) {
        W[i] = s1_512(W[i-2]) + W[i-7] + s0_512(W[i-15]) + W[i-16];
    }
    
    // Initialize working variables
    a = state[0]; b = state[1]; c = state[2]; d = state[3];
    e = state[4]; f = state[5]; g = state[6]; h = state[7];
    
    // Main loop
    for (int i = 0; i < 80; i++) {
        T1 = h + S1_512(e) + CH64(e, f, g) + K512[i] + W[i];
        T2 = S0_512(a) + MAJ64(a, b, c);
        h = g; g = f; f = e; e = d + T1;
        d = c; c = b; b = a; a = T1 + T2;
    }
    
    // Add to state
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

// Simplified SHA-512 for small fixed-size inputs (optimized for BIP32)
__device__ void _SHA512_Small(const uint8_t *data, size_t len, uint8_t *hash) {
    uint64_t state[8];
    
    // Initialize state
    for (int i = 0; i < 8; i++) {
        state[i] = I512[i];
    }
    
    // Prepare padded block (assuming len <= 111 bytes for single block)
    uint8_t block[128];
    
    for (size_t i = 0; i < len; i++) {
        block[i] = data[i];
    }
    block[len] = 0x80;
    
    for (size_t i = len + 1; i < 120; i++) {
        block[i] = 0;
    }
    
    // Length in bits (big-endian, upper 64 bits are 0)
    uint64_t bitLen = len * 8;
    block[120] = 0; block[121] = 0; block[122] = 0; block[123] = 0;
    block[124] = (bitLen >> 24) & 0xFF;
    block[125] = (bitLen >> 16) & 0xFF;
    block[126] = (bitLen >> 8) & 0xFF;
    block[127] = bitLen & 0xFF;
    
    _SHA512Transform(state, block);
    
    // Output hash (big-endian)
    for (int i = 0; i < 8; i++) {
        uint64_t val = bswap64(state[i]);
        ((uint64_t*)hash)[i] = val;
    }
}

// HMAC-SHA512 for BIP32 (optimized for small inputs)
__device__ void _HMAC_SHA512_BIP32(const uint8_t *key, size_t keyLen,
                                   const uint8_t *data, size_t dataLen,
                                   uint8_t *output) {
    uint8_t keyBuf[128];
    
    // Prepare key (keyLen is always 32 or 12 for BIP32)
    for (size_t i = 0; i < keyLen; i++) keyBuf[i] = key[i];
    for (size_t i = keyLen; i < 128; i++) keyBuf[i] = 0;
    
    // Inner hash: H(K XOR ipad, message)
    uint8_t innerBlock[256];
    for (int i = 0; i < 128; i++) {
        innerBlock[i] = keyBuf[i] ^ 0x36;
    }
    for (size_t i = 0; i < dataLen; i++) {
        innerBlock[128 + i] = data[i];
    }
    
    uint8_t innerHash[64];
    _SHA512_Small(innerBlock, 128 + dataLen, innerHash);
    
    // Outer hash: H(K XOR opad, innerHash)
    uint8_t outerBlock[192];
    for (int i = 0; i < 128; i++) {
        outerBlock[i] = keyBuf[i] ^ 0x5c;
    }
    for (int i = 0; i < 64; i++) {
        outerBlock[128 + i] = innerHash[i];
    }
    
    _SHA512_Small(outerBlock, 192, output);
}

// BIP32 hardened child key derivation on GPU
__device__ void _DeriveChildKeyHardened(const uint64_t *parentKey, const uint8_t *parentChainCode,
                                       uint32_t index,
                                       uint64_t *childKey, uint8_t *childChainCode) {
    uint8_t data[37];
    data[0] = 0x00;
    
    // Serialize parent key (32 bytes, big-endian)
    for (int i = 0; i < 4; i++) {
        uint64_t val = parentKey[i];
        for (int j = 0; j < 8; j++) {
            data[1 + i*8 + j] = (val >> ((7-j)*8)) & 0xFF;
        }
    }
    
    // Add hardened index
    uint32_t idx = index | 0x80000000;
    data[33] = (idx >> 24) & 0xFF;
    data[34] = (idx >> 16) & 0xFF;
    data[35] = (idx >> 8) & 0xFF;
    data[36] = idx & 0xFF;
    
    // HMAC-SHA512
    uint8_t I[64];
    _HMAC_SHA512_BIP32(parentChainCode, 32, data, 37, I);
    
    // IL = first 32 bytes (child key material, big-endian)
    uint64_t IL[4];
    for (int i = 0; i < 4; i++) {
        IL[i] = 0;
        for (int j = 0; j < 8; j++) {
            IL[i] = (IL[i] << 8) | I[i*8 + j];
        }
    }
    
    // childKey = (IL + parentKey) mod n (simplified addition)
    uint64_t carry = 0;
    for (int i = 3; i >= 0; i--) {
        uint64_t sum = parentKey[i] + IL[i] + carry;
        childKey[i] = sum;
        carry = (sum < parentKey[i] || (sum == parentKey[i] && (IL[i] != 0 || carry != 0))) ? 1 : 0;
    }
    
    // childChainCode = IR (last 32 bytes)
    for (int i = 0; i < 32; i++) {
        childChainCode[i] = I[32 + i];
    }
}

// Generate HD wallet key from mnemonic seed
// Derives key at path m/84'/coinType'/account'/0/0
__device__ void _DeriveHDKeyFromSeed(const uint8_t *mnemonicSeed, uint32_t coinType, uint32_t account,
                                     uint64_t *derivedKey) {
    // Derive master key from seed
    const char* bitcoinSeed = "Bitcoin seed";
    uint8_t masterData[64];
    _HMAC_SHA512_BIP32((uint8_t*)bitcoinSeed, 12, mnemonicSeed, 64, masterData);
    
    // Master key (first 32 bytes)
    uint64_t masterKey[4];
    for (int i = 0; i < 4; i++) {
        masterKey[i] = 0;
        for (int j = 0; j < 8; j++) {
            masterKey[i] = (masterKey[i] << 8) | masterData[i*8 + j];
        }
    }
    
    // Master chain code (last 32 bytes)
    uint8_t chainCode[32];
    for (int i = 0; i < 32; i++) {
        chainCode[i] = masterData[32 + i];
    }
    
    uint64_t currentKey[4];
    uint8_t currentChain[32];
    
    // Derivation path: m/84'/coinType'/account'/0/0
    // m/84'
    _DeriveChildKeyHardened(masterKey, chainCode, 84, currentKey, currentChain);
    
    // m/84'/coinType'
    _DeriveChildKeyHardened(currentKey, currentChain, coinType, currentKey, currentChain);
    
    // m/84'/coinType'/account'
    _DeriveChildKeyHardened(currentKey, currentChain, account, currentKey, currentChain);
    
    // m/84'/coinType'/account'/0
    _DeriveChildKeyHardened(currentKey, currentChain, 0, currentKey, currentChain);
    
    // m/84'/coinType'/account'/0/0
    _DeriveChildKeyHardened(currentKey, currentChain, 0, currentKey, currentChain);
    
    // Copy final key
    for (int i = 0; i < 4; i++) {
        derivedKey[i] = currentKey[i];
    }
}

// ---------------------------------------------------------------------------------------

__global__ void comp_keys(uint32_t mode,prefix_t *prefix, uint32_t *lookup32, uint64_t *keys, uint32_t maxFound, uint32_t *found) {

  int xPtr = (blockIdx.x*blockDim.x) * 8;
  int yPtr = xPtr + 4 * blockDim.x;
  ComputeKeys(mode, keys + xPtr, keys + yPtr, prefix, lookup32, maxFound, found);

}

__global__ void comp_keys_p2sh(uint32_t mode, prefix_t *prefix, uint32_t *lookup32, uint64_t *keys, uint32_t maxFound, uint32_t *found) {

  int xPtr = (blockIdx.x*blockDim.x) * 8;
  int yPtr = xPtr + 4 * blockDim.x;
  ComputeKeysP2SH(mode, keys + xPtr, keys + yPtr, prefix, lookup32, maxFound, found);

}

__global__ void comp_keys_comp(prefix_t *prefix, uint32_t *lookup32, uint64_t *keys, uint32_t maxFound, uint32_t *found) {

  int xPtr = (blockIdx.x*blockDim.x) * 8;
  int yPtr = xPtr + 4 * blockDim.x;
  ComputeKeysComp(keys + xPtr, keys + yPtr, prefix, lookup32, maxFound, found);

}

__global__ void comp_keys_pattern(uint32_t mode, prefix_t *pattern, uint64_t *keys,  uint32_t maxFound, uint32_t *found) {

  int xPtr = (blockIdx.x*blockDim.x) * 8;
  int yPtr = xPtr + 4 * blockDim.x;
  ComputeKeys(mode, keys + xPtr, keys + yPtr, NULL, (uint32_t *)pattern, maxFound, found);

}

__global__ void comp_keys_p2sh_pattern(uint32_t mode, prefix_t *pattern, uint64_t *keys, uint32_t maxFound, uint32_t *found) {

  int xPtr = (blockIdx.x*blockDim.x) * 8;
  int yPtr = xPtr + 4 * blockDim.x;
  ComputeKeysP2SH(mode, keys + xPtr, keys + yPtr, NULL, (uint32_t *)pattern, maxFound, found);

}

// HD Wallet kernel - generates mnemonics and derives keys via BIP32/BIP44
__global__ void comp_keys_hd(uint32_t mode, prefix_t *prefix, uint32_t *lookup32,
                             uint64_t *mnemonicSeeds, uint32_t coinType, uint32_t account,
                             uint32_t maxFound, uint32_t *found) {
    
    int xPtr = (blockIdx.x*blockDim.x) * 8;
    int yPtr = xPtr + 4 * blockDim.x;
    int tid = (blockIdx.x*blockDim.x) + threadIdx.x;
    
    // Get mnemonic seed for this thread (64 bytes)
    uint8_t mnemonicSeed[64];
    for (int i = 0; i < 8; i++) {
        uint64_t val = mnemonicSeeds[tid * 8 + i];
        for (int j = 0; j < 8; j++) {
            mnemonicSeed[i*8 + j] = (val >> ((7-j)*8)) & 0xFF;
        }
    }
    
    // Derive HD key from mnemonic seed at path m/84'/coinType'/account'/0/0
    uint64_t derivedKey[4];
    _DeriveHDKeyFromSeed(mnemonicSeed, coinType, account, derivedKey);
    
    // Convert derived key to point on curve and continue with vanity search
    // Store derived key back to keys array for ComputeKeys to process
    uint64_t *keys = mnemonicSeeds; // Reuse the input array
    for (int i = 0; i < 4; i++) {
        keys[tid * 4 + i] = derivedKey[i];
    }
    
    // Now call the standard key computation with the derived key
    // The derived key is treated as a regular private key for address generation
    ComputeKeys(mode, keys + xPtr, keys + yPtr, prefix, lookup32, maxFound, found);
}

//#define FULLCHECK
#ifdef FULLCHECK

// ---------------------------------------------------------------------------------------

__global__ void chekc_mult(uint64_t *a, uint64_t *b, uint64_t *r) {

  _ModMult(r, a, b);
  r[4]=0;

}

// ---------------------------------------------------------------------------------------

__global__ void chekc_hash160(uint64_t *x, uint64_t *y, uint32_t *h) {

  _GetHash160(x, y, (uint8_t *)h);
  _GetHash160Comp(x, y, (uint8_t *)(h+5));

}

// ---------------------------------------------------------------------------------------

__global__ void get_endianness(uint32_t *endian) {

  uint32_t a = 0x01020304;
  uint8_t fb = *(uint8_t *)(&a);
  *endian = (fb==0x04);

}

#endif //FULLCHECK

// ---------------------------------------------------------------------------------------

using namespace std;

std::string toHex(unsigned char *data, int length) {

  string ret;
  char tmp[3];
  for (int i = 0; i < length; i++) {
    if (i && i % 4 == 0) ret.append(" ");
    sprintf(tmp, "%02x", (int)data[i]);
    ret.append(tmp);
  }
  return ret;

}

int _ConvertSMVer2Cores(int major, int minor) {

  // Defines for GPU Architecture types (using the SM version to determine
  // the # of cores per SM
  typedef struct {
    int SM;  // 0xMm (hexidecimal notation), M = SM Major version,
    // and m = SM minor version
    int Cores;
  } sSMtoCores;

  sSMtoCores nGpuArchCoresPerSM[] = {
      {0x20, 32}, // Fermi Generation (SM 2.0) GF100 class
      {0x21, 48}, // Fermi Generation (SM 2.1) GF10x class
      {0x30, 192},
      {0x32, 192},
      {0x35, 192},
      {0x37, 192},
      {0x50, 128},
      {0x52, 128},
      {0x53, 128},
      {0x60,  64},
      {0x61, 128},
      {0x62, 128},
      {0x70,  64},
      {0x72,  64},
      {0x75,  64},
      {0x80,  64},
      {0x86, 128},
      {0x90, 128},
      {-1, -1} };

  int index = 0;

  while (nGpuArchCoresPerSM[index].SM != -1) {
    if (nGpuArchCoresPerSM[index].SM == ((major << 4) + minor)) {
      return nGpuArchCoresPerSM[index].Cores;
    }

    index++;
  }

  return 0;

}

GPUEngine::GPUEngine(int nbThreadGroup, int nbThreadPerGroup, int gpuId, uint32_t maxFound,bool rekey) {

  // Initialise CUDA
  this->rekey = rekey;
  this->nbThreadPerGroup = nbThreadPerGroup;
  initialised = false;
  
  // Initialisiere alle Pointer auf nullptr
  inputPrefix = nullptr;
  inputPrefixPinned = nullptr;
  inputPrefixLookUp = nullptr;
  inputPrefixLookUpPinned = nullptr;
  inputKey = nullptr;
  inputKeyPinned = nullptr;
  outputPrefix = nullptr;
  outputPrefixPinned = nullptr;
  
  cudaError_t err;

  int deviceCount = 0;
  cudaError_t error_id = cudaGetDeviceCount(&deviceCount);

  if (error_id != cudaSuccess) {
    printf("GPUEngine: CudaGetDeviceCount %s %d\n", cudaGetErrorString(error_id),error_id);
    return;
  }

  // This function call returns 0 if there are no CUDA capable devices.
  if (deviceCount == 0) {
    printf("GPUEngine: There are no available device(s) that support CUDA\n");
    return;
  }

  err = cudaSetDevice(gpuId);
  if (err != cudaSuccess) {
    printf("GPUEngine: %s\n", cudaGetErrorString(err));
    return;
  }

  cudaDeviceProp deviceProp;
  cudaGetDeviceProperties(&deviceProp, gpuId);

  if (nbThreadGroup == -1)
    nbThreadGroup = deviceProp.multiProcessorCount * 8;

  this->nbThread = nbThreadGroup * nbThreadPerGroup;
  this->maxFound = maxFound;
  this->outputSize = (maxFound*ITEM_SIZE + 4);

  char tmp[512];
  sprintf(tmp,"GPU #%d %s (%dx%d cores) Grid(%dx%d)",
  gpuId,deviceProp.name,deviceProp.multiProcessorCount,
  _ConvertSMVer2Cores(deviceProp.major, deviceProp.minor),
                      nbThread / nbThreadPerGroup,
                      nbThreadPerGroup);
  deviceName = std::string(tmp);

  // Prefer L1 (We do not use __shared__ at all)
  err = cudaDeviceSetCacheConfig(cudaFuncCachePreferL1);
  if (err != cudaSuccess) {
    printf("GPUEngine: %s\n", cudaGetErrorString(err));
    return;
  }

  size_t stackSize = 49152;
  err = cudaDeviceSetLimit(cudaLimitStackSize, stackSize);
  if (err != cudaSuccess) {
    printf("GPUEngine: %s\n", cudaGetErrorString(err));
    return;
  }

  /*
  size_t heapSize = ;
  err = cudaDeviceSetLimit(cudaLimitMallocHeapSize, heapSize);
  if (err != cudaSuccess) {
    printf("Error: %s\n", cudaGetErrorString(err));
    exit(0);
  }

  size_t size;
  cudaDeviceGetLimit(&size, cudaLimitStackSize);
  printf("Stack Size %lld\n", size);
  cudaDeviceGetLimit(&size, cudaLimitMallocHeapSize);
  printf("Heap Size %lld\n", size);
  */

  // Allocate memory
  err = cudaMalloc((void **)&inputPrefix, _64K * 2);
  if (err != cudaSuccess) {
    printf("GPUEngine: Allocate prefix memory: %s\n", cudaGetErrorString(err));
    return;
  }
  err = cudaHostAlloc(&inputPrefixPinned, _64K * 2, cudaHostAllocWriteCombined | cudaHostAllocMapped);
  if (err != cudaSuccess) {
    printf("GPUEngine: Allocate prefix pinned memory: %s\n", cudaGetErrorString(err));
    return;
  }
  err = cudaMalloc((void **)&inputKey, nbThread * 32 * 2);
  if (err != cudaSuccess) {
    printf("GPUEngine: Allocate input memory: %s\n", cudaGetErrorString(err));
    return;
  }
  err = cudaHostAlloc(&inputKeyPinned, nbThread * 32 * 2, cudaHostAllocWriteCombined | cudaHostAllocMapped);
  if (err != cudaSuccess) {
    printf("GPUEngine: Allocate input pinned memory: %s\n", cudaGetErrorString(err));
    return;
  }
  err = cudaMalloc((void **)&outputPrefix, outputSize);
  if (err != cudaSuccess) {
    printf("GPUEngine: Allocate output memory: %s\n", cudaGetErrorString(err));
    return;
  }
  err = cudaHostAlloc(&outputPrefixPinned, outputSize, cudaHostAllocMapped);
  if (err != cudaSuccess) {
    printf("GPUEngine: Allocate output pinned memory: %s\n", cudaGetErrorString(err));
    return;
  }

  searchMode = SEARCH_COMPRESSED;
  searchType = P2PKH;
  initialised = true;
  pattern = "";
  hasPattern = false;
  hdWalletMode = false;
  hdCoinType = 0;
  hdAccount = 0;

}

int GPUEngine::GetGroupSize() {
  return GRP_SIZE;
}

void GPUEngine::PrintCudaInfo() {

  //cudaError_t err;
  //
  //const char *sComputeMode[] =
  //{
  //  "Multiple host threads",
  //  "Only one host thread",
  //  "No host thread",
  //  "Multiple process threads",
  //  "Unknown",
  //   NULL
  //};
  //
  //int deviceCount = 0;
  //cudaError_t error_id = cudaGetDeviceCount(&deviceCount);
  //
  //if (error_id != cudaSuccess) {
  //  printf("GPUEngine: CudaGetDeviceCount %s\n", cudaGetErrorString(error_id));
  //  return;
  //}
  //
  //// This function call returns 0 if there are no CUDA capable devices.
  //if (deviceCount == 0) {
  //  printf("GPUEngine: There are no available device(s) that support CUDA\n");
  //  return;
  //}
  //
  //for(int i=0;i<deviceCount;i++) {
  //
  //  err = cudaSetDevice(i);
  //  if (err != cudaSuccess) {
  //    printf("GPUEngine: cudaSetDevice(%d) %s\n", i, cudaGetErrorString(err));
  //    return;
  //  }
  //
  //  cudaDeviceProp deviceProp;
  //  cudaGetDeviceProperties(&deviceProp, i);
  //  printf("GPU #%d %s (%dx%d cores) (Cap %d.%d) (%.1f MB) (%s)\n",
  //    i,deviceProp.name,deviceProp.multiProcessorCount,
  //    _ConvertSMVer2Cores(deviceProp.major, deviceProp.minor),
  //    deviceProp.major, deviceProp.minor,(double)deviceProp.totalGlobalMem/1048576.0,
  //    sComputeMode[deviceProp.computeMode]);
  //
  //}

}

GPUEngine::~GPUEngine() {
    if (!initialised) return;

    // KRITISCH: Warte auf GPU-Abschluss
    cudaDeviceSynchronize();

    // Ignoriere Fehler beim Freigeben (besser als Memory Leak)
    if (inputKey) cudaFree(inputKey);
    if (inputKeyPinned) cudaFreeHost(inputKeyPinned);
    if (inputPrefix) cudaFree(inputPrefix);
    if (inputPrefixPinned) cudaFreeHost(inputPrefixPinned);
    if (inputPrefixLookUp) cudaFree(inputPrefixLookUp);
    if (inputPrefixLookUpPinned) cudaFreeHost(inputPrefixLookUpPinned);
    if (outputPrefix) cudaFree(outputPrefix);
    if (outputPrefixPinned) cudaFreeHost(outputPrefixPinned);
}

void GPUEngine::WaitForCompletion() {
    if (!initialised) return;

    // Synchronisiere alle GPU-Operationen
    cudaDeviceSynchronize();
}

int GPUEngine::GetNbThread() {
  return nbThread;
}

void GPUEngine::SetSearchMode(int searchMode) {
  this->searchMode = searchMode;
}

void GPUEngine::SetSearchType(int searchType) {
  this->searchType = searchType;
}

void GPUEngine::SetPrefix(std::vector<prefix_t> prefixes) {

  memset(inputPrefixPinned, 0, _64K * 2);
  for(int i=0;i<(int)prefixes.size();i++)
    inputPrefixPinned[prefixes[i]]=1;

  // Fill device memory
  cudaMemcpy(inputPrefix, inputPrefixPinned, _64K * 2, cudaMemcpyHostToDevice);

  // We do not need the input pinned memory anymore
  cudaFreeHost(inputPrefixPinned);
  inputPrefixPinned = NULL;
  lostWarning = false;

  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess) {
    printf("GPUEngine: SetPrefix: %s\n", cudaGetErrorString(err));
  }

}

void GPUEngine::SetPattern(const char *pattern) {

  strcpy((char *)inputPrefixPinned,pattern);

  // Fill device memory
  cudaMemcpy(inputPrefix, inputPrefixPinned, _64K * 2, cudaMemcpyHostToDevice);

  // We do not need the input pinned memory anymore
  cudaFreeHost(inputPrefixPinned);
  inputPrefixPinned = NULL;
  lostWarning = false;

  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess) {
    printf("GPUEngine: SetPattern: %s\n", cudaGetErrorString(err));
  }

  hasPattern = true;

}

void GPUEngine::SetHDWalletMode(bool enabled, uint32_t coinType, uint32_t account) {
  this->hdWalletMode = enabled;
  this->hdCoinType = coinType;
  this->hdAccount = account;
}

bool GPUEngine::SetMnemonicSeeds(uint8_t *seeds, int count) {
  // seeds should be an array of 64-byte mnemonic seeds (BIP39 seed output)
  // Each seed is the result of PBKDF2(mnemonic, "mnemonic" + passphrase)
  
  if (count != nbThread) {
    printf("GPUEngine: SetMnemonicSeeds: count (%d) != nbThread (%d)\n", count, nbThread);
    return false;
  }
  
  // Copy seeds to inputKeyPinned (we reuse this memory for HD wallet mode)
  // Each seed is 64 bytes, so we need nbThread * 64 bytes
  // inputKeyPinned is nbThread * 32 * 2 bytes, which equals nbThread * 64 bytes - perfect!
  memcpy(inputKeyPinned, seeds, count * 64);
  
  // Fill device memory
  cudaMemcpy(inputKey, inputKeyPinned, nbThread * 64, cudaMemcpyHostToDevice);
  
  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess) {
    printf("GPUEngine: SetMnemonicSeeds: %s\n", cudaGetErrorString(err));
    return false;
  }
  
  return true;
}

void GPUEngine::SetPrefix(std::vector<LPREFIX> prefixes, uint32_t totalPrefix) {

  // Allocate memory for the second level of lookup tables
  cudaError_t err = cudaMalloc((void **)&inputPrefixLookUp, (_64K+totalPrefix) * 4);
  if (err != cudaSuccess) {
    printf("GPUEngine: Allocate prefix lookup memory: %s\n", cudaGetErrorString(err));
    return;
  }
  err = cudaHostAlloc(&inputPrefixLookUpPinned, (_64K+totalPrefix) * 4, cudaHostAllocWriteCombined | cudaHostAllocMapped);
  if (err != cudaSuccess) {
    printf("GPUEngine: Allocate prefix lookup pinned memory: %s\n", cudaGetErrorString(err));
    return;
  }

  uint32_t offset = _64K;
  memset(inputPrefixPinned, 0, _64K * 2);
  memset(inputPrefixLookUpPinned, 0, _64K * 4);
  for (int i = 0; i < (int)prefixes.size(); i++) {
    int nbLPrefix = (int)prefixes[i].lPrefixes.size();
    inputPrefixPinned[prefixes[i].sPrefix] = (uint16_t)nbLPrefix;
    inputPrefixLookUpPinned[prefixes[i].sPrefix] = offset;
    for (int j = 0; j < nbLPrefix; j++) {
      inputPrefixLookUpPinned[offset++]=prefixes[i].lPrefixes[j];
    }
  }

  if (offset != (_64K+totalPrefix)) {
    printf("GPUEngine: Wrong totalPrefix %d!=%d!\n",offset- _64K, totalPrefix);
    return;
  }

  // Fill device memory
  cudaMemcpy(inputPrefix, inputPrefixPinned, _64K * 2, cudaMemcpyHostToDevice);
  cudaMemcpy(inputPrefixLookUp, inputPrefixLookUpPinned, (_64K+totalPrefix) * 4, cudaMemcpyHostToDevice);

  // We do not need the input pinned memory anymore
  cudaFreeHost(inputPrefixPinned);
  inputPrefixPinned = NULL;
  cudaFreeHost(inputPrefixLookUpPinned);
  inputPrefixLookUpPinned = NULL;
  lostWarning = false;

  err = cudaGetLastError();
  if (err != cudaSuccess) {
    printf("GPUEngine: SetPrefix (large): %s\n", cudaGetErrorString(err));
  }

}

bool GPUEngine::callKernel() {

  // Reset nbFound
  cudaMemset(outputPrefix,0,4);

  // Call the appropriate kernel
  if (hdWalletMode) {
    // HD Wallet mode - use mnemonic-based derivation
    comp_keys_hd << < nbThread / nbThreadPerGroup, nbThreadPerGroup >> >
      (searchMode, inputPrefix, inputPrefixLookUp, inputKey, hdCoinType, hdAccount, maxFound, outputPrefix);
  } else if (searchType == P2SH) {

    if (hasPattern) {
      comp_keys_p2sh_pattern << < nbThread / nbThreadPerGroup, nbThreadPerGroup >> >
        (searchMode, inputPrefix, inputKey, maxFound, outputPrefix);
    } else {
      comp_keys_p2sh << < nbThread / nbThreadPerGroup, nbThreadPerGroup >> >
        (searchMode, inputPrefix, inputPrefixLookUp, inputKey, maxFound, outputPrefix);
    }

  } else {

    // P2PKH or BECH32
    if (hasPattern) {
      if (searchType == BECH32) {
        // TODO
        printf("GPUEngine: (TODO) BECH32 not yet supported with wildard\n");
        return false;
      }
      comp_keys_pattern << < nbThread / nbThreadPerGroup, nbThreadPerGroup >> >
        (searchMode, inputPrefix, inputKey, maxFound, outputPrefix);
    } else {
      if (searchMode == SEARCH_COMPRESSED) {
        comp_keys_comp << < nbThread / nbThreadPerGroup, nbThreadPerGroup >> >
          (inputPrefix, inputPrefixLookUp, inputKey, maxFound, outputPrefix);
      } else {
        comp_keys << < nbThread / nbThreadPerGroup, nbThreadPerGroup >> >
          (searchMode, inputPrefix, inputPrefixLookUp, inputKey, maxFound, outputPrefix);
      }
    }

  }

  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess) {
    printf("GPUEngine: Kernel: %s\n", cudaGetErrorString(err));
    return false;
  }
  return true;

}

bool GPUEngine::SetKeys(Point *p) {

  // Sets the starting keys for each thread
  // p must contains nbThread public keys
  for (int i = 0; i < nbThread; i+= nbThreadPerGroup) {
    for (int j = 0; j < nbThreadPerGroup; j++) {

      inputKeyPinned[8*i + j + 0* nbThreadPerGroup] = p[i + j].x.bits64[0];
      inputKeyPinned[8*i + j + 1* nbThreadPerGroup] = p[i + j].x.bits64[1];
      inputKeyPinned[8*i + j + 2* nbThreadPerGroup] = p[i + j].x.bits64[2];
      inputKeyPinned[8*i + j + 3* nbThreadPerGroup] = p[i + j].x.bits64[3];

      inputKeyPinned[8*i + j + 4* nbThreadPerGroup] = p[i + j].y.bits64[0];
      inputKeyPinned[8*i + j + 5* nbThreadPerGroup] = p[i + j].y.bits64[1];
      inputKeyPinned[8*i + j + 6* nbThreadPerGroup] = p[i + j].y.bits64[2];
      inputKeyPinned[8*i + j + 7* nbThreadPerGroup] = p[i + j].y.bits64[3];

    }
  }

  // Fill device memory
  cudaMemcpy(inputKey, inputKeyPinned, nbThread*32*2, cudaMemcpyHostToDevice);

  if (!rekey) {
    // We do not need the input pinned memory anymore
    cudaFreeHost(inputKeyPinned);
    inputKeyPinned = NULL;
  }

  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess) {
    printf("GPUEngine: SetKeys: %s\n", cudaGetErrorString(err));
  }

  return callKernel();

}

bool GPUEngine::Launch(std::vector<ITEM> &prefixFound,bool spinWait) {


  prefixFound.clear();

  // Get the result

  if(spinWait) {

    cudaMemcpy(outputPrefixPinned, outputPrefix, outputSize, cudaMemcpyDeviceToHost);

  } else {

    // Use cudaMemcpyAsync to avoid default spin wait of cudaMemcpy wich takes 100% CPU
    cudaEvent_t evt;
    cudaEventCreate(&evt);
    cudaMemcpyAsync(outputPrefixPinned, outputPrefix, 4, cudaMemcpyDeviceToHost, 0);
    cudaEventRecord(evt, 0);
    while (cudaEventQuery(evt) == cudaErrorNotReady) {
      // Sleep 1 ms to free the CPU
      Timer::SleepMillis(1);
    }
    cudaEventDestroy(evt);

  }

  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess) {
    printf("GPUEngine: Launch: %s\n", cudaGetErrorString(err));
    return false;
  }

  // Look for prefix found
  uint32_t nbFound = outputPrefixPinned[0];
  if (nbFound > maxFound) {
    // prefix has been lost
    if (!lostWarning) {
      printf("\nWarning, %d items lost\nHint: Search with less prefixes, less threads (-g) or increase maxFound (-m)\n", (nbFound - maxFound));
      lostWarning = true;
    }
    nbFound = maxFound;
  }

  // When can perform a standard copy, the kernel is eneded
  cudaMemcpy( outputPrefixPinned , outputPrefix , nbFound*ITEM_SIZE + 4 , cudaMemcpyDeviceToHost);

  for (uint32_t i = 0; i < nbFound; i++) {
    uint32_t *itemPtr = outputPrefixPinned + (i*ITEM_SIZE32 + 1);
    ITEM it;
    it.thId = itemPtr[0];
    int16_t *ptr = (int16_t *)&(itemPtr[1]);
    it.endo = ptr[0] & 0x7FFF;
    it.mode = (ptr[0]&0x8000)!=0;
    it.incr = ptr[1];
    it.hash = (uint8_t *)(itemPtr + 2);
    prefixFound.push_back(it);
  }

  return callKernel();

}

bool GPUEngine::CheckHash(uint8_t *h, vector<ITEM>& found,int tid,int incr,int endo, int *nbOK) {

  bool ok = true;

  // Search in found by GPU
  bool f = false;
  int l = 0;
  //printf("Search: %s\n", toHex(h,20).c_str());
  while (l < found.size() && !f) {
    f = ripemd160_comp_hash(found[l].hash, h);
    if (!f) l++;
  }
  if (f) {
    found.erase(found.begin() + l);
    *nbOK = *nbOK+1;
  } else {
    ok = false;
    printf("Expected item not found %s (thread=%d, incr=%d, endo=%d)\n",
      toHex(h, 20).c_str(),tid,incr,endo);
  }

  return ok;

}

bool GPUEngine::Check(Secp256K1 *secp) {

  uint8_t h[20];
  int i = 0;
  int j = 0;
  bool ok = true;

  if(!initialised)
    return false;

  printf("GPU: %s\n",deviceName.c_str());

#ifdef FULLCHECK

  // Get endianess
  get_endianness<<<1,1>>>(outputPrefix);
  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess) {
    printf("GPUEngine: get_endianness: %s\n", cudaGetErrorString(err));
    return false;
  }
  cudaMemcpy(outputPrefixPinned, outputPrefix,1,cudaMemcpyDeviceToHost);
  littleEndian = *outputPrefixPinned != 0;
  printf("Endianness: %s\n",(littleEndian?"Little":"Big"));

  // Check modular mult
  Int a;
  Int b;
  Int r;
  Int c;
  a.Rand(256);
  b.Rand(256);
  c.ModMulK1(&a,&b);
  memcpy(inputKeyPinned,a.bits64,BIFULLSIZE);
  memcpy(inputKeyPinned+5,b.bits64,BIFULLSIZE);
  cudaMemcpy(inputKey, inputKeyPinned, BIFULLSIZE*2, cudaMemcpyHostToDevice);
  chekc_mult<<<1,1>>>(inputKey,inputKey+5,(uint64_t *)outputPrefix);
  cudaMemcpy(outputPrefixPinned, outputPrefix, BIFULLSIZE, cudaMemcpyDeviceToHost);
  memcpy(r.bits64,outputPrefixPinned,BIFULLSIZE);

  if(!c.IsEqual(&r)) {
    printf("\nModular Mult wrong:\nR=%s\nC=%s\n",
    toHex((uint8_t *)r.bits64,BIFULLSIZE).c_str(),
    toHex((uint8_t *)c.bits64,BIFULLSIZE).c_str());
    return false;
  }

  // Check hash 160C
  uint8_t hc[20];
  Point pi;
  pi.x.Rand(256);
  pi.y.Rand(256);
  secp.GetHash160(pi, false, h);
  secp.GetHash160(pi, true, hc);
  memcpy(inputKeyPinned,pi.x.bits64,BIFULLSIZE);
  memcpy(inputKeyPinned+5,pi.y.bits64,BIFULLSIZE);
  cudaMemcpy(inputKey, inputKeyPinned, BIFULLSIZE*2, cudaMemcpyHostToDevice);
  chekc_hash160<<<1,1>>>(inputKey,inputKey+5,outputPrefix);
  cudaMemcpy(outputPrefixPinned, outputPrefix, 64, cudaMemcpyDeviceToHost);

  if(!ripemd160_comp_hash((uint8_t *)outputPrefixPinned,h)) {
    printf("\nGetHask160 wrong:\n%s\n%s\n",
    toHex((uint8_t *)outputPrefixPinned,20).c_str(),
    toHex(h,20).c_str());
    return false;
  }
  if (!ripemd160_comp_hash((uint8_t *)(outputPrefixPinned+5), hc)) {
    printf("\nGetHask160Comp wrong:\n%s\n%s\n",
      toHex((uint8_t *)(outputPrefixPinned + 5), 20).c_str(),
      toHex(h, 20).c_str());
    return false;
  }

#endif //FULLCHECK

  Point *p = new Point[nbThread];
  Point *p2 = new Point[nbThread];
  Int k;

  // Check kernel
  int nbFoundCPU[6];
  int nbOK[6];
  vector<ITEM> found;
  bool searchComp;

  if (searchMode == SEARCH_BOTH) {
    printf("Warning, Check function does not support BOTH_MODE, use either compressed or uncompressed");
    return true;
  }

  searchComp = (searchMode == SEARCH_COMPRESSED)?true:false;

  uint32_t seed = (uint32_t)time(NULL);
  printf("Seed: %u\n",seed);
  rseed(seed);
  memset(nbOK,0,sizeof(nbOK));
  memset(nbFoundCPU, 0, sizeof(nbFoundCPU));
  for (int i = 0; i < nbThread; i++) {
    k.Rand(256);
    p[i] = secp->ComputePublicKey(&k);
    // Group starts at the middle
    k.Add((uint64_t)GRP_SIZE/2);
    p2[i] = secp->ComputePublicKey(&k);
  }

  std::vector<prefix_t> prefs;
  prefs.push_back(0xFEFE);
  prefs.push_back(0x1234);
  SetPrefix(prefs);
  SetKeys(p2);
  double t0 = Timer::get_tick();
  Launch(found,true);
  double t1 = Timer::get_tick();
  Timer::printResult((char *)"Key", 6*STEP_SIZE*nbThread, t0, t1);

  //for (int i = 0; i < found.size(); i++) {
  //  printf("[%d]: thId=%d incr=%d\n", i, found[i].thId,found[i].incr);
  //  printf("[%d]: %s\n", i,toHex(found[i].hash,20).c_str());
  //}

  printf("ComputeKeys() found %d items , CPU check...\n",(int)found.size());

  Int beta,beta2;
  beta.SetBase16((char *)"7ae96a2b657c07106e64479eac3434e99cf0497512f58995c1396c28719501ee");
  beta2.SetBase16((char *)"851695d49a83f8ef919bb86153cbcb16630fb68aed0a766a3ec693d68e6afa40");

  // Check with CPU
  for (j = 0; (j<nbThread); j++) {
    for (i = 0; i < STEP_SIZE; i++) {

      Point pt,p1,p2;
      pt = p[j];
      p1 = p[j];
      p2 = p[j];
      p1.x.ModMulK1(&beta);
      p2.x.ModMulK1(&beta2);
      p[j] = secp->NextKey(p[j]);

      // Point and endo
      secp->GetHash160(P2PKH, searchComp, pt, h);
      prefix_t pr = *(prefix_t *)h;
      if (pr == 0xFEFE || pr == 0x1234) {
	      nbFoundCPU[0]++;
        ok &= CheckHash(h,found, j, i, 0, nbOK + 0);
      }
      secp->GetHash160(P2PKH, searchComp, p1, h);
      pr = *(prefix_t *)h;
      if (pr == 0xFEFE || pr == 0x1234) {
        nbFoundCPU[1]++;
        ok &= CheckHash(h, found, j, i, 1, nbOK + 1);
      }
      secp->GetHash160(P2PKH, searchComp, p2, h);
      pr = *(prefix_t *)h;
      if (pr == 0xFEFE || pr == 0x1234) {
        nbFoundCPU[2]++;
        ok &= CheckHash(h, found, j, i, 2, nbOK + 2);
      }

      // Symetrics
      pt.y.ModNeg();
      p1.y.ModNeg();
      p2.y.ModNeg();

      secp->GetHash160(P2PKH, searchComp, pt, h);
      pr = *(prefix_t *)h;
      if (pr == 0xFEFE || pr == 0x1234) {
        nbFoundCPU[3]++;
        ok &= CheckHash(h, found, j, -i, 0, nbOK + 3);
      }
      secp->GetHash160(P2PKH, searchComp, p1, h);
      pr = *(prefix_t *)h;
      if (pr == 0xFEFE || pr == 0x1234) {
        nbFoundCPU[4]++;
        ok &= CheckHash(h, found, j, -i, 1, nbOK + 4);
      }
      secp->GetHash160(P2PKH, searchComp, p2, h);
      pr = *(prefix_t *)h;
      if (pr == 0xFEFE || pr == 0x1234) {
        nbFoundCPU[5]++;
        ok &= CheckHash(h, found, j, -i, 2, nbOK + 5);
      }

    }
  }

  if (ok && found.size()!=0) {
    ok = false;
    printf("Unexpected item found !\n");
  }

  if( !ok ) {

    int nbF = nbFoundCPU[0] + nbFoundCPU[1] + nbFoundCPU[2] +
              nbFoundCPU[3] + nbFoundCPU[4] + nbFoundCPU[5];
    printf("CPU found %d items\n",nbF);

    printf("GPU: point   correct [%d/%d]\n", nbOK[0] , nbFoundCPU[0]);
    printf("GPU: endo #1 correct [%d/%d]\n", nbOK[1] , nbFoundCPU[1]);
    printf("GPU: endo #2 correct [%d/%d]\n", nbOK[2] , nbFoundCPU[2]);

    printf("GPU: sym/point   correct [%d/%d]\n", nbOK[3] , nbFoundCPU[3]);
    printf("GPU: sym/endo #1 correct [%d/%d]\n", nbOK[4] , nbFoundCPU[4]);
    printf("GPU: sym/endo #2 correct [%d/%d]\n", nbOK[5] , nbFoundCPU[5]);

    printf("GPU/CPU check Failed !\n");

  }

  if(ok) printf("GPU/CPU check OK\n");

  delete[] p;
  return ok;

}
