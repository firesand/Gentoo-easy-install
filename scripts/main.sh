# shellcheck source=./scripts/protection.sh
source "$GENTOO_INSTALL_REPO_DIR/scripts/protection.sh" || exit 1

# shellcheck source=./scripts/desktop_environments.sh
source "$GENTOO_INSTALL_REPO_DIR/scripts/desktop_environments.sh" || exit 1


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

	chmod 644 /etc/portage/make.conf \
		|| die "Could not chmod 644 /etc/portage/make.conf"
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

	local modules=()
	[[ $USED_RAID == "true" ]] \
		&& modules+=("mdraid")
	[[ $USED_LUKS == "true" ]] \
		&& modules+=("crypt crypt-gpg")
	[[ $USED_BTRFS == "true" ]] \
		&& modules+=("btrfs")
	[[ $USED_ZFS == "true" ]] \
		&& modules+=("zfs")

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
		modules+=("systemd-networkd")
	fi

	# Generate initramfs
	# TODO --conf          "/dev/null" \
	# TODO --confdir       "/dev/null" \
	try dracut \
		--kver          "$kver" \
		--zstd \
		--no-hostonly \
		--ro-mnt \
		--add           "bash ${modules[*]}" \
		"${dracut_opts[@]}" \
		--force \
		"$output"

	# Create script to repeat initramfs generation
	cat > "$(dirname "$output")/generate_initramfs.sh" <<EOF
#!/bin/bash
kver="\$1"
output="\$2" # At setup time, this was "$output"
[[ -n "\$kver" ]] || { echo "usage \$0 <kernel_version> <output>" >&2; exit 1; }
dracut \\
	--kver          "\$kver" \\
	--zstd \\
	--no-hostonly \\
	--ro-mnt \\
	--add           "bash ${modules[*]}" \\
	${dracut_opts[@]@Q} \\
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

		if [[ ${#raid_members[@]} -eq 0 ]]; then
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

	# Install syslinux MBR record
	einfo "Copying syslinux MBR record"
	local gptdev
	gptdev="$(resolve_device_by_id "${DISK_ID_PART_TO_GPT_ID[$DISK_ID_BIOS]}")" \
		|| die "Could not resolve device with id=${DISK_ID_PART_TO_GPT_ID[$DISK_ID_BIOS]}"
	try dd bs=440 conv=notrunc count=1 if=/usr/share/syslinux/gptmbr.bin of="$gptdev"
}

function install_kernel() {
	# Install vanilla kernel
	einfo "Installing vanilla kernel and related tools"

	if [[ $IS_EFI == "true" ]]; then
		install_kernel_efi
	else
		install_kernel_bios
	fi

	einfo "Installing linux-firmware"
	echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" >> /etc/portage/package.license \
		|| die "Could not write to /etc/portage/package.license"
	try emerge --verbose linux-firmware
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
}

function main_install_gentoo_in_chroot() {
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
	
	# Determine required modules based on system configuration
	local modules=()
	[[ $USED_RAID == "true" ]] && modules+=("mdraid")
	[[ $USED_LUKS == "true" ]] && modules+=("crypt")
	[[ $USED_BTRFS == "true" ]] && modules+=("btrfs")
	[[ $USED_ZFS == "true" ]] && modules+=("zfs")
	
	# Ensure we have at least basic modules
	[[ ${#modules[@]} -eq 0 ]] && modules=("bash")
	
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
		modules+=("systemd-networkd")
	fi
	
	# Generate initramfs using proven dracut command
	einfo "Using modules: ${modules[*]}"
	try dracut \
		--kver "$kver" \
		--zstd \
		--no-hostonly \
		--ro-mnt \
		--add "bash ${modules[*]}" \
		--add-drivers "virtio virtio_pci virtio_net virtio_blk" \
		--force \
		--verbose \
		/boot/initramfs-"$kver".img

	# Install cryptsetup if LUKS is used
	if [[ $USED_LUKS == "true" ]]; then
		einfo "Installing cryptsetup for LUKS support"
		try emerge --verbose sys-fs/cryptsetup
	fi
	
	# Install filesystem tools based on configuration
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
	if [[ "$ENABLE_PERFORMANCE_OPTIMIZATION" == "true" ]]; then
		einfo "Installing performance optimization tools"
		install_performance_optimization
	fi
	

	
	# Install additional packages specified by user
	if [[ ${#ADDITIONAL_PACKAGES[@]} -gt 0 ]]; then
		einfo "Installing additional packages: ${ADDITIONAL_PACKAGES[*]}"
		try emerge --verbose "${ADDITIONAL_PACKAGES[@]}"
	fi
}

function configure_bootloader() {
	einfo "Configuring bootloader"
	
	# Install and configure GRUB
	einfo "Installing and configuring GRUB"
	try emerge --verbose sys-boot/grub
	
	if [[ $IS_EFI == "true" ]]; then
		einfo "Installing EFI bootloader"
		try emerge --verbose sys-boot/grub:2
		grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=gentoo
	else
		einfo "Installing BIOS bootloader"
		# Get the disk device from the root partition ID
		local disk_device
		disk_device="$(get_disk_device_from_partition "$DISK_ID_ROOT")"
		einfo "Installing GRUB to disk: $disk_device"
		grub-install "$disk_device"
	fi
	
	# Generate GRUB configuration
	einfo "Generating GRUB configuration"
	grub-mkconfig -o /boot/grub/grub.cfg
	
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
}

function finalize_installation() {
	einfo "Finalizing installation"
	
	# Set root password
	einfo "Setting root password"
	passwd root || ewarn "Could not set root password - user will need to set it manually"
	
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
	
	# Install and enable dhcpcd
	einfo "Installing dhcpcd"
	try emerge --verbose net-misc/dhcpcd
	enable_service dhcpcd
	
	# Enable SSH if requested
	if [[ $ENABLE_SSHD == "true" ]]; then
		enable_sshd
	fi
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

# Legacy functions for backward compatibility
function install_stage3() {
	ewarn "install_stage3() is deprecated - use main_install() instead"
	main_install
}

function install_desktop_environment() {
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
	
	# Install DE packages
	local de_packages="${DE_PACKAGES[$DESKTOP_ENVIRONMENT]}"
	if [[ -n "$de_packages" ]]; then
		einfo "Installing $DESKTOP_ENVIRONMENT packages: $de_packages"
		try emerge --verbose $de_packages
	else
		ewarn "No package definition found for $DESKTOP_ENVIRONMENT"
		return 1
	fi
	
	# Install additional DE packages
	local additional_packages="${DE_ADDITIONAL_PACKAGES[$DESKTOP_ENVIRONMENT]}"
	if [[ -n "$additional_packages" ]]; then
		einfo "Installing additional $DESKTOP_ENVIRONMENT packages: $additional_packages"
		try emerge --verbose $additional_packages
	fi
	
	# Install user-specified additional packages
	if [[ ${#DESKTOP_ADDITIONAL_PACKAGES[@]} -gt 0 ]]; then
		einfo "Installing user-specified additional packages: ${DESKTOP_ADDITIONAL_PACKAGES[*]}"
		try emerge --verbose "${DESKTOP_ADDITIONAL_PACKAGES[@]}"
	fi
	
	maybe_exec 'after_install_desktop_environment'
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
	
	maybe_exec 'after_configure_desktop_services'
}

function install_gpu_drivers() {
	# Auto-detect GPU driver if not specified
	if [[ -z "$GPU_DRIVER" ]]; then
		if [[ -n "$DESKTOP_ENVIRONMENT" ]]; then
			GPU_DRIVER="$(get_recommended_gpu_driver_for_de "$DESKTOP_ENVIRONMENT")"
			einfo "Auto-detected GPU driver: $GPU_DRIVER (recommended for $DESKTOP_ENVIRONMENT)"
		else
			return 0
		fi
	fi
	
	maybe_exec 'before_install_gpu_drivers'
	
	einfo "Installing GPU drivers: $GPU_DRIVER"
	
	# Check if DE requires Wayland but GPU driver doesn't support it
	if [[ "$(is_wayland_de "$DESKTOP_ENVIRONMENT")" == "true" && "$(gpu_driver_supports_wayland "$GPU_DRIVER")" == "false" ]]; then
		ewarn "Warning: $DESKTOP_ENVIRONMENT is a Wayland DE, but $GPU_DRIVER doesn't support Wayland well"
		ewarn "You may experience issues or fallback to X11"
		if ! ask "Continue with $GPU_DRIVER installation?"; then
			return 1
		fi
	fi
	
	# Install GPU driver packages
	local gpu_packages="${GPU_DRIVER_PACKAGES[$GPU_DRIVER]}"
	if [[ -n "$gpu_packages" ]]; then
		einfo "Installing $GPU_DRIVER packages: $gpu_packages"
		try emerge --verbose $gpu_packages
	else
		ewarn "No package definition found for GPU driver: $GPU_DRIVER"
		return 1
	fi
	
	# Install additional GPU driver packages
	if [[ ${#GPU_DRIVER_ADDITIONAL_PACKAGES[@]} -gt 0 ]]; then
		einfo "Installing additional GPU driver packages: ${GPU_DRIVER_ADDITIONAL_PACKAGES[*]}"
		try emerge --verbose "${GPU_DRIVER_ADDITIONAL_PACKAGES[@]}"
	fi
	
	# Install Vulkan support if enabled
	if [[ "$ENABLE_VULKAN" == "true" ]]; then
		einfo "Installing Vulkan support for $GPU_DRIVER"
		case "$GPU_DRIVER" in
			amd|mesa)
				try emerge --verbose media-libs/mesa-vulkan-drivers
				;;
			nvidia)
				try emerge --verbose media-libs/mesa-vulkan-drivers
				;;
			intel)
				try emerge --verbose media-libs/mesa-vulkan-drivers
				;;
		esac
	fi
	
	# Install OpenCL support if enabled
	if [[ "$ENABLE_OPENCL" == "true" ]]; then
		einfo "Installing OpenCL support for $GPU_DRIVER"
		case "$GPU_DRIVER" in
			amd|mesa)
				try emerge --verbose media-libs/mesa-opencl
				;;
			nvidia)
				try emerge --verbose media-libs/opencl-icd-loader
				;;
			intel)
				try emerge --verbose media-libs/mesa-opencl
				;;
		esac
	fi
	
	maybe_exec 'after_install_gpu_drivers'
}

function configure_gpu_drivers() {
	[[ -z "$GPU_DRIVER" ]] && return 0
	
	maybe_exec 'before_configure_gpu_drivers'
	
	einfo "Configuring GPU drivers: $GPU_DRIVER"
	
	# Configure USE flags for GPU drivers
	local use_flags="${GPU_DRIVER_USE_FLAGS[$GPU_DRIVER]}"
	if [[ -n "$use_flags" ]]; then
		einfo "Setting USE flags for $GPU_DRIVER: $use_flags"
		echo "USE=\"\${USE} $use_flags\"" >> /etc/portage/make.conf
	fi
	
	# Configure kernel modules for GPU drivers
	local kernel_modules="${GPU_DRIVER_KERNEL_MODULES[$GPU_DRIVER]}"
	if [[ -n "$kernel_modules" ]]; then
		einfo "Configuring kernel modules for $GPU_DRIVER: $kernel_modules"
		echo "MODULES_LOAD=\"\${MODULES_LOAD} $kernel_modules\"" >> /etc/conf.d/modules
	fi
	
	# NVIDIA-specific configuration
	if [[ "$GPU_DRIVER" == "nvidia" ]]; then
		einfo "Configuring NVIDIA drivers"
		
		# Create NVIDIA configuration directory
		mkdir_or_die 0755 "/etc/modprobe.d"
		
		# Configure NVIDIA kernel module options
		cat > /etc/modprobe.d/nvidia.conf <<EOF
# NVIDIA driver configuration
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_UsePageAttributeTable=1
EOF
		
		# Enable NVIDIA persistence daemon
		if [[ $SYSTEMD == "true" ]]; then
			enable_service nvidia-persistenced
		else
			# For OpenRC, add to default runlevel
			rc-update add nvidia-persistenced default
		fi
	fi
	
	# AMD-specific configuration
	if [[ "$GPU_DRIVER" == "amd" || "$GPU_DRIVER" == "mesa" ]]; then
		einfo "Configuring AMD drivers"
		
		# Create AMD configuration directory
		mkdir_or_die 0755 "/etc/modprobe.d"
		
		# Configure AMD kernel module options
		cat > /etc/modprobe.d/amdgpu.conf <<EOF
# AMD GPU driver configuration
options amdgpu gpu_recovery=1
options amdgpu ppfeaturemask=0xffffffff
EOF
	fi
	
	# Intel-specific configuration
	if [[ "$GPU_DRIVER" == "intel" || "$GPU_DRIVER" == "mesa" ]]; then
		einfo "Configuring Intel drivers"
		
		# Create Intel configuration directory
		mkdir_or_die 0755 "/etc/modprobe.d"
		
		# Configure Intel kernel module options
		cat > /etc/modprobe.d/i915.conf <<EOF
# Intel GPU driver configuration
options i915 enable_guc=2
options i915 enable_fbc=1
EOF
	fi
	
	maybe_exec 'after_configure_gpu_drivers'
}

function main_chroot() {
	# Skip if already mounted
	mountpoint -q -- "$1" \
		|| die "'$1' is not a mountpoint"

	gentoo_chroot "$@"
}

function install_performance_optimization() {
	[[ "$ENABLE_PERFORMANCE_OPTIMIZATION" != "true" ]] && return 0
	
	maybe_exec 'before_install_performance_optimization'
	
	einfo "Installing performance optimization tools"
	
	# Install CPU optimization tools
	try emerge --verbose app-portage/cpuid2cpuflags
	try emerge --verbose app-misc/resolve-march-native
	
	# Install system monitoring tools
	try emerge --verbose sys-process/btop
	
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
	[[ "$ENABLE_DISPLAY_BACKEND_TESTING" != "true" ]] && return 0
	[[ -z "$GPU_DRIVER" ]] && return 0
	
	maybe_exec 'before_install_display_backend_testing'
	
	einfo "Installing display backend testing tools"
	
	# Install display backend testing dependencies
	try emerge --verbose x11-apps/xdpyinfo
	try emerge --verbose x11-apps/xrandr
	try emerge --verbose media-libs/mesa-demos
	
	# Install performance testing tools
	try emerge --verbose media-libs/mesa-utils
	try emerge --verbose x11-apps/glxgears
	
	# Install Wayland testing tools if using Wayland DE
	if [[ "$(is_wayland_de "$DESKTOP_ENVIRONMENT")" == "true" ]]; then
		try emerge --verbose gui-apps/wl-clipboard
		try emerge --verbose x11-misc/wtype
	fi
	
	maybe_exec 'after_install_display_backend_testing'
}

function install_gpu_benchmarking() {
	[[ "$ENABLE_GPU_BENCHMARKING" != "true" ]] && return 0
	[[ -z "$GPU_DRIVER" ]] && return 0
	
	maybe_exec 'before_install_gpu_benchmarking'
	
	einfo "Installing GPU benchmarking tools"
	
	# Install GPU benchmarking tools
	try emerge --verbose app-benchmarks/glmark2
	try emerge --verbose app-benchmarks/glxgears
	try emerge --verbose app-benchmarks/glxspheres
	
	# Install OpenGL utilities
	try emerge --verbose media-libs/mesa-progs
	try emerge --verbose x11-apps/glxinfo
	
	maybe_exec 'after_install_gpu_benchmarking'
}





function apply_configured_package_management() {
	einfo "Applying configured package management settings"
	
	# Create package.use directory structure
	mkdir_or_die 0755 "/etc/portage/package.use"
	
	# Apply package USE rules
	if [[ ${#PACKAGE_USE_RULES[@]} -gt 0 ]]; then
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
	if [[ ${#PACKAGE_KEYWORDS[@]} -gt 0 ]]; then
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
	

	
	# Apply overlays
	if [[ ${#OVERLAY_URLS[@]} -gt 0 ]]; then
		einfo "Setting up ${#OVERLAY_URLS[@]} portage overlays"
		
		# Install layman if not already installed
		if ! command -v layman >/dev/null 2>&1; then
			einfo "Installing layman for overlay management"
			try emerge --verbose app-portage/layman
		fi
		
		# Add overlays
		for i in "${!OVERLAY_URLS[@]}"; do
			local overlay_url="${OVERLAY_URLS[$i]}"
			local overlay_name="${OVERLAY_NAMES[$i]}"
			
			if [[ -n "$overlay_url" && -n "$overlay_name" ]]; then
				einfo "Adding overlay: $overlay_name ($overlay_url)"
				try layman -a "$overlay_name" -f -o "$overlay_url"
			fi
		done
		
		# Sync overlays
		einfo "Syncing overlays"
		try layman -s ALL
	fi
	
	einfo "Package management configuration applied successfully"
}

function get_disk_device_from_partition() {
	local partition_id="$1"
	local partition_device
	
	# Get the partition device from the partition ID
	partition_device="$(resolve_device_by_id "$partition_id")"
	
	# NEW: Resolve the real path to handle symbolic links correctly
	partition_device="$(realpath "$partition_device")"
	
	# Extract the disk device from the partition device
	# Handle various device naming patterns:
	# /dev/sda1 -> /dev/sda (SATA/SCSI)
	# /dev/sdb2 -> /dev/sdb
	# /dev/hda1 -> /dev/hda (IDE)
	# /dev/nvme0n1p1 -> /dev/nvme0n1 (NVMe)
	# /dev/nvme0n2p2 -> /dev/nvme0n2
	# /dev/vda1 -> /dev/vda (Virtual)
	# /dev/xvda1 -> /dev/xvda (Xen)
	local disk_device
	
	# Try to match common partition naming patterns
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
