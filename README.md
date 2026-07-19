# Wazuh Detection Pack — Stormshield SNS

> Règles et décodeurs Wazuh pour les pare-feux **Stormshield Network Security (SNS)**.
> *Wazuh detection rules & decoders for Stormshield SNS firewalls.*

## Le problème

Wazuh n'a **pas de support natif** pour les logs Stormshield SNS. Envoyés bruts en syslog, ils arrivent au format **WELF** (`champ=valeur`) et ne sont ni décodés ni corrélés : un **scan** (rafale de blocages), un **brute-force** sur le portail d'authentification, une **alarme IPS bloquante** — rien ne remonte en clair, rien ne se corrèle.

Ce pack décode les logs WELF de Stormshield — filtrage (`id=firewall`), authentification (`id=auth`), IPS (`id=alarm`) — et ajoute des règles de détection mappées **MITRE ATT&CK**.

## Ce que le pack détecte

| Événement Stormshield | Règle | Niveau | MITRE ATT&CK |
|---|---|:---:|---|
| Connexion **bloquée** par le filtrage | `100301` | 4 | — |
| **Scan / attaque** (blocages répétés, même source) | `100303` | **10** | T1046 — Network Service Discovery |
| **Échec d'authentification** | `100310` | 5 | T1110 — Brute Force |
| **Brute-force** authentification | `100311` | **10** | T1110 |
| Alarme **IPS** | `100320` | 6 | — |
| **Alarme IPS bloquante** | `100321` | **9** | T1046 |

Les connexions **autorisées** (`100302`) sont décodées en niveau 0 : traçables, sans bruit d'alerte.

Champs décodés exploitables : `srcip`, `srcport`, `dstip`, `dstport`, `protocol`, `action`, `dstuser`, `ss_msg`, `ss_alarmid`.

## Prérequis

- Wazuh **4.x**.
- Logs Stormshield SNS transmis au manager Wazuh en **syslog** (voir plus bas).

## Installation

```bash
git clone https://github.com/serytia/wazuh-stormshield-detection.git
cd wazuh-stormshield-detection
sudo ./install.sh
```

Le script copie les fichiers, **valide la configuration** (`wazuh-analysisd -t`) puis redémarre Wazuh. Rollback : `sudo ./uninstall.sh`.

### Installation manuelle

Copier `decoders/stormshield_decoders.xml` dans `/var/ossec/etc/decoders/` et
`rules/stormshield_rules.xml` dans `/var/ossec/etc/rules/` (propriétaire `wazuh:wazuh`, mode `660`), puis `/var/ossec/bin/wazuh-control restart`.

## Tester sans Stormshield

```bash
while IFS= read -r line; do
  echo "$line" | /var/ossec/bin/wazuh-logtest
done < samples/stormshield-samples.log
```

Les samples couvrent les trois voies (filtrage, authentification, IPS).

## Envoyer les logs Stormshield à Wazuh

- **Sur le SNS** : *Configuration → Notifications → Syslog* — ajouter le manager Wazuh comme serveur syslog (UDP/TCP **514**).
- **Sur Wazuh** : activer la réception syslog distante dans `ossec.conf` :
  ```xml
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips>IP_DU_FIREWALL</allowed-ips>
  </remote>
  ```
  puis redémarrer Wazuh.

## Tableau de bord

Requêtes et visualisations prêtes à l'emploi dans [`dashboard/README.md`](dashboard/README.md).

## Réserve & feuille de route

- Le décodeur **filtrage** (`id=firewall`) est le plus solide. Les décodeurs **auth** et **alarm** sont calés sur la documentation Stormshield « Description des journaux d'audit » et validés sur des logs d'exemple ; **l'ordre exact des champs et la valeur du `id=` restent à reconfirmer sur un vrai SNS en production**. Le décodeur ciblant les champs **par nom**, le risque est faible : au pire une règle ne se déclenche pas — pas de faux positif.
- À venir : géo-IP sur `srcip`, catégories d'alarmes IPS, tunnels VPN (`id=vpn`), dashboard « 1-clic » (`.ndjson`).

## Aller plus loin

Ce pack couvre Stormshield SNS. Pour **brancher la détection sur toute votre stack** (Proxmox, Microsoft 365, sauvegardes…), un **déploiement clé en main**, ou une version **white-label pour MSP/MSSP** : ouvrez une **[issue](../../issues)** ou contactez **[@serytia](https://github.com/serytia)**.

## Licence

**GPLv2** — cohérent avec le ruleset Wazuh. Voir [LICENSE](LICENSE).
