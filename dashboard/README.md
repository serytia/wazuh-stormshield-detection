# Dashboard — Stormshield SNS detection pack

Le pack écrit ses alertes dans l'index Wazuh `wazuh-alerts-*`, sous le groupe **`stormshield`**.
Explore-les dans **Wazuh Dashboard → Threat Hunting / Discover**, ou monte un tableau de bord en quelques visualisations.

## Recherches prêtes (DQL)

| Objectif | Requête |
|---|---|
| Toutes les alertes du pack | `rule.groups: "stormshield"` |
| Connexions bloquées (filtrage) | `rule.groups: "firewall_drop"` |
| **Scan / attaque** (T1046) | `rule.id: "100303"` |
| Échecs d'authentification (T1110) | `rule.groups: "authentication_failed"` |
| **Brute-force** authentification | `rule.id: "100311"` |
| Alarmes IPS | `rule.groups: "ids"` |
| **Alarme IPS bloquante** | `rule.id: "100321"` |

Champs décodés exploitables : `data.srcip`, `data.dstip`, `data.dstport`, `data.protocol`,
`data.action`, `data.dstuser`, `data.ss_alarmid`, `data.ss_msg`, `rule.mitre.id`.

## Visualisations recommandées

| Panneau | Type | Requête / champ |
|---|---|---|
| Alertes du pack dans le temps | Ligne (date histogram) | `rule.groups: "stormshield"` |
| Répartition MITRE ATT&CK | Camembert | champ `rule.mitre.id` |
| Top sources bloquées | Barres | `rule.groups: "firewall_drop"` · champ `data.srcip` |
| Ports destination ciblés | Barres | `rule.groups: "firewall_drop"` · champ `data.dstport` |
| Échecs d'auth par utilisateur | Barres | `rule.groups: "authentication_failed"` · champ `data.dstuser` |
| Alarmes IPS par `alarmid` | Table | `rule.groups: "ids"` · champ `data.ss_alarmid` |

> Le dashboard **« 1-clic »** (`.ndjson`, comme pour le pack Proxmox) sera ajouté après
> validation visuelle sur un stack Wazuh complet — pour ne rien publier qui n'ait été vérifié.
