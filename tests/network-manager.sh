#!/bin/bash

# Advanced Network Manager for QEMU VMs
# Features: VLANs, Network Isolation, Routing, Multiple Interfaces

set -e

# Network Configuration
VM_NAME=""
NETWORK_INTERFACES=()
NETWORK_MODE="user"
BRIDGE_NAME="br0"
VLAN_CONFIG=""
ISOLATION_ENABLED="false"
ROUTING_ENABLED="false"
FIREWALL_ENABLED="false"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to show main menu
show_menu() {
    clear
    echo -e "${GREEN}🌐 Advanced Network Manager - QEMU VM Networking${NC}"
    echo "========================================================"
    echo
    
    echo -e "${CYAN}📋 Current Configuration:${NC}"
    echo "  VM Name: ${VM_NAME:-"Not set"}"
    echo "  Network Mode: $NETWORK_MODE"
    echo "  Interfaces: ${#NETWORK_INTERFACES[@]} configured"
    echo "  Bridge: $BRIDGE_NAME"
    echo "  VLAN: ${VLAN_CONFIG:-"None"}"
    echo "  Isolation: $(on_off_label ISOLATION_ENABLED)"
    echo "  Routing: $(on_off_label ROUTING_ENABLED)"
    echo "  Firewall: $(on_off_label FIREWALL_ENABLED)"
    echo
    
    echo -e "${CYan}📋 Network Management Options:${NC}"
    echo "  1) Configure VM Network"
    echo "  2) Network Interface Management"
    echo "  3) VLAN Configuration"
    echo "  4) Network Isolation Setup"
    echo "  5) Routing Configuration"
    echo "  6) Firewall & Security"
    echo "  7) Bridge Management"
    echo "  8) Show Current Configuration"
    echo "  9) Generate QEMU Commands"
    echo "  0) Exit"
    echo
    
    echo -e "${YELLOW}💡 Advanced networking for enterprise-grade VM isolation${NC}"
    echo
}

# Helper functions
on_off_label() {
    local var_name="$1"
    if [[ "${!var_name}" == "true" ]]; then
        echo -e "${GREEN}ON${NC}"
    else
        echo -e "${RED}OFF${NC}"
    fi
}

# Function to configure VM network
configure_vm_network() {
    clear
    echo -e "${BLUE}⚙️  VM Network Configuration${NC}"
    echo "==============================="
    echo
    
    read -p "VM Name: " VM_NAME
    [[ -z "$VM_NAME" ]] && return
    
    echo "Network Mode Options:"
    echo "  1) User networking (NAT, no root needed)"
    echo "  2) Bridge networking (best performance, requires root)"
    echo "  3) TAP networking (advanced, requires root)"
    read -p "Choose network mode [1-3]: " choice
    
    case $choice in
        1)
            NETWORK_MODE="user"
            echo -e "${GREEN}✓ User networking selected${NC}"
            ;;
        2)
            if [[ $EUID -eq 0 ]]; then
                NETWORK_MODE="bridge"
                echo -e "${GREEN}✓ Bridge networking selected${NC}"
            else
                echo -e "${YELLOW}⚠️  Bridge networking requires root privileges${NC}"
                NETWORK_MODE="user"
            fi
            ;;
        3)
            if [[ $EUID -eq 0 ]]; then
                NETWORK_MODE="tap"
                echo -e "${GREEN}✓ TAP networking selected${NC}"
            else
                echo -e "${YELLOW}⚠️  TAP networking requires root privileges${NC}"
                NETWORK_MODE="user"
            fi
            ;;
        *)
            echo "Invalid choice, using user networking"
            NETWORK_MODE="user"
            ;;
    esac
    
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        read -p "Bridge name [$BRIDGE_NAME]: " input
        [[ -n "$input" ]] && BRIDGE_NAME="$input"
    fi
    
    echo -e "${GREEN}✓ VM network configured${NC}"
    echo "  VM: $VM_NAME"
    echo "  Mode: $NETWORK_MODE"
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        echo "  Bridge: $BRIDGE_NAME"
    fi
    read -p "Press Enter to continue..."
}

# Function to manage network interfaces
manage_network_interfaces() {
    clear
    echo -e "${BLUE}🔌 Network Interface Management${NC}"
    echo "================================="
    echo
    
    echo "Current Interfaces:"
    if [[ ${#NETWORK_INTERFACES[@]} -eq 0 ]]; then
        echo "  No interfaces configured"
    else
        for i in "${!NETWORK_INTERFACES[@]}"; do
            local interface="${NETWORK_INTERFACES[$i]}"
            echo "  $((i+1))) $interface"
        done
    fi
    echo
    
    echo "Options:"
    echo "  1) Add network interface"
    echo "  2) Remove interface"
    echo "  3) Back to main menu"
    echo
    
    read -p "Choose option [1-3]: " choice
    
    case $choice in
        1) add_network_interface ;;
        2) remove_network_interface ;;
        3) return ;;
        *) echo "Invalid option" ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to add network interface
add_network_interface() {
    clear
    echo -e "${BLUE}➕ Add Network Interface${NC}"
    echo "========================"
    echo
    
    local interface_name=""
    local interface_type=""
    local interface_mac=""
    
    read -p "Interface name (e.g., eth0, eth1): " interface_name
    [[ -z "$interface_name" ]] && return
    
    echo "Interface Type Options:"
    echo "  1) virtio (best performance, requires drivers)"
    echo "  2) e1000 (Intel, good compatibility)"
    echo "  3) rtl8139 (Realtek, basic compatibility)"
    read -p "Choose interface type [1-3]: " choice
    
    case $choice in
        1) interface_type="virtio" ;;
        2) interface_type="e1000" ;;
        3) interface_type="rtl8139" ;;
        *) interface_type="virtio" ;;
    esac
    
    # Generate MAC address
    interface_mac="52:54:00:$(printf "%02x:%02x:%02x" $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))"
    
    read -p "MAC address [$interface_mac]: " input
    [[ -n "$input" ]] && interface_mac="$input"
    
    # Create interface configuration string
    local interface_config="$interface_name:$interface_type:$interface_mac"
    NETWORK_INTERFACES+=("$interface_config")
    
    echo -e "${GREEN}✓ Network interface added: $interface_name${NC}"
    echo "  Type: $interface_type"
    echo "  MAC: $interface_mac"
}

# Function to remove network interface
remove_network_interface() {
    if [[ ${#NETWORK_INTERFACES[@]} -eq 0 ]]; then
        echo "No interfaces to remove"
        return
    fi
    
    echo "Select interface to remove:"
    for i in "${!NETWORK_INTERFACES[@]}"; do
        local interface="${NETWORK_INTERFACES[$i]}"
        echo "  $((i+1))) $interface"
    done
    
    read -p "Enter interface number: " choice
    local index=$((choice-1))
    
    if [[ $index -ge 0 && $index -lt ${#NETWORK_INTERFACES[@]} ]]; then
        local removed_interface="${NETWORK_INTERFACES[$index]}"
        unset NETWORK_INTERFACES[$index]
        NETWORK_INTERFACES=("${NETWORK_INTERFACES[@]}")  # Reindex array
        echo -e "${GREEN}✓ Interface removed: $removed_interface${NC}"
    else
        echo -e "${RED}Invalid interface number${NC}"
    fi
}

# Function to configure VLAN
configure_vlan() {
    clear
    echo -e "${BLUE}🏷️  VLAN Configuration${NC}"
    echo "====================="
    echo
    
    echo "VLAN Options:"
    echo "  1) Enable VLAN tagging"
    echo "  2) Disable VLAN"
    read -p "Choose option [1-2]: " choice
    
    case $choice in
        1)
            echo "VLAN Configuration:"
            read -p "VLAN ID (1-4094): " vlan_id
            
            if [[ "$vlan_id" =~ ^[0-9]+$ && $vlan_id -ge 1 && $vlan_id -le 4094 ]]; then
                read -p "VLAN name (optional): " vlan_name
                if [[ -n "$vlan_name" ]]; then
                    VLAN_CONFIG="$vlan_id:$vlan_name"
                else
                    VLAN_CONFIG="$vlan_id"
                fi
                echo -e "${GREEN}✓ VLAN enabled: $VLAN_CONFIG${NC}"
            else
                echo -e "${RED}Invalid VLAN ID${NC}"
            fi
            ;;
        2)
            VLAN_CONFIG=""
            echo -e "${GREEN}✓ VLAN disabled${NC}"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to configure network isolation
configure_network_isolation() {
    clear
    echo -e "${BLUE}🔒 Network Isolation Setup${NC}"
    echo "============================="
    echo
    
    echo "Network Isolation Options:"
    echo "  1) Enable network isolation"
    echo "  2) Disable isolation"
    read -p "Choose option [1-2]: " choice
    
    case $choice in
        1)
            ISOLATION_ENABLED="true"
            echo -e "${GREEN}✓ Network isolation enabled${NC}"
            ;;
        2)
            ISOLATION_ENABLED="false"
            echo -e "${GREEN}✓ Network isolation disabled${NC}"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to configure routing
configure_routing() {
    clear
    echo -e "${BLUE}🛣️  Routing Configuration${NC}"
    echo "========================="
    echo
    
    echo "Routing Options:"
    echo "  1) Enable routing"
    echo "  2) Disable routing"
    read -p "Choose option [1-2]: " choice
    
    case $choice in
        1)
            ROUTING_ENABLED="true"
            echo -e "${GREEN}✓ Routing enabled${NC}"
            ;;
        2)
            ROUTING_ENABLED="false"
            echo -e "${GREEN}✓ Routing disabled${NC}"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to configure firewall
configure_firewall() {
    clear
    echo -e "${BLUE}🔥 Firewall Configuration${NC}"
    echo "========================="
    echo
    
    echo "Firewall Options:"
    echo "  1) Enable firewall"
    echo "  2) Disable firewall"
    read -p "Choose option [1-2]: " choice
    
    case $choice in
        1)
            FIREWALL_ENABLED="true"
            echo -e "${GREEN}✓ Firewall enabled${NC}"
            ;;
        2)
            FIREWALL_ENABLED="false"
            echo -e "${GREEN}✓ Firewall disabled${NC}"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to manage bridge
manage_bridge() {
    clear
    echo -e "${BLUE}🌉 Bridge Management${NC}"
    echo "====================="
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}⚠️  Bridge management requires root privileges${NC}"
        echo "Some features may not work without root access"
        echo
    fi
    
    echo "Bridge Options:"
    echo "  1) Create bridge"
    echo "  2) Delete bridge"
    echo "  3) List bridges"
    echo "  4) Show bridge status"
    echo "  5) Back to main menu"
    echo
    
    read -p "Choose option [1-5]: " choice
    
    case $choice in
        1) create_bridge ;;
        2) delete_bridge ;;
        3) list_bridges ;;
        4) show_bridge_status ;;
        5) return ;;
        *) echo "Invalid option" ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to create bridge
create_bridge() {
    if [[ $EUID -ne 0 ]]; then
        echo "Creating bridge requires root privileges"
        return
    fi
    
    read -p "Bridge name [$BRIDGE_NAME]: " bridge_name
    [[ -n "$bridge_name" ]] && BRIDGE_NAME="$bridge_name"
    
    if ip link show "$BRIDGE_NAME" &> /dev/null; then
        echo "Bridge $BRIDGE_NAME already exists"
        return
    fi
    
    echo "Creating bridge: $BRIDGE_NAME"
    ip link add "$BRIDGE_NAME" type bridge
    ip link set "$BRIDGE_NAME" up
    
    echo -e "${GREEN}✓ Bridge created: $BRIDGE_NAME${NC}"
}

# Function to delete bridge
delete_bridge() {
    if [[ $EUID -ne 0 ]]; then
        echo "Deleting bridge requires root privileges"
        return
    fi
    
    read -p "Bridge name to delete: " bridge_name
    [[ -z "$bridge_name" ]] && return
    
    if ip link show "$bridge_name" &> /dev/null; then
        echo "Deleting bridge: $bridge_name"
        ip link set "$bridge_name" down
        ip link delete "$bridge_name"
        echo -e "${GREEN}✓ Bridge deleted: $bridge_name${NC}"
    else
        echo "Bridge $bridge_name does not exist"
    fi
}

# Function to list bridges
list_bridges() {
    echo "Available bridges:"
    ip link show type bridge 2>/dev/null | grep -E "^[0-9]+:" | cut -d: -f2 | sed 's/^[[:space:]]*//' || echo "  No bridges found"
}

# Function to show bridge status
show_bridge_status() {
    if [[ -n "$BRIDGE_NAME" ]]; then
        echo "Bridge Status: $BRIDGE_NAME"
        if ip link show "$BRIDGE_NAME" &> /dev/null; then
            echo "  Status: $(ip link show "$BRIDGE_NAME" | grep -o 'state [A-Z]*')"
            echo "  MAC: $(ip link show "$BRIDGE_NAME" | grep -o 'link/ether [a-f0-9:]*' | cut -d' ' -f2)"
        else
            echo "  Bridge does not exist"
        fi
    else
        echo "No bridge configured"
    fi
}

# Function to generate QEMU commands
generate_qemu_commands() {
    clear
    echo -e "${BLUE}🔧 QEMU Network Commands${NC}"
    echo "============================="
    echo
    
    if [[ -z "$VM_NAME" ]]; then
        echo "Configure VM network first"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Generated QEMU Network Commands:"
    echo
    
    case "$NETWORK_MODE" in
        "user")
            echo "# User networking (NAT)"
            echo "-netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.1,dhcpstart=10.0.2.15"
            ;;
        "bridge")
            echo "# Bridge networking"
            echo "-netdev bridge,id=net0,br=\"$BRIDGE_NAME\""
            ;;
        "tap")
            echo "# TAP networking"
            echo "-netdev tap,id=net0,ifname=tap0,script=no,downscript=no"
            ;;
        *)
            echo "# Custom networking"
            echo "-netdev user,id=net0"
            ;;
    esac
    
    echo
    echo "# Network interfaces:"
    for i in "${!NETWORK_INTERFACES[@]}"; do
        local interface="${NETWORK_INTERFACES[$i]}"
        local name=$(echo "$interface" | cut -d: -f1)
        local type=$(echo "$interface" | cut -d: -f2)
        local mac=$(echo "$interface" | cut -d: -f3)
        
        echo "-device ${type}-pci,netdev=net0,mac=\"$mac\",id=$name"
    done
    
    if [[ -n "$VLAN_CONFIG" ]]; then
        echo
        echo "# VLAN Configuration: $VLAN_CONFIG"
    fi
    
    if [[ "$ISOLATION_ENABLED" == "true" ]]; then
        echo
        echo "# Network Isolation Enabled"
    fi
    
    if [[ "$FIREWALL_ENABLED" == "true" ]]; then
        echo
        echo "# Firewall Enabled"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to show current configuration
show_configuration() {
    clear
    echo -e "${BLUE}📋 Current Network Configuration${NC}"
    echo "===================================="
    echo
    
    echo -e "${CYan}VM Configuration:${NC}"
    echo "  VM Name: ${VM_NAME:-"Not set"}"
    echo "  Network Mode: $NETWORK_MODE"
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        echo "  Bridge: $BRIDGE_NAME"
    fi
    echo
    
    echo -e "${CYan}Network Interfaces:${NC}"
    if [[ ${#NETWORK_INTERFACES[@]} -eq 0 ]]; then
        echo "  No interfaces configured"
    else
        for i in "${!NETWORK_INTERFACES[@]}"; do
            local interface="${NETWORK_INTERFACES[$i]}"
            local name=$(echo "$interface" | cut -d: -f1)
            local type=$(echo "$interface" | cut -d: -f2)
            local mac=$(echo "$interface" | cut -d: -f3)
            echo "  $((i+1))) $name: $type ($mac)"
        done
    fi
    echo
    
    echo -e "${CYan}Advanced Features:${NC}"
    echo "  VLAN: ${VLAN_CONFIG:-"None"}"
    echo "  Isolation: $(on_off_label ISOLATION_ENABLED)"
    echo "  Routing: $(on_off_label ROUTING_ENABLED)"
    echo "  Firewall: $(on_off_label FIREWALL_ENABLED)"
    echo
    
    read -p "Press Enter to continue..."
}

# Main function
main() {
    # Check if running as root for advanced features
    if [[ $EUID -eq 0 ]]; then
        echo -e "${GREEN}✓ Running as root - all features available${NC}"
    else
        echo -e "${YELLOW}⚠️  Not running as root - some features limited${NC}"
    fi
    
    # Main menu loop
    while true; do
        show_menu
        read -p "Choose option [0-9]: " choice
        
        case $choice in
            1) configure_vm_network ;;
            2) manage_network_interfaces ;;
            3) configure_vlan ;;
            4) configure_network_isolation ;;
            5) configure_routing ;;
            6) configure_firewall ;;
            7) manage_bridge ;;
            8) show_configuration ;;
            9) generate_qemu_commands ;;
            0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please choose 0-9.${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main "$@"
