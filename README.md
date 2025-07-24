# 프로젝트 버전 및 지원플랫폼
- Dart: >=3.8.1
- TagetPlatform : Android

# 프로젝트 구조
- core
  - common : 모든 feature에서 사용되는 기능들
    - models : 공용 모델
    - pages : 공용 페이지
    - services : 공용 서비스
    - utils : 공용 부가 기능
  - constants : 앱 혹은 feature의 상수 관리
  - routes : 페이지 라우트 관리
- feature
  - connection : 소켓 연결에 관한 기능
    - presentaion : 소켓 연결 UI 관련
    - domain : 소켓 연결 기능이 있는 추상 레포지토리
    - data : 추상 레포지토리 구현, Dxi 연결
  - monitoring : 소켓 실시간 데이터에 관한 기능
    - presentaion : 실시간 데이터 UI 관련
    - domain : 실시간 데이터 기능이 있는 추상 레포지토리
    - data : 추상 레포지토리 구현, 실시간 데이터 파싱 및 전달

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
- `Keys.dart` 파일을 `core/constants/` 아래에 추가
## 프로젝트 실행
```
$ flutter run --dart-define-from-file=.env
```
## 프로젝트 설치
```
$ flutter build apk --dart-define-from-file=.env && flutter install
```

# 프로젝트 기능
1. 냉장고와 DXi 프로토콜 소켓 연결
2. 실시간 모니터링 데이터 표시