# Home SOC Architecture

## Overview

The Home SOC consists of:

- 1 Wazuh server
- 1 Windows endpoint
- 1 Linux endpoint
- 1 Raspberry Pi

## Data Collection

Windows:
- Sysmon
- Event Logs

Linux:
- Auth Logs
- Syslog

Raspberry Pi:
- Auth Logs
- Cron Logs

## Detection Layer

Wazuh custom rules detect:

- Brute Force Attacks
- Port Scanning
- PowerShell Abuse
- Credential Dumping

## Response

Alerts are investigated and documented in the incident-reports directory.