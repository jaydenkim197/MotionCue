# 재사용 가능한 개발 문서화 스킬북

문서 상태: `REUSABLE TEMPLATE`  
버전: 1.0  
작성일: 2026-09-04

> 목적: 한 프로젝트에서 발생한 제품 결정, 구현, 검증, 실패, 미해결 사항과 배포 상태를 잃지 않고 기록한다. 이 문서는 개인 개발자, 여러 기기를 오가는 개발 환경, 그리고 Codex 같은 코딩 에이전트 중심 작업에 맞춘 실전 운영 규칙이다.

이 문서는 특정 기술 스택에 종속되지 않는다. 새 프로젝트를 시작할 때 `docs/`로 복사하고, `<PROJECT>`와 placeholder를 실제 값으로 바꿔 사용한다.

## 1. 핵심 원칙

문서화의 목표는 문서를 많이 만드는 것이 아니다. **현재 무엇이 사실인지, 왜 그렇게 되었는지, 무엇이 아직 검증되지 않았는지**를 다음 작업자와 미래의 자신이 빠르게 복원할 수 있게 만드는 것이다.

모든 작업은 아래 네 가지 중 하나 이상을 남긴다.

| 남길 것 | 답해야 하는 질문 |
|---|---|
| 결정 | 무엇을 선택했고, 왜 선택했는가? |
| 변경 | 코드·UI·프로토콜·운영 방식 중 무엇이 달라졌는가? |
| 검증 | 무엇을 어떤 환경에서 확인했는가? |
| 미해결 사항 | 무엇이 아직 가정·계획·위험으로 남아 있는가? |

### 절대 규칙

1. 구현됐다는 말과 검증됐다는 말을 분리한다.
2. 계획과 확정 결정을 분리한다.
3. 과거 기록을 조용히 고쳐 쓰지 않는다. 대체된 결정은 새 기록에서 대체 사실을 밝힌다.
4. 코드 변경과 직접 관련된 문서는 같은 작업 안에서 갱신한다.
5. 문서에 비밀번호, API key, 개인식별정보, 원본 민감 데이터, 서명 인증서를 기록하거나 commit하지 않는다.
6. "최신 상태" 문서가 실제 코드·테스트·배포 상태와 모순되면 먼저 고친다.
7. 모든 작업을 기록할 필요는 없지만, **다음 사람이 다시 조사해야 하는 변경**은 반드시 기록한다.

## 2. 권장 문서 구조

새 프로젝트의 최소 구조는 다음과 같다.

```text
<PROJECT>/
├─ README.md
├─ docs/
│  ├─ development-log.md
│  ├─ open-decisions.md
│  ├─ architecture.md
│  ├─ verification.md
│  ├─ release-runbook.md              # 배포가 있을 때
│  ├─ research-or-product-plan.md     # 연구 또는 제품 계획이 있을 때
│  ├─ design-system.md                # UI 제품일 때
│  └─ cross-platform-git-workflow.md  # 여러 작업 공간일 때
├─ tests/
└─ tools/
```

필요한 문서만 만든다. 예를 들어 CLI 라이브러리에는 `design-system.md`가 필요 없고, 논문·사용자 실험이 없는 앱에는 연구 계획 문서가 필요 없다.

### 문서별 역할

| 문서 | 한 문장 역할 | 갱신 시점 |
|---|---|---|
| `README.md` | 처음 보는 사람이 프로젝트 목적·실행법·현재 상태를 이해하는 입구 | 실행법, 핵심 기능, 현재 상태가 바뀔 때 |
| `development-log.md` | 시간순으로 남기는 변경·결정·검증의 영구 기록 | material change 완료 직전 |
| `open-decisions.md` | 아직 확정되지 않은 선택과 확정 조건의 목록 | 선택지가 생기거나 결정될 때 |
| `architecture.md` | 시스템 경계, 데이터 흐름, 책임 분리 | 구조·통신·저장소 경계가 바뀔 때 |
| `verification.md` | 요구사항별 검증 방법과 현재 증거 | 테스트 전략·환경·결과가 바뀔 때 |
| `release-runbook.md` | 빌드·서명·배포·롤백 절차 | 출시 방식이 바뀔 때 |
| `design-system.md` | UI token, 컴포넌트 상태, 접근성 규칙 | 사용자 대면 UI를 추가·변경할 때 |
| `research-or-product-plan.md` | 문제, 사용자, 가설/RQ, 성공 지표, 범위 | 제품/연구 방향이 바뀔 때 |

## 3. 상태 언어를 통일한다

상태 단어가 프로젝트마다 달라지면 문서가 애매해진다. 아래 집합을 기본값으로 사용한다.

| 상태 | 의미 | 예시 |
|---|---|---|
| `PROPOSAL` | 검토 중인 추천안. 아직 팀 또는 사용자 결정이 아님 | "ONNX Runtime을 우선 검토한다" |
| `DECISION` | 의도적으로 선택했고 이후 작업의 기준이 됨 | "저장소 기본 브랜치는 main" |
| `PLANNED` | 확정됐지만 구현되지 않음 | "오프라인 내보내기 추가" |
| `IMPLEMENTED` | 코드·설정·문서에 반영됨 | "CSV export 코드 추가" |
| `VERIFIED` | 명시한 환경·방법으로 실제 확인됨 | "Windows 11 Release build 성공" |
| `BLOCKED` | 외부 정보·권한·장비 등으로 진행할 수 없음 | "Apple signing team 확인 대기" |
| `DEFERRED` | 의도적으로 후순위로 보냄 | "Android 지원은 v2" |
| `SUPERSEDED` | 이후 기록으로 대체됨. 삭제하지 않는다 | "Wi-Fi 전송안은 BLE로 대체" |

`IMPLEMENTED`는 자동으로 `VERIFIED`가 아니다. 예를 들어 코드는 build됐지만 실기기에서 확인하지 않았다면 `IMPLEMENTED`, `build VERIFIED`, `device verification PLANNED`처럼 구체적으로 쓴다.

## 4. 작업 시작 전 루틴

작업을 시작할 때 아래 다섯 가지를 확인한다.

1. `README.md`의 현재 상태가 무엇인가?
2. `open-decisions.md`에 이번 작업을 막는 미결정이 있는가?
3. `development-log.md`의 최근 항목은 무엇인가?
4. 작업 트리와 원격 저장소가 최신·정상 상태인가?
5. 이번 작업의 완료 기준은 무엇인가?

### 작업 카드 템플릿

큰 변경은 코드보다 먼저 다음처럼 한 단락으로 정의한다.

```markdown
## 작업: <짧은 이름>

- 목적: <사용자/시스템 관점의 결과>
- 범위: <바꾸는 컴포넌트와 바꾸지 않는 경계>
- 완료 기준: <build, test, 실기기, 문서 중 필요한 증거>
- 위험: <호환성·데이터·성능·UX·보안 위험>
- 문서 영향: <갱신할 문서 목록>
```

작업이 작으면 이 카드를 별도 파일로 만들 필요 없다. Codex 작업 메시지나 development log 초안에서 같은 내용을 명확히 하면 충분하다.

## 5. 작업 중 기록 규칙

### 무엇을 기록해야 하는가

다음 중 하나에 해당하면 development log에 남긴다.

- 사용자가 보는 동작, UI, 기본값 또는 error handling이 바뀜
- public API, protocol, data schema, database migration 또는 file format이 바뀜
- 기술 선택, 라이브러리, 플랫폼 지원 범위, privacy/security boundary가 바뀜
- 연구 가설, 실험 조건, 성공 지표, 측정법, 모집·동의 범위가 바뀜
- 테스트로 중요한 실패 조건이나 회귀를 발견·수정함
- 배포 방식, signing, sync workflow, backup/restore 방식이 바뀜
- 중요 후보를 채택·보류·폐기함

다음은 보통 별도 log가 필요 없다.

- 오탈자만 수정
- 결과에 영향을 주지 않는 formatting만 변경
- 이미 기록된 구현의 기계적 리팩터링으로 공개 동작·계약·위험이 그대로인 경우

다만 작은 변경도 버그 원인이나 실험 재현성에 영향을 주면 기록한다.

### 기록 시점

기록은 "나중에 한꺼번에" 하지 않는다.

- 방향을 결정한 직후: `DECISION` 또는 `PROPOSAL`
- 구현을 마친 뒤: `IMPLEMENTED`
- build/test/실기기 확인 뒤: `VERIFIED`
- 작업 완료 직전: 한 항목으로 이유·영향·검증·남은 일을 정리

이 순서가 중요한 이유는 작업 도중에 가정이 바뀌거나 검증이 실패한 사실을 잃지 않기 때문이다.

## 6. Development Log 템플릿

`docs/development-log.md`의 첫 부분은 아래처럼 시작한다.

```markdown
# <PROJECT> Development Log

이 문서는 제품, UX, 기술 구조, 운영, 검증 및 연구 설계의 material change를 시간순으로 보존한다.

## 기록 원칙

- 코드, UI, protocol, data schema, 운영 방식 또는 실험 설계가 바뀌면 같은 작업에서 기록한다.
- 기존 항목은 삭제하지 않는다. 대체된 항목은 새 기록에서 `SUPERSEDED`로 연결한다.
- `IMPLEMENTED`와 `VERIFIED`를 구분한다.
- 비밀값, PII, 원본 민감 데이터는 기록하지 않는다.

## 상태 표기

- `PROPOSAL`: 검토 중인 추천안
- `DECISION`: 확정된 기준
- `PLANNED`: 확정됐지만 미구현
- `IMPLEMENTED`: 반영 완료
- `VERIFIED`: 명시한 방법으로 확인 완료
- `BLOCKED`: 외부 의존성으로 중단
- `DEFERRED`: 후순위 이동
- `SUPERSEDED`: 이후 결정으로 대체

---
```

### 항목 템플릿

```markdown
## YYYY-MM-DD — <변경의 결과가 드러나는 제목>

상태: `IMPLEMENTED`, `VERIFIED`

배경:

- <왜 이 작업이 필요했는가>

변경:

- <무엇을 바꿨는가>
- <의도적으로 바꾸지 않은 경계는 무엇인가>

영향:

- <사용자, 데이터, API, UX, 운영, 실험 설계에 미치는 영향>

검증:

- <명령 또는 테스트 이름>
- <실기기/브라우저/OS/데이터 조건>
- <관찰 결과와 알려진 한계>

남은 작업:

- <아직 하지 않은 검증 또는 후속 결정>
```

### 좋은 기록과 나쁜 기록

나쁜 예:

```markdown
- BLE 수정함. 잘 됨.
```

좋은 예:

```markdown
- stale sensor frame이 남아 cue가 유지될 수 있어, 마지막 frame 후 250 ms가 지나면 cue를 neutral로 전환했다.
- 단위 테스트에서 250 ms 전에는 마지막 cue를 유지하고 이후에는 zero offset으로 바뀌는 것을 확인했다.
- 실제 휴대폰의 background 전송 유지 여부는 아직 검증하지 않았다.
```

좋은 기록은 코드 diff를 다시 읽지 않아도 **이유·동작·증거·한계**를 복원할 수 있다.

## 7. Open Decisions 템플릿

미확정 사항을 development log 속에 묻어 두지 않는다. `docs/open-decisions.md`에 모아 결정이 필요한 시점과 기준을 명시한다.

```markdown
# <PROJECT> Open Decisions

권장안은 기본 제안일 뿐, `확정`이 되기 전에는 최종 결정이 아니다.

| ID | 결정 사항 | 현재 권장안 | 선택 기준 / 필요한 정보 | 결정 마감 | 상태 |
|---|---|---|---|---|---|
| P0-1 | <예: 데이터 저장 위치> | <권장안> | <보안·비용·법적 요건> | 구현 전 | 미정 |
| P1-1 | <예: default UI mode> | <권장안> | <사용자 파일럿 결과> | beta 전 | 미정 |
| P2-1 | <예: 후속 플랫폼> | <권장안> | <실측 성능> | v2 계획 전 | 보류 |
```

### 우선순위 규칙

- `P0`: 구현·안전·법적·데이터 경계를 막는 결정. 구현 전에 확정한다.
- `P1`: 파일럿·beta·출시 전에 확정할 결정.
- `P2`: 지금의 방향에는 영향을 주지만 실측·사용자 피드백 후 결정할 사항.
- `Future`: 현재 milestone과 분리된 확장 아이디어.

결정이 끝나면 행을 삭제하지 않는다. 상태를 `확정`, `보류`, `대체됨`으로 바꾸고 development log의 날짜 항목을 연결한다.

## 8. Architecture와 계약 문서

구조 문서는 모든 class를 나열하는 문서가 아니다. 경계와 계약을 보여주는 문서다.

최소한 아래를 적는다.

- 컴포넌트별 책임과 소유자
- 입력·출력 데이터와 신뢰 경계
- 저장되는 데이터와 저장하지 않는 데이터
- 실패·재시도·fallback·중립화 규칙
- platform-specific 부분과 공통 부분
- 버전 호환성 정책

### 데이터 계약 템플릿

```markdown
## <Message / File / API> v1

- 생산자: <component>
- 소비자: <component>
- 전송/저장: <protocol or location>
- 포함 필드: <field, type, unit, range>
- 금지 필드: <PII, location, secret 등>
- 순서/시간 기준: <monotonic timestamp, sequence 등>
- 오류 처리: <invalid input, timeout, duplicate, schema mismatch>
- 호환성: <versioning / migration rule>
```

데이터 계약이 바뀌면 code, tests, architecture, migration 안내, development log를 함께 갱신한다.

## 9. 검증을 문서화하는 방법

### 검증 계층

| 계층 | 검증 대상 | 예시 |
|---|---|---|
| 정적 검사 | formatting, lint, type, secret scan | formatter, compiler, static analyzer |
| 단위 테스트 | 순수 로직, 경계값, parser | 0, max, timeout, invalid input |
| 통합 테스트 | 컴포넌트 연결 | DB/API/BLE codec 연결 |
| 시스템 테스트 | 실제 실행 경로 | app launch, first-run, recovery |
| 실환경 검증 | 실제 기기·네트워크·사용자 맥락 | physical phone, Windows version, route |
| 회귀 검증 | 이전 실패가 다시 발생하지 않는가 | bug-specific test case |

### `verification.md` 템플릿

```markdown
# <PROJECT> Verification Matrix

| 요구사항 | 검증 방법 | 환경 | 최근 결과 | 증거 위치 | 상태 |
|---|---|---|---|---|---|
| 앱이 clean install에서 시작 | manual smoke test | Windows 11 x64 | 2026-09-04 pass | log link | VERIFIED |
| invalid packet을 거부 | unit test | .NET 8 | 24/24 pass | test name | VERIFIED |
| offline fallback | fault injection | physical device | pending | - | PLANNED |
```

### 검증 기록에서 반드시 분리할 것

- **명령이 성공한 사실**과 **사용자 경험이 정상이라는 사실**
- **simulator 결과**와 **physical device 결과**
- **개발 PC 결과**와 **지원 대상 환경 결과**
- **정상 경로**와 **network loss, permission denial, malformed input 같은 실패 경로**

"빌드가 된다"는 것은 배포 가능성이나 연구 가설 검증의 증거가 아니다.

## 10. UX·제품 변경 문서화

사용자 대면 UI를 바꿀 때에는 screenshot만 남기지 말고 다음을 기록한다.

- 어떤 사용자 행동을 쉽게 만들었는가?
- 이전 UI의 인지적 문제는 무엇이었는가?
- default, disabled, loading, error, empty, success 상태가 각각 어떻게 보이는가?
- 오류가 modal이어야 하는가, inline recovery message가 더 적절한가?
- keyboard, screen reader, contrast, touch target에 미치는 영향은 무엇인가?
- 레이아웃이 내용 증가·창 축소·DPI 변화에서 유지되는가?

디자인 시스템이 있는 프로젝트는 색상·spacing·radius·typography token을 개별 화면에 하드코딩하지 않는다. 새 컴포넌트를 만들면 design system의 component state와 review checklist를 갱신한다.

## 11. 연구·데이터·AI 프로젝트의 추가 규칙

연구나 AI 프로젝트는 코드 외에 **주장 가능한 범위**가 중요하다.

### 반드시 분리해서 기록할 것

- 구현된 시스템 기능
- 실제 측정된 성능
- 아직 가정인 모델 성능 또는 사용자 효과
- 탐색 분석과 사전 정의된 1차 분석
- feature와 ground truth
- training, validation, test participant 또는 session의 분리 방식

### 데이터 관리 최소 항목

```markdown
## Data Boundary

- 수집 목적:
- 수집 항목:
- 명시적으로 수집하지 않는 항목:
- 식별자 처리:
- 원본 데이터 보존 기간:
- 파생 데이터 보존 기간:
- 암호화/접근 권한:
- 삭제·철회 절차:
- 동의·심의 상태:
```

특히 얼굴, 음성, 위치, 건강·생체신호, 화면 캡처가 포함되면 "로컬 처리"만으로 충분하다고 가정하지 않는다. 실제 수집 전에 지도기관·IRB·법무·보안 요구사항을 확인하고 상태를 문서에 남긴다.

## 12. 여러 컴퓨터와 Git 운영 규칙

여러 OS·노트북을 오가도 source of truth는 하나여야 한다. 개인이 순차적으로 작업한다면 GitHub 같은 원격 Git 저장소와 각 기기의 독립 clone이 가장 단순하다.

```text
Computer A local clone ── push ──→ remote Git repository
Computer B local clone ←─ pull ── remote Git repository
```

### 권장 completion-sync

1. 작업 시작 전: `git pull --ff-only` 또는 프로젝트 표준 fetch/rebase 절차를 수행한다.
2. 하나의 coherent change를 끝낸다.
3. 관련 코드, tests, docs를 함께 점검한다.
4. `git status`와 diff를 확인한다.
5. commit하고 push한다.
6. 다른 컴퓨터에서는 작업 시작 전에 pull한다.

Codex가 주로 파일을 수정하는 개인 순차 workflow라면, 변경을 감시하는 background watcher보다 **material task 완료 시 한 번만 실행하는 sync helper**가 효율적이다.

### 하지 말아야 할 것

- OneDrive, iCloud Drive, Dropbox, Syncthing에 live Git workspace를 양방향 동기화
- `.git` 폴더 자체의 파일 복사·동기화
- 충돌 상태에서 force push, `reset --hard`, 자동 file overwrite
- build output, dependency cache, signing key, secret, local database를 무분별하게 commit
- 두 컴퓨터에서 같은 문서를 수정한 뒤 pull 없이 자동 병합 기대

작업 방식이 동시 협업으로 바뀌면 completion-sync만으로는 부족하다. branch, pull request, code review, protected branch 규칙을 별도로 도입한다.

## 13. Codex/에이전트 작업 종료 프로토콜

에이전트에게 코드만 수정하게 두면 변경 이유와 검증 경계가 쉽게 사라진다. 아래 종료 프로토콜을 작업 지시 또는 repository instruction에 넣는다.

```markdown
## Material-change completion protocol

작업을 끝내기 전에:

1. 관련 문서(`development-log`, `open-decisions`, `architecture`, `verification`, README)를 갱신한다.
2. `IMPLEMENTED`, `VERIFIED`, `PLANNED`, `BLOCKED`를 정확히 구분한다.
3. 가능한 범위의 build/test/실기기 검증을 실행하고 환경과 결과를 기록한다.
4. `git diff --check`와 `git status`로 변경 범위를 확인한다.
5. 프로젝트의 completion-sync helper가 있다면 한 번 실행한다.
6. 최종 보고에는 결과, 검증, 알려진 한계, 다음 결정 또는 작업을 짧게 제시한다.

원본 민감정보, secret, 인증서, 개인식별정보는 문서·로그·commit에 넣지 않는다.
```

### 좋은 에이전트 보고 예시

```markdown
완료: reconnect 화면을 non-modal inline recovery message로 변경했습니다.

- 이유: 연결 실패가 MessageBox로 흐름을 막고 기존 UI와 달랐습니다.
- 검증: Release build 및 core test 24개 통과. 기기 미선택·scan 실패·disconnect 예외 경로를 확인했습니다.
- 한계: 실제 Bluetooth adapter별 reconnect time은 아직 측정하지 않았습니다.
- 기록: development log, verification matrix, README를 갱신했고 completion-sync를 push했습니다.
```

## 14. Milestone 정리 방식

장기 프로젝트는 log만으로 진행 상황을 파악하기 어렵다. milestone 문서 또는 issue board에는 결과 중심으로 정리한다.

| Milestone | 목표 | 포함 | 제외 | 완료 증거 | 상태 |
|---|---|---|---|---|---|
| M0 Foundation | 재현 가능한 개발 기반 | repo, build, test, docs | feature polish | clean clone build | 완료 |
| M1 MVP | 핵심 사용자 흐름 | primary feature, recovery | advanced automation | system test | 진행 중 |
| M2 Validation | 실제 환경 검증 | instrumentation, pilot | broad rollout | evidence report | 계획 |
| M3 Release | 사용자 배포 | packaging, runbook | v2 research | signed artifact | 계획 |

"80% 완료"보다 "M1의 reconnect recovery 검증이 남음"이 다음 행동을 더 명확하게 만든다.

## 15. 월간 또는 milestone 종료 감사

다음 질문으로 문서와 코드가 다시 어긋나지 않았는지 점검한다.

- README의 기능·실행·현재 상태는 실제인가?
- `PLANNED`로 적힌 기능이 이미 구현되었거나, `VERIFIED`가 사실상 추측은 아닌가?
- 최근 중요한 결정이 open decisions에 여전히 미정으로 남아 있지 않은가?
- architecture의 데이터 흐름이 코드와 다른가?
- 테스트 결과가 실행 환경과 날짜를 포함하는가?
- release runbook을 새 clone 또는 새 장비에서 따라 할 수 있는가?
- secrets, 개인 데이터, build artifact가 Git history에 들어가지 않았는가?
- 더 이상 필요한 없는 문서는 `SUPERSEDED` 경로를 남기고 새 기준 문서로 연결했는가?

## 16. 새 프로젝트 적용 체크리스트

### 시작일

- [ ] README에 목적, 대상 사용자, non-goal, local run 방법 작성
- [ ] `docs/development-log.md`와 `docs/open-decisions.md` 생성
- [ ] `.gitignore`, `.gitattributes`, secret handling 규칙 설정
- [ ] architecture의 시스템 경계와 data boundary 작성
- [ ] build/test 명령과 지원 환경을 README에 기록
- [ ] 원격 Git repository와 backup/restore 방침 확정

### 기능 작업마다

- [ ] 변경 목적과 완료 기준을 정함
- [ ] 관련 코드·테스트·문서를 함께 변경
- [ ] 정상 경로와 실패 경로를 검증
- [ ] development log에 이유·영향·검증·남은 일을 기록
- [ ] 미결정 사항은 open decisions로 이동
- [ ] diff 확인 후 commit/push 또는 completion-sync 실행

### 출시 또는 연구 수집 전

- [ ] version, supported platform, migration/rollback, known limitation 정리
- [ ] privacy/security/data retention 경계 검토
- [ ] physical environment 또는 representative user flow 검증
- [ ] artifact 재현 절차와 checksum 또는 version 식별자 기록
- [ ] 사용자 안내, 안전 중단, support/recovery 경로 작성

## 17. 최소 도입안

처음부터 모든 문서를 운영하기 어렵다면 아래 세 파일만으로 시작한다.

1. `README.md` — 목적, 실행, 현재 상태
2. `docs/development-log.md` — material change의 이유·검증·한계
3. `docs/open-decisions.md` — 아직 정하지 않은 것과 결정 조건

프로젝트가 커질 때 architecture, verification, release, design, research 문서를 추가한다. 중요한 것은 문서의 개수가 아니라, **결정·변경·증거·미해결 사항이 서로 연결되어 있는가**다.

## 18. MotionCue에서 검증된 적용 방식

이 스킬북은 MotionCue에서 다음 방식으로 실제 적용했다.

- Windows, iOS, BLE protocol, 연구 설계, UI, privacy boundary를 하나의 chronological development log에 기록
- research condition, device, transport, approval처럼 아직 확정되지 않은 사항을 open decisions로 분리
- 실제 iPhone-to-Windows 연결과 build 성공을 별도로 기록해 `IMPLEMENTED`와 `VERIFIED`를 구분
- UI reference를 그대로 asset으로 복사하지 않고, design system 문서로 디자인 언어와 라이선스 경계를 남김
- GitHub private repository를 source of truth로 두고 Windows/Mac의 local clone은 completion-sync만 수행
- background filesystem sync, `.git` 동기화, 자동 충돌 해결을 금지
- 각 material task 종료 시 문서 갱신, 검증, Git sync를 하나의 완료 단위로 취급

이 방식은 프로젝트의 규모보다 작업 맥락 전환 비용이 큰 경우에 특히 효과적이다. 몇 주 뒤 다시 돌아와도 코드만 읽는 대신 문서에서 "무엇을 믿을 수 있고 무엇이 아직 미검증인가"를 먼저 파악할 수 있다.
