# Automatic Stage 3 Selection Based on Desktop Environment

## 🎯 **Overview**

The installer now automatically selects the most appropriate Stage 3 tarball based on your desktop environment choice. This ensures optimal performance and faster setup for desktop systems.

## 🔄 **How It Works**

### **When Desktop Environment is Selected:**
- **Desktop Profile Stage 3** is automatically downloaded
- **Pre-configured** for desktop usage
- **Optimized USE flags** for desktop environments
- **Faster installation** with less manual configuration

### **When No Desktop Environment is Selected:**
- **Standard Stage 3** is used (existing behavior)
- **Minimal base system** suitable for servers/CLI
- **Lightweight installation**

## 📦 **Stage 3 Types**

### **Desktop Profiles (When DE is selected):**

#### **For Systemd Systems:**
```
stage3-amd64-desktop-systemd-YYYYMMDDTHHMMSSZ.tar.xz
```
- **URL Example**: `https://distfiles.gentoo.org/releases/amd64/autobuilds/20250810T165238Z/stage3-amd64-desktop-systemd-20250810T165238Z.tar.xz`
- **Benefits**: Pre-configured for systemd + desktop environments

#### **For OpenRC Systems:**
```
stage3-amd64-desktop-openrc-YYYYMMDDTHHMMSSZ.tar.xz
```
- **URL Example**: `https://distfiles.gentoo.org/releases/amd64/autobuilds/20250810T165238Z/stage3-amd64-desktop-openrc-20250810T165238Z.tar.xz`
- **Benefits**: Pre-configured for OpenRC + desktop environments

### **Standard Profiles (When no DE is selected):**

#### **For Systemd Systems:**
```
stage3-amd64-systemd-YYYYMMDDTHHMMSSZ.tar.xz
```
- **URL Example**: `https://distfiles.gentoo.org/releases/amd64/autobuilds/20250810T165238Z/stage3-amd64-systemd-20250810T165238Z.tar.xz`

#### **For OpenRC Systems:**
```
stage3-amd64-openrc-YYYYMMDDTHHMMSSZ.tar.xz
```
- **URL Example**: `https://distfiles.gentoo.org/releases/amd64/autobuilds/20250810T165238Z/stage3-amd64-openrc-20250810T165238Z.tar.xz`

## 🖥️ **Desktop Environment Support**

The following desktop environments will trigger desktop profile Stage 3:

- **KDE Plasma** → `stage3-amd64-desktop-{systemd|openrc}`
- **GNOME** → `stage3-amd64-desktop-{systemd|openrc}`
- **XFCE** → `stage3-amd64-desktop-{systemd|openrc}`
- **Hyprland** → `stage3-amd64-desktop-{systemd|openrc}`
- **LXQt** → `stage3-amd64-desktop-{systemd|openrc}`
- **Cinnamon** → `stage3-amd64-desktop-{systemd|openrc}`
- **MATE** → `stage3-amd64-desktop-{systemd|openrc}`
- **Budgie** → `stage3-amd64-desktop-{systemd|openrc}`
- **i3** → `stage3-amd64-desktop-{systemd|openrc}`
- **Sway** → `stage3-amd64-desktop-{systemd|openrc}`
- **Openbox** → `stage3-amd64-desktop-{systemd|openrc}`
- **Fluxbox** → `stage3-amd64-desktop-{systemd|openrc}`
- **Enlightenment** → `stage3-amd64-desktop-{systemd|openrc}`
- **Pantheon** → `stage3-amd64-desktop-{systemd|openrc}`

## ✅ **Benefits of Desktop Profile Stage 3**

### **1. Pre-configured USE Flags**
- **Optimized** for desktop usage
- **Common desktop packages** pre-enabled
- **Reduced compilation time** for desktop applications

### **2. Faster Setup**
- **Less manual configuration** needed
- **Desktop-specific optimizations** already applied
- **Better performance** out of the box

### **3. Reduced Errors**
- **Tested configurations** for desktop environments
- **Known working combinations** of USE flags
- **Less dependency conflicts**

## 🚀 **How to Use**

### **1. Configure Desktop Environment:**
```bash
./configure
```
- Select your desired desktop environment
- Choose init system (systemd or OpenRC)
- Configure other settings

### **2. Run Installer:**
```bash
./install
```

### **3. Automatic Selection:**
The installer will automatically:
- **Detect** your desktop environment choice
- **Select** appropriate Stage 3 profile
- **Download** desktop profile if DE selected
- **Download** standard profile if no DE selected
- **Show** clear information about what's being downloaded

## 📊 **Example Output**

### **With Desktop Environment Selected:**
```
[+] Desktop environment selected: kde
[+] Will download desktop profile Stage 3 for better DE support
[+] Selected desktop profile: stage3-amd64-desktop-systemd
[+] === Stage 3 Selection Information ===
[+] Desktop Environment: kde
[+] Stage 3 Type: Desktop Profile (desktop-systemd)
[+] Benefits:
[+]   - Pre-configured USE flags for desktop environments
[+]   - Optimized for desktop usage
[+]   - Includes common desktop packages and configurations
[+]   - Faster desktop environment setup
[+] Architecture: amd64
[+] Init System: systemd
[+] =====================================
[+] Downloading stage3-amd64-desktop-systemd tarball
```

### **Without Desktop Environment:**
```
[+] No desktop environment selected, using standard Stage 3
[+] === Stage 3 Selection Information ===
[+] Desktop Environment: None (Server/CLI mode)
[+] Stage 3 Type: Standard Profile (standard)
[+] Benefits:
[+]   - Minimal base system
[+]   - Lightweight installation
[+]   - Suitable for servers and minimal systems
[+] Architecture: amd64
[+] Init System: systemd
[+] =====================================
[+] Downloading stage3-amd64-systemd tarball
```

## 🔧 **Technical Details**

### **Stage 3 Selection Logic:**
```bash
if [[ -n "$DESKTOP_ENVIRONMENT" ]]; then
    # Desktop profile Stage 3
    if [[ "$STAGE3_VARIANT" == *systemd* ]]; then
        STAGE3_BASENAME_FINAL="stage3-$GENTOO_ARCH-desktop-systemd"
    else
        STAGE3_BASENAME_FINAL="stage3-$GENTOO_ARCH-desktop-openrc"
    fi
else
    # Standard Stage 3 (existing logic)
    STAGE3_BASENAME_FINAL="$STAGE3_BASENAME"
fi
```

### **URL Construction:**
- **Base URL**: `https://distfiles.gentoo.org/releases/amd64/autobuilds/current-{STAGE3_BASENAME}/`
- **Automatic detection** of latest timestamp
- **Proper architecture** and variant selection

## 🎉 **Result**

Your Gentoo installation will now automatically use the **optimal Stage 3** for your use case:

- **Desktop users** get pre-optimized desktop profiles
- **Server users** get minimal standard profiles
- **No manual Stage 3 selection** needed
- **Better performance** and faster setup
- **Reduced configuration errors**

This feature ensures that every user gets the best possible starting point for their Gentoo system! 🚀
