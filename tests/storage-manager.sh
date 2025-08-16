#!/bin/bash

# Advanced Storage Manager for QEMU VMs
# Features: RAID, Encryption, Snapshots, Multiple Disks, Storage Pools

set -e

# Storage Configuration
STORAGE_POOL="$HOME/vm-storage"
VM_NAME=""
DISK_CONFIGS=()
RAID_CONFIG=""
ENCRYPTION_ENABLED="false"
ENCRYPTION_PASSWORD=""
SNAPSHOT_ENABLED="false"
SNAPSHOT_RETENTION="7"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Function to show main menu
show_menu() {
    clear
    echo -e "${GREEN}💾 Advanced Storage Manager - QEMU VM Storage${NC}"
    echo "========================================================"
    echo
    
    echo -e "${CYAN}📋 Current Configuration:${NC}"
    echo "  VM Name: ${VM_NAME:-"Not set"}"
    echo "  Storage Pool: $STORAGE_POOL"
    echo "  Disks: ${#DISK_CONFIGS[@]} configured"
    echo "  RAID: ${RAID_CONFIG:-"None"}"
    echo "  Encryption: $(on_off_label ENCRYPTION_ENABLED)"
    echo "  Snapshots: $(on_off_label SNAPSHOT_ENABLED)"
    echo "  Snapshot Retention: $SNAPSHOT_RETENTION days"
    echo
    
    echo -e "${CYan}📋 Storage Management Options:${NC}"
    echo "  1) Configure VM Storage"
    echo "  2) Disk Management (Add/Remove/Configure)"
    echo "  3) RAID Configuration"
    echo "  4) Encryption Setup"
    echo "  5) Snapshot Management"
    echo "  6) Storage Pool Management"
    echo "  7) Performance Benchmarking"
    echo "  8) Show Current Configuration"
    echo "  9) Export Storage Configuration"
    echo "  10) Import Storage Configuration"
    echo "  11) Generate QEMU Commands"
    echo "  0) Exit"
    echo
    
    echo -e "${YELLOW}💡 Advanced storage features for enterprise-grade VMs${NC}"
    echo
}

# Helper functions
on_off_label() {
    local var_name="$1"
    if [[ "${!var_name}" == "true" ]]; then
        echo -e "${GREEN}ON${NC}"
    else
        echo -e "${RED}OFF${NC}"
    fi
}

# Function to configure VM storage
configure_vm_storage() {
    clear
    echo -e "${BLUE}⚙️  VM Storage Configuration${NC}"
    echo "==============================="
    echo
    
    read -p "VM Name: " VM_NAME
    [[ -z "$VM_NAME" ]] && return
    
    echo "Storage Pool Options:"
    echo "  1) Default: $HOME/vm-storage"
    echo "  2) Custom path"
    echo "  3) Use existing pool"
    read -p "Choose option [1-3]: " choice
    
    case $choice in
        1)
            STORAGE_POOL="$HOME/vm-storage"
            ;;
        2)
            read -p "Enter custom storage pool path: " STORAGE_POOL
            ;;
        3)
            echo "Available storage pools:"
            find /home -name "vm-storage" -type d 2>/dev/null | head -10
            read -p "Enter existing pool path: " STORAGE_POOL
            ;;
        *)
            echo "Invalid choice, using default"
            STORAGE_POOL="$HOME/vm-storage"
            ;;
    esac
    
    # Create storage pool if it doesn't exist
    mkdir -p "$STORAGE_POOL"
    
    echo -e "${GREEN}✓ VM storage configured${NC}"
    echo "  VM: $VM_NAME"
    echo "  Pool: $STORAGE_POOL"
    read -p "Press Enter to continue..."
}

# Function to manage disks
manage_disks() {
    clear
    echo -e "${BLUE}💿 Disk Management${NC}"
    echo "=================="
    echo
    
    echo "Current Disks:"
    if [[ ${#DISK_CONFIGS[@]} -eq 0 ]]; then
        echo "  No disks configured"
    else
        for i in "${!DISK_CONFIGS[@]}"; do
            local disk="${DISK_CONFIGS[$i]}"
            echo "  $((i+1))) $disk"
        done
    fi
    echo
    
    echo "Options:"
    echo "  1) Add new disk"
    echo "  2) Remove disk"
    echo "  3) Configure disk"
    echo "  4) Back to main menu"
    echo
    
    read -p "Choose option [1-4]: " choice
    
    case $choice in
        1) add_disk ;;
        2) remove_disk ;;
        3) configure_disk ;;
        4) return ;;
        *) echo "Invalid option" ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to add a new disk
add_disk() {
    clear
    echo -e "${BLUE}➕ Add New Disk${NC}"
    echo "==============="
    echo
    
    local disk_name=""
    local disk_size=""
    local disk_bus=""
    local disk_format=""
    
    read -p "Disk name (e.g., data, cache, backup): " disk_name
    [[ -z "$disk_name" ]] && return
    
    echo "Disk size options: 10G, 20G, 50G, 100G, 200G, 500G, 1T, 2T"
    read -p "Disk size: " disk_size
    [[ -z "$disk_size" ]] && return
    
    echo "Storage bus options:"
    echo "  1) virtio (best performance)"
    echo "  2) sata (good compatibility)"
    echo "  3) ide (best compatibility)"
    echo "  4) nvme (fastest, requires drivers)"
    echo "  5) scsi (enterprise, requires drivers)"
    read -p "Choose storage bus [1-5]: " choice
    
    case $choice in
        1) disk_bus="virtio" ;;
        2) disk_bus="sata" ;;
        3) disk_bus="ide" ;;
        4) disk_bus="nvme" ;;
        5) disk_bus="scsi" ;;
        *) disk_bus="virtio" ;;
    esac
    
    echo "Disk format options:"
    echo "  1) qcow2 (recommended, supports snapshots)"
    echo "  2) raw (best performance, no snapshots)"
    echo "  3) vmdk (VMware compatibility)"
    echo "  4) vdi (VirtualBox compatibility)"
    read -p "Choose format [1-4]: " choice
    
    case $choice in
        1) disk_format="qcow2" ;;
        2) disk_format="raw" ;;
        3) disk_format="vmdk" ;;
        4) disk_format="vdi" ;;
        *) disk_format="qcow2" ;;
    esac
    
    # Create disk configuration string
    local disk_config="$disk_name:$disk_size:$disk_bus:$disk_format"
    DISK_CONFIGS+=("$disk_config")
    
    echo -e "${GREEN}✓ Disk added: $disk_name${NC}"
    echo "  Size: $disk_size"
    echo "  Bus: $disk_bus"
    echo "  Format: $disk_format"
}

# Function to remove a disk
remove_disk() {
    if [[ ${#DISK_CONFIGS[@]} -eq 0 ]]; then
        echo "No disks to remove"
        return
    fi
    
    echo "Select disk to remove:"
    for i in "${!DISK_CONFIGS[@]}"; do
        local disk="${DISK_CONFIGS[$i]}"
        echo "  $((i+1))) $disk"
    done
    
    read -p "Enter disk number: " choice
    local index=$((choice-1))
    
    if [[ $index -ge 0 && $index -lt ${#DISK_CONFIGS[@]} ]]; then
        local removed_disk="${DISK_CONFIGS[$index]}"
        unset DISK_CONFIGS[$index]
        DISK_CONFIGS=("${DISK_CONFIGS[@]}")  # Reindex array
        echo -e "${GREEN}✓ Disk removed: $removed_disk${NC}"
    else
        echo -e "${RED}Invalid disk number${NC}"
    fi
}

# Function to configure RAID
configure_raid() {
    clear
    echo -e "${BLUE}🔀 RAID Configuration${NC}"
    echo "====================="
    echo
    
    if [[ ${#DISK_CONFIGS[@]} -lt 2 ]]; then
        echo -e "${YELLOW}⚠️  Need at least 2 disks for RAID configuration${NC}"
        echo "Current disks: ${#DISK_CONFIGS[@]}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "RAID Level Options:"
    echo "  1) RAID 0 (Stripe - performance, no redundancy)"
    echo "  2) RAID 1 (Mirror - redundancy, 50% capacity)"
    echo "  3) RAID 5 (Parity - redundancy, 1 disk overhead)"
    echo "  4) RAID 10 (Stripe + Mirror - performance + redundancy)"
    echo "  5) No RAID"
    read -p "Choose RAID level [1-5]: " choice
    
    case $choice in
        1) RAID_CONFIG="raid0" ;;
        2) RAID_CONFIG="raid1" ;;
        3) RAID_CONFIG="raid5" ;;
        4) RAID_CONFIG="raid10" ;;
        5) RAID_CONFIG="none" ;;
        *) RAID_CONFIG="none" ;;
    esac
    
    if [[ "$RAID_CONFIG" != "none" ]]; then
        echo "Select disks for RAID (comma-separated, e.g., 1,2,3):"
        for i in "${!DISK_CONFIGS[@]}"; do
            local disk="${DISK_CONFIGS[$i]}"
            echo "  $((i+1))) $disk"
        done
        
        read -p "Enter disk numbers: " disk_numbers
        RAID_CONFIG="$RAID_CONFIG:$disk_numbers"
        
        echo -e "${GREEN}✓ RAID configured: $RAID_CONFIG${NC}"
    else
        echo -e "${GREEN}✓ RAID disabled${NC}"
    fi
}

# Function to configure encryption
configure_encryption() {
    clear
    echo -e "${BLUE}🔐 Encryption Configuration${NC}"
    echo "========================="
    echo
    
    echo "Encryption Options:"
    echo "  1) Enable LUKS encryption"
    echo "  2) Disable encryption"
    echo "  3) Configure encryption settings"
    read -p "Choose option [1-3]: " choice
    
    case $choice in
        1)
            ENCRYPTION_ENABLED="true"
            echo -e "${GREEN}✓ Encryption enabled${NC}"
            ;;
        2)
            ENCRYPTION_ENABLED="false"
            echo -e "${GREEN}✓ Encryption disabled${NC}"
            ;;
        3)
            if [[ "$ENCRYPTION_ENABLED" == "true" ]]; then
                echo "Encryption Settings:"
                echo "  Algorithm: AES-XTS (recommended)"
                echo "  Key size: 256-bit (recommended)"
                echo "  Hash: SHA-256 (recommended)"
                
                read -p "Enter encryption password: " -s ENCRYPTION_PASSWORD
                echo
                
                if [[ -n "$ENCRYPTION_PASSWORD" ]]; then
                    echo -e "${GREEN}✓ Encryption password set${NC}"
                else
                    echo -e "${RED}❌ No password provided${NC}"
                fi
            else
                echo "Enable encryption first"
            fi
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to manage snapshots
manage_snapshots() {
    clear
    echo -e "${BLUE}📸 Snapshot Management${NC}"
    echo "======================="
    echo
    
    echo "Snapshot Options:"
    echo "  1) Enable snapshots"
    echo "  2) Disable snapshots"
    echo "  3) Configure retention policy"
    echo "  4) List existing snapshots"
    echo "  5) Create snapshot"
    echo "  6) Restore snapshot"
    echo "  7) Delete snapshot"
    echo "  8) Back to main menu"
    echo
    
    read -p "Choose option [1-8]: " choice
    
    case $choice in
        1) SNAPSHOT_ENABLED="true"; echo -e "${GREEN}✓ Snapshots enabled${NC}" ;;
        2) SNAPSHOT_ENABLED="false"; echo -e "${GREEN}✓ Snapshots disabled${NC}" ;;
        3) configure_snapshot_retention ;;
        4) list_snapshots ;;
        5) create_snapshot ;;
        6) restore_snapshot ;;
        7) delete_snapshot ;;
        8) return ;;
        *) echo "Invalid option" ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to configure snapshot retention
configure_snapshot_retention() {
    echo "Snapshot Retention Policy:"
    echo "  Current: $SNAPSHOT_RETENTION days"
    echo "  Options: 1, 3, 7, 14, 30, 90 days"
    read -p "Enter retention period (days): " retention
    
    if [[ "$retention" =~ ^[0-9]+$ ]]; then
        SNAPSHOT_RETENTION="$retention"
        echo -e "${GREEN}✓ Retention policy updated: $SNAPSHOT_RETENTION days${NC}"
    else
        echo -e "${RED}Invalid retention period${NC}"
    fi
}

# Function to list snapshots
list_snapshots() {
    if [[ -z "$VM_NAME" ]]; then
        echo "No VM configured"
        return
    fi
    
    local snapshot_dir="$STORAGE_POOL/$VM_NAME/snapshots"
    if [[ -d "$snapshot_dir" ]]; then
        echo "Snapshots for $VM_NAME:"
        ls -la "$snapshot_dir" 2>/dev/null || echo "  No snapshots found"
    else
        echo "  No snapshots directory found"
    fi
}

# Function to create snapshot
create_snapshot() {
    if [[ -z "$VM_NAME" ]]; then
        echo "No VM configured"
        return
    fi
    
    local snapshot_name=""
    read -p "Enter snapshot name: " snapshot_name
    [[ -z "$snapshot_name" ]] && return
    
    local snapshot_dir="$STORAGE_POOL/$VM_NAME/snapshots"
    mkdir -p "$snapshot_dir"
    
    # Create snapshot using qemu-img
    for disk_config in "${DISK_CONFIGS[@]}"; do
        local disk_name=$(echo "$disk_config" | cut -d: -f1)
        local disk_path="$STORAGE_POOL/$VM_NAME/$disk_name.$disk_format"
        
        if [[ -f "$disk_path" ]]; then
            echo "Creating snapshot for $disk_name..."
            qemu-img snapshot -c "$snapshot_name" "$disk_path"
        fi
    done
    
    echo -e "${GREEN}✓ Snapshot created: $snapshot_name${NC}"
}

# Function to restore snapshot
restore_snapshot() {
    if [[ -z "$VM_NAME" ]]; then
        echo "No VM configured"
        return
    fi
    
    local snapshot_name=""
    read -p "Enter snapshot name to restore: " snapshot_name
    [[ -z "$snapshot_name" ]] && return
    
    echo -e "${YELLOW}⚠️  Warning: Restoring snapshot will overwrite current disk state${NC}"
    read -p "Are you sure? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for disk_config in "${DISK_CONFIGS[@]}"; do
            local disk_name=$(echo "$disk_config" | cut -d: -f1)
            local disk_path="$STORAGE_POOL/$VM_NAME/$disk_name.$disk_format"
            
            if [[ -f "$disk_path" ]]; then
                echo "Restoring snapshot for $disk_name..."
                qemu-img snapshot -a "$snapshot_name" "$disk_path"
            fi
        done
        
        echo -e "${GREEN}✓ Snapshot restored: $snapshot_name${NC}"
    fi
}

# Function to delete snapshot
delete_snapshot() {
    if [[ -z "$VM_NAME" ]]; then
        echo "No VM configured"
        return
    fi
    
    local snapshot_name=""
    read -p "Enter snapshot name to delete: " snapshot_name
    [[ -z "$snapshot_name" ]] && return
    
    echo -e "${YELLOW}⚠️  Warning: Deleting snapshot cannot be undone${NC}"
    read -p "Are you sure? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for disk_config in "${DISK_CONFIGS[@]}"; do
            local disk_name=$(echo "$disk_config" | cut -d: -f1)
            local disk_path="$STORAGE_POOL/$VM_NAME/$disk_path"
            
            if [[ -f "$disk_path" ]]; then
                echo "Deleting snapshot for $disk_name..."
                qemu-img snapshot -d "$snapshot_name" "$disk_path"
            fi
        done
        
        echo -e "${GREEN}✓ Snapshot deleted: $snapshot_name${NC}"
    fi
}

# Function to manage storage pool
manage_storage_pool() {
    clear
    echo -e "${BLUE}🏗️  Storage Pool Management${NC}"
    echo "============================"
    echo
    
    echo "Storage Pool: $STORAGE_POOL"
    echo
    
    echo "Options:"
    echo "  1) Create storage pool"
    echo "  2) List storage pools"
    echo "  3) Clean up old VMs"
    echo "  4) Show pool statistics"
    echo "  5) Back to main menu"
    echo
    
    read -p "Choose option [1-5]: " choice
    
    case $choice in
        1) create_storage_pool ;;
        2) list_storage_pools ;;
        3) cleanup_storage_pool ;;
        4) show_pool_statistics ;;
        5) return ;;
        *) echo "Invalid option" ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to create storage pool
create_storage_pool() {
    echo "Creating storage pool: $STORAGE_POOL"
    mkdir -p "$STORAGE_POOL"
    
    # Create subdirectories
    mkdir -p "$STORAGE_POOL/vms"
    mkdir -p "$STORAGE_POOL/templates"
    mkdir -p "$STORAGE_POOL/backups"
    
    echo -e "${GREEN}✓ Storage pool created${NC}"
    echo "  Main: $STORAGE_POOL"
    echo "  VMs: $STORAGE_POOL/vms"
    echo "  Templates: $STORAGE_POOL/templates"
    echo "  Backups: $STORAGE_POOL/backups"
}

# Function to list storage pools
list_storage_pools() {
    echo "Available storage pools:"
    find /home -name "*vm*storage*" -type d 2>/dev/null | while read pool; do
        local size=$(du -sh "$pool" 2>/dev/null | cut -f1)
        echo "  $pool ($size)"
    done
}

# Function to show pool statistics
show_pool_statistics() {
    if [[ -d "$STORAGE_POOL" ]]; then
        echo "Storage Pool Statistics:"
        echo "  Location: $STORAGE_POOL"
        echo "  Total size: $(du -sh "$STORAGE_POOL" | cut -f1)"
        echo "  VMs: $(find "$STORAGE_POOL" -name "*.qcow2" -o -name "*.raw" | wc -l)"
        echo "  Snapshots: $(find "$STORAGE_POOL" -name "*.snap" | wc -l)"
    else
        echo "Storage pool does not exist"
    fi
}

# Function to generate QEMU commands
generate_qemu_commands() {
    clear
    echo -e "${BLUE}🔧 QEMU Storage Commands${NC}"
    echo "============================="
    echo
    
    if [[ -z "$VM_NAME" || ${#DISK_CONFIGS[@]} -eq 0 ]]; then
        echo "Configure VM storage and add disks first"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Generated QEMU Storage Commands:"
    echo
    
    local disk_index=0
    for disk_config in "${DISK_CONFIGS[@]}"; do
        local disk_name=$(echo "$disk_config" | cut -d: -f1)
        local disk_size=$(echo "$disk_config" | cut -d: -f2)
        local disk_bus=$(echo "$disk_config" | cut -d: -f3)
        local disk_format=$(echo "$disk_config" | cut -d: -f4)
        
        local disk_path="$STORAGE_POOL/$VM_NAME/$disk_name.$disk_format"
        
        echo "# Disk $((disk_index+1)): $disk_name"
        echo "-drive file=\"$disk_path\",if=$disk_bus,format=$disk_format,cache=writeback"
        
        if [[ "$ENCRYPTION_ENABLED" == "true" ]]; then
            echo "# Encrypted disk (LUKS)"
            echo "-drive file=\"$disk_path.luks\",if=$disk_bus,format=luks,encrypt.key-secret=sec0"
        fi
        
        echo
        ((disk_index++))
    done
    
    if [[ "$RAID_CONFIG" != "none" && "$RAID_CONFIG" != "" ]]; then
        echo "# RAID Configuration: $RAID_CONFIG"
        echo "# Note: RAID is handled at the guest OS level"
        echo
    fi
    
    if [[ "$SNAPSHOT_ENABLED" == "true" ]]; then
        echo "# Snapshot Support Enabled"
        echo "# Snapshots stored in: $STORAGE_POOL/$VM_NAME/snapshots"
        echo
    fi
    
    read -p "Press Enter to continue..."
}

# Function to show current configuration
show_configuration() {
    clear
    echo -e "${BLUE}📋 Current Storage Configuration${NC}"
    echo "===================================="
    echo
    
    echo -e "${CYan}VM Configuration:${NC}"
    echo "  VM Name: ${VM_NAME:-"Not set"}"
    echo "  Storage Pool: $STORAGE_POOL"
    echo
    
    echo -e "${CYan}Disk Configuration:${NC}"
    if [[ ${#DISK_CONFIGS[@]} -eq 0 ]]; then
        echo "  No disks configured"
    else
        for i in "${!DISK_CONFIGS[@]}"; do
            local disk="${DISK_CONFIGS[$i]}"
            local name=$(echo "$disk" | cut -d: -f1)
            local size=$(echo "$disk" | cut -d: -f2)
            local bus=$(echo "$disk" | cut -d: -f3)
            local format=$(echo "$disk" | cut -d: -f4)
            echo "  $((i+1))) $name: $size ($bus, $format)"
        done
    fi
    echo
    
    echo -e "${CYan}Advanced Features:${NC}"
    echo "  RAID: ${RAID_CONFIG:-"None"}"
    echo "  Encryption: $(on_off_label ENCRYPTION_ENABLED)"
    echo "  Snapshots: $(on_off_label SNAPSHOT_ENABLED)"
    echo "  Snapshot Retention: $SNAPSHOT_RETENTION days"
    echo
    
    read -p "Press Enter to continue..."
}

# Main function
main() {
    # Check QEMU installation
    if ! command -v qemu-img &> /dev/null; then
        echo -e "${RED}❌ qemu-img not found. Please install QEMU tools${NC}"
        exit 1
    fi
    
    # Create default storage pool
    mkdir -p "$STORAGE_POOL"
    
    # Main menu loop
    while true; do
        show_menu
        read -p "Choose option [0-11]: " choice
        
        case $choice in
            1) configure_vm_storage ;;
            2) manage_disks ;;
            3) configure_raid ;;
            4) configure_encryption ;;
            5) manage_snapshots ;;
            6) manage_storage_pool ;;
            7) echo "Performance benchmarking coming soon..." ; read -p "Press Enter to continue..." ;;
            8) show_configuration ;;
            9) echo "Export feature coming soon..." ; read -p "Press Enter to continue..." ;;
            10) echo "Import feature coming soon..." ; read -p "Press Enter to continue..." ;;
            11) generate_qemu_commands ;;
            0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please choose 0-11.${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main "$@"

