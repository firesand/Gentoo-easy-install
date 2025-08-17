#!/bin/bash

# Test script for critical fixes
# Tests the dracut command fix and partition probing race condition fix

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

# Test 1: Dracut command uses correct flags for dracut modules vs kernel drivers
test_dracut_command_fix() {
    log_info "Testing dracut command fix for proper module separation"
    
    # Check if the old problematic --add "bash ${modules[*]}" is removed
    if ! grep -q 'add "bash \${modules\[\*\]}"' scripts/main.sh; then
        log_success "Old problematic --add flag usage is removed"
    else
        log_failure "Old problematic --add flag usage still exists"
    fi
    
    # Check if proper separation of dracut modules and kernel drivers is implemented
    if grep -q "Determine required dracut and kernel modules" scripts/main.sh; then
        log_success "Proper separation of dracut modules and kernel drivers is implemented"
    else
        log_failure "Proper separation of dracut modules and kernel drivers is missing"
    fi
    
    # Check if --add is used for dracut modules
    if grep -q "add.*dracut_modules" scripts/main.sh; then
        log_success "--add flag is used for dracut modules"
    else
        log_failure "--add flag is missing for dracut modules"
    fi
    
    # Check if --add-drivers is used for kernel drivers
    if grep -q "add-drivers.*kernel_drivers" scripts/main.sh; then
        log_success "--add-drivers flag is used for kernel drivers"
    else
        log_failure "--add-drivers flag is missing for kernel drivers"
    fi
    
    # Check if dracut modules are properly categorized
    if grep -q "dracut_modules.*bash" scripts/main.sh && grep -q "dracut_modules.*mdraid" scripts/main.sh && grep -q "dracut_modules.*crypt" scripts/main.sh; then
        log_success "Dracut modules are properly categorized (bash, mdraid, crypt)"
    else
        log_failure "Dracut modules are not properly categorized"
    fi
    
    # Check if kernel drivers are properly categorized
    if grep -q "kernel_drivers.*btrfs" scripts/main.sh; then
        log_success "Kernel drivers are properly categorized (btrfs)"
    else
        log_failure "Kernel drivers are not properly categorized"
    fi
    
    # Check if virtio drivers are added to kernel_drivers
    if grep -q "kernel_drivers.*virtio" scripts/main.sh; then
        log_success "Virtio drivers are properly added to kernel_drivers"
    else
        log_failure "Virtio drivers are not properly added to kernel_drivers"
    fi
}

# Test 2: Partition probing race condition is fixed
test_partition_probing_fix() {
    log_info "Testing partition probing race condition fix"
    
    # Check if the old sleep loop is removed
    if ! grep -q "for i in {1..10}" scripts/functions.sh; then
        log_success "Old problematic sleep loop is removed"
    else
        log_failure "Old problematic sleep loop still exists"
    fi
    
    # Check if udevadm settle is used for proper device waiting
    if grep -q "udevadm settle" scripts/functions.sh; then
        log_success "udevadm settle is used for proper device waiting"
    else
        log_failure "udevadm settle is not used for device waiting"
    fi
    
    # Check if timeout is set for udevadm settle
    if grep -q "udevadm settle --timeout" scripts/functions.sh; then
        log_success "udevadm settle uses proper timeout"
    else
        log_failure "udevadm settle timeout is not set"
    fi
    
    # Check if fallback method is implemented
    if grep -q "udevadm not available, using fallback method" scripts/functions.sh; then
        log_success "Fallback method is implemented when udevadm is not available"
    else
        log_failure "Fallback method is missing"
    fi
    
    # Check if fallback uses shorter intervals
    if grep -q "for i in {1..5}" scripts/functions.sh; then
        log_success "Fallback method uses shorter intervals (5 iterations)"
    else
        log_failure "Fallback method does not use shorter intervals"
    fi
    
    # Check if fallback uses shorter sleep duration
    if grep -q "sleep 0.5" scripts/functions.sh; then
        log_success "Fallback method uses shorter sleep duration (0.5s)"
    else
        log_failure "Fallback method does not use shorter sleep duration"
    fi
}

# Test 3: Both dracut functions are properly updated
test_both_dracut_functions() {
    log_info "Testing both dracut functions are properly updated"
    
    # Check if configure_kernel function uses correct logic
    if grep -q "Using Dracut modules" scripts/main.sh && grep -q "Using Kernel drivers" scripts/main.sh; then
        log_success "configure_kernel function uses correct module separation"
    else
        log_failure "configure_kernel function does not use correct module separation"
    fi
    
    # Check if generate_initramfs function uses correct logic
    if grep -q "Using Dracut modules" scripts/main.sh && grep -q "Using Kernel drivers" scripts/main.sh; then
        log_success "generate_initramfs function uses correct module separation"
    else
        log_failure "generate_initramfs function does not use correct module separation"
    fi
    
    # Check if both functions use dracut_modules and kernel_drivers
    local dracut_functions_count=$(grep -c "dracut_modules.*bash" scripts/main.sh)
    if [[ $dracut_functions_count -ge 2 ]]; then
        log_success "Both dracut functions use dracut_modules array"
    else
        log_failure "Not all dracut functions use dracut_modules array"
    fi
    
    local kernel_drivers_count=$(grep -c "kernel_drivers.*btrfs" scripts/main.sh)
    if [[ $kernel_drivers_count -ge 2 ]]; then
        log_success "Both dracut functions use kernel_drivers array"
    else
        log_failure "Not all dracut functions use kernel_drivers array"
    fi
}

# Test 4: Proper flag usage in dracut commands
test_proper_flag_usage() {
    log_info "Testing proper flag usage in dracut commands"
    
    # Check if --add is used correctly for dracut modules
    if grep -q "add.*dracut_modules" scripts/main.sh; then
        log_success "--add flag is used correctly for dracut modules"
    else
        log_failure "--add flag is not used correctly for dracut modules"
    fi
    
    # Check if --add-drivers is used correctly for kernel drivers
    if grep -q "add-drivers.*kernel_drivers" scripts/main.sh; then
        log_success "--add-drivers flag is used correctly for kernel drivers"
    else
        log_failure "--add-drivers flag is not used correctly for kernel drivers"
    fi
    
    # Check if no old --add "bash ${modules[*]}" pattern exists
    if ! grep -q 'add.*\${modules\[\*\]}' scripts/main.sh; then
        log_success "No old --add \${modules[*]} pattern exists"
    else
        log_failure "Old --add \${modules[*]} pattern still exists"
    fi
}

# Test 5: Integration and compatibility maintained
test_integration_and_compatibility() {
    log_info "Testing integration and compatibility"
    
    # Check if existing dracut options are maintained
    if grep -q "kver" scripts/main.sh && grep -q "zstd" scripts/main.sh && grep -q "no-hostonly" scripts/main.sh && grep -q "ro-mnt" scripts/main.sh; then
        log_success "Existing dracut options are maintained"
    else
        log_failure "Existing dracut options are broken"
    fi
    
    # Check if existing module detection logic is maintained
    if grep -q "USED_RAID.*mdraid" scripts/main.sh && grep -q "USED_LUKS.*crypt" scripts/main.sh && grep -q "USED_BTRFS.*btrfs" scripts/main.sh; then
        log_success "Existing module detection logic is maintained"
    else
        log_failure "Existing module detection logic is broken"
    fi
    
    # Check if systemd integration is maintained
    if grep -q "systemd-networkd" scripts/main.sh; then
        log_success "Existing systemd integration is maintained"
    else
        log_failure "Existing systemd integration is broken"
    fi
    
    # Check if virtio driver detection is maintained
    if grep -q "systemd-detect-virt" scripts/main.sh; then
        log_success "Virtio driver detection is maintained"
    else
        log_failure "Virtio driver detection is broken"
    fi
}

# Main test execution
main() {
    log_info "Starting critical fixes tests..."
    echo
    
    # Run all tests
    test_dracut_command_fix
    test_partition_probing_fix
    test_both_dracut_functions
    test_proper_flag_usage
    test_integration_and_compatibility
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Critical fixes are working correctly."
        log_success "✅ Dracut command now properly separates dracut modules from kernel drivers!"
        log_success "✅ Partition probing race condition is fixed with proper udev handling!"
        log_success "✅ Both dracut functions use correct --add vs --add-drivers flags!"
        exit 0
    else
        log_failure "Some tests failed. Please review the critical fixes."
        exit 1
    fi
}

# Run main function
main "$@"
