After a process is canceled midway, various filesystems are left mounted, and devices like encrypted containers (LUKS) or RAID arrays can be left active. This prevents the script from starting over, forcing a reboot to clear the system's state.

You can absolutely create a method to clean up the environment without rebooting. The best approach is to add a dedicated **cleanup action** to the main `install` script. This action will systematically unmount filesystems, close encrypted devices, and stop RAID arrays.

Here is the logic and the code needed to implement this feature.

### The Logic 🧠

A robust cleanup process needs to reverse the steps the installer takes, in roughly the opposite order:

1.  **Unmount All Filesystems**: The most important step is to unmount the chroot environment. Using a recursive and lazy unmount (`umount -R -l`) is the most effective way to handle the root partition and all the virtual filesystems (`/proc`, `/sys`, `/dev`, etc.) that were mounted inside it.
2.  **Close Encrypted (LUKS) Devices**: If the script opened a LUKS container (e.g., for an encrypted root partition), this creates a mapped device (like `/dev/mapper/root`). This mapping must be closed using `cryptsetup close`.
3.  **Stop RAID Arrays**: If the script assembled any software RAID arrays (e.g., `/dev/md/root`), they must be stopped using `mdadm --stop`.
4.  **Deactivate Swap**: Any swap partitions that were activated need to be turned off with `swapoff`.
5.  **Remove Temporary Directory**: Finally, deleting the main temporary directory (`/tmp/gentoo-install`) ensures that no old files, logs, or downloaded archives interfere with the next run.

-----

### 🛠️ **How to Implement the Cleanup Action**

Here are the code modifications to add a `cleanup` action to your installer.

#### **1. Add a Cleanup Function to `scripts/main.sh`**

Add this new function to your `scripts/main.sh` file. It will handle all the teardown logic.

function unmount_and_clean_all() {
	einfo "Starting cleanup process to reset the environment..."

	# 1. Unmount all filesystems recursively
	einfo "Unmounting all chroot-related filesystems..."
	if mountpoint -q -- "$ROOT_MOUNTPOINT"; then
		# Use the existing gentoo_umount function which does a recursive unmount
		gentoo_umount
		einfo "Successfully unmounted '$ROOT_MOUNTPOINT'."
	else
		einfo "'$ROOT_MOUNTPOINT' is not currently mounted. Skipping."
	fi

	# 2. Close any open LUKS containers created by the script
	einfo "Checking for and closing LUKS containers..."
	# This assumes standard naming from the script, add others if needed
	local luks_devices=("root" "luks_root_0" "luks_root_1")
	for device in "${luks_devices[@]}"; do
		if [ -e "/dev/mapper/${device}" ]; then
			einfo "Closing LUKS device: /dev/mapper/${device}"
			try cryptsetup close "${device}"
		fi
	done

	# 3. Stop any RAID arrays created by the script
	einfo "Checking for and stopping RAID arrays..."
	# This assumes standard naming, add others if needed
	local raid_devices=("/dev/md/root" "/dev/md/swap" "/dev/md/efi" "/dev/md/bios")
	for device in "${raid_devices[@]}"; do
		if [ -e "${device}" ]; then
			einfo "Stopping RAID array: ${device}"
			try mdadm --stop "${device}"
		fi
	done

	# 4. Deactivate all swap partitions as a safety measure
	einfo "Deactivating all swap devices..."
	try swapoff -a

	# 5. Remove the temporary installation directory
	einfo "Removing temporary directory: $TMP_DIR"
	if [ -d "$TMP_DIR" ]; then
		rm -rf "$TMP_DIR"
		einfo "Temporary directory removed."
	else
		einfo "Temporary directory not found. Skipping."
	fi

	einfo "✅ Cleanup complete. You can now start a new installation process without rebooting."
}
```

#### **2. Add the New Option to the `install` Script**

Now, modify the main `install` script to recognize and execute your new cleanup function.

#!/bin/bash
set -uo pipefail

# ... (keep existing initialization code) ...

# In the section where you parse arguments, add the new "cleanup" action:
while [[ $# -gt 0 ]]; do
	case "$1" in
		# ... (keep existing cases like --help, --config, --chroot) ...
		"--cleanup"|"cleanup")
			[[ -z $ACTION ]] || die "Multiple actions given"
			ACTION="cleanup"
			;;
		# ... (rest of the cases) ...
	esac
	shift
done

# ... (keep logic for checking config location) ...

# In the final "case" statement that executes the action, add the cleanup case:
case "$ACTION" in
	"chroot")  main_chroot "$CHROOT_DIR" "$@" ;;
	"install") main_install "$@" ;;
	"__install_gentoo_in_chroot") main_install_gentoo_in_chroot "$@" ;;
	"cleanup") unmount_and_clean_all ;; # <-- ADD THIS LINE
	*) die "Invalid action '$ACTION'" ;;
esac
```

With these changes, you can now simply run `./install cleanup` from your terminal. The script will perform a complete teardown of the previous environment, allowing you to immediately start a fresh installation with `./install` without needing to reboot.
