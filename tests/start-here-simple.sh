#!/bin/bash

# Simplified Start Here Script for Testing

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to find available VM disks
find_vm_disks() {
    local disks=()
    local common_paths=(
        "$HOME/vm-disks"
        "$HOME/Downloads"
        "$HOME/.local/share/Trash/files"
        "$HOME/Desktop"
        "$HOME/Documents"
    )
    
    echo -e "${BLUE}🔍 Searching for available VM disks...${NC}"
    
    for path in "${common_paths[@]}"; do
        if [[ -d "$path" ]]; then
            echo "  Checking: $path"
            while IFS= read -r -d '' file; do
                if [[ -f "$file" && "$file" == *.qcow2 ]]; then
                    local size=$(du -h "$file" 2>/dev/null | cut -f1 || echo "Unknown")
                    local name=$(basename "$file")
                    disks+=("$file|$name|$size")
                    echo "    Found: $name ($size)"
                fi
            done < <(find "$path" -maxdepth 2 -name "*.qcow2" -type f -print0 2>/dev/null)
        fi
    done
    
    echo -e "${GREEN}✓ Found ${#disks[@]} VM disk(s)${NC}"
    echo
    
    # Return the disks array
    printf '%s\n' "${disks[@]}"
}

# Function to show disk selection menu
show_disk_selection() {
    local disks=("$@")
    local selected_disk=""
    
    echo "Debug: Received ${#disks[@]} disks"
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No VM disks found!${NC}"
        return ""
    fi
    
    echo -e "${CYAN}📋 Available VM Disks:${NC}"
    echo "================================="
    
    local i=1
    for disk in "${disks[@]}"; do
        IFS='|' read -r full_path name size <<< "$disk"
        echo -e "  ${i}) ${CYAN}${name}${NC} (${GREEN}${size}${NC})"
        echo "     Path: ${YELLOW}${full_path}${NC}"
        echo
        ((i++))
    done
    
    echo -e "  0) Back to main menu"
    echo
    
    while true; do
        read -p "Select disk to boot (0-${#disks[@]}): " choice
        
        if [[ "$choice" == "0" ]]; then
            return ""
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#disks[@]} ]]; then
            local selected_index=$((choice - 1))
            IFS='|' read -r full_path name size <<< "${disks[$selected_index]}"
            selected_disk="$full_path"
            break
        else
            echo -e "${RED}❌ Invalid choice. Please enter 0-${#disks[@]}.${NC}"
        fi
    done
    
    echo "$selected_disk"
}

# Function to show main menu
show_main_menu() {
    clear
    echo -e "${GREEN}🚀 Welcome to Advanced VM Management Tools!${NC}"
    echo "=================================================="
    echo

    echo -e "${YELLOW}🎯 Choose Your VM Operation:${NC}"
    echo "  1️⃣  🆕 Install Gentoo from ISO (New VM)"
    echo "  2️⃣  🚀 Boot Installed Gentoo (Existing VM)"
    echo "  3️⃣  🔧 Advanced VM Configuration"
    echo "  4️⃣  📚 Help & Documentation"
    echo "  0️⃣  Exit"
    echo
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

    # Find available VM disks
    echo "Finding disks..."
    local available_disks
    available_disks=$(find_vm_disks)
    
    echo "Converting to array..."
    # Convert output to array
    IFS=$'\n' read -r -d '' -a disk_array <<< "$available_disks"
    
    echo "Array length: ${#disk_array[@]}"
    
    # Show disk selection menu
    echo "Showing disk selection..."
    local selected_disk
    selected_disk=$(show_disk_selection "${disk_array[@]}")
    
    if [[ -z "$selected_disk" ]]; then
        echo "No disk selected, returning to menu"
        return  # User chose to go back
    fi
    
    echo "Selected disk: $selected_disk"
    
    # Extract disk info for display
    local disk_name=$(basename "$selected_disk")
    local disk_size=$(du -h "$selected_disk" 2>/dev/null | cut -f1 || echo "Unknown")
    
    echo -e "${GREEN}📋 Selected Configuration:${NC}"
    echo "  VM Name: ${disk_name%.qcow2}"
    echo "  Storage: $selected_disk"
    echo "  Size: $disk_size"
    echo "  RAM: 16GB | CPU: 8 cores | SSH: Port 2223"
    echo

    echo -e "${YELLOW}💡 What This Does:${NC}"
    echo "  • Boots your existing Gentoo installation"
    echo "  • Uses -boot c (boot from disk, not ISO)"
    echo "  • Provides SSH access via localhost:2223"
    echo "  • Includes shared folder for file transfer"
    echo

    read -p "Press Enter to continue... "
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
                echo "Option 1 selected - New VM installation"
                read -p "Press Enter to continue..."
                ;;
            2)
                handle_boot_existing
                ;;
            3)
                echo "Option 3 selected - Advanced configuration"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo "Option 4 selected - Help & documentation"
                read -p "Press Enter to continue..."
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


