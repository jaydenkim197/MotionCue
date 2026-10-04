# MotionCue — 실제 시험 전 준비 기준

기준일: 2026-10-04 · 대상: iOS/Windows 0.2.0 pilot · 물리 bench 미완료

배포 갱신(20:17 KST): source `212ae50`의 iPhone 0.2.0/build 3 Release 서명·설치·정상 실행 및 runtime log 회수를 확인했다. Windows 구독 1개/sensor Fresh, 미보정 queued 0, 약 50초 foreground Timer p50 약 40.00 ms를 관찰했다. Windows 0.2.0의 이전 actual Streaming 수신 p50 약 58 ms는 임시 gate 35–50 ms 범위를 벗어나며, 새 보정 후 enqueue/수신 비교와 background 중단 재현이 남아 G1은 미통과다. 현 provisioning 만료는 2026-10-11 17:40 KST다.

실측 갱신(20:33 KST): build 3 보정 후 약 70초의 summary 8개에서 enqueue 24.99–25.13 Hz, p50 39.59–40.02 ms, p95 40.77–49.21 ms, queued 60→1813, backpressure/drop 0을 확인했다. Fresh/화면 유지/구독 1개가 관찰됐다. **현재 Windows 수신 통계와 비교 대기**이며, 이 짧은 sender 표본은 G1 30분/잠금/10회 재연결 통과가 아니다.

Windows 실측 갱신(21:15–21:17 KST): foreground 약 47.3초에서 accepted +1182, **실제 수신 24.99 Hz**, missing/rejected 0, p50/p95 58.2/61.1 ms를 확인했다. 60초 목표를 넘어 82초 유지한 잠금 확인 구간에서는 BLE 구독은 유지됐지만 수신이 멈추고 timeout/큐 비표시가 관찰됐다. 잠금 해제 후 복구는 확인 중이다. Median 간격의 역수와 처리량은 다르며 one-way latency로 해석하지 않는다. [Windows bench 기록](bench-2026-10-04-windows-build3.md) 참조. G1 전체는 미통과다.

복구 갱신(21:34–21:36 KST): 잠금 해제 후 MotionCue foreground에서 기존 BLE 구독으로 자동 수신/cue 복구를 확인했다. Scan/Connect/Calibrate 없이 **73.015초 +1825 frames = 24.99 Hz**, missing/rejected 0이다. 누적 약 18분 45초 공백은 사용자 해제 응답 대기로 길어진 시험 중단이며 recovery latency가 아니다. **잠금 연속 송신은 중단, foreground 자동 복구는 확인**이다. 정확한 60초/5분 trial·30분·10회 재연결/G1 전체는 완료되지 않았다.

## 목표 완성도

잠금 대응 후보(build 4): `Details → Locked session → Start`로 iOS 26+ 공식 continued-processing 작업을 명시적으로 시작하는 유한 송신 세션을 추가했다. 45,000 fresh enqueue 목표(약 30분)/35분 hard limit이며 OS 승인·취소/실제 잠금 연속 송신은 실기기 확인이 필요하다. 무기한 송신이나 G1 통과를 의미하지 않는다. [검증 절차](bench-ios-build4-lock-session.md).

후속(build 5): build4의 background 실행/송신 지속은 확인했지만 약8.45 Hz와 일부 >1초 공백으로G1은 실패. 송신을 real Core Motion sample-driven cadence로 변경했다. Simulator42/42 통과, 23:12 KST 실기기0.2.0 (5)의 strict signing/설치·일반 launch 확인. 새 보정·Start 및 잠금실측은 아직 대기다. 단순 움직임 반응만으로25 Hz/G1 통과를 주장하지 않는다.

잠금 실측 갱신(23:21 KST): build5 첫60초 USB 없는 잠금 시험에서 사용자가 Windows Frames 지속 증가를 확인했고, background90.259 s의 +2250 enqueue/**24.9283 Hz** 및 Windows 사진6.66 s의 +165 accepted/**24.78 Hz**를 대조했다. 구독/fresh/보정 유지, 새 session 종료 없음. 잠금 전환 직후 약300 ms send gap은 남았으며 Windows p50 약59 ms/G1 30분/5분/전체 세션은 미완료다. [새 시험 기록](bench-2026-10-04-ios-build5.md).

후속(23:24 KST): 같은background 구간에서**310.8835 s/+7750 enqueue =24.92895 Hz**, 구독/fresh/보정 유지/새 종료 없음. 사용자가5분 Windows Frames 지속 증가를 확인했다. **한 번의USB 없는5분 이상 잠금 송신 지속은 확인**, 별도독립trial/전체45,000frame·35분/취소·Stop/반복/G1전체는 미완료다. Windows5분 종료 정량snapshot은 아직 없다.

**통제된 연구자 공학 파일럿에 사용할 안정적인 버전**을 만든다. App Store 수준, 모든 휴대폰 지원, 잠금 연속 송신 보장, 멀미 개선 효과 입증은 이번 구현 완료 기준이 아니다.

- 유지: IMU 50 Hz → SensorFrame v1 42 bytes/BLE 25 Hz → Windows cue.
- 연구: `NoCue / StaticVisualControl / SynchronizedCue`, `MC-PILOT-2`.
- UI: 짧은 상태·Calibrate만 기본 화면, 나머지는 Details. 박스/버튼의 짧은 label은 한 줄.
- 아이콘: 좌상단 waveform + dot; 독자 SVG/iOS AppIcon/Windows EXE·tray ICO.
- 보류: AI/CV, Android, Wi-Fi, GPS, 앱 계층 인증, public distribution. Android 호환성은 별도 Study A 과제다.
- 지연: 기존 0.20 s filter 유지. 통신과 화면 지연을 분리 측정한 뒤 로그/재검증과 함께 튜닝한다.

현재 후속 확인(23:44 KST): Mac build 5의 8분 background summary는 481.2813 s/+11996 enqueue/**24.92513 Hz**였다. Windows에서 `18383f6` pull 후 직접 읽은 별도 81.3555061 s는 +2028 accepted/**24.9276 Hz**, 추가 missing/rejected 0/0, 시작·끝 Streaming이다. 마지막 p50/p95는 58.0/60.7 ms로 임시 median gate는 아직 미충족이다. 누적 max 2435.1 ms는 측정 시작 전부터 있어 발생 시각·원인 불명이다. 현재 iPhone 화면/세션 상태와 45,000-frame 완료는 미확인이다. 실행 EXE manifest는 이전 revision/dirty 상태이므로 다음 통제 trial 전에 clean build가 필요하다. 진행 중 연결은 보존했다. [상세 기록](bench-2026-10-04-ios-build5.md).

## Gates

| 단계 | 필요한 완성도 | 현재 판단 |
|---|---|---|
| G0 배포 후보 | 자동 테스트, 두 플랫폼 Release build, 아이콘/버전, stale·중복 차단, 오류/복구, Git handoff | 코드 검증 단계; 설치 결과는 개발 로그 참조 |
| G1 책상 bench | 아래 체크리스트, 동일 commit EXE, 정상 스트림/끊김/재연결 | 물리 조작 필요, 미통과 |
| G2 연구자 engineering 실차 | G1 + 고정 거치·실제 축·운전자/안전 모니터·기관의 필요 절차 확인 | 준비 전. 운전자는 앱/노트북 조작 금지 |
| G3 참가자 파일럿/본 실험 | G2 결과 + 심의/면제 등 절차·동의/중단/회복/데이터 관리·과업/순서/노선/시간/자극 고정 | 시작 불가, 연구 승인 TBD |

기술 bench가 사람 대상 연구 승인이나 효과 검증을 대신하지 않는다. 미확정 사람 대상 항목은 [Open Decisions](open-decisions.md) P1에 남긴다.

## G1 물리 bench

수치는 **이번 장비의 임시 공학 release gate**이며 의료적/통계적 효과 기준이 아니다. 실측 뒤 변경 시 로그를 남긴다.

1. 최신 Windows EXE/iPhone 0.2.0 → Scan/Connect → Windows BLE `Subscribed`.
2. 화면 위/상단 전방 방향으로 단단히 고정, 정지 보정. 옆으로 세운 상태/움직이는 상태는 보정 거부 확인.
3. Details: Windows 1, Sample Fresh, 약 25 Hz, Frames 증가. 미보정이면 송신 수 증가 없음.
4. **화면 켠 30분**: crash/hang·의도하지 않은 1초 이상 공백 없음. Windows 간격 p50 35–50 ms, p95 ≤100 ms, sequence gap ≤1%를 임시 기준으로 사용. 실패하면 실차 전 원인 분석.
5. accepted/missing/rejected·p50/p95/max/jitter SD 시작/끝 기록. p50/p95/SD는 최근 1500 간격, max/counters는 연결 이후 누적. Gap은 송신측 drop도 포함하며 radio-only loss가 아님.
6. 정차 상태 background/Bluetooth off/강제 종료: 마지막 Windows 수신 이후 250 ms neutral/1초 source timeout 확인. BLE 구독과 stream timeout은 다른 상태.
7. 재연결 10회: 수동 Scan/Connect 후 10초 이내 새 프레임, 오래된 비중립 cue 재생 없음. Process 종료 후 재보정.
8. 잠금 **60초/5분** 각 1회: 연결·보정 후 debugger 없이 USB를 뽑고 잠금. Subscribed 유지/송신 정지/해제 후 재연결 없는 복구를 따로 기록. build 3에서는 해제 후 앱 foreground 복귀 → Details의 Prepare logs로 summary를 남기고 Mac 재연결 후 로컬 진단을 회수한다. 로그의 runtimeGap과 Windows max gap을 비교하되, 서로 다른 시계 차이를 one-way latency로 사용하지 않는다.
9. 멈춰도 stale 프레임을 새 프레임처럼 보내지 않음. build 4의 유한 Locked session은 Start/Running 확인 후 USB 없이 60초/5분 및 전체 목표·Stop/OS 취소를 따로 시험한다. 단순 Subscribed 유지가 아니라 Windows accepted 증가/Streaming/cue와 iOS fresh enqueue 증가가 필요하다. 아직 미통과이며 **Keep screen on + foreground**가 현재 확인된 fallback이다. 잠금 연속 송신은 보장하지 않음.
10. Windows replay의 3조건/FMS/`Ctrl+Shift+F12`/정상·긴급 CSV 종료 record 재확인. Replay는 실제 축·지연 시험의 대체가 아님.

BLE background mode는 지속 실행을 보장하지 않으며 restoration에는 service/characteristic 복구가 필요하다. [Apple background/restoration guide](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html)

이번 구현은 센서 취득 timestamp로 100 ms 초과/중복 sample을 버린다. [Apple processed device-motion data](https://developer.apple.com/documentation/coremotion/getting-processed-device-motion-data)

## G2 및 참가자 시험 전 남은 작업

- 실제 정차/가속/제동/좌·우회전 축·부호. Gravity는 화면 위 거치만 확인 가능; 전방 yaw alignment는 물리적으로 맞춰야 함.
- 기준 IMU 또는 한계를 명시한 비교 기기와 이벤트 동기화, 입력→BLE→cue 지연 분리. 미동기화 iPhone/PC clock 차이를 one-way latency로 보고하지 않음.
- 실제 route에서 filter 방향/진폭/지연, frame-time/CPU/memory/battery 측정.
- 조건 순서 할당, 동등 과업, 데이터 관리/중단 기준. 이미 완료된 것으로 주장하지 않음.

## Git/Windows handoff

시작 Mac/fetched GitHub main은 `ebbbe7f`로 같았고 최신 원격 Windows 기록은 2026-09-04였다. **Windows 미push 파일·로컬 EXE는 Mac의 Git 상태만으로 확인 불가**다.

현재는 2분 timer/launchd가 아니라 **Codex 완료 때 commit→rebase→push**다. 상대 기기는 시작 전 pull한다. Ignored `.tools/`, `artifacts/`, EXE, iOS build, 인증서는 동기화되지 않는다.

Windows 변경이 있으면 먼저 completion-sync로 보존·push한다. 충돌/활성 Git 작업이면 reset/overwrite 없이 수동 확인한다.

```powershell
git status -sb
powershell -ExecutionPolicy Bypass -File .\tools\git-autosync.ps1
git pull --ff-only
powershell -ExecutionPolicy Bypass -File .\tools\build-windows-release.ps1
git rev-parse HEAD
```

EXE: `artifacts\MotionCue-win-x64\MotionCue.Windows.exe`. Helper는 tests→publish→SHA256/source revision manifest를 만든다. `WorktreeDirty=false`, Mac/GitHub와 동일 revision 확인. `RuntimeValidated=false`는 별도 물리 검증이 필요하다는 뜻이다. Mac cross-build/publish는 Windows GUI/BLE/트레이 및 PowerShell runtime 검증을 대신하지 않는다.

## 측정 기록

```text
Date / commit / iOS version(build) / Windows manifest SHA256:
Windows OS / BLE adapter-driver / app version:
Mount / calibration / foreground duration:
iOS queued frames-rate / dropped:
Windows accepted-missing-rejected / p50-p95-max-jitter:
Lock duration / subscribed? / paused? / unlock recovery / reconnect?:
Bluetooth-off watchdog / reconnect trials:
Axis / emergency stop / CSV end record:
Pass-fail / blocker / coordinate-free evidence path:
```

검증·변경은 [Development Log](development-log.md)에 계속 남긴다.
