#!/bin/bash

# Test version without set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "Script started successfully"

# Function to find available VM disks
find_vm_disks() {
    echo "find_vm_disks function called"
    local disks=()
    local common_paths=(
        "$HOME/vm-disks"
        "$HOME/Downloads"
    )
    
    echo -e "${BLUE}🔍 Searching for available VM disks...${NC}"
    
    for path in "${common_paths[@]}"; do
        echo "Checking path: $path"
        if [[ -d "$path" ]]; then
            echo "  Path exists: $path"
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

echo "About to call find_vm_disks"

# Test the function directly
result=$(find_vm_disks)
echo "Function result: $result"

echo "Script completed successfully"

