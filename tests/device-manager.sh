#!/bin/bash

# Device Passthrough Manager for QEMU VMs
# Features: GPU, USB, PCI, Audio device passthrough

set -e

# Configuration
VM_NAME=""
PASSTHROUGH_DEVICES=()
GPU_PASSTHROUGH="false"
USB_PASSTHROUGH="false"
PCI_PASSTHROUGH="false"
AUDIO_PASSTHROUGH="false"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to show main menu
show_menu() {
    clear
    echo -e "${GREEN}🔌 Device Passthrough Manager - QEMU VM Devices${NC}"
    echo "====================================================="
    echo
    
    echo -e "${CYAN}📋 Current Configuration:${NC}"
    echo "  VM Name: ${VM_NAME:-"Not set"}"
    echo "  GPU Passthrough: $(on_off_label GPU_PASSTHROUGH)"
    echo "  USB Passthrough: $(on_off_label USB_PASSTHROUGH)"
    echo "  PCI Passthrough: $(on_off_label PCI_PASSTHROUGH)"
    echo "  Audio Passthrough: $(on_off_label AUDIO_PASSTHROUGH)"
    echo "  Devices: ${#PASSTHROUGH_DEVICES[@]} configured"
    echo
    
    echo -e "${CYan}📋 Device Management Options:${NC}"
    echo "  1) Configure VM Devices"
    echo "  2) GPU Passthrough Setup"
    echo "  3) USB Device Management"
    echo "  4) PCI Device Management"
    echo "  5) Audio Device Setup"
    echo "  6) Device Compatibility Check"
    echo "  7) Show Current Configuration"
    echo "  8) Generate QEMU Commands"
    echo "  0) Exit"
    echo
    
    echo -e "${YELLOW}💡 Advanced device passthrough for maximum performance${NC}"
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

# Function to configure VM devices
configure_vm_devices() {
    clear
    echo -e "${BLUE}⚙️  VM Device Configuration${NC}"
    echo "==============================="
    echo
    
    read -p "VM Name: " VM_NAME
    [[ -z "$VM_NAME" ]] && return
    
    echo -e "${GREEN}✓ VM device configuration set${NC}"
    echo "  VM: $VM_NAME"
    read -p "Press Enter to continue..."
}

# Function to setup GPU passthrough
setup_gpu_passthrough() {
    clear
    echo -e "${BLUE}🎮 GPU Passthrough Setup${NC}"
    echo "============================"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}⚠️  GPU passthrough requires root privileges${NC}"
        echo "Some features may not work without root access"
        echo
    fi
    
    echo "GPU Passthrough Options:"
    echo "  1) Enable GPU passthrough"
    echo "  2) Disable GPU passthrough"
    echo "  3) Configure GPU settings"
    echo "  4) Check GPU compatibility"
    read -p "Choose option [1-4]: " choice
    
    case $choice in
        1)
            GPU_PASSTHROUGH="true"
            echo -e "${GREEN}✓ GPU passthrough enabled${NC}"
            ;;
        2)
            GPU_PASSTHROUGH="false"
            echo -e "${GREEN}✓ GPU passthrough disabled${NC}"
            ;;
        3)
            if [[ "$GPU_PASSTHROUGH" == "true" ]]; then
                configure_gpu_settings
            else
                echo "Enable GPU passthrough first"
            fi
            ;;
        4)
            check_gpu_compatibility
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to configure GPU settings
configure_gpu_settings() {
    echo "GPU Configuration Options:"
    echo "  1) Select GPU device"
    echo "  2) Configure VRAM"
    echo "  3) Set GPU driver"
    read -p "Choose option [1-3]: " choice
    
    case $choice in
        1)
            echo "Available GPU devices:"
            lspci | grep -i vga | while read line; do
                echo "  $line"
            done
            read -p "Enter GPU device ID (e.g., 01:00.0): " gpu_id
            if [[ -n "$gpu_id" ]]; then
                GPU_DEVICE_ID="$gpu_id"
                echo -e "${GREEN}✓ GPU device selected: $gpu_id${NC}"
            fi
            ;;
        2)
            echo "VRAM Options: 64M, 128M, 256M, 512M, 1G, 2G, 4G, 8G"
            read -p "Enter VRAM size: " vram_size
            if [[ -n "$vram_size" ]]; then
                GPU_VRAM="$vram_size"
                echo -e "${GREEN}✓ VRAM configured: $vram_size${NC}"
            fi
            ;;
        3)
            echo "GPU Driver Options:"
            echo "  1) NVIDIA proprietary"
            echo "  2) AMD Mesa"
            echo "  3) Intel Mesa"
            echo "  4) Auto-detect"
            read -p "Choose driver [1-4]: " driver_choice
            
            case $driver_choice in
                1) GPU_DRIVER="nvidia" ;;
                2) GPU_DRIVER="amd" ;;
                3) GPU_DRIVER="intel" ;;
                4) GPU_DRIVER="auto" ;;
                *) GPU_DRIVER="auto" ;;
            esac
            echo -e "${GREEN}✓ GPU driver set: $GPU_DRIVER${NC}"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Function to check GPU compatibility
check_gpu_compatibility() {
    echo "GPU Compatibility Check:"
    echo "========================"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}⚠️  Not running as root - limited compatibility check${NC}"
    else
        echo -e "${GREEN}✓ Running as root - full compatibility check${NC}"
    fi
    
    # Check IOMMU support
    if dmesg | grep -i iommu &> /dev/null; then
        echo -e "${GREEN}✓ IOMMU support detected${NC}"
    else
        echo -e "${RED}❌ IOMMU support not detected${NC}"
        echo "  IOMMU is required for device passthrough"
    fi
    
    # Check KVM support
    if lsmod | grep kvm &> /dev/null; then
        echo -e "${GREEN}✓ KVM support detected${NC}"
    else
        echo -e "${RED}❌ KVM support not detected${NC}"
    fi
    
    # Check available GPUs
    echo "Available GPU devices:"
    lspci | grep -i vga | while read line; do
        echo "  $line"
    done
    
    # Check if VFIO modules are loaded
    if lsmod | grep vfio &> /dev/null; then
        echo -e "${GREEN}✓ VFIO modules loaded${NC}"
    else
        echo -e "${YELLOW}⚠️  VFIO modules not loaded${NC}"
        echo "  Load with: modprobe vfio vfio_iommu_type1 vfio_pci"
    fi
}

# Function to manage USB devices
manage_usb_devices() {
    clear
    echo -e "${BLUE}🔌 USB Device Management${NC}"
    echo "============================"
    echo
    
    echo "USB Passthrough Options:"
    echo "  1) Enable USB passthrough"
    echo "  2) Disable USB passthrough"
    echo "  3) Add USB device"
    echo "  4) Remove USB device"
    echo "  5) List USB devices"
    read -p "Choose option [1-5]: " choice
    
    case $choice in
        1)
            USB_PASSTHROUGH="true"
            echo -e "${GREEN}✓ USB passthrough enabled${NC}"
            ;;
        2)
            USB_PASSTHROUGH="false"
            echo -e "${GREEN}✓ USB passthrough disabled${NC}"
            ;;
        3)
            if [[ "$USB_PASSTHROUGH" == "true" ]]; then
                add_usb_device
            else
                echo "Enable USB passthrough first"
            fi
            ;;
        4)
            if [[ "$USB_PASSTHROUGH" == "true" ]]; then
                remove_usb_device
            else
                echo "Enable USB passthrough first"
            fi
            ;;
        5)
            list_usb_devices
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to add USB device
add_usb_device() {
    echo "Available USB devices:"
    lsusb | while read line; do
        echo "  $line"
    done
    
    echo
    echo "USB Device Options:"
    echo "  1) Add by vendor:product ID"
    echo "  2) Add by device path"
    echo "  3) Add by device name"
    read -p "Choose option [1-3]: " choice
    
    case $choice in
        1)
            read -p "Enter vendor ID (e.g., 1234): " vendor_id
            read -p "Enter product ID (e.g., 5678): " product_id
            if [[ -n "$vendor_id" && -n "$product_id" ]]; then
                local usb_device="usb:$vendor_id:$product_id"
                PASSTHROUGH_DEVICES+=("$usb_device")
                echo -e "${GREEN}✓ USB device added: $usb_device${NC}"
            fi
            ;;
        2)
            read -p "Enter device path (e.g., /dev/bus/usb/001/002): " device_path
            if [[ -n "$device_path" ]]; then
                local usb_device="usb:path:$device_path"
                PASSTHROUGH_DEVICES+=("$usb_device")
                echo -e "${GREEN}✓ USB device added: $usb_device${NC}"
            fi
            ;;
        3)
            read -p "Enter device name (e.g., keyboard, mouse): " device_name
            if [[ -n "$device_name" ]]; then
                local usb_device="usb:name:$device_name"
                PASSTHROUGH_DEVICES+=("$usb_device")
                echo -e "${GREEN}✓ USB device added: $usb_device${NC}"
            fi
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Function to remove USB device
remove_usb_device() {
    if [[ ${#PASSTHROUGH_DEVICES[@]} -eq 0 ]]; then
        echo "No USB devices configured"
        return
    fi
    
    echo "Configured USB devices:"
    local usb_count=0
    for i in "${!PASSTHROUGH_DEVICES[@]}"; do
        local device="${PASSTHROUGH_DEVICES[$i]}"
        if [[ "$device" == usb:* ]]; then
            echo "  $((++usb_count))) $device"
        fi
    done
    
    if [[ $usb_count -eq 0 ]]; then
        echo "No USB devices found"
        return
    fi
    
    read -p "Enter device number to remove: " choice
    local index=$((choice-1))
    
    if [[ $index -ge 0 && $index -lt ${#PASSTHROUGH_DEVICES[@]} ]]; then
        local removed_device="${PASSTHROUGH_DEVICES[$index]}"
        unset PASSTHROUGH_DEVICES[$index]
        PASSTHROUGH_DEVICES=("${PASSTHROUGH_DEVICES[@]}")  # Reindex array
        echo -e "${GREEN}✓ USB device removed: $removed_device${NC}"
    else
        echo -e "${RED}Invalid device number${NC}"
    fi
}

# Function to list USB devices
list_usb_devices() {
    echo "USB Device Information:"
    echo "======================="
    
    echo "System USB devices:"
    lsusb | while read line; do
        echo "  $line"
    done
    
    echo
    echo "Configured USB passthrough devices:"
    local usb_count=0
    for device in "${PASSTHROUGH_DEVICES[@]}"; do
        if [[ "$device" == usb:* ]]; then
            echo "  $((++usb_count))) $device"
        fi
    done
    
    if [[ $usb_count -eq 0 ]]; then
        echo "  No USB devices configured for passthrough"
    fi
}

# Function to manage PCI devices
manage_pci_devices() {
    clear
    echo -e "${BLUE}🔌 PCI Device Management${NC}"
    echo "============================"
    echo
    
    echo "PCI Passthrough Options:"
    echo "  1) Enable PCI passthrough"
    echo "  2) Disable PCI passthrough"
    echo "  3) Add PCI device"
    echo "  4) Remove PCI device"
    echo "  5) List PCI devices"
    read -p "Choose option [1-5]: " choice
    
    case $choice in
        1)
            PCI_PASSTHROUGH="true"
            echo -e "${GREEN}✓ PCI passthrough enabled${NC}"
            ;;
        2)
            PCI_PASSTHROUGH="false"
            echo -e "${GREEN}✓ PCI passthrough disabled${NC}"
            ;;
        3)
            if [[ "$PCI_PASSTHROUGH" == "true" ]]; then
                add_pci_device
            else
                echo "Enable PCI passthrough first"
            fi
            ;;
        4)
            if [[ "$PCI_PASSTHROUGH" == "true" ]]; then
                remove_pci_device
            else
                echo "Enable PCI passthrough first"
            fi
            ;;
        5)
            list_pci_devices
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to add PCI device
add_pci_device() {
    echo "Available PCI devices:"
    lspci | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "Enter PCI device ID (e.g., 01:00.0): " pci_id
    if [[ -n "$pci_id" ]]; then
        local pci_device="pci:$pci_id"
        PASSTHROUGH_DEVICES+=("$pci_device")
        echo -e "${GREEN}✓ PCI device added: $pci_device${NC}"
    fi
}

# Function to remove PCI device
remove_pci_device() {
    if [[ ${#PASSTHROUGH_DEVICES[@]} -eq 0 ]]; then
        echo "No PCI devices configured"
        return
    fi
    
    echo "Configured PCI devices:"
    local pci_count=0
    for i in "${!PASSTHROUGH_DEVICES[@]}"; do
        local device="${PASSTHROUGH_DEVICES[$i]}"
        if [[ "$device" == pci:* ]]; then
            echo "  $((++pci_count))) $device"
        fi
    done
    
    if [[ $pci_count -eq 0 ]]; then
        echo "No PCI devices found"
        return
    fi
    
    read -p "Enter device number to remove: " choice
    local index=$((choice-1))
    
    if [[ $index -ge 0 && $index -lt ${#PASSTHROUGH_DEVICES[@]} ]]; then
        local removed_device="${PASSTHROUGH_DEVICES[$index]}"
        unset PASSTHROUGH_DEVICES[$index]
        PASSTHROUGH_DEVICES=("${PASSTHROUGH_DEVICES[@]}")  # Reindex array
        echo -e "${GREEN}✓ PCI device removed: $removed_device${NC}"
    else
        echo -e "${RED}Invalid device number${NC}"
    fi
}

# Function to list PCI devices
list_pci_devices() {
    echo "PCI Device Information:"
    echo "======================="
    
    echo "System PCI devices:"
    lspci | while read line; do
        echo "  $line"
    done
    
    echo
    echo "Configured PCI passthrough devices:"
    local pci_count=0
    for device in "${PASSTHROUGH_DEVICES[@]}"; do
        if [[ "$device" == pci:* ]]; then
            echo "  $((++pci_count))) $device"
        fi
    done
    
    if [[ $pci_count -eq 0 ]]; then
        echo "  No PCI devices configured for passthrough"
    fi
}

# Function to setup audio devices
setup_audio_devices() {
    clear
    echo -e "${BLUE}🎵 Audio Device Setup${NC}"
    echo "======================="
    echo
    
    echo "Audio Passthrough Options:"
    echo "  1) Enable audio passthrough"
    echo "  2) Disable audio passthrough"
    echo "  3) Configure audio settings"
    echo "  4) List audio devices"
    read -p "Choose option [1-4]: " choice
    
    case $choice in
        1)
            AUDIO_PASSTHROUGH="true"
            echo -e "${GREEN}✓ Audio passthrough enabled${NC}"
            ;;
        2)
            AUDIO_PASSTHROUGH="false"
            echo -e "${GREEN}✓ Audio passthrough disabled${NC}"
            ;;
        3)
            if [[ "$AUDIO_PASSTHROUGH" == "true" ]]; then
                configure_audio_settings
            else
                echo "Enable audio passthrough first"
            fi
            ;;
        4)
            list_audio_devices
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to configure audio settings
configure_audio_settings() {
    echo "Audio Configuration Options:"
    echo "  1) Select audio backend"
    echo "  2) Configure audio device"
    echo "  3) Set audio quality"
    read -p "Choose option [1-3]: " choice
    
    case $choice in
        1)
            echo "Audio Backend Options:"
            echo "  1) ALSA (Linux)"
            echo "  2) PulseAudio"
            echo "  3) JACK"
            echo "  4) OSS"
            read -p "Choose backend [1-4]: " backend_choice
            
            case $backend_choice in
                1) AUDIO_BACKEND="alsa" ;;
                2) AUDIO_BACKEND="pulse" ;;
                3) AUDIO_BACKEND="jack" ;;
                4) AUDIO_BACKEND="oss" ;;
                *) AUDIO_BACKEND="alsa" ;;
            esac
            echo -e "${GREEN}✓ Audio backend set: $AUDIO_BACKEND${NC}"
            ;;
        2)
            echo "Available audio devices:"
            if command -v aplay &> /dev/null; then
                aplay -l | grep -A 1 "card" | while read line; do
                    echo "  $line"
                done
            else
                echo "  aplay not available"
            fi
            
            read -p "Enter audio device (e.g., hw:0,0): " audio_device
            if [[ -n "$audio_device" ]]; then
                AUDIO_DEVICE="$audio_device"
                echo -e "${GREEN}✓ Audio device set: $audio_device${NC}"
            fi
            ;;
        3)
            echo "Audio Quality Options:"
            echo "  1) Low (22.05 kHz, 8-bit)"
            echo "  2) Medium (44.1 kHz, 16-bit)"
            echo "  3) High (48 kHz, 24-bit)"
            echo "  4) Ultra (96 kHz, 32-bit)"
            read -p "Choose quality [1-4]: " quality_choice
            
            case $quality_choice in
                1) AUDIO_QUALITY="low" ;;
                2) AUDIO_QUALITY="medium" ;;
                3) AUDIO_QUALITY="high" ;;
                4) AUDIO_QUALITY="ultra" ;;
                *) AUDIO_QUALITY="medium" ;;
            esac
            echo -e "${GREEN}✓ Audio quality set: $AUDIO_QUALITY${NC}"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Function to list audio devices
list_audio_devices() {
    echo "Audio Device Information:"
    echo "========================="
    
    echo "ALSA devices:"
    if command -v aplay &> /dev/null; then
        aplay -l 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        echo "  aplay not available"
    fi
    
    echo
    echo "PulseAudio devices:"
    if command -v pactl &> /dev/null; then
        pactl list short sinks 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        echo "  pactl not available"
    fi
}

# Function to check device compatibility
check_device_compatibility() {
    clear
    echo -e "${BLUE}🔍 Device Compatibility Check${NC}"
    echo "================================="
    echo
    
    echo "System Compatibility Check:"
    echo "=========================="
    
    # Check root privileges
    if [[ $EUID -eq 0 ]]; then
        echo -e "${GREEN}✓ Running as root - full device access${NC}"
    else
        echo -e "${YELLOW}⚠️  Not running as root - limited device access${NC}"
    fi
    
    # Check IOMMU support
    if dmesg | grep -i iommu &> /dev/null; then
        echo -e "${GREEN}✓ IOMMU support detected${NC}"
    else
        echo -e "${RED}❌ IOMMU support not detected${NC}"
        echo "  IOMMU is required for PCI device passthrough"
    fi
    
    # Check VFIO modules
    if lsmod | grep vfio &> /dev/null; then
        echo -e "${GREEN}✓ VFIO modules loaded${NC}"
    else
        echo -e "${YELLOW}⚠️  VFIO modules not loaded${NC}"
        echo "  Load with: modprobe vfio vfio_iommu_type1 vfio_pci"
    fi
    
    # Check KVM support
    if lsmod | grep kvm &> /dev/null; then
        echo -e "${GREEN}✓ KVM support detected${NC}"
    else
        echo -e "${RED}❌ KVM support not detected${NC}"
    fi
    
    # Check available devices
    echo
    echo "Available Devices:"
    echo "=================="
    
    echo "GPU devices:"
    lspci | grep -i vga | head -5 | while read line; do
        echo "  $line"
    done
    
    echo
    echo "USB devices:"
    lsusb | head -5 | while read line; do
        echo "  $line"
    done
    
    echo
    echo "Audio devices:"
    if command -v aplay &> /dev/null; then
        aplay -l 2>/dev/null | grep "card" | head -3 | while read line; do
            echo "  $line"
        done
    else
        echo "  aplay not available"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to generate QEMU commands
generate_qemu_commands() {
    clear
    echo -e "${BLUE}🔧 QEMU Device Passthrough Commands${NC}"
    echo "========================================="
    echo
    
    if [[ -z "$VM_NAME" ]]; then
        echo "Configure VM devices first"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Generated QEMU Device Commands:"
    echo
    
    # GPU passthrough
    if [[ "$GPU_PASSTHROUGH" == "true" ]]; then
        echo "# GPU Passthrough Configuration"
        if [[ -n "$GPU_DEVICE_ID" ]]; then
            echo "-device vfio-pci,host=$GPU_DEVICE_ID"
        else
            echo "-device vfio-pci,host=01:00.0  # Replace with actual GPU ID"
        fi
        
        if [[ -n "$GPU_VRAM" ]]; then
            echo "-vga none"
            echo "-device virtio-gpu-pci,virgl=on"
        fi
        echo
    fi
    
    # USB passthrough
    if [[ "$USB_PASSTHROUGH" == "true" ]]; then
        echo "# USB Passthrough Configuration"
        for device in "${PASSTHROUGH_DEVICES[@]}"; do
            if [[ "$device" == usb:* ]]; then
                local device_type=$(echo "$device" | cut -d: -f2)
                local device_id=$(echo "$device" | cut -d: -f3)
                
                case $device_type in
                    "usb")
                        echo "-device usb-host,vendorid=0x$device_id,productid=0x$(echo "$device" | cut -d: -f4)"
                        ;;
                    "path")
                        echo "-device usb-host,hostbus=1,hostaddr=$device_id"
                        ;;
                    "name")
                        echo "-device usb-$device_id"
                        ;;
                esac
            fi
        done
        echo
    fi
    
    # PCI passthrough
    if [[ "$PCI_PASSTHROUGH" == "true" ]]; then
        echo "# PCI Passthrough Configuration"
        for device in "${PASSTHROUGH_DEVICES[@]}"; do
            if [[ "$device" == pci:* ]]; then
                local pci_id=$(echo "$device" | cut -d: -f2)
                echo "-device vfio-pci,host=$pci_id"
            fi
        done
        echo
    fi
    
    # Audio passthrough
    if [[ "$AUDIO_PASSTHROUGH" == "true" ]]; then
        echo "# Audio Passthrough Configuration"
        echo "-device intel-hda"
        echo "-device hda-duplex"
        
        if [[ -n "$AUDIO_BACKEND" ]]; then
            case $AUDIO_BACKEND in
                "alsa")
                    echo "-audiodev alsa,id=alsa0"
                    ;;
                "pulse")
                    echo "-audiodev pa,id=pa0"
                    ;;
                "jack")
                    echo "-audiodev jack,id=jack0"
                    ;;
                "oss")
                    echo "-audiodev oss,id=oss0"
                    ;;
            esac
        fi
        echo
    fi
    
    # General device options
    echo "# General Device Options"
    echo "-usb"
    echo "-device usb-tablet"
    echo "-device virtio-balloon"
    echo "-device virtio-rng-pci"
    
    read -p "Press Enter to continue..."
}

# Function to show current configuration
show_configuration() {
    clear
    echo -e "${BLUE}📋 Current Device Configuration${NC}"
    echo "===================================="
    echo
    
    echo -e "${CYan}VM Configuration:${NC}"
    echo "  VM Name: ${VM_NAME:-"Not set"}"
    echo
    
    echo -e "${CYan}Device Passthrough Status:${NC}"
    echo "  GPU Passthrough: $(on_off_label GPU_PASSTHROUGH)"
    echo "  USB Passthrough: $(on_off_label USB_PASSTHROUGH)"
    echo "  PCI Passthrough: $(on_off_label PCI_PASSTHROUGH)"
    echo "  Audio Passthrough: $(on_off_label AUDIO_PASSTHROUGH)"
    echo
    
    echo -e "${CYan}Configured Devices:${NC}"
    if [[ ${#PASSTHROUGH_DEVICES[@]} -eq 0 ]]; then
        echo "  No devices configured"
    else
        for i in "${!PASSTHROUGH_DEVICES[@]}"; do
            local device="${PASSTHROUGH_DEVICES[$i]}"
            echo "  $((i+1))) $device"
        done
    fi
    echo
    
    if [[ "$GPU_PASSTHROUGH" == "true" ]]; then
        echo -e "${CYan}GPU Configuration:${NC}"
        echo "  Device ID: ${GPU_DEVICE_ID:-"Not set"}"
        echo "  VRAM: ${GPU_VRAM:-"Default"}"
        echo "  Driver: ${GPU_DRIVER:-"Auto-detect"}"
        echo
    fi
    
    if [[ "$AUDIO_PASSTHROUGH" == "true" ]]; then
        echo -e "${CYan}Audio Configuration:${NC}"
        echo "  Backend: ${AUDIO_BACKEND:-"Default"}"
        echo "  Device: ${AUDIO_DEVICE:-"Default"}"
        echo "  Quality: ${AUDIO_QUALITY:-"Default"}"
        echo
    fi
    
    read -p "Press Enter to continue..."
}

# Main function
main() {
    # Check if running as root for advanced features
    if [[ $EUID -eq 0 ]]; then
        echo -e "${GREEN}✓ Running as root - all device passthrough features available${NC}"
    else
        echo -e "${YELLOW}⚠️  Not running as root - some features limited${NC}"
    fi
    
    # Main menu loop
    while true; do
        show_menu
        read -p "Choose option [0-8]: " choice
        
        case $choice in
            1) configure_vm_devices ;;
            2) setup_gpu_passthrough ;;
            3) manage_usb_devices ;;
            4) manage_pci_devices ;;
            5) setup_audio_devices ;;
            6) check_device_compatibility ;;
            7) show_configuration ;;
            8) generate_qemu_commands ;;
            0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please choose 0-8.${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main "$@"

