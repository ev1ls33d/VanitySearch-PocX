/*
 * This file is part of the VanitySearch distribution (https://github.com/JeanLucPons/VanitySearch).
 * Copyright (c) 2019 Jean Luc PONS.
 */

#ifndef SHA512_H
#define SHA512_H
#include <cstdint>

void sha512(const uint8_t *input, size_t length, uint8_t *digest);
void pbkdf2_hmac_sha512(uint8_t *output, size_t output_len,
                        const uint8_t *password, size_t password_len,
                        const uint8_t *salt, size_t salt_len,
                        unsigned int rounds);

#endif // SHA512_H
