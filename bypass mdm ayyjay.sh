#!/bin/bash

# Backup existing hosts file
sudo cp /etc/hosts /etc/hosts.backup-$(date +%Y%m%d%H%M%S)

# List of domains to block
DOMAINS=(
"apple.com"
"icloud.com"
"cdn-apple.com"
"appleid.apple.com"
"mz.apple.com"
"mosyle.com"
"mosyle.net"
"mosyle.io"
"mosyle.app"
"mosyle.mdm"
"m.dmtracking.com"
"m.mdmtracking.com"
"iprofile.apple.com"
"deviceprofile.apple.com"
"profile.apple.com"
"config.apple.com"
"mdm.apple.com"
)

# Add blocking entries
for DOMAIN in "${DOMAINS[@]}"; do
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo "0.0.0.0 $DOMAIN" | sudo tee -a /etc/hosts
        echo "Blocked $DOMAIN"
    else
        echo "$DOMAIN is already blocked."
    fi
done

# Flush DNS cache to apply changes
dscacheutil -flushcache; sudo killall -HUP mDNSResponder

echo "All specified domains have been blocked. Please reboot or restart network services if needed."
