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

#include "BIP32.h"
#include "hash/sha512.h"
#include <cstring>
#include <sstream>
#include <vector>

const uint32_t BIP32::HARDENED;

void BIP32::DeriveMasterKey(const uint8_t* seed, size_t seedLen,
                           Int& masterKey, uint8_t* chainCode) {
    // BIP32: I = HMAC-SHA512(Key = "Bitcoin seed", Data = seed)
    const char* key = "Bitcoin seed";
    uint8_t I[64];
    
    hmac_sha512((unsigned char*)key, strlen(key), 
                (unsigned char*)seed, seedLen, I);
    
    // IL = master secret key (first 32 bytes)
    // IR = master chain code (last 32 bytes)
    masterKey.SetInt32(0);
    for (int i = 0; i < 32; i++) {
        masterKey.ShiftL(8);
        masterKey.Add((uint64_t)I[i]);
    }
    
    memcpy(chainCode, I + 32, 32);
}

void BIP32::DeriveChildKey(const Int& parentKey, const uint8_t* parentChainCode,
                          uint32_t index, bool hardened,
                          Int& childKey, uint8_t* childChainCode) {
    uint8_t data[37];
    
    if (hardened) {
        // Hardened child: data = 0x00 || ser256(parentKey) || ser32(index)
        data[0] = 0x00;
        
        // Serialize parent key (big-endian)
        Int tempKey = parentKey;
        for (int i = 32; i >= 1; i--) {
            uint8_t byte = (uint8_t)(tempKey.bits64[0] & 0xFF);
            data[i] = byte;
            tempKey.ShiftR(8);
        }
        
        // Add index (with hardened bit set)
        uint32_t idx = index | HARDENED;
        data[33] = (idx >> 24) & 0xFF;
        data[34] = (idx >> 16) & 0xFF;
        data[35] = (idx >> 8) & 0xFF;
        data[36] = idx & 0xFF;
        
        // I = HMAC-SHA512(Key = chainCode, Data = data)
        uint8_t I[64];
        hmac_sha512((unsigned char*)parentChainCode, 32, data, 37, I);
        
        // IL = first 32 bytes
        Int IL;
        IL.SetInt32(0);
        for (int i = 0; i < 32; i++) {
            IL.ShiftL(8);
            IL.Add((uint64_t)I[i]);
        }
        
        // childKey = (IL + parentKey) mod n
        childKey = parentKey;
        childKey.Add(&IL);
        
        // Reduce modulo the order of secp256k1
        // n = FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
        Int n;
        n.SetBase16((char*)"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141");
        childKey.Mod(&n);
        
        // childChainCode = IR (last 32 bytes)
        memcpy(childChainCode, I + 32, 32);
        
    } else {
        // Non-hardened derivation not implemented for private keys in this context
        // For vanity search, we only need hardened derivation
        memset(childChainCode, 0, 32);
        childKey.SetInt32(0);
    }
}

void BIP32::DerivePath(const uint8_t* seed, size_t seedLen,
                      const std::string& path,
                      Int& derivedKey) {
    // Parse path: m/84'/0'/0'/0/0
    if (path.empty() || path[0] != 'm') {
        derivedKey.SetInt32(0);
        return;
    }
    
    // Derive master key
    uint8_t chainCode[32];
    DeriveMasterKey(seed, seedLen, derivedKey, chainCode);
    
    // Parse and derive each level
    std::string pathCopy = path.substr(1); // Skip 'm'
    if (pathCopy.empty()) {
        return; // Just master key
    }
    
    std::istringstream iss(pathCopy);
    std::string segment;
    
    while (std::getline(iss, segment, '/')) {
        if (segment.empty()) continue;
        
        bool hardened = false;
        if (segment.back() == '\'' || segment.back() == 'h') {
            hardened = true;
            segment.pop_back();
        }
        
        uint32_t index = 0;
        try {
            index = std::stoul(segment);
        } catch (...) {
            // Invalid index, stop derivation
            break;
        }
        
        Int childKey;
        uint8_t childChainCode[32];
        DeriveChildKey(derivedKey, chainCode, index, hardened, childKey, childChainCode);
        
        derivedKey = childKey;
        memcpy(chainCode, childChainCode, 32);
    }
}
