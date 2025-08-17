# shellcheck source=./scripts/protection.sh
source "$GENTOO_INSTALL_REPO_DIR/scripts/protection.sh" || exit 1

# shellcheck source=./scripts/desktop_environments.sh
source "$GENTOO_INSTALL_REPO_DIR/scripts/desktop_environments.sh" || exit 1

# Proactively initialize config arrays to prevent "unbound variable" errors
# with older config files when using 'set -u'.
# The ':=()' syntax assigns an empty array only if the variable is unset.
: "${ADDITIONAL_PACKAGES:=()}"
: "${DESKTOP_ADDITIONAL_PACKAGES:=()}"
: "${GRUB_CUSTOM_PARAMS:=()}"
: "${PACKAGE_USE_RULES:=()}"
: "${PACKAGE_KEYWORDS:=()}"
: "${OVERLAY_NAMES:=()}"
: "${HYPRLAND_CONFIG:=}" # For string variables, use := ""

# IMPORTANT: NetworkManager and dhcpcd service conflicts are handled in configure_openrc()
# Only one network management service should run at a time to avoid unpredictable results

# GCC COMPATIBILITY: The ensure_gcc_compatibility() function automatically handles
# compiler version requirements for packages like Hyprland (GCC 15+)
# This prevents installation failures due to outdated Stage3 tarball compilers


################################################
# Functions

function install_stage3() {
	prepare_installation_environment
	apply_disk_configuration
	download_stage3
	extract_stage3
}

function configure_base_system() {
	if [[ $MUSL == "true" ]]; then
		einfo "Installing musl-locales"
		try emerge --verbose sys-apps/musl-locales
		echo 'MUSL_LOCPATH="/usr/share/i18n/locales/musl"' >> /etc/env.d/00local \
			|| die "Could not write to /etc/env.d/00local"
	else
		einfo "Generating locales"
		echo "$LOCALES" > /etc/locale.gen \
			|| die "Could not write /etc/locale.gen"
		locale-gen \
			|| die "Could not generate locales"
	fi

	if [[ $SYSTEMD == "true" ]]; then
		einfo "Setting machine-id"
		systemd-machine-id-setup \
			|| die "Could not setup systemd machine id"

		# Set hostname
		einfo "Selecting hostname"
		echo "$HOSTNAME" > /etc/hostname \
			|| die "Could not write /etc/hostname"

		# Set keymap
		einfo "Selecting keymap"
		echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf \
			|| die "Could not write /etc/vconsole.conf"

		# Set locale
		einfo "Selecting locale"
		echo "LANG=$LOCALE" > /etc/locale.conf \
			|| die "Could not write /etc/locale.conf"

		einfo "Selecting timezone"
		ln -sfn "../usr/share/zoneinfo/$TIMEZONE" /etc/localtime \
			|| die "Could not change /etc/localtime link"
	else
		# Set hostname
		einfo "Selecting hostname"
		sed -i "/hostname=/c\\hostname=\"$HOSTNAME\"" /etc/conf.d/hostname \
			|| die "Could not sed replace in /etc/conf.d/hostname"

		# Set timezone
		if [[ $MUSL == "true" ]]; then
			try emerge -v sys-libs/timezone-data
			einfo "Selecting timezone"
			echo -e "TZ=\"$TIMEZONE\"" >> /etc/env.d/00local \
				|| die "Could not write to /etc/env.d/00local"
		else
			einfo "Selecting timezone"
			echo "$TIMEZONE" > /etc/timezone \
				|| die "Could not write /etc/timezone"
			chmod 644 /etc/timezone \
				|| die "Could not set correct permissions for /etc/timezone"
			try emerge -v --config sys-libs/timezone-data
		fi

		# Set keymap
		einfo "Selecting keymap"
		sed -i "/keymap=/c\\keymap=\"$KEYMAP\"" /etc/conf.d/keymaps \
			|| die "Could not sed replace in /etc/conf.d/keymaps"

		# Set locale
		einfo "Selecting locale"
		try eselect locale set "$LOCALE"
	fi

	# Update environment
	env_update
	
	# Add essential system information
	einfo "Setting up essential system information"
	
	# Set up /etc/hosts with localhost entries
	einfo "Configuring /etc/hosts"
	echo "127.0.0.1 localhost" >> /etc/hosts
	echo "::1 localhost" >> /etc/hosts
	echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
	
	# Set secure umask for better security
	einfo "Setting secure umask"
	echo "umask 077" >> /etc/profile
	
	# Add system information to environment
	einfo "Setting system environment variables"
	echo "HOSTNAME=\"$HOSTNAME\"" >> /etc/env.d/99hostname
	echo "TIMEZONE=\"$TIMEZONE\"" >> /etc/env.d/99timezone
}

function configure_portage() {
	# Prepare /etc/portage for autounmask
	mkdir_or_die 0755 "/etc/portage/package.use"
	touch_or_die 0644 "/etc/portage/package.use/zz-autounmask"
	mkdir_or_die 0755 "/etc/portage/package.keywords"
	touch_or_die 0644 "/etc/portage/package.keywords/zz-autounmask"
	touch_or_die 0644 "/etc/portage/package.license"

	if [[ $SELECT_MIRRORS == "true" ]]; then
		einfo "Temporarily installing mirrorselect"
		try emerge --verbose --oneshot app-portage/mirrorselect

		einfo "Selecting fastest portage mirrors"
		mirrorselect_params=("-s" "4" "-b" "10")
		[[ $SELECT_MIRRORS_LARGE_FILE == "true" ]] \
			&& mirrorselect_params+=("-D")
		try mirrorselect "${mirrorselect_params[@]}"
	fi

	if [[ $ENABLE_BINPKG == "true" ]]; then
		echo 'FEATURES="getbinpkg binpkg-request-signature"' >> /etc/portage/make.conf
		getuto
		chmod 644 /etc/portage/gnupg/pubring.kbx
	fi

	# Configure bleeding edge testing if enabled
	if [[ "${USE_PORTAGE_TESTING:-false}" == "true" ]]; then
		einfo "Enabling bleeding edge testing for architecture: $GENTOO_ARCH"
		echo "ACCEPT_KEYWORDS=\"~$GENTOO_ARCH\"" >> /etc/portage/make.conf
		einfo "Added ACCEPT_KEYWORDS=\"~$GENTOO_ARCH\" to /etc/portage/make.conf"
		einfo "Note: This enables testing branch packages which may be less stable"
		einfo "You can disable this later by removing the ACCEPT_KEYWORDS line from /etc/portage/make.conf"
	else
		einfo "Using stable branch packages (default)"
		einfo "To enable testing branch later, add ACCEPT_KEYWORDS=\"~$GENTOO_ARCH\" to /etc/portage/make.conf"
	fi

	chmod 644 /etc/portage/make.conf \
		|| die "Could not chmod 644 /etc/portage/make.conf"
	
	# Verify Portage configuration
	verify_portage_configuration
}

function verify_portage_configuration() {
	einfo "Verifying Portage configuration"
	
	# Check if make.conf exists and is readable
	if [[ ! -f /etc/portage/make.conf ]]; then
		ewarn "Warning: /etc/portage/make.conf not found"
		return 1
	fi
	
	# Check ACCEPT_KEYWORDS setting
	if [[ "${USE_PORTAGE_TESTING:-false}" == "true" ]]; then
		if grep -q "ACCEPT_KEYWORDS.*~$GENTOO_ARCH" /etc/portage/make.conf; then
			einfo "✓ ACCEPT_KEYWORDS=\"~$GENTOO_ARCH\" is properly configured"
			einfo "  Testing branch packages are enabled for $GENTOO_ARCH"
		else
			ewarn "Warning: ACCEPT_KEYWORDS setting not found in /etc/portage/make.conf"
			ewarn "Bleeding edge testing may not be enabled"
		fi
	else
		if grep -q "ACCEPT_KEYWORDS.*~$GENTOO_ARCH" /etc/portage/make.conf; then
			ewarn "Warning: ACCEPT_KEYWORDS=\"~$GENTOO_ARCH\" found but USE_PORTAGE_TESTING is false"
			ewarn "This may indicate a configuration inconsistency"
		else
			einfo "✓ Stable branch packages are configured (default)"
		fi
	fi
	
	# Check binary package configuration if enabled
	if [[ "${ENABLE_BINPKG:-false}" == "true" ]]; then
		if grep -q 'FEATURES.*getbinpkg' /etc/portage/make.conf; then
			einfo "✓ Binary package support is properly configured"
		else
			ewarn "Warning: Binary package support may not be properly configured"
		fi
	fi
	
	einfo "Portage configuration verification completed"
}

function enable_sshd() {
	einfo "Installing and enabling sshd"
	install -m0600 -o root -g root "$GENTOO_INSTALL_REPO_DIR/contrib/sshd_config" /etc/ssh/sshd_config \
		|| die "Could not install /etc/ssh/sshd_config"
	enable_service sshd
}

function install_authorized_keys() {
	mkdir_or_die 0700 "/root/"
	mkdir_or_die 0700 "/root/.ssh"

	if [[ -n "$ROOT_SSH_AUTHORIZED_KEYS" ]]; then
		einfo "Adding authorized keys for root"
		touch_or_die 0600 "/root/.ssh/authorized_keys"
		echo "$ROOT_SSH_AUTHORIZED_KEYS" > "/root/.ssh/authorized_keys" \
			|| die "Could not add ssh key to /root/.ssh/authorized_keys"
	fi
}

function generate_initramfs() {
	local output="$1"

	# Generate initramfs
	einfo "Generating initramfs"

	# Determine required dracut and kernel modules based on system configuration
	local dracut_modules=("bash")  # bash is always a dracut module
	local kernel_drivers=()
	
	# Populate dracut modules (scripts, tools)
	[[ $USED_RAID == "true" ]] && dracut_modules+=("mdraid")
	[[ $USED_LUKS == "true" ]] && dracut_modules+=("crypt" "crypt-gpg")
	[[ $USED_ZFS == "true" ]] && dracut_modules+=("zfs")
	
	# Populate kernel drivers (filesystem support)
	[[ $USED_BTRFS == "true" ]] && kernel_drivers+=("btrfs")

	local kver
	kver="$(readlink /usr/src/linux)" \
		|| die "Could not figure out kernel version from /usr/src/linux symlink."
	kver="${kver#linux-}"

	dracut_opts=()
	if [[ $SYSTEMD == "true" && $SYSTEMD_INITRAMFS_SSHD == "true" ]]; then
		cd /tmp || die "Could not change into /tmp"
		try git clone https://github.com/gsauthof/dracut-sshd
		try cp -r dracut-sshd/46sshd /usr/lib/dracut/modules.d
		sed -e 's/^Type=notify/Type=simple/' \
			-e 's@^\(ExecStart=/usr/sbin/sshd\) -D@\1 -e -D@' \
			-i /usr/lib/dracut/modules.d/46sshd/sshd.service \
			|| die "Could not replace sshd options in service file"
		dracut_opts+=("--install" "/etc/systemd/network/20-wired.network")
		dracut_modules+=("systemd-networkd")
	fi

	# Generate initramfs with proper module separation
	einfo "Using Dracut modules: ${dracut_modules[*]}"
	einfo "Using Kernel drivers: ${kernel_drivers[*]}"
	
	try dracut \
		--kver          "$kver" \
		--zstd \
		--no-hostonly \
		--ro-mnt \
		--add           "${dracut_modules[*]}" \
		--add-drivers   "${kernel_drivers[*]}" \
		"${dracut_opts[@]}" \
		--force \
		"$output"

	# Create script to repeat initramfs generation
	cat > "$(dirname "$output")/generate_initramfs.sh" <<EOF
#!/bin/bash
kver="\$1"
output="\$2" # At setup time, this was "$output"
[[ -n "\$kver" ]] || { echo "usage: \$0 <kernel_version> <output>" >&2; exit 1; }

	# Dracut modules and drivers are hardcoded from the installation environment
	# This ensures the script works regardless of the user's current shell environment
	dracut_modules=(${dracut_modules[*]})
	kernel_drivers=(${kernel_drivers[*]})

dracut \\
	--kver          "\$kver" \\
	--zstd \\
	--no-hostonly \\
	--ro-mnt \\
	--add           "\${dracut_modules[*]}" \\
	--add-drivers   "\${kernel_drivers[*]}" \\
	--force \\
	"\$output"
EOF
}

function get_cmdline() {
	local cmdline=("rd.vconsole.keymap=$KEYMAP_INITRAMFS")
	cmdline+=("${DISK_DRACUT_CMDLINE[@]}")

	if [[ $USED_ZFS != "true" ]]; then
		cmdline+=("root=UUID=$(get_blkid_uuid_for_id "$DISK_ID_ROOT")")
	fi

	echo -n "${cmdline[*]}"
}

function install_kernel_efi() {
	try emerge --verbose sys-boot/efibootmgr

	# Copy kernel to EFI
	local kernel_file
	kernel_file="$(find "/boot" \( -name "vmlinuz-*" -or -name 'kernel-*' \) -printf '%f\n' | sort -V | tail -n 1)" \
		|| die "Could not list newest kernel file"

	try cp "/boot/$kernel_file" "/boot/efi/vmlinuz.efi"

	# Generate initramfs
	generate_initramfs "/boot/efi/initramfs.img"

	# Create boot entry
	einfo "Creating EFI boot entry"
	local efipartdev
	efipartdev="$(resolve_device_by_id "$DISK_ID_EFI")" \
		|| die "Could not resolve device with id=$DISK_ID_EFI"
	efipartdev="$(realpath "$efipartdev")" \
		|| die "Error in realpath '$efipartdev'"

	# Get the sysfs path to EFI partition
	local sys_efipart
	sys_efipart="/sys/class/block/$(basename "$efipartdev")" \
		|| die "Could not construct /sys path to EFI partition"

	# Extract partition number, handling both standard and RAID cases
	local efipartnum
	if [[ -e "$sys_efipart/partition" ]]; then
		efipartnum="$(cat "$sys_efipart/partition")" \
			|| die "Failed to find partition number for EFI partition $efipartdev"
	else
		efipartnum="1" # Assume partition 1 if not found, common for RAID-based EFI
		einfo "Assuming partition 1 for RAID-based EFI on device $efipartdev"
	fi

	# Identify the parent block device and create EFI boot entry
	local gptdev
	if mdadm --detail --scan "$efipartdev" | grep -qE "^ARRAY $efipartdev " && [[ "$efipartdev" =~ ^/dev/md[0-9]+$ ]]; then
		# RAID 1 case: Create EFI boot entries for each RAID member
		local raid_members
		raid_members=($(mdadm --detail "$efipartdev" | sed -n 's|.*active sync[^/]*\(/dev/[^ ]*\).*|\1|p' | sort))

		if [[ -v raid_members && ${#raid_members[@]} -eq 0 ]]; then
			die "RAID setup detected, but no valid member disks found for $efipartdev"
		fi

		einfo "RAID detected. RAID members: ${raid_members[*]}"

		for disk in "${raid_members[@]}"; do
			gptdev="$disk"
			einfo "Adding EFI boot entry for RAID member: $gptdev"
			try efibootmgr --verbose --create --disk "$gptdev" --part "$efipartnum" --label "gentoo" --loader '\vmlinuz.efi' --unicode "initrd=\\initramfs.img $(get_cmdline)"
		done
	else
		# Non-RAID case: Create a single EFI boot entry
		gptdev="/dev/$(basename "$(readlink -f "$sys_efipart/..")")" \
			|| die "Failed to find parent device for EFI partition $efipartdev"
		if [[ ! -e "$gptdev" ]] || [[ -z "$gptdev" ]]; then
			gptdev="$(resolve_device_by_id "${DISK_ID_PART_TO_GPT_ID[$DISK_ID_EFI]}")" \
				|| die "Could not resolve device with id=${DISK_ID_PART_TO_GPT_ID[$DISK_ID_EFI]}"
		fi
		try efibootmgr --verbose --create --disk "$gptdev" --part "$efipartnum" --label "gentoo" --loader '\vmlinuz.efi' --unicode 'initrd=\initramfs.img'" $(get_cmdline)"
	fi

	# Create script to repeat adding efibootmgr entry
	cat > "/boot/efi/efibootmgr_add_entry.sh" <<EOF
#!/bin/bash
# This is the command that was used to create the efibootmgr entry when the
# system was installed using gentoo-install.
efibootmgr --verbose --create --disk "$gptdev" --part "$efipartnum" --label "gentoo" --loader '\\vmlinuz.efi' --unicode 'initrd=\\initramfs.img'" $(get_cmdline)"
EOF
}

function generate_syslinux_cfg() {
	cat <<EOF
DEFAULT gentoo
PROMPT 0
TIMEOUT 0

LABEL gentoo
	LINUX ../vmlinuz-current
	APPEND initrd=../initramfs.img $(get_cmdline)
EOF
}

function install_kernel_bios() {
	try emerge --verbose sys-boot/syslinux

	# Link kernel to known name
	local kernel_file
	kernel_file="$(find "/boot" \( -name "vmlinuz-*" -or -name 'kernel-*' \) -printf '%f\n' | sort -V | tail -n 1)" \
		|| die "Could not list newest kernel file"

	try cp "/boot/$kernel_file" "/boot/bios/vmlinuz-current"

	# Generate initramfs
	generate_initramfs "/boot/bios/initramfs.img"

	# Install syslinux
	einfo "Installing syslinux"
	local biosdev
	biosdev="$(resolve_device_by_id "$DISK_ID_BIOS")" \
		|| die "Could not resolve device with id=$DISK_ID_BIOS"
	mkdir_or_die 0700 "/boot/bios/syslinux"
	try syslinux --directory syslinux --install "$biosdev"

	# Create syslinux.cfg
	generate_syslinux_cfg > /boot/bios/syslinux/syslinux.cfg \
		|| die "Could save generated syslinux.cfg"

	# Install syslinux MBR record - SAFER APPROACH
	einfo "Installing syslinux MBR record using syslinux-install"
	local gptdev
	gptdev="$(resolve_device_by_id "${DISK_ID_PART_TO_GPT_ID[$DISK_ID_BIOS]}")" \
		|| die "Could not resolve device with id=${DISK_ID_PART_TO_GPT_ID[$DISK_ID_BIOS]}"
	
	# Use syslinux-install for safer MBR installation
	if command -v syslinux-install >/dev/null 2>&1; then
		einfo "Using syslinux-install for safe MBR installation"
		try syslinux-install -i "$gptdev" -m
	else
		# Fallback: Use dd but with additional safety checks
		einfo "syslinux-install not available, using dd with safety checks"
		
		# Verify the target device is actually a block device
		if [[ ! -b "$gptdev" ]]; then
			die "Target device $gptdev is not a block device"
		fi
		
		# Check if the device is mounted (dangerous to write to mounted devices)
		if mount | grep -q "$gptdev"; then
			die "Target device $gptdev is mounted - refusing to write MBR for safety"
		fi
		
		# Verify the syslinux MBR file exists
		if [[ ! -f "/usr/share/syslinux/gptmbr.bin" ]]; then
			die "syslinux MBR file /usr/share/syslinux/gptmbr.bin not found"
		fi
		
		# Use dd with safety measures
		einfo "Installing MBR to $gptdev (this operation modifies the disk)"
		try dd bs=440 conv=notrunc count=1 if=/usr/share/syslinux/gptmbr.bin of="$gptdev"
	fi
}

function install_kernel() {
	# Install vanilla kernel
	einfo "Installing vanilla kernel and related tools"

	# Choose kernel installation method based on bootloader type
	case "${BOOTLOADER_TYPE:-grub}" in
		"grub")
			if [[ $IS_EFI == "true" ]]; then
				install_kernel_efi
			else
				install_kernel_bios
			fi
			;;
		"systemd-boot")
			if [[ $IS_EFI == "true" ]]; then
				install_kernel_systemd_boot
			else
				die "systemd-boot requires UEFI system"
			fi
			;;
		"efistub")
			if [[ $IS_EFI == "true" ]]; then
				install_kernel_efi_stub
			else
				die "EFI Stub requires UEFI system"
			fi
			;;
		*)
			ewarn "Unknown bootloader type: ${BOOTLOADER_TYPE:-grub}, defaulting to GRUB"
			if [[ $IS_EFI == "true" ]]; then
				install_kernel_efi
			else
				install_kernel_bios
			fi
			;;
	esac

	einfo "Installing linux-firmware"
	echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" >> /etc/portage/package.license \
		|| die "Could not write to /etc/portage/package.license"
	try emerge --verbose linux-firmware
}

function install_kernel_systemd_boot() {
	einfo "Installing kernel for systemd-boot"
	
	# Install efibootmgr for UEFI boot entry management
	try emerge --verbose sys-boot/efibootmgr
	
	# Copy kernel to EFI System Partition
	local kernel_file
	kernel_file="$(find "/boot" \( -name "vmlinuz-*" -or -name 'kernel-*' \) -printf '%f\n' | sort -V | tail -n 1)" \
		|| die "Could not list newest kernel file"
	
	einfo "Found kernel: $kernel_file"
	
	# Create EFI directory structure if it doesn't exist
	mkdir -p /efi/EFI/Loader || die "Could not create EFI Loader directory"
	mkdir -p /efi/EFI/gentoo || die "Could not create EFI gentoo directory"
	
	# Copy kernel to EFI partition
	try cp "/boot/$kernel_file" "/efi/EFI/gentoo/vmlinuz-$(uname -r).efi"
	
	# Generate initramfs
	generate_initramfs "/efi/EFI/gentoo/initramfs-$(uname -r).img"
	
	# Create systemd-boot loader configuration
	einfo "Creating systemd-boot loader configuration"
	cat > /efi/EFI/Loader/loader.conf <<EOF
default gentoo
timeout 3
editor yes
EOF
	
	# Create kernel entry configuration
	einfo "Creating systemd-boot kernel entry"
	cat > "/efi/EFI/Loader/entries/gentoo.conf" <<EOF
title Gentoo Linux
linux /gentoo/vmlinuz-$(uname -r).efi
initrd /gentoo/initramfs-$(uname -r).img
options $(get_cmdline)
EOF
	
	einfo "systemd-boot kernel installation completed"
	einfo "Kernel: $kernel_file"
	einfo "Initramfs: initramfs-$(uname -r).img"
}

function install_kernel_efi_stub() {
	einfo "Installing kernel for EFI Stub booting"
	
	# Install efibootmgr for UEFI boot entry management
	try emerge --verbose sys-boot/efibootmgr
	
	# Copy kernel to EFI System Partition
	local kernel_file
	kernel_file="$(find "/boot" \( -name "vmlinuz-*" -or -name 'kernel-*' \) -printf '%f\n' | sort -V | tail -n 1)" \
		|| die "Could not list newest kernel file"
	
	einfo "Found kernel: $kernel_file"
	
	# Create EFI directory structure if it doesn't exist
	mkdir -p /efi/EFI/Gentoo || die "Could not create EFI Gentoo directory"
	
	# Copy kernel to EFI partition
	try cp "/boot/$kernel_file" "/efi/EFI/Gentoo/vmlinuz-$(uname -r).efi"
	
	# Generate initramfs
	generate_initramfs "/efi/EFI/Gentoo/initramfs-$(uname -r).img"
	
	# Create EFI boot entry using efibootmgr
	einfo "Creating EFI boot entry for EFI Stub"
	local efipartdev
	efipartdev="$(resolve_device_by_id "$DISK_ID_EFI")" \
		|| die "Could not resolve device with id=$DISK_ID_EFI"
	efipartdev="$(realpath "$efipartdev")" \
		|| die "Error in realpath '$efipartdev'"
	
	# Get the sysfs path to EFI partition
	local sys_efipart
	sys_efipart="/sys/class/block/$(basename "$efipartdev")" \
		|| die "Could not construct /sys path to EFI partition"
	
	# Extract partition number, handling both standard and RAID cases
	local efipartnum
	if [[ -e "$sys_efipart/partition" ]]; then
		efipartnum="$(cat "$sys_efipart/partition")" \
			|| die "Failed to find partition number for EFI partition $efipartdev"
	else
		efipartnum="1" # Assume partition 1 if not found, common for RAID-based EFI
		einfo "Assuming partition 1 for RAID-based EFI on device $efipartdev"
	fi
	
	# Identify the parent block device and create EFI boot entry
	local gptdev
	if mdadm --detail --scan "$efipartdev" | grep -qE "^ARRAY $efipartdev " && [[ "$efipartdev" =~ ^/dev/md[0-9]+$ ]]; then
		# RAID 1 case: Create EFI boot entries for each RAID member
		local raid_members
		raid_members=($(mdadm --detail "$efipartdev" | sed -n 's|.*active sync[^/]*\(/dev/[^ ]*\).*|\1|p' | sort))
		
		if [[ -v raid_members && ${#raid_members[@]} -eq 0 ]]; then
			die "RAID setup detected, but no valid member disks found for $efipartdev"
		fi
		
		einfo "RAID detected. RAID members: ${raid_members[*]}"
		
		for disk in "${raid_members[@]}"; do
			gptdev="$disk"
			einfo "Adding EFI boot entry for RAID member: $gptdev"
			try efibootmgr --verbose --create --disk "$gptdev" --part "$efipartnum" --label "Gentoo EFI Stub" --loader "\\EFI\\Gentoo\\vmlinuz-$(uname -r).efi" --unicode "initrd=\\EFI\\Gentoo\\initramfs-$(uname -r).img $(get_cmdline)"
		done
	else
		# Non-RAID case: Create a single EFI boot entry
		gptdev="/dev/$(basename "$(readlink -f "$sys_efipart/..")")" \
			|| die "Failed to find parent device for EFI partition $efipartdev"
		if [[ ! -e "$gptdev" ]] || [[ -z "$gptdev" ]]; then
			gptdev="$(resolve_device_by_id "${DISK_ID_PART_TO_GPT_ID[$DISK_ID_EFI]}")" \
				|| die "Could not resolve device with id=${DISK_ID_PART_TO_GPT_ID[$DISK_ID_EFI]}"
		fi
		try efibootmgr --verbose --create --disk "$gptdev" --part "$efipartnum" --label "Gentoo EFI Stub" --loader "\\EFI\\Gentoo\\vmlinuz-$(uname -r).efi" --unicode "initrd=\\EFI\\Gentoo\\initramfs-$(uname -r).img $(get_cmdline)"
	fi
	
	einfo "EFI Stub kernel installation completed"
	einfo "Kernel: $kernel_file"
	einfo "Initramfs: initramfs-$(uname -r).img"
	einfo "EFI boot entry created: Gentoo EFI Stub"
}

function add_fstab_entry() {
	printf '%-46s  %-24s  %-6s  %-96s %s\n' "$1" "$2" "$3" "$4" "$5" >> /etc/fstab \
		|| die "Could not append entry to fstab"
}

function generate_fstab() {
	einfo "Generating fstab"
	install -m0644 -o root -g root "$GENTOO_INSTALL_REPO_DIR/contrib/fstab" /etc/fstab \
		|| die "Could not overwrite /etc/fstab"
	if [[ $USED_ZFS != "true" && -n $DISK_ID_ROOT_TYPE ]]; then
		add_fstab_entry "UUID=$(get_blkid_uuid_for_id "$DISK_ID_ROOT")" "/" "$DISK_ID_ROOT_TYPE" "$DISK_ID_ROOT_MOUNT_OPTS" "0 1"
	fi
	if [[ $IS_EFI == "true" ]]; then
		add_fstab_entry "UUID=$(get_blkid_uuid_for_id "$DISK_ID_EFI")" "/boot/efi" "vfat" "defaults,noatime,fmask=0177,dmask=0077,noexec,nodev,nosuid,discard" "0 2"
	else
		add_fstab_entry "UUID=$(get_blkid_uuid_for_id "$DISK_ID_BIOS")" "/boot/bios" "vfat" "defaults,noatime,fmask=0177,dmask=0077,noexec,nodev,nosuid,discard" "0 2"
	fi
	if [[ -v "DISK_ID_SWAP" ]]; then
		add_fstab_entry "UUID=$(get_blkid_uuid_for_id "$DISK_ID_SWAP")" "none" "swap" "defaults,discard" "0 0"
	fi
}

function main_install() {
	[[ $# == 0 ]] || die "Too many arguments"

	einfo "Starting Gentoo installation following Handbook sequence"
	
	# Set up cleanup trap if enabled
	if [[ "${CLEANUP_ON_INTERRUPT:-false}" == "true" ]]; then
		trap 'cleanup_on_exit' INT TERM
		einfo "Cleanup on interrupt enabled - will cleanup environment on Ctrl+C"
	fi
	
	# Step 1: Prepare installation environment (network already configured)
	einfo "Step 1: Preparing installation environment"
	prepare_installation_environment
	
	# Step 2: Prepare disks (partitioning and mounting)
	einfo "Step 2: Preparing disks"
	apply_disk_configuration
	
	# Step 3: Download and extract Stage 3
	einfo "Step 3: Installing Gentoo installation files (Stage 3)"
	download_stage3
	extract_stage3
	
	# Step 4: Chroot into the new system
	einfo "Step 4: Chrooting into new system"
	[[ $IS_EFI == "true" ]] && mount_efivars
	gentoo_chroot "$ROOT_MOUNTPOINT" "$GENTOO_INSTALL_REPO_BIND/install" __install_gentoo_in_chroot
	
	# Automatic cleanup if enabled
	if [[ "${ENABLE_AUTO_CLEANUP:-false}" == "true" ]]; then
		einfo "Auto cleanup enabled - cleaning up environment"
		unmount_and_clean_all
	fi
}

function main_install_gentoo_in_chroot() {
    # FIX 1: Ensure variables are loaded inside the chroot
    source "$GENTOO_INSTALL_REPO_DIR/gentoo.conf" || die "Could not load config inside chroot"
	[[ $# == 0 ]] || die "Too many arguments"

	einfo "Continuing installation inside chroot environment"
	
	maybe_exec 'before_install'

	# Step 5: Install Gentoo base system
	einfo "Step 5: Installing Gentoo base system"
	install_base_system
	
	# Step 6: Configure the Linux kernel
	einfo "Step 6: Configuring the Linux kernel"
	configure_kernel
	
	# Step 7: Configure the system
	einfo "Step 7: Configuring the system"
	configure_system
	
	# Step 8: Install system tools
	einfo "Step 8: Installing system tools"
	install_system_tools
	
	# NEW SECTION: Install Desktop Environment and GPU Drivers
	if [[ -n "$DESKTOP_ENVIRONMENT" ]]; then
		einfo "Step 8a: Installing Desktop Environment"
		install_desktop_environment
		install_display_manager
		install_network_manager
		configure_desktop_services
	fi
	# GPU driver installation function removed - too complex for automated installation
	# Users can manually install GPU drivers after installation if needed
	# END OF NEW SECTION
	# Step 9: Configure the bootloader
	einfo "Step 9: Configuring the bootloader"
	configure_bootloader
	
	# Step 10: Finalize the installation
	einfo "Step 10: Finalizing the installation"
	finalize_installation
	
	maybe_exec 'after_install'
}

function install_base_system() {
	einfo "Installing base system components"
	
	# Remove the root password for automated tasks during installation
	einfo "Clearing root password"
	passwd -d root || die "Could not change root password"

	# Sync portage tree
	einfo "Syncing portage tree"
	try emerge-webrsync

	# Install mdadm if we used RAID
	if [[ $USED_RAID == "true" ]]; then
		einfo "Installing mdadm for RAID support"
		try emerge --verbose sys-fs/mdadm
	fi

	# Mount boot partitions
	if [[ $IS_EFI == "true" ]]; then
		einfo "Mounting EFI partition"
		mount_efivars
		mount_by_id "$DISK_ID_EFI" "/boot/efi"
	else
		einfo "Mounting BIOS partition"
		mount_by_id "$DISK_ID_BIOS" "/boot/bios"
	fi

	# Configure basic system (timezone, locale, etc.)
	maybe_exec 'before_configure_base_system'
	configure_base_system
	maybe_exec 'after_configure_base_system'

	# Configure portage environment
	maybe_exec 'before_configure_portage'
	configure_portage
	maybe_exec 'after_configure_portage'
}

function configure_kernel() {
	einfo "Configuring Linux kernel"

	local virtio_drivers=""
	# Install filesystem tools BEFORE kernel/dracut installation
	# These are required for dracut to properly handle filesystem modules
	if [[ $USED_BTRFS == "true" ]]; then
		einfo "Installing BTRFS tools for BTRFS support"
		try emerge --verbose sys-fs/btrfs-progs
	fi
	
	if [[ $USED_ZFS == "true" ]]; then
		einfo "Installing ZFS tools for ZFS support"
		try emerge --verbose sys-fs/zfs
	fi
	
	if [[ $USED_RAID == "true" ]]; then
		einfo "Installing RAID tools for RAID support"
		try emerge --verbose sys-fs/mdadm
	fi
	
	# Install git for portage overlays
	einfo "Installing git for portage overlays"
	try emerge --verbose dev-vcs/git

	# Configure git-based portage if requested
	if [[ "$PORTAGE_SYNC_TYPE" == "git" ]]; then
		einfo "Configuring git-based portage"
		mkdir_or_die 0755 "/etc/portage/repos.conf"
		cat > /etc/portage/repos.conf/gentoo.conf <<EOF
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /var/db/repos/gentoo
sync-type = git
sync-uri = $PORTAGE_GIT_MIRROR
auto-sync = yes
sync-depth = $([[ $PORTAGE_GIT_FULL_HISTORY == true ]] && echo -n 0 || echo -n 1)
sync-git-verify-commit-signature = yes
sync-openpgp-key-path = /usr/share/openpgp-keys/gentoo-release.asc
EOF
		chmod 644 /etc/portage/repos.conf/gentoo.conf \
			|| die "Could not change permissions of '/etc/portage/repos.conf/gentoo.conf'"
		rm -rf /var/db/repos/gentoo \
			|| die "Could not delete obsolete rsync gentoo repository"
		try emerge --sync
	fi

	# Generate SSH host keys
	einfo "Generating SSH host keys"
	try ssh-keygen -A

	# Install authorized keys
	install_authorized_keys

	# Configure kernel installation
	einfo "Configuring kernel installation"
	echo "sys-kernel/installkernel dracut" > /etc/portage/package.use/installkernel \
		|| die "Could not write /etc/portage/package.use/installkernel"

	# Install kernel and dracut
	einfo "Installing kernel and dracut"
	try emerge --verbose sys-kernel/dracut app-arch/zstd
	
	# Try to install binary kernel first, fallback to source if needed
	if ! emerge --verbose sys-kernel/gentoo-kernel-bin; then
		ewarn "Binary kernel installation failed, trying source kernel"
		try emerge --verbose sys-kernel/gentoo-sources
		try emerge --verbose sys-kernel/genkernel
		
		# Configure and compile kernel
		einfo "Configuring and compiling kernel"
		cd /usr/src/linux
		try make defconfig
		try make -j$(nproc)
		try make modules_install
		try make install
		cd /
	fi
	
	# Generate initramfs using the proven dracut approach
	einfo "Generating initramfs with dracut"
	
	# Determine required dracut and kernel modules based on system configuration
	local dracut_modules=("bash")  # bash is always a dracut module
	local kernel_drivers=()
	
	# Populate dracut modules (scripts, tools)
	[[ $USED_RAID == "true" ]] && dracut_modules+=("mdraid")
	[[ $USED_LUKS == "true" ]] && dracut_modules+=("crypt")
	[[ $USED_ZFS == "true" ]] && dracut_modules+=("zfs")
	
	# Populate kernel drivers (filesystem support)
	[[ $USED_BTRFS == "true" ]] && kernel_drivers+=("btrfs")
	
	# Get kernel version from symlink (proven method)
	local kver
	kver="$(readlink /usr/src/linux)" || die "Could not figure out kernel version from /usr/src/linux symlink."
	kver="${kver#linux-}"
	
	# Configure dracut options
	local dracut_opts=()
	if [[ $SYSTEMD == "true" && $SYSTEMD_INITRAMFS_SSHD == "true" ]]; then
		cd /tmp || die "Could not change into /tmp"
		try git clone https://github.com/gsauthof/dracut-sshd
		try cp -r dracut-sshd/46sshd /usr/lib/dracut/modules.d
		sed -e 's/^Type=notify/Type=simple/' \
			-e 's@^\(ExecStart=/usr/sbin/sshd\) -D@\1 -e -D@' \
			-i /usr/lib/dracut/modules.d/46sshd/sshd.service \
			|| die "Could not replace sshd options in service file"
		
		dracut_opts+=("--install" "/etc/systemd/network/20-wired.network")
		dracut_modules+=("systemd-networkd")
	fi
 
	# Conditionally add virtio drivers for VM compatibility
	if systemd-detect-virt -q; then
		einfo "Virtual machine detected, adding virtio drivers to initramfs"
		kernel_drivers+=("virtio" "virtio_pci" "virtio_net" "virtio_blk")
	fi

	# Generate initramfs using proven dracut command
	einfo "Using Dracut modules: ${dracut_modules[*]}"
	einfo "Using Kernel drivers: ${kernel_drivers[*]}"
	
	# Build and execute the final dracut command
	try dracut \
		--kver "$kver" \
		--zstd \
		--no-hostonly \
		--ro-mnt \
		--add "${dracut_modules[*]}" \
		--add-drivers "${kernel_drivers[*]}" \
		"${dracut_opts[@]}" \
		--force \
		--verbose \
		"/boot/initramfs-$kver.img"

	# Install cryptsetup if LUKS is used
	if [[ $USED_LUKS == "true" ]]; then
		einfo "Installing cryptsetup for LUKS support"
		try emerge --verbose sys-fs/cryptsetup
	fi
	


	# Rebuild systemd with cryptsetup if needed
	if [[ $SYSTEMD == "true" && $USED_LUKS == "true" ]] ; then
		einfo "Enabling cryptsetup USE flag on systemd"
		echo "sys-apps/systemd cryptsetup" > /etc/portage/package.use/systemd \
			|| die "Could not write /etc/portage/package.use/systemd"
		einfo "Rebuilding systemd with changed USE flag"
		try emerge --verbose --changed-use --oneshot sys-apps/systemd
	fi
}

function configure_system() {
	einfo "Configuring system settings"
	
	# Apply configured package management settings
	apply_configured_package_management
	
	# Configure systemd or OpenRC
	if [[ $SYSTEMD == "true" ]]; then
		einfo "Configuring systemd"
		configure_systemd
	else
		einfo "Configuring OpenRC"
		configure_openrc
	fi
}

function install_system_tools() {
	einfo "Installing system tools"
	
	# Install performance optimization tools if enabled
	if [[ "${ENABLE_PERFORMANCE_OPTIMIZATION:-false}" == "true" ]]; then
		einfo "Installing performance optimization tools"
		install_performance_optimization
	fi
	

	
	# Install additional packages specified by user
	if [[ -v ADDITIONAL_PACKAGES && ${#ADDITIONAL_PACKAGES[@]} -gt 0 ]]; then
		einfo "Installing additional packages: ${ADDITIONAL_PACKAGES[*]}"
		try emerge --verbose "${ADDITIONAL_PACKAGES[@]}"
	fi
}

function configure_bootloader() {
	einfo "Configuring bootloader"
	
	# CRITICAL: Verify EFI System Partition setup for UEFI systems
	verify_efi_system_partition
	
	# Check Secure Boot status for UEFI systems
	configure_secure_boot_support
	
	# Configure bootloader based on user selection
	case "${BOOTLOADER_TYPE:-grub}" in
		"grub")
			configure_grub_bootloader
			;;
		"systemd-boot")
			configure_systemd_boot
			;;
		"efistub")
			configure_efi_stub
			;;
		*)
			ewarn "Unknown bootloader type: ${BOOTLOADER_TYPE:-grub}, defaulting to GRUB"
			configure_grub_bootloader
			;;
	esac
	
	einfo "Bootloader configuration completed successfully"
}

function configure_grub_bootloader() {
	einfo "Installing and configuring GRUB bootloader"
	
	# Install and configure GRUB
	einfo "Installing and configuring GRUB"
	
	# CRITICAL: Set proper GRUB platforms for UEFI systems
	# According to Gentoo Handbook: UEFI systems need GRUB_PLATFORMS="efi-64"
	if [[ $IS_EFI == "true" ]]; then
		einfo "UEFI system detected - configuring GRUB for UEFI"
		
		# Create package.use directory if it doesn't exist
		mkdir -p /etc/portage/package.use || die "Could not create /etc/portage/package.use directory"
		
		# Set GRUB_PLATFORMS for UEFI support
		einfo "Setting GRUB_PLATFORMS=\"efi-64\" for UEFI support"
		echo 'sys-boot/grub GRUB_PLATFORMS="efi-64"' > /etc/portage/package.use/grub-uefi \
			|| die "Could not write GRUB UEFI USE flags to /etc/portage/package.use/grub-uefi"
		
		einfo "UEFI GRUB configuration prepared"
	else
		einfo "BIOS/Legacy system detected - configuring GRUB for BIOS"
	fi
	
	# Install GRUB with proper platform support
	try emerge --verbose sys-boot/grub
	
	if [[ $IS_EFI == "true" ]]; then
		einfo "Installing EFI bootloader"
		
		# Use the correct grub-install command for UEFI systems
		# According to Gentoo Handbook: --efi-directory should point to EFI mount point
		einfo "Installing GRUB to EFI System Partition"
		grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=gentoo \
			|| die "Failed to install GRUB EFI bootloader"
		
		# Enhanced RAID support for UEFI systems
		if [[ "${USED_RAID:-false}" == "true" ]]; then
			configure_raid_uefi_boot_order
		fi
		
		einfo "GRUB EFI bootloader installed successfully"
	else
		einfo "Installing BIOS bootloader"
		# Get the disk device from the root partition ID
		local disk_device
		disk_device="$(get_disk_device_from_partition "$DISK_ID_ROOT")"
		einfo "Installing GRUB to disk: $disk_device"
		grub-install "$disk_device" || die "Failed to install GRUB BIOS bootloader"
		
		# Enhanced RAID support for BIOS systems
		if [[ "${USED_RAID:-false}" == "true" ]]; then
			configure_raid_bios_bootloader
		fi
		
		einfo "GRUB BIOS bootloader installed successfully"
	fi
	
	# Generate GRUB configuration
	einfo "Generating GRUB configuration"
	grub-mkconfig -o /boot/grub/grub.cfg || die "Failed to generate GRUB configuration"
	
	# Configure advanced GRUB options
	configure_advanced_grub
	
	# Configure dual boot detection if enabled
	configure_dual_boot_detection
	
	# Regenerate GRUB configuration with advanced options
	einfo "Regenerating GRUB configuration with advanced options"
	grub-mkconfig -o /boot/grub/grub.cfg || die "Failed to regenerate GRUB configuration with advanced options"
	
	# Verify kernel files exist
	einfo "Verifying kernel installation"
	if ! ls /boot/{vmlinuz,kernel}-* 1> /dev/null 2>&1; then
		ewarn "No kernel image found in /boot"
		ls -la /boot/ || true
		ls -la /usr/src/ || true
	fi
	
	if ! ls /boot/initramfs-* 1> /dev/null 2>&1; then
		ewarn "No initramfs found in /boot"
		ls -la /boot/ || true
	fi
	
	einfo "GRUB bootloader configuration completed successfully"
	if [[ $IS_EFI == "true" ]]; then
		einfo "UEFI bootloader installed with GRUB_PLATFORMS=\"efi-64\""
		einfo "EFI System Partition verified and accessible"
	else
		einfo "BIOS bootloader installed successfully"
	fi
}

function configure_advanced_grub() {
	[[ "${BOOTLOADER_TYPE:-grub}" == "grub" ]] || return 0
	
	einfo "Configuring advanced GRUB options"
	
	# Create GRUB configuration directory
	mkdir -p /etc/default || die "Could not create /etc/default directory"
	
	# Configure GRUB_DEFAULT (default boot entry)
	einfo "Setting GRUB default boot entry"
	echo 'GRUB_DEFAULT=0' > /etc/default/grub \
		|| die "Could not write GRUB_DEFAULT to /etc/default/grub"
	
	# Configure GRUB_TIMEOUT (boot menu timeout)
	einfo "Setting GRUB boot menu timeout"
	echo 'GRUB_TIMEOUT=5' >> /etc/default/grub \
		|| die "Could not write GRUB_TIMEOUT to /etc/default/grub"
	
	# Configure GRUB_CMDLINE_LINUX (custom kernel parameters)
	einfo "Configuring custom kernel parameters"
	local custom_params=""
	
	# Add performance tuning parameters if enabled
	if [[ "${ENABLE_PERFORMANCE_OPTIMIZATION:-false}" == "true" ]]; then
		custom_params="intel_pstate=performance i915.enable_rc6=0"
		einfo "Adding performance tuning parameters: $custom_params"
	fi
	
	# Add desktop environment specific parameters
	if [[ -n "$DESKTOP_ENVIRONMENT" ]]; then
		case "$DESKTOP_ENVIRONMENT" in
			kde|gnome|hyprland)
				custom_params="$custom_params quiet splash"
				einfo "Adding desktop environment parameters: quiet splash"
				;;
			xfce|cinnamon|mate|budgie)
				custom_params="$custom_params quiet"
				einfo "Adding desktop environment parameters: quiet"
				;;
		esac
	fi
	
	# Add custom parameters from user configuration
	if [[ -n "${GRUB_CUSTOM_PARAMS[*]-}" ]]; then
    local user_params="${GRUB_CUSTOM_PARAMS[*]}"
    custom_params="$custom_params $user_params"
    einfo "Adding user custom parameters: $user_params"
    fi
	
	# Write kernel parameters to GRUB configuration
	if [[ -n "$custom_params" ]]; then
		echo "GRUB_CMDLINE_LINUX=\"$custom_params\"" >> /etc/default/grub \
			|| die "Could not write GRUB_CMDLINE_LINUX to /etc/default/grub"
	else
		echo 'GRUB_CMDLINE_LINUX=""' >> /etc/default/grub \
			|| die "Could not write empty GRUB_CMDLINE_LINUX to /etc/default/grub"
	fi
	
	# Configure GRUB_DISABLE_OS_PROBER (for dual boot detection)
	if [[ "${ENABLE_DUAL_BOOT_DETECTION:-false}" == "true" ]]; then
		einfo "Enabling dual boot detection with os-prober"
		echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub \
			|| die "Could not write GRUB_DISABLE_OS_PROBER to /etc/default/grub"
	else
		einfo "Disabling dual boot detection (os-prober disabled)"
		echo 'GRUB_DISABLE_OS_PROBER=true' >> /etc/default/grub \
			|| die "Could not write GRUB_DISABLE_OS_PROBER to /etc/default/grub"
	fi
	
	# Configure GRUB_GFXMODE (graphics mode for UEFI systems)
	if [[ $IS_EFI == "true" ]]; then
		einfo "Setting GRUB graphics mode for UEFI"
		echo 'GRUB_GFXMODE=1920x1080x32,auto' >> /etc/default/grub \
			|| die "Could not write GRUB_GFXMODE to /etc/default/grub"
	fi
	
	# Configure GRUB_THEME (if available)
	if [[ -d "/usr/share/grub/themes" ]]; then
		einfo "Setting GRUB theme"
		echo 'GRUB_THEME="/usr/share/grub/themes/gentoo/theme.txt"' >> /etc/default/grub \
			|| ewarn "Could not write GRUB_THEME to /etc/default/grub"
	fi
	
	# Configure GRUB_SAVEDEFAULT (save last booted entry)
	einfo "Enabling GRUB saved default entry"
	echo 'GRUB_SAVEDEFAULT=true' >> /etc/default/grub \
		|| die "Could not write GRUB_SAVEDEFAULT to /etc/default/grub"
	
	# Configure GRUB_DEFAULT_SAVED (use saved entry as default)
	echo 'GRUB_DEFAULT=saved' >> /etc/default/grub \
		|| die "Could not write GRUB_DEFAULT=saved to /etc/default/grub"
	
	einfo "Advanced GRUB configuration completed"
	einfo "Custom kernel parameters: $custom_params"
	if [[ "${ENABLE_DUAL_BOOT_DETECTION:-false}" == "true" ]]; then
		einfo "Dual boot detection enabled"
	else
		einfo "Dual boot detection disabled"
	fi
}

function configure_dual_boot_detection() {
	[[ "${BOOTLOADER_TYPE:-grub}" == "grub" ]] || return 0
	[[ "${ENABLE_DUAL_BOOT_DETECTION:-false}" == "true" ]] || return 0
	
	einfo "Configuring dual boot detection with os-prober"
	
	# Install os-prober for multi-OS detection
	einfo "Installing os-prober for dual boot detection"
	try emerge --verbose sys-boot/os-prober
	
	# Install additional tools for better OS detection
	einfo "Installing additional tools for OS detection"
	try emerge --verbose sys-boot/mtools sys-fs/ntfs3g
	
	# Create os-prober configuration
	einfo "Creating os-prober configuration"
	mkdir -p /etc/os-prober.d || die "Could not create /etc/os-prober.d directory"
	
	# Configure os-prober to detect common operating systems
	cat > /etc/os-prober.d/gentoo.conf <<EOF
# Gentoo os-prober configuration
# Enable detection of common operating systems

# Windows detection
WINDOWS_BOOT_LOADER=true
WINDOWS_EFI_LOADER=true

# Linux distribution detection
LINUX_DISTROS=true

# macOS detection (if on compatible hardware)
MACOS_DETECTION=false

# Custom OS detection scripts
CUSTOM_SCRIPTS=false
EOF
	
	# Set proper permissions
	chmod 644 /etc/os-prober.d/gentoo.conf \
		|| ewarn "Could not set permissions on os-prober configuration"
	
	# Create a script to run os-prober after GRUB configuration
	einfo "Creating os-prober integration script"
	cat > /usr/local/bin/update-grub-with-os-prober <<'EOF'
#!/bin/bash
# Script to update GRUB configuration with os-prober detection

set -e

einfo "Updating GRUB configuration with os-prober detection"

# Check if os-prober is available
if ! command -v os-prober >/dev/null 2>&1; then
    ewarn "os-prober not found, installing..."
    emerge --verbose sys-boot/os-prober
fi

# Run os-prober to detect other operating systems
einfo "Detecting other operating systems with os-prober"
if os-prober; then
    einfo "Other operating systems detected"
else
    einfo "No other operating systems detected"
fi

# Generate GRUB configuration with os-prober integration
einfo "Generating GRUB configuration with OS detection"
grub-mkconfig -o /boot/grub/grub.cfg

einfo "GRUB configuration updated with os-prober detection"
einfo "Reboot to see detected operating systems in boot menu"
EOF
	
	# Make the script executable
	chmod +x /usr/local/bin/update-grub-with-os-prober \
		|| ewarn "Could not make os-prober script executable"
	
	# Create a post-install hook for automatic os-prober integration
	einfo "Setting up automatic os-prober integration"
	mkdir -p /etc/portage/postinst.d || die "Could not create /etc/portage/postinst.d directory"
	
	cat > /etc/portage/postinst.d/grub-os-prober-update <<'EOF'
#!/bin/bash
# Post-install hook to update GRUB with os-prober after kernel updates

# Only run if GRUB is installed and os-prober is enabled
if [[ -f /etc/default/grub ]] && grep -q 'GRUB_DISABLE_OS_PROBER=false' /etc/default/grub; then
    if command -v update-grub-with-os-prober >/dev/null 2>&1; then
        einfo "Running os-prober update after package installation"
        update-grub-with-os-prober
    fi
fi
EOF
	
	# Make the post-install hook executable
	chmod +x /etc/portage/postinst.d/grub-os-prober-update \
		|| ewarn "Could not make post-install hook executable"
	
	einfo "Dual boot detection configuration completed"
	einfo "os-prober will automatically detect other operating systems"
	einfo "Use 'update-grub-with-os-prober' to manually update GRUB configuration"
	einfo "Post-install hooks will automatically update GRUB after kernel updates"
}

function verify_efi_system_partition() {
	[[ $IS_EFI == "true" ]] || return 0
	
	einfo "Verifying EFI System Partition setup"
	
	# Check if EFI system partition is mounted
	if ! mountpoint -q -- "/boot/efi"; then
		ewarn "EFI System Partition not mounted at /boot/efi"
		ewarn "This is required for UEFI bootloader installation"
		
		# Try to mount the EFI system partition
		if [[ -n "$DISK_ID_EFI" ]]; then
			einfo "Mounting EFI System Partition using DISK_ID_EFI: $DISK_ID_EFI"
			mount_by_id "$DISK_ID_EFI" "/boot/efi"
		else
			die "EFI System Partition not mounted and DISK_ID_EFI not available"
		fi
	fi
	
	# Verify EFI System Partition is accessible and has proper structure
	if [[ ! -d "/boot/efi/EFI" ]]; then
		einfo "Creating EFI directory structure"
		mkdir -p "/boot/efi/EFI" || die "Could not create EFI directory structure"
	fi
	
	# Check if EFI system partition has proper permissions and is writable
	if [[ ! -w "/boot/efi" ]]; then
		die "EFI System Partition is not writable - check mount permissions"
	fi
	
	# Verify efivars is mounted for UEFI variable access
	if ! mountpoint -q -- "/sys/firmware/efi/efivars"; then
		einfo "Mounting efivars for UEFI variable access"
		mount_efivars
	fi
	
	einfo "EFI System Partition verified and ready for bootloader installation"
}

function configure_systemd_boot() {
	[[ $IS_EFI == "true" ]] || die "systemd-boot requires UEFI system"
	[[ "${BOOTLOADER_TYPE:-grub}" == "systemd-boot" ]] || return 0
	
	einfo "Installing and configuring systemd-boot"
	
	# Install systemd-boot with proper USE flags
	einfo "Installing systemd-boot packages"
	
	# Create package.use directory if it doesn't exist
	mkdir -p /etc/portage/package.use || die "Could not create /etc/portage/package.use directory"
	
	# Set systemd-boot USE flags
	einfo "Setting systemd-boot USE flags"
	if [[ "${SYSTEMD:-false}" == "true" ]]; then
		echo 'sys-apps/systemd boot' > /etc/portage/package.use/systemd-boot \
			|| die "Could not write systemd-boot USE flags"
	else
		echo 'sys-apps/systemd-utils boot' > /etc/portage/package.use/systemd-boot \
			|| die "Could not write systemd-boot USE flags"
	fi
	
	# Install systemd-boot
	if [[ "${SYSTEMD:-false}" == "true" ]]; then
		try emerge --verbose sys-apps/systemd
	else
		try emerge --verbose sys-apps/systemd-utils
	fi
	
	# Install systemd-boot to EFI System Partition
	einfo "Installing systemd-boot to EFI System Partition"
	bootctl install || die "Failed to install systemd-boot"
	
	# Verify installation
	einfo "Verifying systemd-boot installation"
	bootctl list || ewarn "Could not list boot entries"
	
	einfo "systemd-boot installation completed successfully"
	einfo "Note: Kernel installation will automatically update boot entries"
}

function configure_efi_stub() {
	[[ $IS_EFI == "true" ]] || die "EFI Stub requires UEFI system"
	[[ "${BOOTLOADER_TYPE:-grub}" == "efistub" ]] || return 0
	
	einfo "Installing and configuring EFI Stub booting"
	
	# Install efibootmgr for UEFI boot entry management
	einfo "Installing efibootmgr for UEFI boot entry management"
	try emerge --verbose sys-boot/efibootmgr
	
	# Configure installkernel for EFI Stub support
	einfo "Configuring installkernel for EFI Stub support"
	
	# Create package.use directory if it doesn't exist
	mkdir -p /etc/portage/package.use || die "Could not create /etc/portage/package.use directory"
	
	# Set efistub USE flag for installkernel
	echo 'sys-kernel/installkernel efistub' > /etc/portage/package.use/installkernel-efistub \
		|| die "Could not write installkernel efistub USE flags"
	
	# Reinstall installkernel with efistub support
	einfo "Reinstalling installkernel with EFI Stub support"
	try emerge --verbose sys-kernel/installkernel
	
	# Create EFI directory structure
	einfo "Creating EFI directory structure"
	mkdir -p /efi/EFI/Gentoo || die "Could not create EFI directory structure"
	
	einfo "EFI Stub configuration completed successfully"
	einfo "Note: Kernel installation will automatically create EFI boot entries"
}

function configure_secure_boot_support() {
	[[ $IS_EFI == "true" ]] || return 0
	
	einfo "Checking Secure Boot support"
	
	# Check if secure boot is enabled in UEFI
	if [[ -d "/sys/firmware/efi/efivars" ]]; then
		# Try to read secure boot status (this may fail if not accessible)
		local secure_boot_status="unknown"
		if command -v mokutil >/dev/null 2>&1; then
			if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
				secure_boot_status="enabled"
			elif mokutil --sb-state 2>/dev/null | grep -q "SecureBoot disabled"; then
				secure_boot_status="disabled"
			fi
		fi
		
		einfo "Secure Boot status: $secure_boot_status"
		
		# If secure boot is enabled, offer to install shim for compatibility
		if [[ "$secure_boot_status" == "enabled" ]]; then
			ewarn "Secure Boot is enabled - this may require additional setup for GRUB to work"
			ewarn "Consider installing shim for better Secure Boot compatibility"
			
			# Offer optional shim installation
			if ask "Install shim packages for Secure Boot compatibility?"; then
				einfo "Installing shim packages for Secure Boot support"
				
				# Install required packages for Secure Boot
				try emerge --verbose sys-boot/shim sys-boot/mokutil sys-boot/efibootmgr
				
				# Create EFI directory structure for shim
				mkdir -p /efi/EFI/Gentoo || die "Could not create EFI directory structure"
				
				# Copy shim files to EFI partition
				einfo "Installing shim files to EFI System Partition"
				cp /usr/share/shim/BOOTX64.EFI /efi/EFI/Gentoo/shimx64.efi \
					|| ewarn "Could not copy shim BOOTX64.EFI"
				cp /usr/share/shim/mmx64.efi /efi/EFI/Gentoo/mmx64.efi \
					|| ewarn "Could not copy shim mmx64.efi"
				
				# Copy signed GRUB EFI file
				if [[ -f /usr/lib/grub/grub-x86_64.efi.signed ]]; then
					cp /usr/lib/grub/grub-x86_64.efi.signed /efi/EFI/Gentoo/grubx64.efi \
						|| ewarn "Could not copy signed GRUB EFI file"
				else
					ewarn "Signed GRUB EFI file not found - Secure Boot may not work"
				fi
				
				einfo "Shim installation completed"
				einfo "Note: You may need to manually configure UEFI boot entries"
				einfo "See Gentoo Handbook for detailed Secure Boot configuration"
			else
				einfo "Shim installation skipped - GRUB may not work with Secure Boot enabled"
			fi
		fi
	else
		ewarn "Could not determine Secure Boot status - efivars not accessible"
	fi
}

function finalize_installation() {
	einfo "Finalizing installation"
	
	# Set root password
	einfo "Setting root password"
	passwd root || ewarn "Could not set root password - user will need to set it manually"
	
	# Create user account if specified
	if [[ -n "$CREATE_USER" ]]; then
		einfo "Creating user account: $CREATE_USER"
		
			# Create user with configurable groups (with desktop environment additions)
	local user_groups="${CREATE_USER_GROUPS:-users,wheel,audio,video,usb}"
	if [[ -n "$DESKTOP_ENVIRONMENT" ]]; then
		# Add desktop-specific groups if not already present
		local desktop_groups="plugdev,input"
		for group in $desktop_groups; do
			if [[ "$user_groups" != *"$group"* ]]; then
				user_groups="$user_groups,$group"
			fi
		done
		einfo "Added desktop-specific groups: plugdev,input"
	fi
		
		einfo "Creating user with groups: $user_groups"
		useradd -m -G "$user_groups" -s /bin/bash "$CREATE_USER" \
			|| ewarn "Could not create user $CREATE_USER"
		
		# Set user password securely
		if [[ "${ENABLE_RANDOM_PASSWORD:-false}" == "true" ]]; then
			# Generate secure random password
			einfo "Generating secure random password for user $CREATE_USER"
			local random_password
			random_password=$(generate_secure_password)
			
			# Set the password using chpasswd for non-interactive operation
			echo "$CREATE_USER:$random_password" | chpasswd \
				|| ewarn "Could not set random password for user $CREATE_USER"
			
			# Display the password to the user
			einfo "✅ User $CREATE_USER created with random password:"
			einfo "   Username: $CREATE_USER"
			einfo "   Password: $random_password"
			einfo "   ⚠️  IMPORTANT: Save this password securely - it won't be shown again!"
			einfo "   ⚠️  You can change it later with: passwd $CREATE_USER"
		else
			# Set password interactively for security
			einfo "Setting password for user $CREATE_USER interactively"
			einfo "You will be prompted to enter and confirm the password"
			passwd "$CREATE_USER" || ewarn "Could not set password for user $CREATE_USER"
		fi
		
			einfo "User account $CREATE_USER created successfully"
		einfo "Groups: $user_groups"
		
		# Apply the custom Hyprland configuration for the new user
		if [[ "$DESKTOP_ENVIRONMENT" == "hyprland" && -v HYPRLAND_CONFIG && -n "$HYPRLAND_CONFIG" ]]; then
			einfo "Applying custom Hyprland configuration for user $CREATE_USER..."
			local user_home="/home/$CREATE_USER"
			local hypr_config_dir="$user_home/.config/hypr"
			
			# Create the Hyprland config directory
			su - "$CREATE_USER" -c "mkdir -p '$hypr_config_dir'" \
				|| ewarn "Could not create Hyprland config directory for user $CREATE_USER."
			
			# Copy the configuration file with proper ownership
			install -o "$(id -u "$CREATE_USER")" -g "$(id -g "$CREATE_USER")" -m 644 \
				<(echo "$HYPRLAND_CONFIG") "$hypr_config_dir/hyprland.conf" \
				|| ewarn "Could not copy hyprland.conf for user $CREATE_USER."
			
			einfo "✅ Hyprland configuration applied successfully"
			einfo "   Config file: $hypr_config_dir/hyprland.conf"
			einfo "   User: $CREATE_USER"
		fi
else
	einfo "No user account creation requested"
fi

# Set secure file permissions for better security
einfo "Setting secure file permissions"
chmod 600 /etc/shadow || ewarn "Could not set secure permissions on /etc/shadow"
chmod 644 /etc/passwd || ewarn "Could not set secure permissions on /etc/passwd"
chmod 644 /etc/group || ewarn "Could not set secure permissions on /etc/group"
	
	# Clean up temporary files
	einfo "Cleaning up temporary files"
	emerge --depclean
	
	# Update system
	einfo "Updating system"
	emerge --update --deep --newuse @world
	
	einfo "Gentoo installation completed successfully!"
	einfo "You can now reboot into your new system"
}

function configure_systemd() {
	einfo "Configuring systemd services"
	
	# Enable essential systemd services
	enable_service systemd-networkd
	enable_service systemd-resolved
	
	# Configure network if specified
	if [[ $SYSTEMD_NETWORKD == "true" ]]; then
		if [[ $SYSTEMD_NETWORKD_DHCP == "true" ]]; then
			echo -en "[Match]\nName=${SYSTEMD_NETWORKD_INTERFACE_NAME}\n\n[Network]\nDHCP=yes" > /etc/systemd/network/20-wired.network \
				|| die "Could not write dhcp network config to '/etc/systemd/network/20-wired.network'"
		else
			addresses=""
			for addr in "${SYSTEMD_NETWORKD_ADDRESSES[@]}"; do
				addresses="${addresses}Address=$addr\n"
			done
			echo -en "[Match]\nName=${SYSTEMD_NETWORKD_INTERFACE_NAME}\n\n[Network]\n${addresses}Gateway=$SYSTEMD_NETWORKD_GATEWAY" > /etc/systemd/network/20-wired.network \
				|| die "Could not write dhcp network config to '/etc/systemd/network/20-wired.network'"
		fi
		chown root:systemd-network /etc/systemd/network/20-wired.network \
			|| die "Could not change owner of '/etc/systemd/network/20-wired.network'"
		chmod 640 /etc/systemd/network/20-wired.network \
			|| die "Could not change permissions of '/etc/systemd/network/20-wired.network'"
	fi
}

function configure_openrc() {
	einfo "Configuring OpenRC services"
	
	# CRITICAL: Prevent NetworkManager and dhcpcd service conflicts
	# According to Gentoo Handbook: "Only one network management service should run at a time"
	local will_use_networkmanager="false"
	
	# Check user's explicit network manager preference first
	if [[ "$ENABLE_NETWORK_MANAGER" == "none" ]]; then
		einfo "User explicitly disabled network manager - will use dhcpcd"
		will_use_networkmanager="false"
	elif [[ -n "$DESKTOP_ENVIRONMENT" ]]; then
		# Only auto-detect if user hasn't explicitly set it
		local nm="${ENABLE_NETWORK_MANAGER:-auto}"
		if [[ "$nm" == "auto" ]]; then
			nm="$(get_default_nm_for_de "$DESKTOP_ENVIRONMENT")"
		fi
		[[ "$nm" != "none" ]] && will_use_networkmanager="true"
	else
		# No desktop environment, check if user explicitly enabled network manager
		[[ "$ENABLE_NETWORK_MANAGER" != "none" ]] && will_use_networkmanager="true"
	fi
	
	# Only install and enable dhcpcd if NetworkManager is NOT being used
	if [[ "$will_use_networkmanager" == "false" ]]; then
		einfo "Installing dhcpcd service (NetworkManager not enabled)"
		try emerge --verbose net-misc/dhcpcd
		enable_service dhcpcd
		einfo "dhcpcd service enabled - system will have network connectivity"
	else
		einfo "Skipping dhcpcd service (NetworkManager will handle networking)"
		einfo "Note: NetworkManager and dhcpcd should not run simultaneously"
		einfo "This prevents networking conflicts and follows Gentoo Handbook recommendations"
	fi
	
	# Enable SSH if requested
	if [[ $ENABLE_SSHD == "true" ]]; then
		enable_sshd
	fi
	
	# Verify network configuration is complete
	verify_network_configuration
}

function enable_service() {
	local service="$1"
	einfo "Enabling service: $service"
	
	if [[ $SYSTEMD == "true" ]]; then
		try systemctl enable "$service"
	else
		try rc-update add "$service" default
	fi
}

function enable_sshd() {
	einfo "Enabling SSH daemon"
	
	if [[ $SYSTEMD == "true" ]]; then
		try systemctl enable sshd
	else
		try rc-update add sshd default
	fi
}

function verify_network_configuration() {
	einfo "Verifying network configuration"
	
	local network_service_enabled="false"
	local network_manager_enabled="false"
	
	# Check if dhcpcd is enabled
	if [[ $SYSTEMD == "true" ]]; then
		if systemctl is-enabled dhcpcd >/dev/null 2>&1; then
			network_service_enabled="true"
		fi
	else
		if rc-update show | grep -q "dhcpcd.*default"; then
			network_service_enabled="true"
		fi
	fi
	
	# Check if NetworkManager is enabled
	if [[ $SYSTEMD == "true" ]]; then
		if systemctl is-enabled NetworkManager >/dev/null 2>&1; then
			network_manager_enabled="true"
		fi
	else
		if rc-update show | grep -q "NetworkManager.*default"; then
			network_manager_enabled="true"
		fi
	fi
	
	# Verify that at least one network service is configured
	if [[ "$network_service_enabled" == "true" || "$network_manager_enabled" == "true" ]]; then
		einfo "Network configuration verified: system will have network connectivity"
		if [[ "$network_service_enabled" == "true" ]]; then
			einfo "  - dhcpcd service enabled for automatic network configuration"
		fi
		if [[ "$network_manager_enabled" == "true" ]]; then
			einfo "  - NetworkManager service enabled for advanced network management"
		fi
	else
		ewarn "WARNING: No network service is enabled!"
		ewarn "The system may not have network connectivity after installation"
		ewarn "Consider enabling either dhcpcd or NetworkManager"
		
		# Offer to enable dhcpcd as a fallback
		if ask "Enable dhcpcd service to ensure network connectivity?"; then
			einfo "Enabling dhcpcd service as fallback for network connectivity"
			try emerge --verbose net-misc/dhcpcd
			enable_service dhcpcd
			einfo "dhcpcd service enabled - network connectivity ensured"
		else
			ewarn "No network service enabled - user must configure networking manually"
		fi
	fi
}

# Cleanup and environment reset functions
function unmount_and_clean_all() {
	einfo "Starting cleanup process to reset the environment..."
	
	# 1. Unmount all filesystems recursively
	einfo "Unmounting all chroot-related filesystems..."
	if mountpoint -q -- "${ROOT_MOUNTPOINT:-/mnt/gentoo}"; then
		# Use the existing gentoo_umount function which does a recursive unmount
		if command -v gentoo_umount >/dev/null 2>&1; then
			gentoo_umount
			einfo "Successfully unmounted '${ROOT_MOUNTPOINT:-/mnt/gentoo}'."
		else
			# Fallback: manual unmount with recursive and lazy options
			einfo "gentoo_umount not available, using manual unmount"
			try umount -R -l "${ROOT_MOUNTPOINT:-/mnt/gentoo}"
			einfo "Successfully unmounted '${ROOT_MOUNTPOINT:-/mnt/gentoo}'."
		fi
	else
		einfo "'${ROOT_MOUNTPOINT:-/mnt/gentoo}' is not currently mounted. Skipping."
	fi
	
	# 2. Close any open LUKS containers created by the script
	einfo "Checking for and closing LUKS containers..."
	# Detect active LUKS devices dynamically
	local luks_devices=()
	if command -v cryptsetup >/dev/null 2>&1; then
		luks_devices=($(ls /dev/mapper/ 2>/dev/null | grep -v '^control$' || true))
	fi
	
	# Also check for common LUKS device names used by the installer
	local common_luks_devices=("root" "luks_root_0" "luks_root_1" "luks_swap" "luks_efi")
	
	for device in "${luks_devices[@]}" "${common_luks_devices[@]}"; do
		if [[ -e "/dev/mapper/${device}" ]]; then
			einfo "Closing LUKS device: /dev/mapper/${device}"
			try cryptsetup close "${device}"
		fi
	done
	
	# 3. Stop any RAID arrays created by the script
	einfo "Checking for and stopping RAID arrays..."
	# Detect active RAID devices dynamically
	local raid_devices=()
	if command -v mdadm >/dev/null 2>&1; then
		raid_devices=($(ls /dev/md/ 2>/dev/null || true))
	fi
	
	# Also check for common RAID device names used by the installer
	local common_raid_devices=("/dev/md/root" "/dev/md/swap" "/dev/md/efi" "/dev/md/bios")
	
	for device in "${raid_devices[@]}" "${common_raid_devices[@]}"; do
		if [[ -e "${device}" ]]; then
			einfo "Stopping RAID array: ${device}"
			try mdadm --stop "${device}"
		fi
	done
	
	# 4. Deactivate all swap partitions as a safety measure
	einfo "Deactivating all swap devices..."
	try swapoff -a
	
	# 5. Remove the temporary installation directory
	local tmp_dir="${TMP_DIR:-/tmp/gentoo-install}"
	einfo "Removing temporary directory: $tmp_dir"
	if [[ -d "$tmp_dir" ]]; then
		rm -rf "$tmp_dir"
		einfo "Temporary directory removed."
	else
		einfo "Temporary directory not found. Skipping."
	fi
	
	# 6. Additional cleanup: remove any loop devices that might have been created
	einfo "Checking for and removing loop devices..."
	if command -v losetup >/dev/null 2>&1; then
		local loop_devices=($(losetup -l 2>/dev/null | awk 'NR>1 {print $1}' | sed 's/://' || true))
		for device in "${loop_devices[@]}"; do
			if [[ -n "$device" ]]; then
				einfo "Removing loop device: $device"
				try losetup -d "$device"
			fi
		done
	fi
	
	einfo "✅ Cleanup complete. You can now start a new installation process without rebooting."
	einfo "Note: If you encounter any issues, a system reboot may still be necessary."
}

function cleanup_on_exit() {
	einfo "🔄 Interrupt detected - performing automatic cleanup..."
	einfo "This may take a moment to safely unmount filesystems and close devices..."
	
	# Call the main cleanup function
	unmount_and_clean_all
	
	einfo "✅ Automatic cleanup completed due to interrupt"
	einfo "You can now start a new installation process without rebooting"
	exit 1
}

function generate_secure_password() {
	# Generate a secure random password with good entropy
	# Uses /dev/urandom for cryptographically secure randomness
	local password_length=16
	local password_chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
	
	# Generate password using /dev/urandom for security
	local password=""
	local i
	for ((i=0; i<password_length; i++)); do
		local random_byte
		random_byte=$(od -An -N1 -tu1 < /dev/urandom)
		local char_index=$((random_byte % ${#password_chars}))
		password="${password}${password_chars:$char_index:1}"
	done
	
	echo "$password"
}

# Legacy functions for backward compatibility
function install_stage3() {
	ewarn "install_stage3() is deprecated - use main_install() instead"
	main_install
}

function install_desktop_environment() {
	# CRITICAL: This function sets the correct Portage profile before installing desktop environments
	# Portage profiles are essential because they set dozens of critical, system-wide USE flags
	# required for graphical environments, such as X, gtk, dbus, policykit, and udisks.
	# Without the correct profile, desktop environments may be broken or incomplete.
	#
	# FUTURE-PROOF: This function now dynamically detects the latest available profile version
	# instead of hardcoding specific versions (e.g., 17.1, 23.0). It automatically adapts to
	# new Gentoo profile releases, ensuring long-term maintainability.
	
	[[ -z "$DESKTOP_ENVIRONMENT" ]] && return 0
	
	maybe_exec 'before_install_desktop_environment'
	
	einfo "Installing desktop environment: $DESKTOP_ENVIRONMENT"
	
	# Check if DE requires systemd but we're using OpenRC
	if [[ "$(de_requires_systemd "$DESKTOP_ENVIRONMENT")" == "true" && "$SYSTEMD" != "true" ]]; then
		ewarn "Warning: $DESKTOP_ENVIRONMENT requires systemd, but you're using OpenRC"
		ewarn "Installation may fail or the DE may not work properly"
		if ! ask "Continue with $DESKTOP_ENVIRONMENT installation?"; then
			return 1
		fi
	fi
	
	# Set the correct Portage profile based on the selected DE
	einfo "Setting Portage profile for $DESKTOP_ENVIRONMENT..."
	local profile_type=""
	local selected_profile=""
	
	# Determine the base profile type needed
	if [[ "$DESKTOP_ENVIRONMENT" == "kde" ]]; then
		profile_type="desktop/plasma"
	elif [[ "$DESKTOP_ENVIRONMENT" == "gnome" ]]; then
		profile_type="desktop/gnome"
	else
		# For XFCE, Hyprland, etc., use the generic desktop profile
		profile_type="desktop"
	fi
	
	# Append init system if systemd is used
	if [[ "$SYSTEMD" == "true" ]]; then
		# GNOME profile already includes systemd
		if [[ "$profile_type" != "desktop/gnome" ]]; then
			profile_type+="/systemd"
		fi
	fi
	
	# Dynamically find the latest stable profile matching the type
	# This makes the script future-proof (e.g., for profile version 23.0)
	# BARU (Final dan Benar)
    selected_profile=$(eselect profile list | grep "${profile_type}" | grep -v 'developer\|hardened\|selinux' | sort -k2,2 -V -r | head -n 1 | awk '{gsub(/\[|\]/,"", $1); print $1}')
	
	if [[ -n "$selected_profile" ]]; then
		einfo "Dynamically selected latest profile: $selected_profile"
		try eselect profile set "$selected_profile"
	else
		ewarn "Could not dynamically determine the latest profile for '$profile_type'. Installation may continue with the default profile."
	fi
	
	# Verify profile was set correctly
	if [[ -n "$selected_profile" ]]; then
		local current_profile
		current_profile="$(eselect profile show | grep -oE '\[.*\]' | sed 's/\[\(.*\)\]/\1/')"
		if [[ "$current_profile" == "$selected_profile" ]]; then
			einfo "✅ Portage profile successfully set to: $current_profile"
			einfo "This profile provides essential USE flags for desktop environments (X, gtk, dbus, policykit, udisks)"
			
			# Check if profile change requires system updates
			if [[ "$current_profile" != "default/linux/amd64"* ]]; then
				einfo "🔄 Profile change detected. You may need to update your system after installation:"
				einfo "   emerge --update --deep --newuse @world"
				einfo "   This ensures all packages use the new profile's USE flags"
			fi
		else
			ewarn "⚠️  Profile verification failed. Expected: $selected_profile, Got: $current_profile"
			ewarn "Desktop environment may not function properly without correct profile"
			ewarn "You can manually set the profile with: eselect profile set $selected_profile"
		fi
	fi
	
	# Enable GURU overlay for Hyprland (required for packages like hypridle, waybar, wofi)
	# IMPROVED: This section now uses the robust overlay management function
	if [[ "$DESKTOP_ENVIRONMENT" == "hyprland" ]]; then
		einfo "Hyprland selected. Enabling the GURU overlay for required packages..."
		
		# Use the robust overlay management function
		if manage_overlay_robustly "guru"; then
			einfo "✅ GURU overlay setup completed successfully"
		else
			ewarn "⚠️  GURU overlay setup encountered issues, but continuing with installation"
			ewarn "Some Hyprland packages may not be available immediately"
		fi
		
		# CRITICAL: Ensure GCC is up to date for Hyprland compilation
		# Hyprland requires GCC 15+ but older Stage3 tarballs may have GCC 14
		if ensure_gcc_compatibility 15 "Hyprland"; then
			einfo "✅ GCC compatibility check passed for Hyprland"
		else
			ewarn "⚠️  GCC compatibility check failed for Hyprland"
			ewarn "Installation may fail due to compiler incompatibility"
		fi
		
		# Verify that key Hyprland packages are now available
		einfo "Verifying GURU overlay availability..."
		local key_packages=("gui-wm/hyprland" "gui-apps/hypridle" "gui-apps/waybar" "gui-apps/wofi")
		local missing_packages=()
		
		for package in "${key_packages[@]}"; do
			if emerge --search "$package" >/dev/null 2>&1; then
				einfo "✅ Package available: $package"
			else
				ewarn "⚠️  Package not found: $package"
				missing_packages+=("$package")
			fi
		done
		
		if [[ -v missing_packages && ${#missing_packages[@]} -gt 0 ]]; then
			ewarn "Some Hyprland packages are still not available: ${missing_packages[*]}"
			ewarn "This may indicate a sync issue. Consider running: emerge --sync guru"
			
			# Provide additional troubleshooting information
			einfo "🔍 GURU overlay troubleshooting:"
			einfo "   • Check if GURU is enabled: eselect repository list"
			einfo "   • Check GURU sync status: emerge --sync guru"
			einfo "   • Verify GURU configuration: cat /etc/portage/repos.conf/guru.conf"
		fi
	fi
	
	# Install DE packages
	local de_packages="${DE_PACKAGES[$DESKTOP_ENVIRONMENT]}"
	if [[ -n "$de_packages" ]]; then
		einfo "Installing $DESKTOP_ENVIRONMENT packages: $de_packages"
		try emerge --verbose $de_packages
		
		# Configure KDE-specific USE flags if installing KDE
		configure_kde_use_flags
	else
		ewarn "No package definition found for $DESKTOP_ENVIRONMENT"
		return 1
	fi
	
	# Install essential DE packages (ALWAYS installed, cannot be overridden)
	local essential_packages
	essential_packages="$(get_essential_packages_for_de "$DESKTOP_ENVIRONMENT")"
	if [[ -n "$essential_packages" ]]; then
		einfo "Installing essential $DESKTOP_ENVIRONMENT packages (required for functionality): $essential_packages"
		einfo "These packages include critical components like input drivers and desktop-specific tools"
		
		# Validate that essential packages are available in Portage
		einfo "Validating essential packages availability..."
		local packages_array=($essential_packages)
		local missing_packages=()
		
		for package in "${packages_array[@]}"; do
			if emerge --search "$package" >/dev/null 2>&1; then
				einfo "✅ Package available: $package"
			else
				ewarn "⚠️  Package not found: $package"
				missing_packages+=("$package")
			fi
		done
		
		if [[ -v missing_packages && ${#missing_packages[@]} -gt 0 ]]; then
			ewarn "Some essential packages are not available: ${missing_packages[*]}"
			ewarn "This may indicate a Portage sync issue or missing overlays"
			ewarn "Consider running: emerge --sync"
		fi
		
		# Install packages individually for better error handling
		for package in "${packages_array[@]}"; do
			einfo "Installing essential package: $package"
			if try emerge --verbose "$package"; then
				einfo "✅ Successfully installed: $package"
			else
				ewarn "⚠️  Failed to install essential package: $package"
				ewarn "This may affect desktop environment functionality"
				ewarn "You can try to install it manually later with: emerge --verbose $package"
			fi
		done
	else
		einfo "No essential packages defined for $DESKTOP_ENVIRONMENT"
	fi
	
	# Install additional DE packages (can be overridden by user configuration)
	local additional_packages="${DE_ADDITIONAL_PACKAGES[$DESKTOP_ENVIRONMENT]}"
	if [[ -n "$additional_packages" ]]; then
		einfo "Installing additional $DESKTOP_ENVIRONMENT packages: $additional_packages"
		try emerge --verbose $additional_packages
	fi
	
	# Install user-specified additional packages
	if [[ -v DESKTOP_ADDITIONAL_PACKAGES && ${#DESKTOP_ADDITIONAL_PACKAGES[@]} -gt 0 ]]; then
		einfo "Installing user-specified additional packages: ${DESKTOP_ADDITIONAL_PACKAGES[*]}"
		try emerge --verbose "${DESKTOP_ADDITIONAL_PACKAGES[@]}"
	fi
	
	# Install Hyprland-specific dependencies if configuration is provided
	if [[ "$DESKTOP_ENVIRONMENT" == "hyprland" && -v HYPRLAND_CONFIG && -n "$HYPRLAND_CONFIG" ]]; then
		einfo "Installing Hyprland configuration dependencies..."
		
		# Parse the configuration to identify required packages
		local hypr_deps=()
		
		# Core Hyprland ecosystem packages
		hypr_deps+=("gui-apps/waybar" "gui-apps/wofi" "x11-terms/kitty")
		
		# Wallpaper and visual effects
		if echo "$HYPRLAND_CONFIG" | grep -q "swww"; then
			hypr_deps+=("gui-apps/swww")
		fi
		
		# Screenshot and clipboard tools
		if echo "$HYPRLAND_CONFIG" | grep -q "grim\|slurp\|wl-copy"; then
			hypr_deps+=("gui-apps/grim" "gui-apps/slurp" "gui-apps/wl-clipboard")
		fi
		
		# Audio control
		if echo "$HYPRLAND_CONFIG" | grep -q "wpctl\|playerctl"; then
			hypr_deps+=("media-video/wireplumber" "media-sound/playerctl")
		fi
		
		# Brightness control
		if echo "$HYPRLAND_CONFIG" | grep -q "brightnessctl"; then
			hypr_deps+=("app-misc/brightnessctl")
		fi
		
		# Notifications
		if echo "$HYPRLAND_CONFIG" | grep -q "mako"; then
			hypr_deps+=("gui-apps/mako")
		fi
		
		# Clipboard history
		if echo "$HYPRLAND_CONFIG" | grep -q "cliphist"; then
			hypr_deps+=("app-misc/cliphist")
		fi
		
		# Idle management
		if echo "$HYPRLAND_CONFIG" | grep -q "hypridle"; then
			hypr_deps+=("gui-apps/hypridle")
		fi
		
		# Polkit agent
		if echo "$HYPRLAND_CONFIG" | grep -q "polkit"; then
			hypr_deps+=("kde-plasma/polkit-kde-agent")
		fi
		
		# File manager
		if echo "$HYPRLAND_CONFIG" | grep -q "thunar"; then
			hypr_deps+=("xfce-base/thunar")
		fi
		
		# Performance monitoring
		if echo "$HYPRLAND_CONFIG" | grep -q "corectrl"; then
			hypr_deps+=("app-misc/corectrl")
		fi
		
		# Gaming tools
		if echo "$HYPRLAND_CONFIG" | grep -q "mangohud\|goverlay"; then
			hypr_deps+=("games-util/mangohud" "games-util/goverlay")
		fi
		
		# Remove duplicates
		hypr_deps=($(printf "%s\n" "${hypr_deps[@]}" | sort -u))
		
		if [[ -v hypr_deps && ${#hypr_deps[@]} -gt 0 ]]; then
			einfo "Installing Hyprland dependencies: ${hypr_deps[*]}"
			
			# Install packages individually for better error handling
			for package in "${hypr_deps[@]}"; do
				einfo "Installing Hyprland dependency: $package"
				if try emerge --verbose "$package"; then
					einfo "✅ Successfully installed: $package"
				else
					ewarn "⚠️  Failed to install Hyprland dependency: $package"
					ewarn "This may affect Hyprland functionality"
					ewarn "You can try to install it manually later with: emerge --verbose $package"
				fi
			done
		else
			einfo "No additional Hyprland dependencies identified"
		fi
	fi
	
	maybe_exec 'after_install_desktop_environment'
	
	# Provide user guidance about Portage profiles
	einfo "🎯 Portage Profile Information:"
	einfo "The installer has set your system to use the appropriate desktop profile."
	einfo "This profile provides essential USE flags for graphical environments:"
	einfo "  • X11 support (X, gtk, qt)"
	einfo "  • Desktop services (dbus, policykit, udisks)"
	einfo "  • Input device support (libinput, evdev)"
	einfo "  • Audio/video support (pipewire, wayland)"
	einfo ""
	einfo "If you need to change profiles later, use: eselect profile list"
	einfo "Current profile: $(eselect profile show | grep -oE '\[.*\]' | sed 's/\[\(.*\)\]/\1/')"
}

function configure_kde_use_flags() {
	[[ "$DESKTOP_ENVIRONMENT" == "kde" ]] || return 0
	
	einfo "Configuring KDE USE flags for optimal integration"
	
	# Create package.use directory if it doesn't exist
	mkdir -p /etc/portage/package.use || die "Could not create /etc/portage/package.use directory"
	
	# Set critical KDE USE flags for optimal functionality
	# These flags ensure NetworkManager integration, SDDM display manager, and KWallet support
	local kde_use_flags="networkmanager sddm display-manager elogind kwallet"
	
	einfo "Setting KDE Plasma USE flags: $kde_use_flags"
	echo "kde-plasma/plasma-meta $kde_use_flags" > /etc/portage/package.use/kde-plasma \
		|| die "Could not write KDE Plasma USE flags to /etc/portage/package.use/kde-plasma"
	
	# Also set NetworkManager USE flag for KDE applications if they're installed
	if [[ -v DE_ADDITIONAL_PACKAGES && -n "${DE_ADDITIONAL_PACKAGES[kde]}" ]] || [[ ${#DESKTOP_ADDITIONAL_PACKAGES[@]} -gt 0 ]]; then
		einfo "Setting NetworkManager USE flag for KDE applications"
		echo "kde-apps/kde-apps-meta networkmanager" >> /etc/portage/package.use/kde-apps \
			|| ewarn "Could not append KDE apps USE flags"
	fi
	
	einfo "KDE USE flags configured successfully"
	einfo "Note: These flags ensure optimal NetworkManager integration and KDE functionality"
}

function configure_kde_system() {
	[[ "$DESKTOP_ENVIRONMENT" == "kde" ]] || return 0
	
	einfo "Configuring KDE-specific system settings"
	
	# Configure KWallet PAM integration if enabled
	if [[ "${ENABLE_KDE_KWALLET_PAM:-true}" == "true" ]]; then
		if [[ -f /etc/pam.d/sddm ]]; then
			einfo "Configuring KWallet PAM integration for SDDM"
			
			# Check if KWallet PAM lines are already present
			if ! grep -q "pam_kwallet5.so" /etc/pam.d/sddm; then
				einfo "Adding KWallet PAM configuration to SDDM"
				
				# Add KWallet PAM lines for auto-unlocking
				# This allows KWallet to unlock automatically when user logs in
				cat >> /etc/pam.d/sddm << 'EOF'

# KWallet PAM integration for auto-unlocking
auth           optional        pam_kwallet5.so
session        optional        pam_kwallet5.so auto_start
EOF
				
				einfo "KWallet PAM configuration added to SDDM"
			else
				einfo "KWallet PAM configuration already present in SDDM"
			fi
		else
			ewarn "SDDM PAM configuration not found - KWallet auto-unlocking may not work"
		fi
	else
		einfo "KWallet PAM integration disabled by user configuration"
	fi
	
	# Configure polkit for non-root user authentication in KDE dialogs if enabled
	if [[ "${ENABLE_KDE_POLKIT_ADMIN:-true}" == "true" ]]; then
		einfo "Configuring polkit for KDE dialogs"
		
		# Create polkit rules directory if it doesn't exist
		mkdir -p /etc/polkit-1/rules.d || die "Could not create /etc/polkit-1/rules.d directory"
		
		# Set up wheel group as administrators for KDE dialogs
		# This allows users in the wheel group to authenticate for system operations
		if [[ ! -f /etc/polkit-1/rules.d/49-wheel.rules ]]; then
			einfo "Creating polkit rule for wheel group administrators"
			
			cat > /etc/polkit-1/rules.d/49-wheel.rules << 'EOF'
polkit.addAdminRule(function(action, subject) {
    return ["unix-group:wheel"];
});
EOF
			
			einfo "Polkit rule created: wheel group users can authenticate for system operations"
		else
			einfo "Polkit rule for wheel group already exists"
		fi
		
		# Set proper permissions for polkit rules
		chmod 644 /etc/polkit-1/rules.d/49-wheel.rules \
			|| ewarn "Could not set proper permissions on polkit rules"
		
		einfo "Polkit configuration completed: wheel group users can authenticate for KDE system dialogs"
	else
		einfo "Polkit administrative privileges disabled by user configuration"
		einfo "Users will need to use sudo or su for system operations"
	fi
	
	einfo "KDE system configuration completed successfully"
	if [[ "${ENABLE_KDE_KWALLET_PAM:-true}" == "true" ]]; then
		einfo "KWallet will auto-unlock when logging in via SDDM"
	fi
	if [[ "${ENABLE_KDE_POLKIT_ADMIN:-true}" == "true" ]]; then
		einfo "Users in wheel group can authenticate for KDE system dialogs"
	else
		einfo "Administrative privileges require sudo/su (polkit disabled)"
	fi
}

function install_display_manager() {
	[[ "$ENABLE_DISPLAY_MANAGER" == "none" ]] && return 0
	
	local dm="$ENABLE_DISPLAY_MANAGER"
	[[ "$dm" == "auto" ]] && dm="$(get_default_dm_for_de "$DESKTOP_ENVIRONMENT")"
	[[ "$dm" == "none" ]] && return 0
	
	einfo "Installing display manager: $dm"
	
	local dm_package="${DM_PACKAGES[$dm]}"
	if [[ -n "$dm_package" ]]; then
		try emerge --verbose "$dm_package"
	else
		ewarn "No package definition found for display manager: $dm"
		return 1
	fi
}

function install_network_manager() {
	[[ "$ENABLE_NETWORK_MANAGER" == "none" ]] && return 0
	
	local nm="$ENABLE_NETWORK_MANAGER"
	[[ "$nm" == "auto" ]] && nm="$(get_default_nm_for_de "$DESKTOP_ENVIRONMENT")"
	[[ "$nm" == "none" ]] && return 0
	
	einfo "Installing network manager: $nm"
	
	# Important: NetworkManager will handle all networking, including DHCP
	# The dhcpcd service will NOT be enabled to avoid conflicts
	einfo "Note: NetworkManager will handle DHCP and network configuration"
	
	local nm_package="${NM_PACKAGES[$nm]}"
	if [[ -n "$nm_package" ]]; then
		try emerge --verbose "$nm_package"
	else
		ewarn "No package definition found for network manager: $nm"
		return 1
	fi
}

function configure_desktop_services() {
	[[ -z "$DESKTOP_ENVIRONMENT" ]] && return 0
	
	maybe_exec 'before_configure_desktop_services'
	
	einfo "Configuring desktop environment services"
	
	# Enable display manager
	if [[ "$ENABLE_DISPLAY_MANAGER" != "none" ]]; then
		local dm="${ENABLE_DISPLAY_MANAGER:-auto}"
		[[ "$dm" == "auto" ]] && dm="$(get_default_dm_for_de "$DESKTOP_ENVIRONMENT")"
		if [[ "$dm" != "none" ]]; then
			enable_display_manager "$dm"
		fi
	fi
	
	# Enable network manager if needed
	if [[ "$ENABLE_NETWORK_MANAGER" != "none" ]]; then
		local nm="${ENABLE_NETWORK_MANAGER:-auto}"
		[[ "$nm" == "auto" ]] && nm="$(get_default_nm_for_de "$DESKTOP_ENVIRONMENT")"
		if [[ "$nm" != "none" ]]; then
			enable_network_manager "$nm"
		fi
	fi
	
	# Configure KDE-specific system settings if installing KDE
	configure_kde_system
	
	maybe_exec 'after_configure_desktop_services'
}

# GPU driver configuration function removed - too complex for automated installation
# Users can manually configure GPU drivers after installation if needed

function main_chroot() {
	# Skip if already mounted
	mountpoint -q -- "$1" \
		|| die "'$1' is not a mountpoint"

	gentoo_chroot "$@"
}

function install_performance_optimization() {
	[[ "${ENABLE_PERFORMANCE_OPTIMIZATION:-false}" != "true" ]] && return 0
	
	maybe_exec 'before_install_performance_optimization'
	
	einfo "Installing performance optimization tools"
	
	# Install CPU optimization tools
	try emerge --verbose app-portage/cpuid2cpuflags
	try emerge --verbose app-misc/resolve-march-native
	
	# Install system monitoring tools
	try emerge --verbose sys-process/btop

	try emerge --verbose net-misc/openssh
	try emerge --verbose app-eselect/eselect-repository
	# Note: dhcpcd is installed as a tool, not as a service
	# This avoids conflicts with NetworkManager
	try emerge --verbose net-misc/dhcpcd
	try emerge --verbose net-wireless/iw
	
	# Configure performance settings
	einfo "Configuring performance optimization"
	
	# Set CPU flags for native optimization
	if command -v cpuid2cpuflags &> /dev/null; then
		local cpu_flags
		cpu_flags="$(cpuid2cpuflags)"
		if [[ -n "$cpu_flags" ]]; then
			einfo "Setting CPU flags: $cpu_flags"
			echo "CPU_FLAGS_X86=\"$cpu_flags\"" >> /etc/portage/make.conf
		fi
	fi
	
	# Set march flags for native optimization
	if command -v resolve-march-native &> /dev/null; then
		local march_flags
		march_flags="$(resolve-march-native)"
		if [[ -n "$march_flags" ]]; then
			einfo "Setting march flags: $march_flags"
			echo "CFLAGS=\"$march_flags -O2 -pipe\"" >> /etc/portage/make.conf
			echo "CXXFLAGS=\"$march_flags -O2 -pipe\"" >> /etc/portage/make.conf
		fi
	fi
	
	maybe_exec 'after_install_performance_optimization'
}



function install_display_backend_testing() {
	[[ "${ENABLE_DISPLAY_BACKEND_TESTING:-false}" != "true" ]] && return 0
	
	maybe_exec 'before_install_display_backend_testing'
	
	einfo "Installing display backend testing tools"
	
	# Install display backend testing dependencies
	try emerge --verbose x11-apps/xdpyinfo
	try emerge --verbose x11-apps/xrandr
	
	# Install Wayland testing tools if using Wayland DE
	if [[ "$(is_wayland_de "$DESKTOP_ENVIRONMENT")" == "true" ]]; then
		try emerge --verbose gui-apps/wl-clipboard
	fi
	
	maybe_exec 'after_install_display_backend_testing'
}

function install_gpu_benchmarking() {
	[[ "${ENABLE_GPU_BENCHMARKING:-false}" != "true" ]] && return 0
	
	maybe_exec 'before_install_gpu_benchmarking'
	
	einfo "Installing GPU benchmarking tools"
	
	# Install OpenGL utilities
	try emerge --verbose x11-apps/mesa-progs
	
	maybe_exec 'after_install_gpu_benchmarking'
}

function apply_configured_package_management() {
	einfo "Applying configured package management settings"
	
	# Create package.use directory structure
	mkdir_or_die 0755 "/etc/portage/package.use"
	
	# Apply package USE rules
	if [[ -v PACKAGE_USE_RULES && ${#PACKAGE_USE_RULES[@]} -gt 0 ]]; then
		einfo "Applying ${#PACKAGE_USE_RULES[@]} package USE rules"
		
		# Create a comprehensive package.use file
		cat > /etc/portage/package.use/zz-autounmask <<EOF
# Package USE rules configured during installation
# Generated automatically by gentoo-easy-install
EOF
		
		for rule in "${PACKAGE_USE_RULES[@]}"; do
			if [[ -n "$rule" ]]; then
				einfo "Applying USE rule: $rule"
				echo "$rule" >> /etc/portage/package.use/zz-autounmask
			fi
		done
		
		# Also create individual files for better organization
		for rule in "${PACKAGE_USE_RULES[@]}"; do
			if [[ -n "$rule" ]]; then
				local package_atom="${rule%% *}"
				local use_flags="${rule#* }"
				
				if [[ -n "$package_atom" && -n "$use_flags" ]]; then
					local package_name="${package_atom##*/}"
					local package_file="/etc/portage/package.use/${package_name}"
					
					einfo "Creating package.use file for $package_atom"
					echo "# USE flags for $package_atom" > "$package_file"
					echo "$package_atom $use_flags" >> "$package_file"
				fi
			fi
		done
	fi
	
	# Create package.keywords directory structure
	mkdir_or_die 0755 "/etc/portage/package.keywords"
	
	# Apply package keywords
	if [[ -v PACKAGE_KEYWORDS && ${#PACKAGE_KEYWORDS[@]} -gt 0 ]]; then
		einfo "Applying ${#PACKAGE_KEYWORDS[@]} package keywords"
		
		# Create a comprehensive package.keywords file
		cat > /etc/portage/package.keywords/zz-autounmask <<EOF
# Package keywords configured during installation
# Generated automatically by gentoo-easy-install
EOF
		
		for keyword_rule in "${PACKAGE_KEYWORDS[@]}"; do
			if [[ -n "$keyword_rule" ]]; then
				einfo "Applying package keyword: $keyword_rule"
				echo "$keyword_rule" >> /etc/portage/package.keywords/zz-autounmask
			fi
		done
		
		# Also create individual files for better organization
		for keyword_rule in "${PACKAGE_KEYWORDS[@]}"; do
			if [[ -n "$keyword_rule" ]]; then
				local package_atom="${keyword_rule%% *}"
				local keywords="${keyword_rule#* }"
				
				if [[ -n "$package_atom" && -n "$keywords" ]]; then
					local package_name="${package_atom##*/}"
					local package_file="/etc/portage/package.keywords/${package_name}"
					
					einfo "Creating package.keywords file for $package_atom"
					echo "# Keywords for $package_atom" > "$package_file"
					echo "$package_atom $keywords" >> "$package_file"
				fi
			fi
		done
	fi
	

	
	# Apply overlays using the correct 'eselect repository enable' command
	if [[ -v OVERLAY_NAMES && ${#OVERLAY_NAMES[@]} -gt 0 ]]; then
		einfo "Configuring ${#OVERLAY_NAMES[@]} Portage overlay(s)..."
		
		# Ensure the management tool is installed
		if ! command -v eselect >/dev/null 2>&1 || ! eselect repository --version >/dev/null 2>&1; then
			einfo "Installing overlay management tools..."
			try emerge --verbose app-eselect/eselect-repository
		fi
		
		local new_overlays_enabled=false
		# Enable each new overlay
		for overlay_name in "${OVERLAY_NAMES[@]}"; do
			if ! eselect repository list -i | grep -q "^$overlay_name "; then
				einfo "Enabling overlay: $overlay_name"
				if try eselect repository enable "$overlay_name"; then
					new_overlays_enabled=true
				else
					ewarn "Failed to enable overlay '$overlay_name'. It may not be an official Gentoo overlay."
				fi
			else
				einfo "Overlay '$overlay_name' is already enabled."
			fi
		done
		
		# After enabling any new overlays, perform a single global sync
		if [[ "$new_overlays_enabled" == "true" ]]; then
		    einfo "Syncing all Portage repositories to fetch new overlays..."
		    try emerge --sync
		fi
		
		einfo "✅ All overlays successfully configured"
	fi
	
	einfo "Package management configuration applied successfully"
}

function get_disk_device_from_partition() {
	local partition_id="$1"
	local partition_device
	
	# Get the partition device from the partition ID
	partition_device="$(resolve_device_by_id "$partition_id")"
	
	# Resolve the real path to handle symbolic links correctly
	partition_device="$(realpath "$partition_device")"
	
	# Use lsblk to reliably trace the parent device of a partition
	# This is more robust than regex patterns and handles complex storage setups
	local disk_device
	
	if command -v lsblk >/dev/null 2>&1; then
		# Use lsblk -no pkname to get the parent device name
		# This handles LVM, software RAID, and other complex storage setups
		disk_device="$(lsblk -no pkname "$partition_device" 2>/dev/null | head -n1)"
		
		if [[ -n "$disk_device" && "$disk_device" != "loop" ]]; then
			# lsblk found a valid parent device
			echo "/dev/$disk_device"
			return 0
		fi
	fi
	
	# Fallback to regex patterns if lsblk is not available or fails
	# Handle various device naming patterns:
	# /dev/sda1 -> /dev/sda (SATA/SCSI)
	# /dev/sdb2 -> /dev/sdb
	# /dev/hda1 -> /dev/hda (IDE)
	# /dev/nvme0n1p1 -> /dev/nvme0n1 (NVMe)
	# /dev/nvme0n2p2 -> /dev/nvme0n2
	# /dev/vda1 -> /dev/vda (Virtual)
	# /dev/xvda1 -> /dev/xvda (Xen)
	
	if [[ "$partition_device" =~ ^(/dev/[a-z]+[0-9]*n[0-9]+)p[0-9]+$ ]]; then
		# NVMe devices: /dev/nvme0n1p1 -> /dev/nvme0n1
		disk_device="${BASH_REMATCH[1]}"
	elif [[ "$partition_device" =~ ^(/dev/[a-z]+[0-9]*)p?[0-9]+$ ]]; then
		# SATA/SCSI/IDE/Virtual: /dev/sda1, /dev/hda1, /dev/vda1 -> /dev/sda, /dev/hda, /dev/vda
		disk_device="${BASH_REMATCH[1]}"
	else
		# Fallback: try to get the parent device using dirname
		# This handles cases where the pattern doesn't match
		disk_device="$(dirname "$partition_device")"
		# If dirname returns "/dev", try to get the device without the partition number
		if [[ "$disk_device" == "/dev" ]]; then
			# Remove the last number(s) from the device name
			disk_device="$(echo "$partition_device" | sed -E 's/[0-9]+$//')"
		fi
	fi
	
	echo "$disk_device"
}

function configure_raid_uefi_boot_order() {
	[[ "${USED_RAID:-false}" == "true" ]] || return 0
	[[ $IS_EFI == "true" ]] || return 0
	
	einfo "Configuring enhanced RAID support for UEFI systems"
	
	# Install efibootmgr for UEFI boot entry management
	if ! command -v efibootmgr >/dev/null 2>&1; then
		einfo "Installing efibootmgr for UEFI boot management"
		try emerge --verbose sys-boot/efibootmgr
	fi
	
	# Get all RAID member disks
	local raid_members=()
	local raid_devices
	
	# Detect RAID arrays and their member devices
	if command -v mdadm >/dev/null 2>&1; then
		raid_devices="$(mdadm --detail --scan 2>/dev/null | grep -o '/dev/md[0-9]*' || true)"
		
		for raid_device in $raid_devices; do
			if [[ -b "$raid_device" ]]; then
				einfo "Found RAID array: $raid_device"
				
				# Get member devices for this RAID array
				local members
				members="$(mdadm --detail "$raid_device" 2>/dev/null | grep -E '^[[:space:]]*[0-9]+[[:space:]]+[^[:space:]]+' | awk '{print $NF}' || true)"
				
				for member in $members; do
					if [[ -b "$member" ]]; then
						raid_members+=("$member")
						einfo "  RAID member: $member"
					fi
				done
			fi
		done
	fi
	
	# If we found RAID members, configure UEFI boot order
	if [[ -v raid_members && ${#raid_members[@]} -gt 0 ]]; then
		einfo "Configuring UEFI boot order for ${#raid_members[@]} RAID members"
		
		# Get current UEFI boot entries
		local current_boot_order
		current_boot_order="$(efibootmgr -v 2>/dev/null | grep -E '^Boot[0-9]+' | sort | awk '{print $1}' | sed 's/Boot//' | tr '\n' ',' | sed 's/,$//' || echo '')"
		
		if [[ -n "$current_boot_order" ]]; then
			einfo "Current UEFI boot order: $current_boot_order"
			
			# Create optimized boot order with RAID members first
			local optimized_order=""
			local other_entries=""
			
			# Separate RAID members from other boot entries
			for entry in ${current_boot_order//,/ }; do
				local entry_info
				entry_info="$(efibootmgr -v 2>/dev/null | grep -E "^Boot$entry[[:space:]]" || true)"
				
				if [[ "$entry_info" =~ /dev/[a-z]+ ]]; then
					local device
					device="$(echo "$entry_info" | grep -o '/dev/[a-z]+[0-9]*' | head -n1 || true)"
					
					if [[ -n "$device" ]]; then
						# Check if this device is a RAID member
						local is_raid_member=false
						for raid_member in "${raid_members[@]}"; do
							if [[ "$device" == "$raid_member" ]] || [[ "$device" =~ ${raid_member%?} ]]; then
								is_raid_member=true
								break
							fi
						done
						
						if [[ "$is_raid_member" == "true" ]]; then
							optimized_order="$entry,$optimized_order"
						else
							other_entries="$other_entries,$entry"
						fi
					fi
				fi
			done
			
			# Combine optimized order: RAID members first, then others
			optimized_order="${optimized_order%,}${other_entries%,}"
			
			if [[ -n "$optimized_order" && "$optimized_order" != "$current_boot_order" ]]; then
				einfo "Setting optimized UEFI boot order: $optimized_order"
				try efibootmgr -o "$optimized_order"
				einfo "UEFI boot order optimized for RAID redundancy"
			else
				einfo "UEFI boot order already optimized"
			fi
		fi
		
		# Install GRUB to each RAID member for redundancy
		einfo "Installing GRUB to RAID member devices for redundancy"
		for member in "${raid_members[@]}"; do
			local member_disk
			member_disk="$(get_disk_device_from_partition "$member")"
			
			if [[ -n "$member_disk" && -b "$member_disk" ]]; then
				einfo "Installing GRUB to RAID member disk: $member_disk"
				try grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="gentoo-raid-$(basename "$member_disk")" "$member_disk"
			fi
		done
		
		einfo "RAID UEFI boot order configuration completed"
		einfo "System will automatically fail over to available RAID members"
	else
		einfo "No RAID members detected for UEFI boot order optimization"
	fi
}

function configure_raid_bios_bootloader() {
	[[ "${USED_RAID:-false}" == "true" ]] || return 0
	[[ $IS_EFI != "true" ]] || return 0
	
	einfo "Configuring enhanced RAID support for BIOS systems"
	
	# Get all RAID member disks
	local raid_members=()
	local raid_devices
	
	# Detect RAID arrays and their member devices
	if command -v mdadm >/dev/null 2>&1; then
		raid_devices="$(mdadm --detail --scan 2>/dev/null | grep -o '/dev/md[0-9]*' || true)"
		
		for raid_device in $raid_devices; do
			if [[ -b "$raid_device" ]]; then
				einfo "Found RAID array: $raid_device"
				
				# Get member devices for this RAID array
				local members
				members="$(mdadm --detail "$raid_device" 2>/dev/null | grep -E '^[[:space:]]*[0-9]+[[:space:]]+[^[:space:]]+' | awk '{print $NF}' || true)"
				
				for member in $members; do
					if [[ -b "$member" ]]; then
						raid_members+=("$member")
						einfo "  RAID member: $member"
					fi
				done
			fi
		done
	fi
	
	# If we found RAID members, install GRUB to each for redundancy
	if [[ -v raid_members && ${#raid_members[@]} -gt 0 ]]; then
		einfo "Installing GRUB to ${#raid_members[@]} RAID member devices for redundancy"
		
		for member in "${raid_members[@]}"; do
			local member_disk
			member_disk="$(get_disk_device_from_partition "$member")"
			
			if [[ -n "$member_disk" && -b "$member_disk" ]]; then
				einfo "Installing GRUB to RAID member disk: $member_disk"
				try grub-install "$member_disk"
			fi
		done
		
		einfo "RAID BIOS bootloader configuration completed"
		einfo "System will automatically fail over to available RAID members"
	else
		einfo "No RAID members detected for BIOS bootloader redundancy"
	fi
}

function manage_overlay_robustly() {
	# Robust overlay management function that handles various overlay states
	# Usage: manage_overlay_robustly <overlay_name> [sync_after_enable]
	# Args:
	#   overlay_name: Name of the overlay (e.g., "guru", "gentoo-zh")
	#   sync_after_enable: Whether to sync after enabling (default: true)
	
	local overlay_name="$1"
	local sync_after_enable="${2:-true}"
	
	[[ -n "$overlay_name" ]] || return 1
	
	einfo "Managing overlay: $overlay_name"
	
	# Install overlay management tools if not present
	if ! command -v eselect >/dev/null 2>&1 || ! eselect repository --help >/dev/null 2>&1; then
		einfo "Installing overlay management tools..."
		try emerge --verbose app-eselect/eselect-repository
	fi
	
	# Check if overlay is already enabled
	if eselect repository list | grep -q "$overlay_name"; then
		einfo "✅ Overlay '$overlay_name' is already enabled"
		return 0
	fi
	
	# Check if overlay exists but is disabled
	if eselect repository list --disabled | grep -q "$overlay_name"; then
		einfo "Overlay '$overlay_name' found but disabled. Enabling it..."
		if try eselect repository enable "$overlay_name"; then
			einfo "✅ Overlay '$overlay_name' successfully enabled"
		else
			ewarn "⚠️  Failed to enable overlay '$overlay_name'"
			return 1
		fi
	else
		# Check if overlay configuration already exists in the system
		if [[ -f "/etc/portage/repos.conf/${overlay_name}.conf" ]] || \
		   [[ -f /usr/share/portage/config/repos.conf ]] && grep -q "$overlay_name" /usr/share/portage/config/repos.conf; then
			einfo "Overlay '$overlay_name' configuration found in system, attempting to enable..."
			if try eselect repository enable "$overlay_name"; then
				einfo "✅ Overlay '$overlay_name' successfully enabled from existing configuration"
			else
				ewarn "⚠️  Failed to enable existing overlay '$overlay_name'"
				return 1
			fi
		else
			# Try to add the overlay
			einfo "Adding overlay '$overlay_name'..."
			if eselect repository add "$overlay_name" 2>/dev/null; then
				einfo "✅ Overlay '$overlay_name' successfully added"
			else
				# If add fails, try to enable it (it might already exist)
				einfo "Overlay '$overlay_name' add failed, attempting to enable existing repository..."
				if try eselect repository enable "$overlay_name"; then
					einfo "✅ Overlay '$overlay_name' successfully enabled"
				else
					ewarn "⚠️  Failed to add or enable overlay '$overlay_name'"
					ewarn "This may indicate the overlay is not available or there are permission issues"
					return 1
				fi
			fi
		fi
	fi
	
	# Sync the overlay if requested
	if [[ "$sync_after_enable" == "true" ]]; then
		einfo "Syncing overlay '$overlay_name'..."
		if try emerge --sync "$overlay_name"; then
			einfo "✅ Overlay '$overlay_name' successfully synced"
		else
			ewarn "⚠️  Overlay '$overlay_name' sync failed. This may be due to network issues or repository problems."
			ewarn "You can try to sync manually later with: emerge --sync $overlay_name"
			ewarn "For now, continuing - some packages may not be available immediately."
		fi
	fi
	
	einfo "✅ Overlay '$overlay_name' management completed"
	return 0
}

function ensure_gcc_compatibility() {
	# Ensure GCC version is compatible with specified requirements
	# Usage: ensure_gcc_compatibility <min_major_version> [package_name]
	# Args:
	#   min_major_version: Minimum GCC major version required (e.g., 15)
	#   package_name: Name of package requiring this GCC version (for logging)
	
	local min_gcc_major="$1"
	local package_name="${2:-"the selected package"}"
	
	[[ -n "$min_gcc_major" ]] || return 1
	
	einfo "Checking GCC compatibility for $package_name (requires GCC $min_gcc_major+)..."
	
	# Get current GCC version
	local current_gcc_version
	current_gcc_version=$(gcc --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
	
	if [[ -z "$current_gcc_version" ]]; then
		ewarn "⚠️  Could not determine current GCC version"
		return 1
	fi
	
	local gcc_major
	gcc_major=$(echo "$current_gcc_version" | cut -d. -f1)
	
	if [[ "$gcc_major" -ge "$min_gcc_major" ]]; then
		einfo "✅ GCC version $current_gcc_version is compatible (requires $min_gcc_major+)"
		return 0
	fi
	
	ewarn "⚠️  Current GCC version $current_gcc_version is too old for $package_name (requires GCC $min_gcc_major+)"
	einfo "🔄 Upgrading GCC to latest version for compatibility..."
	
	# Create package.accept_keywords directory if it doesn't exist
	mkdir -p /etc/portage/package.accept_keywords || die "Could not create package.accept_keywords directory"
	
	# Unmask the latest GCC version
	einfo "Unmasking latest GCC version..."
	echo "sys-devel/gcc" >> /etc/portage/package.accept_keywords/gcc || ewarn "Could not unmask GCC"
	
	# Sync Portage to get latest package information
	einfo "Syncing Portage for latest GCC availability..."
	try emerge --sync
	
	# Emerge the new compiler
	einfo "Installing latest GCC version (this may take a while)..."
	if try emerge -v1 sys-devel/gcc; then
		einfo "✅ GCC upgrade completed successfully"
		
		# Rebuild libtool after major GCC upgrade
		einfo "Rebuilding libtool for new GCC compatibility..."
		try emerge -v1 dev-build/libtool
		
		# Find and select the latest GCC version
		local latest_gcc
		latest_gcc=$(gcc-config -l | awk '{gsub(/\[|\]/,"", $1); print $1}' | sort -nr | head -n1)
		if [[ -n "$latest_gcc" ]]; then
			einfo "Switching to GCC version $latest_gcc"
			if try gcc-config "$latest_gcc"; then
				# Source profile to update environment
				source /etc/profile
				einfo "✅ Successfully switched to GCC version $latest_gcc"
				
				# Verify the new GCC version
				local new_gcc_version
				new_gcc_version=$(gcc --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
				local new_gcc_major
				new_gcc_major=$(echo "$new_gcc_version" | cut -d. -f1)
				
				einfo "Current GCC version: $new_gcc_version"
				
				if [[ "$new_gcc_major" -ge "$min_gcc_major" ]]; then
					einfo "✅ GCC upgrade successful - now compatible with $package_name"
					return 0
				else
					ewarn "⚠️  GCC upgrade completed but version $new_gcc_version still not compatible with $package_name"
					return 1
				fi
			else
				ewarn "⚠️  Failed to switch to new GCC version"
				return 1
			fi
		else
			ewarn "⚠️  Could not determine latest GCC version to select"
			return 1
		fi
	else
		ewarn "⚠️  GCC upgrade failed. $package_name installation may fail due to compiler incompatibility."
		ewarn "You may need to manually upgrade GCC: emerge -v1 sys-devel/gcc"
		return 1
	fi
}
