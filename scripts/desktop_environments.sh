# Desktop Environment package definitions for Gentoo installer
# This file contains all the package definitions and configuration for various desktop environments

# Desktop Environment packages
declare -A DE_PACKAGES=(
    [kde]="kde-plasma/plasma-meta"
    [gnome]="gnome-base/gnome"
    [hyprland]="gui-wm/hyprland"
    [xfce]="xfce-base/xfce4-meta"
    [cinnamon]="gnome-extra/cinnamon"
    [mate]="mate-base/mate"
    [budgie]="gnome-extra/budgie-desktop"
    [i3]="gui-wm/i3"
    [sway]="gui-wm/sway"
    [openbox]="gui-wm/openbox"
    [fluxbox]="gui-wm/fluxbox"
)

# Display manager packages
declare -A DM_PACKAGES=(
    [sddm]="x11-misc/sddm"
    [gdm]="gnome-base/gdm"
    [lightdm]="x11-misc/lightdm"
    [lxdm]="x11-misc/lxdm"
    [slim]="x11-misc/slim"
)

# Network manager packages
declare -A NM_PACKAGES=(
    [networkmanager]="net-misc/networkmanager"
    [connman]="net-misc/connman"
)

# Default display manager for each DE
declare -A DE_DEFAULT_DM=(
    [kde]="sddm"
    [gnome]="gdm"
    [hyprland]="none"
    [xfce]="lightdm"
    [cinnamon]="lightdm"
    [mate]="lightdm"
    [budgie]="lightdm"
    [i3]="lightdm"
    [sway]="none"
    [openbox]="lightdm"
    [fluxbox]="lightdm"
)

# Default network manager for each DE
declare -A DE_DEFAULT_NM=(
    [kde]="networkmanager"
    [gnome]="networkmanager"
    [hyprland]="networkmanager"
    [xfce]="networkmanager"
    [cinnamon]="networkmanager"
    [mate]="networkmanager"
    [budgie]="networkmanager"
    [i3]="networkmanager"
    [sway]="networkmanager"
    [openbox]="networkmanager"
    [fluxbox]="networkmanager"
)

# Essential packages that are critical for each DE to function properly
# These packages are ALWAYS installed and cannot be overridden by user configuration
# 
# CRITICAL: These packages include:
# - Input drivers (xf86-input-libinput) for keyboard, mouse, and touchpad functionality
# - Desktop-specific tools (kwallet-pam, gnome-shell, waybar)
# - Wayland ecosystem packages (pipewire, wireplumber, xdg-desktop-portal) for Hyprland
# - Session management tools for proper desktop environment startup
# 
# Without these packages, desktop environments may fail to start or have limited functionality.
declare -A DE_ESSENTIAL_PACKAGES=(
    [kde]="kde-plasma/kwallet-pam x11-drivers/xf86-input-libinput"
    [gnome]="gnome-base/gnome-shell x11-drivers/xf86-input-libinput"
    [hyprland]="gui-apps/waybar media-video/pipewire media-sound/wireplumber xdg-desktop-portal xdg-desktop-portal-wlr x11-drivers/xf86-input-libinput"
    [xfce]="xfce-base/xfce4-session x11-drivers/xf86-input-libinput"
    [cinnamon]="gnome-base/gnome-session x11-drivers/xf86-input-libinput"
    [mate]="mate-base/mate-session-manager x11-drivers/xf86-input-libinput"
    [budgie]="gnome-base/gnome-session x11-drivers/xf86-input-libinput"
    [i3]="gui-wm/i3 x11-drivers/xf86-input-libinput"
    [sway]="gui-wm/sway x11-drivers/xf86-input-libinput"
    [openbox]="gui-wm/openbox x11-drivers/xf86-input-libinput"
    [fluxbox]="gui-wm/fluxbox x11-drivers/xf86-input-libinput"
)

# Additional packages that are commonly needed for DEs
# These can be overridden by user configuration
declare -A DE_ADDITIONAL_PACKAGES=(
    [kde]="kde-apps/konsole kde-apps/dolphin kde-apps/kate"
    [gnome]="gnome-extra/gnome-tweaks gnome-extra/gnome-software"
    [hyprland]="gui-apps/wofi gui-apps/kitty xfce-extra/xfce4-terminal"
    [xfce]="xfce-extra/xfce4-goodies"
    [cinnamon]="gnome-extra/gnome-tweaks"
    [mate]="mate-extra/mate-tweak"
    [budgie]="gnome-extra/gnome-tweaks"
    [i3]="gui-apps/dmenu gui-apps/i3status"
    [sway]="gui-apps/wofi"
    [openbox]="gui-apps/tint2 gui-apps/obconf"
    [fluxbox]="gui-apps/fbsetbg"
)

# Function to get default display manager for a DE
function get_default_dm_for_de() {
    local de="$1"
    [[ -n "${DE_DEFAULT_DM[$de]}" ]] && echo "${DE_DEFAULT_DM[$de]}" || echo "lightdm"
}

# Function to get default network manager for a DE
function get_default_nm_for_de() {
    local de="$1"
    [[ -n "${DE_DEFAULT_NM[$de]}" ]] && echo "${DE_DEFAULT_NM[$de]}" || echo "networkmanager"
}

# Function to check if DE requires X11 or Wayland
function is_wayland_de() {
    local de="$1"
    case "$de" in
        hyprland|sway) echo "true" ;;
        *) echo "false" ;;
    esac
}

# Function to get essential packages for a DE
function get_essential_packages_for_de() {
    local de="$1"
    [[ -n "${DE_ESSENTIAL_PACKAGES[$de]}" ]] && echo "${DE_ESSENTIAL_PACKAGES[$de]}" || echo ""
}

# Function to check if DE requires systemd
function de_requires_systemd() {
	local de="$1"
	case "$de" in
		gnome|budgie) echo "true" ;;
		*) echo "false" ;;
	esac
}

# GPU Driver functionality removed - too complex for automated installation
# Users can manually install and configure GPU drivers after installation if needed
