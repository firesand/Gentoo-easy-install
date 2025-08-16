# 🔗 SSH Setup Guide for Gentoo VM

## 🚀 **Quick Start: Get SSH Working in 3 Steps**

### **Step 1: Start the VM**
```bash
# Use the unified launcher
./tests/gentoo-vm-launcher.sh --cdrom /path/to/gentoo.iso --auto-start

# Or use interactive mode
./tests/gentoo-vm-launcher.sh
# Then select option 2 (Select ISO), then option 6 (Start VM)
```

### **Step 2: Install SSH Inside the VM**
Once the VM is running and you're at the Gentoo installation prompt:

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

### **Step 3: Connect from Host**
From another terminal on your host system:

```bash
# Connect via SSH (port 2223)
ssh -p 2223 root@localhost

# If you changed the SSH port, use that instead
ssh -p YOUR_PORT root@localhost
```

## 🔍 **Troubleshooting SSH Connection**

### **"Connection Refused" Error**

#### **Check 1: Is the VM Running?**
```bash
ps aux | grep qemu
```
You should see a QEMU process running.

#### **Check 2: Is SSH Service Running in VM?**
Inside the VM, check:
```bash
# Check if SSH service is running
/etc/init.d/sshd status

# If not running, start it
/etc/init.d/sshd start

# Check if port 22 is listening
netstat -tuln | grep :22
```

#### **Check 3: Is Port Forwarding Working?**
On your host system:
```bash
# Check if the forwarded port is listening
ss -tuln | grep :2223

# You should see something like:
# tcp   LISTEN 0      1            0.0.0.0:2223       0.0.0.0:*
```

#### **Check 4: Firewall Issues**
If you have a firewall, make sure port 2223 is allowed:
```bash
# Check firewall status
sudo ufw status
# or
sudo iptables -L
```

## 🌐 **Network Configuration Details**

### **Port Forwarding Setup**
The unified launcher automatically sets up port forwarding:
- **Host Port**: 2223 (configurable)
- **VM Port**: 22 (SSH)
- **Forwarding**: `tcp::2223-:22`

### **VM Network Configuration**
- **VM IP**: 10.0.2.15 (QEMU default)
- **Gateway**: 10.0.2.2
- **DNS**: 10.0.2.3
- **Host Access**: 10.0.2.2

## 🛠️ **Advanced SSH Configuration**

### **SSH Key Authentication (Recommended)**
```bash
# Generate SSH key on host (if you don't have one)
ssh-keygen -t rsa -b 4096

# Copy key to VM
ssh-copy-id -p 2223 root@localhost

# Test key-based login
ssh -p 2223 root@localhost
```

### **SSH Config File**
Create `~/.ssh/config` on your host:
```
Host gentoo-vm
    HostName localhost
    Port 2223
    User root
    IdentityFile ~/.ssh/id_rsa
```

Then connect simply with:
```bash
ssh gentoo-vm
```

### **Custom SSH Port**
To change the SSH port:
```bash
# Use the TUI launcher
./tests/gentoo-vm-launcher.sh

# Select option 3 (Configure Network)
# Choose user networking
# Set custom SSH port (e.g., 2224)

# Or use command line
./tests/gentoo-vm-launcher.sh --ssh-port 2224 --cdrom iso --auto-start
```

## 📱 **SSH Commands Inside VM**

### **SSH Service Management**
```bash
# Start SSH service
/etc/init.d/sshd start

# Stop SSH service
/etc/init.d/sshd stop

# Restart SSH service
/etc/init.d/sshd restart

# Check SSH service status
/etc/init.d/sshd status

# Enable SSH at boot
rc-update add sshd default

# Disable SSH at boot
rc-update del sshd default
```

### **SSH Configuration**
```bash
# Edit SSH config
nano /etc/ssh/sshd_config

# Common settings to change:
# PermitRootLogin yes
# PasswordAuthentication yes
# Port 22

# Restart SSH after config changes
/etc/init.d/sshd restart
```

## 🔧 **Common Issues & Solutions**

### **Issue: "Permission denied (publickey)"**
**Solution**: Enable password authentication in `/etc/ssh/sshd_config`:
```
PasswordAuthentication yes
PermitRootLogin yes
```

### **Issue: "Connection timed out"**
**Solution**: Check if VM is running and port forwarding is working.

### **Issue: "No route to host"**
**Solution**: VM network is not properly configured. Restart the VM.

### **Issue: "Address already in use"**
**Solution**: Port 2223 is already in use. Change to a different port.

## 🎯 **Quick Commands Reference**

```bash
# Start VM with auto-start
./tests/gentoo-vm-launcher.sh --cdrom iso --auto-start

# Check VM status
ps aux | grep qemu

# Check SSH port
ss -tuln | grep :2223

# Connect via SSH
ssh -p 2223 root@localhost

# Stop all VMs
pkill -f "qemu-system-x86_64"
```

## 🚀 **Next Steps After SSH is Working**

1. **File Transfer**: Use `scp` or `rsync` to copy files
2. **Port Forwarding**: Forward additional ports if needed
3. **Shared Folder**: Mount the shared folder in the VM
4. **Development**: Use SSH for remote development

---

**🎉 Happy SSH-ing! 🐧✨**

