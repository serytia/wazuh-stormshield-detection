#!/bin/bash
# Desinstalle le pack de detection Stormshield SNS.
# Usage : sudo ./uninstall.sh
set -e

OSSEC="/var/ossec"
[ "$(id -u)" -eq 0 ] || { echo "Lancez ce script en root (sudo)."; exit 1; }

rm -f "$OSSEC/etc/decoders/stormshield_decoders.xml" \
      "$OSSEC/etc/rules/stormshield_rules.xml"
echo "[*] Fichiers retires. Redemarrage de Wazuh..."
"$OSSEC/bin/wazuh-control" restart
echo "[OK] Pack Stormshield SNS desinstalle."
