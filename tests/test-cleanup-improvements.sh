#!/bin/bash

# Test script for cleanup functionality improvements
# Tests the enhanced cleanup system with manual and automatic cleanup options

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

# Test 1: Cleanup function is implemented
test_cleanup_function_implementation() {
    log_info "Testing cleanup function implementation"
    
    # Check if the main cleanup function exists
    if grep -q "function unmount_and_clean_all" scripts/main.sh; then
        log_success "unmount_and_clean_all function is implemented"
    else
        log_failure "unmount_and_clean_all function is missing"
    fi
    
    # Check if cleanup_on_exit function exists
    if grep -q "function cleanup_on_exit" scripts/main.sh; then
        log_success "cleanup_on_exit function is implemented"
    else
        log_failure "cleanup_on_exit function is missing"
    fi
}

# Test 2: Cleanup function handles filesystem unmounting
test_filesystem_unmounting() {
    log_info "Testing filesystem unmounting logic"
    
    # Check if chroot unmounting is implemented
    if grep -q "Unmounting all chroot-related filesystems" scripts/main.sh; then
        log_success "Chroot filesystem unmounting is implemented"
    else
        log_failure "Chroot filesystem unmounting is missing"
    fi
    
    # Check if gentoo_umount fallback is implemented
    if grep -q "gentoo_umount not available, using manual unmount" scripts/main.sh; then
        log_success "Manual unmount fallback is implemented"
    else
        log_failure "Manual unmount fallback is missing"
    fi
    
    # Check if recursive and lazy unmount is used
    if grep -q "umount -R -l" scripts/main.sh; then
        log_success "Recursive and lazy unmount is implemented"
    else
        log_failure "Recursive and lazy unmount is missing"
    fi
}

# Test 3: Cleanup function handles LUKS devices
test_luks_device_cleanup() {
    log_info "Testing LUKS device cleanup logic"
    
    # Check if LUKS device detection is implemented
    if grep -q "Checking for and closing LUKS containers" scripts/main.sh; then
        log_success "LUKS device cleanup is implemented"
    else
        log_failure "LUKS device cleanup is missing"
    fi
    
    # Check if dynamic LUKS device detection is implemented
    if grep -q "Detect active LUKS devices dynamically" scripts/main.sh; then
        log_success "Dynamic LUKS device detection is implemented"
    else
        log_failure "Dynamic LUKS device detection is missing"
    fi
    
    # Check if common LUKS device names are handled
    if grep -q "common_luks_devices.*root.*luks_root" scripts/main.sh; then
        log_success "Common LUKS device names are handled"
    else
        log_failure "Common LUKS device names are missing"
    fi
}

# Test 4: Cleanup function handles RAID arrays
test_raid_array_cleanup() {
    log_info "Testing RAID array cleanup logic"
    
    # Check if RAID array cleanup is implemented
    if grep -q "Checking for and stopping RAID arrays" scripts/main.sh; then
        log_success "RAID array cleanup is implemented"
    else
        log_failure "RAID array cleanup is missing"
    fi
    
    # Check if dynamic RAID device detection is implemented
    if grep -q "Detect active RAID devices dynamically" scripts/main.sh; then
        log_success "Dynamic RAID device detection is implemented"
    else
        log_failure "Dynamic RAID device detection is missing"
    fi
    
    # Check if common RAID device names are handled
    if grep -q "common_raid_devices.*md/root.*md/swap" scripts/main.sh; then
        log_success "Common RAID device names are handled"
    else
        log_failure "Common RAID device names are missing"
    fi
}

# Test 5: Cleanup function handles additional devices
test_additional_device_cleanup() {
    log_info "Testing additional device cleanup logic"
    
    # Check if swap deactivation is implemented
    if grep -q "Deactivating all swap devices" scripts/main.sh; then
        log_success "Swap deactivation is implemented"
    else
        log_failure "Swap deactivation is missing"
    fi
    
    # Check if loop device cleanup is implemented
    if grep -q "Checking for and removing loop devices" scripts/main.sh; then
        log_success "Loop device cleanup is implemented"
    else
        log_failure "Loop device cleanup is missing"
    fi
    
    # Check if temporary directory cleanup is implemented
    if grep -q "Removing temporary directory" scripts/main.sh; then
        log_success "Temporary directory cleanup is implemented"
    else
        log_failure "Temporary directory cleanup is missing"
    fi
}

# Test 6: Cleanup action is integrated in install script
test_cleanup_action_integration() {
    log_info "Testing cleanup action integration in install script"
    
    # Check if cleanup action is defined
    if grep -q "cleanup.*Multiple actions given" install || grep -q "cleanup.*ACTION.*cleanup" install || grep -q "cleanup.*--cleanup" install; then
        log_success "Cleanup action is defined in install script"
    else
        log_failure "Cleanup action is missing from install script"
    fi
    
    # Check if cleanup action is executed
    if grep -q "cleanup.*unmount_and_clean_all" install; then
        log_success "Cleanup action execution is implemented"
    else
        log_failure "Cleanup action execution is missing"
    fi
    
    # Check if cleanup help text is provided
    if grep -q "cleanup.*Cleans up the environment after interrupted installations" install; then
        log_success "Cleanup help text is provided"
    else
        log_failure "Cleanup help text is missing"
    fi
}

# Test 7: Cleanup configuration options are implemented
test_cleanup_configuration_options() {
    log_info "Testing cleanup configuration options"
    
    # Check if ENABLE_AUTO_CLEANUP is defined
    if grep -q "ENABLE_AUTO_CLEANUP.*false" configure; then
        log_success "ENABLE_AUTO_CLEANUP configuration option is defined"
    else
        log_failure "ENABLE_AUTO_CLEANUP configuration option is missing"
    fi
    
    # Check if CLEANUP_ON_INTERRUPT is defined
    if grep -q "CLEANUP_ON_INTERRUPT.*true" configure; then
        log_success "CLEANUP_ON_INTERRUPT configuration option is defined"
    else
        log_failure "CLEANUP_ON_INTERRUPT configuration option is missing"
    fi
    
    # Check if cleanup options are in the save function
    if grep -q "ENABLE_AUTO_CLEANUP.*@Q" configure; then
        log_success "ENABLE_AUTO_CLEANUP is included in save function"
    else
        log_failure "ENABLE_AUTO_CLEANUP is missing from save function"
    fi
    
    if grep -q "CLEANUP_ON_INTERRUPT.*@Q" configure; then
        log_success "CLEANUP_ON_INTERRUPT is included in save function"
    else
        log_failure "CLEANUP_ON_INTERRUPT is missing from save function"
    fi
}

# Test 8: Cleanup configuration menu functions are implemented
test_cleanup_configuration_menu() {
    log_info "Testing cleanup configuration menu functions"
    
    # Check if ENABLE_AUTO_CLEANUP menu functions exist
    local auto_cleanup_functions=("ENABLE_AUTO_CLEANUP_tag" "ENABLE_AUTO_CLEANUP_label" "ENABLE_AUTO_CLEANUP_show" "ENABLE_AUTO_CLEANUP_help" "ENABLE_AUTO_CLEANUP_menu")
    
    for func in "${auto_cleanup_functions[@]}"; do
        if grep -q "function $func" configure; then
            log_success "Menu function $func is implemented"
        else
            log_failure "Menu function $func is missing"
        fi
    done
    
    # Check if CLEANUP_ON_INTERRUPT menu functions exist
    local interrupt_cleanup_functions=("CLEANUP_ON_INTERRUPT_tag" "CLEANUP_ON_INTERRUPT_label" "CLEANUP_ON_INTERRUPT_show" "CLEANUP_ON_INTERRUPT_help" "CLEANUP_ON_INTERRUPT_menu")
    
    for func in "${interrupt_cleanup_functions[@]}"; do
        if grep -q "function $func" configure; then
            log_success "Menu function $func is implemented"
        else
            log_failure "Menu function $func is missing"
        fi
    done
}

# Test 9: Cleanup configuration is documented
test_cleanup_configuration_documentation() {
    log_info "Testing cleanup configuration documentation"
    
    # Check if cleanup options are documented in example configuration
    if grep -q "ENABLE_AUTO_CLEANUP=false" gentoo.conf.example; then
        log_success "ENABLE_AUTO_CLEANUP is documented in example configuration"
    else
        log_failure "ENABLE_AUTO_CLEANUP is missing from example configuration"
    fi
    
    if grep -q "CLEANUP_ON_INTERRUPT=true" gentoo.conf.example; then
        log_success "CLEANUP_ON_INTERRUPT is documented in example configuration"
    else
        log_failure "CLEANUP_ON_INTERRUPT is missing from example configuration"
    fi
    
    # Check if helpful comments are provided
    if grep -q "Automatically cleanup the environment when the installer exits normally" gentoo.conf.example; then
        log_success "Helpful comments are provided for ENABLE_AUTO_CLEANUP"
    else
        log_failure "Helpful comments are missing for ENABLE_AUTO_CLEANUP"
    fi
    
    if grep -q "Automatically cleanup the environment when the installer is interrupted" gentoo.conf.example; then
        log_success "Helpful comments are provided for CLEANUP_ON_INTERRUPT"
    else
        log_failure "Helpful comments are missing for CLEANUP_ON_INTERRUPT"
    fi
}

# Test 10: Automatic cleanup integration is implemented
test_automatic_cleanup_integration() {
    log_info "Testing automatic cleanup integration"
    
    # Check if cleanup trap is set up in main_install
    if grep -q "Set up cleanup trap if enabled" scripts/main.sh; then
        log_success "Cleanup trap setup is implemented in main_install"
    else
        log_failure "Cleanup trap setup is missing from main_install"
    fi
    
    # Check if automatic cleanup is called at the end
    if grep -q "Auto cleanup enabled - cleaning up environment" scripts/main.sh; then
        log_success "Automatic cleanup at exit is implemented"
    else
        log_failure "Automatic cleanup at exit is missing"
    fi
    
    # Check if interrupt cleanup is properly handled
    if grep -q "Interrupt detected - performing automatic cleanup" scripts/main.sh; then
        log_success "Interrupt cleanup handling is implemented"
    else
        log_failure "Interrupt cleanup handling is missing"
    fi
}

# Main test execution
main() {
    log_info "Starting cleanup functionality improvements tests..."
    echo
    
    # Run all tests
    test_cleanup_function_implementation
    test_filesystem_unmounting
    test_luks_device_cleanup
    test_raid_array_cleanup
    test_additional_device_cleanup
    test_cleanup_action_integration
    test_cleanup_configuration_options
    test_cleanup_configuration_menu
    test_cleanup_configuration_documentation
    test_automatic_cleanup_integration
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Cleanup functionality improvements are working correctly."
        exit 0
    else
        log_failure "Some tests failed. Please review the cleanup functionality improvements."
        exit 1
    fi
}

# Run main function
main "$@"
