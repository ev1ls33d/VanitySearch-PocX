/*
 * Bitcoin Core descriptor checksum implementation
 */

#ifndef DESCRIPTORCHECKSUM_H
#define DESCRIPTORCHECKSUM_H

#include <string>

// Calculate the descriptor checksum for a given descriptor string
// Returns an 8-character checksum
std::string DescriptorChecksum(const std::string& descriptor);

#endif // DESCRIPTORCHECKSUM_H
