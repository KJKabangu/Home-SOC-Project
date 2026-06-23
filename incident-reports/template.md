# Incident Report — [INCIDENT-ID]

> **Template usage:** Duplicate this file and rename it to the incident ID (e.g. `IR-2024-001.md`).  
> Fill in every section. Leave no field blank — use `N/A` or `None observed` where applicable.

---

## 1. Incident Summary

| Field | Details |
|---|---|
| **Incident ID** | IR-YYYY-### |
| **Date Detected** | YYYY-MM-DD |
| **Time Detected** | HH:MM UTC |
| **Date Resolved** | YYYY-MM-DD |
| **Time Resolved** | HH:MM UTC |
| **Total Duration** | X hours Y minutes |
| **Analyst** | Your Name |
| **Severity** | 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low |
| **Status** | Open / Contained / Resolved / Closed |
| **Classification** | Brute Force / Malware / Insider Threat / Recon / Web Attack / Other |

**One-line description:**
> _e.g. "Repeated SSH login failures from external IP 203.0.113.42 followed by a successful authentication."_

---

## 2. Detection

**Alert triggered:**
> _Name of the Wazuh rule or Splunk alert that fired._

**Rule ID / Alert name:**
> _e.g. Rule 100002 — Successful login after brute force_

**MITRE ATT&CK Technique:**
> _e.g. T1110.001 — Brute Force: Password Guessing_

**Log source:**
> _e.g. `/var/log/auth.log` on host `raspberrypi-01`_

**Raw log snippet (anonymized):**
```
Paste the key log line(s) that triggered the alert here.
e.g.
Jan 15 03:42:17 raspberrypi sshd[1234]: Failed password for root from 203.0.113.42 port 52341 ssh2
Jan 15 03:42:31 raspberrypi sshd[1234]: Accepted password for root from 203.0.113.42 port 52341 ssh2
```

---

## 3. Affected Assets

| Asset | Role | IP Address | OS |
|---|---|---|---|
| | | | |
| | | | |

---

## 4. Timeline

| Time (UTC) | Event |
|---|---|
| HH:MM | First malicious log entry observed |
| HH:MM | Alert triggered in SIEM |
| HH:MM | Analyst begins triage |
| HH:MM | Scope confirmed / false positive ruled out |
| HH:MM | Containment action taken |
| HH:MM | Threat cleared / incident resolved |

---

## 5. Triage & Analysis

**Is this a true positive or false positive?**
> _True Positive / False Positive / Benign True Positive_

**Reasoning:**
> _Explain how you determined this. What evidence confirmed or ruled out malicious intent?_

**Scope — lateral movement observed?**
> _Yes / No. If yes, list affected hosts._

**Data exfiltration observed?**
> _Yes / No. If yes, describe._

**Persistence mechanisms found?**
> _e.g. New cron job, new user account, SSH key added. List findings or write "None observed."_

**Attacker tools / techniques identified:**
> _e.g. Hydra brute force, nc reverse shell, etc._

---

## 6. Containment

**Actions taken:**

- [ ] Blocked source IP at firewall: `<IP>`
- [ ] Disabled compromised user account: `<username>`
- [ ] Removed unauthorized SSH key from `~/.ssh/authorized_keys`
- [ ] Killed malicious process PID: `<PID>`
- [ ] Isolated host from network: `<hostname>`
- [ ] Other: ___

**Containment verified?**
> _Yes / No. How confirmed?_

---

## 7. Root Cause

> _What allowed this to happen? e.g. "SSH password authentication enabled with a weak password on the root account. No rate limiting or fail2ban configured."_

---

## 8. Remediation

**Immediate fixes applied:**

- [ ] Changed compromised credentials
- [ ] Disabled SSH password auth, enforced key-based auth
- [ ] Installed and configured fail2ban
- [ ] Patched vulnerable service (version: ___)
- [ ] Removed unauthorized accounts / cron jobs
- [ ] Other: ___

**Long-term hardening recommendations:**
> _What systemic changes prevent recurrence? e.g. "Disable root SSH login globally. Implement 2FA for all remote access."_

---

## 9. Detection Rule Review

**Did the rule perform as expected?**
> _Yes / No_

**False positive rate:**
> _e.g. "Rule fired 3 times during testing; 1 was a false positive from a legitimate admin login."_

**Rule tuning applied?**
> _e.g. "Raised threshold from 5 to 8 failures to reduce noise from automated backup scripts."_

**New rule needed?**
> _Yes / No. If yes, describe._

---

## 10. Lessons Learned

**What went well?**
> 

**What could be improved?**
> 

**Follow-up actions:**

| Action | Owner | Due Date |
|---|---|---|
| | | |
| | | |

---

## 11. References

- Wazuh alert ID / Splunk search link:
- MITRE ATT&CK: https://attack.mitre.org/techniques/T____/
- Related CVE (if applicable):
- External threat intel:

---

*Report completed by: __________________ Date: __________________*