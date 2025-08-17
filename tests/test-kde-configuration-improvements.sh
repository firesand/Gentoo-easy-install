#!/bin/bash

# Test script for KDE configuration improvements
# Tests the enhanced KDE system configuration with optional features and essential packages

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

# Test 1: Essential packages are properly defined
test_essential_packages_definition() {
    log_info "Testing essential packages definition"
    
    # Check if essential packages are defined for KDE
    if grep -q "kde-plasma/kwallet-pam" scripts/desktop_environments.sh; then
        log_success "KDE essential packages are properly defined"
    else
        log_failure "KDE essential packages are missing from desktop_environments.sh"
    fi
    
    # Check if essential packages are separated from additional packages
    if grep -q "DE_ESSENTIAL_PACKAGES" scripts/desktop_environments.sh; then
        log_success "Essential packages array is properly defined"
    else
        log_failure "Essential packages array is missing"
    fi
    
    # Check if additional packages no longer contain essential packages
    if ! grep -q "kde-plasma/kwallet-pam.*DE_ADDITIONAL_PACKAGES" scripts/desktop_environments.sh; then
        log_success "Essential packages are properly separated from additional packages"
    else
        log_failure "Essential packages are still mixed with additional packages"
    fi
}

# Test 2: Essential packages function exists
test_essential_packages_function() {
    log_info "Testing essential packages function"
    
    # Check if the function exists
    if grep -q "get_essential_packages_for_de" scripts/desktop_environments.sh; then
        log_success "get_essential_packages_for_de function is implemented"
    else
        log_failure "get_essential_packages_for_de function is missing"
    fi
    
    # Check if the function is called in main script
    if grep -q "get_essential_packages_for_de" scripts/main.sh; then
        log_success "Essential packages function is integrated in main script"
    else
        log_failure "Essential packages function is not integrated in main script"
    fi
}

# Test 3: KDE configuration options are defined
test_kde_configuration_options() {
    log_info "Testing KDE configuration options"
    
    # Check if KDE polkit admin option is defined
    if grep -q "ENABLE_KDE_POLKIT_ADMIN" configure; then
        log_success "ENABLE_KDE_POLKIT_ADMIN configuration option is defined"
    else
        log_failure "ENABLE_KDE_POLKIT_ADMIN configuration option is missing"
    fi
    
    # Check if KDE KWallet PAM option is defined
    if grep -q "ENABLE_KDE_KWALLET_PAM" configure; then
        log_success "ENABLE_KDE_KWALLET_PAM configuration option is defined"
    else
        log_failure "ENABLE_KDE_KWALLET_PAM configuration option is missing"
    fi
    
    # Check if these options are in the menu
    if grep -q "ENABLE_KDE_POLKIT_ADMIN.*show" configure; then
        log_success "ENABLE_KDE_POLKIT_ADMIN menu integration is implemented"
    else
        log_failure "ENABLE_KDE_POLKIT_ADMIN menu integration is missing"
    fi
}

# Test 4: KDE system configuration uses configuration options
test_kde_system_configuration_integration() {
    log_info "Testing KDE system configuration integration"
    
    # Check if polkit configuration is conditional
    if grep -q "ENABLE_KDE_POLKIT_ADMIN.*true" scripts/main.sh; then
        log_success "Polkit configuration is conditional on user preference"
    else
        log_failure "Polkit configuration is not conditional"
    fi
    
    # Check if KWallet PAM configuration is conditional
    if grep -q "ENABLE_KDE_KWALLET_PAM.*true" scripts/main.sh; then
        log_success "KWallet PAM configuration is conditional on user preference"
    else
        log_failure "KWallet PAM configuration is not conditional"
    fi
    
    # Check if appropriate messages are shown based on configuration
    if grep -q "Polkit administrative privileges disabled by user configuration" scripts/main.sh; then
        log_success "User choice feedback is implemented for polkit"
    else
        log_failure "User choice feedback is missing for polkit"
    fi
}

# Test 5: Desktop environment installation uses essential packages
test_desktop_environment_installation() {
    log_info "Testing desktop environment installation with essential packages"
    
    # Check if essential packages are installed first
    if grep -q "Installing essential.*packages.*required for functionality" scripts/main.sh; then
        log_success "Essential packages installation is properly implemented"
    else
        log_failure "Essential packages installation is missing"
    fi
    
    # Check if essential packages are separated from additional packages
    if grep -q "essential.*DE packages.*ALWAYS installed.*cannot be overridden" scripts/main.sh; then
        log_success "Essential packages are properly documented as non-overridable"
    else
        log_failure "Essential packages documentation is missing"
    fi
    
    # Check if additional packages are marked as overridable
    if grep -q "additional.*DE packages.*can be overridden by user configuration" scripts/main.sh; then
        log_success "Additional packages are properly marked as overridable"
    else
        log_failure "Additional packages overridability is not documented"
    fi
}

# Test 6: Configuration options are properly integrated in menu
test_configuration_menu_integration() {
    log_info "Testing configuration menu integration"
    
    # Check if KDE options are in the main menu list
    if grep -q "ENABLE_KDE_POLKIT_ADMIN" configure; then
        log_success "ENABLE_KDE_POLKIT_ADMIN is in the main menu"
    else
        log_failure "ENABLE_KDE_POLKIT_ADMIN is not in the main menu"
    fi
    
    # Check if KDE options show only when KDE is selected
    if grep -q "DESKTOP_ENVIRONMENT.*kde" configure; then
        log_success "KDE options are properly conditional on desktop environment"
    else
        log_failure "KDE options are not properly conditional"
    fi
}

# Main test execution
main() {
    log_info "Starting KDE configuration improvements tests..."
    echo
    
    # Run all tests
    test_essential_packages_definition
    test_essential_packages_function
    test_kde_configuration_options
    test_kde_system_configuration_integration
    test_desktop_environment_installation
    test_configuration_menu_integration
    
    echo
    log_info "Test Results Summary:"
    log_info "Tests passed: $TESTS_PASSED"
    log_info "Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! KDE configuration improvements are working correctly."
        exit 0
    else
        log_failure "Some tests failed. Please review the KDE configuration improvements."
        exit 1
    fi
}

# Run main function
main "$@"
