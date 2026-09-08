# Wazuh Detection Pack — Stormshield SNS

> Wazuh rules & decoders for **Stormshield Network Security (SNS)** firewalls.

## The problem

Wazuh has **no native support** for Stormshield SNS logs. Sent raw over syslog, they arrive in the **WELF** format (`field=value`) and are neither decoded nor correlated: a **scan** (burst of blocks), a **brute-force** on the authentication portal, a **blocking IPS alarm** — nothing surfaces in clear text, nothing correlates.

This pack decodes Stormshield WELF logs — filtering, authentication and IPS, distinguished by the **`logtype=`** field (`filter` / `auth` / `alarm`) that every SNS syslog line carries — and adds detection rules mapped to **MITRE ATT&CK**.

## What the pack detects

| Stormshield event | Rule | Level | MITRE ATT&CK |
|---|---|:---:|---|
| Connection **blocked** by filtering | `100301` | 4 | — |
| **Scan / attack** (repeated blocks, same source) | `100303` | **10** | T1046 — Network Service Discovery |
| **Authentication failure** | `100310` | 5 | T1110 — Brute Force |
| Authentication **brute-force** | `100311` | **10** | T1110 |
| **IPS** alarm | `100320` | 6 | — |
| **Blocking IPS alarm** | `100321` | **9** | T1190 — Exploit Public-Facing Application |

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

## Validation status

Honest disclosure: the decoders are built to the field names and WELF/syslog format
documented in Stormshield's *Description of audit logs* (SNS v4) and cross-checked against
real log captures published by third-party integrations, then validated end-to-end with
`wazuh-logtest` on a sample set covering filtering (incl. ICMP with no ports),
authentication (both `src`/`user` field orders), and IPS alarms. They have **not yet been
confirmed against a specific live SNS appliance** — field availability can vary by model
and firmware, so run the `wazuh-logtest` check above on your own logs before relying on it
in production. (An earlier version of this pack dispatched on `id=auth` / `id=alarm`, which
real SNS syslog never emits — the type is always in `logtype=`; that is now fixed.)

### Replay on public SNS test logs (2026-09-08)

48 lines of public Stormshield SNS logs were replayed through `wazuh-logtest`:
`test-firewall.log` (35 lines) comes from the test data of Elastic's Stormshield
integration (Elastic License 2.0), plus `test-log-families.log` (13 lines) from the same test
directory, covering the other SNS log families. Both files are in `samples/`, unmodified.
Numbers as measured, **before** the alarm fix described below:

| File | Lines | Decoded by the pack |
|---|:---:|---|
| `test-firewall.log` | 35 | 3 (`filter` 1/1, `auth` 1/1, `alarm` 1/1 but with empty fields) |
| 13-line log-family set | 13 | 5 (`auth` 2/2, `filter` 1/1, `alarm` 2/2, one with empty fields) |

Every line of the three log types the pack claims to cover reached a pack decoder, but the
field **order** inside an alarm line is not stable on real logs: 2 of the 3 alarm lines
decoded zero fields, so a blocking IPS alarm stayed at level 6 (`100320`) instead of
reaching `100321`. The alarm decoder now carries sibling decoders for the observed orders,
including system alarms that have no `src`/`dst` at all. **Re-measured on a Wazuh 4.14.6
manager after the fix** (same three files): the blocking IPS alarm with `alarmid` first now
decodes `src`, `dst` and `action` and fires `100321` (level 9) instead of `100320` (level 6);
the system alarm (`class=system`, no network fields) now decodes `ss_alarmid` and stays at
`100320`; `stormshield-samples.log` still decodes 10/10 with the same rules as before.
Coverage by log type is unchanged (3/35 and 5/13), because the other lines belong to
families the pack does not claim.

The other lines are log types this pack does not cover, by choice: `connection` (10),
`server` (9), `system` (8), `web` (2), `vpn` (2), `count` (2), `filterstat` (2), `authstat`,
`monitor`, `plugin`, `xvpn`, and one line of a deliberately unknown family. One `filter`
line carrying an empty `action=` decodes at the
grouped level only (`100300`, no fields).

Coming next: geo-IP on `srcip`, IPS alarm categories, VPN tunnels (`logtype="vpn"`), and
first-hand validation against a live/EVA appliance.

## Going further

This pack covers Stormshield SNS. To **wire detection across your whole stack** (Proxmox, Microsoft 365, backups…), a **turnkey deployment**, or a **white-label build for MSP/MSSP**: open an **[issue](../../issues)** or reach out to **[@serytia](https://github.com/serytia)**.

## License

**GPLv2** — consistent with the Wazuh ruleset. See [LICENSE](LICENSE).
