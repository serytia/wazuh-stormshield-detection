#!/bin/bash
# Uninstalls the Stormshield SNS detection pack.
# Usage: sudo ./uninstall.sh
set -e

OSSEC="/var/ossec"
[ "$(id -u)" -eq 0 ] || { echo "Run this script as root (sudo)."; exit 1; }

rm -f "$OSSEC/etc/decoders/stormshield_decoders.xml" \
      "$OSSEC/etc/rules/stormshield_rules.xml"
echo "[*] Files removed. Restarting Wazuh..."
"$OSSEC/bin/wazuh-control" restart
echo "[OK] Stormshield SNS pack uninstalled."
