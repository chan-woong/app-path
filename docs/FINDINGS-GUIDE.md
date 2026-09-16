# Security Findings Guide

`app-path` can surface evidence relevant to insecure deep links, WebView attack surface, weak transport configuration, excessive entitlements, insecure shared containers, sensitive local storage, application-state leakage, WebKit storage exposure, configuration leakage, embedded-component exposure, and debug/provisioning exposure.

An indicator alone is not a vulnerability. Use: `Indicator + Reachability + security-relevant behavior + missing control + demonstrable impact`. Severity must come from validated impact and attack preconditions, not the tool output alone.
