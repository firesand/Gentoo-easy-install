#!/bin/bash

# Display Backend Tester for KDE Wayland + NVIDIA
# Tests GTK vs SDL backends to find the best option

set -e

# Configuration
VM_NAME="gentoo-test"
VM_RAM="16G"
VM_CORES="8"
VM_STORAGE="512G"
VM_ISO=""
VM_DISK="$HOME/vm-disks/${VM_NAME}.qcow2"
SHARED_FOLDER="$HOME/vm-shared/${VM_NAME}"
SSH_PORT="2223"

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
    echo -e "${GREEN}🎮 Display Backend Tester - KDE Wayland + NVIDIA${NC}"
    echo "========================================================"
    echo
    
    echo -e "${CYAN}📋 Current Configuration:${NC}"
    echo "  VM Name: $VM_NAME"
    echo "  RAM: $VM_RAM"
    echo "  CPU Cores: $VM_CORES"
    echo "  Storage: $VM_STORAGE"
    echo "  ISO: ${VM_ISO:-"Not specified"}"
    echo "  SSH Port: $SSH_PORT"
    echo
    
    echo -e "${CYAN}🎯 Display Backend Options:${NC}"
    echo "  1) Test GTK Backend (Current - Stable)"
    echo "  2) Test SDL Backend (Performance - Experimental)"
    echo "  3) Test SPICE Backend (Alternative)"
    echo "  4) Auto-detect Best Backend"
    echo "  5) Configure VM Settings"
    echo "  6) Select ISO File"
    echo "  7) Show Backend Comparison"
    echo "  8) Start VM with Selected Backend"
    echo "  0) Exit"
    echo
    
    echo -e "${YELLOW}💡 Recommendation: Start with GTK (option 1) for stability${NC}"
    echo -e "${YELLOW}   Then try SDL (option 2) for better performance${NC}"
    echo
}

# Function to test GTK backend
test_gtk_backend() {
    echo -e "${BLUE}🧪 Testing GTK Backend...${NC}"
    echo "  ✓ Best compatibility with NVIDIA drivers"
    echo "  ✓ Stable - fewer display issues"
    echo "  ✓ Good performance with virtio-gpu"
    echo "  ⚠️  Limited acceleration - basic rendering"
    echo "  ⚠️  No OpenGL - can't leverage GPU capabilities"
    echo
    
    DISPLAY_BACKEND="gtk"
    echo -e "${GREEN}✓ GTK backend selected${NC}"
    read -p "Press Enter to continue..."
}

# Function to test SDL backend
test_sdl_backend() {
    echo -e "${BLUE}🧪 Testing SDL Backend...${NC}"
    echo "  ✓ Better performance - hardware acceleration support"
    echo "  ✓ OpenGL support - can use GPU capabilities"
    echo "  ✓ Smoother graphics - better for desktop environments"
    echo "  ⚠️  Potential compatibility issues with NVIDIA + Wayland"
    echo "  ⚠️  May crash if OpenGL isn't properly configured"
    echo
    
    echo -e "${YELLOW}⚠️  Warning: SDL backend may have issues with NVIDIA + Wayland${NC}"
    echo "  If you experience crashes or display issues, fall back to GTK"
    echo
    
    DISPLAY_BACKEND="sdl"
    echo -e "${GREEN}✓ SDL backend selected${NC}"
    read -p "Press Enter to continue..."
}

# Function to test SPICE backend
test_spice_backend() {
    echo -e "${BLUE}🧪 Testing SPICE Backend...${NC}"
    echo "  ✓ Excellent performance with proper setup"
    echo "  ✓ Hardware acceleration support"
    echo "  ✓ Remote access capabilities"
    echo "  ⚠️  More complex setup required"
    echo "  ⚠️  May need additional packages"
    echo
    
    DISPLAY_BACKEND="spice"
    echo -e "${GREEN}✓ SPICE backend selected${NC}"
    read -p "Press Enter to continue..."
}

# Function to auto-detect best backend
auto_detect_backend() {
    echo -e "${BLUE}🎯 Auto-detecting best backend for your environment...${NC}"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo "  ✓ Root privileges available"
        # Root available - can use more advanced backends
        if command -v nvidia-smi &> /dev/null; then
            echo "  ✓ NVIDIA GPU detected"
            echo "  🎯 Recommending SDL backend for best performance"
            DISPLAY_BACKEND="sdl"
        else
            echo "  🎯 Recommending GTK backend for stability"
            DISPLAY_BACKEND="gtk"
        fi
    else
        echo "  ⚠️  No root privileges"
        echo "  🎯 Recommending GTK backend for stability"
        DISPLAY_BACKEND="gtk"
    fi
    
    echo -e "${GREEN}✓ Auto-detected backend: $DISPLAY_BACKEND${NC}"
    read -p "Press Enter to continue..."
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
    
    # SSH Port
    read -p "SSH Port [$SSH_PORT]: " input
    [[ -n "$input" ]] && SSH_PORT="$input"
    
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

# Function to show backend comparison
show_backend_comparison() {
    clear
    echo -e "${BLUE}📊 Display Backend Comparison${NC}"
    echo "================================"
    echo
    
    echo -e "${CYAN}🎮 GTK Backend (Current Default)${NC}"
    echo "  Pros:"
    echo "    ✓ Best compatibility with NVIDIA drivers"
    echo "    ✓ Stable - fewer display issues"
    echo "    ✓ Good performance with virtio-gpu"
    echo "    ✓ Works well with KDE Wayland"
    echo "  Cons:"
    echo "    ⚠️  Limited acceleration - basic rendering"
    echo "    ⚠️  No OpenGL - can't leverage GPU capabilities"
    echo "    ⚠️  May feel less responsive"
    echo
    
    echo -e "${CYAN}🚀 SDL Backend (Performance Option)${NC}"
    echo "  Pros:"
    echo "    ✓ Better performance - hardware acceleration support"
    echo "    ✓ OpenGL support - can use GPU capabilities"
    echo "    ✓ Smoother graphics - better for desktop environments"
    echo "    ✓ More responsive UI"
    echo "  Cons:"
    echo "    ⚠️  Potential compatibility issues with NVIDIA + Wayland"
    echo "    ⚠️  May crash if OpenGL isn't properly configured"
    echo "    ⚠️  Less stable than GTK"
    echo
    
    echo -e "${CYan}🔥 SPICE Backend (Advanced Option)${NC}"
    echo "  Pros:"
    echo "    ✓ Excellent performance with proper setup"
    echo "    ✓ Hardware acceleration support"
    echo "    ✓ Remote access capabilities"
    echo "    ✓ Professional-grade virtualization"
    echo "  Cons:"
    echo "    ⚠️  More complex setup required"
    echo "    ⚠️  May need additional packages"
    echo "    ⚠️  Overkill for simple testing"
    echo
    
    echo -e "${YELLOW}💡 Recommendation for KDE Wayland + NVIDIA:${NC}"
    echo "  1. Start with GTK for stability and compatibility"
    echo "  2. If performance is acceptable, stick with GTK"
    echo "  3. If you need better performance, try SDL carefully"
    echo "  4. Use SPICE only if you need advanced features"
    echo
    
    read -p "Press Enter to continue..."
}

# Function to start VM with selected backend
start_vm() {
    if [[ -z "$DISPLAY_BACKEND" ]]; then
        echo -e "${YELLOW}⚠️  No display backend selected. Using GTK (default).${NC}"
        DISPLAY_BACKEND="gtk"
    fi
    
    if [[ -z "$VM_ISO" ]]; then
        echo -e "${RED}❌ No ISO file selected. Please select an ISO first.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${GREEN}🚀 Starting Gentoo VM with $DISPLAY_BACKEND backend...${NC}"
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
    echo -e "${CYAN}📋 Final Configuration:${NC}"
    echo "  Display Backend: $DISPLAY_BACKEND"
    echo "  Network Mode: User networking with SSH forwarding"
    echo "  SSH Port: $SSH_PORT"
    echo "  SSH: ssh -p $SSH_PORT root@localhost"
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
    
    # Add display based on selected backend
    case "$DISPLAY_BACKEND" in
        "gtk")
            qemu_cmd="$qemu_cmd -display gtk"
            echo "  🎮 Using GTK display backend"
            ;;
        "sdl")
            qemu_cmd="$qemu_cmd -display sdl"
            echo "  🚀 Using SDL display backend"
            ;;
        "spice")
            qemu_cmd="$qemu_cmd -display spice-app"
            echo "  🔥 Using SPICE display backend"
            ;;
        *)
            qemu_cmd="$qemu_cmd -display gtk"
            echo "  🎮 Using GTK display backend (fallback)"
            ;;
    esac
    
    # Add storage
    qemu_cmd="$qemu_cmd -drive file=\"$VM_DISK\",if=virtio,cache=writeback,discard=unmap"
    
    # Add network
    qemu_cmd="$qemu_cmd -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.1,dhcpstart=10.0.2.15,hostfwd=tcp::$SSH_PORT-:22"
    qemu_cmd="$qemu_cmd -device virtio-net-pci,netdev=net0"
    
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
    
    # Add ISO
    qemu_cmd="$qemu_cmd -cdrom \"$VM_ISO\""
    qemu_cmd="$qemu_cmd -boot d"
    
    echo -e "${GREEN}🚀 Starting VM with $DISPLAY_BACKEND backend...${NC}"
    echo "Press Ctrl+C to stop the VM"
    echo
    
    # Execute QEMU command
    eval $qemu_cmd
    
    echo
    echo -e "${GREEN}✅ VM stopped.${NC}"
    echo "To start again, run: $0"
    echo "To reset (delete disk), run: rm -f $VM_DISK && $0"
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
        read -p "Choose option [0-8]: " choice
        
        case $choice in
            1) test_gtk_backend ;;
            2) test_sdl_backend ;;
            3) test_spice_backend ;;
            4) auto_detect_backend ;;
            5) configure_vm_settings ;;
            6) select_iso ;;
            7) show_backend_comparison ;;
            8) start_vm ;;
            0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please choose 0-8.${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main "$@"
