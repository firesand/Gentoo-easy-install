#!/bin/bash

# Test script for disk selection functionality

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
    for disk in "${disks[@]}"; do
        echo "Debug: Disk entry: $disk"
    done
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No VM disks found!${NC}"
        echo "Please ensure you have .qcow2 files in common locations:"
        echo "  • ~/vm-disks/"
        echo "  • ~/Downloads/"
        echo "  • ~/Desktop/"
        echo "  • ~/Documents/"
        echo
        read -p "Press Enter to return to main menu..."
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

# Main test
echo "Testing disk selection functionality..."
echo

# Find disks
echo "Step 1: Finding disks..."
disks_output=$(find_vm_disks)
echo "Raw output: $disks_output"

# Convert to array
IFS=$'\n' read -r -d '' -a disks <<< "$disks_output"
echo "Array length: ${#disks[@]}"

# Show selection
echo "Step 2: Showing disk selection..."
selected=$(show_disk_selection "${disks[@]}")

if [[ -n "$selected" ]]; then
    echo "Selected disk: $selected"
else
    echo "No disk selected or user went back"
fi

