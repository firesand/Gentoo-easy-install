# 🐧 Gentoo VM Testing Tools

## 🚀 **Unified VM Launcher (Recommended)**

**`gentoo-vm-launcher.sh`** - One script to rule them all!

### **Features**
- 🎯 **Auto-detection** of your environment (NVIDIA, Wayland, root privileges)
- 🖥️ **TUI Interface** for easy configuration
- 🌐 **Smart networking** (bridge vs user networking)
- 🎮 **NVIDIA + Wayland optimization** built-in
- 📱 **SSH access** with automatic port forwarding
- ⚡ **Performance optimization** based on your setup

### **Quick Start**
```bash
# Interactive TUI mode
./tests/gentoo-vm-launcher.sh

# Auto-start with ISO
./tests/gentoo-vm-launcher.sh --cdrom gentoo.iso --auto-start

# Custom configuration
./tests/gentoo-vm-launcher.sh --cdrom gentoo.iso --ram 8G --cores 4
```

### **TUI Menu Options**
1. **Configure VM Settings** - RAM, CPU, storage, name
2. **Select ISO File** - Browse or enter path
3. **Configure Network** - Bridge or user networking
4. **Configure Display** - GTK, SPICE, SDL, or auto
5. **Show SSH Connection Info** - Connection details and setup
6. **Start VM (Auto-optimized)** - Smart configuration
7. **Start VM (Custom Configuration)** - Manual settings
8. **Reset Configuration** - Back to defaults
9. **Help & Troubleshooting** - Common issues and solutions
0. **Exit** - Close the launcher

## 🔧 **Legacy Scripts (Deprecated)**

> ⚠️ **These scripts are kept for reference but are no longer recommended.**

- `start-gentoo-vm.sh` - Basic launcher (limited features)
- `start-gentoo-vm-ide.sh` - IDE storage compatibility version
- `start-gentoo-vm-nvidia-wayland.sh` - Bridge networking version
- `start-gentoo-vm-ssh.sh` - User networking with SSH

## 🎯 **Why the Unified Approach?**

### **Before (Multiple Scripts)**
- ❌ Confusing - which script to use?
- ❌ Duplicate code - maintenance nightmare
- ❌ No auto-detection - manual configuration needed
- ❌ Limited flexibility - fixed configurations

### **After (Unified Script)**
- ✅ **One script** - clear choice
- ✅ **Auto-detection** - works out of the box
- ✅ **TUI interface** - user-friendly configuration
- ✅ **Smart defaults** - optimized for your environment
- ✅ **Flexible** - command-line or interactive mode

## 🌟 **Environment Auto-Detection**

The unified launcher automatically detects:

- **Root privileges** → Bridge networking if available
- **Wayland vs X11** → Optimal display settings
- **NVIDIA GPU** → Best graphics compatibility
- **KVM support** → Performance optimization
- **QEMU installation** → Dependency checking

## 🚀 **Usage Examples**

### **1. Quick Start (Recommended)**
```bash
./tests/gentoo-vm-launcher.sh
# Then use the TUI to configure and start
```

### **2. Auto-start with ISO**
```bash
./tests/gentoo-vm-launcher.sh --cdrom /path/to/gentoo.iso --auto-start
```

### **3. Custom Configuration**
```bash
./tests/gentoo-vm-launcher.sh \
  --cdrom /path/to/gentoo.iso \
  --ram 8G \
  --cores 4 \
  --storage 256G \
  --ssh-port 2222
```

### **4. Headless Mode (SSH only)**
```bash
# Start VM with TUI
./tests/gentoo-vm-launcher.sh

# Configure network for SSH
# Select option 3 (Configure Network)
# Choose user networking with SSH forwarding

# Start VM
# Select option 6 (Start VM)

# From another terminal, SSH to VM
ssh -p 2222 root@localhost
```

## 🔍 **Troubleshooting**

### **Common Issues**
1. **Permission denied** → Use `--auto-start` or configure network manually
2. **Display issues** → Try different display options in TUI
3. **Network problems** → Check port availability and firewall settings
4. **Performance issues** → Use bridge networking if root available

### **Getting Help**
- Use option 9 in the TUI for help
- Check the `NVIDIA-WAYLAND-GUIDE.md` for detailed information
- Run with `--help` for command-line options

## 📚 **Documentation**

- **`gentoo-vm-launcher.sh`** - This unified launcher
- **`NVIDIA-WAYLAND-GUIDE.md`** - Detailed guide for NVIDIA + Wayland users
- **`QEMU-README.md`** - QEMU configuration details

## 🎉 **Migration Guide**

If you were using the old scripts:

1. **Replace all script calls** with `./tests/gentoo-vm-launcher.sh`
2. **Use the TUI** to configure your preferred settings
3. **Save your configuration** by noting the settings
4. **Use `--auto-start`** for quick launches

---

**🎯 One script, infinite possibilities! 🐧✨**

