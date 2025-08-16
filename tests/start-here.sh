#!/bin/bash

# Start Here - Your Entry Point to Advanced VM Management
# This script shows you exactly where to begin

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${GREEN}🚀 Welcome to Advanced VM Management Tools!${NC}"
echo "=================================================="
echo

echo -e "${CYAN}📋 What We've Built for You:${NC}"
echo "  ✅ Clean, focused workspace (removed 15+ old scripts)"
echo "  ✅ 4 essential tools for every need"
echo "  ✅ Progressive complexity from simple to advanced"
echo "  ✅ Professional quality for serious VM management"
echo

echo -e "${YELLOW}🎯 START HERE - Your Main Tool:${NC}"
echo "  🐧 gentoo-vm-launcher.sh - Smart VM launcher with auto-detection"
echo "  💡 This is your main tool for everyday use"
echo "  🚀 Auto-detects your environment (NVIDIA, Wayland, root)"
echo "  🔧 Smart defaults optimized for your setup"
echo

echo -e "${BLUE}📚 Your Tool Progression:${NC}"
echo "  1️⃣  gentoo-vm-launcher.sh     ← START HERE (simple)"
echo "  2️⃣  enhanced-vm-launcher.sh   ← More options (intermediate)"
echo "  3️⃣  advanced-vm-configurator.sh ← Full control (expert)"
echo "  4️⃣  test-display-backends.sh  ← Performance optimization"
echo

echo -e "${GREEN}🚀 Ready to Start?${NC}"
echo "  Just run: ./gentoo-vm-launcher.sh"
echo "  That's it! Everything else is optional."
echo

echo -e "${CYAN}📖 Need Help?${NC}"
echo "  📚 README.md - Project overview"
echo "  🎯 GETTING-STARTED.md - Detailed guide"
echo "  🌐 QEMU-README.md - QEMU configuration"
echo "  🎮 DISPLAY-BACKEND-GUIDE.md - Performance tips"
echo

echo -e "${YELLOW}💡 Pro Tips:${NC}"
echo "  • Start simple, add complexity as needed"
echo "  • Each tool builds on the previous one"
echo "  • All tools work together seamlessly"
echo "  • You can always go back to simpler tools"
echo

read -p "Press Enter to start your VM management journey... "

echo
echo -e "${GREEN}🚀 Launching your main tool...${NC}"
echo "  If you see any errors, make sure the script is executable:"
echo "  chmod +x gentoo-vm-launcher.sh"
echo

# Check if the main launcher is executable
if [[ -x "gentoo-vm-launcher.sh" ]]; then
    echo -e "${GREEN}✓ Main launcher is ready!${NC}"
    echo "  Starting in 3 seconds..."
    sleep 3
    ./gentoo-vm-launcher.sh
else
    echo -e "${RED}❌ Main launcher needs execute permissions${NC}"
    echo "  Run: chmod +x gentoo-vm-launcher.sh"
    echo "  Then try again!"
fi

