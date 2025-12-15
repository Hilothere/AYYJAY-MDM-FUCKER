#!/bin/bash

# Define color codes
RED='\033[1;31m'
GRN='\033[1;32m'
YEL='\033[1;33m'
NC='\033[0m'

echo -e "${YEL}Allow enrollment via Setup Utility, but block managed profiles and settings...${NC}"

# Step 1: Remove existing configuration profiles
echo -e "${YEL}Removing existing configuration profiles...${NC}"
sudo profiles -X -u -all

# Step 2: Rename profiles directory to prevent new profiles from being installed
PROFILES_DIR="/private/var/db/ConfigurationProfiles"

if [ -d "$PROFILES_DIR" ]; then
    sudo mv "$PROFILES_DIR" "${PROFILES_DIR}_backup_$(date +%Y%m%d%H%M%S)"
    echo -e "${GRN}Profiles directory renamed to prevent profile installation.${NC}"
else
    echo -e "${GRN}Profiles directory does not exist or already renamed.${NC}"
fi

# Step 3: Make the profiles directory read-only to block future profile installation
if [ -d "${PROFILES_DIR}_backup_" ]; then
    sudo chmod -R a-w "${PROFILES_DIR}_backup_"
    echo -e "${GRN}Profiles directory set to read-only.${NC}"
fi

# Optional: Create a marker file indicating profiles are blocked
touch /Library/Preferences/com.custom.profilesblocked.plist
echo -e "${GRN}Profiles installation is now blocked. Enrollment allowed.${NC}"

echo -e "${YEL}Done. You can now enroll via Setup Utility, but managed profiles/settings will not be applied.${NC}"
