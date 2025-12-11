#!/bin/bash
# PoCX VanitySearch Compatibility Check Script
# Tests that PoCX support is correctly implemented

echo "=================================="
echo "PoCX VanitySearch Compatibility Check"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

# Function to run test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "Testing: $test_name... "
    
    result=$(eval "$command" 2>&1)
    
    if echo "$result" | grep -q "$expected"; then
        echo -e "${GREEN}PASS${NC}"
        ((PASS++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Expected: $expected"
        echo "  Got: $result"
        ((FAIL++))
        return 1
    fi
}

# Check if VanitySearch exists
if [ ! -f "./VanitySearch" ]; then
    echo -e "${RED}ERROR: VanitySearch executable not found${NC}"
    echo "Please build the project first:"
    echo "  make gpu=1 CCAP=9.0 all"
    exit 1
fi

echo "VanitySearch executable found ?"
echo ""

# Test 1: Version check
run_test "Version" "./VanitySearch -v" "1.19"

# Test 2: Help mentions PoCX
run_test "Help mentions PoCX" "./VanitySearch -h 2>&1" "PoCX"

# Test 3: Generate key pair
echo ""
echo "Test: Generate key pair with seed..."
./VanitySearch -s "test_seed" -kp > /tmp/vanity_test_kp.txt 2>&1
if grep -q "Priv :" /tmp/vanity_test_kp.txt && grep -q "Pub  :" /tmp/vanity_test_kp.txt; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAIL++))
fi

# Test 4: Generate PoCX address from known private key
echo ""
echo "Test: Generate PoCX address from private key..."
./VanitySearch -cp 0x0000000000000000000000000000000000000000000000000000000000000001 > /tmp/vanity_test_addr.txt 2>&1

# Check if all address types are generated
if grep -q "P2PKH" /tmp/vanity_test_addr.txt && \
   grep -q "P2SH" /tmp/vanity_test_addr.txt && \
   grep -q "BECH32" /tmp/vanity_test_addr.txt && \
   grep -q "POCX" /tmp/vanity_test_addr.txt; then
    echo -e "${GREEN}PASS${NC} - All address types generated"
    ((PASS++))
    
    # Extract and verify PoCX address starts with 'p'
    pocx_addr=$(grep "POCX" /tmp/vanity_test_addr.txt | awk '{print $NF}')
    if [[ $pocx_addr == p* ]]; then
        echo -e "${GREEN}PASS${NC} - PoCX address starts with 'p': $pocx_addr"
        ((PASS++))
    else
        echo -e "${RED}FAIL${NC} - PoCX address doesn't start with 'p': $pocx_addr"
        ((FAIL++))
    fi
else
    echo -e "${RED}FAIL${NC} - Not all address types generated"
    ((FAIL++))
fi

# Test 5: Check GPU support (if available)
echo ""
if ./VanitySearch -l 2>&1 | grep -q "GPU"; then
    echo -e "${GREEN}GPU support detected${NC}"
    
    # Try a simple GPU search (will timeout after 2 seconds)
    echo "Test: GPU search for 'pocx1T' (2 second timeout)..."
    timeout 2 ./VanitySearch -gpu -stop pocx1T > /tmp/vanity_test_gpu.txt 2>&1
    
    if grep -q "GPU #0" /tmp/vanity_test_gpu.txt; then
        echo -e "${GREEN}PASS${NC} - GPU search initialized"
        ((PASS++))
    else
        echo -e "${YELLOW}WARN${NC} - GPU search may have issues"
    fi
else
    echo -e "${YELLOW}INFO${NC} - No GPU detected (CPU-only build or no CUDA device)"
fi

# Test 6: Verify CUDA version (if GPU build)
if ldd ./VanitySearch 2>/dev/null | grep -q "libcudart"; then
    echo ""
    echo "Test: CUDA library linkage..."
    cuda_lib=$(ldd ./VanitySearch | grep libcudart | awk '{print $3}')
    if [ -f "$cuda_lib" ]; then
        echo -e "${GREEN}PASS${NC} - CUDA library found: $cuda_lib"
        ((PASS++))
    else
        echo -e "${RED}FAIL${NC} - CUDA library not found"
        ((FAIL++))
    fi
fi

# Summary
echo ""
echo "=================================="
echo "Test Summary"
echo "=================================="
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}? All tests passed! PoCX support is working correctly.${NC}"
    echo ""
    echo "You can now use VanitySearch to generate PoCX addresses:"
    echo "  ./VanitySearch -gpu pocx1Test"
    exit 0
else
    echo -e "${RED}? Some tests failed. Please check the build.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Rebuild: make clean && make gpu=1 CCAP=9.0 all"
    echo "  2. Check CUDA: nvcc --version"
    echo "  3. Check GPU: nvidia-smi"
    exit 1
fi

# Cleanup
rm -f /tmp/vanity_test_*.txt
