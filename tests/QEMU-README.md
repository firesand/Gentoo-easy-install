# 🖥️ QEMU Configuration for Gentoo Testing

This directory contains QEMU configurations for testing the Gentoo installer with modern hardware specifications and convenient features.

## 🎯 **VM Specifications**

- **RAM**: 16GB
- **CPU**: 8 cores (host CPU passthrough)
- **VRAM**: 64MB (virtio-gpu)
- **Storage**: 512GB Virtio mode (best performance)
- **Features**: Bidirectional copy-paste, shared folder, modern hardware

## 📁 **Files Overview**

### **1. `qemu-gentoo-test.sh`** - Advanced QEMU Launcher
- **Full-featured launcher** with command-line options
- **Automatic disk creation** and management
- **Convenience scripts** for easy VM management
- **Smart defaults** and validation
- **Comprehensive help** and documentation

### **2. `qemu-gentoo.conf`** - QEMU Configuration File
- **Raw QEMU arguments** for manual use
- **Exact specifications** as requested
- **Easy to modify** for custom configurations
- **Reference document** for understanding options

### **3. `start-gentoo-vm.sh`** - Simple Launcher
- **Easy-to-use script** for quick VM startup
- **Automatic setup** of directories and disk
- **Minimal configuration** needed
- **Perfect for beginners**

## 🚀 **Quick Start**

### **Option 1: Simple Launcher (Recommended for beginners)**
```bash
# Navigate to tests directory
cd tests

# Start the VM with default settings
./start-gentoo-vm.sh
```

### **Option 2: Advanced Launcher (Recommended for power users)**
```bash
# Show help
./qemu-gentoo-test.sh --help

# Start with default settings
./qemu-gentoo-test.sh

# Start with custom configuration
./qemu-gentoo-test.sh --name my-gentoo --ram 32G --cores 16

# Start with specific ISO
./qemu-gentoo-test.sh --iso /path/to/gentoo.iso
```

### **Option 3: Manual QEMU Command**
```bash
# Use the configuration file as reference
# Copy arguments from qemu-gentoo.conf and modify as needed
qemu-system-x86_64 [arguments from config file]
```

## 🔧 **Features Explained**

### **Modern Hardware Configuration**
- **Q35 Chipset**: Modern UEFI-based motherboard emulation
- **KVM Acceleration**: Near-native performance on Linux hosts
- **Host CPU Passthrough**: Uses your actual CPU features
- **Virtio Devices**: High-performance paravirtualized devices

### **Storage Configuration**
- **Virtio Mode**: High-performance paravirtualized storage (best performance)
- **Alternative IDE Mode**: Available for compatibility if needed
- **QCow2 Format**: Efficient disk image format with snapshots
- **Writeback Cache**: Better performance (data loss risk on crashes)
- **Discard Support**: Automatic TRIM for SSD optimization

### **Network Configuration**
- **User Networking**: Simple NAT networking (192.168.100.0/24)
- **Virtio Network**: High-performance network adapter
- **DHCP Server**: Automatic IP assignment for guest
- **Host Access**: Guest can access host at 192.168.100.1

### **Shared Folder (Virtio-FS)**
- **High Performance**: Direct file system access
- **Bidirectional**: Files accessible from both host and guest
- **Automatic Setup**: Created automatically by launcher scripts
- **Security Model**: Mapped security for easy access

### **Copy-Paste Support**
- **SPICE Agent**: Bidirectional clipboard sharing
- **Virtio Serial**: High-performance communication channel
- **Automatic Setup**: No manual configuration needed
- **Cross-Platform**: Works on Linux, Windows, and macOS hosts

## 📋 **Prerequisites**

### **Required Software**
```bash
# Ubuntu/Debian
sudo apt install qemu-system-x86

# Arch Linux
sudo pacman -S qemu

# Fedora
sudo dnf install qemu-system-x86

# Gentoo
sudo emerge qemu
```

### **Optional Dependencies**
```bash
# For better shared folder performance
sudo apt install virtiofsd

# For advanced networking features
sudo apt install socat
```

### **Hardware Requirements**
- **KVM Support**: CPU with virtualization extensions (Intel VT-x, AMD-V)
- **Sufficient RAM**: At least 20GB total (16GB for VM + 4GB for host)
- **Storage Space**: At least 600GB free space (512GB VM + overhead)

## 🎮 **Usage Examples**

### **Basic Testing**
```bash
# Start VM and test basic functionality
./start-gentoo-vm.sh

# Install Gentoo using the installer
# Test desktop environment selection
# Test GPU driver installation
```

### **Advanced Testing**
```bash
# Test with custom hardware specs
./qemu-gentoo-test.sh --ram 32G --cores 16 --storage 1T

# Test with specific ISO
./qemu-gentoo-test.sh --iso ~/Downloads/gentoo-live.iso

# Test with custom shared folder
./qemu-gentoo-test.sh --folder ~/my-shared-folder
```

### **Development Testing**
```bash
# Test installer modifications
# Test new desktop environment features
# Test GPU driver configurations
# Test different Gentoo profiles
```

## 🔍 **Troubleshooting**

### **Common Issues**

#### **1. QEMU Not Found**
```bash
# Install QEMU first
sudo apt install qemu-system-x86  # Ubuntu/Debian
sudo pacman -S qemu               # Arch
sudo dnf install qemu-system-x86  # Fedora
sudo emerge qemu                  # Gentoo
```

#### **2. KVM Not Available**
```bash
# Check if KVM is available
lsmod | grep kvm

# Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo

# Enable KVM module
sudo modprobe kvm
sudo modprobe kvm_intel  # Intel
sudo modprobe kvm_amd    # AMD
```

#### **3. Copy-Paste Not Working**
```bash
# Inside the VM, install spice-vdagent
emerge spice-vdagent

# Enable the service
rc-update add spice-vdagentd default
```

#### **4. Shared Folder Not Accessible**
```bash
# Inside the VM, mount the shared folder
mkdir -p /mnt/shared
mount -t virtiofs shared /mnt/shared

# Check if virtio-fs is available
lsmod | grep virtio_fs
```

#### **5. Performance Issues**
```bash
# Ensure KVM is enabled
qemu-system-x86_64 -enable-kvm

# Use virtio devices
-drive file=disk.qcow2,if=virtio
-device virtio-net-pci
```

### **Performance Tips**
1. **Use KVM**: Always enable KVM for near-native performance
2. **Virtio Devices**: Use virtio for network, storage, and graphics
3. **Host CPU**: Use `-cpu host` for best performance
4. **Memory**: Allocate sufficient RAM (16GB recommended)
5. **Storage**: Use writeback cache for better performance

## 📚 **Advanced Configuration**

### **Customizing the VM**

#### **Modify Hardware Specs**
Edit the launcher scripts or create your own configuration:
```bash
# Custom RAM and CPU
-m 32G -smp 16

# Custom storage
-drive file=disk.qcow2,if=sata,size=1T

# Custom network
-netdev user,id=net0,net=10.0.0.0/24
```

#### **Add Additional Features**
```bash
# Enable SPICE for better graphics
-spice port=5930,addr=127.0.0.1

# Enable USB passthrough
-device usb-host,vendorid=0x1234,productid=0x5678

# Enable audio passthrough
-device intel-hda
-device hda-duplex
```

#### **Network Configuration**
```bash
# Bridge networking (for external access)
-netdev bridge,id=net0,br=virbr0
-device virtio-net-pci,netdev=net0

# Port forwarding
-netdev user,id=net0,hostfwd=tcp::2222-:22
```

## 🎯 **Testing Scenarios**

### **1. Basic Installation**
- Test the installer with default settings
- Verify all desktop environment options
- Test GPU driver installation

### **2. Advanced Features**
- Test custom disk layouts (ZFS, BTRFS, RAID)
- Test encryption (LUKS, ZFS encryption)
- Test different boot configurations (EFI/BIOS)

### **3. Desktop Environments**
- Test KDE Plasma installation
- Test GNOME installation
- Test Hyprland/Wayland support
- Test GPU driver compatibility

### **4. Performance Testing**
- Test compilation performance
- Test gaming performance
- Test multimedia performance

## 📝 **Notes**

- **Data Persistence**: VM disk persists between sessions
- **Easy Reset**: Delete disk file to start fresh
- **Snapshots**: Use `qemu-img snapshot` for testing
- **Backup**: Backup disk files before major changes
- **Resources**: Monitor host system resources during VM operation

## 🆘 **Getting Help**

If you encounter issues:

1. **Check Prerequisites**: Ensure QEMU and KVM are properly installed
2. **Check Hardware**: Verify CPU virtualization support
3. **Check Logs**: Look for error messages in QEMU output
4. **Test Basic**: Try with minimal configuration first
5. **Ask Community**: Gentoo forums and IRC channels

## 🎉 **Happy Testing!**

This QEMU configuration provides an excellent environment for testing the Gentoo installer with modern hardware specifications. The VM offers near-native performance while maintaining the flexibility to test various configurations and scenarios.

Enjoy testing the enhanced Gentoo installer with desktop environment and GPU driver support! 🐧✨
