# MotionCue — 실제 시험 전 준비 기준

기준일: 2026-10-04 · 대상: iOS/Windows 0.2.0 pilot · 물리 bench 미완료

배포 갱신(18:17 KST): iPhone 0.2.0/build 2 Release 서명·설치 완료. 실행 시 Untrusted Developer가 표시되어 기기의 개발자 신뢰 확인 대기다. 설치만으로 G1 통과를 뜻하지 않는다. 현재 provisioning 만료는 2026-10-11 17:40 KST이며 이후에는 재서명/재설치한다. 상세 증거는 개발 로그에 기록했다.

## 목표 완성도

**통제된 연구자 공학 파일럿에 사용할 안정적인 버전**을 만든다. App Store 수준, 모든 휴대폰 지원, 잠금 연속 송신 보장, 멀미 개선 효과 입증은 이번 구현 완료 기준이 아니다.

- 유지: IMU 50 Hz → SensorFrame v1 42 bytes/BLE 25 Hz → Windows cue.
- 연구: `NoCue / StaticVisualControl / SynchronizedCue`, `MC-PILOT-2`.
- UI: 짧은 상태·Calibrate만 기본 화면, 나머지는 Details. 박스/버튼의 짧은 label은 한 줄.
- 아이콘: 좌상단 waveform + dot; 독자 SVG/iOS AppIcon/Windows EXE·tray ICO.
- 보류: AI/CV, Android, Wi-Fi, GPS, 앱 계층 인증, public distribution. Android 호환성은 별도 Study A 과제다.
- 지연: 기존 0.20 s filter 유지. 통신과 화면 지연을 분리 측정한 뒤 로그/재검증과 함께 튜닝한다.

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
8. 잠금 **60초/5분** 각 1회: 연결·보정 후 debugger 없이 USB를 뽑고 잠금. Subscribed 유지/송신 정지/해제 후 재연결 없는 복구를 따로 기록.
9. 멈춰도 stale 프레임을 새 프레임처럼 보내지 않음. 연속 송신이 필요하면 **Keep screen on** 사용. 잠금 연속 송신은 보장하지 않음.
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
