# app-path

`app-path` is a lightweight command-line utility for **jailbroken iOS application discovery and security triage**.

It is designed for mobile application security assessments where common iOS/macOS utilities such as `plutil` may not be available on the target device.

Given an application's Bundle ID, `app-path` can locate the installed application bundle and data container, parse a binary `Info.plist`, inspect URL schemes and provisioning information, enumerate local storage, and collect indicators useful during an iOS security assessment.

> `app-path` is an evidence collection and triage tool.
> An indicator reported by the tool is **not automatically a vulnerability**. Reachability, security controls, attack preconditions, and actual impact must be validated separately.

Korean documentation: [README.ko.md](README.ko.md)

---

## Why app-path?

During an iOS application security assessment, an analyst frequently needs to answer questions such as:

* Where is the application bundle?
* Where is the application's writable data container?
* What is the application's executable name and version?
* Which URL schemes or deep-link entry points are registered?
* Does the application contain ATS exceptions?
* Was the application provisioned with `get-task-allow`?
* Which Keychain Access Groups are available?
* Does the application use Application Groups?
* Are Associated Domains configured?
* Which frameworks, plug-ins, or extensions are bundled?
* Are SQLite, Realm, plist, JSON, or XML files stored locally?
* Does the application leave data in Saved Application State?
* Does it use WebKit storage such as cookies or Local Storage?

`app-path` collects this information from a jailbroken device through a single CLI.

---

# Features

## Application Discovery

Search installed applications and identify their Bundle IDs.

```sh
app-path --list
```

Example output:

```text
[ INSTALLED APPS ]

com.example.app    Example App    1.4.2    1042    /var/containers/Bundle/Application/.../Example.app
```

This is useful when the application name is known but its exact Bundle ID is not.

---

## Bundle and Data Container Discovery

```sh
app-path com.example.app --basic
```

Example:

```text
[ BASIC ]

Bundle ID       : com.example.app
Bundle Path     : /var/containers/Bundle/Application/<UUID>/Example.app
Data Path       : /var/mobile/Containers/Data/Application/<UUID>

CFBundleDisplayName : Example
CFBundleExecutable  : Example
Version             : 1.4.2
Build               : 1042
Minimum iOS         : 15.0
URL Scheme          : example
```

The application bundle normally contains executable code and packaged resources.

The Data Container contains writable application data such as:

```text
Documents/
Library/
Library/Preferences/
Library/Caches/
tmp/
```

Knowing both locations is fundamental for static analysis and local-storage review.

---

# Binary Info.plist Parsing

iOS applications commonly use a binary property-list format:

```text
bplist00
```

On constrained jailbreak environments, `plutil` or Python plist libraries may not be available.

`app-path` includes an AWK-based binary plist parser:

```text
libexec/app-path-bplist.awk
```

The parser reads plist bytes through `od` and traverses the binary plist object graph.

This allows common `Info.plist` values to be inspected without depending on:

* `plutil`
* Python
* Ruby
* Swift
* Objective-C runtime helpers
* third-party plist tools

---

# Query Info.plist

Specific plist keys can be queried directly.

```sh
app-path com.example.app --plist CFBundleURLSchemes
```

Other useful examples:

```sh
app-path com.example.app --plist CFBundleURLTypes

app-path com.example.app --plist LSApplicationQueriesSchemes

app-path com.example.app --plist CFBundleDocumentTypes

app-path com.example.app --plist NSAppTransportSecurity
```

This is useful for identifying application entry points and security-relevant configuration.

---

# URL Scheme / Deep-Link Review

Applications may register custom URL schemes.

For example:

```text
example://
```

Run:

```sh
app-path com.example.app --basic
```

or:

```sh
app-path com.example.app --plist CFBundleURLSchemes
```

Possible output:

```text
CFBundleURLSchemes    example
```

A registered URL scheme represents an externally reachable application entry point.

During a security assessment, investigate whether external input can reach:

* authentication flows
* account operations
* sensitive screens
* payment or transaction functions
* WebViews
* redirect handlers
* internal application functionality

Potential vulnerability classes include:

```text
Deep Link Authentication Bypass
Deep Link Authorization Bypass
Unvalidated URL Parameters
Unsafe Redirect Handling
WebView Navigation Manipulation
Sensitive Data Exposure Through URLs
```

The existence of a URL scheme alone does not prove any of these vulnerabilities.

---

# Provisioning and Entitlement Review

Run:

```sh
app-path com.example.app --security
```

Example output:

```text
[ SECURITY / PROVISIONING ]

application-identifier : TEAMID.com.example.app
team-identifier        : TEAMID
get-task-allow         : false
aps-environment        : production

[ associated-domains ]

applinks:example.com

[ keychain-access-groups ]

TEAMID.com.example.shared

[ application-groups ]

group.com.example.shared

[ profile flags ]

CreationDate           : ...
ExpirationDate         : ...
```

These values help identify the application's security boundaries.

---

## get-task-allow

A particularly important value is:

```text
get-task-allow
```

For example:

```text
get-task-allow : true
```

This entitlement allows debugging-related task access under appropriate platform conditions.

If it appears in a production-distributed application, analysts should verify:

* build type
* provisioning context
* debugging exposure
* whether the entitlement was intentionally enabled

Do not classify the application as vulnerable solely because the value is present.

---

# Keychain Access Groups

Example:

```text
[ keychain-access-groups ]

TEAMID.com.example.shared
```

Keychain Access Groups define Keychain sharing boundaries between applications.

During an assessment, determine:

* which applications share the group
* what data is stored in the shared namespace
* whether sensitive credentials or tokens are shared
* whether another application can access the same group
* whether access controls match the intended trust model

This can support investigation of issues involving inappropriate credential sharing or excessive trust relationships.

---

# Application Groups

Example:

```text
[ application-groups ]

group.com.example.shared
```

Application Groups allow multiple applications or extensions to access a shared container.

Review:

```text
Shared preferences
Shared files
Authentication state
Session information
Tokens
IPC data
Extension communication
```

The presence of an Application Group is not itself a vulnerability. The important question is what crosses that trust boundary.

---

# Associated Domains

Example:

```text
[ associated-domains ]

applinks:example.com
```

Associated Domains are commonly used for Universal Links.

During assessment, review:

* associated domain ownership
* AASA configuration
* accepted URL paths
* authentication behavior
* authorization after link handling
* redirects
* sensitive parameters

This helps identify the Universal Link attack surface.

---

# Local Storage Discovery

Run:

```sh
app-path com.example.app --files
```

The tool searches for potentially interesting files such as:

```text
*.plist
*.json
*.xml
*.db
*.sqlite
*.sqlite3
*.realm
```

Example:

```text
[ FILES / COMPONENTS ]

/var/mobile/Containers/Data/Application/<UUID>/Library/Preferences/com.example.app.plist

/var/mobile/Containers/Data/Application/<UUID>/Documents/application.db

/var/mobile/Containers/Data/Application/<UUID>/Library/config.json
```

These files become candidates for manual sensitive-data review.

---

# Database Discovery

```sh
app-path com.example.app --db
```

Searches for:

```text
.db
.sqlite
.sqlite3
.realm
```

Review discovered databases for security-relevant data such as:

```text
Access tokens
Refresh tokens
Session identifiers
User information
Authentication state
Personal information
Transaction information
Application secrets
```

The presence of a database does not imply insecure storage.

---

# Configuration File Discovery

```sh
app-path com.example.app --config
```

Searches for:

```text
.plist
.json
.xml
```

These files may contain:

```text
API endpoints
Feature flags
Environment configuration
Internal URLs
Client configuration
Authentication state
Tokens or credentials
```

Any discovered value should be evaluated in context before it is treated as sensitive.

---

# Saved Application State

```sh
app-path com.example.app --state
```

iOS may persist application UI state under:

```text
Library/Saved Application State/
```

Security review should determine whether sensitive information remains in persisted application state after:

* logout
* application termination
* account switching
* session expiration

---

# WebKit Storage

```sh
app-path com.example.app --webkit
```

The tool searches for WebKit-related storage paths such as:

```text
WebKit
Cookies
WebsiteData
HTTPStorages
LocalStorage
```

These locations are particularly relevant for applications using:

```text
WKWebView
Hybrid application frameworks
Embedded web authentication
JavaScript bridges
```

Review for:

```text
Session cookies
Authentication tokens
Local Storage
Cached sensitive content
Persistent web sessions
WebView-origin data
```

---

# Embedded Components

`--files` also enumerates application components under locations such as:

```text
Frameworks/
PlugIns/
Extensions/
```

This can help identify:

* third-party frameworks
* app extensions
* embedded SDKs
* additional executable components
* unexpected attack surfaces

The discovered component names can then be correlated with IDA, Ghidra, or other static-analysis tools.

---

# Security Review Mode

For a quick first-pass review:

```sh
app-path com.example.app --review
```

Example:

```text
[ SECURITY REVIEW INDICATORS ]

ATS configuration key      : FOUND
NSAllowsArbitraryLoads      : NOT FOUND
URL scheme configuration    : FOUND
get-task-allow              : false
keychain-access-groups      : FOUND
application-groups          : FOUND
associated-domains          : FOUND
```

This mode is intended to answer:

> Which areas should I investigate next?

It is not intended to answer:

> Is this application vulnerable?

---

# Full Collection

```sh
app-path com.example.app --all
```

This executes the primary collection modes together:

```text
Basic application information
Embedded components
Database discovery
Configuration discovery
Saved Application State
WebKit storage
Provisioning information
Application Groups
Security review indicators
```

This is useful at the beginning of an assessment when building an initial attack-surface map.

---

# Security Assessment Workflow

A practical workflow is:

```text
Installed application
        │
        ▼
app-path --list
        │
        ▼
--basic
        │
        ├── Bundle path
        ├── Data container
        ├── Version/build
        └── URL schemes
        │
        ▼
--security / --groups
        │
        ├── Provisioning
        ├── get-task-allow
        ├── Keychain groups
        ├── Application groups
        └── Associated domains
        │
        ▼
--files / --db / --config
        │
        └── Local storage review
        │
        ▼
--state / --webkit
        │
        └── Persistent state and WebView storage
        │
        ▼
Static analysis
        │
        ├── IDA
        ├── Ghidra
        └── other authorized analysis tools
        │
        ▼
Dynamic validation
        │
        ├── Frida
        └── Burp Suite
        │
        ▼
Validated security finding
```

---

# Static Analysis Correlation

Information discovered with `app-path` can be correlated with native application code.

Useful strings/APIs to investigate include:

```text
WKWebView
WKScriptMessageHandler
evaluateJavaScript
openURL
application:openURL:options:
scene:openURLContexts:
SecItemAdd
SecItemCopyMatching
UserDefaults
SQLite
Realm
```

For example:

```text
app-path
    ↓
URL Scheme discovered
    ↓
Locate URL handler in native code
    ↓
Trace external parameters
    ↓
Identify privileged operation
    ↓
Validate authentication/authorization
```

This reduces the amount of code that must be inspected blindly.

---

# Dynamic Analysis Correlation

After identifying a candidate attack surface, dynamic instrumentation can verify whether it is actually reachable.

Examples:

```text
URL Scheme
    → trace URL handler
    → inspect parameters
    → observe sensitive function calls

WKWebView
    → inspect navigation
    → trace JavaScript bridge
    → verify origin/trust validation

Local Storage
    → trigger login/logout
    → observe file changes
    → determine whether sensitive data persists

Network configuration
    → capture authorized test traffic
    → verify actual TLS behavior
```

---

# What Vulnerabilities Can app-path Help Investigate?

The tool can provide initial evidence relevant to:

* insecure deep-link handling
* URL scheme attack surface
* Universal Link handling
* WebView attack surface
* JavaScript bridge exposure
* weak transport configuration
* debug/provisioning exposure
* excessive entitlements
* inappropriate Keychain sharing
* insecure Application Group usage
* sensitive local-data storage
* application-state leakage
* WebKit storage exposure
* configuration leakage
* unexpected embedded components

`app-path` does **not** automatically prove these vulnerabilities.

A useful assessment model is:

```text
Indicator
    +
Reachability
    +
Security-relevant behavior
    +
Missing or insufficient security control
    +
Demonstrable impact
    =
Reportable security finding
```

---

# Requirements

The target jailbroken device should provide common command-line utilities including:

```text
awk or gawk
od
grep
find
dd
head
cut
tr
sort
sed
```

Default installation paths:

```text
/var/jb/usr/local/bin/app-path
/var/jb/usr/local/libexec/app-path-bplist.awk
```

---

# Installation

```sh
git clone https://github.com/chan-woong/app-path.git
cd app-path

sh install.sh

export PATH="/var/jb/usr/local/bin:$PATH"
```

Verify:

```sh
app-path --version
```

Expected:

```text
app-path v3.1.1
```

---

# Documentation

Additional documentation is available under:

```text
docs/
├── ANALYSIS-GUIDE.md
├── ANALYSIS-GUIDE.ko.md
├── FINDINGS-GUIDE.md
└── FINDINGS-GUIDE.ko.md
```

* `ANALYSIS-GUIDE.md` — practical security-analysis workflow
* `FINDINGS-GUIDE.md` — interpretation of security indicators
* Korean equivalents are provided for both documents.

---

# Limitations

`app-path` is not a complete iOS security scanner.

It does not:

* automatically determine exploitability
* automatically assign vulnerability severity
* decrypt protected application data
* automatically dump Keychain secrets
* replace static analysis
* replace dynamic instrumentation
* replace network analysis

Provisioning-profile parsing is intentionally lightweight, and some non-ASCII binary plist strings may be represented conservatively.

---

# Responsible Use

Use `app-path` only on applications and devices that you own or are explicitly authorized to assess.

Security findings should be based on reproducible evidence and validated impact rather than a configuration indicator alone.

---

# License

MIT License. See [LICENSE](LICENSE).
