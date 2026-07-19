# Wazuh Detection Pack — Stormshield SNS

> Wazuh rules & decoders for **Stormshield Network Security (SNS)** firewalls.

## The problem

Wazuh has **no native support** for Stormshield SNS logs. Sent raw over syslog, they arrive in the **WELF** format (`field=value`) and are neither decoded nor correlated: a **scan** (burst of blocks), a **brute-force** on the authentication portal, a **blocking IPS alarm** — nothing surfaces in clear text, nothing correlates.

This pack decodes Stormshield WELF logs — filtering (`id=firewall`), authentication (`id=auth`), IPS (`id=alarm`) — and adds detection rules mapped to **MITRE ATT&CK**.

## What the pack detects

| Stormshield event | Rule | Level | MITRE ATT&CK |
|---|---|:---:|---|
| Connection **blocked** by filtering | `100301` | 4 | — |
| **Scan / attack** (repeated blocks, same source) | `100303` | **10** | T1046 — Network Service Discovery |
| **Authentication failure** | `100310` | 5 | T1110 — Brute Force |
| Authentication **brute-force** | `100311` | **10** | T1110 |
| **IPS** alarm | `100320` | 6 | — |
| **Blocking IPS alarm** | `100321` | **9** | T1046 |

**Allowed** connections (`100302`) are decoded at level 0: traceable, without alert noise.

Decoded fields you can use: `srcip`, `srcport`, `dstip`, `dstport`, `protocol`, `action`, `dstuser`, `ss_msg`, `ss_alarmid`.

## Requirements

- Wazuh **4.x**.
- Stormshield SNS logs forwarded to the Wazuh manager over **syslog** (see below).

## Installation

```bash
git clone https://github.com/serytia/wazuh-stormshield-detection.git
cd wazuh-stormshield-detection
sudo ./install.sh
```

The script copies the files, **validates the configuration** (`wazuh-analysisd -t`), then restarts Wazuh. Rollback: `sudo ./uninstall.sh`.

### Manual installation

Copy `decoders/stormshield_decoders.xml` to `/var/ossec/etc/decoders/` and
`rules/stormshield_rules.xml` to `/var/ossec/etc/rules/` (owner `wazuh:wazuh`, mode `660`), then `/var/ossec/bin/wazuh-control restart`.

## Test without Stormshield

```bash
while IFS= read -r line; do
  echo "$line" | /var/ossec/bin/wazuh-logtest
done < samples/stormshield-samples.log
```

The samples cover the three paths (filtering, authentication, IPS).

## Send Stormshield logs to Wazuh

- **On the SNS**: *Configuration → Notifications → Syslog* — add the Wazuh manager as a syslog server (UDP/TCP **514**).
- **On Wazuh**: enable remote syslog reception in `ossec.conf`:
  ```xml
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips>FIREWALL_IP</allowed-ips>
  </remote>
  ```
  then restart Wazuh.

## Dashboard

Ready-to-use queries and visualizations in [`dashboard/README.md`](dashboard/README.md).

## Caveats & roadmap

- The **filtering** decoder (`id=firewall`) is the most solid. The **auth** and **alarm** decoders are based on the Stormshield "Audit logs description" documentation and validated against sample logs; **the exact field order and the `id=` value remain to be reconfirmed on a real SNS in production**. Since the decoders target fields **by name**, the risk is low: at worst a rule doesn't fire — no false positives.
- Coming next: geo-IP on `srcip`, IPS alarm categories, VPN tunnels (`id=vpn`).

## Going further

This pack covers Stormshield SNS. To **wire detection across your whole stack** (Proxmox, Microsoft 365, backups…), a **turnkey deployment**, or a **white-label build for MSP/MSSP**: open an **[issue](../../issues)** or reach out to **[@serytia](https://github.com/serytia)**.

## License

**GPLv2** — consistent with the Wazuh ruleset. See [LICENSE](LICENSE).
