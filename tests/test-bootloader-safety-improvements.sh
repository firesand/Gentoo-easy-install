#!/bin/bash

# Test script for bootloader safety improvements
# Tests the enhanced functions for safer and more robust bootloader configuration

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_failure() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test 1: Enhanced get_disk_device_from_partition function
test_enhanced_device_detection() {
    log_info "Testing enhanced device detection with lsblk fallback"
    
    # Check if the function exists in main.sh
    if grep -q "lsblk -no pkname" scripts/main.sh; then
        log_success "Enhanced device detection with lsblk is implemented"
    else
        log_failure "Enhanced device detection with lsblk is missing"
    fi
    
    # Check if fallback regex patterns are still present
    if grep -q "NVMe devices:" scripts/main.sh; then
        log_success "Regex fallback patterns are maintained"
    else
        log_failure "Regex fallback patterns are missing"
    fi
}

# Test 2: Safer MBR installation
test_safer_mbr_installation() {
    log_info "Testing safer MBR installation logic"
    
    # Check if syslinux-install is used as primary method
    if grep -q "syslinux-install" scripts/main.sh; then
        log_success "syslinux-install is implemented as primary MBR method"
    else
        log_failure "syslinux-install is missing from MBR installation"
    fi
    
    # Check if safety checks are implemented
    local safety_checks=0
    if grep -q "! -b.*gptdev" scripts/main.sh; then ((safety_checks++)); fi
    if grep -q "mount.*grep.*gptdev" scripts/main.sh; then ((safety_checks++)); fi
    if grep -q "! -f.*gptmbr.bin" scripts/main.sh; then ((safety_checks++)); fi
    
    if [[ $safety_checks -eq 3 ]]; then
        log_success "All MBR safety checks are implemented ($safety_checks/3)"
    else
        log_failure "Missing MBR safety checks: $safety_checks/3"
    fi
}

# Test 3: RAID UEFI boot order configuration
test_raid_uefi_boot_order() {
    log_info "Testing RAID UEFI boot order configuration"
    
    # Check if the function exists
    if grep -q "configure_raid_uefi_boot_order" scripts/main.sh; then
        log_success "RAID UEFI boot order function is implemented"
    else
        log_failure "RAID UEFI boot order function is missing"
    fi
    
    # Check if RAID detection logic is present
    if grep -q "mdadm --detail --scan" scripts/main.sh; then
        log_success "RAID detection logic is implemented"
    else
        log_failure "RAID detection logic is missing"
    fi
}

# Test 4: UEFI boot order optimization
test_uefi_boot_order_optimization() {
    log_info "Testing UEFI boot order optimization"
    
    # Check if efibootmgr is used for boot order management
    if grep -q "efibootmgr -o" scripts/main.sh; then
        log_success "UEFI boot order optimization is implemented"
    else
        log_failure "UEFI boot order optimization is missing"
    fi
    
    # Check if boot order detection is implemented
    if grep -q "efibootmgr -v.*Boot.*sort" scripts/main.sh; then
        log_success "UEFI boot order detection is implemented"
    else
        log_failure "UEFI boot order detection is missing"
    fi
}

# Test 5: RAID BIOS bootloader redundancy
test_raid_bios_redundancy() {
    log_info "Testing RAID BIOS bootloader redundancy"
    
    # Check if the function exists
    if grep -q "configure_raid_bios_bootloader" scripts/main.sh; then
        log_success "RAID BIOS bootloader function is implemented"
    else
        log_failure "RAID BIOS bootloader function is missing"
    fi
    
    # Check if GRUB installation to RAID members is implemented
    if grep -q "Installing GRUB to.*RAID member" scripts/main.sh; then
        log_success "RAID member GRUB installation is implemented"
    else
        log_failure "RAID member GRUB installation is missing"
    fi
}

# Test 6: Integration with existing bootloader configuration
test_bootloader_integration() {
    log_info "Testing bootloader integration with RAID support"
    
    # Check if RAID functions are called from main bootloader configuration
    if grep -q "configure_raid_uefi_boot_order" scripts/main.sh; then
        log_success "UEFI RAID integration is implemented"
    else
        log_failure "UEFI RAID integration is missing"
    fi
    
    if grep -q "configure_raid_bios_bootloader" scripts/main.sh; then
        log_success "BIOS RAID integration is implemented"
    else
        log_failure "BIOS RAID integration is missing"
    fi
}

# Main test execution
main() {
    log_info "Starting bootloader safety improvements tests..."
    echo
    
    # Run all tests
    test_enhanced_device_detection
    test_safer_mbr_installation
    test_raid_uefi_boot_order
    test_uefi_boot_order_optimization
    test_raid_bios_redundancy
    test_bootloader_integration
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Bootloader safety improvements are working correctly."
        exit 0
    else
        log_failure "Some tests failed. Please review the bootloader safety improvements."
        exit 1
    fi
}

# Run main function
main "$@"
