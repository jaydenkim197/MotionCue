# MotionCue 연구·논문 계획

## 1. 연구 포지셔닝

MotionCue의 논문 가치는 단순히 Apple과 유사한 점 오버레이를 Windows에 구현했다는 데 있지 않다. 핵심 연구 질문은 다음과 같다.

> Android 또는 iPhone의 차량 동기화 IMU 신호를 무선으로 수신하는 Windows 노트북의 주변시 모션 큐가, 차량 이동 중 노트북 작업의 멀미 불편을 줄이면서 작업 수행과 주의 집중을 유지할 수 있는가?

직접적으로 유사한 2026년 국내 연구는 실제 버스에서 iPhone의 IMU 기반 시각적 모션 큐를 사용해 모션 큐 없음, 흑백, 빨강 조건을 비교했다. 따라서 본 연구가 단순히 색상이나 모션 큐 유무만 반복하면 신규성이 약하다. MotionCue는 다음의 차별점에 집중한다.

1. 스마트폰 센서를 사용하지만 자극은 Windows 노트북 전체 화면에 제공되는 시스템 전역 오버레이
2. Android와 iPhone을 하나의 SensorFrame으로 정규화하는 교차 플랫폼 무선 센서 브리지
3. BLE 기반 무선 센서 브리지의 지연, 손실, 재연결 및 연결 실패 안전성 평가
4. 큰 화면에서 문서 읽기·영상·업무를 수행하는 실제 사용 맥락
5. 좌표를 전송·저장하지 않는 로컬·프라이버시 중심 설계

## 2. 가제

영문:

> MotionCue: Design and Evaluation of Wireless Smartphone-Synchronized Peripheral Visual Motion Cues for Laptop Passengers

국문:

> 이동 차량 내 노트북 승객을 위한 무선 스마트폰 동기화 주변시 모션 큐 시스템의 설계 및 효과 평가

## 2.1 논문 기본 정보

- 저자: Jayden Kim
- 소속: Department of Electronic Engineering, Yeungnam University
- 문서 유형: English undergraduate thesis
- 지도교수: Professor Chan-Su Lee, Department of Electronic Engineering, Yeungnam University
- 목표 제출: 2026년 말
- 목표 참여자: 20대 초중반 남녀 30명
- 사례비: 10,000 KRW per visit; 3 visits per participant; maximum 900,000 KRW for 30 completed participants
- 1차 플랫폼: Windows laptop + Android/iPhone sensor companion
- Study A 기기: Samsung Galaxy A50 with Android 11 and iPhone 16 Pro with the latest stable iOS available on the test date; the initial baselines are `SM-A505N / A505NKSS6DWB1` and `iOS 26.6 / 23G71`, subject to on-device verification and later stable updates
- Study B 표준 센서폰: iPhone 16 Pro; 2026-08-20 현재 실기기 즉시 사용 가능
- MacBook Air M1: 현재 iOS 개발에 즉시 사용 가능; macOS 효과 실험은 후속 연구로 분리

## 3. 예상 학술적 기여

1. Android와 iPhone 센서를 동일한 무선 프로토콜로 Windows에 연결하는 주변시 모션 큐 시스템을 제시한다.
2. BLE 센서 브리지의 지연, 지터, 패킷 손실, 재연결 및 안전 중립화 특성을 측정한다.
3. 정적 점 자체의 효과와 실제 차량 동기화 정보의 효과를 `No Cue / Static Visual Control / Synchronized Cue`로 분리해 평가한다.
4. 실제 차량에서 동기화 큐가 멀미의 시간적 증가, 작업 정확도, 정신적 작업부하, 시각적 방해에 미치는 영향을 평가한다.
5. 위치 권한 없는 센서 처리, 휴대폰 거치 방향 교정 및 노트북 화면 설계에 대한 재현 가능한 지침을 제시한다.

의학적 치료 효과나 Apple 기능과의 동등성을 주장하지 않는다.

## 4. 연구 질문과 가설

### 공학적 평가

- RQ1. Android와 iPhone의 IMU 신호는 고정된 차량 좌표계에서 가속·감속·좌우 회전을 어느 정도 일관되게 표현하는가?
- RQ2. BLE는 큐 생성에 필요한 지연, 지터 및 패킷 손실 기준을 어느 정도 충족하는가?
- RQ3. 센서 데이터 중단 시 큐가 250 ms 안에 중립으로 복귀하고 1초 안에 연결 상실을 알리는가?
- RQ4. 화면 주사율 보간이 무선 센서 수신 주기와 분리되어 안정적인 시각 움직임을 제공하는가?

### 사용자 평가

- H1. Synchronized Cue는 No Cue보다 주행 중 Fast Motion Sickness Scale의 시간 누적값과 증가율을 낮출 것이다.
- H2. Synchronized Cue는 Static Visual Control보다 FMS 시간 누적값과 증가율을 낮출 것이다.
- H3. Static Visual Control과 No Cue의 차이가 작다면 점의 단순한 존재보다 차량 동기화 정보가 효과의 핵심임을 지지한다.
- H4. Synchronized Cue는 노트북 작업 정확도와 완료 시간을 유의하게 악화시키지 않을 것이다.
- H5. Synchronized Cue는 주관적 정신 작업부하와 시각적 방해를 유의하게 증가시키지 않을 것이다.
- H6. 평소 멀미 민감도가 높은 참여자에게 효과가 더 크게 나타날 수 있다. 이 항목은 상호작용 효과로 탐색한다.

## 5. 2단계 연구 설계

### Study A — 신호 및 시스템 검증

동일 차량에 다음을 장착한다.

- MotionCue가 실행되는 Windows 노트북
- 차량 전방 축으로 고정·교정된 Android 또는 iPhone
- BLE Sensor Bridge
- 가능하다면 차량 CAN/OBD 또는 별도 기준 IMU: 정답 기준 데이터

직선 가속, 제동, 일정 속도 좌·우회전, 정차 후 재출발 및 무선 통신 음영·강제 중단 구간을 반복한다. 평가 지표는 다음과 같다.

- Android와 iPhone 간 축·진폭 일치도
- 기준 IMU 대비 가속도 및 yaw-rate 오차
- 가속·감속·좌·우 회전 이벤트의 precision, recall, F1
- 이벤트 검출 지연
- 잘못된 큐 발생률
- BLE 종단간 지연의 중앙값과 95백분위수
- 패킷 손실률, 재연결 시간 및 중립 복귀 시간
- 프레임 시간, CPU, 메모리, 렌더링 누락률

현재의 정적 시뮬레이션은 이 단계의 회귀 테스트와 UI 검증에 사용한다. 시뮬레이션 결과만으로 멀미 완화 효과를 주장하지 않는다.

### Study B — 실제 차량 사용자 실험

권장 설계는 참여자 내 반복측정 교차설계다. 모든 참여자가 서로 다른 날 동일 좌석·동일 노선·유사 시간대에 다음 조건을 경험한다.

1. No Cue
2. Static Visual Control: 움직이지 않는 정적 점으로 시각 요소의 존재만 통제
3. Synchronized Cue: 스마트폰 IMU와 동기화된 점

조건 순서는 Latin square로 균형화한다. 세션은 서로 다른 날에 수행해 잔류 멀미와 적응 효과를 줄인다. 모든 참여자는 같은 연구용 Windows 노트북과 센서용 휴대폰을 사용해 기기 차이를 통제한다.

본 사용자 실험은 빌린 동일 승용차, 동일 운전자·노선·시간대, 오른쪽 뒷좌석을 기본 환경으로 한다. 참여자는 승객이며 운전하지 않는다. 대중교통은 Study A의 공학 검증 또는 후속 외적 타당성 파일럿으로 분리한다.

권장 과업은 실제 노트북 사용을 반영한 문서 읽기·이해 문항 또는 지속적 시각 탐색 과업이다. 영상만 시청하게 하면 작업 성능 기여를 보여주기 어렵다.

## 6. 참여자와 표본

- 파일럿: 6~10명으로 BLE 연결, 휴대폰 거치, 절차, 노선 강도, 탈락률과 효과크기 추정
- 본 실험 목표: 30명 완료
- 표본 수 30명은 학부논문의 현실적 파일럿·탐색 연구 범위로 명시하고, 작은 효과를 확증할 충분한 검정력은 주장하지 않는다.
- 파일럿 효과크기를 이용해 최종 분석 전 검정력과 불확실성을 다시 평가한다.
- MSSQ-Short로 평소 멀미 민감도를 사전 측정하되 극단값을 임의로 제외하기보다 공변량·층화 요인으로 다룬다.
- 성별, 연령, 시력, 전정기관 질환, 멀미약·음주·수면 상태 등의 기준을 사전에 정의한다.

연구 심의 상태는 현재 `TBD`다. 지금은 실제 참여자 연구를 시작하는 단계가 아니므로 신청 또는 면제 판단을 진행하지 않는다. 실제 모집 전에는 사전 동의, 언제든 중단할 권리, 명확한 안전 중단 기준과 회복 절차를 마련하고, 이찬수 교수 또는 학교 담당 부서에 정식 심의·심의면제 신청·별도 절차 불필요 중 무엇이 적용되는지 확인한 뒤 상태를 갱신한다.

공식 확인 자료: [영남대학교 생명윤리위원회(IRB) 심의안내](https://www.yu.ac.kr/rnd/community/notice.do?articleNo=185146&attachNo=35931&mode=fileDownload)

## 7. 측정 지표

### 1차 결과

- FMS 0~20: 매 1분 구두 응답
- 분석값: 세션 전체 AUC, 최고점, 시간에 따른 증가 기울기

### 2차 결과

- MSAQ: 세션 전후 멀미의 위장·중추·말초·sopite 차원
- MSSQ-Short: 개인별 기저 멀미 민감도
- 작업 정답률, 반응시간, 중도 포기율
- Raw NASA-TLX 또는 NASA-TLX: 정신적 작업부하
- 큐의 가시성, 방해성, 선호도, 지속 사용 의향
- 선택적 생리 지표: 심박/HRV 등. 핵심 결과가 아니라 탐색적 결과로 취급

## 8. 분석 계획

주요 분석은 반복측정 자료를 처리할 수 있는 혼합효과모형을 사용한다.

```text
FMS ~ Condition × Time + MSSQ + SessionOrder + (1 | Participant)
```

- 조건별 FMS AUC와 MSAQ 변화량을 비교한다.
- 작업 정확도와 반응시간은 별도 혼합모형으로 분석한다.
- 사후 비교는 다중비교 보정을 적용한다.
- p-value뿐 아니라 효과크기와 95% 신뢰구간을 보고한다.
- 결측과 안전 중단을 성공 사례에서 제외하지 말고 사전 정의한 방식으로 처리한다.
- 본 실험 전 연구 질문, 1차 지표, 제외 기준, 분석식을 사전등록한다.

## 9. 논문 구조

1. Introduction: 차량 내 노트북 NDRT와 감각 불일치 문제
2. Related Work: 감각 불일치, 주변시·예측 큐, 모바일/VR 모션 큐, 측정 척도
3. MotionCue System: Android/iPhone 센서 앱, BLE 브리지, 센서 융합, 큐 엔진, Windows 오버레이, 프라이버시
4. Study A: 모바일 IMU, 무선 전송 및 시스템 성능 검증
5. Study B: 실제 차량 사용자 실험
6. Results
7. Discussion: 효과, 지연, 방해성, 접근성, 실패 조건
8. Limitations and Future Work: 휴대폰 센서·거치 오차, BLE 제약, 표본·노선 일반화, 플랫폼 확장
9. Conclusion

### 작성 양식

- 작업 원고는 공식 ICCV 2025 Author Kit의 LaTeX 2단 스타일을 원형으로 사용한다.
- 이 문서는 ICCV 2025 투고물이 아니라 영문 학부논문이므로 학회 제출용 8쪽 제한, 익명 저자 표기 및 rebuttal 규칙은 적용하지 않는다.
- 저자 `Jayden Kim`, 소속과 지도교수 정보를 처음부터 표시한다.
- 참고문헌과 그림·표 스타일은 ICCV 형식을 유지하고, 실험 절차·추가 결과는 필요한 분량만큼 본문 또는 appendix에 둔다.
- 학교가 학위 제출에 필수 표지나 승인 페이지를 요구하는 경우 최종본 앞쪽에 최소한으로 추가하고 본문 스타일은 유지한다.

공식 양식 자료: [ICCV 2025 Author Guidelines and Author Kit](https://iccv.thecvf.com/Conferences/2025/AuthorGuidelines)

macOS용 구현은 본 실험 범위에서 제외한다. MacBook Air M1은 Windows 연구 완료 후 플랫폼 비교 또는 Apple의 macOS Vehicle Motion Cues와의 후속 비교 대상으로 다룬다.

### 후속 연구: 선박용 USB IMU MotionCue

현재 학부논문은 승용차, 스마트폰 IMU, BLE를 대상으로 유지한다. 별도 후속 연구에서는 가속도계와 자이로스코프가 포함된 USB IMU 동글을 Windows 노트북에 직접 연결해 휴대폰 앱 없이 동작하는 구성을 평가한다. 대상 환경은 민간 여객선·일반 선박을 우선하며, 해군 함정은 보안·장비 반입·전자파 적합성·안전·기관 승인 요건을 별도로 해결한 뒤 확장한다.

선박 연구에서는 차량용 전후·좌우 모델을 그대로 사용하지 않고 surge, sway, heave, roll, pitch, yaw의 6자유도 선체 운동과 파랑의 저주파·장주기 특성을 반영한다. USB 센서는 공통 SensorFrame으로 정규화하고 기존 `MotionState → CuePresentationEngine → Windows overlay` 경로를 재사용하는 방향을 권장한다. 연구 질문에는 스마트폰 BLE 대비 USB IMU의 지연·안정성, 선체축 교정, 장기 드리프트, 수직운동 표현, 선박 멀미와 노트북 과업 영향이 포함된다.

## 10. 연구용 추가 개발

1. ✅ 실험 조건을 설정하는 숨겨진 Research Mode
2. ✅ 익명 참가자·세션 ID 관리
3. ✅ FMS 1분 알림 및 입력 UI
4. ✅ 좌표를 구조적으로 제외한 파생 신호·큐 상태 opt-in CSV 기록
5. ✅ 기준 IMU와 시간 동기화할 수 있는 이벤트 마커
6. ✅ 즉시 중단 단축키와 큐 강제 종료
7. ✅ 실제 추정 경로를 사용하는 결정론적 가상 SensorFrame 재생
8. ✅ CSV 데이터 사전과 익명화 경계 문서
9. ⬜ 차량 기준 IMU 수집·시간 동기화 도구
10. ⬜ 조건 순서 생성과 연구자 눈가림(blinding) 기능
11. ⬜ 프레임 시간·CPU·메모리 성능 로깅
12. ✅ 공통 SensorFrame v1 바이너리 프로토콜·코덱·스트림 안전 감시
13. 🟨 Windows BLE service 광고 scan, GATT 수신, UI·MotionController·차량축 estimator 연결 완료; 실제 송신폰 검증은 미완료
14. ⬜ Android IMU + BLE 송신 앱
15. ⬜ iPhone Core Motion + BLE 송신 앱
16. ⏸️ 로컬 Wi-Fi 보조 전송: BLE 실측이 기준을 충족하지 못할 때만 재개
17. ⬜ 차량축 교정 UI와 거치 오류 검출
18. ⬜ `Static Visual Control / Synchronized Cue` Research Mode 조건
19. ⬜ 무선 지연·지터·손실·재연결 로그
20. ⬜ 앱 계층 페어링 인증·암호화

## 11. 영향 분석

### 기대 영향

- 이동 중 노트북 업무·학습의 불편 완화 가능성
- 운영체제 차원의 접근성 보조 기능 가능성
- IMU가 없는 노트북이 휴대폰 센서를 무선으로 활용하는 저비용 설계 지침
- 계정·클라우드·위치 기록 없이 구현되는 프라이버시 중심 사례

### 위험 및 부정적 영향

- 잘못되거나 지연된 큐가 오히려 감각 불일치를 키울 수 있음
- 주변시 점이 작업 집중이나 영상 시청을 방해할 수 있음
- 휴대폰 거치 방향 오류 또는 BLE 지연이 잘못된 큐를 만들 수 있음
- Android·iPhone 기종별 센서 처리 차이가 재현성에 영향을 줄 수 있음
- BLE 어댑터·드라이버 차이로 Windows 호환성이 달라질 수 있음
- 개인별 멀미 민감도 차이가 커 평균 효과만으로 일반화하기 어려움
- 치료·예방 효과로 과장할 경우 의료적 오해를 만들 수 있음

따라서 논문에서는 '완화 가능성', '사용자 불편', '실험 조건에서의 효과'로 표현하고 의료기기나 치료 효과를 주장하지 않는다.

## 12. 핵심 선행연구

1. Kim, G., Park, M., Hwang, J., & Jeong, Y. (2026). Effects of Visual Motion Cues and Color Variation on Motion Sickness and Task Concentration in Public Transport. *Journal of the Ergonomics Society of Korea, 45*(3), 163–175. https://doi.org/10.5143/JESK.2026.45.3.163
2. Karjanto, J., et al. (2018). The effect of peripheral visual feedforward system in enhancing situation awareness and mitigating motion sickness in fully automated driving. *Transportation Research Part F, 58*, 678–692. https://doi.org/10.1016/j.trf.2018.06.046
3. Kuiper, O. X., et al. (2018). Looking forward: In-vehicle auxiliary display positioning affects carsickness. *Applied Ergonomics, 68*, 169–175. https://doi.org/10.1016/j.apergo.2017.11.002
4. Li, D., et al. (2023). MOSI APP — A Motion Cueing Application to Mitigate Car Sickness While Performing Non-driving Task. *HCII 2023*, 173–190. https://doi.org/10.1007/978-3-031-35908-8_13
5. Keshavarz, B., & Hecht, H. (2011). Validating an efficient method to quantify motion sickness. *Human Factors, 53*(4), 415–426. https://doi.org/10.1177/0018720811403736
6. Gianaros, P. J., et al. (2001). A questionnaire for the assessment of the multiple dimensions of motion sickness. *Aviation, Space, and Environmental Medicine, 72*(2), 115–119. https://pubmed.ncbi.nlm.nih.gov/11211039/
7. Golding, J. F. (2006). Predicting individual differences in motion sickness susceptibility by questionnaire. *Personality and Individual Differences, 41*(2), 237–248. https://doi.org/10.1016/j.paid.2006.01.012

## 13. 바로 다음 단계

1. ✅ 공통 SensorFrame, Windows BLE 수신, 차량축 estimator, Settings 연결, 가상 replay와 dropout 중립화를 구현·검증했다.
2. Windows Bluetooth radio를 준비 상태로 전환한 뒤 nearby service scan을 재확인한다.
3. M1 MacBook과 Xcode에서 iPhone 16 Pro용 Core Motion/BLE 송신 앱을 구현·서명한다.
4. iPhone 실기기에서 BLE 지연·손실·재연결·축 방향을 측정한다.
5. Android IMU 송신 앱을 구현해 Galaxy A50 호환성을 비교한다.
6. 로컬 Wi-Fi 보조 전송은 BLE 측정이 필요성을 보일 때만 구현한다. 현재 논문 핵심 평가 범위에는 포함하지 않는다.
7. `No Cue / Static Visual Control / Synchronized Cue` Research Mode를 완성한다.
8. Study A의 기준 IMU 동기화 주행을 먼저 수행한다.
9. 결과를 바탕으로 사용자 실험 자극 세기와 승용차 노선·주행 시간을 확정한다.
10. 파일럿 6~10명 후 본 실험 30명과 연구계획 사전등록을 진행한다.
