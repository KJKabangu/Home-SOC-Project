# Port Scan Incident Report

## Summary

A network scan was detected from an internal host using Nmap.

## Detection

Alert Name: Internal Port Scan

Severity: Medium

## Evidence

Source Host: Kali VM

Target Host: Ubuntu-Lab

Command Executed:

nmap -sV 192.168.1.100

Multiple connection attempts observed across sequential ports.

## MITRE ATT&CK

Technique: T1046 - Network Service Discovery

## Investigation

Analyzed firewall and Sysmon network logs.

Observed connections to ports 22, 80, 443, and 3389 within a short timeframe.

## Containment

No containment required because activity originated from an authorized test system.

## Lessons Learned

Detection successfully identified reconnaissance activity.
