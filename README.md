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
