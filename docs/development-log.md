# MotionCue Development Log

이 문서는 MotionCue의 제품, UX, 기술 구조, 연구 설계 및 검증 과정에서 발생한 변경을 시간순으로 보존한다.

## 기록 원칙

- 코드, UI, 통신 구조, 연구 조건 또는 문서 방향이 바뀌면 해당 작업 안에서 즉시 기록한다.
- 이미 기록된 항목은 삭제하지 않는다. 잘못된 결정은 새 항목에서 `대체됨` 또는 `철회됨`으로 표시한다.
- 구현 완료와 아이디어·계획을 구분한다.
- 각 항목에는 변경 이유, 영향 범위, 검증 결과 및 남은 작업을 기록한다.
- 참가자 개인정보, 위치 좌표, 인증키와 같은 민감정보는 기록하지 않는다.

상태 표기:

- `IMPLEMENTED`: 코드나 문서에 반영됨
- `VERIFIED`: 테스트 또는 실제 UI에서 확인됨
- `DECISION`: 제품·연구 방향으로 확정됨
- `PLANNED`: 확정됐지만 아직 구현되지 않음
- `SUPERSEDED`: 이후 결정으로 대체됨

---

## 2026-08-24 — Windows·Mac 공동 개발을 위한 Git 공유 방식 채택

상태: `DECISION`, `IMPLEMENTED`, `VERIFIED`

- Windows와 Mac은 같은 private GitHub repository를 각각 clone한 별도 로컬 working copy로 사용한다. USB·OneDrive·iCloud·Syncthing으로 소스 폴더를 실시간 공유하지 않는다.
- OS별 기능 소유 범위는 Windows의 `src/`·`tests/`, Mac의 `mobile/ios/`이며, `docs/`, protocol, paper와 project metadata는 pull 후 순차적으로 수정한다.
- 이 Windows 작업 폴더에는 기존 Git 이력이 없었으므로 새 로컬 Git repository를 초기화했다. private GitHub remote `https://github.com/jaydenkim197/MotionCue.git`의 `main`에 첫 기준 커밋 `f5dbe0c`를 push했다.
- GitHub가 영남대 이메일의 공개를 차단하므로 이 repository의 Git author email은 `jaydenkim197@users.noreply.github.com`을 사용한다.
- `.gitignore`에 Xcode user data·DerivedData, macOS resource fork/`.DS_Store`, Python cache, QA rendering, temporary PDF/build output을 추가했다. 이미 제외 중인 `.tools`, `bin`, `obj`, artifacts는 계속 원격에 올리지 않는다.
- `.gitattributes`로 공유 텍스트 파일을 LF 줄바꿈으로 고정해 Windows와 macOS에서 줄바꿈만 다른 대규모 diff가 생기지 않게 했다. Office/PDF/이미지/실행 파일은 binary로 취급한다.
- Syncthing으로 작업트리 전체와 독립 `.git` repositories를 함께 자동화하는 안은 채택하지 않았다. 작업트리의 변경과 Git commit/pull/push가 서로 다른 두 컴퓨터에서 경합하면 공통 문서와 Xcode project file에 데이터 보존형 충돌을 과도하게 만들기 때문이다.
- 대신 GitHub-only 2분 주기 Windows autosync를 `tools/git-autosync.ps1`로 추가했다. 이 도구는 dirty tree를 하나의 snapshot으로 커밋하고 fetch/rebase/push하되, merge·rebase·lock·충돌 상태에서는 자동 덮어쓰기 없이 중단하고 `%LOCALAPPDATA%\\MotionCue\\git-autosync.log`에 상태를 남긴다.
- 현재 Windows 사용자 로그인 세션에 `MotionCue Git AutoSync` Scheduled Task를 2분 반복으로 등록했다. 배터리 사용 중에도 실행하도록 설정하며, 이 작업은 로그인한 사용자만 실행한다.
- `docs/cross-platform-git-workflow.md`에 초기 publish, normal handoff 및 금지된 동기화 대상을 기록했다.

영향:

- SensorFrame v1, BLE UUID, 개발 로그 및 iOS/Windows 코드가 하나의 버전 이력으로 관리된다.
- Windows의 실행파일과 로컬 SDK처럼 용량이 큰 생성물은 GitHub repository에서 제외해 clone·검토·충돌 비용을 줄인다.

---

## 2026-08-24 — iPhone-to-Windows BLE 실연동 및 SensorFrame 구독 확인

상태: `VERIFIED`; 차량축·종단간 지연 수치화는 아직 `PLANNED`

실기기 관찰:

- iPhone MotionCue Sensor가 Windows MotionCue에 `MotionCue sensor 70B3C5712705`로 발견됐고, Windows가 SensorFrame notify characteristic을 구독했다.
- Windows Settings 상태는 `Subscribed to SensorFrame notifications`, source `Jayden’s iPhone`, source kind `PhoneImu`, BLE state `Subscribed`, link watchdog `Streaming`으로 표시됐다.
- 수신 샘플 간격은 약 41 ms로 관찰됐으며, v1의 25 Hz(40 ms) 전송 목표와 일치하는 범위다. 협상된 BLE PDU는 527 bytes로 42-byte SensorFrame v1 payload보다 충분히 크다.
- calibration 완료, Automatic 활성, 100% activation confidence, 정상 프레임 수용 상태가 확인됐다. 정지 상태의 raw/filtered longitudinal·lateral 값은 모두 0으로 관찰됐다.

해석과 다음 검증:

- 이 결과는 iPhone Core Motion → iOS BLE Peripheral → Windows scan/connect/subscribe → SensorFrame decoder → PhoneImuEstimator 경로가 실제 기기에서 동작함을 보여준다.
- 사용자가 느낀 반응 지연은 BLE만으로 단정하지 않는다. 25 Hz 전송 주기, iOS motion 처리, Windows UI/renderer scheduling 및 현재 `PhoneImuEstimator`의 0.20 s 저역통과 평활화가 함께 기여할 수 있다.
- 현재 0.20 s 평활화는 step 입력에서 약 200 ms에 63%, 약 600 ms에 95%에 도달하는 설계값이다. Study A 전에는 계수를 효과 파라미터로 해석하거나 임의로 낮추지 않는다.
- 다음 단계는 고정된 휴대폰으로 가속·제동·좌/우회전 축 부호를 확인하고, 이벤트 표식 또는 고속 영상으로 sensor event부터 화면 cue까지의 지연 분포(중앙값·p95), 지터·손실·재연결을 측정하는 것이다.

---

## 2026-08-23 — iPhone MotionCue Sensor MVP 생성

상태: `IMPLEMENTED`; 실기기 BLE 상호운용 검증은 아직 `PLANNED`

변경 파일:

- `mobile/ios/MotionCueSensor/` — SwiftUI iOS 앱, Xcode project 및 XCTest target

구현:

- iPhone의 Core Motion device-motion을 전용 serial queue에서 50 Hz로 수집한다. 표준 거치 방향(화면 위, 상단 전방)에 맞춰 iPhone 축을 차량축 `+X 전방 / +Y 우측 / +Z 아래`로 변환한다.
- 1초(50 sample) 정차 교정, calibration-relative quaternion, 보수적인 급격한 mount-movement 탐지, 교정 실패 시 송신 중지를 구현했다.
- SensorFrame v1의 고정 UUID, 42-byte little-endian layout, fixed-point scaling, saturation flag, CRC-16/CCITT-FALSE를 Swift로 구현했다. GPS, Wi-Fi, 계정, 클라우드 및 센서 영구 저장 경로는 추가하지 않았다.
- CoreBluetooth Peripheral로 MotionCue service, notify SensorFrame characteristic, read-only control compatibility characteristic를 등록하고, 구독 central에만 최신 프레임을 25 Hz로 보낸다. CoreBluetooth flow control 시 오래된 frame을 적재하지 않고 최신 값만 재시도한다.
- SwiftUI 단일 화면에 모션 상태, Bluetooth/advertising 상태, central 수, 교정 상태, 전송률, 마지막 알림 시각 및 비저장 sensor diagnostic을 표시한다.
- `NSMotionUsageDescription`과 `NSBluetoothAlwaysUsageDescription`을 project build setting으로 추가했다.

검증:

- Xcode 26.6에서 iPhone 17 Simulator Debug build와 `build-for-testing`을 `CODE_SIGNING_ALLOWED=NO`로 성공했다. App Intents 미사용 metadata warning만 발생했다.
- SensorFrame deterministic XCTest에 CRC-16/CCITT-FALSE 표준 check value `0x29B1`, known byte layout과 CRC `0x73AC` vector, saturation flag, invalid quaternion rejection을 추가했다. Simulator test execution은 첫 simulator boot의 data migration이 완료되지 않아 보류했다.
- 실제 iPhone은 Mac에 연결되어 있는 것을 확인했다. Mac keychain에는 현재 유효한 code-signing identity가 없으므로 Apple Account team 설정이 선행되어야 한다. 실제 motion permission, BLE advertising, Windows receiver discovery와 axis validation은 검증하지 않았다.

남은 작업:

- Apple Account team으로 physical iPhone에 build/install하고 permission prompt와 sensor update를 확인
- Windows Bluetooth radio를 준비한 뒤 service discovery, subscription, 25 Hz notification, 250 ms neutralization/1 sec disconnect와 차량축 sign을 실측

---

## 2026-08-23 — iPhone 실기기 배포 사전 확인

상태: `VERIFIED`; 설치는 Developer Mode 활성화 대기

- Xcode device discovery에서 연결된 `iPhone 16 Pro (iPhone17,1)`를 확인했다.
- 실제 iPhone destination으로 `xcodebuild`를 실행한 결과, 현재 유일한 차단 원인은 iPhone의 Developer Mode가 비활성화된 상태라는 Xcode 진단이었다.
- iPhone에서 `설정 → 개인정보 보호 및 보안 → 개발자 모드`를 활성화하고 재시동·확인을 마치면 동일 destination으로 앱 설치, 모션 권한, BLE advertising 검증을 계속한다.
- 이 시점에는 아직 iPhone에 MotionCue Sensor 앱이 설치되지 않았으며, Windows BLE 상호운용 결과도 없다.

---

## 2026-08-23 — iPhone 16 Pro 서명 빌드 및 설치

상태: `VERIFIED`; 첫 실행의 개발자 신뢰 승인 대기

- iPhone Developer Mode 활성화 뒤 연결된 iPhone 16 Pro destination으로 Debug device build를 성공했다.
- Personal Team의 Apple Development identity와 자동 생성된 `com.motioncue.sensor` provisioning profile을 사용했으며, 프로젝트 Debug/Release configuration에 해당 development team을 지정했다.
- Xcode 26 Debug preview dylib의 별도 signing 단계가 대기해, 제품 실행과 무관한 `ENABLE_DEBUG_DYLIB`을 Debug configuration에서 끄고 정상 서명 빌드를 완료했다.
- `xcrun devicectl`로 MotionCue Sensor를 iPhone에 설치했다.
- 첫 launch는 `profile has not been explicitly trusted by the user`로 iOS가 거부했다. iPhone의 개발자 앱 신뢰를 승인한 다음 다시 launch하여 motion permission·BLE advertising을 확인한다.

---

## 2026-08-23 — iPhone 실기기 교정 단위 오류 수정

상태: `IMPLEMENTED`; 수정본 실기기 재검증 진행 중

- 첫 실행에서 Motion permission과 Bluetooth advertising은 동작했지만, stationary calibration이 `gravity reading is unreliable`로 실패했다.
- 원인은 Core Motion의 `CMAcceleration` gravity/userAcceleration가 g 단위인데 Swift sender가 이를 SensorFrame v1의 m/s²로 변환하지 않은 것이었다. 정지 gravity 약 `1.0`이 교정기의 `8.0–11.5 m/s²` 유효 범위를 통과하지 못했다.
- `DeviceMotionProvider`에서 gravity와 userAcceleration 모두 `9.80665`를 곱해 차량축 m/s²로 전송하도록 수정했다. rotation rate는 이미 rad/s이므로 변환하지 않는다.
- 수정본을 iPhone 16 Pro에 서명·재설치하고 실행했다. 사용자 확인 결과 `Calibrated, waiting for Windows MotionCue`, Bluetooth ready, advertising on 상태에 도달했다.

---

## 2026-08-22 — 기획서와 Mac 구현 컨텍스트를 현재 구조로 정렬

상태: `IMPLEMENTED`, `DECISION`

- MacBook Air M1은 현재 즉시 사용 가능한 iOS 개발 장비로 갱신했다. 이전의 `2026-08-22부터 사용 가능 예정` 표현은 대체됐다.
- 논문·제품 계획에서 BLE와 로컬 Wi-Fi를 동등한 비교 대상처럼 표현한 항목을 수정했다. v1과 본 논문의 공학 평가는 BLE만 대상으로 하며, Wi-Fi는 BLE 실측 실패 시에만 재개할 보류된 확장이다.
- iPhone 송신 앱의 구현 계약, 권한, 화면 상태, BLE 상태 기계, 검증 기준을 `docs/ios-transmitter-implementation-spec.md`로 새로 분리했다.
- Mac Codex에 전달할 최소 파일, 전체 저장소 전달 기준 및 시작 순서를 `docs/mac-codex-context.md`로 새로 작성했다.
- 현재 기획서의 단일 실제 모션 입력은 GPS가 아닌 휴대폰 IMU이고, 첫 구현 우선순위는 iPhone 16 Pro용 SwiftUI 송신 앱이라는 점을 유지했다.

---

## 2026-08-21 — iPhone 송신 앱 실기기 개발 착수 가능 상태로 갱신

상태: `DECISION`, `PLANNED`

- MacBook Air M1이 3일 후 사용 가능하다는 기존 일정 전제는 대체됐다. 현재 MacBook과 iPhone 16 Pro를 모두 즉시 사용할 수 있다.
- 다음 구현 단계는 iPhone에서 Core Motion으로 기기 운동 데이터를 얻고, CoreBluetooth BLE Peripheral GATT 알림으로 Windows MotionCue에 `SensorFrame`을 송신하는 SwiftUI 앱이다.
- iPhone 센서와 BLE Peripheral 동작은 iOS 시뮬레이터로 대체 검증할 수 없으므로 실제 iPhone에 Xcode로 설치·테스트한다.
- 개발 단계에서만 Mac–iPhone 유선 연결 또는 무선 디버깅 페어링이 필요할 수 있다. 이는 연구 제품의 실행 중 `휴대폰–Windows 무선 연결` 제약과 별개다.
- 앱에는 모션 접근 목적 문자열(`NSMotionUsageDescription`)과 Bluetooth 사용 목적 설명을 추가하고, 연구 데이터는 기기 밖에 저장하지 않는 방향을 유지한다.

남은 작업:

- Mac에 Xcode 최신 안정판 설치·Apple Account 서명·iPhone 개발자 모드 및 신뢰 설정 확인
- 공통 저장소에 iOS SwiftUI 프로젝트 생성
- GATT 광고, 25 Hz 송신, 차량축 교정, 중립화·재연결 및 Windows 실연동 검증

---

## 2026-08-21 — 선박용 USB IMU 후속 연구 방향 추가

상태: `PLANNED`; 현재 승용차·휴대폰 IMU 연구 범위에는 영향 없음

- 해군 함정, 여객선 및 일반 선박에서 스마트폰 앱 없이 사용할 수 있도록 가속도계·자이로스코프가 포함된 USB IMU 동글을 Windows 노트북에 직접 연결하는 방향을 후속 연구로 추가했다.
- 과거의 `USB 케이블 미사용` 결정은 휴대폰과 노트북을 케이블로 연결하지 않는다는 현재 연구의 제약이다. 별도 USB 센서 하드웨어를 사용하는 후속 연구와는 구분한다.
- 선박 운동은 자동차의 전후 가감속·평면 회전뿐 아니라 roll, pitch, yaw, heave, sway, surge의 6자유도와 더 긴 주기의 파랑 운동을 포함하므로 현재 차량용 계수를 그대로 사용하지 않는다.
- 재사용 경계는 `센서별 원시 입력 → 공통 차량/선체 좌표 SensorFrame → MotionState → CuePresentationEngine`으로 유지한다. 후속 구현에서는 `UsbImuSource`와 선체축 교정기만 추가하고 화면 엔진은 공유하는 것을 기본안으로 한다.
- 후보 검증 항목은 USB 센서 샘플링률·timestamp 품질·드리프트·노이즈·Windows 드라이버 호환성·고정 장착·선체 좌표 교정·통신 단절 시 중립화다.
- 군용 함정 적용은 보안·망분리·장비 반입·전자파 적합성·승조원 안전 및 기관 승인 문제가 있으므로, 초기 검증은 민간 선박 또는 모션 플랫폼에서 수행하고 함정 적용은 별도 연구로 분리한다.

---

## 2026-08-20 — Phone IMU 전용 실행 경로로 전환

상태: `DECISION`, `IMPLEMENTED`, `VERIFIED`; 기존 `GPS 보조·폴백 유지` 결정은 `SUPERSEDED`

결정:

- iPhone 16 Pro는 추후 확보 예정이 아니라 현재 즉시 사용 가능한 실기기다.
- 제품과 Study A·Study B에서 GPS/GNSS를 사용하지 않는다. 휴대폰 IMU가 유일한 실제 모션 입력이다.
- iPhone용 BLE 주변기기 앱의 설치·서명에는 Xcode가 필요하므로, MacBook Air M1 사용 전에는 Windows 수신·처리와 가상 `SensorFrame`을 우선 검증한다.
- 현재 단계 완료 기준은 `SensorFrame → 차량축 Phone IMU 추정 → MotionController → 화면 큐`가 가상 입력으로 검증되고, 같은 입력점에 실제 iPhone BLE 알림을 연결할 수 있는 상태다.

제거:

- Windows `Geolocator` 기반 GNSS 수집기
- 좌표·속도·heading 기반 `MotionEstimator`, `GeoMath`, 관련 tuning
- GPS 시나리오 및 GNSS probe 프로젝트
- 좌표·속도·heading 전용 연구 CSV 필드와 테스트
- GNSS 설정 버튼, 상태 문구, 온보딩 설명 및 연구 시작 조건

구현:

- 차량축 `+X` 전후, `+Y` 좌우 가속도를 dead zone, 지수 저역통과, 정규화, saturation으로 처리하는 `PhoneImuEstimator`
- 25 Hz 가상 `SensorFrame`의 전체 데모·가속·제동·좌우회전·중립·1.2초 dropout 시나리오
- Windows BLE 실기기 선택·연결·해제 UI와 `MotionController` 연결
- iPhone CoreBluetooth 주변기기를 찾을 수 있도록 MotionCue service UUID 광고를 4초간 active scan하고 Bluetooth 주소로 직접 연결; 기존 paired-only 정책은 `SUPERSEDED`
- 실기 UI에서 paired-device 보조 조회의 빈 예외가 전체 검색을 중단하는 문제를 발견해 광고 스캔과 paired 조회를 독립 처리하고 한 경로의 실패가 다른 경로를 차단하지 않도록 수정
- 최종 배포본 검색 QA에서 현재 Windows가 BLE 광고 스캔에 `0x800710DF (device not ready)`를 반환함을 확인했다. Bluetooth PnP 어댑터와 `bthserv`는 존재하지만 라디오가 스캔 준비 상태가 아니며, 시스템 설정은 변경하지 않고 앱에 명시적 Bluetooth-on 안내를 추가했다.
- 의미 검증에서 거부된 프레임은 watchdog의 마지막 정상 프레임 시각을 갱신하지 않으며, 단일 CRC 오류는 연결 전체를 영구 Faulted 상태로 만들지 않도록 수정
- 250 ms 미수신 시 즉시 중립화, 1초 미수신 시 연결 끊김 처리
- 60초 연구 프로토콜은 실제 Phone IMU만 허용하고 10초 QA에서만 가상 재생 허용
- 현재 필터·정규화 계수는 Study A 전까지 잠정 공학값이며 효과값으로 해석하지 않음

검증:

- Release 빌드: 경고 0, 오류 0
- 자동 테스트: 23개 통과
- 기존 43개 중 GNSS·좌표 계산 전용 20개 테스트는 해당 코드와 함께 제거됨
- Windows UI 가속 replay: longitudinal raw `0.486`, filtered 약 `0.45`, 화면 큐 이동 확인
- Windows UI dropout replay: 250 ms 이후 `Neutralizing` 및 raw/filtered `0.000 / 0.000`, 1초 이후 `Disconnected` 확인
- .NET 포맷 검사 통과
- self-contained x64 단일 실행 파일: `180,445,850` bytes, SHA-256 `11B034FEE193935A313318AF3C78D4A976F7D3D6E56A368E6D7036B19515D0B9`
- 영문 ICCV 스타일 논문 PDF를 최신 Phone IMU 전용 구현 상태로 다시 생성하고 3페이지 전체 PNG 육안 검사에서 clipping·overlap·깨진 참조가 없음을 확인; PDF SHA-256 `6053FCF4940CA30F0F2F561DF9BAE919776A5126055C2A211D702FA27C9C8EB4`
- 남은 작업: iPhone 송신 앱 구현·서명, Windows Bluetooth radio 준비 후 실기 BLE 측정

---

## 2026-08-19 — SensorFrame·Windows BLE·논문 골격 통합 검증 완료

상태: `VERIFIED`

코드 검증:

- 시스템 `dotnet`에는 SDK가 없어 첫 `dotnet test`가 실행되지 않았다.
- 프로젝트 `global.json`과 동일한 .NET SDK 8.0.424를 사용자 cache `C:/Users/sukhe/.cache/motioncue-dotnet`에 설치하고 명시 경로로 사용했다.
- `dotnet format MotionCue.sln --verify-no-changes --no-restore`: 성공
- Release solution build: 성공, warning 0, error 0
- 전체 단위 테스트: 43 passed, 0 failed, 0 skipped
- 새 테스트 범위: SensorFrame round-trip·CRC·포화·quaternion, sequence gap·duplicate·out-of-order·wraparound, 250 ms neutral·1초 disconnect

논문 검증:

- 공식 ICCV 2025 style 자산과 MotionCue 원고를 분리했다.
- Tectonic 0.17.0을 사용자 cache에 설치하고 SHA-256이 배포 metadata와 일치함을 확인했다.
- 최종 LaTeX·BibTeX build 성공; BibTeX error와 warning 없음
- 최종 PDF: `output/pdf/MotionCue_thesis_draft.pdf`
- PDF page: 3, letter portrait, encrypted/form/JavaScript 없음
- PDF SHA-256: `0B44C5F034053D1648296652B6E1D5CB6258D2CD8A25C81198E4BC78270BB3C5`
- 144 DPI로 세 페이지를 모두 렌더링해 잘림·겹침·깨진 문자·빈 페이지가 없음을 확인했다.
- pdfplumber로 3페이지, 참고문헌 `[1]`부터 `[5]`, 결과 미수집 고지 문구 존재를 확인했다.

현재 구현 경계:

- Windows BLE client는 compile되는 독립 scaffold지만 Settings UI와 `MotionController`에는 아직 연결되지 않았다.
- 모바일 GATT peripheral 앱과 실기기 BLE 연결 검증은 아직 없다.
- PDF의 Study A·B 결과는 결과 미수집으로 명시되어 있으며 효과 수치를 포함하지 않는다.

---

## 2026-08-19 — ICCV형 MotionCue 영문 논문 원고 골격 생성

상태: `IMPLEMENTED`

추가 파일:

- `paper/main.tex`
- `paper/sections/00_abstract.tex`부터 `08_conclusion.tex`
- `paper/references.bib`
- `paper/README.md`
- `paper/vendor/iccv2025/iccv.sty`
- `paper/vendor/iccv2025/ieeenat_fullname.bst`
- `paper/vendor/iccv2025/preamble.tex`

출처 및 경계:

- ICCV 2025 공식 Author Kit에서 style, bibliography style과 preamble만 원본 그대로 보존했다.
- MotionCue 원고 파일은 `paper/main.tex`, `paper/sections`와 `paper/references.bib`로 분리했다.
- 이 원고는 ICCV 투고물이 아니므로 page number를 켜고 저자·소속·지도교수를 표시했다.
- 학회 8쪽 제한, 익명 심사, paper ID와 rebuttal 규칙은 적용하지 않았다.

작성 내용:

- Abstract, Introduction, Related Work, System, Study A, Study B, Results, Discussion과 Conclusion 골격을 영문으로 작성했다.
- 현재 구현된 Windows prototype과 SensorFrame은 현재형으로, 모바일 앱과 실험은 계획 또는 미완료로 구분했다.
- 결과가 없는 Results에는 수치나 효과를 만들어 넣지 않고 미수집 상태를 명시했다.
- 심의 상태는 `TBD`, 필터·gain, 합격 기준, 주행 세부와 기준 센서도 `TBD`로 유지했다.
- 우선 확인된 척도 논문을 BibTeX에 넣고, 전체 저자 목록을 아직 검증하지 않은 두 문헌은 note로 명시했다.

검증 상태:

- 첫 Tectonic build에서 공식 예제에 있던 `iccvblue` 정의 누락으로 3차 TeX pass가 중단됐다.
- vendor style 검색 경로와 공식 색상 정의를 `paper/main.tex`에 추가했다.
- 재빌드로 3쪽 PDF 생성에 성공했다.
- 세 페이지를 144 DPI PNG로 렌더링해 제목, 저자, 2단 본문, 페이지 번호, 수식과 참고문헌을 모두 확인했다.
- 잘림·겹침·깨진 문자·빈 페이지는 없었다.
- 시각 검토에서 참고문헌 back-reference 숫자, 노출된 임시 bibliography note와 빽빽한 혼합모형 수식을 발견했다.
- back-reference를 제거하고, 검증 메모를 BibTeX 주석으로 이동하고, 수식을 두 줄 정렬형으로 수정했다.
- 첫 최종 재빌드에서 BibTeX가 항목 내부 `% TODO` 주석을 잘못된 필드로 처리해 두 문헌을 건너뛴 사실을 build log에서 발견했다.
- 주석을 각 BibTeX 항목 밖으로 이동했다. 수정 후 재빌드와 참고문헌 개수 검증을 다시 수행한다.
- 최종 재빌드와 전 페이지 재검사는 다음 로그 항목에 기록한다.

---

## 2026-08-19 — Windows BLE GATT 수신 클라이언트 골격 구현

상태: `IMPLEMENTED`

변경 파일:

- `src/MotionCue.Windows/Sensors/WindowsBleSensorClient.cs`

구현:

- Windows에 이미 페어링된 BLE 장치 목록을 조회한다.
- 선택한 장치에서 MotionCue 전용 service와 SensorFrame notify characteristic를 uncached 조회한다.
- notify 지원 여부를 검사하고 CCCD에 `Notify`를 기록해 알림을 구독한다.
- 협상된 GATT PDU가 42바이트 SensorFrame과 ATT header를 담을 수 있는지 최대 2초 기다린 후 검사한다.
- 알림 payload를 SensorFrame v1 코덱으로 검증하고 CRC·길이·버전 오류를 별도 이벤트로 보고한다.
- accepted/gap 프레임만 상위 계층으로 전달하고 duplicate·out-of-order 프레임은 큐 입력에서 제외한다.
- 연결 상태, 장치명과 협상 PDU를 진단 상태로 제공한다.
- 연결 종료 시 CCCD 구독, characteristic, service, GATT session과 BLE device 참조를 해제한다.

범위:

- 아직 Settings UI와 `MotionController`에는 연결하지 않았다.
- 모바일 GATT peripheral 앱이 없으므로 실제 무선 연결 검증은 아직 수행할 수 없다.
- Windows에서 OS 페어링 창을 직접 제어하지 않고 사용자가 Windows 설정에서 먼저 페어링하는 초기 정책이다.

근거:

- Microsoft GATT client 절차의 service/characteristic discovery, CCCD 기록과 `ValueChanged` 구독 방식을 따랐다.
- https://learn.microsoft.com/en-us/windows/apps/develop/devices-sensors/gatt-client

검증 상태:

- Windows 프로젝트 빌드와 전체 단위 테스트 결과는 다음 로그 항목에 기록한다.

---

## 2026-08-19 — SensorFrame v1 프로토콜과 무선 안전 감시 구현

상태: `IMPLEMENTED`

변경 파일:

- `src/MotionCue.Core/Sensors/SensorFrame.cs`
- `src/MotionCue.Core/Sensors/SensorFrameCodec.cs`
- `src/MotionCue.Core/Sensors/SensorStreamMonitor.cs`
- `tests/MotionCue.Core.Tests/SensorFrameCodecTests.cs`
- `tests/MotionCue.Core.Tests/SensorStreamMonitorTests.cs`
- `docs/sensorframe-v1.md`

구조 판단:

- 기존 `IMotionSource`와 `MotionEstimator`는 GNSS 좌표를 전제로 하므로 스마트폰 IMU에 더미 좌표를 넣지 않는다.
- 좌표 없는 SensorFrame 코덱과 스트림 감시를 Core의 독립 계층으로 먼저 구현하고, 차량축 IMU 추정기는 다음 단계에서 별도로 연결한다.

프로토콜:

- 42바이트 고정 길이, little-endian, CRC-16/CCITT-FALSE를 사용하는 `SensorFrame v1`을 정의했다.
- 차량 기준축은 `+X 전방 / +Y 우측 / +Z 아래`로 정했다.
- sequence, 단조 경과 시각, 차량축 user acceleration·rotation rate·gravity, 교정 기준 quaternion, 정확도와 상태 플래그를 포함했다.
- 위도·경도·경로·계정·참여자 식별자는 포함하지 않았다.
- BLE service, notify characteristic와 control characteristic UUID를 고정했다.

안전 및 진단:

- 프레임 중복·역순·sequence gap을 구분하고 추정 패킷 손실률을 계산한다.
- `uint32` sequence wraparound를 정상 처리한다.
- 수신 중단 250 ms에 `Neutralizing`, 1초에 `Disconnected`가 되는 watchdog을 구현했다.
- v1에는 플랫폼별 임의 fragmentation을 넣지 않았다. 협상된 GATT payload가 42바이트 미만이면 연결을 실패시키고 중립 상태를 유지한다.

검증 상태:

- 코덱 round-trip, CRC 손상 거부, 포화 플래그, 잘못된 quaternion, sequence gap·중복·역순·wrap, 250 ms/1초 watchdog 단위 테스트를 추가했다.
- 빌드 및 전체 테스트 실행 결과는 다음 로그 항목에 기록한다.

---

## 2026-08-19 — ICCV형 논문 양식과 모바일 OS 기준 확정

상태: `DECISION`, `IMPLEMENTED`

변경 파일:

- `docs/open-decisions.md`
- `docs/research-paper-plan.md`

변경:

- 오래된 학교 기본 양식 대신 ICCV 2025 공식 Author Kit의 영문 LaTeX 2단 스타일을 작업 원형으로 사용하기로 했다.
- 학부논문은 ICCV 투고물이 아니므로 8쪽 제한, 익명 심사 표기와 rebuttal 규칙은 적용하지 않기로 했다.
- 정식 제출에 학교 필수 표지·승인 페이지가 요구될 경우 최종본에 최소한으로 추가하고 본문은 ICCV형으로 유지한다.
- 연구 심의 상태를 현재 `TBD`로 변경했다. 지금은 신청하지 않으며 실제 참여자 모집 전에 적용 절차를 확인한다.
- iPhone 16 Pro는 개발·실험 시점의 최신 안정 iOS를 사용한다. 2026-08-19 공식 최신 안정판은 iOS 26.6 빌드 `23G71`이며 iOS 27 베타는 연구 기기에 사용하지 않는다.
- 국내 Galaxy A50 모델 `SM-A505N`의 마지막 공식 배포인 Android 11, 빌드 `A505NKSS6DWB1`, 2023-02-01 보안 패치를 개발 기준으로 설정했다.

기기 재현성 규칙:

- Galaxy A50은 실제 단말의 모델번호, Android 버전, 빌드번호와 보안 패치 수준을 기록한다.
- iPhone은 각 Study A·B 실행 시점의 iOS 버전과 빌드번호를 기록한다.
- 최신 버전이라는 표현만 결과 논문에 남기지 않고 구체적인 실행 버전을 Methods에 보고한다.

공식 확인 자료:

- Apple 최신 안정 iOS: https://support.apple.com/en-by/100100
- Samsung Galaxy A50 `SM-A505N` 업데이트 이력: https://doc.samsungmobile.com/SM-A505N/007424190621/kor.html
- ICCV 2025 Author Guidelines: https://iccv.thecvf.com/Conferences/2025/AuthorGuidelines

---

## 2026-08-19 — 연구 자원과 기본 실험안 확정

상태: `DECISION`, `IMPLEMENTED`

사용자 제공 정보:

- Android: Samsung Galaxy A50
- iPhone: iPhone 16 Pro
- MacBook Air M1: 2026-08-22부터 사용 가능 예정
- 빌린 승용차 사용 가능
- Study B 표준 센서폰: iPhone 16 Pro
- 지도교수: Professor Chan-Su Lee, Yeungnam University
- 나머지 미정 사항은 문서의 권장 기본안 채택

변경 파일:

- `docs/open-decisions.md`
- `docs/research-paper-plan.md`
- `docs/research-mode.md`

변경:

- Study A에서는 Galaxy A50와 iPhone 16 Pro를 모두 검증하고 Study B에서는 iPhone 16 Pro 한 기종만 사용하도록 확정했다.
- 모바일 앱은 Kotlin·Swift 네이티브 구현, BLE 우선, IMU 50 Hz 수집·25 Hz 송신을 기본안으로 확정했다.
- Study B는 동일 승용차·운전자·노선과 오른쪽 뒷좌석을 기본 통제 환경으로 설정했다. 고정 운전자와 안전 모니터 확보는 남은 확인 사항이다.
- 사례비는 회당 10,000 KRW, 참여자당 3회, 30명 완료 기준 최대 900,000 KRW로 계산했다.
- 대조 조건 명칭을 `Sham Cue`에서 과도한 눈가림 의미를 피한 `Static Visual Control`로 변경했다.
- 이찬수 교수를 지도교수로 연구계획서에 반영했다. 공식 학과 페이지에서 컴퓨터비전·인간 시각 특성 전공을 확인했다.

연구 심의 판단:

- 사용자는 자율 연구이므로 별도 심의가 없을 것으로 예상했다.
- 영남대학교 공식 IRB 안내에는 인간대상연구 승인과 별도의 심의면제 신청 절차가 명시되어 있었다.
- 따라서 `심의 불필요`로 확정하지 않고, 참여자 모집 전 지도교수 또는 담당 부서의 서면 판단을 받는 것으로 기록했다.
- 이 조치는 정식 심의가 반드시 필요하다고 미리 결론낸 것이 아니라 적용 절차를 기관이 판단하게 하는 안전 경계다.

공식 확인 자료:

- https://www.yu.ac.kr/electronics/faculty/lcs.do
- https://www.yu.ac.kr/rnd/community/notice.do?articleNo=185146&attachNo=35931&mode=fileDownload

남은 확인:

- 두 휴대폰의 실제 OS 버전
- 고정 운전자·안전 모니터·거치대
- 학부논문 템플릿·인용 형식·정확한 제출일
- 연구 심의 또는 심의면제 적용 여부에 대한 기관 확인

---

## 2026-08-19 — 미확정 결정 목록과 우선순위 문서화

상태: `IMPLEMENTED`

변경 파일:

- `docs/open-decisions.md`
- `README.md`

변경:

- 구현 전 `P0`, 파일럿 전 `P1`, Study A·논문 전 `P2`로 미확정 사항을 분류했다.
- Android와 iPhone은 Study A에서 모두 검증하되 Study B에서는 한 대의 표준 센서폰을 사용한다는 권장 원칙을 기록했다.
- 초기 구현은 BLE에 집중하고 Wi-Fi와 GPS 보조는 측정 결과에 따라 추가하는 범위 관리 원칙을 기록했다.
- 기술 기본안, 실험 조건, 안전·연구 승인, 사례비, 데이터 관리 및 논문 행정 항목을 포함했다.
- 사용자에게 필요한 기기·차량·예산·학교 정보를 다섯 가지로 정리했다.

영향:

- 미정인 사항을 구현 완료나 확정 결정으로 오인하지 않게 되었다.
- 사용자 답변 전에도 SensorFrame 명세와 Windows BLE 수신기 골격은 기본안으로 진행할 수 있다.

검증:

- 이 항목들은 `권장안` 또는 `미정`이며 새로운 최종 제품 결정을 의미하지 않는다.

---

## 2026-08-19 14:34 KST — 변경 로그 문구 오류 수정

상태: `IMPLEMENTED`, `VERIFIED`

변경:

- 기록 정책 항목의 `단일 누적 로그인`을 `단일 누적 로그 파일인`으로 바로잡았다.
- 제품 기능, 연구 설계 및 앱 동작에는 변화가 없다.

검증:

- 변경 로그와 README의 연결 문구를 다시 검색해 확인했다.
- 대상 Markdown 파일에서 후행 공백과 병합 충돌 표식이 없음을 PowerShell로 확인했다.
- 현재 작업 폴더는 Git 저장소가 아니므로 `git diff --check` 대신 위 검사를 사용했다.

---

## 2026-08-19 14:31 KST — 연구계획서를 무선 스마트폰 센서 구조로 동기화

상태: `IMPLEMENTED`

변경 파일:

- `docs/research-paper-plan.md`
- `docs/research-mode.md`

변경:

- 논문 가제에서 `GNSS-Only`를 제거하고 `Wireless Smartphone-Synchronized`로 변경했다.
- 학부논문 저자, 소속, 언어, 목표 제출 시기, 표본 및 사례비 정보를 추가했다.
- 공학 연구질문을 Android/iPhone 센서 일치도, BLE/Wi-Fi 지연·손실, 연결 실패 안전성 및 GPS 보정 평가로 변경했다.
- 사용자 실험 가설과 조건을 `No Cue / Sham Cue / Synchronized Cue`로 변경했다.
- 목표 표본을 완료 기준 30명으로 설정하고 탐색적 학부 연구의 한계를 명시했다.
- 실제 차량과 대중교통을 하나의 본 실험에서 혼합하지 않고 주 환경과 후속 환경으로 분리하도록 했다.
- Android/iPhone 앱, BLE/Wi-Fi, 교정, 보안, 연구 조건 구현을 추가 개발 체크리스트에 넣었다.
- 현재 앱에는 여전히 `NoCue / Regular / Dynamic`만 구현되어 있다는 사실을 Research Mode 문서에 명시했다.

문서 정확성 조치:

- 아직 구현되지 않은 `Sham Cue / Synchronized Cue`를 현재 사용 가능한 기능처럼 표현하지 않았다.
- 기존 GNSS-only 설계는 삭제된 것이 아니라 본 로그의 대체 이력으로 보존했다.

---

## 2026-08-19 14:26 KST — 전체 변경 과정 기록 정책 도입

상태: `IMPLEMENTED`

사용자 요청:

> 바뀌는 점이 있으면 바로 Markdown에 하나씩 기록하고 전체 과정을 확인할 수 있어야 한다.

변경:

- 단일 누적 로그 파일인 `docs/development-log.md`를 생성했다.
- 이후 모든 구현·설계·연구 변경은 같은 작업에서 이 파일에 추가한다.
- README에서 로그로 바로 이동할 수 있게 연결했다.
- 과거 결정도 아래에 역추적해 기록했다.

영향:

- 앞으로 결정의 근거와 구현 상태를 구분해 추적할 수 있다.
- 이전 내용을 수정해서 덮어쓰기보다 새 기록으로 변경 이력을 보존한다.

---

## 2026-08-19 14:18 KST — 모바일 센서 송신 방식은 설치형 앱으로 확정

상태: `DECISION`, `PLANNED`

변경 전:

- 휴대폰 센서를 웹페이지 또는 앱에서 송신하는 방식을 비교 중이었다.

변경 후:

- Android와 iPhone 모두 설치형 `MotionCue Sensor` 앱을 사용한다.
- 모바일 앱은 센서 수집, 차량축 교정, BLE 연결, 상태 표시 및 긴급 중단을 담당한다.
- 웹은 센서 송신의 본 경로로 사용하지 않는다. 필요하면 설명·진단용 보조 화면에만 사용한다.

이유:

- iPhone Safari는 Web Bluetooth를 지원하지 않는다.
- 웹 모션 이벤트는 보안 컨텍스트, 사용자 권한 및 화면 가시성 제약을 받는다.
- 연구에서는 센서 주기, 축, 권한, 연결 수명과 오류 상태를 더 직접적으로 제어해야 한다.

예정 산출물:

- Android 앱 패키지
- iOS 앱 패키지
- 공통 SensorFrame 프로토콜
- Windows 센서 수신기

아직 구현되지 않음:

- 모바일 프로젝트
- BLE GATT 서비스
- iOS 실기기 빌드·서명

---

## 2026-08-19 14:09 KST — 무선 전송은 BLE 기본, Wi-Fi 보조로 확정

상태: `DECISION`, `PLANNED`

변경 전:

- 동일 로컬 Wi-Fi를 통한 센서 전송을 기본안으로 검토했다.

변경 후:

- 기본 전송: Bluetooth Low Energy(BLE)
- 보조 전송: 동일 로컬 Wi-Fi
- 케이블 연결: 지원 범위에서 제외
- 인터넷·클라우드: 사용하지 않음

이유:

- BLE는 공유기나 핫스팟 설정 없이 차량과 대중교통에서 사용할 수 있다.
- 전송할 센서 프레임은 작은 바이너리 데이터이므로 BLE GATT 알림에 적합하다.
- Wi-Fi는 연구용 고빈도 원시 데이터, 디버깅 및 BLE 호환성 문제의 폴백으로 유지한다.

현재 환경 확인:

- Windows 개발 랩탑에서 `Intel(R) Wireless Bluetooth(R)` 어댑터가 정상 인식됐다.
- 드라이버 버전은 `23.90.0.8`이다.
- 실제 알림 빈도, 지연 및 손실률은 모바일 앱 구현 후 실측해야 한다.

안전 요구사항:

- 센서 패킷이 250 ms 이상 없으면 큐를 중립으로 복귀한다.
- 1초 이상 연결이 끊기면 연결 상실 상태로 전환한다.
- 패킷 번호와 센서 타임스탬프로 손실·지연을 계산한다.
- 일회용 페어링 키와 앱 계층 인증·암호화를 적용한다.

---

## 2026-08-19 13:59 KST — Android와 iPhone 동시 지원 및 무선 전용 요구 확정

상태: `DECISION`

사용자 요구:

- Android와 iPhone이 모두 Windows MotionCue와 호환되어야 한다.
- USB를 포함한 케이블 연결은 사용할 수 없다.

영향:

- Android 전용 프로토타입을 최종 구조로 사용할 수 없다.
- iOS Core Motion과 Android Sensor Framework를 동일한 SensorFrame으로 정규화해야 한다.
- iOS 최종 빌드·서명·실기기 검증에는 M1 MacBook과 Xcode가 필요하다.

---

## 2026-08-19 13:50 KST — GPS는 폐기하지 않고 보조 센서로 역할 변경

상태: `DECISION`; 기존 `GNSS-only 주 입력` 결정은 `SUPERSEDED`

변경 전:

- Windows 랩탑의 Satellite GNSS만으로 가감속과 회전을 추정하는 구조가 핵심이었다.

변경 후:

- 주 입력: 차량에 고정된 스마트폰의 IMU
- 보조 입력: 스마트폰 또는 랩탑의 GPS/GNSS
- GPS 용도: 주행 시작·정지, 속도 확인, 진행 방향 보조, 장기 드리프트 보정 및 비교 평가
- GPS-only 모드: 공학적 비교·폴백용으로만 유지

이유:

- 현재 개발 랩탑은 Satellite GNSS fix를 제공하지 않고 Wi-Fi 위치만 제공했다.
- GNSS 단독 입력은 급제동, 짧은 회전과 고주파 차량 움직임을 충분히 빠르게 포착하기 어렵다.
- IMU는 실제 큐 방향과 타이밍을 만드는 데 필요한 직접적인 가속도·회전율을 제공한다.

프라이버시 경계:

- 위도와 경도는 휴대폰에서 Windows로 전송하지 않는다.
- 필요하면 휴대폰에서 파생한 속도·course·정확도만 전송한다.
- 연구 CSV에도 좌표 필드를 추가하지 않는다.

---

## 2026-08-19 13:43 KST — 정적 점은 치료 조건이 아니라 Sham 조건으로 재정의

상태: `DECISION`, `PLANNED`

핵심 판단:

- 실제 가속도·회전과 동기화되지 않은 점은 차량 운동 정보를 전달하지 못한다.
- 랜덤하거나 잘못된 방향의 움직임은 감각 불일치를 늘릴 가능성이 있다.
- 따라서 점을 단순 표시하는 상태를 효과 조건으로 해석하지 않는다.

사용자 실험의 권장 조건:

1. `No Cue`: 점 없음
2. `Sham Cue`: 정적이거나 실제 운동과 무관한 점
3. `Synchronized Cue`: 스마트폰 IMU와 동기화된 점

영향:

- 기존 `No Cue / Regular / Dynamic`은 현재 앱의 구현·QA 조건으로 남는다.
- 본 사용자 실험에서는 먼저 동기화 정보의 효과를 검증한다.
- `Regular / Dynamic` 시각 패턴 비교는 동기화 효과가 확인된 뒤의 2차 연구로 미룬다.

아직 구현되지 않음:

- Research Mode의 `Sham Cue`와 `Synchronized Cue` 조건
- 스마트폰 센서 입력에 따른 실제 큐 구동

---

## 2026-08-19 13:39 KST — Research Mode MVP 검증 및 배포

상태: `IMPLEMENTED`, `VERIFIED`

구현:

- 익명 참가자 코드와 세션 ID
- `NoCue / Regular / Dynamic` 연구 조건 고정
- FMS 0–20 주기 입력
- 이벤트 마커와 수동 FMS 기록
- 좌표가 구조적으로 없는 CSV
- 세션 중 일반 설정 및 시뮬레이션 변경 차단
- `Ctrl+Shift+F12` 긴급 정지
- 긴급 정지 시 Cue Off 지속

QA에서 발견하고 수정한 문제:

- 10초 QA FMS 팝업이 기존 팝업 위에 반복 생성되는 문제
- 하나의 FMS 팝업만 유지하도록 가드 추가
- 긴급 정지 시 열려 있는 FMS 팝업 닫기
- 설정 로드 중 이벤트가 재귀적으로 저장을 유발하지 않도록 `_loading` 보호

검증:

- Release 빌드: 경고 0, 오류 0
- 자동 테스트: 36개 통과
- 포맷 검증 통과
- 정상 종료 CSV 마지막 레코드: `SessionEnded`
- 긴급 종료 CSV 마지막 레코드: `EmergencyStop`
- CSV 좌표 컬럼: 없음
- 단일 실행 파일 배포 완료

배포 파일:

- `artifacts/MotionCue-win-x64/MotionCue.Windows.exe`

---

## 2026-08-19 13:20 KST — 학부논문 기본 정보 확정

상태: `DECISION`

연구 정보:

- 문서 유형: Undergraduate thesis
- 언어: English
- 저자: Jayden Kim
- 소속: Department of Electronic Engineering, Yeungnam University
- 지도교수: 미정
- 목표 제출 시기: 2026년 말
- 대상: 20대 초중반 남녀
- 목표 표본: 30명 권장
- 사례비: 10,000 KRW로 제시됨; 세션당 지급인지 전체 지급인지 최종 확정 필요
- 초기 환경: 실제 차량과 대중교통
- MacBook Air M1: 후속 비교·확장 연구

연구 범위 조정:

- 하나의 본 실험에서 실제 차량과 대중교통을 혼합하면 환경 차이가 교란될 수 있다.
- 주 연구 환경은 하나로 고정하고 다른 환경은 공학 검증 또는 후속 외적 타당성 연구로 분리하는 것이 권장된다.
- 사람 대상 연구이므로 정식 심의가 없더라도 지도교수 또는 학교 담당 부서에 심의 면제·불필요 여부를 확인해야 한다.

---

## 2026-08-19 이전 — Windows MotionCue 공학 MVP

상태: `IMPLEMENTED`

구현 범위:

- .NET 8 WPF 시스템 트레이 앱
- Windows Geolocator 기반 Satellite GNSS 필터
- Wi-Fi/IP 위치 거부
- 소스 독립형 모션 추정기
- 투명 클릭스루 화면 가장자리 점 오버레이
- Automatic / On / Off 모드
- Regular / Dynamic 패턴과 색상·크기·개수 설정
- 시작프로그램 옵션
- 개발자 시뮬레이션
- GNSS probe 도구와 결정론적 코어 테스트

개발자 기능 열기:

1. Settings를 연다.
2. `Version 0.1.0-dev`를 다섯 번 클릭한다.
3. Developer Mode와 Research Session을 확인한다.
