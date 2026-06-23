# 🛡️ Home Security Operations Center (SOC)

A hands-on home lab simulating a real-world Security Operations Center using open-source tooling. This project demonstrates log ingestion, threat detection, alerting, and incident response across a personal network — skills directly applicable to SOC Analyst, Security Engineer, and Blue Team roles.

---

## 📌 Project Goals

- Build a functional SIEM environment using **Wazuh** and/or **Splunk Free**
- Ingest logs from network devices, endpoints, and a Raspberry Pi
- Author custom detection rules for real attack patterns (brute force, port scans, privilege escalation, etc.)
- Practice triage, alert tuning, and incident documentation
- Demonstrate the day-to-day workflow of a SOC analyst

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     Home Network                        │
│                                                         │
│  ┌─────────────┐   ┌─────────────┐   ┌──────────────┐  │
│  │  Raspberry  │   │  Windows /  │   │   Router /   │  │
│  │     Pi      │   │  Linux VM   │   │   Firewall   │  │
│  │ (log agent) │   │ (endpoint)  │   │  (syslog)    │  │
│  └──────┬──────┘   └──────┬──────┘   └──────┬───────┘  │
│         │                 │                 │           │
│         └─────────────────┼─────────────────┘           │
│                           │                             │
│                    ┌──────▼──────┐                      │
│                    │  SIEM Host  │                      │
│                    │  (Wazuh /   │                      │
│                    │   Splunk)   │                      │
│                    └─────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

---

## 🧰 Tech Stack

| Component | Tool | Purpose |
|---|---|---|
| SIEM (Option A) | [Wazuh](https://wazuh.com/) | Open-source XDR/SIEM, agent-based log collection |
| SIEM (Option B) | [Splunk Free](https://www.splunk.com/en_us/download/splunk-enterprise.html) | Industry-standard SIEM, 500MB/day free tier |
| Log Agents | Wazuh Agent / Splunk UF | Installed on endpoints and Raspberry Pi |
| Network Logs | Syslog (router/firewall) | Network-level visibility |
| Attack Simulation | [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) | MITRE ATT&CK-mapped test cases |
| OS | Ubuntu 22.04 LTS (SIEM host) | Stable, widely used in enterprise |

---

## ⚙️ Setup

### Prerequisites

- A spare PC, server, or VM with at least **4GB RAM / 50GB disk** (8GB+ recommended for Splunk)
- Network access to devices you want to monitor
- Basic Linux comfort (SSH, file editing, service management)

### Option A — Wazuh (Recommended for Beginners)

Wazuh is fully open-source, includes a built-in dashboard, and is agent-based — making it easy to onboard new devices.

```bash
# 1. Run the Wazuh all-in-one installer (indexer + server + dashboard)
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
sudo bash wazuh-install.sh -a

# 2. Access the dashboard
# https://<your-siem-ip>:443
# Default credentials printed at end of install

# 3. Deploy agents to endpoints (run on each monitored host)
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -
# Follow agent enrollment steps in the dashboard under: Agents > Deploy New Agent
```

See [`agent-configs/`](./agent-configs/) for pre-configured `ossec.conf` files for different device types.

### Option B — Splunk Free

Splunk is the industry standard. The free tier (500MB/day) is enough for a home lab.

```bash
# 1. Download Splunk Enterprise (free license) from splunk.com
# 2. Install on Ubuntu
sudo dpkg -i splunk-<version>-linux-2.6-amd64.deb
sudo /opt/splunk/bin/splunk start --accept-license

# 3. Install Universal Forwarder on each endpoint
# https://www.splunk.com/en_us/download/universal-forwarder.html

# 4. Configure forwarder to send to your SIEM IP on port 9997
sudo /opt/splunkforwarder/bin/splunk add forward-server <SIEM-IP>:9997
```

---

## 📡 Log Sources

| Source | Log Type | Method |
|---|---|---|
| Raspberry Pi | Auth logs, cron, syslog | Wazuh Agent / Splunk UF |
| Windows endpoints | Event logs (4624, 4625, 4688…) | Wazuh Agent / Splunk UF |
| Linux VMs | `/var/log/auth.log`, `/var/log/syslog` | Wazuh Agent / Splunk UF |
| Router / Firewall | Syslog (connection, deny events) | Syslog forward to SIEM port 514 |
| Web server (optional) | Apache / Nginx access + error logs | Wazuh Agent |

---

## 🔍 Detection Rules

Custom rules are stored in [`wazuh-rules/`](./wazuh-rules/) and Splunk alerts in [`splunk-alerts/`](./splunk-alerts/).

### Example Detections

| Rule | ATT&CK Technique | Severity |
|---|---|---|
| SSH brute force (5+ failures in 60s) | T1110.001 | High |
| Successful login after multiple failures | T1110.001 | Critical |
| New user account created | T1136.001 | Medium |
| Sudo privilege escalation | T1548.003 | High |
| Port scan detected from internal host | T1046 | Medium |
| Cron job added by non-root user | T1053.003 | Medium |
| Outbound connection to known bad IP | T1071 | High |

### Sample Wazuh Custom Rule

```xml
<!-- wazuh-rules/local_rules.xml -->
<group name="custom_brute_force,">
  <rule id="100001" level="10" frequency="5" timeframe="60">
    <if_matched_sid>5716</if_matched_sid>
    <description>SSH brute force: 5+ failed logins in 60 seconds</description>
    <mitre>
      <id>T1110.001</id>
    </mitre>
    <group>authentication_failures,pci_dss_10.2.4,pci_dss_10.2.5,</group>
  </rule>
</group>
```

### Sample Splunk Search (SPL)

```spl
-- Detect repeated failed logins followed by success
index=main sourcetype=linux_secure "Failed password"
| stats count as failures by src_ip, user
| where failures > 5
| join src_ip [search index=main sourcetype=linux_secure "Accepted password"]
| table _time, src_ip, user, failures
| sort -failures
```

---

## 🧪 Attack Simulation

To validate that rules fire correctly, attacks are simulated using **Atomic Red Team**:

```bash
# Install Atomic Red Team (PowerShell — run on a test Windows VM)
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
Install-AtomicRedTeam -getAtomics

# Run a brute-force simulation test
Invoke-AtomicTest T1110.001

# On Linux — simulate brute force with hydra against your own test box
hydra -l testuser -P /usr/share/wordlists/rockyou.txt ssh://192.168.x.x
```

> ⚠️ **Only run simulations against systems you own on your isolated lab network.**

---

## 📋 Incident Response Workflow

When an alert fires, the following triage process is followed:

```
1. DETECT   → Alert triggered in Wazuh/Splunk dashboard
2. TRIAGE   → Review raw logs, determine true/false positive
3. SCOPE    → Identify affected hosts, timeframe, lateral movement
4. CONTAIN  → Block IP (firewall rule), disable compromised account
5. DOCUMENT → Write incident report (see /incident-reports/)
6. TUNE     → Adjust rule threshold if false positive
```

Incident report templates are in [`incident-reports/`](./incident-reports/).

---

## 📁 Repository Structure

```
Home-SOC-Project/
├── agent-configs/          # Wazuh ossec.conf & Splunk inputs.conf for each device type
│   ├── raspberry-pi.conf
│   ├── windows-endpoint.conf
│   └── linux-vm.conf
├── wazuh-rules/            # Custom Wazuh detection rules (XML)
│   └── local_rules.xml
├── splunk-alerts/          # Saved SPL searches and alert configs
│   └── brute_force.spl
├── scripts/                # Setup and utility scripts
│   ├── install-wazuh.sh
│   ├── deploy-agent.sh
│   └── test-detections.sh
├── incident-reports/       # Documented simulated incidents
│   └── template.md
└── README.md
```

---

## 🎯 Skills Demonstrated

- **SIEM deployment & configuration** (Wazuh, Splunk)
- **Log ingestion pipeline** from heterogeneous sources
- **Custom detection rule authoring** (Wazuh XML, Splunk SPL)
- **MITRE ATT&CK framework** mapping
- **Alert triage** and false-positive tuning
- **Attack simulation** with Atomic Red Team
- **Incident documentation**

---

## 🗺️ Roadmap

- [x] Repository scaffolding
- [ ] Wazuh all-in-one install + dashboard
- [ ] Agent deployed on Raspberry Pi
- [ ] Agent deployed on Windows VM
- [ ] Router syslog forwarding configured
- [ ] 5 custom detection rules written and tested
- [ ] First simulated incident documented
- [ ] Splunk Free setup (parallel comparison)
- [ ] Threat intel feed integration (AbuseIPDB API)
- [ ] Automated alert → ticket workflow

---

## 📚 Resources

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Splunk Fundamentals 1 (free)](https://www.splunk.com/en_us/training/free-courses/splunk-fundamentals-1.html)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team)
- [TryHackMe — SOC Level 1 Path](https://tryhackme.com/path/outline/soclevel1)
- [Blue Team Labs Online](https://blueteamlabs.online/)

---

## 👤 Author

**KJ Kabangu**  
Aspiring Cybersecurity Professional | Blue Team Enthusiast  
[GitHub](https://github.com/KJKabangu) · [LinkedIn](#) <!-- add your LinkedIn URL -->

---

*This project is built for educational purposes on an isolated home lab network.*