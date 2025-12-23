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

#include "BIP39.h"
#include "hash/sha256.h"
#include "hash/sha512.h"
#include "Random.h"
#include <fstream>
#include <sstream>
#include <cstring>
#include <algorithm>

std::vector<std::string> BIP39::wordlist;
bool BIP39::wordlistLoaded = false;

bool BIP39::LoadWordlist(const char* filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        return false;
    }
    
    wordlist.clear();
    std::string word;
    while (std::getline(file, word)) {
        // Trim whitespace
        word.erase(word.find_last_not_of(" \n\r\t") + 1);
        if (!word.empty()) {
            wordlist.push_back(word);
        }
    }
    
    wordlistLoaded = (wordlist.size() == 2048);
    return wordlistLoaded;
}

std::string BIP39::GetWord(int index) {
    if (!wordlistLoaded || index < 0 || index >= 2048) {
        return "";
    }
    return wordlist[index];
}

int BIP39::GetWordIndex(const std::string& word) {
    if (!wordlistLoaded) {
        return -1;
    }
    
    auto it = std::find(wordlist.begin(), wordlist.end(), word);
    if (it != wordlist.end()) {
        return std::distance(wordlist.begin(), it);
    }
    return -1;
}

std::string BIP39::GenerateMnemonic12() {
    if (!wordlistLoaded) {
        return "";
    }
    
    // Generate 128 bits of entropy for 12 words
    uint8_t entropy[16];
    for (int i = 0; i < 16; i++) {
        entropy[i] = (uint8_t)(rndl() & 0xFF);
    }
    
    // Calculate checksum (first 4 bits of SHA256)
    uint8_t hash[32];
    sha256(entropy, 16, hash);
    uint8_t checksum = hash[0] >> 4;  // First 4 bits
    
    // Convert to 11-bit indices
    // 128 bits entropy + 4 bits checksum = 132 bits = 12 words (12 * 11 = 132)
    uint16_t indices[12];
    
    // Process entropy bits
    for (int i = 0; i < 11; i++) {
        int bitOffset = i * 11;
        int byteOffset = bitOffset / 8;
        int bitShift = bitOffset % 8;
        
        uint16_t value;
        if (bitShift <= 5) {
            // Can get 11 bits from 2 bytes
            value = ((uint16_t)entropy[byteOffset] << 8) | (uint16_t)entropy[byteOffset + 1];
            value = (value >> (5 - bitShift)) & 0x7FF;
        } else {
            // Need 3 bytes
            value = ((uint16_t)entropy[byteOffset] << 16) | 
                    ((uint16_t)entropy[byteOffset + 1] << 8) |
                    (uint16_t)entropy[byteOffset + 2];
            value = (value >> (13 - bitShift)) & 0x7FF;
        }
        indices[i] = value;
    }
    
    // Last word includes checksum
    // Bits 121-128 from entropy (last byte) + 4 checksum bits
    uint16_t lastValue = ((uint16_t)entropy[15] << 3) | (checksum & 0x0F);
    lastValue = (lastValue >> 1) & 0x7FF;
    indices[11] = lastValue;
    
    // Build mnemonic string
    std::string mnemonic;
    for (int i = 0; i < 12; i++) {
        if (i > 0) mnemonic += " ";
        mnemonic += wordlist[indices[i]];
    }
    
    return mnemonic;
}

bool BIP39::ValidateMnemonic(const std::string& mnemonic) {
    if (!wordlistLoaded) {
        return false;
    }
    
    // Split mnemonic into words
    std::vector<std::string> words;
    std::istringstream iss(mnemonic);
    std::string word;
    while (iss >> word) {
        words.push_back(word);
    }
    
    // Check word count (12, 15, 18, 21, or 24 words)
    if (words.size() != 12 && words.size() != 15 && 
        words.size() != 18 && words.size() != 21 && words.size() != 24) {
        return false;
    }
    
    // Convert words to indices
    std::vector<uint16_t> indices;
    for (const auto& w : words) {
        int idx = GetWordIndex(w);
        if (idx < 0) {
            return false;
        }
        indices.push_back((uint16_t)idx);
    }
    
    // Reconstruct entropy and checksum
    int totalBits = words.size() * 11;
    int checksumBits = totalBits / 33;
    int entropyBits = totalBits - checksumBits;
    int entropyBytes = entropyBits / 8;
    
    uint8_t entropy[32];
    memset(entropy, 0, 32);
    
    // Convert indices back to entropy
    int bitPos = 0;
    for (size_t i = 0; i < indices.size(); i++) {
        uint16_t idx = indices[i];
        for (int bit = 10; bit >= 0; bit--) {
            if (idx & (1 << bit)) {
                entropy[bitPos / 8] |= (1 << (7 - (bitPos % 8)));
            }
            bitPos++;
        }
    }
    
    // Calculate and verify checksum
    uint8_t hash[32];
    sha256(entropy, entropyBytes, hash);
    
    uint8_t calculatedChecksum = hash[0] >> (8 - checksumBits);
    uint8_t providedChecksum = 0;
    
    for (int i = 0; i < checksumBits; i++) {
        int bit = entropyBits + i;
        if (entropy[bit / 8] & (1 << (7 - (bit % 8)))) {
            providedChecksum |= (1 << (checksumBits - 1 - i));
        }
    }
    
    return calculatedChecksum == providedChecksum;
}

void BIP39::MnemonicToSeed(const std::string& mnemonic, const std::string& passphrase,
                           uint8_t* seed) {
    // BIP39: seed = PBKDF2(mnemonic, "mnemonic" + passphrase, 2048 iterations)
    std::string salt = "mnemonic" + passphrase;
    
    pbkdf2_hmac_sha512(seed, 64,
                       (const uint8_t*)mnemonic.c_str(), mnemonic.length(),
                       (const uint8_t*)salt.c_str(), salt.length(),
                       2048);
}
