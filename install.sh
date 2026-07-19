#!/bin/bash
# Installs the Stormshield SNS detection pack for Wazuh.
# Usage: sudo ./install.sh
set -e

OSSEC="/var/ossec"
DEC_DST="$OSSEC/etc/decoders/stormshield_decoders.xml"
RUL_DST="$OSSEC/etc/rules/stormshield_rules.xml"

[ "$(id -u)" -eq 0 ] || { echo "Run this script as root (sudo)."; exit 1; }
[ -d "$OSSEC" ] || { echo "Wazuh not found in $OSSEC."; exit 1; }
cd "$(dirname "$0")"

echo "[*] Copying decoders and rules..."
install -o wazuh -g wazuh -m 660 decoders/stormshield_decoders.xml "$DEC_DST"
install -o wazuh -g wazuh -m 660 rules/stormshield_rules.xml       "$RUL_DST"

echo "[*] Checking configuration (wazuh-analysisd -t)..."
if "$OSSEC/bin/wazuh-analysisd" -t; then
  echo "[*] Configuration valid. Restarting Wazuh..."
  "$OSSEC/bin/wazuh-control" restart
  echo "[OK] Stormshield SNS pack installed."
else
  echo "[!] Configuration error -- removing files."
  rm -f "$DEC_DST" "$RUL_DST"
  exit 1
fi
