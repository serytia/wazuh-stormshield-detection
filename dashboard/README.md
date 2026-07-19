# Dashboard — Stormshield SNS detection pack

The pack writes its alerts to the Wazuh index `wazuh-alerts-*`, under the **`stormshield`** group.
Explore them in **Wazuh Dashboard → Threat Hunting / Discover**, or build a dashboard from a few visualizations.

## Ready-made searches (DQL)

| Goal | Query |
|---|---|
| All pack alerts | `rule.groups: "stormshield"` |
| Blocked connections (filtering) | `rule.groups: "firewall_drop"` |
| **Scan / attack** (T1046) | `rule.id: "100303"` |
| Authentication failures (T1110) | `rule.groups: "authentication_failed"` |
| **Brute-force** authentication | `rule.id: "100311"` |
| IPS alarms | `rule.groups: "ids"` |
| **Blocking IPS alarm** | `rule.id: "100321"` |

Decoded fields you can use: `data.srcip`, `data.dstip`, `data.dstport`, `data.protocol`,
`data.action`, `data.dstuser`, `data.ss_alarmid`, `data.ss_msg`, `rule.mitre.id`.

## Recommended visualizations

| Panel | Type | Query / field |
|---|---|---|
| Pack alerts over time | Line (date histogram) | `rule.groups: "stormshield"` |
| MITRE ATT&CK breakdown | Pie | field `rule.mitre.id` |
| Top blocked sources | Bars | `rule.groups: "firewall_drop"` · field `data.srcip` |
| Targeted destination ports | Bars | `rule.groups: "firewall_drop"` · field `data.dstport` |
| Auth failures by user | Bars | `rule.groups: "authentication_failed"` · field `data.dstuser` |
| IPS alarms by `alarmid` | Table | `rule.groups: "ids"` · field `data.ss_alarmid` |

## One-click import

The **"Stormshield SNS - Detection (pack)"** dashboard ships ready to import:
[`sns-dashboard.ndjson`](sns-dashboard.ndjson) — counter, MITRE ATT&CK pie, timeline by severity
level, top blocked sources, targeted ports, and an IPS alarms table. **Validated on Wazuh
Dashboard 4.14 / OpenSearch Dashboards 2.19.**

- **Via the UI**: *Dashboards Management → Saved Objects → Import* → `sns-dashboard.ndjson` →
  *Import* (check "overwrite"). Then open "Stormshield SNS - Detection (pack)" and set the time
  picker to *Last 24 hours*.
- **Via the API**:
  ```bash
  curl -sk -u admin:PASS -H "osd-xsrf: true" \
    -F file=@sns-dashboard.ndjson \
    "https://YOUR-DASHBOARD/api/saved_objects/_import?overwrite=true"
  ```

It references the `wazuh-alerts-*` index pattern (Wazuh's default ID). If your install uses a
different ID, adjust the reference in the `.ndjson`.
