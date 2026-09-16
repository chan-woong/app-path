# Analysis Guide

Recommended sequence: `--list` → `--basic` → `--security`/`--groups` → `--review` → storage modes → targeted `--plist` queries → static analysis → authorized Frida/Burp validation.

Review URL schemes for authentication/authorization, parameter validation, redirects, and WebView entry points. Review ATS exceptions against actual HTTP/TLS behavior. Review `get-task-allow`, Keychain access groups, application groups, and associated domains against the intended trust boundary. Review SQLite/Realm/plist/JSON/XML, Saved Application State, cookies, Local Storage, WebsiteData, and HTTPStorages for sensitive data.

Correlate findings with native code involving `WKWebView`, `WKScriptMessageHandler`, `evaluateJavaScript`, URL handlers, `SecItemAdd`, `SecItemCopyMatching`, `UserDefaults`, database writes, certificate validation, crypto, and IPC/XPC.

A final finding should include affected version/component, preconditions, reproduction steps, expected/actual behavior, impact, evidence, remediation, and retest criteria.
