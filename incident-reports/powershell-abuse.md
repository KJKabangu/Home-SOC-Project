# PowerShell Abuse Incident Report

## Summary

Suspicious PowerShell execution detected on a Windows endpoint.

## Detection

Sysmon Event ID: 1

Alert Severity: High

## Evidence

Command:

powershell.exe -enc SQBmACAAZABpAGQAIABhACAAdABoAGkAbmcA

Parent Process:

cmd.exe

## MITRE ATT&CK

T1059.001 - PowerShell

## Investigation

Reviewed Sysmon Process Creation logs.

Detected use of encoded PowerShell command.

Verified activity originated from a security testing exercise.

## Containment

Process terminated.

No persistence mechanisms found.

## Lessons Learned

Created additional detection for Base64-encoded PowerShell commands.
