# 분석 가이드

권장 순서는 `--list` → `--basic` → `--security`/`--groups` → `--review` → 저장소 관련 모드 → 필요한 `--plist` 조회 → 정적 분석 → 허가된 범위의 Frida/Burp 검증입니다.

URL Scheme은 인증/인가, Parameter 검증, Redirect, WebView 진입점을 확인합니다. ATS 예외는 실제 HTTP/TLS 동작과 대조합니다. `get-task-allow`, Keychain Access Group, Application Group, Associated Domain은 실제 Trust Boundary와 비교합니다. SQLite/Realm/plist/JSON/XML, Saved Application State, Cookie, Local Storage, WebsiteData, HTTPStorages에서는 민감정보 저장 여부를 확인합니다.

정적 분석에서는 `WKWebView`, `WKScriptMessageHandler`, `evaluateJavaScript`, URL Handler, `SecItemAdd`, `SecItemCopyMatching`, `UserDefaults`, DB Write, Certificate Validation, Crypto, IPC/XPC 관련 코드를 연계해서 확인합니다.

최종 Finding에는 영향 버전/Component, 사전조건, 재현 절차, 기대/실제 동작, 영향, 증거, 개선 방안, 재검증 기준을 기록합니다.
