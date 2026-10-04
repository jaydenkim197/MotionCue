# Windows reception / iPhone build 3 bench — 2026-10-04

상태: foreground 수신/잠금 중 수신 중단 `VERIFIED`; 해제 후 복구 관찰 진행 중

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

해제 뒤 사용자는 MotionCue foreground 복귀만 하고 Scan/Connect/Calibrate는 누르지 않도록 안내했다. 자동 복구, 새 프레임과 누적 max는 확인 대기다.

Windows live 통계는 메모리 자료다. iPhone runtime JSONL은 Mac에서 `tools/collect-ios-runtime-logs.sh`로 회수해 이 시간 구간과 대조한다.
