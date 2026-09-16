# 취약점 분석 지표 가이드

`app-path`로 Deep Link/URL Handling, WebView Attack Surface, Transport 설정, 과도한 Entitlement, Shared Container, 민감정보 Local Storage, Application State, WebKit Storage, Configuration Leakage, Embedded Component, Debug/Provisioning 관련 증거를 찾을 수 있습니다.

Indicator 하나만으로 취약점이라고 판단하지 않습니다. `Indicator + Reachability + 보안 관련 동작 + 부족한 통제 + 재현 가능한 영향`을 기준으로 검증합니다. Severity 역시 실제 영향과 공격 전제조건을 확인한 뒤 판단해야 합니다.
