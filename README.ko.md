# app-path

`app-path`는 **탈옥된 iOS 단말에서 모바일 애플리케이션 취약점 점검을 보조하기 위한 경량 CLI 도구**입니다.

Bundle ID를 기준으로 설치된 앱의 Application Bundle 및 Data Container를 찾고, `plutil` 없이 binary `Info.plist`를 분석하며, Provisioning Profile, URL Scheme, Application Group, Keychain Access Group, 로컬 저장소, WebKit 데이터 등 보안 점검에 필요한 정보를 빠르게 수집합니다.

이 도구의 목적은 취약점을 자동으로 판정하는 것이 아니라 **취약점 분석을 시작할 위치와 추가 검증이 필요한 Attack Surface를 빠르게 식별하는 것**입니다.

---

## 주요 기능

`app-path`는 다음 정보를 수집하거나 분석할 수 있습니다.

* 설치된 앱 및 Bundle ID 탐색
* Application Bundle 경로 확인
* Data Container 경로 확인
* binary `Info.plist` 직접 파싱
* 앱 이름 / 버전 / Build / Executable 확인
* URL Scheme 확인
* 임의 `Info.plist` Key 조회
* Provisioning Profile 분석
* `get-task-allow` 확인
* Keychain Access Group 확인
* Application Group 확인
* Associated Domains 확인
* Framework / Plug-in / Extension 탐색
* SQLite / Realm 등 DB 파일 탐색
* plist / JSON / XML 설정 파일 탐색
* Saved Application State 탐색
* WebKit / Cookie / Local Storage 탐색
* 주요 보안 설정 Indicator 출력

---

## 설치

```sh
sh install.sh
export PATH="/var/jb/usr/local/bin:$PATH"
```

기본 설치 위치:

```text
/var/jb/usr/local/bin/app-path
/var/jb/usr/local/libexec/app-path-bplist.awk
```

---

## 앱 기본 정보 확인

```sh
app-path com.example.app --basic
```

예상 출력:

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

이 정보는 이후 정적/동적 분석에서 매우 중요합니다.

특히 다음 경로를 바로 확보할 수 있습니다.

```text
Application Binary
Info.plist
Frameworks
PlugIns
Extensions
Data Container
```

따라서 IDA/Ghidra 분석, Frida Hooking, 파일시스템 분석을 시작하기 위한 기본 정보를 빠르게 확보할 수 있습니다.

---

## 설치된 앱 목록 확인

```sh
app-path --list
```

예상 출력:

```text
[ INSTALLED APPS ]

com.example.app       Example       1.2.3       123
com.example.second    SecondApp     2.0.0       45
```

점검 대상 앱의 정확한 Bundle ID를 모를 때 사용할 수 있습니다.

---

## Binary Info.plist 분석

iOS 앱의 `Info.plist`는 binary plist 형태로 저장되는 경우가 많습니다.

탈옥 단말 환경에서는 다음과 같은 도구가 없을 수 있습니다.

```text
plutil
Python plist library
Ruby
Swift helper
```

`app-path`는 별도의 plist Utility 없이 다음 구조를 이용합니다.

```text
binary Info.plist
        |
        v
       od
        |
        v
   byte sequence
        |
        v
      AWK
        |
        v
binary plist object parsing
```

예:

```sh
app-path com.example.app --plist CFBundleIdentifier
```

출력:

```text
CFBundleIdentifier    com.example.app
```

URL Scheme도 직접 조회할 수 있습니다.

```sh
app-path com.example.app --plist CFBundleURLSchemes
```

---

## URL Scheme / Deep Link 분석

출력 예:

```text
CFBundleURLSchemes    example
```

이는 앱이 다음과 같은 외부 URL 입력을 처리할 가능성이 있음을 의미합니다.

```text
example://...
```

이후 정적 분석에서 다음 Handler를 찾아볼 수 있습니다.

```text
application:openURL:options:
scene:openURLContexts:
openURL
canOpenURL
```

점검 대상:

* 인증 우회
* 인가 우회
* Parameter 검증 미흡
* 임의 페이지 이동
* WebView 임의 URL Loading
* 민감 기능 호출
* Token 유출
* Open Redirect
* Deep Link Hijacking

단, **URL Scheme이 존재한다는 사실만으로 취약점은 아닙니다.**

실제 외부 입력이 보안상 민감한 기능까지 도달하는지 확인해야 합니다.

---

## Provisioning / Security 분석

```sh
app-path com.example.app --security
```

주요 분석 대상:

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

출력 예:

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

이 정보는 앱이 어떤 보안 경계와 공유 자원을 사용하는지 파악하는 데 도움이 됩니다.

---

## get-task-allow

예:

```text
get-task-allow : true
```

`true`인 경우 Debugging 관련 Entitlement가 활성화된 상태일 가능성이 있으므로 추가 검토가 필요합니다.

확인해야 할 사항:

* Development Build인지
* 실제 Production 배포본인지
* Debugging이 의도된 설정인지
* 해당 설정으로 민감 기능이나 데이터가 노출되는지

따라서:

```text
get-task-allow=true
```

만으로 바로 취약점으로 판정하지 않습니다.

---

## Keychain Access Group

예:

```text
[ keychain-access-groups ]

TEAMID.com.example.shared
```

Keychain Access Group은 여러 앱 또는 Component가 동일한 Keychain Namespace를 공유할 수 있음을 의미합니다.

추가로 확인할 항목:

* Access Token
* Refresh Token
* 사용자 Credential
* 암호화 Key
* Session 정보
* 인증 상태

중요한 점은 **어떤 앱이 해당 Group에 접근할 수 있는가**입니다.

의도하지 않은 앱이 민감한 Keychain Item에 접근할 수 있는 경우 실제 보안 문제가 될 수 있습니다.

---

## Application Group

예:

```text
[ application-groups ]

group.com.example.shared
```

Application Group은 앱과 Extension 등이 Shared Container를 사용할 수 있게 합니다.

분석할 항목:

```text
어떤 앱/Extension이 Group을 사용하는가?
        |
        v
Shared Container에는 무엇이 저장되는가?
        |
        v
인증정보가 공유되는가?
        |
        v
다른 Component가 데이터를 변경할 수 있는가?
        |
        v
변경된 데이터를 Main App이 신뢰하는가?
```

이 과정에서 Component 간 Trust Boundary 문제를 발견할 수 있습니다.

---

## Associated Domains / Universal Link

예:

```text
[ associated-domains ]

applinks:example.com
```

이는 Universal Link 관련 Attack Surface가 존재한다는 의미입니다.

추가 분석 대상:

* `apple-app-site-association`
* 허용 URL Path
* 인증 처리
* Parameter 검증
* Redirect
* Universal Link로 호출 가능한 민감 기능

Associated Domain 존재 자체가 취약점은 아닙니다.

---

## ATS / 네트워크 보안 설정

```sh
app-path com.example.app --review
```

출력 예:

```text
[ SECURITY REVIEW INDICATORS ]

ATS configuration key : FOUND
NSAllowsArbitraryLoads : FOUND - MANUAL REVIEW
```

`NSAllowsArbitraryLoads`가 발견되었다면 다음을 확인합니다.

```text
어떤 Domain이 영향을 받는가?
실제로 HTTP 통신이 가능한가?
민감정보가 HTTP로 전송되는가?
TLS 검증이 정상적으로 수행되는가?
Redirect 과정에서 HTTPS -> HTTP Downgrade가 발생하는가?
```

이후 Burp Suite를 이용해 실제 네트워크 동작과 비교할 수 있습니다.

---

## DB 파일 탐색

```sh
app-path com.example.app --db
```

다음 파일을 탐색합니다.

```text
*.db
*.sqlite
*.sqlite3
*.realm
```

DB에서 점검할 수 있는 정보:

* Access Token
* Refresh Token
* 사용자 ID
* 개인정보
* API Response Cache
* 인증 상태
* 암호화 관련 데이터
* 내부 업무 데이터

DB가 존재한다는 것 자체는 취약점이 아닙니다.

DB 내부에 어떤 정보가 있으며 해당 정보에 적절한 보호가 적용되어 있는지 확인해야 합니다.

---

## 설정 파일 탐색

```sh
app-path com.example.app --config
```

탐색 대상:

```text
*.plist
*.json
*.xml
```

분석 대상:

* API Endpoint
* 내부 서버 주소
* Feature Flag
* Development/Production 설정
* Client Identifier
* Hard-coded Secret
* Credential
* Debug 설정

---

## Saved Application State

```sh
app-path com.example.app --state
```

다음 위치를 확인합니다.

```text
Library/Saved Application State
```

앱의 화면 상태가 저장되는 과정에서 예상하지 못한 민감정보가 남아있는지 확인하는 데 사용할 수 있습니다.

예:

* 사용자 정보
* 거래 정보
* 인증 관련 정보
* 민감 화면 State
* 개인정보

---

## WebKit Storage

```sh
app-path com.example.app --webkit
```

다음과 관련된 파일을 탐색합니다.

```text
WebKit
Cookies
WebsiteData
HTTPStorages
LocalStorage
```

`WKWebView`를 사용하는 앱에서 특히 유용합니다.

점검 대상:

* Session Cookie
* Access Token
* Local Storage
* Web Cache
* Persistent Authentication
* JavaScript Bridge 관련 데이터

정적 분석에서는 다음 API를 함께 확인할 수 있습니다.

```text
WKWebView
WKScriptMessageHandler
addScriptMessageHandler
evaluateJavaScript
```

이를 통해 Web ↔ Native 사이의 Trust Boundary를 분석할 수 있습니다.

---

## Framework / Plug-in / Extension

```sh
app-path com.example.app --files
```

앱 내부의 다음 Component를 탐색합니다.

```text
Frameworks/
PlugIns/
Extensions/
```

이를 통해 다음과 같은 추가 Attack Surface를 찾을 수 있습니다.

* Third-party SDK
* 인증 SDK
* WebView Framework
* Network Library
* Crypto Library
* App Extension
* IPC Component
* 보안 Solution

발견한 Binary는 이후 IDA/Ghidra에서 별도로 분석할 수 있습니다.

---

## Security Review

```sh
app-path com.example.app --review
```

예:

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

이 결과의 목적은 취약점을 자동 판정하는 것이 아니라:

```text
"어디를 추가 분석해야 하는가?"
```

를 빠르게 판단하는 것입니다.

---

## 전체 정보 수집

```sh
app-path com.example.app --all
```

주요 분석 모드를 한 번에 실행합니다.

초기 Reconnaissance 단계에서 사용하기 좋습니다.

수집 가능한 정보:

```text
Bundle Metadata
Application Path
Data Container
URL Scheme
Framework / Extension
Database
Configuration
Saved Application State
WebKit Storage
Provisioning Profile
Application Groups
Security Indicators
```

---

# 취약점 점검 Workflow

권장 흐름은 다음과 같습니다.

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
               정적 분석
              IDA / Ghidra
                    |
                    v
               동적 분석
                 Frida
                    |
                    v
              Network 분석
              Burp Suite
                    |
                    v
               실제 검증
                    |
                    v
              취약점 Finding
```

## 1. Reconnaissance

```sh
app-path --list
app-path com.example.app --basic
app-path com.example.app --all
```

앱의 전체 구조와 분석 대상 Component를 파악합니다.

## 2. Configuration 분석

다음을 확인합니다.

```text
Info.plist
Provisioning Profile
URL Scheme
Associated Domains
Keychain Groups
Application Groups
ATS
```

## 3. Storage 분석

```sh
app-path com.example.app --db
app-path com.example.app --config
app-path com.example.app --state
app-path com.example.app --webkit
```

민감정보가 저장될 가능성이 있는 파일을 선별합니다.

## 4. 정적 분석

발견한 Executable 및 Framework를:

```text
IDA
Ghidra
```

등에서 분석합니다.

## 5. 동적 분석

Frida를 이용해 허가된 범위에서 실제 Runtime 동작을 검증합니다.

주요 Hook/Trace 대상:

```text
URL Handler
WKWebView
JavaScript Bridge
Keychain
Authentication
File Access
Database
Certificate Validation
Crypto
```

## 6. Network 분석

Burp Suite를 이용하여 ATS 등의 설정이 실제 통신에서 어떻게 동작하는지 확인합니다.

---

# Indicator와 실제 취약점 구분

`app-path`에서 가장 중요한 개념입니다.

```text
Indicator
    +
Reachability
    +
보안 관련 동작
    +
부족한 보안 통제
    +
재현 가능한 영향
    =
Reportable Finding
```

예를 들어:

```text
URL Scheme 발견
```

만으로는 취약점이 아닙니다.

하지만:

```text
외부 URL
   ↓
URL Handler
   ↓
민감 기능 호출
   ↓
인증/인가 검증 없음
   ↓
비인가 기능 실행 가능
```

이라면 실제 취약점으로 연결될 수 있습니다.

마찬가지로:

```text
SQLite DB 발견
```

자체는 취약점이 아닙니다.

하지만:

```text
SQLite DB
   ↓
재사용 가능한 인증 Token 저장
   ↓
적절한 보호 없이 저장
   ↓
Token 획득
   ↓
다른 환경에서 Account 접근 가능
```

과 같이 실제 영향까지 검증되어야 의미 있는 Finding이 됩니다.

---

# app-path가 점검에 도움을 줄 수 있는 영역

다음 항목에 대한 초기 증거 및 분석 시작점을 찾는 데 사용할 수 있습니다.

* Insecure Deep Link Handling
* URL Scheme Attack Surface
* Universal Link Security
* WebView Attack Surface
* JavaScript Bridge Exposure
* ATS / Transport Security 설정
* Debug Entitlement Exposure
* Excessive Entitlements
* Keychain Shared Access
* Application Group Shared Container
* Sensitive Local Data Storage
* Configuration Information Leakage
* Application State Leakage
* WebKit Storage Exposure
* Embedded Framework Attack Surface
* Extension / Plug-in Attack Surface
* Provisioning / Build Configuration 문제

단, `app-path`의 출력만으로 위 취약점이 존재한다고 판단해서는 안 됩니다.

---

# 요구 사항

탈옥된 iOS 단말에서 다음 명령어를 사용할 수 있어야 합니다.

```text
awk 또는 gawk
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

기본 설치 위치:

```text
/var/jb/usr/local/bin/app-path
/var/jb/usr/local/libexec/app-path-bplist.awk
```

---

# 한계

`app-path`는 완전한 모바일 취약점 Scanner가 아닙니다.

다음 기능은 수행하지 않습니다.

* 취약점 자동 Exploit
* Severity 자동 판정
* 보호된 앱 데이터 자동 복호화
* Keychain Secret 자동 Dump
* Reverse Engineering 대체
* Runtime 분석 대체
* Network 분석 대체

Provisioning Profile 분석은 경량 Triage 목적으로 구현되어 있으며 일부 특수한 binary plist 구조나 비 ASCII UTF-16BE 문자열은 추가 분석이 필요할 수 있습니다.

---

# 추가 문서

```text
docs/
├── ANALYSIS-GUIDE.md
├── ANALYSIS-GUIDE.ko.md
├── FINDINGS-GUIDE.md
└── FINDINGS-GUIDE.ko.md
```

영문 메인 문서:

```text
README.md
```

한글 메인 문서:

```text
README.ko.md
```

---

# 사용 범위

`app-path`는 합법적인 모바일 애플리케이션 보안 연구 및 취약점 점검을 위한 도구입니다.

본인이 소유하거나 명시적인 점검 권한을 받은 애플리케이션, 단말 및 환경에서만 사용하십시오.
