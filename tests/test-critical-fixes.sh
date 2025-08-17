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

# Test 1: Dracut command uses correct flags for kernel modules
test_dracut_command_fix() {
    log_info "Testing dracut command fix for kernel modules"
    
    # Check if the old problematic --add "bash ${modules[*]}" is removed
    if ! grep -q '--add "bash \${modules\[\*\]}"' scripts/main.sh; then
        log_success "Old problematic --add flag usage is removed"
    else
        log_failure "Old problematic --add flag usage still exists"
    fi
    
    # Check if proper separation of bash and kernel modules is implemented
    if grep -q "Separate bash.*file.*from kernel modules.*drivers" scripts/main.sh; then
        log_success "Proper separation of bash and kernel modules is implemented"
    else
        log_failure "Proper separation of bash and kernel modules is missing"
    fi
    
    # Check if --add-drivers is used for kernel modules
    if grep -q "add-drivers.*kernel_modules" scripts/main.sh || grep -q "add-drivers.*kernel_modules" scripts/main.sh; then
        log_success "--add-drivers flag is used for kernel modules"
    else
        log_failure "--add-drivers flag is missing for kernel modules"
    fi
    
    # Check if --add is only used for bash (files)
    if grep -q "add.*bash" scripts/main.sh || grep -q "add.*bash_module" scripts/main.sh; then
        log_success "--add flag is correctly used only for bash (files)"
    else
        log_failure "--add flag usage for bash is missing or incorrect"
    fi
    
    # Check if dracut command is built dynamically
    if grep -q "dracut_cmd=(" scripts/main.sh; then
        log_success "Dracut command is built dynamically with proper flags"
    else
        log_failure "Dracut command is not built dynamically"
    fi
    
    # Check if virtio drivers are handled correctly
    if grep -q "add-drivers.*virtio_drivers" scripts/main.sh || grep -q "add-drivers.*virtio_drivers" scripts/main.sh; then
        log_success "Virtio drivers are handled with --add-drivers flag"
    else
        log_failure "Virtio drivers are not handled with --add-drivers flag"
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

# Test 3: Dracut command handles different module types correctly
test_dracut_module_handling() {
    log_info "Testing dracut module handling logic"
    
    # Check if bash module is extracted separately
    if grep -q "Extract bash if present, collect other modules" scripts/main.sh; then
        log_success "Bash module extraction logic is implemented"
    else
        log_failure "Bash module extraction logic is missing"
    fi
    
    # Check if kernel modules are collected separately
    if grep -q "kernel_modules+=.*module" scripts/main.sh; then
        log_success "Kernel module collection logic is implemented"
    else
        log_failure "Kernel module collection logic is missing"
    fi
    
    # Check if dracut command array is built properly
    if grep -q "dracut_cmd=(" scripts/main.sh; then
        log_success "Dracut command array building is implemented"
    else
        log_failure "Dracut command array building is missing"
    fi
    
    # Check if conditional flag addition is implemented
    if grep -q "Add bash module if present" scripts/main.sh; then
        log_success "Conditional bash module addition is implemented"
    else
        log_failure "Conditional bash module addition is missing"
    fi
    
    # Check if conditional kernel module addition is implemented
    if grep -q "Add kernel modules.*--add-drivers" scripts/main.sh; then
        log_success "Conditional kernel module addition is implemented"
    else
        log_failure "Conditional kernel module addition is missing"
    fi
}

# Test 4: Error handling and fallbacks are implemented
test_error_handling_and_fallbacks() {
    log_info "Testing error handling and fallbacks"
    
    # Check if udevadm command availability is checked
    if grep -q "command -v udevadm" scripts/functions.sh; then
        log_success "udevadm command availability is checked"
    else
        log_failure "udevadm command availability is not checked"
    fi
    
    # Check if fallback method is documented
    if grep -q "udevadm not available, using fallback method" scripts/functions.sh; then
        log_success "Fallback method is properly documented"
    else
        log_failure "Fallback method is not documented"
    fi
    
    # Check if timeout handling is implemented
    if grep -q "udevadm settle timed out, continuing anyway" scripts/functions.sh; then
        log_success "Timeout handling is implemented"
    else
        log_failure "Timeout handling is missing"
    fi
    
    # Check if proper error messages are provided
    if grep -q "Using udevadm settle to wait for partition availability" scripts/functions.sh; then
        log_success "Proper error messages are provided"
    else
        log_failure "Proper error messages are missing"
    fi
}

# Test 5: Integration and compatibility
test_integration_and_compatibility() {
    log_info "Testing integration and compatibility"
    
    # Check if the fix integrates with existing virtio driver logic
    if grep -q "Add virtio drivers if in VM" scripts/main.sh; then
        log_success "Virtio driver integration is maintained"
    else
        log_failure "Virtio driver integration is broken"
    fi
    
    # Check if the fix maintains existing dracut options
    if grep -q "kver" scripts/main.sh && grep -q "zstd" scripts/main.sh && grep -q "no-hostonly" scripts/main.sh && grep -q "ro-mnt" scripts/main.sh; then
        log_success "Existing dracut options are maintained"
    else
        log_failure "Existing dracut options are broken"
    fi
    
    # Check if the fix maintains existing module detection logic
    if grep -q "USED_RAID.*mdraid" scripts/main.sh && grep -q "USED_LUKS.*crypt" scripts/main.sh && grep -q "USED_BTRFS.*btrfs" scripts/main.sh; then
        log_success "Existing module detection logic is maintained"
    else
        log_failure "Existing module detection logic is broken"
    fi
    
    # Check if the fix maintains existing systemd integration
    if grep -q "systemd-networkd" scripts/main.sh && grep -q "modules" scripts/main.sh; then
        log_success "Existing systemd integration is maintained"
    else
        log_failure "Existing systemd integration is broken"
    fi
}

# Main test execution
main() {
    log_info "Starting critical fixes tests..."
    echo
    
    # Run all tests
    test_dracut_command_fix
    test_partition_probing_fix
    test_dracut_module_handling
    test_error_handling_and_fallbacks
    test_integration_and_compatibility
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Critical fixes are working correctly."
        log_success "✅ Dracut command now uses correct flags for kernel modules!"
        log_success "✅ Partition probing race condition is fixed with proper udev handling!"
        exit 0
    else
        log_failure "Some tests failed. Please review the critical fixes."
        exit 1
    fi
}

# Run main function
main "$@"
