#!/bin/bash

# Enhanced VM Launcher - Advanced QEMU Configuration
# Features: CPU, RAM, VRAM, Storage, Networking, Copy-Paste, SSH

set -e

# Configuration
VM_NAME="gentoo-test"
VM_RAM="16G"
VM_CORES="8"
VM_THREADS="2"
VM_SOCKETS="1"
VM_CPU_TYPE="host"
VM_VRAM="64M"
VM_STORAGE="512G"
VM_STORAGE_BUS="virtio"
VM_ISO=""
VM_DISK="$HOME/vm-disks/${VM_NAME}.qcow2"
SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
SSH_PORT="2223"
NETWORK_MODE="user"
NETWORK_TYPE="virtio"
DISPLAY_BACKEND="gtk"
ENABLE_COPY_PASTE="true"
ENABLE_SHARED_FOLDER="true"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to show menu
show_menu() {
    clear
    echo -e "${GREEN}🚀 Enhanced VM Launcher - Advanced Configuration${NC}"
    echo "========================================================"
    echo
    
    echo -e "${CYAN}📋 Current Configuration:${NC}"
    echo "  VM Name: $VM_NAME"
    echo "  CPU: $VM_CPU_TYPE ($VM_SOCKETS socket, $VM_CORES cores, $VM_THREADS threads)"
    echo "  RAM: $VM_RAM"
    echo "  VRAM: $VM_VRAM"
    echo "  Storage: $VM_STORAGE ($VM_STORAGE_BUS)"
    echo "  Network: $NETWORK_MODE ($NETWORK_TYPE)"
    echo "  Display: $DISPLAY_BACKEND"
    echo "  SSH Port: $SSH_PORT"
    echo "  Copy-Paste: $(on_off_label ENABLE_COPY_PASTE)"
    echo "  Shared Folder: $(on_off_label ENABLE_SHARED_FOLDER)"
    echo
    
    echo -e "${CYAN}📋 Configuration Options:${NC}"
    echo "  1) Basic Settings (Name, RAM, Storage)"
    echo "  2) CPU Configuration (Type, Cores, Threads)"
    echo "  3) Graphics (VRAM, Display Backend)"
    echo "  4) Storage (Bus Type, Size)"
    echo "  5) Network (Mode, Type, SSH)"
    echo "  6) Advanced Features (Copy-Paste, Shared Folder)"
    echo "  7) Select ISO File"
    echo "  8) Show Current Configuration"
    echo "  9) Start VM with Current Settings"
    echo "  10) Reset to Defaults"
    echo "  0) Exit"
    echo
    
    echo -e "${YELLOW}💡 This tool provides advanced VM configuration options${NC}"
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

toggle_boolean() {
    local var_name="$1"
    if [[ "${!var_name}" == "true" ]]; then
        eval "$var_name=false"
        echo -e "${RED}✓ $var_name disabled${NC}"
    else
        eval "$var_name=true"
        echo -e "${GREEN}✓ $var_name enabled${NC}"
    fi
}

# Configuration functions
configure_basic_settings() {
    clear
    echo -e "${BLUE}⚙️  Basic VM Configuration${NC}"
    echo "========================="
    echo
    
    read -p "VM Name [$VM_NAME]: " input
    [[ -n "$input" ]] && VM_NAME="$input"
    
    echo "RAM Options: 1G, 2G, 4G, 8G, 16G, 32G, 64G"
    read -p "RAM [$VM_RAM]: " input
    [[ -n "$input" ]] && VM_RAM="$input"
    
    echo "Storage Options: 10G, 20G, 50G, 100G, 200G, 500G, 1T, 2T"
    read -p "Storage [$VM_STORAGE]: " input
    [[ -n "$input" ]] && VM_STORAGE="$input"
    
    VM_DISK="$HOME/vm-disks/${VM_NAME}.qcow2"
    SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
    
    echo -e "${GREEN}✓ Basic settings updated${NC}"
    read -p "Press Enter to continue..."
}

configure_cpu_settings() {
    clear
    echo -e "${BLUE}🖥️  CPU Configuration${NC}"
    echo "====================="
    echo
    
    echo "CPU Type Options: host, qemu64, core2duo, phenom, athlon"
    read -p "CPU Type [$VM_CPU_TYPE]: " input
    [[ -n "$input" ]] && VM_CPU_TYPE="$input"
    
    read -p "CPU Cores [$VM_CORES]: " input
    [[ -n "$input" ]] && VM_CORES="$input"
    
    read -p "CPU Threads per Core [$VM_THREADS]: " input
    [[ -n "$input" ]] && VM_THREADS="$input"
    
    read -p "CPU Sockets [$VM_SOCKETS]: " input
    [[ -n "$input" ]] && VM_SOCKETS="$input"
    
    echo -e "${GREEN}✓ CPU settings updated${NC}"
    read -p "Press Enter to continue..."
}

configure_graphics() {
    clear
    echo -e "${BLUE}🎮 Graphics Configuration${NC}"
    echo "========================="
    echo
    
    echo "VRAM Options: 16M, 32M, 64M, 128M, 256M, 512M, 1G"
    read -p "VRAM [$VM_VRAM]: " input
    [[ -n "$input" ]] && VM_VRAM="$input"
    
    echo "Display Backend Options:"
    echo "  1) GTK (recommended for NVIDIA + Wayland)"
    echo "  2) SDL (performance option)"
    echo "  3) SPICE (advanced)"
    read -p "Choose display backend [1-3]: " choice
    
    case $choice in
        1) DISPLAY_BACKEND="gtk" ;;
        2) DISPLAY_BACKEND="sdl" ;;
        3) DISPLAY_BACKEND="spice-app" ;;
        *) echo "Invalid choice, keeping current: $DISPLAY_BACKEND" ;;
    esac
    
    echo -e "${GREEN}✓ Graphics settings updated${NC}"
    read -p "Press Enter to continue..."
}

configure_storage() {
    clear
    echo -e "${BLUE}💾 Storage Configuration${NC}"
    echo "========================"
    echo
    
    echo "Storage Bus Options:"
    echo "  1) virtio (best performance)"
    echo "  2) sata (good compatibility)"
    echo "  3) ide (best compatibility)"
    echo "  4) nvme (fastest, requires drivers)"
    read -p "Choose storage bus [1-4]: " choice
    
    case $choice in
        1) VM_STORAGE_BUS="virtio" ;;
        2) VM_STORAGE_BUS="sata" ;;
        3) VM_STORAGE_BUS="ide" ;;
        4) VM_STORAGE_BUS="nvme" ;;
        *) echo "Invalid choice, keeping current: $VM_STORAGE_BUS" ;;
    esac
    
    echo "Storage Size Options: 10G, 20G, 50G, 100G, 200G, 500G, 1T, 2T"
    read -p "Storage Size [$VM_STORAGE]: " input
    [[ -n "$input" ]] && VM_STORAGE="$input"
    
    echo -e "${GREEN}✓ Storage settings updated${NC}"
    read -p "Press Enter to continue..."
}

configure_network() {
    clear
    echo -e "${BLUE}🌐 Network Configuration${NC}"
    echo "========================"
    echo
    
    echo "Network Mode Options:"
    echo "  1) User networking with SSH forwarding (no root needed)"
    echo "  2) User networking without SSH (basic)"
    read -p "Choose network mode [1-2]: " choice
    
    case $choice in
        1) NETWORK_MODE="user" ;;
        2) NETWORK_MODE="user-basic" ;;
        *) echo "Invalid choice, keeping current: $NETWORK_MODE" ;;
    esac
    
    echo "Network Device Type:"
    echo "  1) virtio (best performance)"
    echo "  2) e1000 (Intel, good compatibility)"
    echo "  3) rtl8139 (Realtek, basic compatibility)"
    read -p "Choose network type [1-3]: " choice
    
    case $choice in
        1) NETWORK_TYPE="virtio" ;;
        2) NETWORK_TYPE="e1000" ;;
        3) NETWORK_TYPE="rtl8139" ;;
        *) echo "Invalid choice, keeping current: $NETWORK_TYPE" ;;
    esac
    
    read -p "SSH Port [$SSH_PORT]: " input
    [[ -n "$input" ]] && SSH_PORT="$input"
    
    echo -e "${GREEN}✓ Network settings updated${NC}"
    read -p "Press Enter to continue..."
}

configure_advanced_features() {
    clear
    echo -e "${BLUE}⚙️  Advanced Features Configuration${NC}"
    echo "====================================="
    echo
    
    echo -e "${CYAN}Feature Toggles:${NC}"
    echo "  1) Copy-Paste Support: $(on_off_label ENABLE_COPY_PASTE)"
    echo "  2) Shared Folder: $(on_off_label ENABLE_SHARED_FOLDER)"
    echo "  3) Back to main menu"
    echo
    
    read -p "Choose option to toggle [1-3]: " choice
    
    case $choice in
        1) toggle_boolean ENABLE_COPY_PASTE ;;
        2) toggle_boolean ENABLE_SHARED_FOLDER ;;
        3) return ;;
        *) echo "Invalid option" ;;
    esac
    
    read -p "Press Enter to continue..."
}

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

show_configuration() {
    clear
    echo -e "${BLUE}📋 Current VM Configuration${NC}"
    echo "==============================="
    echo
    
    echo -e "${CYAN}Basic Settings:${NC}"
    echo "  VM Name: $VM_NAME"
    echo "  RAM: $VM_RAM"
    echo "  Storage: $VM_STORAGE"
    echo "  ISO: ${VM_ISO:-"Not specified"}"
    echo
    
    echo -e "${CYan}CPU Configuration:${NC}"
    echo "  CPU Type: $VM_CPU_TYPE"
    echo "  Sockets: $VM_SOCKETS"
    echo "  Cores: $VM_CORES"
    echo "  Threads: $VM_THREADS"
    echo
    
    echo -e "${CYan}Graphics Configuration:${NC}"
    echo "  VRAM: $VM_VRAM"
    echo "  Display Backend: $DISPLAY_BACKEND"
    echo
    
    echo -e "${CYan}Storage Configuration:${NC}"
    echo "  Storage Bus: $VM_STORAGE_BUS"
    echo
    
    echo -e "${CYan}Network Configuration:${NC}"
    echo "  Network Mode: $NETWORK_MODE"
    echo "  Network Type: $NETWORK_TYPE"
    echo "  SSH Port: $SSH_PORT"
    echo
    
    echo -e "${CYan}Advanced Features:${NC}"
    echo "  Copy-Paste: $(on_off_label ENABLE_COPY_PASTE)"
    echo "  Shared Folder: $(on_off_label ENABLE_SHARED_FOLDER)"
    echo
    
    read -p "Press Enter to continue..."
}

start_vm() {
    if [[ -z "$VM_ISO" ]]; then
        echo -e "${YELLOW}⚠️  No ISO file selected. Please select an ISO first.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${GREEN}🚀 Starting VM with enhanced configuration...${NC}"
    echo
    
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
    
    # Show final configuration
    echo
    echo -e "${CYan}📋 Final Configuration Summary:${NC}"
    echo "  VM Name: $VM_NAME"
    echo "  CPU: $VM_CPU_TYPE ($VM_SOCKETS socket, $VM_CORES cores, $VM_THREADS threads)"
    echo "  RAM: $VM_RAM"
    echo "  VRAM: $VM_VRAM"
    echo "  Storage: $VM_STORAGE ($VM_STORAGE_BUS)"
    echo "  Network: $NETWORK_MODE ($NETWORK_TYPE)"
    echo "  Display: $DISPLAY_BACKEND"
    echo "  SSH Port: $SSH_PORT"
    echo "  Copy-Paste: $(on_off_label ENABLE_COPY_PASTE)"
    echo "  Shared Folder: $(on_off_label ENABLE_SHARED_FOLDER)"
    echo
    
    # Build QEMU command
    local qemu_cmd="qemu-system-x86_64"
    qemu_cmd="$qemu_cmd -name \"$VM_NAME\""
    qemu_cmd="$qemu_cmd -m \"$VM_RAM\""
    qemu_cmd="$qemu_cmd -smp $VM_CORES,sockets=$VM_SOCKETS,cores=$VM_CORES,threads=$VM_THREADS"
    qemu_cmd="$qemu_cmd -enable-kvm"
    qemu_cmd="$qemu_cmd -cpu \"$VM_CPU_TYPE\""
    qemu_cmd="$qemu_cmd -machine type=q35,accel=kvm"
    qemu_cmd="$qemu_cmd -vga virtio"
    qemu_cmd="$qemu_cmd -display \"$DISPLAY_BACKEND\""
    
    # Storage
    qemu_cmd="$qemu_cmd -drive file=\"$VM_DISK\",if=$VM_STORAGE_BUS,cache=writeback,discard=unmap"
    
    # Network
    if [[ "$NETWORK_MODE" == "user" ]]; then
        qemu_cmd="$qemu_cmd -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.1,dhcpstart=10.0.2.15,hostfwd=tcp::$SSH_PORT-:22"
    else
        qemu_cmd="$qemu_cmd -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.1,dhcpstart=10.0.2.15"
    fi
    qemu_cmd="$qemu_cmd -device ${NETWORK_TYPE}-pci,netdev=net0"
    
    # Advanced features
    if [[ "$ENABLE_SHARED_FOLDER" == "true" ]]; then
        qemu_cmd="$qemu_cmd -virtfs local,path=\"$SHARED_FOLDER\",mount_tag=shared,security_model=mapped"
    fi
    
    if [[ "$ENABLE_COPY_PASTE" == "true" ]]; then
        qemu_cmd="$qemu_cmd -device virtio-serial-pci"
        qemu_cmd="$qemu_cmd -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"
        qemu_cmd="$qemu_cmd -chardev spicevmc,id=spicechannel0,name=vdagent"
    fi
    
    # Other devices
    qemu_cmd="$qemu_cmd -device virtio-balloon"
    qemu_cmd="$qemu_cmd -device virtio-rng-pci"
    qemu_cmd="$qemu_cmd -usb"
    qemu_cmd="$qemu_cmd -device usb-tablet"
    qemu_cmd="$qemu_cmd -device intel-hda"
    qemu_cmd="$qemu_cmd -device hda-duplex"
    qemu_cmd="$qemu_cmd -rtc base=utc"
    qemu_cmd="$qemu_cmd -no-reboot"
    qemu_cmd="$qemu_cmd -no-shutdown"
    
    # ISO
    qemu_cmd="$qemu_cmd -cdrom \"$VM_ISO\""
    qemu_cmd="$qemu_cmd -boot d"
    
    echo -e "${GREEN}🚀 Starting VM with enhanced configuration...${NC}"
    echo "Press Ctrl+C to stop the VM"
    echo
    
    # Execute QEMU command
    eval $qemu_cmd
    
    echo
    echo -e "${GREEN}✅ VM stopped.${NC}"
    echo "To start again, run: $0"
    echo "To reset (delete disk), run: rm -f $VM_DISK && $0"
}

reset_configuration() {
    echo -e "${YELLOW}⚠️  Reset configuration to defaults? [y/N]: ${NC}"
    read -p "" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        VM_NAME="gentoo-test"
        VM_RAM="16G"
        VM_CORES="8"
        VM_THREADS="2"
        VM_SOCKETS="1"
        VM_CPU_TYPE="host"
        VM_VRAM="64M"
        VM_STORAGE="512G"
        VM_STORAGE_BUS="virtio"
        SSH_PORT="2223"
        NETWORK_MODE="user"
        NETWORK_TYPE="virtio"
        DISPLAY_BACKEND="gtk"
        ENABLE_COPY_PASTE="true"
        ENABLE_SHARED_FOLDER="true"
        
        VM_DISK="$HOME/vm-disks/${VM_NAME}.qcow2"
        SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
        
        echo -e "${GREEN}✓ Configuration reset to defaults${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Main function
main() {
    # Check QEMU installation
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        echo -e "${RED}❌ QEMU not found. Please install qemu-system-x86_64${NC}"
        exit 1
    fi
    
    # Main menu loop
    while true; do
        show_menu
        read -p "Choose option [0-10]: " choice
        
        case $choice in
            1) configure_basic_settings ;;
            2) configure_cpu_settings ;;
            3) configure_graphics ;;
            4) configure_storage ;;
            5) configure_network ;;
            6) configure_advanced_features ;;
            7) select_iso ;;
            8) show_configuration ;;
            9) start_vm ;;
            10) reset_configuration ;;
            0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please choose 0-10.${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main "$@"

