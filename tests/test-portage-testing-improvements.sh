#!/bin/bash

# Test script for Portage testing improvements
# Tests the enhanced Portage configuration with bleeding edge testing support

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

# Test 1: USE_PORTAGE_TESTING configuration variable is properly defined
test_use_portage_testing_variable() {
    log_info "Testing USE_PORTAGE_TESTING configuration variable"
    
    # Check if USE_PORTAGE_TESTING is defined in configure
    if grep -q "USE_PORTAGE_TESTING=true" configure; then
        log_success "USE_PORTAGE_TESTING is properly defined with default value"
    else
        log_failure "USE_PORTAGE_TESTING is missing or has incorrect default value"
    fi
    
    # Check if USE_PORTAGE_TESTING is in the save function
    if grep -q "USE_PORTAGE_TESTING.*@Q" configure; then
        log_success "USE_PORTAGE_TESTING is included in configuration save function"
    else
        log_failure "USE_PORTAGE_TESTING is missing from configuration save function"
    fi
}

# Test 2: USE_PORTAGE_TESTING menu functions are implemented
test_use_portage_testing_menu_functions() {
    log_info "Testing USE_PORTAGE_TESTING menu functions"
    
    # Check if all required menu functions exist
    local functions=("USE_PORTAGE_TESTING_tag" "USE_PORTAGE_TESTING_label" "USE_PORTAGE_TESTING_show" "USE_PORTAGE_TESTING_help" "USE_PORTAGE_TESTING_menu")
    
    for func in "${functions[@]}"; do
        if grep -q "function $func" configure; then
            log_success "Menu function $func is implemented"
        else
            log_failure "Menu function $func is missing"
        fi
    done
    
    # Check if USE_PORTAGE_TESTING is in the main menu list
    if grep -q "USE_PORTAGE_TESTING" configure; then
        log_success "USE_PORTAGE_TESTING is properly integrated in the main menu"
    else
        log_failure "USE_PORTAGE_TESTING is not properly integrated in the main menu"
    fi
}

# Test 3: USE_PORTAGE_TESTING is documented in example configuration
test_use_portage_testing_documentation() {
    log_info "Testing USE_PORTAGE_TESTING documentation"
    
    # Check if USE_PORTAGE_TESTING is documented in gentoo.conf.example
    if grep -q "USE_PORTAGE_TESTING=true" gentoo.conf.example; then
        log_success "USE_PORTAGE_TESTING is documented in example configuration"
    else
        log_failure "USE_PORTAGE_TESTING is missing from example configuration"
    fi
    
    # Check if helpful comments are provided
    if grep -q "ACCEPT_KEYWORDS.*GENTOO_ARCH" gentoo.conf.example; then
        log_success "Helpful comments are provided for USE_PORTAGE_TESTING"
    else
        log_failure "Helpful comments are missing for USE_PORTAGE_TESTING"
    fi
}

# Test 4: configure_portage function implements USE_PORTAGE_TESTING logic
test_configure_portage_implementation() {
    log_info "Testing configure_portage function implementation"
    
    # Check if the function checks USE_PORTAGE_TESTING
    if grep -q "USE_PORTAGE_TESTING.*true" scripts/main.sh; then
        log_success "configure_portage function checks USE_PORTAGE_TESTING variable"
    else
        log_failure "configure_portage function does not check USE_PORTAGE_TESTING variable"
    fi
    
    # Check if ACCEPT_KEYWORDS is added when testing is enabled
    if grep -q "ACCEPT_KEYWORDS.*GENTOO_ARCH" scripts/main.sh; then
        log_success "ACCEPT_KEYWORDS is properly configured for testing branch"
    else
        log_failure "ACCEPT_KEYWORDS configuration is missing"
    fi
    
    # Check if appropriate messages are shown
    if grep -q "Enabling bleeding edge testing for architecture" scripts/main.sh; then
        log_success "Appropriate messages are shown when enabling testing"
    else
        log_failure "Testing enablement messages are missing"
    fi
    
    if grep -q "Using stable branch packages.*default" scripts/main.sh; then
        log_success "Appropriate messages are shown when using stable branch"
    else
        log_failure "Stable branch messages are missing"
    fi
}

# Test 5: verify_portage_configuration function is implemented
test_verify_portage_configuration_function() {
    log_info "Testing verify_portage_configuration function"
    
    # Check if the verification function exists
    if grep -q "function verify_portage_configuration" scripts/main.sh; then
        log_success "verify_portage_configuration function is implemented"
    else
        log_failure "verify_portage_configuration function is missing"
    fi
    
    # Check if it's called from configure_portage
    if grep -A 10 -B 50 "verify_portage_configuration" scripts/main.sh | grep -q "configure_portage"; then
        log_success "verify_portage_configuration is called from configure_portage"
    else
        log_failure "verify_portage_configuration is not called from configure_portage"
    fi
}

# Test 6: Portage configuration verification logic
test_portage_configuration_verification() {
    log_info "Testing Portage configuration verification logic"
    
    # Check if make.conf existence is verified
    if grep -q "make.conf not found" scripts/main.sh; then
        log_success "make.conf existence verification is implemented"
    else
        log_failure "make.conf existence verification is missing"
    fi
    
    # Check if ACCEPT_KEYWORDS setting is verified
    if grep -q "ACCEPT_KEYWORDS.*GENTOO_ARCH.*make.conf" scripts/main.sh; then
        log_success "ACCEPT_KEYWORDS setting verification is implemented"
    else
        log_failure "ACCEPT_KEYWORDS setting verification is missing"
    fi
    
    # Check if binary package configuration is verified
    if grep -q "Binary package support is properly configured" scripts/main.sh; then
        log_success "Binary package configuration verification is implemented"
    else
        log_failure "Binary package configuration verification is missing"
    fi
}

# Test 7: Configuration consistency checks
test_configuration_consistency_checks() {
    log_info "Testing configuration consistency checks"
    
    # Check if inconsistency warnings are implemented
    if grep -q "configuration inconsistency" scripts/main.sh; then
        log_success "Configuration inconsistency warnings are implemented"
    else
        log_failure "Configuration inconsistency warnings are missing"
    fi
    
    # Check if proper success indicators are shown
    if grep -q "✓ ACCEPT_KEYWORDS.*properly configured" scripts/main.sh; then
        log_success "Success indicators for ACCEPT_KEYWORDS are implemented"
    else
        log_failure "Success indicators for ACCEPT_KEYWORDS are missing"
    fi
    
    if grep -q "✓ Stable branch packages are configured" scripts/main.sh; then
        log_success "Success indicators for stable branch are implemented"
    else
        log_failure "Success indicators for stable branch are missing"
    fi
}

# Test 8: User guidance and information
test_user_guidance_and_information() {
    log_info "Testing user guidance and information"
    
    # Check if testing branch warnings are provided
    if grep -q "testing branch packages which may be less stable" scripts/main.sh; then
        log_success "Testing branch stability warnings are provided"
    else
        log_failure "Testing branch stability warnings are missing"
    fi
    
    # Check if manual configuration guidance is provided
    if grep -q "You can disable this later by removing" scripts/main.sh; then
        log_success "Manual configuration guidance is provided"
    else
        log_failure "Manual configuration guidance is missing"
    fi
    
    # Check if architecture-specific information is shown
    if grep -q "Testing branch packages are enabled for.*GENTOO_ARCH" scripts/main.sh; then
        log_success "Architecture-specific information is shown"
    else
        log_failure "Architecture-specific information is missing"
    fi
}

# Main test execution
main() {
    log_info "Starting Portage testing improvements tests..."
    echo
    
    # Run all tests
    test_use_portage_testing_variable
    test_use_portage_testing_menu_functions
    test_use_portage_testing_documentation
    test_configure_portage_implementation
    test_verify_portage_configuration_function
    test_portage_configuration_verification
    test_configuration_consistency_checks
    test_user_guidance_and_information
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Portage testing improvements are working correctly."
        exit 0
    else
        log_failure "Some tests failed. Please review the Portage testing improvements."
        exit 1
    fi
}

# Run main function
main "$@"
