# iPhone build 4/5 — 유한 잠금 송신 후보 시험

상태: build 4 background 송신 지속은 확인했으나25 Hz/공백 기준은 실패. **build 5 한 번의5분 이상 USB 없는 잠금 송신 지속/약25 Hz 확인**, 전환 gap/전체 세션/반복/G1은 미완료.

수정: build 4는 잠금/background 송신이 계속됐지만 목표25 Hz에 미달했다. build 5가 후속 후보이며 설치·잠금 재시험 상태는 개발 로그를 확인한다.

2026-10-04 배포 확인: iPhone 0.2.0 (4) Release build/strict signing/설치·정상 launch, Simulator 35/35 및 Core Release 30/30 통과. Start 후 Frames 증가 사용자 확인. 실제 iOS background/Windows 수신 시험은 아래 절차로 별도 검증한다.

23:12 KST 후속 배포: source `e1ac090`의 **0.2.0 (5)** strict signing/설치·기기 inventory/일반 launch를 확인했다. 대기 중인 서명 요청은 없다. Simulator 42/42 통과이며 새 보정·foreground 수신/Start/잠금 rate는 아직 실측 전이다.

23:21 KST 후속 실측: 사용자 USB 분리·60초 잠금/Windows Frames 증가 보고와, iOS background90.259 s/+2250 enqueue/**24.9283 Hz**를 대조했다. Windows 사진6.6595604 s/+165 accepted/**24.7764 Hz**, 양쪽 Streaming이다. 잠금 전환 직후 약300 ms send gap 한 번이 남아 무공백/G1 통과를 뜻하지 않는다. [상세 시험 기록](bench-2026-10-04-ios-build5.md). 다음은 같은 세션5분 잠금이다.

23:24 KST 후속: 같은 continuous background summary가**310.8835 s/+7750 =24.92895 Hz**로 이어졌다. 사용자가5분 Windows Frames 증가를 확인했다. 새 invalid/세션 종료/전환 이후 추가≥250 ms send gap event 없음. 별개의60초/5분 두 trial로 집계하지 않는다. 유한 session 전체/Stop·OS cancellation/반복 및 G1은 여전히 남아 있다.

## build 4 실측과 build 5 후보

- 22:00:16 Start/Running →22:01:18 background. 첫 세션은22:03:11 calibration invalid/세션중단. 고정 실패 종류를 저장하지 않던 build4 로그로는 원인을 확정할 수 없다. 거치 움직임 등 안전 guard를 제거하지 않는다.
- 두 번째22:03:48 Start/Running →22:03:54 background. 22:04:02–22:11:15의 **432.768 s, +3659 enqueue =8.4549 Hz**. 구독1/fresh1/drop·backpressure0은 summary에서 확인됐으나 목표25 Hz는 실패. 사용자는 잠금 중 움직임에 Windows cue 반응을 보고했다. 실제 Windows counters/수신률은 추가 대조가 필요하다.
- 이후 observed Timer gap1.56/1.31/2.32 s 및 foreground/background 재전환이 있어 전체를 정확한5분 하나로 합산하지 않는다. 실행 유지와 안정적인25 Hz는 별도 조건이다.
- build 5는 Main RunLoop Timer로 전송하지 않는다. Core Motion callback/acquisition timestamp에서25 Hz 기회를 생성하고 지연슬롯을 건너뛴다. 100 ms freshness/중복 차단/latest-only pending/거치 안전검사는 그대로다. Timer는1 Hz health/logging만 수행. Diagnostic acceleration display만 foreground10 Hz이며 송신은 별도다.
- build 5 local tick metrics는 **sample-driven 송신 기회**의 간격이며 build3/4 Timer metrics와 의미가 다르다. Calibration invalid category 숫자와 종료 elapsed freeze도 추가. 원시센서/오류문자열 저장 없음.
- Simulator **42/42** 및 실기기 서명/설치·일반 launch 확인. 새 잠금rate는 별도 확인한다. 자동 테스트나 build4 잠금 지속을 build5 실측 통과로 사용하지 않는다.

## 달라진 점

build 3는 BLE 구독을 유지하지만 잠금 중 센서 송신이 멈췄고 foreground 복귀로 자동 복구됐다. build 4는 iOS 26+ `BGContinuedProcessingTask`로 사용자가 시작한 유한 송신 작업을 background에서 계속할 실행 시간을 요청한다. 무기한 실행 보장, 전원 종료 지원 또는 Live Activity만으로 해결하는 방법이 아니다.

- 목표: CoreBluetooth에 실제 enqueue한 fresh frame **45,000개**. 25 Hz에서 약 30분; Windows 수신 ACK는 아님.
- 한도: sleep 포함 **35분**. 완료/Stop/iOS 취소·expiration/연결·보정 상실/5초 progress 없음에 종료; 자동 재시작 없음.
- 동작: foreground 연결·보정 후 **설정(톱니) → Locked session → Start**. `Running`을 확인한 다음 잠근다. `Starting`이나 `Not allowed`는 승인된 세션이 아니다.
- 사용 중 iOS 시스템 진행률/취소 UI가 나타날 수 있다. 새 위치/마이크/GPU/HealthKit 권한은 필요하지 않다. 거절되면 error code와 상태를 그대로 기록한다.
- 종료가 background에서 발생하면 pending을 버리고 foreground 복귀 전 송신을 막는다. Windows의 250 ms neutral/1초 timeout 로직은 변경하지 않았다. foreground 일반 송신은 별도이며 Stop 버튼이 앱 전체 종료를 의미하지 않는다.
- Wire format/UUID/50 Hz acquisition/25 Hz enqueue/Windows 0.20 s smoothing은 변경하지 않았다. Windows EXE 재빌드는 이번 iOS-only 변경에 필요하지 않다.

## 먼저 60초 시험

1. 설치된 최신 후보 확인(후속 **0.2.0 (5)**). 재설치/프로세스 재시작 후에는 정지 거치(화면 위/상단 전방)하고 **Calibrate**를 다시 한다.
2. Windows 기존 구독/수신이 복구됐는지 확인; 복구되지 않을 때만 Scan/Connect. `Subscribed / Streaming`, accepted·missing·rejected·시각·최근 수신 통계를 기록한다.
3. iPhone Details의 Windows 1/Fresh/약25 Hz 확인 → Locked session Start → **Running + session Frames 증가** 확인. 요청 거절 시 잠금 시험을 진행하지 않는다.
4. debugger/console 없이 **USB를 뽑고 측면 버튼으로 잠금**. 정확한 잠금 시각 기록. 전원 종료/앱 강제 종료는 하지 않는다.
5. Windows에서 60초 동안 accepted가 계속 증가하는지, Streaming/cue가 유지되는지 기록. `Subscribed` 하나만으로 통과로 보지 않는다.
6. 해제 후 MotionCue foreground 복귀. Session 상태/Frames·Rate/Fresh 및 Windows 복구/재연결 필요 여부 기록. 원본 iOS 로그를 남기려면 Prepare logs → Mac 재연결 후 collection helper 사용.
7. 통과하면 별도의 **5분 잠금**과 **전체 세션**, **background 시스템 취소/Stop**, **foreground 복귀 후 재시작**을 검증한다. 60초 성공을 무기한/실차/G1 전체 통과로 확대하지 않는다.

## 결과 기록

```text
Date / git revision / iOS version / app build / Windows EXE manifest:
Foreground Start time / Running time / initial queued-session frames:
USB disconnected? / debugger absent? / lock-unlock wall times:
Windows accepted delta / elapsed receipt time / missing-rejected:
Windows Streaming throughout? / first timeout / subscribed? / cue:
iOS session state before-after / frames / expiry-denial error:
iOS background summary timestamps / fresh / queue count-rate:
Stop / OS cancel / reconnect / recovery / stale replay:
Pass / fail / evidence artifact paths:
```

iPhone/Windows 시계 차이는 one-way latency가 아니다. `systemUptime` gap은 sleep 중 wall time과 다를 수 있으며 세션 deadline만 ContinuousClock을 쓴다. 기존 256 KB rolling runtime log를 회수하고 원본은 ignored artifacts에 보관한다. 변경/관찰은 [개발 로그](development-log.md)에 기록한다.

기술 근거: [Apple long-running tasks](https://developer.apple.com/documentation/backgroundtasks/performing-long-running-tasks-on-ios-and-ipados), [Apple DTS motion/background 설명](https://developer.apple.com/forums/thread/841001). OS runtime 보장이나 이 기기 잠금 성공을 문서만으로 주장하지 않는다.
