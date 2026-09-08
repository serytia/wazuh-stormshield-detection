# Sample logs

- `stormshield-samples.log`: hand-written samples following the SNS v4 "Description of audit logs" note (syslog header + WELF body).
- `elastic-test-firewall.log` and `elastic-test-log-families.log`: public test data of the Stormshield integration of
  Elastic (`elastic/integrations`, `packages/stormshield/data_stream/log/_dev/test/pipeline/`, Elastic License 2.0),
  copied unmodified on 2026-09-08. Anonymized WELF lines without syslog header, covering `filter`, `connection`, `alarm`,
  `auth`, `web`, `vpn`, `system`, `monitor`, `filterstat`, `authstat`, `server`. Not captures from a production appliance,
  but the same field layout a real SNS emits, which is what the decoders are tested against.

Replay any file with `wazuh-logtest` on a manager where the pack is installed (one line per event).
