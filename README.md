Of course. Based on all the recent fixes and feature enhancements, I have updated your `README.md`.

The new version is more comprehensive, highlights the latest security and reliability improvements, and provides clearer instructions for the user.

Here is the updated `README.md`:

-----

## About Gentoo Easy Install

This project is a fork of [oddlama/gentoo-install](https://github.com/oddlama/gentoo-install) with enhanced features and additional functionality. It aspires to be your favourite way to install Gentoo. It aims to provide a smooth, reliable, and secure installation experience for both beginners and experts. You may configure it by using a menuconfig-inspired interface or simply via a config file.

It supports common disk layouts, various file systems like ext4, ZFS, and Btrfs, and additional layers such as LUKS encryption and mdraid. It robustly supports both **EFI (recommended)** and **BIOS** boot, and can be used with **systemd** or **OpenRC** as the init system.

## Features

  * **User-Friendly TUI**: An easy-to-use terminal interface to configure every aspect of your installation.
  * **Flexible Disk Configuration**: Support for various partitioning schemes including LUKS encryption, software RAID (RAID 0/1), LVM, Btrfs-RAID, and ZFS.
  * **Modern Bootloader Support**: Full support for GRUB, systemd-boot, and direct EFI Stub booting, with automatic detection for UEFI and Secure Boot.
  * **Desktop Environment Support**: Automated installation for popular desktop environments like KDE Plasma, GNOME, XFCE, and more, with optimized configurations.
  * **Enhanced KDE Plasma Integration**: Automatic setup of optimal USE flags, KWallet PAM auto-unlocking, and Polkit rules for a seamless experience.
  * **Secure by Default**: Includes options for a hardened SSH configuration, interactive password setting (no plaintext passwords in config), and secure system defaults.
  * **Automated and Repeatable**: Create a configuration once and use it for consistent, automated installations.
  * **Robust Error Handling & Cleanup**: The installer can now automatically clean up the environment after an interruption (Ctrl+C) to prevent leaving a broken state.

## Usage

First, boot into a live environment of your choice. An [Arch Linux](https://www.archlinux.org/download/) live ISO is recommended, as it allows the installer to automatically download required programs on the fly.

```bash
# In your live environment, install git if needed:
# pacman -Sy git (Arch Linux)

# Clone the repository
git clone "https://github.com/firesand/Gentoo-easy-install"
cd Gentoo-easy-install

# Configure the installation to your liking and save it
./configure

# Begin the installation
./install
```

Every option is explained in detail in `gentoo.conf.example` and in the help menus of the TUI configurator. When installing, you will be asked to review the partitioning scheme before any changes are made to your disks.

## Overview of Installation Steps

1.  **Partition Disks**: Partitions and formats disks according to your chosen layout.
2.  **Download and Extract Stage3**: Fetches and cryptographically verifies the official Gentoo Stage3 tarball.
3.  **Chroot and Configure Portage**: Enters the new environment, syncs the Portage tree, and selects the fastest mirrors.
4.  **Base System Configuration**: Sets up hostname, timezone, keymap, and locales.
5.  **Install Core Packages**: Installs essential packages like the kernel, system tools, and drivers.
6.  **Install Desktop Environment** (Optional): Installs and configures your chosen DE.
7.  **Make System Bootable**: Generates `fstab`, builds the `initramfs`, and installs the bootloader.
8.  **Finalize**: Sets the root password, creates a user account, and installs optional packages.

### Secure User Account Creation

The installer now handles user passwords securely:

  * **No Plaintext Passwords**: The `CREATE_USER_PASSWORD` variable has been removed from the configuration to prevent storing passwords in plaintext.
  * **Interactive by Default**: During installation, you will be prompted to enter a password for the new user.
  * **Random Password Generation** (Optional): You can choose to have a secure, random password generated for the new user, which will be displayed once upon completion.

### Enhanced Bootloader Configuration

The installer provides intelligent bootloader configuration following Gentoo Handbook best practices:

  * **Bootloader Options**: Choose between **GRUB**, **systemd-boot**, or minimalist **EFI Stub** booting.
  * **Platform Detection**: Automatically detects UEFI vs. BIOS systems and applies the correct installation method.
  * **Secure Boot Awareness**: Detects if Secure Boot is enabled and provides guidance and optional `shim` installation for compatibility.
  * **Advanced GRUB Configuration**: Easily configure custom kernel parameters, dual-boot detection with `os-prober`, and performance-tuning boot flags.

### KDE Plasma Enhanced Integration

When installing KDE Plasma, the installer provides enhanced integration features:

  * **Optimal USE Flags**: Automatically configures critical USE flags for NetworkManager, SDDM, and KWallet.
  * **KWallet Auto-Unlocking**: Configures PAM for automatic KWallet unlocking via SDDM login.
  * **User Authentication**: Sets up Polkit rules to allow users in the `wheel` group to authenticate for system operations.

## Updating the Kernel

By default, the system uses `sys-kernel/gentoo-kernel-bin`. To update your kernel:

1.  Emerge the new kernel package.
2.  Run `eselect kernel set <new-kernel-version>`.
3.  Backup your old kernel and initramfs (e.g., `mv /boot/efi/vmlinuz.efi /boot/efi/vmlinuz.efi.bak`).
4.  Generate a new initramfs using the provided convenience script: `  /boot/efi/generate_initramfs.sh <new-kernel-version> /boot/efi/initramfs.img `.
5.  Copy the new kernel to the correct location (e.g., `cp /boot/vmlinuz-<version> /boot/efi/vmlinuz.efi`).

## Troubleshooting and FAQ

  * **Installation Fails**: The script will prompt you to drop into an emergency shell to fix issues. Most commands can be retried without restarting the entire process.
  * **`blkid` Errors After Partitioning**: Ensure all devices are unmounted before starting. Use `wipefs -a <device>` to clear old filesystem signatures if problems persist.
  * **Chrooting After a Failed Install**: If you need to fix the installed system, mount your root partition under `/mnt` and run `./install --chroot /mnt`.

## Attribution

This project is a fork of [oddlama/gentoo-install](https://github.com/oddlama/gentoo-install) with additional enhancements:

  * **Performance Optimization**: Advanced display backend testing and GPU optimization.
  * **Extended Documentation**: Detailed guides for various use cases.
  * **Additional Scripts**: Device management, storage management, and more.

Original project by [oddlama](https://github.com/oddlama) - thank you for the excellent foundation\!
