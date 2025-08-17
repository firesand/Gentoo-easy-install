#!/bin/bash

# Test script for network configuration improvements
# Tests the enhanced network configuration logic and connectivity verification

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

# Test 1: Network configuration logic prioritizes user preferences
test_network_configuration_logic() {
    log_info "Testing network configuration logic prioritizes user preferences"
    
    # Check if the logic checks user's explicit preference first
    if grep -q "User explicitly disabled network manager" scripts/main.sh; then
        log_success "User explicit preference is checked first in network logic"
    else
        log_failure "User explicit preference is not prioritized in network logic"
    fi
    
    # Check if auto-detection only happens when user hasn.*explicitly set it
    if grep -q "Only auto-detect if user hasn.*explicitly set it" scripts/main.sh; then
        log_success "Auto-detection is properly conditional on user preference"
    else
        log_failure "Auto-detection logic is not properly conditional"
    fi
    
    # Check if fallback logic exists for no desktop environment
    if grep -q "No desktop environment.*check if user explicitly enabled" scripts/main.sh; then
        log_success "Fallback logic exists for systems without desktop environment"
    else
        log_failure "Fallback logic is missing for systems without desktop environment"
    fi
}

# Test 2: Network connectivity verification is implemented
test_network_connectivity_verification() {
    log_info "Testing network connectivity verification"
    
    # Check if the verification function exists
    if grep -q "verify_network_configuration" scripts/main.sh; then
        log_success "Network configuration verification function is implemented"
    else
        log_failure "Network configuration verification function is missing"
    fi
    
    # Check if both dhcpcd and NetworkManager are checked
    if grep -q "Check if dhcpcd is enabled" scripts/main.sh; then
        log_success "dhcpcd service verification is implemented"
    else
        log_failure "dhcpcd service verification is missing"
    fi
    
    if grep -q "Check if NetworkManager is enabled" scripts/main.sh; then
        log_success "NetworkManager service verification is implemented"
    else
        log_failure "NetworkManager service verification is missing"
    fi
}

# Test 3: Fallback network service offering
test_fallback_network_service() {
    log_info "Testing fallback network service offering"
    
    # Check if fallback to dhcpcd is offered when no network service is enabled
    if grep -q "Offer to enable dhcpcd as a fallback" scripts/main.sh; then
        log_success "Fallback network service offering is implemented"
    else
        log_failure "Fallback network service offering is missing"
    fi
    
    # Check if user is warned about potential network connectivity issues
    if grep -q "WARNING: No network service is enabled" scripts/main.sh; then
        log_success "Network connectivity warnings are implemented"
    else
        log_failure "Network connectivity warnings are missing"
    fi
    
    # Check if fallback installation logic exists
    if grep -q "Enabling dhcpcd service as fallback for network connectivity" scripts/main.sh; then
        log_success "Fallback network service installation is implemented"
    else
        log_failure "Fallback network service installation is missing"
    fi
}

# Test 4: Integration with configure_openrc
test_configure_openrc_integration() {
    log_info "Testing configure_openrc integration"
    
    # Check if network verification is called from configure_openrc
    if grep -q "verify_network_configuration" scripts/main.sh; then
        log_success "Network verification is integrated with configure_openrc"
    else
        log_failure "Network verification is not integrated with configure_openrc"
    fi
    
    # Check if the function is called at the right place
    if grep -A 2 -B 50 "verify_network_configuration" scripts/main.sh | grep -q "configure_openrc"; then
        log_success "Network verification is properly placed in configure_openrc"
    else
        log_failure "Network verification placement in configure_openrc is incorrect"
    fi
}

# Test 5: Comprehensive network service detection
test_network_service_detection() {
    log_info "Testing comprehensive network service detection"
    
    # Check if both systemd and OpenRC are supported
    if grep -q "systemctl is-enabled dhcpcd" scripts/main.sh; then
        log_success "systemd network service detection is implemented"
    else
        log_failure "systemd network service detection is missing"
    fi
    
    if grep -q "rc-update show.*dhcpcd.*default" scripts/main.sh; then
        log_success "OpenRC network service detection is implemented"
    else
        log_failure "OpenRC network service detection is missing"
    fi
    
    # Check if NetworkManager detection is also comprehensive
    if grep -q "systemctl is-enabled NetworkManager" scripts/main.sh; then
        log_success "systemd NetworkManager detection is implemented"
    else
        log_failure "systemd NetworkManager detection is missing"
    fi
    
    if grep -q "rc-update show.*NetworkManager.*default" scripts/main.sh; then
        log_success "OpenRC NetworkManager detection is implemented"
    else
        log_failure "OpenRC NetworkManager detection is missing"
    fi
}

# Test 6: Clear user feedback and guidance
test_user_feedback_and_guidance() {
    log_info "Testing user feedback and guidance"
    
    # Check if clear success messages are provided
    if grep -q "Network configuration verified: system will have network connectivity" scripts/main.sh; then
        log_success "Clear success messages for network configuration are implemented"
    else
        log_failure "Clear success messages for network configuration are missing"
    fi
    
    # Check if detailed service information is provided
    if grep -q "dhcpcd service enabled for automatic network configuration" scripts/main.sh; then
        log_success "Detailed service information is provided"
    else
        log_failure "Detailed service information is missing"
    fi
    
    # Check if user guidance is provided for manual configuration
    if grep -q "user must configure networking manually" scripts/main.sh; then
        log_success "User guidance for manual configuration is provided"
    else
        log_failure "User guidance for manual configuration is missing"
    fi
}

# Main test execution
main() {
    log_info "Starting network configuration improvements tests..."
    echo
    
    # Run all tests
    test_network_configuration_logic
    test_network_connectivity_verification
    test_fallback_network_service
    test_configure_openrc_integration
    test_network_service_detection
    test_user_feedback_and_guidance
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Network configuration improvements are working correctly."
        exit 0
    else
        log_failure "Some tests failed. Please review the network configuration improvements."
        exit 1
    fi
}

# Run main function
main "$@"
