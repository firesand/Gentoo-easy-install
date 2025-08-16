#!/bin/bash

# Advanced VM Configurator - Comprehensive QEMU Configuration Tool
# Features: CPU, RAM, VRAM, Storage, Networking, Copy-Paste, SSH, and more

set -e

# Configuration Variables
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
BRIDGE_NAME="br0"
VM_IP="192.168.100.100"
VM_MAC="52:54:00:12:34:56"

# Advanced Features
ENABLE_COPY_PASTE="true"
ENABLE_SHARED_FOLDER="true"
ENABLE_SPICE="false"
ENABLE_VIRTIO="true"
ENABLE_KVM="true"
ENABLE_HUGE_PAGES="false"
ENABLE_BALLOON="true"
ENABLE_RNG="true"
ENABLE_USB="true"
ENABLE_AUDIO="true"

# Display Configuration
DISPLAY_BACKEND="gtk"
DISPLAY_ACCELERATION="false"

# Network Configuration
NETWORK_MODE="user"
NETWORK_TYPE="virtio"

# Auto-detected settings
WAYLAND_DETECTED=""
NVIDIA_DETECTED=""
ROOT_AVAILABLE=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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
        ENABLE_KVM="false"
    fi
    
    echo
}

# Function to show main menu
show_main_menu() {
    clear
    echo -e "${GREEN}🚀 Advanced VM Configurator - Comprehensive QEMU Tool${NC}"
    echo "================================================================"
    echo
    
    # Show current configuration
    echo -e "${CYAN}📋 Current Configuration:${NC}"
    echo "  VM Name: $VM_NAME"
    echo "  CPU: $VM_CPU_TYPE ($VM_SOCKETS socket, $VM_CORES cores, $VM_THREADS threads)"
    echo "  RAM: $VM_RAM"
    echo "  VRAM: $VM_VRAM"
    echo "  Storage: $VM_STORAGE ($VM_STORAGE_BUS)"
    echo "  ISO: ${VM_ISO:-"Not specified"}"
    echo "  Network: $NETWORK_MODE ($NETWORK_TYPE)"
    echo "  Display: $DISPLAY_BACKEND"
    echo "  SSH Port: $SSH_PORT"
    echo
    
    # Show advanced features
    echo -e "${CYAN}⚙️  Advanced Features:${NC}"
    echo "  Copy-Paste: $(on_off_label ENABLE_COPY_PASTE)"
    echo "  Shared Folder: $(on_off_label ENABLE_SHARED_FOLDER)"
    echo "  SPICE: $(on_off_label ENABLE_SPICE)"
    echo "  Virtio: $(on_off_label ENABLE_VIRTIO)"
    echo "  KVM: $(on_off_label ENABLE_KVM)"
    echo "  Huge Pages: $(on_off_label ENABLE_HUGE_PAGES)"
    echo "  Balloon: $(on_off_label ENABLE_BALLOON)"
    echo "  RNG: $(on_off_label ENABLE_RNG)"
    echo "  USB: $(on_off_label ENABLE_USB)"
    echo "  Audio: $(on_off_label ENABLE_AUDIO)"
    echo
    
    # Show menu options
    echo -e "${CYAN}📋 Configuration Options:${NC}"
    echo "  1) Basic VM Settings (Name, RAM, Storage)"
    echo "  2) CPU Configuration (Type, Cores, Threads, Sockets)"
    echo "  3) Graphics Configuration (VRAM, Display Backend)"
    echo "  4) Storage Configuration (Bus Type, Size, Options)"
    echo "  5) Network Configuration (Mode, Type, SSH)"
    echo "  6) Advanced Features (Copy-Paste, Shared Folder, etc.)"
    echo "  7) Display & Graphics Options"
    echo "  8) Performance Tuning (KVM, Huge Pages, etc.)"
    echo "  9) Select ISO File"
    echo "  10) Show Current Configuration"
    echo "  11) Export Configuration"
    echo "  12) Import Configuration"
    echo "  13) Start VM with Current Settings"
    echo "  14) Reset to Defaults"
    echo "  15) Help & Documentation"
    echo "  0) Exit"
    echo
    
    echo -e "${YELLOW}💡 Use this tool to create highly customized VM configurations${NC}"
    echo
}

# Helper function for on/off labels
on_off_label() {
    local var_name="$1"
    if [[ "${!var_name}" == "true" ]]; then
        echo -e "${GREEN}ON${NC}"
    else
        echo -e "${RED}OFF${NC}"
    fi
}

# Function to toggle boolean values
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

# Function to configure basic VM settings
configure_basic_settings() {
    clear
    echo -e "${BLUE}⚙️  Basic VM Configuration${NC}"
    echo "========================="
    echo
    
    # VM Name
    read -p "VM Name [$VM_NAME]: " input
    [[ -n "$input" ]] && VM_NAME="$input"
    
    # RAM
    echo "RAM Options: 1G, 2G, 4G, 8G, 16G, 32G, 64G"
    read -p "RAM [$VM_RAM]: " input
    [[ -n "$input" ]] && VM_RAM="$input"
    
    # Storage
    echo "Storage Options: 10G, 20G, 50G, 100G, 200G, 500G, 1T, 2T"
    read -p "Storage [$VM_STORAGE]: " input
    [[ -n "$input" ]] && VM_STORAGE="$input"
    
    # Update paths
    VM_DISK="$HOME/vm-disks/${VM_NAME}.qcow2"
    SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
    
    echo -e "${GREEN}✓ Basic settings updated${NC}"
    read -p "Press Enter to continue..."
}

# Function to configure CPU settings
configure_cpu_settings() {
    clear
    echo -e "${BLUE}🖥️  CPU Configuration${NC}"
    echo "====================="
    echo
    
    # CPU Type
    echo "CPU Type Options:"
    echo "  host - Use host CPU (best performance)"
    echo "  qemu64 - Generic 64-bit CPU"
    echo "  core2duo - Intel Core 2 Duo"
    echo "  phenom - AMD Phenom"
    echo "  athlon - AMD Athlon"
    echo "  pentium3 - Intel Pentium III"
    read -p "CPU Type [$VM_CPU_TYPE]: " input
    [[ -n "$input" ]] && VM_CPU_TYPE="$input"
    
    # CPU Cores
    read -p "CPU Cores [$VM_CORES]: " input
    [[ -n "$input" ]] && VM_CORES="$input"
    
    # CPU Threads
    read -p "CPU Threads per Core [$VM_THREADS]: " input
    [[ -n "$input" ]] && VM_THREADS="$input"
    
    # CPU Sockets
    read -p "CPU Sockets [$VM_SOCKETS]: " input
    [[ -n "$input" ]] && VM_SOCKETS="$input"
    
    echo -e "${GREEN}✓ CPU settings updated${NC}"
    read -p "Press Enter to continue..."
}

# Function to configure graphics
configure_graphics() {
    clear
    echo -e "${BLUE}🎮 Graphics Configuration${NC}"
    echo "========================="
    echo
    
    # VRAM
    echo "VRAM Options: 16M, 32M, 64M, 128M, 256M, 512M, 1G"
    read -p "VRAM [$VM_VRAM]: " input
    [[ -n "$input" ]] && VM_VRAM="$input"
    
    # Display Backend
    echo "Display Backend Options:"
    echo "  1) GTK (recommended for NVIDIA + Wayland)"
    echo "  2) SDL (performance option)"
    echo "  3) SPICE (advanced)"
    echo "  4) X11 (legacy)"
    echo "  5) Wayland (experimental)"
    read -p "Choose display backend [1-5]: " choice
    
    case $choice in
        1) DISPLAY_BACKEND="gtk" ;;
        2) DISPLAY_BACKEND="sdl" ;;
        3) DISPLAY_BACKEND="spice-app" ;;
        4) DISPLAY_BACKEND="x11" ;;
        5) DISPLAY_BACKEND="wayland" ;;
        *) echo "Invalid choice, keeping current: $DISPLAY_BACKEND" ;;
    esac
    
    # Display Acceleration
    echo -e "${YELLOW}⚠️  Display acceleration may cause issues with NVIDIA + Wayland${NC}"
    read -p "Enable display acceleration? [y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        DISPLAY_ACCELERATION="true"
    else
        DISPLAY_ACCELERATION="false"
    fi
    
    echo -e "${GREEN}✓ Graphics settings updated${NC}"
    read -p "Press Enter to continue..."
}

# Function to configure storage
configure_storage() {
    clear
    echo -e "${BLUE}💾 Storage Configuration${NC}"
    echo "========================"
    echo
    
    # Storage Bus Type
    echo "Storage Bus Options:"
    echo "  1) virtio (best performance, requires virtio drivers)"
    echo "  2) sata (good performance, widely compatible)"
    echo "  3) ide (best compatibility, slower performance)"
    echo "  4) scsi (enterprise, requires drivers)"
    echo "  5) nvme (fastest, requires drivers)"
    read -p "Choose storage bus [1-5]: " choice
    
    case $choice in
        1) VM_STORAGE_BUS="virtio" ;;
        2) VM_STORAGE_BUS="sata" ;;
        3) VM_STORAGE_BUS="ide" ;;
        4) VM_STORAGE_BUS="scsi" ;;
        5) VM_STORAGE_BUS="nvme" ;;
        *) echo "Invalid choice, keeping current: $VM_STORAGE_BUS" ;;
    esac
    
    # Storage Size
    echo "Storage Size Options: 10G, 20G, 50G, 100G, 200G, 500G, 1T, 2T"
    read -p "Storage Size [$VM_STORAGE]: " input
    [[ -n "$input" ]] && VM_STORAGE="$input"
    
    # Storage Options
    echo -e "${CYAN}Storage Options:${NC}"
    read -p "Enable writeback cache? [Y/n]: " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        STORAGE_CACHE="off"
    else
        STORAGE_CACHE="writeback"
    fi
    
    read -p "Enable discard support? [Y/n]: " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        STORAGE_DISCARD="false"
    else
        STORAGE_DISCARD="true"
    fi
    
    echo -e "${GREEN}✓ Storage settings updated${NC}"
    read -p "Press Enter to continue..."
}

# Function to configure network
configure_network() {
    clear
    echo -e "${BLUE}🌐 Network Configuration${NC}"
    echo "========================"
    echo
    
    # Network Mode
    echo "Network Mode Options:"
    if [[ "$ROOT_AVAILABLE" == "true" ]]; then
        echo "  1) Bridge networking (best performance, requires root)"
        echo "  2) User networking with SSH forwarding (no root needed)"
        echo "  3) TAP networking (advanced, requires root)"
        echo "  4) Macvtap networking (advanced, requires root)"
    else
        echo "  1) User networking with SSH forwarding (only option)"
        echo "  2) User networking without SSH (basic)"
    fi
    read -p "Choose network mode: " choice
    
    case $choice in
        1)
            if [[ "$ROOT_AVAILABLE" == "true" ]]; then
                NETWORK_MODE="bridge"
                read -p "Bridge name [$BRIDGE_NAME]: " input
                [[ -n "$input" ]] && BRIDGE_NAME="$input"
                read -p "VM IP [$VM_IP]: " input
                [[ -n "$input" ]] && VM_IP="$input"
            else
                NETWORK_MODE="user"
                echo "Bridge networking requires root, using user networking instead"
            fi
            ;;
        2)
            NETWORK_MODE="user"
            read -p "SSH port [$SSH_PORT]: " input
            [[ -n "$input" ]] && SSH_PORT="$input"
            ;;
        3)
            if [[ "$ROOT_AVAILABLE" == "true" ]]; then
                NETWORK_MODE="tap"
                echo "TAP networking selected"
            else
                echo "TAP networking requires root, using user networking instead"
                NETWORK_MODE="user"
            fi
            ;;
        4)
            if [[ "$ROOT_AVAILABLE" == "true" ]]; then
                NETWORK_MODE="macvtap"
                echo "Macvtap networking selected"
            else
                echo "Macvtap networking requires root, using user networking instead"
                NETWORK_MODE="user"
            fi
            ;;
        *)
            echo "Invalid choice, keeping current: $NETWORK_MODE"
            ;;
    esac
    
    # Network Type
    echo "Network Device Type:"
    echo "  1) virtio (best performance, requires drivers)"
    echo "  2) e1000 (Intel, good compatibility)"
    echo "  3) rtl8139 (Realtek, basic compatibility)"
    read -p "Choose network type [1-3]: " choice
    
    case $choice in
        1) NETWORK_TYPE="virtio" ;;
        2) NETWORK_TYPE="e1000" ;;
        3) NETWORK_TYPE="rtl8139" ;;
        *) echo "Invalid choice, keeping current: $NETWORK_TYPE" ;;
    esac
    
    echo -e "${GREEN}✓ Network settings updated${NC}"
    read -p "Press Enter to continue..."
}

# Function to configure advanced features
configure_advanced_features() {
    clear
    echo -e "${BLUE}⚙️  Advanced Features Configuration${NC}"
    echo "====================================="
    echo
    
    echo -e "${CYAN}Feature Toggles:${NC}"
    echo "  1) Copy-Paste Support: $(on_off_label ENABLE_COPY_PASTE)"
    echo "  2) Shared Folder: $(on_off_label ENABLE_SHARED_FOLDER)"
    echo "  3) SPICE Support: $(on_off_label ENABLE_SPICE)"
    echo "  4) Virtio Devices: $(on_off_label ENABLE_VIRTIO)"
    echo "  5) KVM Acceleration: $(on_off_label ENABLE_KVM)"
    echo "  6) Huge Pages: $(on_off_label ENABLE_HUGE_PAGES)"
    echo "  7) Memory Balloon: $(on_off_label ENABLE_BALLOON)"
    echo "  8) Random Number Generator: $(on_off_label ENABLE_RNG)"
    echo "  9) USB Support: $(on_off_label ENABLE_USB)"
    echo "  10) Audio Support: $(on_off_label ENABLE_AUDIO)"
    echo "  11) Back to main menu"
    echo
    
    read -p "Choose option to toggle [1-11]: " choice
    
    case $choice in
        1) toggle_boolean ENABLE_COPY_PASTE ;;
        2) toggle_boolean ENABLE_SHARED_FOLDER ;;
        3) toggle_boolean ENABLE_SPICE ;;
        4) toggle_boolean ENABLE_VIRTIO ;;
        5) toggle_boolean ENABLE_KVM ;;
        6) toggle_boolean ENABLE_HUGE_PAGES ;;
        7) toggle_boolean ENABLE_BALLOON ;;
        8) toggle_boolean ENABLE_RNG ;;
        9) toggle_boolean ENABLE_USB ;;
        10) toggle_boolean ENABLE_AUDIO ;;
        11) return ;;
        *) echo "Invalid option" ;;
    esac
    
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

# Function to show current configuration
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
    
    echo -e "${CYAN}CPU Configuration:${NC}"
    echo "  CPU Type: $VM_CPU_TYPE"
    echo "  Sockets: $VM_SOCKETS"
    echo "  Cores: $VM_CORES"
    echo "  Threads: $VM_THREADS"
    echo
    
    echo -e "${CYAN}Graphics Configuration:${NC}"
    echo "  VRAM: $VM_VRAM"
    echo "  Display Backend: $DISPLAY_BACKEND"
    echo "  Display Acceleration: $(on_off_label DISPLAY_ACCELERATION)"
    echo
    
    echo -e "${CYAN}Storage Configuration:${NC}"
    echo "  Storage Bus: $VM_STORAGE_BUS"
    echo "  Cache: ${STORAGE_CACHE:-"writeback"}"
    echo "  Discard: $(on_off_label STORAGE_DISCARD)"
    echo
    
    echo -e "${CYAN}Network Configuration:${NC}"
    echo "  Network Mode: $NETWORK_MODE"
    echo "  Network Type: $NETWORK_TYPE"
    echo "  SSH Port: $SSH_PORT"
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        echo "  Bridge: $BRIDGE_NAME"
        echo "  VM IP: $VM_IP"
    fi
    echo
    
    echo -e "${CYan}Advanced Features:${NC}"
    echo "  Copy-Paste: $(on_off_label ENABLE_COPY_PASTE)"
    echo "  Shared Folder: $(on_off_label ENABLE_SHARED_FOLDER)"
    echo "  SPICE: $(on_off_label ENABLE_SPICE)"
    echo "  Virtio: $(on_off_label ENABLE_VIRTIO)"
    echo "  KVM: $(on_off_label ENABLE_KVM)"
    echo "  Huge Pages: $(on_off_label ENABLE_HUGE_PAGES)"
    echo "  Balloon: $(on_off_label ENABLE_BALLOON)"
    echo "  RNG: $(on_off_label ENABLE_RNG)"
    echo "  USB: $(on_off_label ENABLE_USB)"
    echo "  Audio: $(on_off_label ENABLE_AUDIO)"
    echo
    
    echo -e "${CYan}Generated QEMU Command:${NC}"
    echo "  $(generate_qemu_command | head -c 80)..."
    echo
    
    read -p "Press Enter to continue..."
}

# Function to generate QEMU command
generate_qemu_command() {
    local cmd="qemu-system-x86_64"
    cmd="$cmd -name \"$VM_NAME\""
    cmd="$cmd -m \"$VM_RAM\""
    cmd="$cmd -smp $VM_CORES,sockets=$VM_SOCKETS,cores=$VM_CORES,threads=$VM_THREADS"
    
    if [[ "$ENABLE_KVM" == "true" ]]; then
        cmd="$cmd -enable-kvm"
    fi
    
    cmd="$cmd -cpu \"$VM_CPU_TYPE\""
    cmd="$cmd -machine type=q35,accel=kvm"
    
    # Graphics
    cmd="$cmd -vga virtio"
    cmd="$cmd -display \"$DISPLAY_BACKEND\""
    
    # Storage
    local cache="${STORAGE_CACHE:-writeback}"
    local discard=""
    [[ "$STORAGE_DISCARD" == "true" ]] && discard=",discard=unmap"
    cmd="$cmd -drive file=\"$VM_DISK\",if=$VM_STORAGE_BUS,cache=$cache$discard"
    
    # Network
    case "$NETWORK_MODE" in
        "bridge")
            cmd="$cmd -netdev bridge,id=net0,br=\"$BRIDGE_NAME\""
            cmd="$cmd -device ${NETWORK_TYPE}-pci,netdev=net0,mac=\"$VM_MAC\""
            ;;
        "user")
            cmd="$cmd -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.1,dhcpstart=10.0.2.15,hostfwd=tcp::$SSH_PORT-:22"
            cmd="$cmd -device ${NETWORK_TYPE}-pci,netdev=net0"
            ;;
        *)
            cmd="$cmd -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.1,dhcpstart=10.0.2.15"
            cmd="$cmd -device ${NETWORK_TYPE}-pci,netdev=net0"
            ;;
    esac
    
    # Advanced features
    [[ "$ENABLE_SHARED_FOLDER" == "true" ]] && cmd="$cmd -virtfs local,path=\"$SHARED_FOLDER\",mount_tag=shared,security_model=mapped"
    [[ "$ENABLE_COPY_PASTE" == "true" ]] && cmd="$cmd -device virtio-serial-pci -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent"
    [[ "$ENABLE_BALLOON" == "true" ]] && cmd="$cmd -device virtio-balloon"
    [[ "$ENABLE_RNG" == "true" ]] && cmd="$cmd -device virtio-rng-pci"
    [[ "$ENABLE_USB" == "true" ]] && cmd="$cmd -usb -device usb-tablet"
    [[ "$ENABLE_AUDIO" == "true" ]] && cmd="$cmd -device intel-hda -device hda-duplex"
    
    # ISO
    [[ -n "$VM_ISO" ]] && cmd="$cmd -cdrom \"$VM_ISO\" -boot d"
    
    echo "$cmd"
}

# Function to start VM
start_vm() {
    if [[ -z "$VM_ISO" ]]; then
        echo -e "${YELLOW}⚠️  No ISO file selected. Please select an ISO first.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${GREEN}🚀 Starting VM with advanced configuration...${NC}"
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
    echo -e "${CYAN}📋 Final Configuration Summary:${NC}"
    echo "  VM Name: $VM_NAME"
    echo "  CPU: $VM_CPU_TYPE ($VM_SOCKETS socket, $VM_CORES cores, $VM_THREADS threads)"
    echo "  RAM: $VM_RAM"
    echo "  VRAM: $VM_VRAM"
    echo "  Storage: $VM_STORAGE ($VM_STORAGE_BUS)"
    echo "  Network: $NETWORK_MODE ($NETWORK_TYPE)"
    echo "  Display: $DISPLAY_BACKEND"
    echo "  SSH Port: $SSH_PORT"
    echo
    
    # Generate and execute QEMU command
    local qemu_cmd=$(generate_qemu_command)
    echo -e "${GREEN}🚀 Starting VM with generated configuration...${NC}"
    echo "Press Ctrl+C to stop the VM"
    echo
    
    eval $qemu_cmd
    
    echo
    echo -e "${GREEN}✅ VM stopped.${NC}"
    echo "To start again, run: $0"
    echo "To reset (delete disk), run: rm -f $VM_DISK && $0"
}

# Function to reset configuration
reset_configuration() {
    echo -e "${YELLOW}⚠️  Reset configuration to defaults? [y/N]: ${NC}"
    read -p "" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Reset to defaults
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
        BRIDGE_NAME="br0"
        VM_IP="192.168.100.100"
        NETWORK_MODE="user"
        NETWORK_TYPE="virtio"
        DISPLAY_BACKEND="gtk"
        DISPLAY_ACCELERATION="false"
        ENABLE_COPY_PASTE="true"
        ENABLE_SHARED_FOLDER="true"
        ENABLE_SPICE="false"
        ENABLE_VIRTIO="true"
        ENABLE_KVM="true"
        ENABLE_HUGE_PAGES="false"
        ENABLE_BALLOON="true"
        ENABLE_RNG="true"
        ENABLE_USB="true"
        ENABLE_AUDIO="true"
        
        # Update paths
        VM_DISK="$HOME/vm-disks/${VM_NAME}.qcow2"
        SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
        
        echo -e "${GREEN}✓ Configuration reset to defaults${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to show help
show_help() {
    clear
    echo -e "${BLUE}❓ Advanced VM Configurator Help${NC}"
    echo "====================================="
    echo
    
    echo -e "${CYAN}📚 What This Tool Does:${NC}"
    echo "  • Creates highly customized QEMU VM configurations"
    echo "  • Optimizes for your specific hardware and needs"
    echo "  • Provides advanced features like copy-paste, shared folders"
    echo "  • Supports multiple storage and network configurations"
    echo
    
    echo -e "${CYan}🎯 Key Features:${NC}"
    echo "  • CPU: Type, cores, threads, sockets"
    echo "  • Memory: RAM size, huge pages, ballooning"
    echo "  • Graphics: VRAM, display backend, acceleration"
    echo "  • Storage: Bus type, size, caching options"
    echo "  • Network: Mode, device type, SSH forwarding"
    echo "  • Advanced: Copy-paste, shared folders, SPICE"
    echo
    
    echo -e "${CYan}🚀 Quick Start:${NC}"
    echo "  1. Configure basic settings (option 1)"
    echo "  2. Select ISO file (option 9)"
    echo "  3. Start VM (option 13)"
    echo
    
    echo -e "${CYan}🔧 Advanced Usage:${NC}"
    echo "  • Use CPU configuration for performance tuning"
    echo "  • Use storage options for different use cases"
    echo "  • Use network options for different scenarios"
    echo "  • Enable/disable features as needed"
    echo
    
    read -p "Press Enter to continue..."
}

# Main function
main() {
    # Check QEMU installation
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        echo -e "${RED}❌ QEMU not found. Please install qemu-system-x86_64${NC}"
        exit 1
    fi
    
    # Detect environment
    detect_environment
    
    # Main menu loop
    while true; do
        show_main_menu
        read -p "Choose option [0-15]: " choice
        
        case $choice in
            1) configure_basic_settings ;;
            2) configure_cpu_settings ;;
            3) configure_graphics ;;
            4) configure_storage ;;
            5) configure_network ;;
            6) configure_advanced_features ;;
            7) configure_graphics ;;
            8) configure_advanced_features ;;
            9) select_iso ;;
            10) show_configuration ;;
            11) echo "Export feature coming soon..." ; read -p "Press Enter to continue..." ;;
            12) echo "Import feature coming soon..." ; read -p "Press Enter to continue..." ;;
            13) start_vm ;;
            14) reset_configuration ;;
            15) show_help ;;
            0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please choose 0-15.${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main "$@"

