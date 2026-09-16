# app-path

`app-path` is a lightweight command-line utility for **authorized iOS application security assessment on jailbroken devices**.

It discovers installed applications and their containers, parses binary `Info.plist` files without relying on `plutil`, inspects provisioning and application metadata, enumerates local storage, and highlights configuration values that are useful during manual vulnerability analysis.

The tool is intended primarily as a **reconnaissance and triage utility**. It does not automatically declare an application vulnerable. Instead, it helps an analyst quickly identify attack surfaces and evidence that should be investigated with static analysis, dynamic instrumentation, filesystem analysis, or network testing.

---

## Features

### Application discovery

Find installed applications by Bundle ID and identify:

* Application Bundle path
* Application Data Container path
* `Info.plist`
* Executable name
* Display name
* Application version
* Build number
* Minimum supported iOS version

Example:

```sh
app-path com.example.app --basic
```

Typical output:

```text
[ BASIC ]
Bundle ID       : com.example.app
Bundle Path     : /var/containers/Bundle/Application/<UUID>/Example.app
Data Path       : /var/mobile/Containers/Data/Application/<UUID>

CFBundleDisplayName : Example
CFBundleExecutable  : Example
Version             : 1.2.3
Build               : 123
Minimum iOS         : 15.0

URL Scheme          : example
```

This provides the paths required for subsequent static analysis, filesystem inspection, binary extraction, and runtime instrumentation.

---

## Binary Info.plist Parsing

Many iOS applications store `Info.plist` in Apple's binary plist format.

On constrained jailbreak environments, utilities such as `plutil`, Python plist libraries, or other parsing tools may not be installed.

`app-path` includes its own lightweight parser implemented using:

```text
od + AWK
```

The parser understands the binary plist object table and can retrieve common dictionaries, arrays, strings, integers, and Boolean values.

Example:

```sh
app-path com.example.app --plist CFBundleIdentifier
```

```text
CFBundleIdentifier    com.example.app
```

Another example:

```sh
app-path com.example.app --plist CFBundleURLSchemes
```

```text
CFBundleURLSchemes    example
```

This allows application metadata to be inspected directly on the device without copying every plist to another system first.

---

## Installed Application Enumeration

```sh
app-path --list
```

The command enumerates applications found under the iOS application bundle container.

Typical output:

```text
[ INSTALLED APPS ]

com.example.app       Example       1.2.3       123
com.example.second    SecondApp     2.0.0       45
```

This is useful when the exact Bundle ID of the assessment target is not known.

---

## Security and Provisioning Analysis

```sh
app-path com.example.app --security
```

The command inspects security-relevant values from the embedded provisioning profile.

Examples include:

```text
application-identifier
com.apple.developer.team-identifier
get-task-allow
aps-environment
keychain-access-groups
application-groups
com.apple.developer.associated-domains
CreationDate
ExpirationDate
```

Typical output:

```text
[ SECURITY / PROVISIONING ]

application-identifier : TEAMID.com.example.app
team-identifier        : TEAMID
get-task-allow         : false
aps-environment        : production

[ keychain-access-groups ]

TEAMID.com.example.shared

[ application-groups ]

group.com.example.shared

[ associated-domains ]

applinks:example.com
```

These values help identify trust relationships and security boundaries that require further review.

---

## `get-task-allow`

The `get-task-allow` entitlement is particularly useful during build and provisioning review.

Example:

```text
get-task-allow : true
```

A value of `true` may indicate that debugging capabilities are enabled.

This should **not automatically be reported as a vulnerability**.

The analyst should determine:

* whether the application is a development/debug build,
* whether the assessed package represents the production distribution,
* whether debugging creates a realistic security exposure,
* and whether sensitive functionality becomes accessible as a result.

---

## Keychain Access Groups

Example:

```text
[ keychain-access-groups ]

TEAMID.com.example.shared
```

Keychain access groups define Keychain namespaces that may be shared between applications signed under compatible entitlements.

This output can guide investigation into:

* shared authentication tokens,
* credentials,
* cryptographic keys,
* session information,
* cross-application trust relationships.

The presence of a shared group alone is not a vulnerability.

The security question is whether an unintended or insufficiently trusted application can access sensitive data through that group.

---

## Application Groups

Example:

```text
[ application-groups ]

group.com.example.shared
```

Application Groups allow multiple related applications or extensions to share a container.

During an assessment, investigate:

* which applications/extensions use the group,
* what information is stored in the shared container,
* whether authentication state is shared,
* whether another component can modify trusted data,
* whether authorization decisions depend on shared files.

---

## Associated Domains

Example:

```text
[ associated-domains ]

applinks:example.com
```

Associated Domains can expose Universal Link-related attack surface.

Further testing should include:

* Apple App Site Association configuration,
* accepted URL paths,
* authentication requirements,
* redirect behavior,
* parameter validation,
* sensitive actions triggered from Universal Links.

---

## URL Scheme / Deep Link Analysis

Applications may register custom URL schemes.

Example:

```sh
app-path com.example.app --plist CFBundleURLSchemes
```

Output:

```text
CFBundleURLSchemes    example
```

This indicates that URLs similar to:

```text
example://...
```

may be handled by the application.

The analyst should then locate the corresponding URL handler in the application code.

Useful native methods and APIs include:

```text
application:openURL:options:
scene:openURLContexts:
openURL
canOpenURL
```

Potential security issues include:

* authentication bypass,
* authorization bypass,
* unvalidated parameters,
* arbitrary navigation,
* unsafe WebView loading,
* sensitive action invocation,
* token leakage,
* open redirect behavior,
* deep-link hijacking.

A registered URL scheme is an **attack-surface indicator**, not proof of a vulnerability.

---

## ATS / Transport Security Review

Run:

```sh
app-path com.example.app --review
```

The tool checks for indicators such as:

```text
NSAppTransportSecurity
NSAllowsArbitraryLoads
```

Example:

```text
[ SECURITY REVIEW INDICATORS ]

ATS configuration key : FOUND
NSAllowsArbitraryLoads : FOUND - MANUAL REVIEW
```

If an ATS exception is present, further investigation should determine:

* which domains are affected,
* whether HTTP traffic is actually permitted,
* whether sensitive information is transmitted,
* whether TLS validation is correctly implemented,
* whether redirects downgrade transport security.

An ATS exception by itself should not be treated as proof of exploitable insecure communication.

Burp Suite or another authorized interception environment can be used to validate the actual network behavior.

---

## Local Storage Discovery

Applications frequently store information under their Data Container.

`app-path` provides several discovery modes.

### Database files

```sh
app-path com.example.app --db
```

Searches for files such as:

```text
*.db
*.sqlite
*.sqlite3
*.realm
```

Possible investigation targets include:

* access tokens,
* refresh tokens,
* user identifiers,
* account information,
* cached API responses,
* personally identifiable information,
* cryptographic material,
* authentication state.

The presence of a database file is not itself a vulnerability.

The analyst must inspect its contents and protection requirements.

---

## Configuration Files

```sh
app-path com.example.app --config
```

Searches for:

```text
*.plist
*.json
*.xml
```

These files may reveal:

* API endpoints,
* internal hostnames,
* feature flags,
* environment information,
* client configuration,
* identifiers,
* hard-coded secrets or credentials.

Any suspected secret must be validated before reporting.

---

## Saved Application State

```sh
app-path com.example.app --state
```

The command checks:

```text
Library/Saved Application State
```

Application state files can sometimes preserve information displayed by the application.

Review them for unexpected persistence of:

* account information,
* sensitive screen state,
* transaction information,
* authentication-related data,
* private user information.

---

## WebKit Storage

```sh
app-path com.example.app --webkit
```

The tool searches for paths associated with:

```text
WebKit
Cookies
WebsiteData
HTTPStorages
LocalStorage
```

This is especially useful when the application uses:

```text
WKWebView
```

Possible review targets include:

* session cookies,
* access tokens,
* Web storage,
* cached web content,
* persistent authentication state,
* JavaScript bridge-related data.

Static analysis should also search for APIs such as:

```text
WKWebView
WKScriptMessageHandler
addScriptMessageHandler
evaluateJavaScript
```

This can help identify native-to-JavaScript trust boundaries.

---

## Frameworks, Plug-ins, and Extensions

```sh
app-path com.example.app --files
```

The command enumerates embedded components including:

```text
Frameworks/
PlugIns/
Extensions/
```

These components can significantly increase the application's attack surface.

Review embedded components for:

* third-party SDKs,
* WebView frameworks,
* cryptographic libraries,
* authentication SDKs,
* network libraries,
* application extensions,
* IPC mechanisms,
* custom security frameworks.

The discovered binaries can then be analyzed with tools such as IDA or Ghidra.

---

## Quick Security Review

```sh
app-path com.example.app --review
```

This mode provides a quick overview of several security-relevant indicators.

Example:

```text
[ SECURITY REVIEW INDICATORS ]

ATS configuration key       : FOUND
NSAllowsArbitraryLoads      : NOT FOUND
URL scheme configuration    : FOUND
get-task-allow              : false
keychain-access-groups      : FOUND
application-groups          : FOUND
associated-domains          : FOUND
```

The purpose of this output is to determine **where manual analysis should continue**.

---

## Full Collection

```sh
app-path com.example.app --all
```

This combines the major inspection modes and is useful for the initial reconnaissance phase of an assessment.

Depending on the application, the output may include:

* Bundle metadata
* Application paths
* URL schemes
* Embedded components
* Databases
* Configuration files
* Saved Application State
* WebKit storage
* Provisioning information
* Application groups
* Security-review indicators

---

## Recommended Vulnerability Assessment Workflow

A practical workflow is:

```text
             app-path --list
                    |
                    v
                --basic
                    |
          +---------+---------+
          |                   |
          v                   v
     --security            --review
          |                   |
          +---------+---------+
                    |
                    v
        --files / --db / --config
          --state / --webkit
                    |
                    v
              Static Analysis
              IDA / Ghidra
                    |
                    v
             Dynamic Analysis
                  Frida
                    |
                    v
             Network Analysis
               Burp Suite
                    |
                    v
            Manual Validation
                    |
                    v
           Security Finding
```

### Phase 1 — Reconnaissance

```sh
app-path --list
app-path com.example.app --basic
app-path com.example.app --all
```

Establish the application layout and identify interesting components.

### Phase 2 — Configuration review

Inspect:

```text
Info.plist
Provisioning Profile
URL Schemes
Associated Domains
Keychain Groups
Application Groups
ATS
```

### Phase 3 — Storage review

Inspect candidate files discovered through:

```sh
app-path com.example.app --db
app-path com.example.app --config
app-path com.example.app --state
app-path com.example.app --webkit
```

### Phase 4 — Static analysis

Use the discovered executable and frameworks with tools such as:

```text
IDA
Ghidra
```

Trace security-sensitive configuration values to their implementation.

### Phase 5 — Dynamic analysis

Use Frida in an authorized environment to validate runtime behavior.

Examples of useful investigation targets include:

```text
URL handlers
WebView navigation
JavaScript bridges
Keychain access
authentication state
file/database access
certificate validation
cryptographic operations
```

### Phase 6 — Network validation

Use Burp Suite or an equivalent authorized interception proxy to determine whether configuration indicators translate into insecure network behavior.

---

## From Indicator to Finding

`app-path` deliberately separates **discovery** from **vulnerability determination**.

A useful model is:

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

For example:

```text
URL Scheme exists
```

is only an indicator.

However:

```text
External URL
    ->
URL Handler
    ->
Sensitive operation
    ->
No authentication/authorization validation
    ->
Unauthorized action
```

may constitute a valid security finding.

Similarly:

```text
SQLite database exists
```

is not a vulnerability.

But:

```text
SQLite database
    ->
Contains reusable authentication token
    ->
Token stored without appropriate protection
    ->
Token can be reused to access the account
```

provides substantially stronger evidence for a security finding.

---

## What app-path Can Help Investigate

The tool can provide starting evidence for investigation of:

* Insecure Deep Link handling
* URL Scheme attack surface
* Universal Link security
* WebView attack surface
* JavaScript bridge exposure
* Weak ATS / transport configuration
* Debug entitlement exposure
* Excessive entitlements
* Shared Keychain trust boundaries
* Shared Application Group containers
* Sensitive local data storage
* Configuration information leakage
* Application state leakage
* WebKit storage exposure
* Unexpected embedded frameworks
* Extension/plug-in attack surface
* Provisioning/build configuration issues

It does **not** automatically confirm any of these vulnerabilities.

---

## Requirements

The target is a jailbroken iOS device with access to common command-line utilities including:

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

## Limitations

`app-path` is not a complete mobile security scanner.

It does not:

* automatically exploit discovered attack surfaces,
* determine vulnerability severity,
* decrypt protected application data,
* automatically dump Keychain secrets,
* replace reverse engineering,
* replace runtime analysis,
* replace network analysis.

Provisioning parsing is intentionally lightweight, and some uncommon binary plist structures or non-ASCII UTF-16BE strings may require additional analysis.

---

## Documentation

Additional documentation is available under:

```text
docs/
├── ANALYSIS-GUIDE.md
├── ANALYSIS-GUIDE.ko.md
├── FINDINGS-GUIDE.md
└── FINDINGS-GUIDE.ko.md
```

Korean project documentation is also available in:

```text
README.ko.md
```

---

## Authorized Use

`app-path` is intended for legitimate mobile application security research and authorized vulnerability assessments.

Use it only on applications, devices, and environments that you own or are explicitly authorized to test.
