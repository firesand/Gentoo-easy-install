# 🐧 Gentoo Installer Guide: KDE Plasma + Wayland + NVIDIA

This guide is specifically optimized for users running **KDE Plasma with Wayland** on **NVIDIA drivers** who want to test the Gentoo installer in a QEMU virtual machine.

## 🎯 **Your Setup**
- **Host OS**: Linux with KDE Plasma + Wayland
- **Graphics**: NVIDIA drivers
- **Goal**: Test Gentoo installer in QEMU VM with SSH access

## 🚀 **Quick Start (Recommended)**

### **Option 1: User Networking (No Root Required)**
```bash
# Start VM with SSH port forwarding
./tests/start-gentoo-vm-ssh.sh --cdrom /path/to/gentoo-iso.iso

# From another terminal, SSH to VM
ssh -p 2222 root@localhost
```

### **Option 2: Bridge Networking (Better Performance, Requires Root)**
```bash
# Start VM with bridge networking
sudo ./tests/start-gentoo-vm-nvidia-wayland.sh --cdrom /path/to/gentoo-iso.iso

# From another terminal, SSH to VM
ssh root@192.168.100.100
```

## 🔧 **NVIDIA + Wayland Optimizations**

### **Why These Settings Work Best**
1. **`-vga virtio`**: Best compatibility with NVIDIA drivers
2. **`-display gtk`**: Avoids OpenGL acceleration issues
3. **`-machine type=q35,accel=kvm`**: Modern hardware emulation
4. **Virtio devices**: Best performance for storage, network, and graphics

### **Display Issues with NVIDIA + Wayland**
- **Problem**: QEMU with OpenGL acceleration can cause EGL errors
- **Solution**: Use `-display gtk` without `gl=on`
- **Alternative**: Use SPICE display if GTK has issues

## 🌐 **Network Configuration**

### **User Networking (Option 1)**
- **VM IP**: 10.0.2.15
- **Gateway**: 10.0.2.2
- **DNS**: 10.0.2.3
- **SSH**: Port 2222 → 22 (port forwarding)
- **Pros**: No root required, works out of the box
- **Cons**: Limited network access, slower

### **Bridge Networking (Option 2)**
- **VM IP**: 192.168.100.100 (configurable)
- **Gateway**: 192.168.100.1
- **DNS**: 8.8.8.8, 1.1.1.1
- **SSH**: Direct access via VM IP
- **Pros**: Full network access, better performance
- **Cons**: Requires root, bridge setup

## 📱 **SSH Access Setup**

### **Inside the VM (After Installation)**
```bash
# Install OpenSSH
emerge openssh

# Enable SSH service
rc-update add sshd default

# Start SSH service
/etc/init.d/sshd start

# Set root password (if not set)
passwd
```

### **From Host System**
```bash
# Option 1: User networking
ssh -p 2222 root@localhost

# Option 2: Bridge networking
ssh root@192.168.100.100

# With key-based authentication (recommended)
ssh -i ~/.ssh/id_rsa -p 2222 root@localhost
```

## 🎮 **Gentoo Installer Configuration**

### **Recommended Settings for Your Setup**
```bash
# Desktop Environment
DESKTOP_ENVIRONMENT="kde"
ENABLE_DISPLAY_MANAGER="auto"  # Will use SDDM
ENABLE_NETWORK_MANAGER="auto"  # Will use NetworkManager

# GPU Drivers
GPU_DRIVER="nvidia"  # Or "mesa" for better Wayland support
ENABLE_VULKAN=true
ENABLE_OPENCL=true
```

### **Why These Settings?**
- **KDE Plasma**: Best integration with your current setup
- **SDDM**: KDE's default display manager
- **NetworkManager**: Excellent KDE integration
- **NVIDIA drivers**: Match your host setup
- **Vulkan/OpenCL**: Gaming and compute support

## 🔍 **Troubleshooting**

### **Common Issues**

#### **1. Display Problems**
```bash
# Error: "egl: eglCreateWindowSurface failed"
# Solution: Use -display gtk (already configured)

# Alternative: Use SPICE display
-display spice-app,gl=on
```

#### **2. Network Issues**
```bash
# SSH connection refused
# Check: Is SSH service running in VM?
# Check: Is port forwarding working?

# Network not working in VM
# Check: DHCP client is running
# Check: Network interface is up
```

#### **3. Performance Issues**
```bash
# Slow VM performance
# Solution: Use bridge networking instead of user networking
# Solution: Ensure KVM is enabled and working

# Check KVM status
lsmod | grep kvm
```

### **Debug Commands**
```bash
# Check QEMU process
ps aux | grep qemu

# Check network bridges
ip link show

# Check port usage
netstat -tuln | grep :2222

# Check VM disk usage
ls -lh ~/vm-disks/
```

## 📁 **File Sharing**

### **Shared Folder Setup**
```bash
# Inside VM
mkdir -p /mnt/shared
mount -t virtiofs shared /mnt/shared

# Access shared files
ls /mnt/shared/
cp /mnt/shared/file.txt ~/
```

### **Shared Folder Location**
- **Host**: `~/vm-shared/gentoo-test/`
- **VM**: `/mnt/shared/`

## 🚀 **Advanced Configuration**

### **Custom QEMU Options**
```bash
# Add custom QEMU arguments
qemu-system-x86_64 \
    [existing options] \
    -device virtio-gpu-pci \
    -device virtio-input-host-pci \
    -device virtio-mouse-pci \
    -device virtio-keyboard-pci
```

### **Performance Tuning**
```bash
# CPU pinning (advanced)
-taskset 0-7

# Memory ballooning
-device virtio-balloon-pci

# Disk I/O tuning
-drive file=disk.qcow2,if=virtio,cache=writeback,io=threads
```

## 📚 **Useful Commands**

### **VM Management**
```bash
# Start VM
./tests/start-gentoo-vm-ssh.sh --cdrom iso.iso

# Stop VM
# Press Ctrl+C in QEMU window

# Reset VM (delete disk)
rm -f ~/vm-disks/gentoo-test.qcow2

# Check VM status
ps aux | grep qemu
```

### **Network Management**
```bash
# Check bridge status
ip link show br0

# Create bridge manually
sudo ip link add br0 type bridge
sudo ip link set br0 up

# Remove bridge
sudo ip link delete br0
```

## 🎯 **Next Steps**

1. **Test the installer** with your preferred configuration
2. **Install Gentoo** with KDE Plasma + NVIDIA drivers
3. **Configure SSH** for remote access
4. **Test shared folders** for file transfer
5. **Optimize performance** based on your needs

## 📞 **Support**

If you encounter issues:
1. Check the troubleshooting section above
2. Verify your QEMU and KVM installation
3. Check system logs for errors
4. Try different networking options
5. Ensure NVIDIA drivers are working on host

---

**Happy Gentoo testing! 🐧✨**

