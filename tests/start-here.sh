#!/bin/bash

# Start Here - Your Entry Point to Advanced VM Management
# This script shows you exactly where to begin

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to show main menu
show_main_menu() {
    clear
    echo -e "${GREEN}🚀 Welcome to Advanced VM Management Tools!${NC}"
    echo "=================================================="
    echo

    echo -e "${CYAN}📋 What We've Built for You:${NC}"
    echo "  ✅ Clean, focused workspace (removed 15+ old scripts)"
    echo "  ✅ 4 essential tools for every need"
    echo "  ✅ Progressive complexity from simple to advanced"
    echo "  ✅ Professional quality for serious VM management"
    echo

    echo -e "${YELLOW}🎯 Choose Your VM Operation:${NC}"
    echo "  1️⃣  🆕 Install Gentoo from ISO (New VM)"
    echo "  2️⃣  🚀 Boot Installed Gentoo (Existing VM)"
    echo "  3️⃣  🔧 Advanced VM Configuration"
    echo "  4️⃣  📚 Help & Documentation"
    echo "  0️⃣  Exit"
    echo

    echo -e "${GREEN}💡 Quick Start Options:${NC}"
    echo "  • Option 1: For installing Gentoo on new VM"
    echo "  • Option 2: For booting your existing Gentoo installation"
    echo "  • Option 3: For advanced users who want full control"
    echo
}

# Function to handle new VM installation
handle_new_vm() {
    clear
    echo -e "${BLUE}🆕 Installing Gentoo from ISO (New VM)${NC}"
    echo "==============================================="
    echo
    
    echo -e "${CYAN}📋 Your Main Tool:${NC}"
    echo "  🐧 gentoo-vm-launcher.sh - Smart VM launcher with auto-detection"
    echo "  💡 This is your main tool for everyday use"
    echo "  🚀 Auto-detects your environment (NVIDIA, Wayland, root)"
    echo "  🔧 Smart defaults optimized for your setup"
    echo

    echo -e "${GREEN}🚀 Ready to Start?${NC}"
    echo "  Just run: ./gentoo-vm-launcher.sh"
    echo "  That's it! Everything else is optional."
    echo

    echo -e "${CYAN}📖 Need Help?${NC}"
    echo "  📚 README.md - Project overview"
    echo "  🎯 GETTING-STARTED.md - Detailed guide"
    echo "  🌐 QEMU-README.md - QEMU configuration"
    echo "  🎮 DISPLAY-BACKEND-GUIDE.md - Performance tips"
    echo

    echo -e "${YELLOW}💡 Pro Tips:${NC}"
    echo "  • Start simple, add complexity as needed"
    echo "  • Each tool builds on the previous one"
    echo "  • All tools work together seamlessly"
    echo "  • You can always go back to simpler tools"
    echo

    read -p "Press Enter to launch gentoo-vm-launcher.sh... "

    echo
    echo -e "${GREEN}🚀 Launching your main tool...${NC}"
    echo "  If you see any errors, make sure the script is executable:"
    echo "  chmod +x gentoo-vm-launcher.sh"
    echo

    # Check if the main launcher is executable
    if [[ -x "gentoo-vm-launcher.sh" ]]; then
        echo -e "${GREEN}✓ Main launcher is ready!${NC}"
        echo "  Starting in 3 seconds..."
        sleep 3
        ./gentoo-vm-launcher.sh
    else
        echo -e "${RED}❌ Main launcher needs execute permissions${NC}"
        echo "  Run: chmod +x gentoo-vm-launcher.sh"
        echo "  Then try again!"
    fi
}

# Function to handle booting existing VM
handle_boot_existing() {
    clear
    echo -e "${BLUE}🚀 Booting Installed Gentoo (Existing VM)${NC}"
    echo "=================================================="
    echo
    
    echo -e "${CYAN}📋 Your Tool for Existing VMs:${NC}"
    echo "  🐧 boot-installed-gentoo.sh - Boot from existing disk"
    echo "  💡 Specifically designed for already installed Gentoo systems"
    echo "  🚀 No ISO needed - boots directly from your VM storage"
    echo "  🔧 Optimized for performance with KVM and virtio devices"
    echo

    echo -e "${GREEN}📋 Current Configuration:${NC}"
    echo "  VM Name: Gentoo_TUI"
    echo "  Storage: /home/edo/vm-disks/Gentoo_TUI.qcow2"
    echo "  RAM: 16GB | CPU: 8 cores | SSH: Port 2223"
    echo

    echo -e "${YELLOW}💡 What This Does:${NC}"
    echo "  • Boots your existing Gentoo installation"
    echo "  • Uses -boot c (boot from disk, not ISO)"
    echo "  • Provides SSH access via localhost:2223"
    echo "  • Includes shared folder for file transfer"
    echo

    echo -e "${CYAN}📖 Documentation:${NC}"
    echo "  📚 BOOT-INSTALLED-GENTOO-README.md - Complete guide"
    echo "  ⚙️  qemu-gentoo-installed.conf - Manual QEMU arguments"
    echo

    read -p "Press Enter to launch boot-installed-gentoo.sh... "

    echo
    echo -e "${GREEN}🚀 Launching boot tool...${NC}"
    echo "  If you see any errors, make sure the script is executable:"
    echo "  chmod +x boot-installed-gentoo.sh"
    echo

    # Check if the boot script is executable
    if [[ -x "boot-installed-gentoo.sh" ]]; then
        echo -e "${GREEN}✓ Boot tool is ready!${NC}"
        echo "  Starting in 3 seconds..."
        sleep 3
        ./boot-installed-gentoo.sh
    else
        echo -e "${RED}❌ Boot tool needs execute permissions${NC}"
        echo "  Run: chmod +x boot-installed-gentoo.sh"
        echo "  Then try again!"
    fi
}

# Function to handle advanced configuration
handle_advanced_config() {
    clear
    echo -e "${BLUE}🔧 Advanced VM Configuration${NC}"
    echo "================================="
    echo
    
    echo -e "${CYAN}📋 Your Advanced Tools:${NC}"
    echo "  2️⃣  enhanced-vm-launcher.sh   ← More options (intermediate)"
    echo "  3️⃣  advanced-vm-configurator.sh ← Full control (expert)"
    echo "  4️⃣  test-display-backends.sh  ← Performance optimization"
    echo

    echo -e "${YELLOW}💡 When to Use Advanced Tools:${NC}"
    echo "  • enhanced-vm-launcher.sh: More configuration options"
    echo "  • advanced-vm-configurator.sh: Full control over every setting"
    echo "  • test-display-backends.sh: Optimize graphics performance"
    echo

    echo -e "${GREEN}🚀 Choose Your Tool:${NC}"
    echo "  1) enhanced-vm-launcher.sh (intermediate)"
    echo "  2) advanced-vm-configurator.sh (expert)"
    echo "  3) test-display-backends.sh (performance)"
    echo "  4) Back to main menu"
    echo

    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)
            if [[ -x "enhanced-vm-launcher.sh" ]]; then
                ./enhanced-vm-launcher.sh
            else
                echo -e "${RED}❌ Script needs execute permissions${NC}"
                echo "  Run: chmod +x enhanced-vm-launcher.sh"
            fi
            ;;
        2)
            if [[ -x "advanced-vm-configurator.sh" ]]; then
                ./advanced-vm-configurator.sh
            else
                echo -e "${RED}❌ Script needs execute permissions${NC}"
                echo "  Run: chmod +x advanced-vm-configurator.sh"
            fi
            ;;
        3)
            if [[ -x "test-display-backends.sh" ]]; then
                ./test-display-backends.sh
            else
                echo -e "${RED}❌ Script needs execute permissions${NC}"
                echo "  Run: chmod +x test-display-backends.sh"
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            ;;
    esac

    read -p "Press Enter to continue..."
}

# Function to show help and documentation
show_help_docs() {
    clear
    echo -e "${BLUE}📚 Help & Documentation${NC}"
    echo "============================="
    echo
    
    echo -e "${CYAN}📖 Available Documentation:${NC}"
    echo "  📚 README.md - Project overview"
    echo "  🎯 GETTING-STARTED.md - Detailed guide"
    echo "  🌐 QEMU-README.md - QEMU configuration"
    echo "  🎮 DISPLAY-BACKEND-GUIDE.md - Performance tips"
    echo "  🐧 BOOT-INSTALLED-GENTOO-README.md - Boot existing VM guide"
    echo

    echo -e "${YELLOW}💡 Quick Reference:${NC}"
    echo "  • New VM: gentoo-vm-launcher.sh"
    echo "  • Boot Existing: boot-installed-gentoo.sh"
    echo "  • Advanced: enhanced-vm-launcher.sh"
    echo "  • Expert: advanced-vm-configurator.sh"
    echo

    echo -e "${GREEN}🔧 Common Commands:${NC}"
    echo "  chmod +x *.sh                    # Make all scripts executable"
    echo "  ./start-here.sh                  # Show this menu again"
    echo "  ./boot-installed-gentoo.sh --help # Show boot script help"
    echo

    read -p "Press Enter to continue..."
}

# Main menu loop
main() {
    while true; do
        show_main_menu
        read -p "Enter your choice (0-4): " choice

        case $choice in
            0)
                echo -e "${GREEN}👋 Goodbye! Happy VM management!${NC}"
                exit 0
                ;;
            1)
                handle_new_vm
                break  # Exit loop after launching
                ;;
            2)
                handle_boot_existing
                break  # Exit loop after launching
                ;;
            3)
                handle_advanced_config
                ;;
            4)
                show_help_docs
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please enter 0-4.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Start the main menu
main

