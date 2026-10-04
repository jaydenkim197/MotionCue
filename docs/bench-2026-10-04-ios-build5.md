# 2026-10-04 — iPhone build 5 잠금 송신 시험

상태: **USB 없는 5분 이상 잠금 중 nominal25 Hz 송신 지속 확인**. 전체 세션/종료·취소/새 잠금 반복 및 G1 전체는 미완료. 잠금 전환 직후 공백과 Windows 수신 간격은 별도 개선 대상이다.

## 조건과 증거

- iPhone 16 Pro / iOS 27.0.1 / MotionCue 0.2.0 (5), source `e1ac090`. 후속 `76db914`는 배포 문서만 변경했다.
- Release strict signing/설치/일반 launch 확인. 이번 관찰 중 재설치·프로세스 재시작·debugger/console attach는 하지 않았다.
- 23:14:21 KST 보정 완료, 23:14:28 user-started Locked session Requested → Running. 사용자가 Frames 증가를 확인했다.
- 23:15/23:17 기기 연결은 wired였고, 23:19에는 **localNetwork**였다. 사용자는 USB 분리·60초 화면 잠금 시험을 완료했고 Windows Frames가 계속 증가했다고 보고했다. 네트워크는 명명된 앱 로그 파일 회수용이며 센서 데이터는 기존 BLE 경로다.
- 원본은 ignored `artifacts/ios-runtime-20261004-231539-qmKFOm`, `ios-runtime-20261004-231749-GBeym5`, `ios-runtime-20261004-231922-Wb4RiP` 및 `ios-build5-trial-transport.json`에 보관한다. Raw IMU/다른 앱 로그/기기 식별정보를 Git에 올리지 않는다.

## iPhone 실측

| 구간 | 관찰 길이 | 실제 enqueue 증가 | 평균 enqueue rate | 해석 |
|---|---:|---:|---:|---|
| 새 Start 후 foreground 23:14:34–23:15:34 | 60.1721 s | 3362→4862, +1500 | 24.9285 Hz | 화면 켠 송신 확인 |
| background summary 23:17:45–23:19:15 | 90.2590 s | 8107→10357, +2250 | 24.9283 Hz | 잠금 시험에 대응한 background 송신 지속 |

23:17:38 inactive/짧은 active 이후 23:17:39 background 전환이 기록됐다. Summary 간 duration은 monotonic uptime의 차이이며, 이는 정확한 측면 버튼/잠금 해제 시각이나 Windows 수신 duration이 아니다. 화면 잠금·USB 분리는 사용자 보고와 연결 transport를 함께 대조한다.

- Background summary 10개 모두 centrals **1**, fresh **1**, screenAwake **0**. 마지막 session Frames **7139**, elapsed **286 s**. 새 calibration invalid/세션 종료 event 없음.
- 최근 250 enqueue 간격 p50 범위 **40.109–40.120 ms**, p95 **47.991–52.695 ms**. 마지막 p50/p95 **40.112/47.991 ms**, max **53.463 ms**. 이는 최근 window별 sender 통계이지 전체 trial의 global percentile 또는 end-to-end latency가 아니다.
- Background 전환 직후 23:17:39 send-opportunity gap **300.299 ms** 1회, 다음 summary의 enqueue max **303.764 ms**. 이후 23:19:15까지 추가 ≥250 ms send-opportunity gap event 없음. 전환 순간 무공백이라고 주장하지 않는다.
- 해당 90초 summary 간 dropped **1→1**(추가0), backpressure **4→5**(추가1). 앱 전체 실행 중 dropped1/backpressure5는 0이 아니며, BLE transport failure/Windows missing과 동일한 계수가 아니다. Queue sample age의 summary 최대 **5.434 ms**는 기록된 최신 enqueue sample들의 값이며 trial 전체 sample-age 최대는 아니다.
- Simulator **42/42**, 실패/skip/runtime warnings0인 기존 xcresult를 재확인했다. 이번에는 테스트를 다시 실행하거나 기기 앱을 바꾸지 않았다.

## Windows 사용자 사진 대조

사용자 제공 두 Diagnostics 사진의 sample timestamp는 수신 시각으로 전달된 `MotionState.Timestamp`이다. iPhone IMU elapsed timestamp나 두 기기 간 동기화 clock으로 사용하지 않는다.

| Windows 수신 시각 (KST) | accepted / missing / rejected | p50 / p95 | 누적 max / 최근 jitter SD | 상태 |
|---|---|---|---|---|
| 23:18:03.0380804 | 5449 / 1 / 0 | 59.0 / 60.6 ms | 240.4 / 29.7 ms | Subscribed / Streaming / cue visible |
| 23:18:09.6976408 | 5614 / 1 / 0 | 58.9 / 60.6 ms | 240.4 / 29.5 ms | Subscribed / Streaming / cue visible |

- **6.6595604 s에 +165 accepted =24.7764 Hz**. 짧은 표본이며 사용자 보고와 함께 수신 지속을 뒷받침한다. 두 snapshot만으로 구간 내 모든 watchdog 상태를 증명하지 않는다.
- Missing1/rejected0, sequence gap0.02%는 두 사진에서 같았다. iPhone의 dropped1과 수치가 같더라도 동일 frame임을 증명하지 못했다.
- p50의 역수는 평균 throughput이 아니다. 최근1500 interval p50 약59 ms가 25 Hz throughput과 함께 나타나는 이유/notification batching은 아직 실측 분리 전이다. One-way latency로 해석하지 않는다.
- 0.20 s smoothing 및 250 ms neutral/1 s timeout은 변경하지 않았다. Windows 누적 max240.4 ms와 iPhone enqueue max303.8 ms는 다른 계측점/clock/window이므로 차이를 network delay로 계산하지 않는다.
- 현재 Windows EXE manifest/source hash는 이번 사진만으로 재검증하지 않았다. GitHub에 새 Windows commit은 없었으며 미push 파일·실행 binary를 Mac Git 상태만으로 검증하지 않는다.

## 판정과 다음 단계

Build4 background 표본의 약8.45 Hz에 비해 새 후보의 이번 background 표본은 nominal25 Hz 수준으로 유지됐다. 서로 다른 run/구간이며 무기한 background 지원 또는 전환 공백 해결을 뜻하지 않는다.

### 23:24 KST 후속 — 5분 이상 연속 송신

사용자는 5분 시험 완료 및 Windows Frames 지속 증가를 보고했다. `artifacts/ios-runtime-20261004-232258-q7y6P9`의 추가 회수에서 23:17:39 background 이후 23:22:56까지 새 active 전환이 없었다. 따라서 60초 시험 뒤 독립된 두 번째5분 시험이 아니라 **같은 background 구간의 연장**으로 기록한다. 잠금 해제/foreground 복귀의 정확한 시각은 이 capture에서 아직 확인되지 않았다.

- Background summary **32개**, 23:17:45–23:22:56, **310.8835 s**, queued **8107→15857(+7750) =24.92895 Hz**. Summary window만으로도5분 이상이며 각 summary의 centrals1/fresh1/screenAwake0이 유지됐다. 새 stream-freshness 변화/calibration invalid/세션 종료 event 없음.
- 최근250 enqueue interval p50 범위 **40.108–40.136 ms**, p95 **46.744–52.695 ms**. 마지막 p50/p95/max **40.118/47.786/68.625 ms**. 전환 직후300.299 ms gap 외 추가 ≥250 ms send-opportunity event가 이 capture에는 없었다. Summary/allowlist log는 per-frame trace가 아니므로 모든 radio gap을 입증하지 않는다.
- 동일 구간 dropped 추가0/backpressure 추가1(누적1/5). 마지막 session Frames **12639**, elapsed **507 s**. 45,000 frame 목표 또는35분 hard limit에는 아직 도달하지 않았다.
- Windows의5분 지속 수신은 사용자 보고이며 현재 제공된 사진 수치는23:18의6.66초 표본이다. 5분 종료 accepted/p95/max의 정량 자료는 아직 사진으로 확인되지 않았다.
- `Keep screen on` 값이1인 foreground와 달리 background에서는 screenAwake0이다. 이 metric 자체가 물리 화면 상태를 증명하지는 않으며 실제 잠금 여부는 사용자 보고를 함께 사용한다.

이 candidate의 **한 번의5분 이상 잠금 송신 지속 조건**은 확인됐다. 무기한/모든 iOS·장비·OS 종료 조건 또는 G1 전체 통과로 확대하지 않는다.

### 23:27 KST 추가 관찰 — 8분 이상 background 지속

최종 회수 `artifacts/ios-runtime-20261004-232551-HKtzYD`의 23:17:45–23:25:46 background summary49개는 **481.2813 s / +11996 enqueue =24.92513 Hz**였다. 구독1/fresh1, 추가drop0/backpressure2(첫 summary 대비; 마지막 summary 누적1/6), 새 invalid/세션 종료 및 추가≥250 ms send-opportunity gap event 없음. 23:25:48 inactive→23:25:50 background 전환이 있었으나 active event는 없었다. 마지막 lifecycle에서는 session Frames16985/elapsed681 s, 누적backpressure10/drop1이었다. Summary49개 이후의 counters를 해당8분 summary 구간에 섞지 않는다.

따라서 앱 background 실행/송신은8분 이상 관찰됐다. 실제 화면 잠금은 사용자가 확인한 trial 조건이며, 23:25의 정확한 잠금/해제·다른 앱 사용 여부는 이 앱 lifecycle만으로 알 수 없다. Foreground 복귀 성공을 active event 없이 주장하지 않는다.

코드 검토 한계: cadence의38 ms guard는 **IMU acquisition timestamp 사이**에 적용된다. MainActor callback backlog/일시적 BLE backpressure 뒤 실제 enqueue wall-time 간격의 하한을 보장하는 별도 guard는 아니다. Latest-only/100 ms freshness가 유지되지만 모든 실제 enqueue burst 부재를42개 unit tests 또는 summary만으로 증명하지 않는다. Main callback/Windows batching과 전환 gap은 후속 계측 대상이다.

1. 잠금 해제 후 기존 BLE 구독·보정/foreground 복귀 확인 및 별도 새 잠금 반복.
2. 45,000 fresh enqueue 목표/35분 hard limit, Stop/OS cancellation 및 foreground 재시작 검증. 자동 재시작 없음.
3. Windows 수신 간격/전환 gap, 30분 foreground/10회 재연결 등 G1 잔여 조건 확인 후 지연·필터 튜닝 판단.

### Windows 후속 관찰 — 23:40–23:41 KST

Windows에서 GitHub `18383f6`까지 pull했다. 새 변경은 iOS 코드와 문서이며 Windows 코드는 바뀌지 않았다. Mac 시험 기록은 검토했지만 ignored iPhone 원본 JSONL은 이 복사본에 없어 재계산하지 않았다. 아래는 Windows에서 직접 읽은 별도의 수신 관찰이다.

| 수신 시각 (KST) | accepted / missing / rejected | p50 / p95 (ms) | 누적 max / 최근 jitter SD (ms) |
|---|---|---|---|
| 23:40:23.1559546 | 38368 / 45 / 0 | 58.1 / 60.9 | 2435.1 / 37.3 |
| 23:41:44.5114607 | 40396 / 45 / 0 | 58.0 / 60.7 | 2435.1 / 27.8 |

- **81.3555061 s / +2028 accepted = 약 24.9276 Hz**, 추가 missing/rejected **0/0**. 시작·끝 모두 Ready / Subscribed / Streaming / cue visible / sample interval 40 ms였다. 전체 세션 또는 모든 중간 watchdog 상태를 입증하는 per-frame trace는 아니다.
- 누적 sequence gap은 0.12%→0.11%로 표시됐다. Missing 45와 max 2435.1 ms는 시작 전부터 있던 값이다. 이 구간에서 max가 증가하지 않았지만, 더 짧은 새 공백이 없었다거나 기존 2.44초 공백의 원인이 잠금 전환이었다고 단정할 수 없다.
- BLE notification callback의 수신 간격은 monotonic clock으로 기록된다. Sample timestamp는 Windows 수신 UTC 시각이다. 25 Hz 처리량과 p50 약 58 ms가 함께 관찰됐으며 batching 등의 원인과 입력→화면의 실제 지연은 분리 측정 전이다. 0.20 s smoothing은 유지했다.
- iPhone의 현재 물리 화면·Locked session 상태는 Windows만으로 확인 불가하다. 이 후속 81초를 독립적인 USB 없는 잠금 trial이나 30분 완료 시험으로 집계하지 않는다.
- 실행 파일은 `artifacts/MotionCue-win-x64/MotionCue.Windows.exe`. SHA256은 manifest와 같은 `1CAD098FACA729E7BBB3B5F5B4B6EC77E3C65D5D8E2898896B9CD75CE9817338`이다. Manifest source는 `8766ff0b399589d5dbd1f7f11e38391f5d6a61af`, `WorktreeDirty=true`, build UTC `2026-10-04T09:44:27.9191777Z`, `RuntimeValidated=false`다. clean `18383f6` 빌드라는 주장은 하지 않는다. 현재 스트림을 보존해 재빌드·재실행·재연결하지 않았다. 다음 통제된 trial 전에 clean revision으로 재빌드한다.

다음은 iPhone Details의 **Locked session state / Frames / elapsed**와 Mac runtime 종료 로그를 대조하여 45,000-frame 완료 또는 종료 이유를 확인하는 것이다. Windows 누적 accepted와 iPhone 작업 Frames는 계수 범위가 다르다. 이후 새 세션 반복 잠금·Stop·OS 취소와 지연 분리 측정을 수행한다.

변경·검증은 [개발 로그](development-log.md), 공통 gate는 [준비 기준](pre-field-test-readiness.md), 물리 절차는 [잠금 시험 안내](bench-ios-build4-lock-session.md)에 기록한다.
