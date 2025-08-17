#!/bin/bash

# Boot Installed Gentoo VM Script
# This script boots an already installed Gentoo system from existing VM storage
# Usage: ./boot-installed-gentoo.sh [--disk /path/to/disk.qcow2]

set -e

# Configuration for your installed Gentoo system
VM_NAME="Gentoo_TUI"
VM_RAM="16G"
VM_CORES="8"
VM_DISK="/home/edo/vm-disks/Gentoo_TUI.qcow2"
SSH_PORT="2223"
SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --disk)
                if [[ -n "$2" && "$2" != --* ]]; then
                    VM_DISK="$2"
                    # Update VM name based on disk filename
                    VM_NAME=$(basename "$2" .qcow2)
                    # Update shared folder path
                    SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
                    shift 2
                else
                    echo -e "${RED}❌ Error: --disk requires a file path${NC}"
                    exit 1
                fi
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --config)
                show_configuration
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if QEMU is installed
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        echo -e "${RED}❌ QEMU not found. Please install qemu-system-x86_64${NC}"
        exit 1
    fi
    
    # Check if KVM is available
    if ! lsmod | grep kvm &> /dev/null; then
        echo -e "${YELLOW}⚠️  KVM not available (performance will be reduced)${NC}"
    else
        echo -e "${GREEN}✓ KVM support available${NC}"
    fi
    
    # Check if the VM disk exists
    if [[ ! -f "$VM_DISK" ]]; then
        echo -e "${RED}❌ VM disk not found: $VM_DISK${NC}"
        echo "Please ensure the disk file exists and the path is correct."
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites met${NC}"
    echo
}

# Function to show configuration
show_configuration() {
    echo -e "${CYAN}📋 VM Configuration:${NC}"
    echo "  VM Name: $VM_NAME"
    echo "  RAM: $VM_RAM"
    echo "  CPU Cores: $VM_CORES"
    echo "  Disk: $VM_DISK"
    echo "  SSH Port: $SSH_PORT"
    echo "  Shared Folder: $SHARED_FOLDER"
    echo
    
    # Show disk info
    if [[ -f "$VM_DISK" ]]; then
        local disk_size=$(du -h "$VM_DISK" | cut -f1)
        echo -e "${GREEN}✓ Disk found: $disk_size${NC}"
    fi
    echo
}

# Function to create shared folder
setup_shared_folder() {
    echo -e "${BLUE}📁 Setting up shared folder...${NC}"
    mkdir -p "$SHARED_FOLDER"
    
    # Create README if it doesn't exist
    if [[ ! -f "$SHARED_FOLDER/README.txt" ]]; then
        cat > "$SHARED_FOLDER/README.txt" << EOF
Gentoo VM Shared Folder
========================

This folder is shared between your host system and the Gentoo VM.
Files placed here will be accessible from both systems.

To access this folder from inside the VM:
1. Create mount point: mkdir -p /mnt/shared
2. Mount the shared folder: mount -t virtiofs shared /mnt/shared

The shared folder will be available at /mnt/shared inside the VM.
EOF
        echo -e "${GREEN}✓ Shared folder README created${NC}"
    fi
    echo
}

# Function to start the VM
start_vm() {
    echo -e "${GREEN}🚀 Starting installed Gentoo VM...${NC}"
    echo
    
    # Build QEMU command for booting from existing disk
    local qemu_cmd="qemu-system-x86_64"
    qemu_cmd="$qemu_cmd -name \"$VM_NAME\""
    qemu_cmd="$qemu_cmd -m \"$VM_RAM\""
    qemu_cmd="$qemu_cmd -smp \"$VM_CORES\""
    qemu_cmd="$qemu_cmd -cpu host"
    qemu_cmd="$qemu_cmd -enable-kvm"
    qemu_cmd="$qemu_cmd -machine type=q35,accel=kvm"
    qemu_cmd="$qemu_cmd -vga virtio"
    qemu_cmd="$qemu_cmd -display gtk"
    
    # Storage - boot from existing disk (not ISO)
    qemu_cmd="$qemu_cmd -drive file=\"$VM_DISK\",if=virtio,cache=writeback,discard=unmap"
    
    # Network - user networking with SSH port forwarding
    qemu_cmd="$qemu_cmd -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.1,dhcpstart=10.0.2.15,hostfwd=tcp::$SSH_PORT-:22"
    qemu_cmd="$qemu_cmd -device virtio-net-pci,netdev=net0"
    
    # Shared folder
    qemu_cmd="$qemu_cmd -virtfs local,path=\"$SHARED_FOLDER\",mount_tag=shared,security_model=mapped"
    
    # Additional devices for better experience
    qemu_cmd="$qemu_cmd -device virtio-serial-pci"
    qemu_cmd="$qemu_cmd -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"
    qemu_cmd="$qemu_cmd -chardev spicevmc,id=spicechannel0,name=vdagent"
    qemu_cmd="$qemu_cmd -usb"
    qemu_cmd="$qemu_cmd -device usb-tablet"
    qemu_cmd="$qemu_cmd -device intel-hda"
    qemu_cmd="$qemu_cmd -device hda-duplex"
    qemu_cmd="$qemu_cmd -device virtio-balloon"
    qemu_cmd="$qemu_cmd -device virtio-rng-pci"
    qemu_cmd="$qemu_cmd -rtc base=utc"
    qemu_cmd="$qemu_cmd -no-reboot"
    qemu_cmd="$qemu_cmd -no-shutdown"
    
    # IMPORTANT: Boot from disk (not ISO)
    qemu_cmd="$qemu_cmd -boot c"
    
    echo -e "${CYAN}📋 QEMU Command:${NC}"
    echo "$qemu_cmd"
    echo
    
    echo -e "${GREEN}🚀 Starting VM...${NC}"
    echo "Press Ctrl+C to stop the VM"
    echo "SSH access: ssh -p $SSH_PORT root@localhost"
    echo
    
    # Execute QEMU command
    eval $qemu_cmd
    
    echo
    echo -e "${GREEN}✅ VM stopped.${NC}"
    echo "To start again, run: $0"
}

# Function to show help
show_help() {
    echo -e "${BLUE}🐧 Boot Installed Gentoo VM${NC}"
    echo "================================"
    echo
    echo "This script boots your already installed Gentoo system from the existing VM storage."
    echo
    echo -e "${CYan}📋 Current Configuration:${NC}"
    show_configuration
    echo -e "${CYan}🔧 Usage:${NC}"
    echo "  $0                                    # Start VM with current settings"
    echo "  $0 --disk /path/to/disk.qcow2        # Start VM with specific disk"
    echo "  $0 --help                            # Show this help"
    echo "  $0 --config                          # Show current configuration"
    echo
    echo -e "${CYan}📱 SSH Access:${NC}"
    echo "  ssh -p $SSH_PORT root@localhost"
    echo
    echo -e "${CYan}💡 Tips:${NC}"
    echo "  • The VM will boot directly from your installed Gentoo system"
    echo "  • No ISO is needed - it boots from the existing disk"
    echo "  • Use --disk to specify a different .qcow2 file"
    echo "  • Shared folder is available at /mnt/shared inside the VM"
    echo "  • Use Ctrl+C to stop the VM gracefully"
    echo
}

# Main script logic
main() {
    # Parse command line arguments first
    parse_arguments "$@"
    
    # Check prerequisites
    check_prerequisites
    
    # Show configuration
    show_configuration
    
    # Setup shared folder
    setup_shared_folder
    
    # Start VM
    start_vm
}

# Run main function
main "$@"

