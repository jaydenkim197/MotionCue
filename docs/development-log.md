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
- `PROPOSAL`: 검토 중인 추천안이며 아직 확정되지 않음
- `DECISION`: 제품·연구 방향으로 확정됨
- `PLANNED`: 확정됐지만 아직 구현되지 않음
- `BLOCKED`: 외부 정보·권한·장비 등으로 진행할 수 없음
- `DEFERRED`: 의도적으로 후순위로 이동함
- `SUPERSEDED`: 이후 결정으로 대체됨

---

## 2026-10-04 23:44 KST — Mac build 5 검토 및 Windows 실제 수신 후속 확인

상태: GitHub `18383f6` pull·변경 검토 `VERIFIED`; Windows 약 81초 nominal 25 Hz 수신 `HARDWARE-VERIFIED`; 세션 완료·반복/취소·실제 end-to-end 지연은 미검증.

- 유한 `LockedSensorSession`과 Core Motion sample-driven 25 Hz cadence를 검토했다. 45,000 fresh enqueue 목표/35분 hard limit, 자동 연장 없음, 신선도·보정·구독 guard를 확인했다. Mac 5분/8분 결과는 bench 문서로 검토했으며 ignored iPhone JSONL을 Windows에서 재계산한 것으로 주장하지 않는다. 이전 build 3의 잠금 중단 기록은 보존한다.
- Windows 23:40:23.1559546→23:41:44.5114607, accepted 38368→40396: **81.3555061 s / +2028 = 약 24.9276 Hz**, missing 45→45/rejected 0→0, 양쪽 Ready/Subscribed/Streaming/cue visible. p50/p95 58.1/60.9→58.0/60.7 ms. 누적 max 2435.1 ms는 시작 전부터 있어 원인·발생 시각을 이번 관찰로 단정하지 않는다.
- iPhone 물리 화면·현재 세션 상태는 Windows로 확인 불가하므로 이 81초를 새 잠금 trial/30분 완료로 집계하지 않았다. BLE 수신 간격은 end-to-end latency가 아니며 0.20 s smoothing은 변경하지 않았다. 상세 수치·한계를 `docs/bench-2026-10-04-ios-build5.md`에 추가하고 readiness를 갱신했다.
- EXE SHA256과 기존 manifest는 일치한다. 다만 manifest source `8766ff0`, `WorktreeDirty=true`이므로 clean 최신 commit 빌드라고 주장하지 않는다. 새 Windows 코드 변경은 없고 진행 중 스트림 보존을 위해 재빌드/재실행/재연결하지 않았다. 다음 통제된 trial 전 clean release build가 필요하다.
- 다음 확인: iPhone Frames/elapsed/state와 Mac 종료 로그 대조 → 45,000-frame 완료/35분 한계·Stop/OS 취소 → 새 세션 잠금 반복 → 수신·화면 지연 분리. 앱/프로토콜/필터 코드는 변경하지 않았다.
- 문서만 명시적으로 stage/commit/push한다. 사용자 untracked `MotionQue_theme_standard.zip`과 ignored artifacts는 보존하고 업로드하지 않는다.

---

## 2026-10-04 23:24 KST — build 5 USB 없는 5분 이상 잠금 송신 지속 확인

상태: 한 번의 연속 잠금 구간에서5분 이상 nominal25 Hz 송신 지속 `VERIFIED`; 전체 유한 세션/종료·취소/반복 및 G1 전체 미완료.

- 사용자는5분 시험 완료/Windows Frames 지속 증가를 보고했다. 추가 회수 `artifacts/ios-runtime-20261004-232258-q7y6P9`에서23:17:39 background 이후23:22:56까지 새 active 전환 없음. 60초 trial 뒤 독립적인 두 번째5분 trial로 중복 집계하지 않고 같은 background 구간 연장으로 기록한다. 이 capture에서 정확한 잠금 해제/foreground 복귀 시각은 아직 미확인이다.
- Background summary32개,23:17:45–23:22:56 **310.8835 s**, queued8107→15857(+7750) =**24.92895 Hz**. Summary마다 centrals1/fresh1/screenAwake0, 새 freshness 변화/invalid/세션 종료 없음. 마지막 session Frames12639/elapsed507 s. 최근250 enqueue p50범위40.108–40.136 ms/p9546.744–52.695 ms, 마지막max68.625 ms.
- 전환 직후300.299 ms send gap 외 추가≥250 ms send-opportunity event 없음. 추가drop0/backpressure1(누적1/5). Window-summary/allowlist log는 per-frame 또는Windows 전체 수신 trace가 아니다. Windows5분 종료counter/p95/max 정량 사진은 아직 없으며 지속수신은 사용자 보고로 구분한다.
- 이 기기/한 번의5분 이상 조건은 확인했지만 무기한 잠금 지원·모든OS·실차/G1 전체 통과는 아니다. 후보는 실제45000fresh enqueue 목표(25 Hz 약30분)/35분 hard limit의 user-started 유한 session이며 자동 재시작 없음. 전체 목표/Stop/OS cancel/새 잠금 반복·Windows간격/필터 지연이 남아 있다. 측정 중 앱/Windows/프로토콜 코드는 변경하지 않았다.
- 상세수치/증거/한계/후속은 `docs/bench-2026-10-04-ios-build5.md`에 보완했다. 로그·문서 변경은 완료-sync로GitHub에 전달한다; ignored raw evidence/기기 정보는 제외한다.
- 23:27 KST 추가: 마지막 capture `artifacts/ios-runtime-20261004-232551-HKtzYD`에서background summary49개/23:17:45–23:25:46, **481.2813 s/+11996 =24.92513 Hz**, 구독1/fresh1/추가drop0/backpressure2(마지막summary 누적1/6). 추가invalid/종료/≥250 ms send gap event 없음. 이후inactive→background만 있어 foreground 복귀/실제화면상태를 추정하지 않는다. 마지막 lifecycle의Frames16985/elapsed681 s/누적backpressure10은summary 구간과 구분한다.
- 문서 표현 보완: build5 cadence38 ms 하한은acquisition timestamp 간격이며 실제enqueue wall-time하한은 아니다. 지연callback/전송backpressure 뒤 모든burst가 없다고unit tests만으로 주장하지 않는다. 이번에는측정 중코드를바꾸지 않고5분 이상실측과이한계를spec/bench에 반영했다.

---

## 2026-10-04 23:21 KST — build 5 첫 잠금 송신 지속 확인 및 Windows 사진 대조

상태: user-started 세션/foreground·첫60초 잠금 송신 지속 `VERIFIED`; 5분/전체 세션/전환 gap/G1 전체는 미완료. 앱 코드는 변경하지 않았다.

- 사용자 요청대로 수동 설명 대신 명명된 앱 runtime JSONL을 직접 회수·계산했다. 23:14:28 Requested→Running과 보정을 확인했다. Foreground60.1721 s의 queued3362→4862(+1500)는24.9285 Hz였다. 기기 연결은 초기 wired, 23:19 localNetwork로 확인했고 debugger/console/재설치/재시작 없이 회수했다.
- 사용자는 USB 분리·60초 잠금 시험 완료 및 Windows Frames 지속 증가를 보고했다. 23:17:39 background 이후 summary10개(23:17:45–23:19:15), **90.2590 s의 +2250 enqueue =24.9283 Hz**, 구독1/fresh1/screenAwake0, 새로운 invalid/session 종료 없음. 최근250 interval p50 약40.11 ms/p95 약48–53 ms. 이는 build4의 약8.45 Hz 표본보다 개선됐지만 다른 run의 관찰이며 G1 전체 통과가 아니다.
- 잠금 전환 직후 send-opportunity gap300.299 ms/다음 enqueue window max303.764 ms 한 번이 남았다. 이후90초 summary 구간의 dropped 추가0/backpressure 추가1; 앱 누적은 dropped1/backpressure5로0이 아니다. Windows 수신과 같은 계측점으로 간주하지 않는다.
- Windows 사진 수신시각23:18:03.0380804→23:18:09.6976408, accepted5449→5614(+165)/6.6595604 s =24.7764 Hz. 양쪽 Subscribed/Streaming/cue visible, missing1/rejected0/sequence gap0.02%, p50 약59 ms/p9560.6 ms/누적max240.4 ms. Median 역수 또는 두 기기 timestamp 차이를 one-way latency로 사용하지 않는다. 실행 EXE manifest는 이번 사진만으로 재검증 불가다.
- 추가 회수된 이전build4 로그에서 두 번째 세션도22:16:58에8114frames/elapsed789 s로 sessionInterrupted + calibration invalid 종료가 기록됨을 확인했다. OS expiration/35분 timeout이 아니라 보정 무효가 함께 관찰됐으며, 당시 failure category가 없으므로 상세 원인은 단정하지 않는다. Build5의 category 기록/안전 guard는 유지한다.
- 기존42/42 xcresult를 재확인했다. Mac/fetched GitHub main은76db914로 같고 새 Windows commit은 없었다. 미push Windows 파일/binary 상태는 확인 불가다. 새 시험기록 `docs/bench-2026-10-04-ios-build5.md`와 bench/readiness/개발 로그를 갱신한다. Ignored raw evidence/기기 정보는 Git에 올리지 않는다.
- 다음 물리 조작은 같은 세션에서 USB 없이5분 잠금/Windows 지속 수신 확인만 사용자에게 요청했다. iPhone 로그·counter/rate/오류 대조는 Mac에서 수행한다. 0.20 s smoothing/프로토콜/Windows EXE 변경 없음.

---

## 2026-10-04 23:12 KST — build 5 서명 완료·iPhone 설치/실행 확인

상태: Release 서명/실기기 설치/정상 launch `VERIFIED`; 새 보정·Windows 수신 및 잠금 실측 대기. **잠금 문제 해결 완료/G1 통과 아님**.

- 사용자가 서명 요청창을 열어 달라고 요청했다. 앞선 22:28의 서명 대기 상태와 달리 이번 확인에서는 기존 build job이 exit 0/`BUILD SUCCEEDED`로 종료됐고, `codesign --verify --deep --strict`가 통과했다. 대기 중인 codesign/xcodebuild/SecurityAgent 프로세스가 없었다. 누가 언제 허용했는지는 확인하지 않았으며 완료된 서명을 다시 요구하거나 키체인 암호·보안 설정을 조작하지 않았다.
- source `e1ac090`의 0.2.0/build 5 설치 성공, 기기 app inventory의 **0.2.0 (5)** 및 debugger/console 없는 정상 launch 성공을 확인했다. 현재 추가 서명 허용은 필요하지 않다. 설치/launch 원본은 ignored `artifacts/ios-build5-install.json`, `ios-build5-app-inventory.json`, `ios-build5-launch.json`에 보관한다.
- 새 설치 전에 MotionCue의 명명된 runtime 파일 2개를 `artifacts/ios-runtime-20261004-230749-q7lWyU`에 추가 회수했다. 기기 로그를 삭제하지 않았고, raw 로그·기기 식별 정보가 포함된 artifacts는 Git에 올리지 않는다. 이번 회수를 build 5 잠금 시험 결과로 사용하지 않는다.
- 시작 시 Mac/GitHub main은 `e1ac090`으로 동일하고 worktree clean이었다. 이번에는 코드/Windows EXE/프로토콜/필터 변경 없이 배포 상태 문서만 갱신한다. 기존 Simulator 42/42 결과는 유지하되 실제 잠금 rate 검증을 대체하지 않는다.
- 다음 물리 단계: 정지 거치 후 Calibrate → Windows 실제 수신 → Details의 Locked session Start/Running 및 Frames 증가 → USB 없는 60초 잠금. 먼저 Start/foreground 상태를 확인한 뒤 잠금 시험을 진행한다. 재설치/프로세스 재시작 후 이전 보정을 유지한 것으로 간주하지 않는다.

---

## 2026-10-04 22:21 KST — build 4 잠금 중 실행 지속/감속 확인 및 build 5 sample-driven 송신 후보

상태: build 4 실제 background 실행 지속·rate 감속 `VERIFIED`; build 5 변경 `IMPLEMENTED`, 자동 검증/배포/잠금 재시험 진행 중. **해결 완료/G1 통과 아님**.

- 사용자 Start 후 Frames 증가 및 잠긴 iPhone 움직임에 따른 Windows cue 반응을 보고했다. USB 분리/60초→5분 확인을 요청했고 이후 `done` 응답을 받았다. 검사 도중 앱 재설치/재시작/debugger/console attach는 하지 않았다. 기존 CoreDevice localNetwork 연결로 **명명된 MotionCue runtime 파일 2개만** 읽어 회수했으며 이는 앱의 BLE 전송 경로를 Wi-Fi로 바꾼 것이 아니다.
- build 4 source `82e29bf`, 22:00:16 sessionRequested→sessionRunning, 22:01:18 background. 22:03:11 sessionInterrupted(2463 frames)와 calibration invalid가 동시에 기록됐다. 현 build 4 schema에는 invalid 원인 종류가 없어 **타이밍 때문이라고 확정할 수 없다**. 앞선 대화의 원인 단정은 철회한다. 가능한 고정 실패 사유는 sensor normalization/거치 움직임이며 안전 guard를 없애지 않는다.
- 22:03:48 두 번째 Start/Running, 22:03:54 background. `artifacts/ios-runtime-20261004-221114-GAAVdm`의 22:04:02–22:11:15 summary 44개, **432.768 s**에 queued **6179→9838 (+3659) = 8.4549 Hz**. Summary마다 centrals 1/fresh 1/drop·backpressure 0. 22:11:15 최근 window enqueue p50/p95 **135.49/180.90 ms**, send-timer p50/p95 **135.78/180.93 ms**였다. Sample-at-queue는 이 window에서 최대 약25.63 ms. 실행·fresh motion/BLE enqueue는 계속됐으나 nominal25 Hz/G1은 실패다. Windows 수신 counter/rate와 별개다.
- 추가 회수 `artifacts/ios-runtime-20261004-222110-tP48Y0`에서 22:12:46 약1.56 s, 22:12:52 약1.31 s, 22:16:34 약2.32 s의 observed Timer gap 및 후반 freshness 변동을 확인했다. 중간 foreground 복귀/추가 background 구간도 있어 전체를 한 번의 정확한5분 trial로 합산하지 않는다. iOS runtime grant만으로 지연·연속성을 보장한다고 주장하지 않는다.
- 후보 build 5: Main RunLoop Timer는 1 Hz health/summary/no-progress watchdog만 맡기고, **실제 50 Hz Core Motion callback의 acquisition timestamp**로25 Hz 송신 기회를 정한다. 2 ms sample jitter tolerance, 최소38 ms 송신 spacing, stale/duplicate/future/unreliable rejection, 지연 슬롯 skip/no catch-up burst 및 session reset을 적용했다. 기존100 ms freshness gate와 latest-only BLE pending validation은 유지한다. Core Motion OperationQueue는 userInitiated이며 diagnostic acceleration UI만 foreground10 Hz로 줄인다. 백그라운드25 Hz 복구는 아직 실측 전 가설이다.
- 거치/보정 guard는 유지하고 invalid의 고정 category 숫자(1 sensor/2 stationary/3 gravity/4 mount/5 calibration timing/6 possible mount movement)를 allowlist log에 추가했다. 오류 문자열/원시 센서값은 저장하지 않는다. 종료된 background session의 elapsed metric이 계속 증가하던 문제도 종료 시점에 freeze했다. Timer tick 필드는 build 5부터 sample-driven send-opportunity 간격이므로 이전build Timer 통계와 구분한다.
- 코드 추가에 따른 Xcode source/test refs와 버전을0.2.0 (5)로 갱신한다. Protocol/UUID/Windows 코드/0.20 s smoothing은 그대로다. 검증: cadence50→25/jitter/no-burst/stale/clock reset5개, 종료 elapsed freeze1개, 거치 guard/category1개를 기존35개에 추가했다. 결과/설치와 후속 잠금 시험은 아래에 보완한다.
- 22:28 KST 후속: 최신 source의 Simulator **42/42**, 실패/skip/runtime warning0을 xcresult에서 확인했다. `git diff --check`/plist lint 통과. Device Release compile을 마쳤지만 codesign/SecurityAgent가 사용자 키체인 허용을 기다리며 artifact는 아직 unsigned였다. 설치 앱을build5라고 표시하지 않고 사용자에게 직접 서명 허용과 iPhone 잠금 해제를 요청했다. 이전 잠금 trial원본은 새 설치 전에 모두 회수했다. Helper는 raw artifacts를 Git에 올리지 않으며 source/spec/bench/readiness/README/로그를 동기화한다.

---

## 2026-10-04 21:48 KST — 잠금 중 센서 송신 중단 원인 확인 및 유한 background 세션 후보 구현

상태: 원인 대조 `VERIFIED`; iOS background 세션 후보 `IMPLEMENTED`; 빌드/자동 테스트/실기기 잠금 검증 진행 중

- 사용자 요청으로 GitHub `095bd6b`, `baeb53f`의 Windows bench 기록을 fast-forward pull했다. 기존 자동 복구는 확인됐으므로 BLE 재연결을 원인으로 오진하지 않는다. 화면 잠금/USB 분리 시험이며 휴대폰 전원 종료가 아니다. 전원이 꺼진 iPhone은 센서/BLE 송신 불가다.
- MotionCue 앱의 기존 bounded runtime log만 회수했다: ignored `artifacts/ios-runtime-20261004-214011-4ICH7k/runtime.jsonl`. 21:15:45 background 이후 queued 52510→52514까지만, 다음 기록은 21:34:31 runtimeGap/fresh 0→1, 21:34:32 active/centrals 1이었다. iPhone enqueue 수와 Windows accepted는 서로 다른 카운터다. `systemUptime` gap 약 203.9 s는 wall-clock 약 18분 46초와 다르므로 screen-off 기간 또는 recovery latency로 사용하지 않는다. 깊은 sleep을 포함하는 duration에는 별도 ContinuousClock을 사용한다.
- Apple DTS는 Core Motion 자체가 앱에 background 실행 시간을 주지 않으며, 앱이 실행 중이면 motion delivery는 가능하다고 설명한다. 위치를 쓰지 않는 앱에 location background mode를 추가하는 방식을 채택하지 않는다. [Apple DTS 설명](https://developer.apple.com/forums/thread/841001).
- iOS 26+ `BGContinuedProcessingTask`의 user-started finite job/실제 progress/cancel/expiration 경로를 후보로 추가했다. 이는 **무기한 잠금 송신 보장 또는 실측 통과가 아니다**. 45,000 fresh frames의 실제 CoreBluetooth enqueue가 목표(25 Hz에서 약 30분), sleep을 포함한 hard limit 35분이며 연결/보정 상실·5초 이상 progress 없음·사용자 Stop·OS expiration 시 종료한다. 작업은 foreground Start 탭으로만 시작한다. 자동 재시작/작업 체이닝/시간만으로 가짜 진행률을 표시하지 않는다.
- Details → Locked session에 Start/Stop/상태/실제 frame progress를 배치했다. 기본 화면의 짧은 hint 외에 큰 설명/카드를 추가하지 않았다. 시스템 progress UI는 BackgroundTasks가 제공하며 Live Activity만으로 센서 실행을 보장한다고 주장하지 않는다. `processing` background mode 및 task identifier prefix만 추가; audio/location/HealthKit/GPU entitlement 및 raw IMU 저장은 없다.
- iOS 27 비동기 submission을 off-main에서 호출하며 26 fallback을 유지한다. 동적 exact handler, 중복 Start/늦은 callback/종료 뒤 progress 방지, 10초 launch timeout 및 종료 시 pending frame 삭제를 포함했다. background 작업 종료 후 foreground 복귀 전까지 추가 송신을 차단하고 기존 Windows stale/watchdog가 neutral/timeout 처리하도록 한다. 센서 frame v1, nominal 50→25 Hz, Windows 코드/0.20 s smoothing은 그대로다.
- 근거: [Apple long-running task 문서](https://developer.apple.com/documentation/backgroundtasks/performing-long-running-tasks-on-ios-and-ipados), [BGContinuedProcessingTask](https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtask), [WWDC25](https://developer.apple.com/videos/play/wwdc2025/227/), 설치된 iOS 27 SDK BackgroundTasks headers. 문서는 일반 background CPU/sensor analysis와 종료 조건을 설명하며 locked CoreMotion/BLE의 이 장비 25 Hz 보장은 하지 않는다. 실제 무디버거·USB 분리·60초/5분 잠금 시험이 필요하다.
- 검증 중 발견한 project Debug/Release 설정 누락을 복구하고 iOS 0.2.0/build 4로 갱신했다. SDK Swift API error-domain 명칭을 수정했으며 Objective-C request는 foreground에서 구성한 뒤 worker에 단일 handoff한다. Start 때 기존 pending/callback generation을 reset해 이전 프레임을 새 세션 progress로 세지 않는다. 새 coordinator 테스트 12개는 explicit start/중복/실제 enqueue progress/성공·중단/continuous deadline/no-progress/launch timeout/늦은 callback/오류·unsupported/throttling을 다룬다. 실제 iOS scheduler/BLE/잠금 성공을 fake scheduler 테스트로 대체하지 않는다.
- 21:57–22:00 KST 후속 검증: iOS Simulator **35/35**(기존 23 + 새 12) 및 .NET Core Release **30/30** 통과. 기기 Release build/strict codesign 검증 성공, iPhone inventory **0.2.0 (4)** 설치 및 debugger/console 없는 정상 launch를 확인했다. AppIntents 미사용 metadata-skip warning만 있으며 Swift compile 오류 없음. `git diff --check`/plist lint 통과. 메인 screenshot에서 Connected/Calibrated/약25 Hz, 앱 로그에서 fresh/구독1을 확인했다. 원본은 ignored `artifacts/ios-build4-*`, `artifacts/ios-test-locked-session`, `artifacts/ios-runtime-20261004-220009-MEpsF1`에 보관한다.
- 사용자가 Locked session Start 이후 Frames 증가를 보고했다. 정확한 running/background 여부는 로그 대조 전이며, USB 분리·60초 잠금 중 Windows accepted 지속 증가와 해제 후 iPhone 기록을 요청했다. 5분/전체 세션/시스템 cancel/G1은 미검증이다. 절차를 `docs/bench-ios-build4-lock-session.md`, spec/readiness/README에 반영했다. Windows 소스/EXE는 바꾸지 않았으며 이번 iOS-only 배포 때문에 EXE 재빌드할 필요는 없다.

---

## 2026-10-04 21:34–21:36 KST — iPhone 잠금 해제 후 기존 BLE 구독의 자동 복구 확인

상태: foreground 자동 복구 `VERIFIED`; 잠금 연속 송신/정확한 복구 latency/G1 전체 미검증

- 사용자 `해제됨` 확인 후 Windows screenshot의 `SensorFrame stream restored`, Diagnostics의 `Ready / Subscribed / Streaming` 및 cue visible을 확인했다. accepted **54194→54868** 증가를 관찰했다. Windows Scan/Connect/Calibrate, 앱 재실행 또는 연결 초기화 없이 복구됐다.
- Windows 누적 max **1125403.4 ms (약 18분 45.4초)**는 사용자가 화면을 보지 않아 해제 응답이 늦어진 시험 중단 구간이다. 사용자 설명을 반영해 이를 unlock recovery latency나 일반 BLE 지연으로 해석하지 않는다. 정확한 60초 lock trial도 아니다.
- 실제 수신 timestamp 21:35:14.1255161→21:36:27.1406626 KST **73.015초**에 accepted **55275→57100 (+1825)**, 평균 **24.9949 Hz**, missing/rejected **0/0**, 종료 p50/p95 **58.1/60.6 ms**를 확인했다. 가려진 창의 접근성 cache 지연을 피하기 위해 조회 시각 대신 진단의 Windows receipt timestamp로 처리량을 계산했다.
- 복구 직후 긴 공백을 포함한 recent window의 jitter SD **29047.1 ms**는 새 interval로 window가 교체된 뒤 **27.8 ms**가 됐다. 누적 max와 recent-window 통계를 구분한다. Windows smoothing 0.20 s 및 protocol은 변경하지 않았다.
- bench 보고서와 준비 상태를 갱신했다. Mac 후속은 build 3 runtime JSONL의 21:15~21:36 KST lifecycle/runtimeGap/summary 대조이며, unlock→최초 송신 시간은 iPhone 로그 추가 확인 전 미측정이다. 원본 로그는 ignored artifacts에만 보존한다.

---

## 2026-10-04 21:15–21:17 KST — Windows 실제 25 Hz 수신 및 iPhone build 3 잠금 중단 관찰

상태: foreground throughput/잠금 중단 `VERIFIED`; 잠금 해제 복구 확인 진행 중, G1 미완료

- GitHub `16487ba`까지 Mac 4개 commit을 pull해 iPhone build 3 local runtime logging/common-mode Timer 및 약 25 Hz enqueue 검증 기록을 반영했다. `e76845b..16487ba`에서 Windows `src/`, `tests/`, release helper 변경이 없음을 확인해 현재 EXE/구독을 유지했다.
- 사용자 foreground/보정/USB 분리 준비 확인 후 기존 Windows BLE 구독에서 `Ready/Streaming`으로 자동 복귀했다. 수동 Disconnect/Connect는 사용하지 않았다.
- 21:14:33.681–21:15:20.982 KST, **47.301초**에 accepted **52395→53577 (+1182)**로 실제 평균 수신률 **24.9889 Hz**를 확인했다. Missing/rejected **0/0**, sender sample interval **40 ms**, p50/p95 **58.2/61.1 ms**였다.
- 따라서 약 58 ms median의 역수로 수신률 약 17 Hz 또는 BLE 지연을 결론낼 수 없다. 전체 처리량은 25 Hz에 해당한다. 불균등/묶음 전달은 후보 설명이며 개별 간격 분포/OS trace 없이 확정하지 않는다. Mac enqueue 표본은 다른 시각이라 동시 송수신 비교도 아직 아니다.
- 사용자 잠금 확인 뒤 21:16:31.670–21:17:53.731 KST **82.061초** 동안 유지 후 해제를 안내했다. 목표 60초를 넘긴 시험이다. 전면 screenshot과 진단에서 BLE `Subscribed` 유지, accepted **54194**로 정지, source/watchdog `Disconnected`, timeout 및 cue invisible/zero offset을 관찰했다. 정확한 잠금 직후 250 ms/1 s transition 시간은 측정하지 않았다.
- Windows 창이 가려질 때 accessibility 결과에 이전 상태가 남아 screenshot을 전면 확인한 뒤 text를 다시 읽었다. 잠금 시작 시의 오래된 `Ready` text를 잠금 연속 송신 증거로 사용하지 않는다.
- 잠금 해제·MotionCue foreground 복귀 뒤 Scan/Connect/Calibrate 없이 자동 복구를 확인하도록 사용자에게 안내했고 결과는 확인 대기다. 장시간/5분 잠금/10회 재연결/G1 전체 통과로 표시하지 않는다.
- 장비·EXE hash·시각별 통계·해석·남은 시험을 `docs/bench-2026-10-04-windows-build3.md`에 정리했다. Filter, wire format, 구현 코드 또는 기존 gate 수치를 변경하지 않았다.

---

## 2026-10-04 20:33 KST — build 3 보정 후 25 Hz 실제 enqueue 확인

상태: iPhone 보정/foreground enqueue 진단 `VERIFIED`; 동시 Windows 수신 비교·G1 장시간/잠금 bench 미완료

- 사용자가 Rate 약 **25 Hz**, Frames 약 **1500**이며 계속 증가한다고 보고했다. 실행 중 앱을 재시작·재설치하지 않고 MotionCue의 bounded runtime log만 회수했다. 증거는 ignored `artifacts/ios-runtime-20261004-203008-hgymZm/runtime.jsonl`에 보존한다.
- 기기 로그에서 20:28:47 KST collecting → **20:28:48 calibrated**를 확인했다. 20:28:51–20:30:01의 summary 8개(약 **70.20초**)에서 queued **60 → 1813**(+1753), enqueue rate **24.99–25.13 Hz**, Windows centrals **1**, Fresh/화면 유지 모두 **1**을 확인했다.
- 최근 250 간격의 summary별 CoreBluetooth enqueue p50은 **39.59–40.02 ms**, p95 **40.77–49.21 ms**였고, 해당 window max의 최대는 **135.39 ms**였다. Summary 시점의 sample age at enqueue는 **9.17–21.48 ms**, 누적 backpressure/pending drop은 모두 **0**이었다. 이 수치는 snapshot/window 통계이며 전체 프레임의 최소/최대 sample age나 Windows 수신 성공을 뜻하지 않는다.
- 따라서 이번 짧은 foreground 표본에서 iPhone의 nominal 25 Hz 생성/enqueue 경로는 정상이다. 이전 Windows 수신 p50 약 58 ms와는 **다른 실행 시점**이므로 새 build가 Windows 간격을 개선했다거나 Bluetooth/Windows 지연 원인을 확정하지 않는다. 사용자에게 같은 현재 실행의 Windows p50/p95 및 accepted/missing/rejected screenshot을 요청했다. Windows callback source는 UI thread에 synchronous Invoke가 아니라 Post하므로 코드만으로 UI blocking을 58 ms의 원인이라고 단정하지 않는다.
- 보정 **전** 20:28:26 background → 20:28:41 active 사이 약 **14.39초 observed Timer gap**과 복귀 직후 stale sample age 약 **1738 ms**/Fresh 0 → 1을 확인했다. 해당 구간 queued 0이었고 USB 상태/화면 잠금 여부가 통제되지 않았으므로 잠금 송신/구독 유지 bench 통과로 사용하지 않는다. 정확한 suspension 원인도 로그만으로 확정하지 않는다.
- 시작 Mac/fetched GitHub main은 `112f0c5`로 같고 clean/ahead-behind 0/0이었다. 코드·filter·wire format·설치 앱 변경 없이 검증 로그/준비 상태만 갱신했다. 0.20 s smoothing은 유지한다.

다음 순서: 동시 Windows reception 비교 → 정상 foreground 지속/스크롤 → USB 없이 60초·5분 잠금 및 해제 후 복구 → G1 30분/10회 재연결. 이번 약 70초 표본을 30분 또는 실차 검증으로 확대 해석하지 않는다.

---

## 2026-10-04 20:17 KST — iPhone build 3 최신 소스 설치·실기기 runtime 로그 회수

상태: 최신 Release 서명/설치/정상 실행/기기 로그 `VERIFIED`; 새 보정 후 실제 송신 및 G1 잠금·장시간 bench 대기

- 사용자 진행 요청 후 이전 서명 job의 성공을 확인했다. 기기 잠금 해제와 최신 재빌드의 키체인 요청을 사용자에게 직접 처리하도록 요청했고, source **`212ae50`**로 Release를 다시 빌드해 `BUILD SUCCEEDED` 및 strict codesign 검증 성공을 확인했다. 이전 대기 산출물을 최종 source로 설치하지 않았다.
- 기존 앱 위로 설치하고 기기 inventory의 **0.2.0/build 3**, debugger/console attach 없는 일반 launch 성공을 확인했다. 실제 screenshot은 **Calibration needed / Ready**, Calibrate 활성화였으며 재시작 뒤 보정을 유지한 것으로 가장하지 않는다.
- MotionCue app container의 runtime.jsonl 생성과 `tools/collect-ios-runtime-logs.sh` 실기기 회수를 확인했다. 첫 rotation 전 runtime-previous.jsonl 부재는 정상이다. 로그는 ignored `artifacts/ios-runtime-20261004-201635-cKU8XW/`에 보존한다. 기기 전체/타 앱 로그를 수집하지 않고 원본 기기 식별 정보 포함 install/process JSON도 Git에 올리지 않는다.
- 실제 launch/lifecycle/motion/BLE/summary record를 확인했다. Windows 구독 **1개**, Bluetooth powered/advertising, sensor **Fresh**가 관찰됐다. 미보정 상태의 queued/rate는 **0/0**으로 유지돼 연결을 송신 성공으로 해석하지 않는다.
- foreground 약 50초의 10초 요약 5개에서 최근 250 tick 간격 p50 약 **40.00 ms**, p95 약 **40.53–40.91 ms**를 관찰했다. 해당 표본의 max는 약 **45.81 ms**, sample age는 약 **5.92–18.03 ms**였다. 이는 iPhone application Timer/fresh sample 검증이며 Windows 수신 간격 58 ms 개선이나 motion-to-display 지연 검증이 아니다.
- 현 provisioning 만료는 여전히 **2026-10-11 17:40 KST**다. 재서명/설치는 이후 필요하며 App Store 배포가 아니다. 인증서/키체인 보안 설정/기존 앱 데이터를 삭제하지 않았다.
- 작업 시작 Mac/fetched GitHub main은 `212ae50`으로 같았고 worktree clean/ahead-behind 0/0이었다. Windows 신규 remote commit은 없었다. iOS source와 배포 검증 문서 외 Windows EXE/filter/wire format 변경은 없다.

사용자에게 정지 screen-up 거치 후 Calibrate와 foreground 유지를 요청했다. 이 조작 뒤 enqueue rate/간격/sample age/backpressure를 Windows live reception과 비교한다. 60초·5분 USB 없는 잠금, 30분 foreground, 10회 재연결 및 실차 축/지연 시험은 아직 완료가 아니다.

---

## 2026-10-04 18:57 KST — Windows 변경 반영 및 iPhone runtime 진단/common-mode 송신 보완

상태: 코드/문서 `IMPLEMENTED`; iOS 자동 테스트 `VERIFIED`; 최신 실기기 서명·설치 및 잠금 재현 대기

- 사용자가 전달한 Windows 결과를 확인하고 clean Mac main을 `e76845b`까지 fast-forward했다. Windows header 제거와 최신 실제 수신 기록 3개 commit을 보존했다. Windows 관찰 p50 약 58 ms는 수신 간격이지 end-to-end 지연이 아니며, 임시 G1 gate 35–50 ms는 아직 충족하지 않는다. 0.20 s cue filter 및 SensorFrame v1은 변경하지 않는다.
- iPhone 앱 container의 Library에 기존 영속 runtime 진단 디렉터리가 없음을 확인했다. 이전 background 중단의 정확한 시각/원인은 회수 가능한 앱 로그가 없어 확정하지 않았다. 다른 앱/기기 전체 로그를 수집하지 않는다.
- iOS **0.2.0 / build 3**에 local runtime JSONL을 추가했다. launch/build, 실제 초기 scene phase와 전환, motion availability, calibration, BLE 상태/중앙 수, sample freshness 변화, ≥250 ms observed timer gap, 10초 요약을 기록한다. Windows live reception과 iPhone CoreBluetooth enqueue를 구분한다.
- 요약은 Timer/실제 enqueue의 최근 250 간격 p50/p95/max, sample age, enqueue rate/count, pending drop, updateValue backpressure를 포함한다. 최대 128 KiB 파일 2개/대기 log record 64개; utility queue 비동기 I/O와 finite numeric allowlist를 사용한다. 원시 IMU/위치/기기·central·참가자 ID/session UUID/오류 문자열을 저장·전송하지 않고 device backup에서 제외한다. Disk/queue/OS suspension 시 로그가 불완전할 수 있으며, 멈춘 동안에는 기록 불가하고 복귀 뒤 gap을 관찰한다.
- Details에 짧은 enqueue 간격/backpressure 진단과 Local logs → Prepare logs → Share logs를 추가했다. Main은 그대로 유지한다. Export는 이전/현재 파일의 snapshot이며 자동 upload는 없다.
- 25 Hz Timer를 main RunLoop common mode에 등록해 Details scrolling/tracking 중 default-mode Timer가 멈출 수 있는 경로를 보완했다. tick마다 추가 MainActor Task를 enqueue하지 않는다. 이는 프로세스 suspension/잠금 연속 송신 보장이 아니다. 송신 통계 정렬은 1초마다 갱신해 per-frame 비용을 줄인다.
- Apple의 현재 CoreBluetooth 설명과 engineer 답변을 재확인했다. iOS 26+ Live Activity Bluetooth privileges를 locked/screen-off Core Motion 지속 실행 보장으로 해석하지 않는다. Live Activity/무음 audio/location 권한/반복 background-task 우회는 추가하지 않았다. [CoreBluetooth](https://developer.apple.com/documentation/corebluetooth), [Apple engineer screen-off 설명](https://developer.apple.com/forums/thread/815189).
- iOS Simulator 자동 검증: 기존 15 + runtime 진단 8 = **23/23 통과**. tracking-mode Timer 실행, monotonic/중복/역행 clock, bounded interval/file rotation, finite privacy schema, async export flush 포함. 최신 후속 수정도 재빌드/회귀 확인한 뒤 배포 결과를 아래에 보완한다.
- Mac에서 최신 Windows-compatible Core source로 Release tests **30/30 통과**를 재확인했다. `tools/collect-ios-runtime-logs.sh`를 추가해 지정한 paired device의 MotionCue 진단 파일 2개만 읽어 unique ignored artifacts folder로 회수한다. iPhone 파일을 수정하거나 debugger를 연결하지 않는다. Helper 실기기 검증은 build 3 설치 뒤 수행한다.
- 실기기 Release compile을 마쳤으나 codesign/SecurityAgent가 키체인 허용 응답을 기다린다. 사용자에게 직접 허용을 요청했으며 보안을 우회하지 않는다. 현재 iPhone의 build 2를 build 3 설치 성공으로 표시하지 않는다.
- 19:02 KST 후속 상태: backpressure 중에도 1초 간격으로 상태를 publish하도록 보완하고, 초기 scene phase 및 진단 UI까지 포함한 최종 source로 Simulator tests를 다시 실행해 **23/23 통과**를 확인했다. Collection helper의 `bash -n`/인자 누락 usage guard를 확인했다. 기기 inventory는 여전히 **0.2.0/build 2**이고 codesign 허용 대기다. 허용 뒤 최신 source를 다시 Release build해 설치해야 하며, 대기 중인 이전 build 산출물을 최종 source로 간주하지 않는다.

잔여 물리 작업: 서명 허용 → 최신 source 재빌드/설치·앱 로그 회수 → 정지 거치/재보정·Windows 재연결 → foreground/Details scrolling 및 60초·5분 잠금 복귀 비교. 잠금 연속 송신·58 ms 개선·G1 통과는 아직 미검증이다.

---

## 2026-10-04 — 0.2.0 실제 수신 확인 및 Windows Settings header 제거

상태: 실제 수신/UI 변경/Release build `VERIFIED`; 장시간/잠금 bench 미완료

- 사용자가 작동과 약간의 지연, iPhone background 중단을 보고했다. Windows live Diagnostics에서 BLE `Subscribed`, watchdog `Streaming`, accepted/missing/rejected **2397/0/0**, sequence gap **0.00%**, sensor sample interval **40 ms**를 직접 확인했다.
- 최근 1500 수신 간격의 p50/p95 **59.0/60.6 ms**, 누적 max **5856.2 ms**, window jitter SD **108.0 ms**를 관찰했다. 간격은 one-way 또는 motion-to-display latency가 아니며, 최대 공백의 원인은 이 snapshot만으로 잠금·background로 확정할 수 없다. Sequence gap 0%도 시간 공백이 없다는 뜻은 아니다.
- iOS code는 background 전환 시 motion을 직접 stop하지 않지만 main Timer와 MainActor를 통해 송신한다. `bluetooth-peripheral`은 구성되어 있으나 앱 suspension 중 지속적인 센서 수집/25 Hz 송신을 보장하지 않는다. 현 단계 임시 사용 방법은 iOS Details의 `Keep screen on`과 foreground 유지이며, background의 정확한 중단 시점·복귀는 별도 재현이 필요하다.
- Windows local app-data에는 settings와 Git sync log만 있었으며 상시 BLE diagnostic file은 없다. 현재 BLE 통계는 메모리의 live panel이고 Research CSV는 세션 시작 시 별도 생성된다. Windows에서는 iPhone Console/device log에 직접 접근하지 못한다.
- 사용자 screenshot 요청에 따라 Windows Settings의 `M` tile, 큰 MotionCue 제목, tagline 및 중복 header-status pill을 제거했다. 첫 연결/current-status 카드가 26 px top padding 뒤 바로 시작한다. native window title·EXE/tray icon은 유지한다.
- 공통 design system에 Windows header 없는 layout 규칙을 반영했다. iOS UI와 BLE/IMU/filter parameter는 이번 변경 범위에서 수정하지 않았다.
- Windows Release helper를 다시 실행해 tests **30/30 통과**와 publish 성공을 확인했다. 갱신 EXE를 재실행해 screenshot과 accessibility tree에서 상단 브랜드/중복 status가 사라지고 첫 카드가 위로 이동한 것을 검수했다. 재시작으로 기존 BLE 구독과 메모리 통계는 초기화된다.
- 재실행 뒤 Scan/Connect로 `Subscribed`와 watchdog `Streaming`을 다시 확인했다. accepted **529**, missing/rejected **0/0**, p50/p95 **58.0/60.9 ms**, max **179.6 ms**를 관찰했다. 빠르게 변하는 state에서 `Phone IMU acceleration is unreliable`도 관찰되어 실제 움직임의 신뢰성·거치 검증은 아직 남아 있다.

---

## 2026-10-04 — Windows 0.2.0 재빌드 및 iPhone BLE 구독 확인

상태: Release/test/앱 실행/BLE 구독 `VERIFIED`; 센서 수신 및 G1 bench 미검증

- GitHub `main`을 fast-forward pull해 Mac의 4개 신규 commit과 source `c66c9b8`을 반영했다. 사용자 로컬 `MotionQue_theme_standard.zip`은 보존하고 업로드하지 않았다.
- Windows에서 `tools/build-windows-release.ps1`을 실제 실행했다. Core Release tests **30/30 통과**, win-x64 self-contained single-file publish 성공을 확인했다.
- build manifest: version `0.2.0`, source revision `c66c9b899eb1f2349a7b22529b516206f02f524b`, BuiltAtUtc `2026-10-04T09:34:11.2646965Z`, SHA256 `09C253CDCD5FF5CA07FA878CFABAF0BEDF4258629BFB8E66E2D607F056769C72`. `WorktreeDirty=true`는 빌드 당시 유일한 미추적 디자인 ZIP 때문이며 tracked source 변경은 없었다. `RuntimeValidated=false`를 유지한다.
- 새 `artifacts/MotionCue-win-x64/MotionCue.Windows.exe --settings`를 실행하고 UI의 `MotionCue 0.2.0 · pilot`을 확인했다. Scan에서 센서 1개를 발견했고 Connect 후 `Subscribed to SensorFrame notifications`, `BLE state: Subscribed`, PDU `527 bytes`를 확인했다.
- 초기 Diagnostics에서 accepted/missing/rejected **0/0/0**, timing window **0**, watchdog `Disconnected`, `SensorFrame stream timed out`를 관찰했다. BLE 구독 성공과 실제 센서 프레임 수신 성공은 구분한다.
- 사용자에게 iPhone 앱 foreground 유지, 화면 위 정지 거치 후 Calibrate 및 Details의 Windows 수/Sample Fresh/약 25 Hz/Frames 증가 확인을 요청했다. 해당 물리 조작과 연속 수신이 확인되기 전 잠금·재연결 bench 통과로 표시하지 않는다.

---

## 2026-10-04 18:23 KST — 개발자 신뢰 후 iPhone 0.2.0 정상 실행 확인

상태: 실기기 앱 실행/UI `VERIFIED`; Windows 수신·보정·G1 bench는 미검증

- 사용자가 개발자 신뢰 설정 완료를 알린 뒤 기기 잠금 상태와 설치 앱을 확인했다. iPhone의 설치 버전은 **0.2.0 / build 2**이며, 일반 launch(debugger/console attach 없음)가 성공했다. 앞선 Untrusted Developer 실행 차단은 해소됐다.
- 실제 앱 screenshot에서 새 waveform + dot 아이콘, 단일 connection/calibration card, Details gear와 한 줄 label을 확인했다. 기본 화면은 **Ready to connect / Calibration Ready**이며 Calibrate 버튼이 활성화돼 있었다. 해당 UI 상태는 Bluetooth powered/advertising 및 센서 사용 가능/fresh sample 조건을 반영한다. 정확한 센서 값·전송률·Windows 수신 성공을 screenshot만으로 검증했다고 표시하지 않는다.
- 앱을 삭제하거나 인증서를 재생성하지 않았다. 코드/통신 형식/연구 조건 변경 없이 배포 검증 결과와 준비 문서만 갱신했다. 실기기 증거는 ignored `artifacts/ios-launch-trusted-20261004.json`, `artifacts/ios-device-trusted-0.2.0.png`에 보존하며 원본 기기 식별 정보는 Git에 넣지 않는다.
- 작업 시작 시 fetched GitHub main과 Mac HEAD는 `82b8016`으로 같고 ahead/behind는 **0/0**, worktree는 clean이었다. 새 Windows remote commit은 없었다. Windows의 미push 파일/실행 중 EXE는 원격 확인하지 못했으며, source pull 뒤 Windows release helper로 재빌드해야 한다.
- 다음 사용자 물리 작업: 화면을 위로 놓고 정지 상태에서 Calibrate → 최신 Windows EXE에서 Scan/Connect → Subscribed 및 iPhone Details의 Windows 1/Fresh/약 25 Hz/Frames 증가 확인. 이후 30분 foreground와 잠금·끊김·재연결 bench를 순서대로 기록한다. 현재는 G1/실차/참가자 시험 통과가 아니다.

---

## 2026-10-04 18:17 KST — 최신 iOS Release 서명·설치 완료, 개발자 신뢰 확인 필요

상태: 빌드/서명/설치 `VERIFIED`; 실기기 실행은 사용자 신뢰 확인 대기

- 사용자 진행 요청 후 이전 codesign job 성공을 확인했다. 최종 RGB/no-alpha 아이콘까지 포함한 source `ed9dd81`을 다시 Release build했고 `BUILD SUCCEEDED` 및 `codesign --verify --deep --strict` 성공을 확인했다.
- 연결된 iPhone 16 Pro/iOS 27.0.1에 `com.motioncue.sensor`를 기존 앱 위로 설치했다. 기기 app inventory에서 **0.2.0 / build 2**를 확인했다. 앱/인증서/프로필을 삭제하거나 인증 보안을 완화하지 않았다.
- 정상 launch(debugger/console attach 없음)를 시도했지만 CoreDevice security 오류로 실패했다. 실제 iPhone screenshot에 **Untrusted Developer**가 표시되어, 기기 설정의 개발자 신뢰 확인이 남아 있음을 확인했다. 설치 성공을 앱 실행/센서/BLE 검증 성공으로 해석하지 않는다.
- 앱 서명과 provisioning entitlement의 application/team identifier가 일치하고 Developer Mode가 Enabled임을 확인했다. 프로파일의 유효기간은 **2026-10-11 17:40 KST**다. 이후 시험에는 Mac에서 재서명/재설치가 필요하다.
- 사용자에게 설정 → 일반 → VPN 및 기기 관리에서 MotionCueSensor가 표시된 개발자를 직접 확인·신뢰하도록 요청했다. 암호 입력/프로필 신뢰를 자동 수행하거나 우회하지 않았다. [Apple developer trust 안내](https://help.apple.com/xcode/mac/current/en.lproj/dev96a12fb84.html)
- 새 코드/연구 조건/통신 형식 변경 없음. 시작 시 Mac/fetched GitHub main은 `ed9dd81`로 같았고 Windows 신규 remote commit은 없었다. Windows의 미push 로컬 파일과 실제 EXE 상태는 여전히 미확인이다.
- 설치·launch JSON과 screenshot은 ignored `artifacts/`에 보존했다. 계정/기기 식별 정보가 포함된 원본 증거는 Git에 넣지 않는다.

남은 순서: 개발자 신뢰 확인 → 앱 실행/보정/센서 확인 → 최신 Windows EXE의 Subscribed 확인 → G1 foreground/잠금/끊김·재연결 bench. 현재 실차 시작 조건을 충족했다고 표시하지 않는다.

---

## 2026-10-04 — 시험 전 안정성 보강 및 waveform 브랜드 적용

상태: 방향 `DECISION`, 코드/문서 `IMPLEMENTED`; 자동 검증 `VERIFIED`; 실기기 설치와 Windows 물리 bench는 별도

- 사용자가 좌상단 waveform + dot 레퍼런스를 선택했다. 독자 SVG 원본과 iOS PNG, Windows 다중 크기 ICO를 생성하는 스크립트를 추가했다. SF Symbols glyph를 제품 아이콘으로 복제하지 않았다.
- iOS 기본 화면의 최소 정보/한 줄 label 원칙을 유지하고, Calibration 상세·오류·진단·화면 유지 옵션을 Details로 분리했다. 연결 자체를 송신 성공으로 표시하지 않도록 구분한다.
- 실제 Core Motion 취득 timestamp 기반 100 ms freshness gate와 중복 sample 거부를 추가했다. BLE flow-control 캐시는 1개만 유지하며 오래된 프레임 및 이미 enqueue한 프레임을 재송신하지 않는다.
- BLE 복구 시 service/characteristic/subscriber 상태를 복원하고, process 종료 후 calibration은 새로 요구한다. Bluetooth off/reset 때 구독자·캐시를 초기화한다. Background 지원은 연속 송신 보장을 뜻하지 않는다.
- 송신 진단은 encode 횟수가 아니라 CoreBluetooth enqueue 성공 기준으로 변경했다. Windows 수신 acknowledgment는 아니며, Windows reception 확인은 별도 실측한다.
- Windows hidden Diagnostics에 bounded 수신 간격 통계를 추가했다(p50/p95/max/jitter SD, accepted/missing/rejected, sequence gap 비율). 최근 1500 간격만 보관하며 좌표·raw IMU를 추가 저장하지 않는다. Sequence gap은 송신측 drop도 포함하고, 수신 간격을 one-way latency로 표현하지 않는다. 기존 0.20 s cue filter는 유지한다.
- 보정 시 중복·간격 단절·회전 중 sample과 nonfinite 값을 거부한다. 평균 gravity가 +Z에서 20° 이내인 화면 위 거치를 요구한다(전방 yaw는 물리 정렬 필요). Windows의 cue filter/연구 조건/SensorFrame v1 wire format은 변경하지 않는다.
- Mac/Windows completion-sync helper가 오래된 `REBASE_HEAD`를 활성 rebase로 오인하는 문제를 수정했다. 실제 rebase 디렉터리와 merge/cherry-pick/revert/index lock 보호는 유지한다.
- 시작 시 Mac HEAD와 origin/main은 `ebbbe7f`로 동일했다. GitHub의 최신 Windows 기록은 2026-09-04였으며, Windows 미push 작업 및 기존 배포 EXE는 Mac에서 확인되지 않았다.
- Xcode 27.0/macOS 26.6.2/iPhone iOS 27.0.1 환경으로 갱신되어 있었다. 새 환경에서 build/test/install을 다시 검증한다.
- 실차 전 목표는 기존 `NoCue / StaticVisualControl / SynchronizedCue`의 연구용 안정성이다. AI/CV는 후속 제안으로 보류한다. 기술 bench → 연구자 engineering pilot → 심의/동의/프로토콜 고정 후 참가자 시험으로 구분한다.
- iOS/Windows 버전을 0.2.0 pilot으로 구분했다. Windows version label은 assembly version을 사용한다. `tools/build-windows-release.ps1`은 core tests/publish/source revision/SHA256 manifest를 제공한다. 기존 EXE는 Git pull로 자동 갱신되지 않는다.
- 새 `docs/pre-field-test-readiness.md`에 G0–G3, 30분 foreground/60초·5분 잠금/10회 재연결/임시 수신 간격·gap 기준, Windows handoff와 측정 template을 기록했다. 연구 계획의 오래된 iPhone 미구현·실BLE 미검증 체크리스트를 갱신했다.

검증:

- iOS Simulator 27.0: encoder 4 + safety 11 = **15 tests 통과**. 새 freshness/중복/expiry/정지·회전·gravity·거치/stream invalid 검증 포함.
- Microsoft 공식 installer로 ignored `.tools/dotnet8-mac`에 .NET SDK 8.0.425를 추가했다. global SDK/Windows local SDK를 변경하지 않았다.
- Core Release: 기존 24 + timing 6 = **30 tests 통과**.
- Windows Release cross-build: **경고 0/오류 0**, win-x64 self-contained single-file publish 성공. PE32+ x64 EXE와 embedded icon 준비. 실제 Windows 실행/새 BLE stats/tray 및 PowerShell helper 실행은 미검증.
- Mac completion-sync local bare fixture: stale REBASE_HEAD 허용, active rebase/merge/cherry-pick/revert/index lock/non-main pause, 비충돌 divergent commit rebase/push 등 **9개 시나리오 통과**. Fixtures는 ignored artifacts에 보존했다.
- iOS는 Xcode의 AppIntents dependency가 없는 metadata skip 안내만 발생했다. 앱 코드 compile 오류는 없으며, 실기기 코드 서명은 키체인 허용 단계에서 대기해 사용자 직접 조작을 요청했다. 설치 성공으로 간주하지 않는다.
- iOS 27 Simulator 앱 실행과 실제 screenshot에서 waveform header/compact 단일 card/한 줄 label을 시각 확인했다. Simulator의 Bluetooth unavailable 상태이며 실BLE 통과 증거가 아니다. Screenshot: ignored `artifacts/ios-main-0.2.0.png`.
- 대기 중 코드 보완으로 초기 서명 job만 중단한 뒤 최신 소스로 다시 Release build를 시작했다. 최신 job도 codesign 키체인 접근 단계 대기이며 사용자 허용 전 기존 iPhone 설치 앱을 덮어쓰지 않았다.
- 기존 인증서/provisioning/USB backup/사용자 파일은 삭제하지 않았다. 인증·암호 정보를 저장하지 않았다.
- 최종 PNG 검수에서 iOS AppIcon/BrandMark의 alpha channel도 제거하도록 renderer를 보완했다(Windows ICO/preview의 투명 모서리는 유지). Windows published PE resource tree에서 icon/group-icon 포함을 확인했다.
- 최종 iOS Release Simulator unsigned build 성공 및 AppIcon 1024×1024/RGB/no-alpha 검증 통과. 실기기 codesign sample은 SecurityServer signature 요청의 응답 대기를 확인했다. 인증서 재생성/키체인 보안 완화/암호 자동 입력을 시도하지 않았다.

물리 잔여 작업: 키체인 허용 및 최신 iPhone 설치/실행 확인, Windows pull·재빌드·revision 확인, G1 bench, 실제 거치·축·지연 및 연구 절차 확정. 2026-08-24 연동 성공은 0.2.0 조합 검증 결과가 아니다.

---

## 2026-09-05 — SF Symbols 아이콘 디자인 환경 및 MotionCue 아이콘 레퍼런스

상태: `IMPLEMENTED`; 최종 아이콘 선택은 `PLANNED`

- Apple Software 서명이 검증된 SF Symbols 8 패키지를 Mac 개발 환경에 설치했다. iOS UI의 SF Symbol 탐색·비교·내보내기에 사용한다.
- MotionCue의 iPhone 앱과 Windows 프로그램에서 공통으로 사용할 수 있는 독자적 아이콘 방향 4가지를 레퍼런스 시트로 생성했다. 외부 아이콘 asset을 제품에 포함하지 않았으며, 최종 아이콘은 선택된 방향을 바탕으로 별도 제작한다.
- 후보는 white waveform, gyroscope, phone/radio wave, edge-dot motion path다. 앱의 핵심이 차량 관리가 아니라 스마트폰 IMU 기반 motion cue임을 반영해 차량 실루엣보다 waveform 또는 motion path를 우선 후보로 둔다.

---

## 2026-09-04 — 재사용 가능한 개발 문서화 스킬북 정리

상태: `IMPLEMENTED`

- MotionCue에서 사용한 development log, open decision register, architecture/data contract, verification matrix, release runbook, 디자인·연구 문서, Git completion-sync 규칙을 일반 프로젝트에 재사용할 수 있는 markdown 스킬북으로 정리했다.
- 스킬북은 기록 대상과 제외 대상, 통일된 상태 언어, 작업 시작·종료 루틴, 문서별 책임, 복사 가능한 template, 연구/AI 데이터 경계, 여러 컴퓨터의 Git 운영, Codex material-change completion protocol 및 최소 도입안을 포함한다.
- 기존 로그에서 실제로 사용하던 `PROPOSAL`, `BLOCKED`, `DEFERRED` 상태를 상태 표기에 추가해 문서와 운영 언어의 불일치를 해소했다.
- README에서 새 스킬북을 연결했다.

문서:

- `docs/reusable-development-documentation-skillbook.md`

---

## 2026-09-03 — AI/CV 개발 후보 평가 및 1~2학기 실행안 문서화

상태: `PROPOSAL`, 문서 `IMPLEMENTED`

- GPT 대화에서 제안된 gaze, 개인화, 얼굴 행동, webcam rPPG, cue parameter 최적화, task recognition, saliency, 자동 교정, 차량 연동 및 wearable 방향을 현재 MotionCue의 장비·예산·표본·기간 조건으로 다시 비교했다.
- 가장 현실적인 2학기 방향으로 사전학습된 얼굴·눈 특징 모델을 이용한 `Attention-Aware Adaptive MotionCue`를 제안했다. 정밀 gaze 좌표나 멀미 진단 대신 좌·중앙·우·화면 이탈 수준의 시각 주의 상태를 로컬에서 추정하고, cue의 모션 방향·타이밍은 유지한 채 가장자리별 salience만 설명 가능한 고정 정책으로 조절한다.
- 30명 규모 자료로 딥러닝 멀미 예측이나 온라인 개인화를 학습하는 안은 데이터 부족과 누수·과적합 위험 때문에 본 학부논문 범위에서 제외했다. 개인화, 얼굴 기반 불편 추정, rPPG, saliency 및 task recognition은 후속 연구로 분리했다.
- 1학기 축소안은 기존 `No Cue / Static Visual Control / Synchronized Cue` 효과 연구를 완성하면서 카메라 정보를 탐색적 관찰 지표로만 기록한다. 2학기 권장안은 기술 검증과 파일럿 뒤 `No Cue / Fixed Synchronized / Attention-Adaptive Synchronized` 3조건을 사용해 현재 3회 방문·최대 900,000 KRW 사례비 구조를 유지한다.
- 카메라 추가는 연구 승인과 프라이버시 부담을 높이므로 심의 상태는 계속 `TBD`로 두되, 모집 전에 적용 절차를 확인한다. 원본 얼굴 영상·얼굴 embedding·화면 캡처는 저장하지 않고 파생 attention state만 기록하는 것을 기본 경계로 정했다.
- 상세 후보 비교, architecture, RQ, 실험 선택지, 학기별 일정, 중단 기준 및 차량 없이 바로 할 수 있는 작업을 `docs/adaptive-motioncue-development-roadmap.md`에 기록했다.
- 이 항목은 추천안이며 기존 연구 조건을 즉시 대체한 확정 결정은 아니다. 지도교수 협의와 기술 스파이크 뒤 별도 결정 로그에서 확정한다.
- README의 오래된 상태 설명을 실제 iPhone-to-Windows BLE 검증 결과와 현재 Research Mode 조건에 맞게 갱신하고 새 로드맵을 연결했다.

---

## 2026-08-29 — Reusable GitHub completion-sync 문서화

상태: `IMPLEMENTED`

- 현재 Windows와 Mac workspace에서 사용하는 GitHub-only completion-sync 방식을 다른 프로젝트에도 적용할 수 있도록 `docs/reusable-github-completion-sync.md`를 추가했다.
- 문서는 실제 MotionCue 배포 정보, 사용 조건, non-goals, 초기 clone/publication, Windows·macOS helper 알고리즘, exit code, daily handoff, conflict recovery, `.gitignore`/`.gitattributes` 조건 및 재사용 checklist를 포함한다.
- 이 방식은 background watcher나 cloud filesystem sync를 대체하는 순차 작업용 Git workflow이며, simultaneous editing 또는 automatic conflict resolution을 제공하지 않는다는 한계를 명시했다.

---

## 2026-08-26 — Diagnostics replay controls와 output 영역의 균형 재정렬

상태: `IMPLEMENTED`, `VERIFIED`

- Virtual SensorFrame replay 버튼이 `WrapPanel`의 기본 흐름에 의존해 줄 간 세로 간격이 없고, 마지막 `Dropout` 버튼이 불균형하게 남았다.
- replay controls를 2열 고정 Grid로 변경해 모든 버튼에 10 px 간격을 적용했다. `Full demo / Accelerate`, `Brake / Turn left`, `Turn right / Neutral`을 균등 배치하고 `Dropout`은 마지막 행 전체 폭을 사용한다.
- Diagnostics output의 고정 220 px height와 내부 vertical scrollbar를 제거했다. output은 read-only multiline text가 wrapping된 줄 수만큼 자동으로 높이를 확보하고, 내부 scrollbar 없이 전체 내용을 표시한다.
- 실제 Settings 창에서 Developer Diagnostics를 펼쳐 control spacing과 자동 확장 output을 확인했다.

---

## 2026-08-26 — Advanced expander가 기본 카드 폭을 재계산하지 않도록 고정

상태: `IMPLEMENTED`, `VERIFIED`

- `Research session` 또는 `Diagnostics & test tools`를 펼칠 때 ScrollViewer 내부 content Grid가 펼쳐진 자식의 desired width를 기준으로 다시 measure되어, window가 미세하게 가로로 늘어나고 좌측 세 primary card의 폭이 줄어드는 문제가 있었다.
- Settings ScrollViewer의 `ViewportWidth`를 outer content Grid의 명시적인 width 기준으로 사용하도록 변경했다. 내부 two-column grid는 이제 항상 현재 창의 viewport 폭 안에서만 star column을 계산한다.
- advanced content를 펼치면 세로 scroll range만 증가하며, connection/motion/style card와 status column의 좌우 폭·window width는 변하지 않는다.
- 후속 시각 검토에서 visible vertical scrollbar가 나타나는 순간 자체가 viewport를 좁힌다는 것을 확인했다. ScrollViewer를 `VerticalScrollBarVisibility="Hidden"`으로 변경해 bar는 표시하지 않고 mouse wheel/keyboard scrolling만 유지한다.
- 구현 중 inline connection alert가 참조한 WPF `Danger` brush token이 누락된 runtime resource 오류를 발견해 명시적 token으로 추가했다. Release build와 실제 Settings window launch를 다시 확인했다.
- Research session을 실제로 펼쳐 column width가 유지되는 것을 검수했다. Diagnostics expander도 동일 ScrollViewer/viewport layout을 공유한다.

---

## 2026-08-26 — iOS 기본 화면 압축 및 세부 설정 분리

상태: `IMPLEMENTED`, 빌드·기기 설치 `VERIFIED`; 사용자 시각 확인 `PLANNED`

- 실기기 screenshot 검토에서 `Waiting`, `Waiting for Windows`, `Ready to send`가 반복되고 연결·전송·재연결 설명이 각각 큰 카드로 노출되어 정보량과 글자 크기가 과도한 것을 확인했다.
- 기본 화면을 `MotionCue` header와 단일 상태/calibration card만 남기도록 압축했다. 연결 상태는 한 줄 제목과 한 줄 다음 행동으로 표시하며, calibration은 같은 카드의 짧은 행으로 유지한다.
- Advertising toggle, 잠금 화면 안내, Bluetooth/app 상태, 전송률, frame 수, 마지막 송신과 acceleration은 우측 상단 gear 버튼의 `Details` sheet로 이동했다.
- pill, button, compact card title/value에는 한 줄 제한과 필요한 경우의 최소 축소율을 적용했다. 짧은 단어가 박스 내부에서 어색하게 줄바꿈되지 않도록 metric tile 형식도 제거했다.
- 이 원칙을 `docs/design-system.md`의 `Compact consumer UI rule`로 추가해 이후 Windows/iOS 작업에도 적용한다.
- BLE protocol, calibration algorithm, sensor acquisition, background entitlement 및 송신 로직은 변경하지 않았다.

검증:

- physical iPhone Debug build와 code-sign verification을 통과했다.
- 새 build를 연결된 iPhone에 설치하고 실행했다.

---

## 2026-08-26 — iOS MotionCue Sensor 소비자 화면 재설계

상태: `IMPLEMENTED`, 빌드·기기 설치 `VERIFIED`; 시각적 실기기 검토 `PLANNED`

- Windows Settings에 적용된 공통 디자인 시스템을 iOS companion의 첫 화면에 적용했다. 기존 `List` 기반 진단 화면을 lavender canvas, white card, soft shadow, periwinkle accent의 native SwiftUI 화면으로 교체했다.
- 첫 화면의 우선순위를 `Phone sensor` → `Sending` → `Need to reconnect?`로 재구성했다. 사용자는 Windows 연결 상태, 1초 calibration, advertising 설정과 현재 전송 상태를 진단 값보다 먼저 본다.
- BLE state, notification timestamp, acceleration, frame count 및 오류는 접힌 `Diagnostics`로 이동했다. 연결된 경우에는 `Windows connected`와 자동 송신 상태를, 미연결인 경우에는 Windows에서 Scan을 누를 구체적인 다음 행동을 표시한다.
- 공통 token을 iOS `Assets.xcassets`의 named color asset으로 추가했다. 화면의 brand color를 개별 SwiftUI literal이 아닌 `Canvas`, `Surface`, `Accent`, `Text` 등 token으로 사용한다.
- 전송 protocol, calibration, Motion acquisition, BLE service/UUID, background mode 동작은 변경하지 않았다. asset catalog를 새로 추가하면서 존재하지 않던 `AppIcon` build setting을 제거했다; app icon artwork는 이번 UI scope에 포함하지 않았다.

검증:

- physical iPhone Debug build가 code signing 및 asset catalog compilation을 포함해 성공했다.
- 새 `.app`을 연결된 iPhone에 설치하고 launch 명령을 완료했다. 실제 기기에서 card clipping, Dynamic Type 및 상태 전환 시각 검토는 다음 사용자 확인에서 기록한다.

---

## 2026-08-26 — Phone connection warning을 non-modal inline recovery 안내로 변경

상태: `IMPLEMENTED`, build/test `VERIFIED`

- Phone sensor가 선택되지 않은 상태에서 `Connect`를 누르면 Windows 기본 `MessageBox`가 표시되어, 사용자의 작업 흐름을 막고 새 카드형 UI 언어와도 충돌했다.
- Phone connection card의 기존 회색 상태 문구 아래에 고정 18 px 높이의 inline alert 영역을 추가했다. 기기 미선택, scan 결과 없음, BLE scan/connect/disconnect 예외는 이제 이 영역에 `danger` 색상의 한 줄 recovery 안내로 표시된다.
- alert 영역은 항상 공간을 예약하므로 오류가 나타나도 카드 또는 창의 높이·배치가 바뀌지 않는다. 긴 시스템 오류는 한 줄 ellipsis와 tooltip으로 보존한다.
- 정상 scan/connect 시작 시 이전 alert는 즉시 지워지고, source status는 기존의 중립적인 상태 문구로 계속 표시된다.
- Research session과 marker 입력처럼 별도 사용자 결정을 요구하는 연구용 modal은 이번 consumer connection UX 변경 범위에서 유지한다.
- Core test 24개와 Release build를 통과했고 새 self-contained Windows artifact를 publish했다.

---

## 2026-08-26 — Cross-platform MotionCue design system baseline

상태: `DECISION`, `IMPLEMENTED`

- 제공된 `gradient-ui-ux-elements-collection.zip`의 JPG/EPS/AI reference를 검토해, 부드러운 lavender canvas·white card·diffuse shadow·periwinkle accent의 시각 언어를 MotionCue 전용 규칙으로 정리했다.
- `docs/design-system.md`를 Windows WPF, iOS SwiftUI, 연구 화면, 향후 문서 screenshot의 단일 디자인 기준으로 추가했다. color/spacing/radius/shadow token, typography, information architecture, component state, status copy, accessibility, asset licensing, review checklist를 포함한다.
- reference archive는 외부 UI kit이며 runtime asset license가 확인되지 않았으므로 JPG/EPS/AI를 제품에 포함하지 않는다. 현재 Windows 구현과 앞으로의 iOS 구현은 native control/template으로 그 디자인 언어만 재현한다.
- Windows는 Segoe UI, iOS는 SF Pro를 사용한다. reference가 안내한 Nunito는 별도 font-install dependency를 만들지 않기 위해 채택하지 않았다.

후속:

- iOS companion app의 다음 UI 작업부터 `docs/design-system.md`의 consumer-facing hierarchy와 token을 적용한다.
- Windows 신규 화면/컨트롤도 동일 문서의 design review checklist를 통과해야 한다.

---

## 2026-08-26 — Windows Settings UI 간소화 및 통합 디자인 적용

상태: `IMPLEMENTED`, `VERIFIED`

- 기존 설정 창은 휴대폰 연결 기능이 Developer Mode 안에 숨겨져 있고, 일상 설정·연구 도구·진단 도구가 동일한 위계로 나열되어 첫 사용자가 필요한 동작을 찾기 어려웠다.
- 기본 화면을 `Connect your phone` → `Motion cues` → `Visual style`의 세 카드로 재구성했다. BLE 스캔·연결·해제와 현재 센서 상태를 항상 첫 화면에서 확인할 수 있다.
- 연구 세션은 별도의 접히는 영역으로 이동했고, 가상 SensorFrame 재생·진단 정보는 Developer Mode를 해제했을 때만 나타나는 별도 진단 카드로 분리했다. 연구·진단 기능과 기존 event handler, 세션 안전 정지 기능은 삭제하지 않았다.
- 밝은 배경, 부드러운 그림자, 보라색 단일 accent, 둥근 카드형 컨트롤을 적용했다. 드롭다운은 Windows 기본 외형 대신 둥근 선택 필드·포커스 링·항목 목록을 사용하고, 체크박스는 선택 시 accent check mark가 보이는 rounded control로 교체했다.
- 제공된 UI kit archive는 EPS/AI/JPG reference와 Nunito 폰트 안내만 포함한다. 외부 폰트를 설치하거나 자산을 앱에 포함하지 않고, 참고 디자인의 palette·spacing·corner treatment만 WPF native template으로 재구현했다.
- Release build와 core test 24개를 통과했고, Settings 창에서 기본 상태·custom ComboBox popup·custom CheckBox 렌더링을 실제로 확인했다.

영향 및 후속:

- 기능상 연결 프로토콜, SensorFrame UUID, motion estimator, 연구 CSV 형식은 변경하지 않았다.
- 새 self-contained Windows artifact를 publish하고 GitHub completion-sync로 Mac clone에 전달한다.

---

## 2026-08-25 — iPhone BLE Peripheral 백그라운드 연결 지원

상태: `IMPLEMENTED`, 설치본 구성 `VERIFIED`; 잠금 화면 실측은 `PLANNED`

- iOS 앱의 명시적 `Info.plist`에 `UIBackgroundModes`의 `bluetooth-peripheral`을 추가했다. 이 권한은 이미 SensorFrame을 구독한 Windows central이 iPhone 잠금 상태에서도 BLE peripheral 연결을 유지할 수 있도록 iOS에 요청한다.
- `CBPeripheralManager`에 안정적인 restoration identifier를 부여하고, Bluetooth가 peripheral 상태를 복원한 사실을 앱 상태로 표시한다. SwiftUI scene lifecycle도 `Foreground`/`Background BLE enabled`로 표시한다.
- 잠금 중에도 연결 보존을 요청하는 것과 25 Hz 센서 송신을 보장하는 것은 구분한다. iOS가 백그라운드 CPU·Core Motion 전달 시점을 결정하므로, 잠금 중 continuous stream은 보장하지 않으며 unlock 후 자동 재개 여부를 실측한다.
- iPhone Debug build를 signing 및 device validation까지 성공했고, 최종 `.app/Info.plist`에서 `UIBackgroundModes = [bluetooth-peripheral]`을 확인했다. 새 build를 연결된 iPhone에 설치하고 실행했다.

남은 실측:

- Windows가 SensorFrame에 구독된 상태에서 iPhone을 30초 이상 잠근 후, Windows가 여전히 subscribed인지와 unlock 시 재연결 없이 frame이 재개되는지를 기록한다.

---

## 2026-08-25 — 차량 비필수 작업: 연구 조건을 실제 소프트웨어와 정렬

상태: `IMPLEMENTED`; 실제 차량 파일럿 QA는 `PLANNED`

- Research Mode의 기존 공학 QA 조건 `NoCue / Regular / Dynamic`을 논문 프로토콜 조건 `NoCue / StaticVisualControl / SynchronizedCue`로 교체했다. consumer appearance의 `Regular / Dynamic` 설정은 별도로 유지한다.
- `StaticVisualControl`은 regular appearance의 점을 보이게 하되, Phone IMU 값과 무관하게 `horizontal=0`, `vertical=0`, `intensity=0`으로 고정한다. 따라서 단순 시각 요소의 존재와 실제 운동 동기화 정보를 분리할 수 있다.
- `SynchronizedCue`는 accepted Phone IMU frame에서 regular appearance의 cue offset을 생성한다. `NoCue`는 cue를 보이지 않게 한다.
- 공통 fail-safe는 유지된다. Phone stream이 Ready가 아니면 StaticVisualControl도 stale visual을 유지하지 않고 cue를 끈다.
- CSV protocol version 기본값을 `MC-PILOT-2`로 올렸고 UI condition labels·CSV enum values·연구 문서·테스트를 함께 변경했다.
- `CuePresentationEngine.CreateStaticFrame`과 unit test를 추가해 static condition이 표시되지만 motion offset·intensity가 0인 것을 보장한다.

남은 차량 비필수 QA:

- live iPhone 연결 상태에서 10초 QA session으로 세 조건의 표시·CSV condition·세션 복구를 검증
- iPhone 잠금 화면 연결 유지 실측

---

## 2026-08-25 — Mac GitHub clone 및 completion-sync 구성

상태: `IMPLEMENTED`, `VERIFIED`

- Windows와 Mac은 GitHub private repository의 분리된 local clone을 사용하며, 기존 USB 복사본은 `/Users/jayden/vehicle_mode_for_laptop_usb_backup_20260825_1045`로 rename하여 보존했다.
- 새 GitHub clone은 문서가 지정한 `/Users/jayden/vehicle_mode_for_laptop`를 실제 Mac 작업 경로로 사용한다. `main`은 origin과 clean 상태로 clone됐다.
- Mac 전용 GitHub SSH key를 설정하고, 기존 다른 repository deploy key와 충돌하지 않도록 `github.com-motioncue` SSH host alias를 사용한다.
- `tools/git-autosync-mac.sh`는 각 material Codex 작업의 완료 직전에 수동 실행한다. dirty tree를 `autosync(mac)` snapshot으로 한 번 commit하고, fetch/rebase/push하되 Git operation, lock 또는 conflict 때는 파일을 덮어쓰지 않고 repository 밖 log에 멈춤 이유를 기록한다.
- Windows·Mac 양쪽에서 continuous watcher, 2분 schedule, launchd, Syncthing 및 cloud-drive live workspace는 사용하지 않는다. 순차 작업의 completion-sync만 사용한다.
- iPhone project를 Xcode 26.6의 `xcodebuild -list`로 열어 `MotionCueSensor`·`MotionCueSensorTests` scheme을 확인했다. 초기 helper 실행은 `autosync(mac): 2026-08-25 10:47 KST` commit을 생성하고 GitHub `main` push까지 성공했다. log는 `~/Library/Logs/MotionCue/git-autosync.log`에 기록된다.

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
- 초기 2분 반복 `MotionCue Git AutoSync` Scheduled Task는 사용자에게 visible PowerShell 창을 반복 표시하고, 사용자가 직접 편집하지 않는 Codex 중심 workflow에는 불필요함이 확인됐다. 이 task는 제거하고 continuous watcher/polling을 사용하지 않는다.
- Windows Codex는 material change가 끝날 때 `tools/git-autosync.ps1`을 한 번 실행하는 completion-sync 방식으로 전환한다. Mac counterpart도 `launchd`가 아니라 Mac Codex task 완료 시점의 helper 실행으로 구성한다.
- Mac clone-first·completion-sync 설정 지침과 실행 프롬프트를 `docs/mac-git-autosync-setup.md`에 기록했다.
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
