# 수익 대시보드 (AdMob & AdSense Dashboard)

애드몹과 애드센스 수익을 한 눈에 확인하는 Flutter 안드로이드 앱

## 실행 전 필수 설정

### 1. Google Cloud Console
- AdMob API 활성화
- AdSense Management API 활성화
- OAuth 2.0 Android 자격증명 생성
  - 패키지: `com.junyoung.admob_adsense_dashboard`
  - SHA-1 서명 해시 입력
- `google-services.json` 다운로드

### 2. google-services.json 설치
```bash
cp ~/Downloads/google-services.json android/app/google-services.json
```

### 3. 빌드
```bash
flutter pub get
flutter run
```

## OAuth 스코프
| API | 스코프 |
|---|---|
| AdMob | `admob.readonly` |
| AdSense | `adsense.readonly` |
