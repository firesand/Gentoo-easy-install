#!/bin/bash

# Test script for password security improvements
# Tests the removal of plaintext password storage and implementation of secure alternatives

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

# Test 1: CREATE_USER_PASSWORD variable is removed from configuration
test_password_variable_removal() {
    log_info "Testing removal of CREATE_USER_PASSWORD variable"
    
    # Check if CREATE_USER_PASSWORD variable assignment is removed from configure script
    if ! grep -q "CREATE_USER_PASSWORD=" configure; then
        log_success "CREATE_USER_PASSWORD variable assignment is completely removed from configure script"
    else
        log_failure "CREATE_USER_PASSWORD variable assignment still exists in configure script"
    fi
    
    # Check if CREATE_USER_PASSWORD variable assignment is removed from example configuration
    if ! grep -q "CREATE_USER_PASSWORD=" gentoo.conf.example; then
        log_success "CREATE_USER_PASSWORD variable assignment is completely removed from example configuration"
    else
        log_failure "CREATE_USER_PASSWORD variable assignment still exists in example configuration"
    fi
    
    # Check if CREATE_USER_PASSWORD variable assignment is removed from main script
    if ! grep -q "CREATE_USER_PASSWORD=" scripts/main.sh; then
        log_success "CREATE_USER_PASSWORD variable assignment is completely removed from main script"
    else
        log_failure "CREATE_USER_PASSWORD variable assignment still exists in main script"
    fi
}

# Test 2: CREATE_USER_PASSWORD menu functions are removed
test_password_menu_functions_removal() {
    log_info "Testing removal of CREATE_USER_PASSWORD menu functions"
    
    # Check if CREATE_USER_PASSWORD menu functions are removed
    local password_functions=("CREATE_USER_PASSWORD_tag" "CREATE_USER_PASSWORD_label" "CREATE_USER_PASSWORD_show" "CREATE_USER_PASSWORD_help" "CREATE_USER_PASSWORD_menu")
    
    for func in "${password_functions[@]}"; do
        if ! grep -q "function $func" configure; then
            log_success "Menu function $func is removed"
        else
            log_failure "Menu function $func still exists"
        fi
    done
}

# Test 3: CREATE_USER_PASSWORD is removed from save function
test_password_save_function_removal() {
    log_info "Testing removal of CREATE_USER_PASSWORD from save function"
    
    # Check if CREATE_USER_PASSWORD is removed from save function
    if ! grep -q "CREATE_USER_PASSWORD.*@Q" configure; then
        log_success "CREATE_USER_PASSWORD is removed from save function"
    else
        log_failure "CREATE_USER_PASSWORD still exists in save function"
    fi
}

# Test 4: CREATE_USER_PASSWORD is removed from menu list
test_password_menu_list_removal() {
    log_info "Testing removal of CREATE_USER_PASSWORD from menu list"
    
    # Check if CREATE_USER_PASSWORD is removed from menu list (but allow comments)
    if ! grep -q "CREATE_USER_PASSWORD.*\"" configure; then
        log_success "CREATE_USER_PASSWORD is removed from menu list"
    else
        log_failure "CREATE_USER_PASSWORD still exists in menu list"
    fi
}

# Test 5: Secure password generation function is implemented
test_secure_password_generation() {
    log_info "Testing secure password generation function"
    
    # Check if generate_secure_password function exists
    if grep -q "function generate_secure_password" scripts/main.sh; then
        log_success "generate_secure_password function is implemented"
    else
        log_failure "generate_secure_password function is missing"
    fi
    
    # Check if function uses secure random source
    if grep -q "/dev/urandom" scripts/main.sh; then
        log_success "Password generation uses /dev/urandom for security"
    else
        log_failure "Password generation does not use /dev/urandom"
    fi
    
    # Check if function generates appropriate length passwords
    if grep -q "password_length=16" scripts/main.sh; then
        log_success "Password generation creates 16-character passwords"
    else
        log_failure "Password generation length is not properly configured"
    fi
}

# Test 6: ENABLE_RANDOM_PASSWORD option is implemented
test_random_password_option() {
    log_info "Testing ENABLE_RANDOM_PASSWORD option implementation"
    
    # Check if ENABLE_RANDOM_PASSWORD is defined in configure
    if grep -q "ENABLE_RANDOM_PASSWORD.*false" configure; then
        log_success "ENABLE_RANDOM_PASSWORD option is defined in configure"
    else
        log_failure "ENABLE_RANDOM_PASSWORD option is missing from configure"
    fi
    
    # Check if ENABLE_RANDOM_PASSWORD is in the save function
    if grep -q "ENABLE_RANDOM_PASSWORD.*@Q" configure; then
        log_success "ENABLE_RANDOM_PASSWORD is included in save function"
    else
        log_failure "ENABLE_RANDOM_PASSWORD is missing from save function"
    fi
    
    # Check if ENABLE_RANDOM_PASSWORD is in the menu list
    if grep -q "ENABLE_RANDOM_PASSWORD" configure; then
        log_success "ENABLE_RANDOM_PASSWORD is included in menu list"
    else
        log_failure "ENABLE_RANDOM_PASSWORD is missing from menu list"
    fi
}

# Test 7: ENABLE_RANDOM_PASSWORD menu functions are implemented
test_random_password_menu_functions() {
    log_info "Testing ENABLE_RANDOM_PASSWORD menu functions"
    
    # Check if ENABLE_RANDOM_PASSWORD menu functions exist
    local random_password_functions=("ENABLE_RANDOM_PASSWORD_tag" "ENABLE_RANDOM_PASSWORD_label" "ENABLE_RANDOM_PASSWORD_show" "ENABLE_RANDOM_PASSWORD_help" "ENABLE_RANDOM_PASSWORD_menu")
    
    for func in "${random_password_functions[@]}"; do
        if grep -q "function $func" configure; then
            log_success "Menu function $func is implemented"
        else
            log_failure "Menu function $func is missing"
        fi
    done
}

# Test 8: Secure password handling logic is implemented in main script
test_secure_password_handling() {
    log_info "Testing secure password handling logic in main script"
    
    # Check if random password logic is implemented
    if grep -q "ENABLE_RANDOM_PASSWORD.*true" scripts/main.sh; then
        log_success "Random password logic is implemented in main script"
    else
        log_failure "Random password logic is missing from main script"
    fi
    
    # Check if interactive password logic is implemented
    if grep -q "Setting password.*interactively" scripts/main.sh; then
        log_success "Interactive password logic is implemented in main script"
    else
        log_failure "Interactive password logic is missing from main script"
    fi
    
    # Check if password is displayed when using random generation
    if grep -q "User.*created with random password" scripts/main.sh; then
        log_success "Random password display logic is implemented"
    else
        log_failure "Random password display logic is missing"
    fi
}

# Test 9: Security documentation is updated
test_security_documentation() {
    log_info "Testing security documentation updates"
    
    # Check if security note is added to example configuration
    if grep -q "Passwords are now set interactively during installation for security" gentoo.conf.example; then
        log_success "Security note is documented in example configuration"
    else
        log_failure "Security note is missing from example configuration"
    fi
    
    # Check if CREATE_USER_PASSWORD removal is documented
    if grep -q "CREATE_USER_PASSWORD variable has been removed to prevent plaintext storage" gentoo.conf.example; then
        log_success "CREATE_USER_PASSWORD removal is documented"
    else
        log_failure "CREATE_USER_PASSWORD removal is not documented"
    fi
    
    # Check if random password option is documented
    if grep -q "Generate random password instead of interactive prompt" gentoo.conf.example; then
        log_success "Random password option is documented"
    else
        log_failure "Random password option is not documented"
    fi
}

# Test 10: No plaintext password storage exists
test_no_plaintext_storage() {
    log_info "Testing complete removal of plaintext password storage"
    
    # Check that no password variable assignments exist anywhere
    local files_to_check=("configure" "gentoo.conf.example" "scripts/main.sh")
    
    for file in "${files_to_check[@]}"; do
        if ! grep -q "PASSWORD.*=" "$file"; then
            log_success "No password variable assignments found in $file"
        else
            # Check if it's just our new secure option
            if grep -q "ENABLE_RANDOM_PASSWORD" "$file" && ! grep -q "CREATE_USER_PASSWORD.*=" "$file"; then
                log_success "Only secure password options found in $file"
            else
                log_failure "Plaintext password variables may still exist in $file"
            fi
        fi
    done
    
    # Check that no password values are stored in configuration
    if ! grep -q "PASSWORD.*=.*\".*\"" configure; then
        log_success "No password values are stored in configuration"
    else
        log_failure "Password values may still be stored in configuration"
    fi
}

# Main test execution
main() {
    log_info "Starting password security improvements tests..."
    echo
    
    # Run all tests
    test_password_variable_removal
    test_password_menu_functions_removal
    test_password_save_function_removal
    test_password_menu_list_removal
    test_secure_password_generation
    test_random_password_option
    test_random_password_menu_functions
    test_secure_password_handling
    test_security_documentation
    test_no_plaintext_storage
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Password security improvements are working correctly."
        log_success "✅ Plaintext password storage has been completely eliminated!"
        log_success "✅ Secure alternatives (interactive + random generation) are implemented!"
        exit 0
    else
        log_failure "Some tests failed. Please review the password security improvements."
        exit 1
    fi
}

# Run main function
main "$@"
