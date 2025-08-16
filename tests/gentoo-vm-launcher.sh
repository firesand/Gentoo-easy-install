#!/bin/bash

# Gentoo VM Launcher - Unified Script with TUI
# Automatically detects environment and provides optimal configurations
# Supports: User networking, Bridge networking, NVIDIA + Wayland optimization

set -e

# Default Configuration
VM_NAME="gentoo-test"
VM_RAM="16G"
VM_CORES="8"
VM_STORAGE="512G"
VM_ISO=""
VM_DISK="$HOME/vm-disks/${VM_NAME}.qcow2"
SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
SSH_PORT="2223"
BRIDGE_NAME="br0"
VM_IP="192.168.100.100"
VM_MAC="52:54:00:12:34:56"

# Auto-detected settings
NETWORK_MODE=""
DISPLAY_TYPE=""
GPU_TYPE=""
WAYLAND_DETECTED=""
NVIDIA_DETECTED=""
ROOT_AVAILABLE=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to detect environment
detect_environment() {
    echo -e "${BLUE}🔍 Detecting your environment...${NC}"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        ROOT_AVAILABLE="true"
        echo "  ✓ Running as root (bridge networking available)"
    else
        ROOT_AVAILABLE="false"
        echo "  ⚠️  Not running as root (user networking only)"
    fi
    
    # Detect Wayland
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        WAYLAND_DETECTED="true"
        echo "  ✓ Wayland detected"
    else
        WAYLAND_DETECTED="false"
        echo "  ⚠️  X11 detected"
    fi
    
    # Detect NVIDIA
    if command -v nvidia-smi &> /dev/null || lspci | grep -i nvidia &> /dev/null; then
        NVIDIA_DETECTED="true"
        echo "  ✓ NVIDIA GPU detected"
    else
        NVIDIA_DETECTED="false"
        echo "  ⚠️  No NVIDIA GPU detected"
    fi
    
    # Check QEMU installation
    if command -v qemu-system-x86_64 &> /dev/null; then
        echo "  ✓ QEMU found"
    else
        echo -e "${RED}  ❌ QEMU not found. Please install qemu-system-x86_64${NC}"
        exit 1
    fi
    
    # Check KVM support
    if lsmod | grep kvm &> /dev/null; then
        echo "  ✓ KVM support available"
    else
        echo -e "${YELLOW}  ⚠️  KVM not available (performance will be reduced)${NC}"
    fi
    
    echo
}

# Function to show main menu
show_main_menu() {
    clear
    echo -e "${GREEN}🐧 Gentoo VM Launcher - Unified Interface${NC}"
    echo "================================================"
    echo
    
    # Show current configuration
    echo -e "${CYAN}📋 Current Configuration:${NC}"
    echo "  VM Name: $VM_NAME"
    echo "  RAM: $VM_RAM"
    echo "  CPU Cores: $VM_CORES"
    echo "  Storage: $VM_STORAGE"
    echo "  ISO: ${VM_ISO:-"Not specified"}"
    echo "  Network Mode: ${NETWORK_MODE:-"Auto-detected"}"
    echo "  Display: ${DISPLAY_TYPE:-"Auto-detected"}"
    echo
    
    # Show detected environment
    echo -e "${CYAN}🔍 Environment Detection:${NC}"
    if [[ "$ROOT_AVAILABLE" == "true" ]]; then
        echo "  ✓ Root privileges available"
    else
        echo "  ⚠️  Root privileges not available"
    fi
    
    if [[ "$WAYLAND_DETECTED" == "true" ]]; then
        echo "  ✓ Wayland detected"
    else
        echo "  ⚠️  X11 detected"
    fi
    
    if [[ "$NVIDIA_DETECTED" == "true" ]]; then
        echo "  ✓ NVIDIA GPU detected"
    else
        echo "  ⚠️  No NVIDIA GPU detected"
    fi
    echo
    
    # Show menu options
    echo -e "${CYAN}📋 Menu Options:${NC}"
    echo "  1) Configure VM Settings"
    echo "  2) Select ISO File"
    echo "  3) Configure Network"
    echo "  4) Configure Display"
    echo "  5) Show SSH Connection Info"
    echo "  6) Start VM (Auto-optimized)"
    echo "  7) Start VM (Custom Configuration)"
    echo "  8) Reset Configuration"
    echo "  9) Help & Troubleshooting"
    echo "  0) Exit"
    echo
}

# Function to configure VM settings
configure_vm_settings() {
    clear
    echo -e "${BLUE}⚙️  VM Configuration${NC}"
    echo "===================="
    echo
    
    # VM Name
    read -p "VM Name [$VM_NAME]: " input
    [[ -n "$input" ]] && VM_NAME="$input"
    
    # RAM
    read -p "RAM [$VM_RAM]: " input
    [[ -n "$input" ]] && VM_RAM="$input"
    
    # CPU Cores
    read -p "CPU Cores [$VM_CORES]: " input
    [[ -n "$input" ]] && VM_CORES="$input"
    
    # Storage
    read -p "Storage [$VM_STORAGE]: " input
    [[ -n "$input" ]] && VM_STORAGE="$input"
    
    # Update paths
    VM_DISK="$HOME/vm-disks/${VM_NAME}.qcow2"
    SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
    
    echo -e "${GREEN}✓ VM settings updated${NC}"
    read -p "Press Enter to continue..."
}

# Function to select ISO file
select_iso() {
    clear
    echo -e "${BLUE}📀 ISO Selection${NC}"
    echo "================"
    echo
    
    if [[ -n "$VM_ISO" ]]; then
        echo "Current ISO: $VM_ISO"
        echo
    fi
    
    echo "Options:"
    echo "  1) Enter ISO path manually"
    echo "  2) Browse current directory"
    echo "  3) Clear ISO selection"
    echo "  4) Back to main menu"
    echo
    
    read -p "Choose option [1-4]: " choice
    
    case $choice in
        1)
            read -p "Enter ISO path: " VM_ISO
            if [[ -f "$VM_ISO" ]]; then
                echo -e "${GREEN}✓ ISO file selected: $VM_ISO${NC}"
            else
                echo -e "${RED}❌ File not found: $VM_ISO${NC}"
                VM_ISO=""
            fi
            ;;
        2)
            echo "Available ISO files in current directory:"
            ls -la *.iso 2>/dev/null || echo "No ISO files found"
            echo
            read -p "Enter ISO filename: " filename
            if [[ -f "$filename" ]]; then
                VM_ISO="$(pwd)/$filename"
                echo -e "${GREEN}✓ ISO file selected: $VM_ISO${NC}"
            else
                echo -e "${RED}❌ File not found: $filename${NC}"
            fi
            ;;
        3)
            VM_ISO=""
            echo -e "${GREEN}✓ ISO selection cleared${NC}"
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to configure network
configure_network() {
    clear
    echo -e "${BLUE}🌐 Network Configuration${NC}"
    echo "======================="
    echo
    
    echo "Current network mode: ${NETWORK_MODE:-"Auto-detected"}"
    echo
    
    echo "Network Options:"
    if [[ "$ROOT_AVAILABLE" == "true" ]]; then
        echo "  1) Bridge networking (best performance, requires root)"
        echo "  2) User networking with SSH port forwarding (no root needed)"
        echo "  3) Auto-detect (recommended)"
    else
        echo "  1) User networking with SSH port forwarding (only option)"
        echo "  2) Auto-detect (recommended)"
    fi
    echo "  4) Back to main menu"
    echo
    
    read -p "Choose option: " choice
    
    case $choice in
        1)
            if [[ "$ROOT_AVAILABLE" == "true" ]]; then
                NETWORK_MODE="bridge"
                read -p "Bridge name [$BRIDGE_NAME]: " input
                [[ -n "$input" ]] && BRIDGE_NAME="$input"
                read -p "VM IP [$VM_IP]: " input
                [[ -n "$input" ]] && VM_IP="$input"
                echo -e "${GREEN}✓ Bridge networking configured${NC}"
            else
                echo -e "${YELLOW}⚠️  Bridge networking requires root privileges${NC}"
                NETWORK_MODE="user"
            fi
            ;;
        2)
            NETWORK_MODE="user"
            read -p "SSH port [$SSH_PORT]: " input
                [[ -n "$input" ]] && SSH_PORT="$input"
            echo -e "${GREEN}✓ User networking configured${NC}"
            ;;
        3)
            NETWORK_MODE="auto"
            echo -e "${GREEN}✓ Auto-detection enabled${NC}"
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to configure display
configure_display() {
    clear
    echo -e "${BLUE}🖥️  Display Configuration${NC}"
    echo "======================="
    echo
    
    echo "Current display: ${DISPLAY_TYPE:-"Auto-detected"}"
    echo
    
    echo "Display Options:"
    echo "  1) GTK (recommended for NVIDIA + Wayland - Stable)"
    echo "  2) SDL (performance option - may have compatibility issues)"
    echo "  3) SPICE (alternative if GTK has issues)"
    echo "  4) Auto-detect (recommended)"
    echo "  5) Back to main menu"
    echo
    
    echo -e "${YELLOW}💡 For KDE Wayland + NVIDIA: Start with GTK for stability${NC}"
    echo -e "${YELLOW}   Try SDL only if you need better performance${NC}"
    echo
    
    read -p "Choose option: " choice
    
    case $choice in
        1)
            DISPLAY_TYPE="gtk"
            echo -e "${GREEN}✓ GTK display configured (best for NVIDIA + Wayland)${NC}"
            ;;
        2)
            DISPLAY_TYPE="sdl"
            echo -e "${YELLOW}⚠️  SDL selected - may have compatibility issues with NVIDIA + Wayland${NC}"
            echo -e "${YELLOW}   If you experience crashes, fall back to GTK${NC}"
            ;;
        3)
            DISPLAY_TYPE="spice"
            echo -e "${GREEN}✓ SPICE display configured${NC}"
            ;;
        4)
            DISPLAY_TYPE="auto"
            echo -e "${GREEN}✓ Auto-detection enabled${NC}"
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to show SSH connection info
show_ssh_info() {
    clear
    echo -e "${BLUE}🔗 SSH Connection Information${NC}"
    echo "==============================="
    echo
    
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        echo "Network Mode: Bridge Networking"
        echo "  Host: $VM_IP"
        echo "  Port: 22"
        echo "  Command: ssh root@$VM_IP"
        echo
        echo "Note: VM must be configured with IP: $VM_IP"
    elif [[ "$NETWORK_MODE" == "user" ]]; then
        echo "Network Mode: User Networking with Port Forwarding"
        echo "  Host: localhost"
        echo "  Port: $SSH_PORT"
        echo "  Command: ssh -p $SSH_PORT root@localhost"
        echo
        echo "Note: Port $SSH_PORT on host forwards to port 22 on VM"
    else
        echo "Network Mode: Auto-detected"
        if [[ "$ROOT_AVAILABLE" == "true" ]]; then
            echo "  Recommended: Bridge networking"
            echo "  Host: $VM_IP"
            echo "  Command: ssh root@$VM_IP"
        else
            echo "  Recommended: User networking with port forwarding"
            echo "  Host: localhost"
            echo "  Port: $SSH_PORT"
            echo "  Command: ssh -p $SSH_PORT root@localhost"
        fi
    fi
    
    echo
    echo "SSH Setup Inside VM:"
    echo "  1. Install OpenSSH: emerge openssh"
    echo "  2. Enable service: rc-update add sshd default"
    echo "  3. Start service: /etc/init.d/sshd start"
    echo "  4. Set password: passwd"
    echo
    
    read -p "Press Enter to continue..."
}

# Function to auto-optimize configuration
auto_optimize() {
    echo -e "${BLUE}🎯 Auto-optimizing configuration for your environment...${NC}"
    
    # Auto-select network mode
    if [[ "$ROOT_AVAILABLE" == "true" ]]; then
        NETWORK_MODE="bridge"
        echo "  ✓ Selected bridge networking (best performance)"
    else
        NETWORK_MODE="user"
        echo "  ✓ Selected user networking with SSH forwarding"
    fi
    
    # Auto-select display type
    if [[ "$WAYLAND_DETECTED" == "true" && "$NVIDIA_DETECTED" == "true" ]]; then
        DISPLAY_TYPE="gtk"
        echo "  ✓ Selected GTK display (best for NVIDIA + Wayland)"
    else
        DISPLAY_TYPE="auto"
        echo "  ✓ Selected auto display detection"
    fi
    
    # Auto-select GPU type
    if [[ "$NVIDIA_DETECTED" == "true" ]]; then
        GPU_TYPE="virtio"
        echo "  ✓ Selected virtio-gpu (best NVIDIA compatibility)"
    else
        GPU_TYPE="virtio"
        echo "  ✓ Selected virtio-gpu (best performance)"
    fi
    
    echo -e "${GREEN}✓ Configuration optimized!${NC}"
    echo
}

# Function to start VM with current configuration
start_vm() {
    echo -e "${GREEN}🚀 Starting Gentoo VM...${NC}"
    echo
    
    # Auto-optimize if not configured
    if [[ -z "$NETWORK_MODE" ]]; then
        auto_optimize
    fi
    
    # Create directories
    mkdir -p "$(dirname "$VM_DISK")"
    mkdir -p "$SHARED_FOLDER"
    
    # Create disk if it doesn't exist
    if [[ ! -f "$VM_DISK" ]]; then
        echo "💾 Creating VM disk: $VM_DISK (${VM_STORAGE})"
        qemu-img create -f qcow2 "$VM_DISK" "$VM_STORAGE"
    else
        echo "💾 Using existing disk: $VM_DISK"
    fi
    
    # Create shared folder README
    if [[ ! -f "$SHARED_FOLDER/README.txt" ]]; then
        cat > "$SHARED_FOLDER/README.txt" << EOF
Gentoo Test VM Shared Folder
============================

This folder is shared between your host system and the Gentoo VM.
Files placed here will be accessible from both systems.

To access this folder from inside the VM:
1. Create mount point: mkdir -p /mnt/shared
2. Mount the shared folder: mount -t virtiofs shared /mnt/shared

The shared folder will be available at /mnt/shared inside the VM.
EOF
    fi
    
    # Show final configuration
    echo
    echo -e "${CYAN}📋 Final Configuration:${NC}"
    echo "  Network Mode: $NETWORK_MODE"
    echo "  Display: $DISPLAY_TYPE"
    echo "  GPU: $GPU_TYPE"
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        echo "  VM IP: $VM_IP"
        echo "  SSH: ssh root@$VM_IP"
    else
        echo "  SSH Port: $SSH_PORT"
        echo "  SSH: ssh -p $SSH_PORT root@localhost"
    fi
    echo
    
    # Build QEMU command
    local qemu_cmd="qemu-system-x86_64"
    qemu_cmd="$qemu_cmd -name \"$VM_NAME\""
    qemu_cmd="$qemu_cmd -m \"$VM_RAM\""
    qemu_cmd="$qemu_cmd -smp \"$VM_CORES\""
    qemu_cmd="$qemu_cmd -cpu host"
    qemu_cmd="$qemu_cmd -enable-kvm"
    qemu_cmd="$qemu_cmd -machine type=q35,accel=kvm"
    qemu_cmd="$qemu_cmd -vga virtio"
    
    # Add display
    if [[ "$DISPLAY_TYPE" == "gtk" ]]; then
        qemu_cmd="$qemu_cmd -display gtk"
    elif [[ "$DISPLAY_TYPE" == "spice" ]]; then
        qemu_cmd="$qemu_cmd -display spice-app"
    elif [[ "$DISPLAY_TYPE" == "sdl" ]]; then
        qemu_cmd="$qemu_cmd -display sdl"
    else
        # Auto-detect based on environment
        if [[ "$WAYLAND_DETECTED" == "true" && "$NVIDIA_DETECTED" == "true" ]]; then
            qemu_cmd="$qemu_cmd -display gtk"
        else
            qemu_cmd="$qemu_cmd -display gtk"
        fi
    fi
    
    # Add storage
    qemu_cmd="$qemu_cmd -drive file=\"$VM_DISK\",if=virtio,cache=writeback,discard=unmap"
    
    # Add network
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        # Create bridge if it doesn't exist
        if ! ip link show "$BRIDGE_NAME" &> /dev/null; then
            echo "🔧 Creating network bridge: $BRIDGE_NAME"
            ip link add "$BRIDGE_NAME" type bridge
            ip link set "$BRIDGE_NAME" up
        fi
        qemu_cmd="$qemu_cmd -netdev bridge,id=net0,br=\"$BRIDGE_NAME\""
        qemu_cmd="$qemu_cmd -device virtio-net-pci,netdev=net0,mac=\"$VM_MAC\""
    else
        qemu_cmd="$qemu_cmd -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.1,dhcpstart=10.0.2.15,hostfwd=tcp::$SSH_PORT-:22"
        qemu_cmd="$qemu_cmd -device virtio-net-pci,netdev=net0"
    fi
    
    # Add shared folder
    qemu_cmd="$qemu_cmd -virtfs local,path=\"$SHARED_FOLDER\",mount_tag=shared,security_model=mapped"
    
    # Add other devices
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
    
    # Add ISO if specified
    if [[ -n "$VM_ISO" ]]; then
        qemu_cmd="$qemu_cmd -cdrom \"$VM_ISO\""
        qemu_cmd="$qemu_cmd -boot d"
    else
        qemu_cmd="$qemu_cmd -boot c"
    fi
    
    echo -e "${GREEN}🚀 Starting VM with optimized configuration...${NC}"
    echo "Press Ctrl+C to stop the VM"
    echo
    
    # Execute QEMU command
    eval $qemu_cmd
    
    echo
    echo -e "${GREEN}✅ VM stopped.${NC}"
    echo "To start again, run: $0"
    if [[ -n "$VM_ISO" ]]; then
        echo "To start with same ISO: $0 --cdrom \"$VM_ISO\""
    fi
    echo "To reset (delete disk), run: rm -f $VM_DISK && $0"
}

# Function to show help
show_help() {
    clear
    echo -e "${BLUE}❓ Help & Troubleshooting${NC}"
    echo "========================="
    echo
    
    echo -e "${CYAN}📚 Quick Start:${NC}"
    echo "  1. Select your ISO file (Menu option 2)"
    echo "  2. Configure network if needed (Menu option 3)"
    echo "  3. Start VM (Menu option 6)"
    echo
    
    echo -e "${CYAN}🔧 Common Issues:${NC}"
    echo "  • Display issues: Try different display options"
    echo "  • Network issues: Check if ports are available"
    echo "  • Performance: Use bridge networking if root available"
    echo "  • NVIDIA + Wayland: GTK display works best"
    echo
    
    echo -e "${CYan}📱 SSH Access:${NC}"
    echo "  • Bridge networking: ssh root@$VM_IP"
    echo "  • User networking: ssh -p $SSH_PORT root@localhost"
    echo "  • Setup SSH in VM: emerge openssh && rc-update add sshd default"
    echo
    
    echo -e "${CYAN}🌐 Network Modes:${NC}"
    echo "  • Bridge: Best performance, requires root, direct IP access"
    echo "  • User: Works without root, port forwarding for SSH"
    echo
    
    read -p "Press Enter to continue..."
}

# Function to reset configuration
reset_config() {
    echo -e "${YELLOW}⚠️  Reset configuration to defaults? [y/N]: ${NC}"
    read -p "" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        NETWORK_MODE=""
        DISPLAY_TYPE=""
        GPU_TYPE=""
        echo -e "${GREEN}✓ Configuration reset to defaults${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to handle command line arguments
handle_cli_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cdrom)
                VM_ISO="$2"
                shift 2
                ;;
            --ram)
                VM_RAM="$2"
                shift 2
                ;;
            --cores)
                VM_CORES="$2"
                shift 2
                ;;
            --storage)
                VM_STORAGE="$2"
                shift 2
                ;;
            --ssh-port)
                SSH_PORT="$2"
                shift 2
                ;;
            --auto-start)
                detect_environment
                auto_optimize
                start_vm
                exit 0
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --cdrom ISO_PATH    Specify ISO file to boot from"
                echo "  --ram SIZE          Set RAM size (e.g., 8G, 16G)"
                echo "  --cores NUM         Set CPU core count"
                echo "  --storage SIZE      Set storage size (e.g., 256G, 512G)"
                echo "  --ssh-port PORT     Set SSH port for user networking"
                echo "  --auto-start        Auto-detect, optimize, and start VM"
                echo "  --help, -h         Show this help message"
                echo
                echo "Examples:"
                echo "  $0 --cdrom gentoo.iso --auto-start"
                echo "  $0 --cdrom gentoo.iso --ram 8G --cores 4"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Handle command line arguments
    handle_cli_args "$@"
    
    # Detect environment
    detect_environment
    
    # Main menu loop
    while true; do
        show_main_menu
        read -p "Choose option [0-9]: " choice
        
        case $choice in
            1) configure_vm_settings ;;
            2) select_iso ;;
            3) configure_network ;;
            4) configure_display ;;
            5) show_ssh_info ;;
            6) start_vm ;;
            7) start_vm ;;
            8) reset_config ;;
            9) show_help ;;
            0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please choose 0-9.${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main "$@"
