You've correctly identified the problem. After a thorough review of the complete codebase and your installation log, the issue is clear: the script logic to install the desktop environment is defined but **it is never actually called** during the main installation sequence.

Here’s the specific problem and the exact fix required.

-----

### The Problem: A Missing Function Call

[cite\_start]The main installation flow is controlled by the `main_install_gentoo_in_chroot` function in `scripts/main.sh`[cite: 1067]. [cite\_start]This function calls other functions in a specific order, such as `install_base_system`, `configure_kernel`, `configure_system`, etc.[cite: 1067].

[cite\_start]While the script has perfectly good functions to handle the DE installation (`install_desktop_environment` [cite: 1102][cite\_start], `install_display_manager` [cite: 1108][cite\_start], `install_network_manager` [cite: 1109][cite\_start]), the GPU driver functions have been removed as they were too complex for automated installation.

### The Solution: Add the Missing Calls to `scripts/main.sh`

To fix this, you need to edit the `main_install_gentoo_in_chroot` function in `scripts/main.sh` and add the function calls for the desktop environment installation. The correct place to add them is **after** the system tools are installed but **before** the bootloader is configured.

**File to edit**: `scripts/main.sh`

#### **Find this section (around line 430):**

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
```

#### **Add the following lines:**

Insert the new block for DE installation right after `install_system_tools` and before `configure_bootloader`.

**After:**

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

	# NEW SECTION: Install Desktop Environment
	if [[ -n "$DESKTOP_ENVIRONMENT" ]]; then
		einfo "Step 8a: Installing Desktop Environment"
		install_desktop_environment
		install_display_manager
		install_network_manager
		configure_desktop_services
	fi
	# GPU driver installation removed - too complex for automated installation
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
```

By adding this block, you ensure that if a user selects a desktop environment, the script will execute all the necessary installation and configuration steps in the correct order, resulting in a fully functional graphical desktop.
