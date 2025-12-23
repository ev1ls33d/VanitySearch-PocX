/*
 * GPU HD Wallet implementation for BIP39/BIP32/BIP44
 * This file contains CUDA device functions for HD wallet key derivation
 */

#ifndef GPUHDWALLET_H
#define GPUHDWALLET_H

// BIP32 hardened child key derivation (forward declaration)
__device__ void _DeriveChildKeyHardened(const uint64_t *parentKey, const uint8_t *parentChainCode,
                                       uint32_t index,
                                       uint64_t *childKey, uint8_t *childChainCode);

#endif // GPUHDWALLET_H
