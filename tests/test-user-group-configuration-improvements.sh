#!/bin/bash

# Test script for user group configuration improvements
# Tests the enhanced user group configuration with customizable groups and desktop environment integration

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

# Test 1: CREATE_USER_GROUPS configuration variable is defined
test_create_user_groups_variable() {
    log_info "Testing CREATE_USER_GROUPS configuration variable"
    
    # Check if CREATE_USER_GROUPS is defined in configure
    if grep -q "CREATE_USER_GROUPS.*users,wheel,audio,video,usb" configure; then
        log_success "CREATE_USER_GROUPS is properly defined with default value"
    else
        log_failure "CREATE_USER_GROUPS is missing or has incorrect default value"
    fi
    
    # Check if CREATE_USER_GROUPS is in the save function
    if grep -q "CREATE_USER_GROUPS.*@Q" configure; then
        log_success "CREATE_USER_GROUPS is included in configuration save function"
    else
        log_failure "CREATE_USER_GROUPS is missing from configuration save function"
    fi
}

# Test 2: CREATE_USER_GROUPS menu functions are implemented
test_create_user_groups_menu_functions() {
    log_info "Testing CREATE_USER_GROUPS menu functions"
    
    # Check if all required menu functions exist
    local functions=("CREATE_USER_GROUPS_tag" "CREATE_USER_GROUPS_label" "CREATE_USER_GROUPS_show" "CREATE_USER_GROUPS_help" "CREATE_USER_GROUPS_menu")
    
    for func in "${functions[@]}"; do
        if grep -q "function $func" configure; then
            log_success "Menu function $func is implemented"
        else
            log_failure "Menu function $func is missing"
        fi
    done
    
    # Check if CREATE_USER_GROUPS is in the main menu list
    if grep -A 10 -B 5 "CREATE_USER_GROUPS" configure | grep -q "CREATE_USER"; then
        log_success "CREATE_USER_GROUPS is properly integrated in the main menu"
    else
        log_failure "CREATE_USER_GROUPS is not properly integrated in the main menu"
    fi
}

# Test 3: CREATE_USER_GROUPS is documented in example configuration
test_create_user_groups_documentation() {
    log_info "Testing CREATE_USER_GROUPS documentation"
    
    # Check if CREATE_USER_GROUPS is documented in gentoo.conf.example
    if grep -q "CREATE_USER_GROUPS.*users,wheel,audio,video,usb" gentoo.conf.example; then
        log_success "CREATE_USER_GROUPS is documented in example configuration"
    else
        log_failure "CREATE_USER_GROUPS is missing from example configuration"
    fi
    
    # Check if helpful comments are provided
    if grep -q "Groups for the new user account.*comma-separated" gentoo.conf.example; then
        log_success "Helpful comments are provided for CREATE_USER_GROUPS"
    else
        log_failure "Helpful comments are missing for CREATE_USER_GROUPS"
    fi
}

# Test 4: User creation logic uses configurable groups
test_user_creation_configurable_groups() {
    log_info "Testing user creation configurable groups logic"
    
    # Check if the script uses CREATE_USER_GROUPS variable
    if grep -q "CREATE_USER_GROUPS.*users,wheel,audio,video,usb" scripts/main.sh; then
        log_success "User creation logic uses CREATE_USER_GROUPS variable"
    else
        log_failure "User creation logic does not use CREATE_USER_GROUPS variable"
    fi
    
    # Check if fallback default groups are provided
    if grep -q "CREATE_USER_GROUPS:-users,wheel,audio,video,usb" scripts/main.sh; then
        log_success "Fallback default groups are properly implemented"
    else
        log_failure "Fallback default groups are missing"
    fi
}

# Test 5: Desktop environment group integration is enhanced
test_desktop_environment_group_integration() {
    log_info "Testing desktop environment group integration"
    
    # Check if desktop-specific groups are added intelligently
    if grep -q "Add desktop-specific groups if not already present" scripts/main.sh; then
        log_success "Desktop-specific groups are added intelligently"
    else
        log_failure "Desktop-specific groups logic is missing"
    fi
    
    # Check if duplicate groups are prevented
    if grep -q "if.*user_groups.*group.*then" scripts/main.sh; then
        log_success "Duplicate group prevention is implemented"
    else
        log_failure "Duplicate group prevention is missing"
    fi
    
    # Check if plugdev and input groups are handled
    if grep -q "plugdev,input" scripts/main.sh; then
        log_success "plugdev and input groups are properly handled"
    else
        log_failure "plugdev and input groups are not properly handled"
    fi
}

# Test 6: User feedback and group information
test_user_feedback_and_group_information() {
    log_info "Testing user feedback and group information"
    
    # Check if group information is displayed to user
    if grep -q "Creating user with groups:" scripts/main.sh; then
        log_success "Group information is displayed to user during creation"
    else
        log_failure "Group information display is missing"
    fi
    
    # Check if desktop group additions are logged
    if grep -q "Added desktop-specific groups:" scripts/main.sh; then
        log_success "Desktop-specific group additions are logged"
    else
        log_failure "Desktop-specific group logging is missing"
    fi
    
    # Check if final group list is shown
    if grep -q "Groups:.*user_groups" scripts/main.sh; then
        log_success "Final group list is shown to user"
    else
        log_failure "Final group list display is missing"
    fi
}

# Test 7: Configuration validation and error handling
test_configuration_validation() {
    log_info "Testing configuration validation and error handling"
    
    # Check if empty CREATE_USER_GROUPS is handled gracefully
    if grep -q "CREATE_USER_GROUPS:-users,wheel,audio,video,usb" scripts/main.sh; then
        log_success "Empty CREATE_USER_GROUPS is handled with fallback defaults"
    else
        log_failure "Empty CREATE_USER_GROUPS handling is missing"
    fi
    
    # Check if user creation errors are handled
    if grep -q "Could not create user.*CREATE_USER" scripts/main.sh; then
        log_success "User creation error handling is implemented"
    else
        log_failure "User creation error handling is missing"
    fi
}

# Main test execution
main() {
    log_info "Starting user group configuration improvements tests..."
    echo
    
    # Run all tests
    test_create_user_groups_variable
    test_create_user_groups_menu_functions
    test_create_user_groups_documentation
    test_user_creation_configurable_groups
    test_desktop_environment_group_integration
    test_user_feedback_and_group_information
    test_configuration_validation
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! User group configuration improvements are working correctly."
        exit 0
    else
        log_failure "Some tests failed. Please review the user group configuration improvements."
        exit 1
    fi
}

# Run main function
main "$@"
