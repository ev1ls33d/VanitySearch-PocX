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

#ifndef BIP39_H
#define BIP39_H

#include <string>
#include <vector>
#include <cstdint>

// BIP39 mnemonic generation and seed derivation
class BIP39 {
public:
    // Load BIP39 English wordlist
    static bool LoadWordlist(const char* filename);
    
    // Generate a random 12-word mnemonic
    static std::string GenerateMnemonic12();
    
    // Convert mnemonic to seed (BIP39)
    static void MnemonicToSeed(const std::string& mnemonic, const std::string& passphrase, 
                               uint8_t* seed);
    
    // Validate mnemonic checksum
    static bool ValidateMnemonic(const std::string& mnemonic);
    
    // Get word from index
    static std::string GetWord(int index);
    
    // Get index from word
    static int GetWordIndex(const std::string& word);
    
private:
    static std::vector<std::string> wordlist;
    static bool wordlistLoaded;
};

#endif // BIP39_H
