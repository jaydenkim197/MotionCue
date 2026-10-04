# Windows reception / iPhone build 3 bench — 2026-10-04

상태: foreground 수신/잠금 중 수신 중단/foreground 자동 복구 `VERIFIED`; G1 전체 미완료

## 장비와 소스

- iPhone 16 Pro: 0.2.0/build 3 설치·실행·약 25 Hz enqueue는 Mac 기록과 사용자 확인에 근거한다.
- Windows 11 Home 10.0.26300, Intel Wireless Bluetooth, MotionCue 0.2.0 pilot.
- Windows EXE SHA256: `1CAD098FACA729E7BBB3B5F5B4B6EC77E3C65D5D8E2898896B9CD75CE9817338`.
- Windows EXE는 2026-10-04 18:44 KST UI 단순화 변경으로 빌드한 기존 실행본이다. source manifest `8766ff0` + 당시 tracked UI 변경이며, 최종 Windows code는 `e76845b`와 같다. 새 GitHub `16487ba`까지의 `src/`, `tests/`, Windows release helper 변경이 없음을 `git diff --quiet`로 확인했다. 이번 측정은 재빌드·재시작 없이 기존 연결을 유지했다.
- 송수신 wire format과 Windows 0.20 s smoothing은 변경하지 않았다.
- 디자인 ZIP은 로컬에만 보존하며 업로드하지 않는다.

## 초기 상태와 foreground 복구

21:13~21:14 KST 초기 진단:

- BLE `Subscribed`, source/watchdog `Disconnected`, cue invisible, timeout 상태.
- accepted/missing/rejected `50991 / 0 / 0`.
- 이전 window p50/p95 `59.2 / 60.4 ms`, 누적 max `3873.6 ms`.
- 마지막 진단 sample timestamp `21:01:46.298 KST`.

이는 앱 실행 전체의 누적 snapshot이며 최신 build 3의 통제된 표본만을 뜻하지 않는다. 사용자가 iPhone foreground/보정/USB 분리 준비 완료를 알린 뒤 Windows에서 `SensorFrame stream restored`, `Ready`, `Streaming`을 확인했다. 이 복구에는 Windows Disconnect/Connect 또는 앱 재시작을 하지 않았다.

## Foreground 수신 표본

사용자에게 iPhone 앱을 화면에 유지하도록 안내하고 다음 두 snapshot을 직접 읽었다.

| 항목 | 시작 | 종료 |
|---|---|---|
| Windows 관찰 시각 KST | 21:14:33.681 | 21:15:20.982 |
| accepted | 52395 | 53577 |
| missing / rejected | 0 / 0 | 0 / 0 |
| p50 / p95 (ms) | 58.1 / 60.5 | 58.2 / 61.1 |
| 최근 interval window | 1500 | 1500 |
| 누적 max (ms) | 3873.6 | 3873.6 |
| jitter SD (ms) | 28.4 | 30.2 |
| source / watchdog | Ready / Streaming | Ready / Streaming |
| sender sample interval | 40 ms | 40 ms |

관찰 간격 **47.301초**, accepted 증가 **1182개**, 실제 평균 수신률 **24.9889 Hz**. Missing/rejected 증가는 0이고 누적 max도 증가하지 않았다.

### 해석

- 이 표본에서 Windows는 nominal 25 Hz에 해당하는 프레임 수를 수신했다.
- Median 수신 간격 58.2 ms의 역수로 수신률을 계산하면 잘못 해석할 수 있다. 불균등·묶음 전달에서는 평균 처리량과 median 간격이 다를 수 있다.
- BLE scheduling/notification batching은 후보 설명이며 개별 간격 분포·OS tracing 없이 원인으로 확정하지 않는다.
- iPhone enqueue 통계는 Mac에서 20:28~20:30에 측정했고 이 Windows 표본은 21:14~21:15다. 동시에 기록한 동일 구간의 sender/receiver pairing은 아직 아니다.
- 수신 spacing은 sensor-to-display 또는 one-way latency가 아니다. 사용자가 느끼는 cue 지연에는 별도 0.20 s smoothing도 기여할 수 있다.
- 기존 G1 median 35–50 ms 임시 기준은 충족하지 않지만, throughput은 정상이다. 기준의 적절성은 개별 간격과 사용자 반응 측정 후 별도 결정하고 사후에 조용히 바꾸지 않는다.
- 약 47초의 endpoint 표본은 30분 연속성, 프레임별 순간 중단, 방향 정확성 또는 G1 전체 통과 증거가 아니다.

## 60초 잠금 시험

진행 조건: USB 분리, iPhone foreground에서 정상 수신 확인 후 사용자 직접 측면 버튼 잠금. 사용자 잠금 확인을 받은 뒤 60초 동안 Windows를 관찰하고 해제를 요청한다. iPhone 물리 상태는 사용자 확인에 근거한다.

사용자 잠금 확인 후 처음 관찰한 시각은 **21:16:31.670 KST**, 해제 요청 전 마지막 관찰은 **21:17:53.731 KST**로 **82.061초** 차이다. 목표 60초를 넘겨 유지한 시험이며 정확히 60.000초 lock duration으로 표현하지 않는다. 실제 버튼을 누른 시점·USB 상태는 사용자 확인에 근거하고 OS event와 동기화하지 않았다.

Windows 창이 가려진 상태의 초기 accessibility 결과에 이전 값이 남아 있어, 전면 활성화 후 screenshot과 새 text를 대조했다. 잠금 직후 정확한 cessation latency는 이 방법으로 측정하지 않았다.

| 항목 | 21:17:14.100 KST | 21:17:53.731 KST |
|---|---|---|
| BLE | Subscribed | Subscribed |
| accepted / missing / rejected | 54194 / 0 / 0 | 54194 / 0 / 0 |
| source / watchdog | Disconnected / Disconnected | Disconnected / Disconnected |
| state | SensorFrame stream timed out | SensorFrame stream timed out |
| cue visible | False | False |
| motion offsets | zero | zero |
| p50 / p95 (ms) | 58.1 / 61.1 | 58.1 / 61.1 |
| cumulative max (ms) | 3873.6 | 3873.6 |

결과: BLE 구독과 실제 센서 스트림은 별개이며, 잠금 중 구독이 유지되더라도 새 프레임은 수신되지 않았다. Windows는 timeout 상태에서 큐를 숨기고 모션 offset을 0으로 만들었다. 정확한 250 ms/1 s 전환 시간은 이 snapshot 시험으로 측정하지 않았다.

해제 뒤 사용자는 MotionCue foreground 복귀만 하고 Scan/Connect/Calibrate는 누르지 않도록 안내했다. 아래 후속 관찰에서 자동 복구를 확인했다.

## 잠금 해제 후 자동 복구 — 21:34~21:36 KST

- 사용자 `해제됨` 확인 후 Windows screenshot에서 `SensorFrame stream restored`, Diagnostics에서 `Ready / Subscribed / Streaming`, cue visible을 확인했다.
- 수신 중단 당시 accepted **54194**에서 최초 복구 관찰 **54868**로 증가했다. Windows에서 Scan/Connect/Calibrate, 앱 재실행 또는 연결 초기화는 수행하지 않았다.
- 누적 max는 **1125403.4 ms (약 18분 45.4초)**로 증가했다. 사용자는 화면을 보지 않아 해제 응답이 늦었다고 확인했다. 이 값은 시험 도중 길어진 수신 중단 구간이며 잠금 해제 후 복구 latency나 일반 BLE 지연이 아니다. 목표 60초 시험을 정확한 60초 lock trial로 사용하지 않는다.
- 실제 unlock 버튼 시각과 최초 새 프레임 시각을 동기화하지 않아 recovery latency는 미측정이다. iPhone runtime lifecycle 로그와 대조하면 active 전환과 송신 재개 구간을 추가 분석할 수 있다.

| 항목 | 복구 후 시작 | 복구 후 종료 |
|---|---|---|
| 진단 수신 timestamp KST | 21:35:14.1255161 | 21:36:27.1406626 |
| accepted | 55275 | 57100 |
| missing / rejected | 0 / 0 | 0 / 0 |
| p50 / p95 (ms) | 58.6 / 60.7 | 58.1 / 60.6 |
| source / watchdog | Ready / Streaming | Ready / Streaming |
| sender sample interval | 40 ms | 40 ms |

진단의 실제 Windows reception timestamp 차이 **73.015초**, accepted 증가 **1825개**, 수신률 **24.9949 Hz**. 접근성 snapshot이 창이 가려지면 지연될 수 있으므로 이 후속 계산은 조회 wall time 대신 두 진단의 receipt timestamp를 사용했다. 이는 같은 Windows 시계 기반의 throughput이며 phone-to-PC latency 측정이 아니다.

복구 직후 최근 interval window에 긴 공백이 포함되어 jitter SD가 **29047.1 ms**까지 커졌지만 새 프레임으로 window가 교체된 뒤 **27.8 ms**로 내려갔다. 누적 max는 그대로 유지된다. 의도한 잠금/대기 구간과 정상 foreground window를 분리해 해석해야 한다.

### 최종 판단과 Mac 후속 작업

1. 정상 foreground 수신은 약 25 Hz다.
2. 잠금 중 BLE 구독은 유지되지만 continuous sensor stream은 멈춘다.
3. 잠금 해제 후 foreground 복귀 시 기존 구독으로 수신·cue가 자동 재개된다.
4. 잠금 연속 송신과 정확한 resume latency는 이번 시험으로 해결·입증되지 않았다.

Mac에서는 Git pull 후 `tools/collect-ios-runtime-logs.sh`로 build 3의 MotionCue runtime JSONL을 회수해 **21:15~21:36 KST** lifecycle/runtimeGap/summary를 대조한다. 사용자 응답 대기로 길어진 구간은 일반 성능 공백과 분리한다. 원본 runtime 파일은 ignored artifacts에 보존하고 파생 결과만 development log에 남긴다.

Windows live 통계는 메모리 자료다. iPhone runtime JSONL은 Mac에서 `tools/collect-ios-runtime-logs.sh`로 회수해 이 시간 구간과 대조한다.
