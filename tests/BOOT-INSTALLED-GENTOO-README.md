# 🐧 Boot Installed Gentoo VM

This guide explains how to boot your already installed Gentoo system from the existing VM storage using QEMU.

## 🎯 **What This Does**

- **Boots from existing disk**: No ISO needed - boots directly from your installed Gentoo system
- **Uses your VM storage**: `/home/edo/vm-disks/Gentoo_TUI.qcow2`
- **Optimized performance**: KVM acceleration, virtio devices, host CPU passthrough
- **Easy SSH access**: Port forwarding to localhost:2223
- **Shared folder**: Access files between host and VM

## 🚀 **Quick Start**

### **Option 1: Use the Script (Recommended)**
```bash
cd tests
./boot-installed-gentoo.sh
```

### **Option 2: Manual QEMU Command**
```bash
# Copy arguments from qemu-gentoo-installed.conf
qemu-system-x86_64 [arguments from config file]
```

## 📋 **VM Configuration**

- **Name**: Gentoo_TUI
- **RAM**: 16GB
- **CPU**: 8 cores (host CPU passthrough)
- **Storage**: `/home/edo/vm-disks/Gentoo_TUI.qcow2`
- **Network**: User networking with SSH port 2223
- **Graphics**: GTK display with virtio-gpu
- **Boot**: From disk (`-boot c`)

## 🔧 **Script Options**

```bash
./boot-installed-gentoo.sh           # Start VM
./boot-installed-gentoo.sh --help    # Show help
./boot-installed-gentoo.sh --config  # Show configuration
```

## 📱 **SSH Access**

Once the VM is running, you can SSH into it:
```bash
ssh -p 2223 root@localhost
```

## 📁 **Shared Folder**

The script creates a shared folder at `/home/edo/vm-shared/Gentoo_TUI` that's accessible from both host and VM.

**Inside the VM**, mount it with:
```bash
mkdir -p /mnt/shared
mount -t virtiofs shared /mnt/shared
```

## ⚠️ **Important Notes**

1. **No ISO needed**: The `-boot c` option tells QEMU to boot from the first hard disk
2. **Existing installation**: This assumes you have a working Gentoo installation on the disk
3. **Storage path**: Make sure the disk path `/home/edo/vm-disks/Gentoo_TUI.qcow2` exists
4. **KVM support**: For best performance, ensure KVM is available on your system

## 🆘 **Troubleshooting**

### **VM won't start**
- Check if QEMU is installed: `which qemu-system-x86_64`
- Verify disk exists: `ls -la /home/edo/vm-disks/Gentoo_TUI.qcow2`
- Check KVM: `lsmod | grep kvm`

### **Can't SSH in**
- Ensure SSH service is running in the VM: `rc-service sshd status`
- Check if port 2223 is available on host: `netstat -tlnp | grep 2223`

### **Performance issues**
- Verify KVM is working: `dmesg | grep kvm`
- Check CPU virtualization support: `cat /proc/cpuinfo | grep flags | grep -i vmx`

## 🔄 **Starting/Stopping**

- **Start**: Run the script or QEMU command
- **Stop**: Press `Ctrl+C` in the terminal running QEMU
- **Restart**: Run the script again

## 📚 **Related Files**

- `boot-installed-gentoo.sh` - Main script for booting installed Gentoo
- `qemu-gentoo-installed.conf` - QEMU command line arguments
- `gentoo-vm-launcher.sh` - Full-featured VM launcher with ISO support
- `enhanced-vm-launcher.sh` - Advanced VM configuration options



