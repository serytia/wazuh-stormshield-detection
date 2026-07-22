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

# Back up any currently-installed pack so a failed validation rolls back to the
# working version instead of leaving the manager with no pack at all.
BACKUP="$(mktemp -d)"
trap 'rm -rf "$BACKUP"' EXIT
for f in "$DEC_DST" "$RUL_DST"; do
  [ -f "$f" ] && cp -p "$f" "$BACKUP/" || true
done

echo "[*] Copying decoders and rules..."
install -o wazuh -g wazuh -m 660 decoders/stormshield_decoders.xml "$DEC_DST"
install -o wazuh -g wazuh -m 660 rules/stormshield_rules.xml       "$RUL_DST"

echo "[*] Checking configuration (wazuh-analysisd -t)..."
if "$OSSEC/bin/wazuh-analysisd" -t; then
  echo "[*] Configuration valid. Restarting Wazuh..."
  "$OSSEC/bin/wazuh-control" restart
  echo "[OK] Stormshield SNS pack installed."
else
  echo "[!] Configuration error -- rolling back to the previous state."
  for name in stormshield_decoders.xml stormshield_rules.xml; do
    case "$name" in
      *decoders*) dst="$DEC_DST" ;;
      *)          dst="$RUL_DST" ;;
    esac
    if [ -f "$BACKUP/$name" ]; then
      cp -p "$BACKUP/$name" "$dst"   # restore the previously-installed version
    else
      rm -f "$dst"                   # nothing was installed before -- remove the bad file
    fi
  done
  echo "[!] Previous state restored. Fix the pack and re-run."
  exit 1
fi
