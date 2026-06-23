# SSH Brute Force Incident Report

## Summary

A brute-force attack was detected against a Linux VM after multiple failed SSH login attempts were observed from a single source IP.

## Detection

Alert Name: SSH Brute Force Detection

Rule ID: 100001

Severity: High

Time Detected: 2026-06-23 14:22 UTC

## Evidence

Source IP: 192.168.1.50

Failed Attempts: 15

Target Host: Ubuntu-Lab

Sample Log:

Failed password for testuser from 192.168.1.50 port 52133 ssh2

## MITRE ATT&CK

Technique: T1110.001 - Password Guessing

## Investigation

Reviewed authentication logs in /var/log/auth.log.

Confirmed repeated failed login attempts from a single source.

No successful login occurred.

## Containment

Blocked source IP using firewall rule.

Verified no account compromise.

## Lessons Learned

Adjusted alert threshold and enabled account lockout policy.
