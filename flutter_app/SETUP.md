# 수익 대시보드 - 설정 가이드

## 1. Google Cloud Console 설정

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. **API 및 서비스 활성화**:
   - AdMob API
   - AdSense Management API
4. **OAuth 2.0 사용자 인증 정보** 생성:
   - 유형: Android 앱
   - 패키지 이름: `com.junyoung.admob_adsense_dashboard`
   - SHA-1 서명 해시 입력

## 2. google-services.json 설치

```bash
# google-services.json 다운로드 후 아래 경로에 복사
cp ~/Downloads/google-services.json android/app/google-services.json
```

## 3. 빌드 및 실행

```bash
cd flutter_app
flutter pub get
flutter run
```

## 4. 연동 API 권한 (OAuth 스코프)

| API | 스코프 |
|-----|------|
| AdMob | `https://www.googleapis.com/auth/admob.readonly` |
| AdSense | `https://www.googleapis.com/auth/adsense.readonly` |

## 5. 주요 기능

- 구글 로그인 (AdMob + AdSense 동시 연동)
- 오늘 / 어제 / 최근 7일 / 이번 달 / 커스텀 기간 필터
- 수익 대시보드 (AdMob + AdSense 합계)
- 앱별 수익 분류
- 광고 단위별 수익 분류
- 계정 정보 (Publisher ID, 통화, 시간대)
- KRW 기준 표시
