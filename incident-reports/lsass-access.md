# LSASS Access Incident Report

## Summary

Unauthorized access attempt to LSASS process detected.

## Detection

Sysmon Event ID: 10

Alert Severity: Critical

## Evidence

Target Process:

C:\Windows\System32\lsass.exe

Source Process:

procdump.exe

## MITRE ATT&CK

T1003.001 - OS Credential Dumping

## Investigation

Reviewed Sysmon Process Access events.

Observed a process attempting to read memory from LSASS.

No credential dump file was successfully created.

## Containment

Terminated offending process.

Collected forensic artifacts.

## Lessons Learned

Added enhanced monitoring for credential-access tools.
