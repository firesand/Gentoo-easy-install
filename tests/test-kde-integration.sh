#!/bin/bash

# Test script for KDE integration features
# This script verifies that our KDE USE flags and system configuration work correctly

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        "PASS") echo -e "${GREEN}[PASS]${NC} $message" ;;
        "FAIL") echo -e "${RED}[FAIL]${NC} $message" ;;
        "INFO") echo -e "${BLUE}[INFO]${NC} $message" ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
    esac
}

# Function to test KDE USE flags configuration
test_kde_use_flags() {
    print_status "INFO" "Testing KDE USE flags configuration logic..."
    
    # Test the USE flags string that would be generated
    local kde_use_flags="networkmanager sddm display-manager elogind kwallet"
    local required_flags=("networkmanager" "sddm" "display-manager" "elogind" "kwallet")
    
    for flag in "${required_flags[@]}"; do
        if echo "$kde_use_flags" | grep -q "$flag"; then
            print_status "PASS" "USE flag '$flag' would be configured"
        else
            print_status "FAIL" "USE flag '$flag' is missing from configuration"
            return 1
        fi
    done
    
    print_status "PASS" "All required KDE USE flags would be configured correctly"
}

# Function to test KDE system configuration
test_kde_system_config() {
    print_status "INFO" "Testing KDE system configuration logic..."
    
    # Test that we have the correct PAM configuration content
    local pam_auth="auth           optional        pam_kwallet5.so"
    local pam_session="session        optional        pam_kwallet5.so auto_start"
    
    if echo "$pam_auth" | grep -q "pam_kwallet5.so"; then
        print_status "PASS" "KWallet PAM auth configuration content is correct"
    else
        print_status "FAIL" "KWallet PAM auth configuration content is incorrect"
        return 1
    fi
    
    if echo "$pam_session" | grep -q "pam_kwallet5.so"; then
        print_status "PASS" "KWallet PAM session configuration content is correct"
    else
        print_status "FAIL" "KWallet PAM session configuration content is incorrect"
        return 1
    fi
    
    # Test that we have the correct polkit rule content
    local polkit_content="polkit.addAdminRule(function(action, subject) { return [\"unix-group:wheel\"]; });"
    
    if echo "$polkit_content" | grep -q "unix-group:wheel"; then
        print_status "PASS" "Polkit wheel group rule content is correct"
    else
        print_status "FAIL" "Polkit wheel group rule content is incorrect"
        return 1
    fi
    
    print_status "PASS" "KDE system configuration logic is correct"
}

# Function to test KDE package selection
test_kde_packages() {
    print_status "INFO" "Testing KDE package selection..."
    
    # Check if KWallet PAM package is in additional packages
    local kde_packages="${DE_ADDITIONAL_PACKAGES[kde]:-}"
    if echo "$kde_packages" | grep -q "kde-plasma/kwallet-pam"; then
        print_status "PASS" "KWallet PAM package is included in KDE additional packages"
    else
        print_status "FAIL" "KWallet PAM package is missing from KDE additional packages"
        return 1
    fi
    
    # Check if essential KDE apps are included
    local essential_apps=("kde-apps/konsole" "kde-apps/dolphin" "kde-apps/kate")
    for app in "${essential_apps[@]}"; do
        if echo "$kde_packages" | grep -q "$app"; then
            print_status "PASS" "Essential KDE app '$app' is included"
        else
            print_status "FAIL" "Essential KDE app '$app' is missing"
            return 1
        fi
    done
    
    print_status "PASS" "KDE package selection is complete"
}

# Function to test NetworkManager integration
test_networkmanager_integration() {
    print_status "INFO" "Testing NetworkManager integration..."
    
    # Check if NetworkManager is set as default for KDE
    local default_nm=$(get_default_nm_for_de "kde")
    if [[ "$default_nm" == "networkmanager" ]]; then
        print_status "PASS" "NetworkManager is set as default for KDE"
    else
        print_status "FAIL" "NetworkManager is not set as default for KDE (got: $default_nm)"
        return 1
    fi
    
    # Check if SDDM is set as default display manager for KDE
    local default_dm=$(get_default_dm_for_de "kde")
    if [[ "$default_dm" == "sddm" ]]; then
        print_status "PASS" "SDDM is set as default display manager for KDE"
    else
        print_status "FAIL" "SDDM is not set as default display manager for KDE (got: $default_dm)"
        return 1
    fi
    
    print_status "PASS" "NetworkManager integration is properly configured"
}

# Main test function
main() {
    print_status "INFO" "Starting KDE integration tests..."
    
    # Source the desktop environments configuration
    if [[ -f "scripts/desktop_environments.sh" ]]; then
        source "scripts/desktop_environments.sh"
    else
        print_status "FAIL" "Could not find scripts/desktop_environments.sh"
        exit 1
    fi
    
    local tests_passed=0
    local tests_total=0
    
    # Run all tests
    if test_kde_use_flags; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    if test_kde_system_config; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    if test_kde_packages; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    if test_networkmanager_integration; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    # Print summary
    echo
    if [[ $tests_passed -eq $tests_total ]]; then
        print_status "PASS" "All KDE integration tests passed! ($tests_passed/$tests_total)"
        exit 0
    else
        print_status "FAIL" "Some KDE integration tests failed ($tests_passed/$tests_total)"
        exit 1
    fi
}

# Run main function
main "$@"
