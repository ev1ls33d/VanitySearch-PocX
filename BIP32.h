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

#ifndef BIP32_H
#define BIP32_H

#include <cstdint>
#include <string>
#include "Int.h"
#include "Point.h"
#include "SECP256k1.h"

// BIP32 HD key derivation
class BIP32 {
public:
    // Derive master key from seed
    static void DeriveMasterKey(const uint8_t* seed, size_t seedLen,
                               Int& masterKey, uint8_t* chainCode);
    
    // Derive child key (hardened derivation only for private keys)
    static void DeriveChildKey(const Int& parentKey, const uint8_t* parentChainCode,
                              uint32_t index, bool hardened,
                              Int& childKey, uint8_t* childChainCode);
    
    // Derive key from path (e.g., "m/84'/0'/0'/0/0")
    // Returns the private key for the final path
    static void DerivePath(const uint8_t* seed, size_t seedLen,
                          const std::string& path,
                          Int& derivedKey);
    
    // Hardened index constant
    static const uint32_t HARDENED = 0x80000000;
};

#endif // BIP32_H
