# app-path

탈옥된 iOS 단말에서 앱 Bundle/Data 경로 검색, binary `Info.plist` 파싱, URL Scheme/Provisioning 보안 지표 확인, 저장소 후보 탐색을 수행하는 경량 CLI입니다. `plutil` 없이 `od + AWK`로 동작합니다.

## 설치

```sh
sh install.sh
export PATH="/var/jb/usr/local/bin:$PATH"
```

## 주요 명령

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

출력된 Indicator 자체를 취약점으로 판단하지 말고 Reachability, 보안 통제, 실제 영향을 수동 검증해야 합니다. `docs/ANALYSIS-GUIDE.ko.md`, `docs/FINDINGS-GUIDE.ko.md`를 참고하십시오.

본인이 소유하거나 명시적으로 점검 권한을 받은 앱/단말에 대해서만 사용하십시오.
