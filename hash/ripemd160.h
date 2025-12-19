/*
 * This file is part of the VanitySearch distribution (https://github.com/JeanLucPons/VanitySearch).
 * Copyright (c) 2019 Jean Luc PONS.
 */

#ifndef RIPEMD160_H
#define RIPEMD160_H
#include <cstdint>

void ripemd160(uint8_t *input, int length, uint8_t *digest);
void ripemd160_32(uint8_t *input, uint8_t *digest);
void ripemd160sse_32(uint32_t *i0, uint32_t *i1, uint32_t *i2, uint32_t *i3,
  uint8_t *d0, uint8_t *d1, uint8_t *d2, uint8_t *d3);
int ripemd160_comp_hash(uint8_t *h1, uint8_t *h2);

#endif // RIPEMD160_H
