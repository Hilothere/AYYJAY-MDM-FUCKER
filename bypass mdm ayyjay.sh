#!/bin/bash

# Define color codes
RED='\033[1;31m'
GRN='\033[1;32m'
YEL='\033[1;33m'
NC='\033[0m'

# Ensure script runs with root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}This script must be run as root. Please run with sudo.${NC}"
  exit 1
fi

# =========================
# Part 1: Create Temporary User
# =========================
echo -e "${YEL}=== Creating a Temporary User ===${NC}"

read -p "Enter Temporary Fullname (Default is 'Apple'): " realName
realName="${realName:=Apple}"

read -p "Enter Temporary Username (Default is 'Apple'): " username
username="${username:=Apple}"

read -p "Enter Temporary Password (Default is '1234'): " passw
passw="${passw:=1234}"

dscl_path='/Volumes/Data/private/var/db/dslocal/nodes/Default'

# Check if dscl path exists
if [ ! -d "$dscl_path" ]; then
  echo -e "${RED}dscl path $dscl_path does not exist. Aborting user creation.${NC}"
  exit 1
fi

echo -e "${GREEN}Creating user '$username'...${NC}"

# Generate a unique UID (should be unique, here fixed at 501 for simplicity)
UID="501"

# Create user account
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" || { echo -e "${RED}Failed to create user.${NC}"; exit 1; }
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "$UID"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
mkdir -p "/Volumes/Data/Users/$username"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"

# Add user to admin group
dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"

echo -e "${GREEN}User '$username' created successfully.${NC}"

# =========================
# Part 2: Block Profile Installation
# =========================
echo -e "${YEL}=== Blocking Profile Installation ===${NC}"

# Step 1: Remove existing configuration profiles
echo -e "${YEL}Removing existing configuration profiles...${NC}"
sudo profiles -X -u -all
if [ $? -eq 0 ]; then
  echo -e "${GRN}Configuration profiles removed.${NC}"
else
  echo -e "${RED}Failed to remove some configuration profiles.${NC}"
fi

# Step 2: Rename profiles directory to prevent new profiles from being installed
PROFILES_DIR="/private/var/db/ConfigurationProfiles"
if [ -d "$PROFILES_DIR" ]; then
  BACKUP_DIR="${PROFILES_DIR}_backup_$(date +%Y%m%d%H%M%S)"
  if mv "$PROFILES_DIR" "$BACKUP_DIR"; then
    echo -e "${GRN}Profiles directory renamed to $BACKUP_DIR.${NC}"
  else
    echo -e "${RED}Failed to rename profiles directory.${NC}"
  fi
else
  echo -e "${GRN}Profiles directory does not exist or already renamed.${NC}"
fi

# Step 3: Make the profiles directory read-only
if [ -d "$BACKUP_DIR" ]; then
  if chmod -R a-w "$BACKUP_DIR"; then
    echo -e "${GRN}Profiles directory set to read-only.${NC}"
  else
    echo -e "${RED}Failed to set profiles directory to read-only.${NC}"
  fi
fi

# Optional: Create marker file indicating profiles are blocked
touch /Library/Preferences/com.custom.profilesblocked.plist
echo -e "${GRN}Profiles installation is now blocked. Enrollment allowed.${NC}"

echo -e "${YEL}Done. You can now enroll via Setup Utility, but managed profiles/settings will not be applied.${NC}"
