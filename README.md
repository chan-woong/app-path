# app-path

Dependency-light jailbreak-side iOS application discovery and security-triage CLI. It locates application bundles/data containers, parses binary `Info.plist` files without `plutil`, inspects URL schemes and provisioning indicators, and enumerates storage candidates.

## Install

```sh
sh install.sh
export PATH="/var/jb/usr/local/bin:$PATH"
```

## Usage

```text
app-path --list
app-path com.example.app --basic
app-path com.example.app --security
app-path com.example.app --review
app-path com.example.app --plist CFBundleURLSchemes
app-path com.example.app --files
app-path com.example.app --db
app-path com.example.app --config
app-path com.example.app --state
app-path com.example.app --webkit
app-path com.example.app --groups
app-path com.example.app --all
```

Indicators are not automatically vulnerabilities. Validate reachability, security controls, and impact manually. See `docs/ANALYSIS-GUIDE.md` and `docs/FINDINGS-GUIDE.md`.

Requirements: jailbroken iOS plus `awk`/`gawk`, `od`, `grep`, `find`, `dd`, `head`, `cut`, `tr`, `sort`, and `sed`.

Use only on applications/devices you own or are explicitly authorized to assess.
