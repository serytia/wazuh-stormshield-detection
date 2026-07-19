#!/bin/bash
# Installe le pack de detection Stormshield SNS pour Wazuh.
# Usage : sudo ./install.sh
set -e

OSSEC="/var/ossec"
DEC_DST="$OSSEC/etc/decoders/stormshield_decoders.xml"
RUL_DST="$OSSEC/etc/rules/stormshield_rules.xml"

[ "$(id -u)" -eq 0 ] || { echo "Lancez ce script en root (sudo)."; exit 1; }
[ -d "$OSSEC" ] || { echo "Wazuh introuvable dans $OSSEC."; exit 1; }
cd "$(dirname "$0")"

echo "[*] Copie des decodeurs et regles..."
install -o wazuh -g wazuh -m 660 decoders/stormshield_decoders.xml "$DEC_DST"
install -o wazuh -g wazuh -m 660 rules/stormshield_rules.xml       "$RUL_DST"

echo "[*] Verification de la configuration (wazuh-analysisd -t)..."
if "$OSSEC/bin/wazuh-analysisd" -t; then
  echo "[*] Configuration valide. Redemarrage de Wazuh..."
  "$OSSEC/bin/wazuh-control" restart
  echo "[OK] Pack Stormshield SNS installe."
else
  echo "[!] Erreur de configuration -- retrait des fichiers."
  rm -f "$DEC_DST" "$RUL_DST"
  exit 1
fi
