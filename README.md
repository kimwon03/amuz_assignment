# 프로젝트 버전 및 지원플랫폼
- Dart: >=3.8.1
- TagetPlatform : Android

# 프로젝트 구조
- core
  - common : 모든 feature에서 사용되는 기능들
  - constants : 앱 혹은 feature의 상수 관리
  - routes : 페이지 라우트 관리
- feature
  - connection : 소켓 연결에 관한 기능
  - monitoring : 소켓 실시간 데이터에 관한 기능

# 사용 기술
- Riverpod, HookRiverpod : 상태관리
- GoRouter : 경로관리
- Freezed : 모델 관리
- GetIt : 의존성 관리

# 실행 방법
## 프로젝트 초기화
```
$ flutter pub get
$ flutter pub run build_runner build
```
- `.env.sample`을 이용하여 `.env` 파일 생성
- `core/constants/`에 `keys.dart` 추가
## 프로젝트 실행
```
$ flutter run --dart-define-from-file=.env
```
## 프로젝트 설치
```
$ flutter build apk --dart-define-from-file=.env && flutter install
```