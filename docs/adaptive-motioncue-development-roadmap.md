# MotionCue AI/CV 개발 방향 및 1~2학기 실행 로드맵

문서 상태: `PROPOSAL`  
작성일: 2026-09-03  
적용 범위: MotionCue Windows 앱, iPhone 센서 앱, 학부논문 확장 방향

> 이 문서는 후보를 비교하고 권장안을 제안한다. 아직 기존 연구 프로토콜을 대체하는 확정 결정은 아니다. 실제 참가자 모집 전 지도교수 협의, 연구 승인 범주 확인, 파일럿 결과를 거쳐 범위를 고정한다.

## 1. 결론

1~2학기 안에 가장 현실적으로 완성할 수 있으면서 기존 MotionCue보다 연구 기여를 강화하는 방향은 다음과 같다.

> **노트북 내장 카메라로 사용자의 거친 시각 주의 상태를 추정하고, 차량 동기화 모션 큐의 방향 정보는 유지하면서 표시 위치와 시각적 강도만 조절하는 Attention-Aware Adaptive MotionCue**

이 방향을 선택하는 이유는 다음과 같다.

- 새 하드웨어, 차량 API, CAN, 웨어러블 또는 클라우드가 필요 없다.
- 이미 구현된 `iPhone IMU → BLE → Windows estimator → peripheral cue` 경로를 그대로 사용한다.
- 이찬수 교수의 컴퓨터비전·인간 시각 연구 분야와 직접 연결된다.
- 정밀한 eye tracker나 자체 딥러닝 학습 데이터 없이도 사전학습된 얼굴·눈 특징 모델로 구현할 수 있다.
- `Fixed Synchronized Cue`와 `Attention-Adaptive Synchronized Cue`의 차이를 명확하게 통제할 수 있다.
- 주 기여를 멀미 진단이 아니라 **효과–방해성 균형 개선**으로 제한해 30명 규모 학부 연구에서 과장된 주장을 피할 수 있다.

권장 일정은 **2학기 트랙**이다. 1학기 안에 반드시 끝내야 한다면 적응형 기능을 주 효과 조건으로 넣지 않고 카메라 기반 주의 상태를 관찰 지표로만 수집하는 축소안을 사용한다.

## 2. 현재 출발점

### 구현·실기기 확인 완료

- Windows 11 WPF 시스템 트레이 앱과 클릭스루 주변시 점 오버레이
- SensorFrame v1 디코딩과 source-independent motion pipeline
- iPhone 16 Pro의 Core Motion 50 Hz 수집 및 BLE 약 25 Hz 송신
- iPhone BLE Peripheral과 Windows BLE Central의 실기기 연결·구독
- 차량축 estimator, smoothing, dead zone, gain, saturation 및 stale-data fail-safe
- 개발자용 가상 SensorFrame replay와 dropout 검증
- Research Session, FMS 입력, event marker, 익명 CSV 및 긴급 정지
- `No Cue / Static Visual Control / Synchronized Cue` 연구 조건
- Windows와 iOS의 공통 MotionCue 디자인 시스템

### 아직 필요한 기본 검증

- 실제 차량에서 가속·제동·좌회전·우회전 축 부호와 큐 방향 검증
- sensor event부터 화면 cue까지의 종단간 지연, 지터, 손실 및 재연결 측정
- iPhone 잠금·백그라운드 상태의 연속 송신 또는 자동 복구 실측
- 차량 거치 방식, 노선, 세션 시간 및 안전 중단 규칙 확정
- Study B용 과업, 설문, 데이터 관리 및 연구 승인 범주 확정

AI/CV 확장은 이 기본 검증을 대체하지 않는다. 기본 동기화 경로가 불안정하면 적응형 조건의 결과도 해석할 수 없다.

## 3. 제품·연구 원칙

1. **추가 하드웨어 없음**: 센서폰과 노트북 내장 카메라까지만 사용한다.
2. **로컬 처리**: 영상, IMU 및 파생 특징을 클라우드로 보내지 않는다.
3. **원본 얼굴 영상 비저장 기본값**: 연구 로그에는 시각 주의 상태와 신뢰도 등 파생값만 기록한다.
4. **Fail-safe 우선**: 얼굴을 찾지 못하거나 모델 신뢰도가 낮으면 고정형 동기화 큐로 즉시 복귀한다.
5. **모션 의미 보존**: 적응 정책은 큐가 표현하는 움직임의 방향과 타이밍을 바꾸지 않는다.
6. **설명 가능한 정책**: 본 연구에서는 온라인 학습이나 블랙박스 제어보다 사전 고정된 규칙 기반 정책을 사용한다.
7. **의료 주장 배제**: 멀미를 진단·치료한다고 표현하지 않고 실험 조건에서의 불편과 방해성을 평가한다.
8. **기존 v1 완성 우선**: 실제 차량 신호 검증과 BLE 측정이 적응형 기능보다 선행한다.

## 4. 후보 방향 비교

점수는 현재 인력 1명, 참가자 약 30명, 기존 장비, 1~2학기라는 조건을 기준으로 한 상대 평가다. 5점이 가장 유리하다.

| 후보 | 연구 차별성 | 구현 가능성 | 30명 데이터 적합성 | 제품 UX 적합성 | 판단 |
|---|---:|---:|---:|---:|---|
| 거친 시각 주의 기반 적응형 큐 | 5 | 4 | 5 | 5 | **본 논문 권장** |
| 화면 saliency 기반 큐 배치 | 4 | 3 | 5 | 4 | 주의 적응 성공 후 확장 |
| 개인별 cue parameter 최적화 | 5 | 3 | 2 | 5 | 후속 연구 권장 |
| 얼굴 행동 기반 불편 위험 추정 | 5 | 3 | 2 | 4 | 보조 특징 또는 후속 연구 |
| webcam rPPG | 5 | 2 | 2 | 4 | 차량 진동·조명 feasibility부터 |
| 작업 종류 자동 인식 | 3 | 4 | 4 | 4 | v2 제품 기능 후보 |
| 자동 거치·연속 재교정 | 4 | 3 | 4 | 5 | 제품성이 높지만 별도 연구축 |
| 차량 연동·전방 카메라·웨어러블 | 4 | 1 | 2 | 1 | 현재 범위 제외 |

### 제외 또는 후순위로 둔 이유

- **멀미 예측 ML**: 30명과 각 3회 수준의 자료는 개인 독립적인 예측 모델을 학습·검증하기에 작다. 참가자별 여러 시점 자료를 독립 표본처럼 취급하면 데이터 누수 위험이 크다.
- **실시간 개인화**: 적응 정책 자체와 개인화 효과가 동시에 변하면 어떤 요소가 결과를 만들었는지 해석하기 어렵다.
- **rPPG**: 차량 진동, 얼굴 움직임, 주야간 조명 변화가 신호 품질을 크게 저하시킬 수 있다. 이것만으로 별도 feasibility 연구가 필요하다.
- **정밀 gaze 좌표**: 일반 웹캠과 자유로운 노트북 자세에서 픽셀 단위 정확도를 주장하기 어렵다. 본 연구에는 거친 영역 분류가 충분하다.
- **head pose 단독 사용**: 노트북이 무릎이나 테이블 위에 놓일 때 카메라와 머리의 상대 위치가 크게 달라진다. 시선 추정의 보조값으로만 사용한다.
- **화면 내용 분석**: 개인정보와 화면 캡처 위험이 생긴다. 첫 연구에서는 사용하지 않는다.
- **딥러닝 모델 자체 개발**: 데이터 수집·라벨링·검증이 학부논문 범위를 초과한다. 사전학습 모델을 이용한 시스템·HCI 기여에 집중한다.

## 5. 권장 시스템: Attention-Aware Adaptive MotionCue

### 5.1 연구 개념

```text
iPhone IMU
   ↓ BLE SensorFrame
Vehicle-motion estimator ───────────────┐
                                        ↓
Laptop webcam → visual-attention state → deterministic adaptation policy
                                        ↓
                         peripheral cue presentation
```

카메라 모듈은 사용자를 식별하지 않는다. 다음과 같은 낮은 해상도의 상태만 출력한다.

- `Center`
- `Left`
- `Right`
- `OffScreen`
- `Unavailable`
- `confidence` 0~1

초기 버전은 좌·중앙·우와 화면 이탈만 사용한다. 상·중·하 3단계를 추가한 3×3 영역은 파일럿에서 안정성이 확인될 때만 활성화한다.

### 5.2 적응 정책

적응 정책은 다음을 지킨다.

- 차량 움직임에서 계산된 큐의 **방향, onset 및 시간 변화**는 고정형 조건과 동일하다.
- 사용자가 보고 있는 가장 가까운 화면 가장자리의 cue opacity 또는 dot count를 부드럽게 낮춘다.
- 필요하면 남은 가장자리에 제한된 범위 안에서 salience를 재분배한다.
- 갑작스러운 깜박임을 막기 위해 attention state에 hysteresis와 attack/release smoothing을 적용한다.
- 신뢰도가 임계값보다 낮거나 얼굴이 일정 시간 보이지 않으면 `Fixed Synchronized Cue`로 복귀한다.
- 연구 시작 전에 모든 임계값과 조절 범위를 고정하고 세션 중 학습하지 않는다.

이 구조는 “AI가 멀미를 판단한다”는 주장이 아니다. AI/CV는 시각 주의 상태를 추정하고, 설명 가능한 controller가 그 결과로 cue salience를 조절한다.

### 5.3 구현 경계

권장 컴포넌트는 다음과 같다.

```text
CameraFrameSource
  → VisualAttentionEstimator
  → AttentionStateFilter
  → CueAdaptationPolicy
  → CuePresentationEngine
  → ResearchLogger
```

우선순위 구현안:

1. **선호안**: .NET에서 ONNX Runtime 또는 검증된 로컬 CV runtime을 사용해 Windows 프로세스 안에서 추론한다.
2. **2주 기술 스파이크 실패 시 fallback**: 로컬 Python CV sidecar와 named pipe를 사용한다. 영상 프레임은 프로세스 밖이나 디스크로 보내지 않고 파생 상태만 WPF에 전달한다.

Python fallback은 연구 프로토타입을 빨리 완성할 수 있지만 설치·배포가 복잡해진다. 최종 배포 단순성이 중요하므로 먼저 C# 단일 프로세스 가능성을 확인한다.

### 5.4 로그 스키마 추가안

원본 이미지 대신 다음 파생 필드만 연구 CSV에 추가한다.

- `CameraEnabled`
- `FaceAvailable`
- `AttentionRegion`
- `AttentionConfidence`
- `EstimatorLatencyMs`
- `AdaptationMode`
- `LeftCueWeight`
- `RightCueWeight`
- `TopCueWeight`
- `BottomCueWeight`
- `FallbackReason`

개인 식별용 얼굴 embedding, screenshot, raw video, 음성은 저장하지 않는다.

## 6. 연구 질문과 예상 기여

### 권장 연구 질문

- **RQ1**: 일반적인 노트북 자세와 조명에서 내장 카메라 기반 모델이 실시간 cue adaptation에 충분한 거친 시각 주의 상태를 얼마나 안정적으로 추정하는가?
- **RQ2**: Attention-Adaptive Synchronized Cue는 Fixed Synchronized Cue보다 주관적 시각 방해를 줄이고 노트북 과업 수행을 유지하는가?
- **RQ3**: Attention-Adaptive Synchronized Cue는 Fixed Synchronized Cue가 보이는 motion-discomfort 결과를 심각하게 훼손하지 않는가?

### 주장 가능한 기여

1. 스마트폰 IMU와 노트북 카메라를 결합하지만 추가 하드웨어와 클라우드를 요구하지 않는 승객용 적응형 인터페이스
2. 모션 정보의 의미와 gaze 기반 salience 조절을 분리한 설명 가능한 cue controller
3. 카메라 실패 시 고정형 cue로 복귀하는 privacy-aware, fail-safe 설계
4. 실제 차량에서 fixed/adaptive cue의 불편–방해성 trade-off를 평가한 탐색적 증거

### 주장하지 않을 내용

- 30명 자료로 일반화 가능한 멀미 예측 AI를 학습했다는 주장
- 의료적 진단, 예방 또는 치료 효과
- 일반 웹캠이 전문 eye tracker와 같은 정밀도를 가진다는 주장
- adaptive condition의 FMS 차이가 유의하지 않다는 사실만으로 동등성 또는 비열등성을 입증했다는 주장

## 7. 권장 실험 구조

### 7.1 카메라 기술 검증

차량 실험 전에 화면 표적 과업으로 별도 검증한다.

- 화면 좌·중앙·우 표적을 무작위 순서로 표시
- 정상 조명, 어두운 조명, 안경 여부 및 대표적인 노트북 각도 포함
- region accuracy, macro-F1, confusion matrix, unavailable 비율 측정
- camera capture부터 `AttentionState` 출력까지 median/p95 latency 측정
- CPU·메모리·frame drop과 MotionCue overlay frame time 동시 측정
- 얼굴을 잃었을 때 fixed cue fallback까지 걸린 시간 측정

합격 기준 수치는 구현 결과를 본 뒤 유리하게 바꾸지 않도록 파일럿 전에 고정한다.

### 7.2 2학기 권장 본 실험

현재 3회 방문·참여자 30명·회당 10,000 KRW 예산을 유지하려면 다음 세 조건이 가장 현실적이다.

1. `No Cue`
2. `Fixed Synchronized Cue`
3. `Attention-Adaptive Synchronized Cue`

이 안은 기존 `Static Visual Control`을 본 효과 실험에서 제외한다. 정적 시각 요소 통제의 가치가 사라지는 것은 아니지만, 네 조건을 서로 다른 날 실시하면 방문이 120회, 사례비가 최대 1,200,000 KRW로 늘고 일정과 탈락 위험도 증가한다.

따라서 선택지는 다음과 같다.

- **권장**: 3회 방문을 유지하고 AI/CV 핵심 비교에 집중한다.
- **대안**: 예산·일정이 늘어날 때만 `No / Static / Fixed / Adaptive` 네 조건을 서로 다른 날 실시한다.
- **비권장**: 한 방문 안에 여러 차량 조건을 짧게 연속 실시한다. 잔류 멀미와 회복 시간 때문에 조건 간 오염을 해석하기 어렵다.

기존 `Static Visual Control` 구현은 삭제하지 않고 소프트웨어 회귀 검증, 파일럿 또는 별도 후속 연구에 보존한다. 본 실험 조건 변경은 지도교수 협의 후 별도로 확정한다.

### 7.3 결과 지표 우선순위

적응형 확장의 1차 비교는 `Fixed` 대 `Adaptive`의 시각 방해성 및 과업 수행이다.

- 주관적 cue distraction/annoyance
- 읽기·이해 과업 정확도와 완료 시간
- Raw NASA-TLX 또는 사전 확정한 workload 척도
- FMS AUC, peak 및 시간 기울기
- 카메라 valid-state 비율과 fallback 횟수
- cue가 실제로 조절된 시간 비율과 조절 강도

FMS는 계속 중요한 결과이지만, 30명 탐색 연구에서 “효과를 유지했다”는 결론은 효과크기와 신뢰구간을 중심으로 조심스럽게 해석한다.

## 8. 학기별 실행안

### A안 — 1학기 내 종료하는 안전한 축소안

목표: 현재 v1의 효과 연구를 완성하고 카메라 분석은 탐색적 관찰로 제한한다.

| 기간 | 작업 |
|---|---|
| 1~2주 | 실제 차량 축·방향·BLE·background 검증, open decision 고정 |
| 3~4주 | 카메라 capture와 얼굴/눈 특징 추출 기술 스파이크 |
| 5~6주 | 원본 영상 비저장 attention logging, 실험 CSV 통합 |
| 7주 | 6~10명 절차 파일럿과 실패 조건 수정 |
| 8~12주 | 기존 `No / Static / Synchronized` 3조건 자료 수집 |
| 13~14주 | 통계 분석과 탐색적 attention–distraction 관계 분석 |
| 15주 | 논문 완성, 재현 자료와 한계 정리 |

장점은 완주 가능성이 가장 높다는 점이다. 단점은 gaze가 실시간 cue를 바꾸지 않으므로 AI/CV 기여가 보조 분석에 머문다는 점이다.

### B안 — 2학기 권장안

#### 1학기: 시스템·파일럿

| 기간 | 작업 |
|---|---|
| 1~2주 | v1 차량 검증, 연구 질문과 privacy boundary 확정 |
| 3~4주 | .NET CV 기술 스파이크, 모델·라이선스·성능 비교 |
| 5~6주 | `VisualAttentionEstimator`와 기술 검증 도구 구현 |
| 7~8주 | smoothing, confidence gate 및 fixed-cue fallback 구현 |
| 9~10주 | `CueAdaptationPolicy`, UI toggle, 로그 스키마 통합 |
| 11~12주 | replay·카메라 부하·장애 주입·성능 테스트 |
| 13~15주 | 6~10명 파일럿, threshold 고정, 본 실험 프로토콜 동결 |

#### 2학기: 본 실험·논문

| 기간 | 작업 |
|---|---|
| 1~2주 | 연구 승인 범주·동의서·안전 절차 최종 확인, 사전등록 |
| 3~9주 | 30명 × 3조건 자료 수집과 품질 점검 |
| 10~11주 | 혼합효과모형, 효과크기·신뢰구간, 결측·중단 분석 |
| 12~13주 | 시스템·방법·결과·논의 작성 및 그림 제작 |
| 14주 | 재현성 점검, 익명 데이터 사전 및 artifact 정리 |
| 15주 | 지도교수 피드백 반영과 최종본 완성 |

## 9. 범위 통제와 중단 기준

다음 규칙을 지켜야 2학기 안에 끝낼 가능성이 높다.

- 본 논문에서 새로 구현할 연구 기능은 `VisualAttentionEstimator + CueAdaptationPolicy` 하나로 제한한다.
- 개인화, rPPG, 표정 기반 불편 추정, saliency 및 task recognition을 동시에 구현하지 않는다.
- 사전학습 모델의 fine-tuning용 얼굴 데이터셋을 새로 수집하지 않는다.
- 카메라 estimator가 기술 검증에서 합격 기준을 충족하지 못하면 adaptive condition을 중단하고 1학기 축소안으로 복귀한다.
- 실제 차량 v1 지연·방향 검증이 끝나기 전 본 참가자 모집을 시작하지 않는다.
- 파일럿 뒤에는 버그 수정 외에 cue policy를 계속 조정하지 않는다.
- 참여자 자료를 본 뒤 가설, 제외 기준 또는 1차 결과를 바꾸지 않는다.

## 10. 연구 승인·프라이버시 영향

카메라를 추가하면 현재의 IMU-only 연구보다 참여자 설명과 데이터 관리 요구가 커진다. 연구 심의 상태는 계속 `TBD`로 둘 수 있지만 다음은 모집 전 필수 gate다.

- 학교 또는 지도교수에게 정식 심의, 심의면제 신청, 별도 절차 불필요 중 어느 범주인지 확인
- 카메라가 켜지는 시점, 처리 목적, 저장하지 않는 항목과 저장하는 파생값을 동의서에 명시
- Windows camera permission 거부 시 처리와 참가자 철회 절차 명시
- 디버깅용 raw video가 꼭 필요하면 본 연구 로그와 분리하고 별도 동의·암호화·보존기간·파기일을 정의
- 얼굴 인식, 신원 추정 또는 emotion diagnosis 기능은 범위에서 제외

“원본 영상을 저장하지 않는다”는 사실만으로 사람 대상 연구 검토가 자동 면제되는 것은 아니다.

## 11. 후속 로드맵

### MotionCue v1 — 현재 기반 완성

Phone IMU → BLE → vehicle-motion estimator → fixed synchronized cue

### MotionCue v1.5 — 본 학부논문 권장

Phone IMU + coarse visual attention → privacy-aware adaptive cue salience

### MotionCue v2 — 개인화

MSSQ, 이전 FMS, distraction, task performance를 이용한 개인별 cue parameter 추천. 작은 자료에서는 회귀, 계층모형 또는 Bayesian optimization을 우선하고 딥러닝은 사용하지 않는다.

### MotionCue v2.5 — 사용자 상태 탐색

blink, eye closure, facial behavior 및 rPPG 품질을 각각 feasibility study로 검증한다. motion-discomfort risk score는 충분한 독립 참가자 데이터가 확보된 뒤 개발한다.

### MotionCue v3 — closed-loop multimodal system

Vehicle state + user state + history → adaptive controller → user response feedback

선박용 USB IMU, 해군 함정, 차량 API, 전방 도로 영상, wearable은 별도의 장기 연구축으로 유지한다.

## 12. 바로 시작할 수 있는 차량 비필수 작업

1. `VisualAttentionEstimator` 인터페이스와 `AttentionState` 데이터 구조 정의
2. 대상 Windows laptop의 webcam 해상도·FPS·CPU baseline 측정
3. C#/.NET에서 후보 사전학습 모델 1~2개의 라이선스와 추론 속도 spike
4. 좌·중앙·우 표적을 표시하고 ground truth를 기록하는 camera validation tool 제작
5. raw video를 저장하지 않는 derived-feature CSV schema 추가
6. fixed-cue fallback, camera permission denial 및 camera disconnect 테스트 작성
7. adaptive cue 정책의 허용 parameter와 변경 금지 parameter를 문서로 고정
8. 파일럿 전 go/no-go 기준과 분석 계획 작성

## 13. 최종 권고

논문의 강도를 높이기 위해 여러 AI 기능을 얹는 것보다 다음 한 문장을 실제로 입증하는 편이 낫다.

> MotionCue combines smartphone inertial sensing with privacy-preserving, laptop-camera-based visual-attention estimation to adapt peripheral motion cues while preserving their vehicle-synchronized motion information.

따라서 **2학기 B안**을 최종 추천한다. 첫 학기에는 v1의 실제 차량 검증과 coarse attention-adaptive prototype을 끝내고, 두 번째 학기에는 `No Cue / Fixed Synchronized / Attention-Adaptive Synchronized` 세 조건으로 30명 반복측정 연구를 수행한다.

개인화, 얼굴 기반 불편 예측 및 rPPG는 논문의 “Future Work”가 아니라 각각 독립적인 후속 연구 후보로 남긴다. 이 범위가 현재 장비, 인력, 예산과 지도 분야를 함께 만족시키는 가장 현실적인 경계다.
