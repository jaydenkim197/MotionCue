from pathlib import Path

from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

import build_motioncue_prd as base


OUT = Path(r"C:\Users\sukhe\Desktop\vehicle_mode_for_laptop\MotionCue_페르소나정의_v0.1.docx")

# One preset only: standard_business_brief.
# Named overrides: Korean glyphs use Malgun Gothic; first-page furniture follows memo_masthead.


def clear_paragraph(paragraph):
    for child in list(paragraph._p):
        paragraph._p.remove(child)


def add_page_field(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    base.set_font(paragraph.add_run("MotionCue 페르소나 정의  |  "), size=8.5, color=base.MUTED)
    for index, field_name in enumerate(("PAGE", "NUMPAGES")):
        if index:
            base.set_font(paragraph.add_run(" / "), size=8.5, color=base.MUTED)
        fld = OxmlElement("w:fldSimple")
        fld.set(qn("w:instr"), field_name)
        run = OxmlElement("w:r")
        text = OxmlElement("w:t")
        text.text = "1"
        run.append(text)
        fld.append(run)
        paragraph._p.append(fld)


def setup_doc():
    doc = base.setup_doc()
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1.0)
    section.right_margin = Inches(1.0)
    section.bottom_margin = Inches(1.0)
    section.left_margin = Inches(1.0)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)

    header_p = section.header.paragraphs[0]
    clear_paragraph(header_p)
    header_p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    base.set_font(
        header_p.add_run("MOTIONCUE  /  CUSTOMER & PERSONA DEFINITION  v0.1"),
        size=8.3,
        bold=True,
        color=base.MUTED,
    )
    footer_p = section.footer.paragraphs[0]
    clear_paragraph(footer_p)
    add_page_field(footer_p)

    core = doc.core_properties
    core.title = "MotionCue 페르소나 정의 v0.1"
    core.subject = "Windows 11 이동 중 노트북 사용자를 위한 타깃 고객 및 페르소나 가설"
    core.author = "MotionCue Product Strategy"
    core.keywords = "MotionCue, Persona, Target Customer, Windows, GNSS, Customer Discovery"
    return doc


def page_break(doc):
    doc.add_page_break()


def add_small_note(doc, text):
    p = doc.add_paragraph(style="Small Note")
    base.set_font(p.add_run(text), size=8.5, color=base.MUTED)
    return p


def add_quote(doc, quote):
    p = doc.add_paragraph(style="Quote")
    p.paragraph_format.left_indent = Inches(0.24)
    p.paragraph_format.right_indent = Inches(0.18)
    base.set_font(p.add_run("가상 Persona Quote — 실제 사용자 인터뷰 발언 아님\n"), size=8.6, bold=True, color=base.RED)
    base.set_font(p.add_run(f'“{quote}”'), size=10.5, italic=True, color=base.DARK_BLUE)
    return p


def add_persona_snapshot(doc, rows):
    return base.add_table(
        doc,
        ["관찰 기준", "페르소나 가설"],
        rows,
        [1850, 7510],
        font_size=9.05,
        header_fill=base.LIGHT_BLUE,
    )


def add_ranked_items(doc, items):
    rows = [(str(i + 1), level, text) for i, (level, text) in enumerate(items)]
    return base.add_table(
        doc,
        ["순위", "중요도", "내용"],
        rows,
        [650, 1100, 7610],
        font_size=9.0,
        aligns=["center", "center", "left"],
        header_fill=base.LIGHT,
    )


def opening(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after = Pt(2)
    base.set_font(p.add_run("CUSTOMER & PERSONA DEFINITION"), size=9, bold=True, color=base.BLUE)
    p = doc.add_paragraph(style="Title")
    base.set_font(p.add_run("MotionCue Personas"), size=28, bold=True, color=base.NAVY)
    p = doc.add_paragraph(style="Subtitle")
    base.set_font(p.add_run("문제 강도·반복 행동·MVP 제약을 기준으로 한 초기 타깃 고객 정의"), size=13, color=base.MUTED)
    base.add_para(doc, "문서 버전 v0.1  |  기준일 2026-08-19  |  상태: 고객 발견 전 가설 문서", size=9.2, color=base.MUTED, after=12)

    base.add_heading(doc, "현재 가장 유력한 Primary Target", 2)
    base.add_callout(
        doc,
        "잠정 결론",
        "주 3일 이상 30분 넘는 버스 통학을 하며, 이동 중 Windows 노트북으로 과제·문서 작업을 반복하지만 화면 불편 때문에 작업을 중단한 경험이 있는 대학생입니다. 단, 실제 MVP 베타 참여자는 내장 Satellite GNSS가 작동하는 Windows 11 노트북 보유까지 확인되어야 합니다.",
        accent=base.BLUE,
        fill=base.LIGHT_BLUE,
    )

    rows = [
        ("Primary Target", "장거리 버스 통학 중 노트북 작업을 지속하려는 대학생"),
        ("선정 이유", "행동 빈도와 문제 결과가 선명하고, 학교·커뮤니티에서 인터뷰 및 반복 현장 테스트 모집이 비교적 쉽다."),
        ("MVP 필수 게이트", "승객 + Windows 11 노트북 + 사용 가능한 내장 Satellite GNSS 확인"),
        ("Strongest Alternative", "택시·버스 이동 중 업무를 처리하는 현장·고객 대응형 직장인"),
        ("가장 큰 불확실성", "이상적 사용자의 노트북이 실제로 GNSS를 제공하는지, GNSS-only cue가 체감상 유효한지"),
        ("1차 모집 목표", "행동 인터뷰 12–15명 → 하드웨어 스크리닝 → 호환 베타 테스터 5–10명"),
    ]
    base.add_table(doc, ["결정 항목", "현재 판단"], rows, [2100, 7260], font_size=9.0, header_fill=base.LIGHT)
    add_small_note(doc, "표기 규칙: [현재 근거] 제품 전제·관찰 가능한 사실  |  [제품 결정] 현재 선택  |  [가설/조사 필요] 아직 검증되지 않은 판단")
    page_break(doc)


def section_1_core_conclusion(doc):
    base.add_heading(doc, "1. 핵심 결론", 1)
    base.add_label_para(doc, "제품 결정", "연령이나 ‘멀미를 하는 사람’이 아니라 반복 행동의 교집합으로 타깃을 정의한다: 지상 교통수단의 승객이며, Windows 노트북을 자주 사용하고, 불편 때문에 작업이 깨지지만, 해야 할 일이 있어 화면 사용을 계속하려는 사람이다.", base.BLUE)
    base.add_label_para(doc, "가설/조사 필요", "장거리 버스 통학형 대학생이 이 교집합을 가장 높은 빈도로 보이며 초기 접근성이 좋다는 판단은 아직 사용자 인터뷰로 검증되지 않았다.", base.RED)
    base.add_label_para(doc, "현재 근거", "MVP는 Windows 11, 로컬 처리, 시스템 트레이 중심, 내장 Satellite GNSS를 전제로 한다. 따라서 사용자 필요가 커도 GNSS가 없으면 현재 빌드의 테스트 대상이 될 수 없다.", base.NAVY)

    base.add_heading(doc, "선정 원칙", 2)
    for text in [
        "Problem fit: 불편이 실제 행동 중단·지연·품질 저하로 이어지는가?",
        "Behavior fit: 이동 중 노트북 사용이 반복되며, 계속 사용하려는 이유가 분명한가?",
        "MVP fit: Windows 11과 usable Satellite GNSS를 보유하고 권한 부여·설치가 가능한가?",
        "Learning fit: 초기 팀이 모집하고 동일 노선·상황에서 여러 번 관찰할 수 있는가?",
        "Retention fit: 한 번의 호기심이 아니라 다음 이동에서도 자동 실행을 원할 이유가 있는가?",
    ]:
        base.add_bullet(doc, text)

    base.add_heading(doc, "핵심 판단", 2)
    base.add_callout(doc, "Need와 Testability를 분리", "이상적 제품 페르소나는 가장 강한 문제를 가진 사람이고, MVP-compatible test persona는 그 문제에 더해 GNSS 하드웨어까지 충족하는 사람입니다. 두 집단을 섞으면 ‘수요가 없음’과 ‘하드웨어가 없음’을 잘못 해석할 위험이 큽니다.", accent=base.GOLD, fill="FFF8E8")


def section_2_segments(doc):
    base.add_heading(doc, "2. 시장/사용자 세그먼트 후보", 1)
    base.add_para(doc, "아래 후보는 ‘이동 중 승객으로서 Windows 노트북 화면을 본다’는 행동 맥락을 기준으로 만들었습니다. 세그먼트 이름은 모집과 분석을 위한 가설이며 시장 규모의 증거가 아닙니다.")
    rows = [
        ("장거리 버스 통학형 대학생", "광역·시외·통학버스 30–90분", "과제, 강의자료, 코딩, 문서", "반복 빈도와 모집 접근성"),
        ("버스 통근형 사무직", "광역·통근버스 40–100분", "메일, 문서 검토, 발표자료", "반복 행동은 강하나 회사 기기 설치 제한"),
        ("택시·버스 이동 업무형", "고객·현장 간 이동 20–60분", "보고서, 메신저, 일정, 제안서", "시간 가치와 지속 의지가 큼"),
        ("잦은 국내 출장자", "공항·역 연결 버스·택시", "출장 준비, 정리, 회의 문서", "문제는 강할 수 있으나 상황이 불규칙"),
        ("원격·하이브리드 이동 근무자", "업무일 중 여러 장소 이동", "협업 문서, 코딩, 운영 대응", "자율 설치 가능성, 맥락 편차 큼"),
        ("디지털 노마드", "여행지 간 장거리 육상 이동", "창작·개발·고객 업무", "Windows 및 이동 수단 일관성이 낮음"),
        ("화면 민감 고빈도 사용자", "모든 지상 교통수단", "읽기·문서·영상", "문제 강도는 높지만 독립 시장보다 횡단 특성"),
        ("여행 중 생산성 사용자", "휴가·주말 이동", "예약, 사진 정리, 가벼운 업무", "낮은 빈도로 유지 가능성 약함"),
        ("가끔 승용차에서 쓰는 승객", "동승 중 간헐적 사용", "검색, 메시지, 콘텐츠", "행동 빈도와 설치 동기가 낮음"),
    ]
    base.add_table(doc, ["후보", "대표 맥락", "이동 중 작업", "초기 관찰"], rows, [2100, 2100, 2260, 2900], font_size=8.35, header_fill=base.LIGHT_BLUE)
    base.add_label_para(doc, "가설/조사 필요", "각 세그먼트의 Windows 사용률, 이동 중 실제 노트북 사용 빈도, 불편 발생률, 설치 의향, 내장 GNSS 보유율은 현재 근거가 없습니다.", base.RED)


def section_3_scoring(doc):
    page_break(doc)
    base.add_heading(doc, "3. 세그먼트 평가표", 1)
    base.add_para(doc, "점수는 시장 데이터가 아니라 비교를 강제하기 위한 1차 가설입니다. 1=매우 약함, 3=혼합/불확실, 5=매우 강함. ‘?’는 조사 없이 숫자로 만들면 안 되는 항목입니다.")

    base.add_heading(doc, "3.1 문제·행동 적합도", 2)
    rows = [
        ("장거리 버스 통학 대학생", "5", "4", "5", "5", "19/20", "반복·필요·모집이 선명"),
        ("버스 통근 사무직", "5", "3", "4", "4", "16/20", "회사 정책 변수가 큼"),
        ("택시·버스 이동 업무형", "4", "4", "4", "5", "17/20", "시간 가치와 업무 압박"),
        ("잦은 국내 출장자", "3", "4", "4", "5", "16/20", "빈도 개인차"),
        ("원격·하이브리드 이동 근무자", "3", "3", "3", "4", "13/20", "맥락 편차"),
        ("디지털 노마드", "2", "3", "3", "4", "12/20", "초기 모집 표본이 산만"),
        ("화면 민감 고빈도 사용자", "4", "5", "3", "5", "17/20", "횡단 특성, 별도 모집 가능"),
        ("여행 중 생산성 사용자", "2", "2", "2", "3", "9/20", "반복성이 약함"),
        ("가끔 승용차 승객", "1", "2", "1", "2", "6/20", "설치 이유가 약함"),
    ]
    base.add_table(doc, ["세그먼트", "문제 빈도", "문제 강도", "이동 중 노트북", "지속 의지", "합계", "해석"], rows, [2400, 850, 850, 1100, 900, 800, 2460], font_size=8.05, aligns=["left", "center", "center", "center", "center", "center", "left"], header_fill=base.LIGHT)

    base.add_heading(doc, "3.2 채택·MVP·학습 적합도", 2)
    rows = [
        ("장거리 버스 통학 대학생", "4", "4", "?", "5", "5", "Tier 1"),
        ("택시·버스 이동 업무형", "4", "3", "?", "4", "3", "Tier 1"),
        ("버스 통근 사무직", "4", "2", "?", "4", "3", "Tier 2"),
        ("잦은 국내 출장자", "4", "3", "?", "3", "2", "Tier 2"),
        ("화면 민감 고빈도 사용자", "3", "4", "?", "4", "3", "Tier 2"),
        ("원격·하이브리드 이동 근무자", "3", "4", "?", "3", "2", "Tier 3"),
        ("디지털 노마드", "2", "4", "?", "2", "2", "Tier 3"),
        ("여행 중 생산성 사용자", "3", "3", "?", "2", "3", "Tier 3"),
        ("가끔 승용차 승객", "3", "2", "?", "1", "3", "제외"),
    ]
    base.add_table(doc, ["세그먼트", "Windows", "설치 의향", "GNSS 적합", "유지 가능성", "초기 접근성", "결과"], rows, [2500, 850, 1000, 1000, 1000, 1050, 1960], font_size=8.05, aligns=["left", "center", "center", "center", "center", "center", "center"], header_fill=base.LIGHT_BLUE)
    add_small_note(doc, "GNSS 적합도는 모든 세그먼트에서 Unknown입니다. 이 열이 확인되기 전에는 ‘MVP 시장성’ 총점을 계산하지 않습니다.")

    base.add_heading(doc, "3.3 Tier 정리", 2)
    tier_rows = [
        ("Tier 1", "장거리 버스 통학 대학생; 택시·버스 이동 업무형", "강한 문제·반복 행동·현장 테스트 가능성"),
        ("Tier 2", "버스 통근 사무직; 잦은 출장자; 화면 민감 고빈도 사용자", "문제는 의미 있으나 설치·모집·빈도 변수가 큼"),
        ("Tier 3", "원격/하이브리드; 디지털 노마드; 여행 중 생산성 사용자", "매력적 서사보다 반복성과 초기 접근성이 약함"),
        ("초기 제외", "가끔 승용차에서 쓰는 승객", "빈도·유지 동기가 낮아 학습 비용 대비 효율이 낮음"),
    ]
    base.add_table(doc, ["구분", "세그먼트", "판단"], tier_rows, [1100, 3900, 4360], font_size=8.8, header_fill=base.LIGHT)


def section_4_primary_target(doc):
    page_break(doc)
    base.add_heading(doc, "4. Primary Target 선정", 1)
    base.add_heading(doc, "선정: 장거리 버스 통학형 대학생", 2)
    for text in [
        "Pain intensity: 화면 불편이 과제·시험 준비·코딩 같은 마감 작업의 중단으로 이어질 수 있다.",
        "Frequency: 학기 중 동일 노선을 주 3–5회 이용하는 패턴을 모집 기준으로 삼을 수 있다.",
        "Adoption: 개인 소유 노트북일 가능성이 있어 회사 관리 기기보다 설치 장벽이 낮을 수 있다.",
        "Repeat use: 동일 통학 환경에서 Automatic 모드의 반복 가치를 관찰하기 쉽다.",
        "Reach: 대학 커뮤니티·통학버스·동아리·수업 단위로 행동 인터뷰와 후속 테스트를 모집하기 상대적으로 쉽다.",
        "Windows relevance: 과제·개발·문서 도구와 Windows 노트북 사용이 자연스럽지만 실제 비중은 조사해야 한다.",
    ]:
        base.add_bullet(doc, text)
    base.add_label_para(doc, "가설/조사 필요", "이 세그먼트가 실제로 이동 중 노트북을 자주 열고 불편을 반복 경험한다는 증거, 그리고 usable GNSS 노트북 비율은 아직 없습니다.", base.RED)

    base.add_heading(doc, "2순위: 택시·버스 이동 업무형 직장인", 2)
    base.add_para(doc, "현장·고객사 사이를 이동하며 짧은 시간에도 보고서·메시지·제안서를 처리해야 하는 직장인은 시간의 가치와 작업 지속 의지가 더 클 수 있습니다. 그러나 사용 상황이 직무별로 흩어지고, 보안 정책·관리자 권한·위치 권한 때문에 설치가 막힐 수 있으며, 반복 현장 관찰 모집도 대학생보다 어렵습니다. 따라서 가치 가설의 강한 대안이지만 첫 학습 집단으로는 2순위입니다.")

    base.add_callout(doc, "결정 규칙", "Primary 선정은 ‘가장 돈을 많이 낼 것 같은 사람’이 아니라 가장 빠르게 문제·행동·효과를 반복 검증할 수 있는 사람을 기준으로 합니다. 지불 의사는 문제와 효능이 확인된 뒤 별도 검증합니다.", accent=base.BLUE)


def section_5_primary_persona(doc):
    page_break(doc)
    base.add_heading(doc, "5. Primary Persona", 1)
    base.add_heading(doc, "민준 — 장거리 광역버스 통학형 대학생", 2)
    add_small_note(doc, "민준은 분석과 모집을 위한 명시적 가상 이름이며 연구 증거가 아닙니다.")
    add_persona_snapshot(doc, [
        ("한 줄 정의", "주 4일 광역버스로 왕복 통학하며, 이동 중 과제·코딩을 해야 하지만 화면 불편으로 작업을 반복 중단하는 Windows 노트북 사용자"),
        ("상황", "편도 55–80분, 좌석 탑승, 주 4일. 노트북으로 PDF 읽기·문서 작성·코딩·강의 복습"),
        ("사용 빈도 가설", "이동 중 노트북 주 3–4회 / 불편 경험 주 1회 이상 — 가설, 인터뷰 필요"),
        ("MVP 적합 조건", "Windows 11 개인 노트북, usable Satellite GNSS, 위치 권한 허용, 승객 상태"),
        ("연구 상태", "가설 — 사용자 인터뷰/조사 필요"),
    ])

    base.add_heading(doc, "Core Problem & Trigger", 2)
    base.add_label_para(doc, "Core Problem", "버스가 가감속하거나 굽은 구간을 지날 때 화면 집중이 어려워져 읽던 문장을 반복하거나 노트북을 닫습니다. 그 결과 통학 시간을 과제 시간으로 쓰려던 계획이 깨지고, 도착 후 학업 시간이 밀립니다.", base.RED)
    base.add_label_para(doc, "Trigger Situation", "버스 출발 후 20분 이상 PDF·코드·문서를 보다가 몇 분 내 불편감이 올라오고, 창밖을 보거나 화면을 닫을지 고민하는 순간입니다.", base.GOLD)

    base.add_heading(doc, "Current Alternatives", 2)
    for text in [
        "노트북을 닫고 창밖을 본다 — 즉시 대응은 되지만 계획한 과제가 도착 후로 밀린다.",
        "오디오 강의·음성 콘텐츠로 바꾼다 — 읽기·작성·코딩 작업은 대체하지 못한다.",
        "휴대폰으로 짧게 확인한다 — 화면이 작고 생산 작업의 연속성이 깨진다.",
        "불편을 참고 계속한다 — 집중력과 정확도가 떨어지고 이후 상태가 더 나빠질 수 있다고 느낀다.",
        "아예 이동 중 작업 계획을 세우지 않는다 — 통학 시간이 구조적으로 비생산 시간이 된다.",
    ]:
        base.add_bullet(doc, text)

    base.add_heading(doc, "Jobs To Be Done", 2)
    for text in [
        "When 장거리 통학 중 과제 마감이 다가올 때, I want to 노트북 작업을 중단하지 않고 이어가고 싶다, so that 도착 후 학업 부담을 줄일 수 있다.",
        "When 버스가 가감속·회전할 때, I want to 몸이 느끼는 움직임을 화면 주변에서도 직관적으로 파악하고 싶다, so that 화면 집중이 덜 힘들다고 느끼고 싶다.",
        "When 앱을 한 번 설정한 뒤, I want to 다음 통학부터 자동으로 작동하기를 원한다, so that 매번 켜는 일을 기억하지 않아도 된다.",
        "When 위치 권한을 요청받을 때, I want to 데이터가 어디로 가는지 분명히 알고 싶다, so that 학업 기기에 불필요한 추적 도구를 설치했다는 불안을 피할 수 있다.",
    ]:
        base.add_bullet(doc, text)

    base.add_heading(doc, "Desired Outcome", 2)
    base.add_para(doc, "동일 노선·유사 좌석에서 평소보다 더 오래 화면을 보거나 작업 중단 시점이 늦어지고, cue가 눈에 거슬리지 않으며, 다음 통학에도 Automatic 모드를 켜 두겠다고 선택하면 ‘작동한다’고 판단합니다. ‘멀미 치료’가 아니라 관찰 가능한 작업 지속성 개선이 기준입니다.")

    base.add_heading(doc, "Key Pain Points", 2)
    add_ranked_items(doc, [
        ("High", "불편 때문에 읽기·작성·코딩을 중단해 통학 시간 활용 계획이 무너짐"),
        ("High", "도착 후 과제·시험 준비가 밀리며 시간 압박이 커짐"),
        ("Medium", "어떤 날·어떤 구간에 불편이 심할지 예측하기 어려움"),
        ("Medium", "현재 대안은 화면 작업을 포기하는 방식뿐임"),
        ("Low", "앱을 수동으로 켜는 작은 조작 자체"),
    ])

    base.add_heading(doc, "Adoption Motivation", 2)
    add_ranked_items(doc, [
        ("High", "추가 기기 없이 통학 중 과제 시간을 되찾을 가능성"),
        ("High", "한 번 설치 후 거의 조작하지 않는 Automatic 경험"),
        ("Medium", "계정·클라우드 없이 로컬에서 처리된다는 안심"),
        ("Low", "시각 효과의 새로움이나 커스터마이징 자체"),
    ])

    base.add_heading(doc, "Adoption Barriers & Trust", 2)
    base.add_table(doc, ["장벽", "필요한 신뢰 신호"], [
        ("위치 권한과 추적 우려", "로컬 처리, 업로드 없음, 위치 기록 미저장, 계정 없음의 짧고 구체적인 설명"),
        ("내 노트북에서 작동하는지 모름", "설치 전/직후 GNSS 호환성 진단과 이유가 있는 실패 안내"),
        ("배터리·성능 우려", "예상 영향 표시, 사용 중지·완전 종료가 즉시 가능"),
        ("cue가 더 거슬릴 수 있음", "낮은 기본 강도, 즉시 Off, 최소한의 강도 조절"),
        ("효과 회의", "치료 주장 대신 개인별 A/B 체험과 작업 지속 시간 기록"),
    ], [2650, 6710], font_size=8.9, header_fill=base.LIGHT)

    base.add_heading(doc, "Ideal UX & Feature Priority", 2)
    base.add_label_para(doc, "Ideal UX", "거의 없음. 최초 권한·호환성 확인 후 Automatic으로 두고, 트레이에서 상태·On/Off·Quit만 확인하는 경험이 기본 가설입니다.", base.BLUE)
    base.add_table(doc, ["Must-have", "Nice-to-have", "관심 낮음"], [
        ("GNSS 호환성 진단", "cue 강도 2–3단계", "계정·프로필"),
        ("Automatic / On / Off", "개인 테스트 요약", "소셜 공유"),
        ("눈에 덜 띄는 edge dots", "노선별 선호 저장", "화려한 테마"),
        ("명확한 privacy 설명", "키보드 단축키", "클라우드 동기화"),
        ("즉시 Quit·실패 상태 안내", "접근성 세부 설정", "랭킹·보상"),
    ], [3120, 3120, 3120], font_size=8.75, header_fill=base.LIGHT_BLUE)

    base.add_heading(doc, "Retention / Churn", 2)
    base.add_label_para(doc, "Retention Trigger", "두세 번의 통학에서 작업 중단이 줄었다고 느끼고, Automatic이 잘 켜지며, 배터리·시각 방해가 거의 없을 때 유지합니다.", base.GREEN)
    base.add_label_para(doc, "Churn Trigger", "GNSS가 자주 잡히지 않음, cue 방향·타이밍이 틀림, 체감 이득 없음, false activation, 배터리 소모, 거슬리는 점, 위치 권한 불신 중 하나가 반복될 때 삭제합니다.", base.RED)
    add_quote(doc, "버스에서 노트북을 아예 포기하지 않고, 과제 한 단락이라도 더 끝낼 수 있으면 좋겠어요.")


def section_6_secondary_persona(doc):
    base.add_heading(doc, "6. Secondary Persona", 1)
    base.add_heading(doc, "서연 — 택시·버스 이동 업무형 직장인", 2)
    add_small_note(doc, "서연은 분석과 모집을 위한 명시적 가상 이름이며 연구 증거가 아닙니다.")
    add_persona_snapshot(doc, [
        ("한 줄 정의", "주 2–4회 고객사·현장 사이를 택시나 버스로 이동하며, 이동 중 보고서·메일을 마쳐야 하는 Windows 노트북 사용자"),
        ("상황", "회당 25–60분, 일정이 촘촘함. 보고서 수정, 메일, 회의 준비, 일정 확인"),
        ("사용 빈도 가설", "이동 중 노트북 주 2–3회 / 필요가 있는 날 집중 — 가설, 인터뷰 필요"),
        ("MVP 적합 조건", "승객, Windows 11, usable GNSS, 설치 권한, 회사 보안정책 허용"),
        ("연구 상태", "가설 — 사용자 인터뷰/조사 필요"),
    ])
    base.add_heading(doc, "Core Problem & Trigger", 2)
    base.add_label_para(doc, "Core Problem", "이동 중 문서 작업을 끝내지 못하면 고객 도착 직전이나 다음 일정 사이에 급히 마무리해야 합니다. 화면 불편은 단순한 기분 문제가 아니라 응답 지연·준비 부족·야근 가능성으로 이어집니다.", base.RED)
    base.add_label_para(doc, "Trigger Situation", "택시나 광역버스에서 노트북을 열어 고객용 문서를 수정하기 시작했지만, 도심 정체의 잦은 출발·정지와 회전 때문에 몇 분 후 화면을 계속 보기 어려워지는 순간입니다.", base.GOLD)

    base.add_heading(doc, "Current Alternatives", 2)
    for text in [
        "음성 통화·음성 메모로 업무를 바꾼다 — 기밀성과 주변 소음, 문서 편집 한계가 있다.",
        "휴대폰으로 메일만 처리한다 — 복잡한 문서와 파일 작업은 남는다.",
        "도착 직전 카페·로비에서 처리한다 — 다음 일정 준비 시간이 줄어든다.",
        "차량에서는 쉬고 이후 야근한다 — 피로와 일정 리스크가 커진다.",
    ]:
        base.add_bullet(doc, text)

    base.add_heading(doc, "Jobs To Be Done", 2)
    for text in [
        "When 고객사 사이를 이동할 때, I want to 중요한 문서 수정과 응답을 끝내고 싶다, so that 다음 미팅에 준비된 상태로 들어갈 수 있다.",
        "When 차량 움직임 때문에 집중이 깨질 때, I want to 화면 사용 가능 시간을 조금이라도 늘리고 싶다, so that 이동 후 밀린 일이 남지 않게 하고 싶다.",
        "When 업무용 기기에 유틸리티를 설치할 때, I want to 권한·데이터 처리·종료 방법을 명확히 확인하고 싶다, so that 보안 정책을 위반하지 않을 수 있다.",
        "When 일정이 예측 불가능할 때, I want to 앱이 상황을 알아서 처리하길 원한다, so that 매번 수동으로 상태를 바꾸지 않아도 된다.",
    ]:
        base.add_bullet(doc, text)

    base.add_heading(doc, "Desired Outcome & Pain", 2)
    base.add_para(doc, "도착 전에 의도한 작업을 완료하는 비율이 늘고, cue를 의식하지 않아도 되며, 회사 보안 규정을 만족할 때 성공입니다.")
    add_ranked_items(doc, [
        ("High", "이동 중 업무 중단이 고객 응답·회의 준비 지연으로 연결됨"),
        ("High", "짧은 이동 시간을 놓치면 이후 일정과 야근으로 비용이 전가됨"),
        ("Medium", "회사 기기에서 설치와 위치 권한 승인이 필요할 수 있음"),
        ("Medium", "택시·버스마다 움직임 패턴이 달라 예측이 어려움"),
        ("Low", "개인화 기능이 적음"),
    ])

    base.add_heading(doc, "Adoption, Trust & Feature Priority", 2)
    base.add_label_para(doc, "Adoption Motivation", "1순위는 이동 시간을 실제 업무 시간으로 바꾸는 것, 2순위는 거의 조작이 없는 자동성, 3순위는 로컬 처리와 낮은 성능 영향입니다.", base.BLUE)
    base.add_label_para(doc, "Adoption Barriers", "회사 관리자 권한, 보안 정책, 위치 권한, 배터리, cue 오작동, 회의 화면 공유 중 노출, 효과 회의가 핵심입니다.", base.RED)
    base.add_label_para(doc, "Trust Requirements", "네트워크 전송 없음, 위치 저장 없음, 설치 파일의 신뢰성, 관리자가 검토할 수 있는 권한 문서, 즉시 Off/Quit, 화면 공유 시 동작 정책이 필요합니다.", base.NAVY)
    base.add_label_para(doc, "Ideal UX", "거의 없음. 다만 현재 상태·권한·GNSS 수신·완전 종료 여부를 트레이에서 즉시 확인하고 싶어 합니다.", base.BLUE)
    base.add_table(doc, ["Must-have", "Nice-to-have", "관심 낮음"], [
        ("Automatic / 즉시 Off", "업무 시간대 자동 규칙", "소셜 기능"),
        ("명확한 로컬 처리 설명", "화면 공유 시 숨김", "게임화"),
        ("낮은 CPU·배터리 영향", "IT 배포용 문서", "장식용 테마"),
        ("GNSS·오류 상태 표시", "단축키", "클라우드 계정"),
    ], [3120, 3120, 3120], font_size=8.8, header_fill=base.LIGHT_BLUE)
    base.add_label_para(doc, "Retention Trigger", "바쁜 이동일에 도착 전 문서를 끝낸 경험이 반복되고, 회사 정책과 성능 이슈가 없을 때 유지합니다.", base.GREEN)
    base.add_label_para(doc, "Churn Trigger", "관리자 차단, cue 오류, 체감 이득 없음, 화면 방해, 배터리·보안 우려가 한 번이라도 업무 리스크로 느껴질 때 빠르게 삭제합니다.", base.RED)
    add_quote(doc, "도착해서 다시 노트북을 여는 대신, 차 안에서 문서 수정을 끝낼 수 있으면 그 시간이 바로 가치예요.")


def section_7_edge_persona(doc):
    page_break(doc)
    base.add_heading(doc, "7. Future/Edge Persona", 1)
    base.add_heading(doc, "도윤 — GNSS 없는 일반 노트북을 쓰는 잦은 출장자", 2)
    add_small_note(doc, "도윤은 분석을 위한 명시적 가상 이름입니다. 현재 MVP 대상이 아니라 smartphone IMU 가설을 검토하기 위한 edge persona입니다.")
    add_persona_snapshot(doc, [
        ("한 줄 정의", "월 여러 차례 출장하며 지상 이동 중 노트북으로 일을 하지만, 일반 Windows 노트북에 usable GNSS가 없어 현재 MVP를 사용할 수 없는 사용자"),
        ("상황", "공항버스·역 이동·택시 30–120분. 메일, 자료 읽기, 보고서, 회의 준비"),
        ("사용 빈도 가설", "월 2–8회로 불규칙하나 한 번의 시간 가치가 큼 — 가설, 인터뷰 필요"),
        ("현재 MVP 적합", "부적합: built-in Satellite GNSS 없음"),
        ("미래 적합 조건", "Windows 노트북 + 일상적으로 휴대하는 스마트폰 + 간단한 pairing 허용"),
    ])
    base.add_heading(doc, "Core Problem & Trigger", 2)
    base.add_label_para(doc, "Core Problem", "긴 지상 이동 시간에 화면 작업을 계속하고 싶지만 불편 때문에 중단합니다. 필요는 강할 수 있으나 현재 제품의 센서 전제가 이 사용자를 제외합니다.", base.RED)
    base.add_label_para(doc, "Trigger Situation", "공항버스나 택시에서 출장 보고서·다음 회의 자료를 열었지만, 노트북 GNSS 호환성 검사에서 사용할 수 없다는 결과를 받는 순간입니다.", base.GOLD)

    base.add_heading(doc, "Current Alternatives & JTBD", 2)
    for text in [
        "노트북을 닫고 오디오·휴식으로 전환한다 — 준비 업무가 도착 후로 밀린다.",
        "휴대폰으로 단순 메일만 처리한다 — 문서·코딩·복잡한 편집을 대체하지 못한다.",
        "When 일반 노트북으로 이동 중 일해야 할 때, I want to 이미 가진 스마트폰 센서를 간단히 연결하고 싶다, so that 별도 하드웨어 없이 기능을 사용할 수 있다.",
        "When pairing을 허용할 때, I want to 센서 데이터의 범위와 전송 경로를 알고 싶다, so that 위치·개인정보 우려를 통제할 수 있다.",
        "When 출장이 드문 달에도, I want to 연결 상태가 유지되고 자동 재연결되길 원한다, so that 매번 설정을 다시 하지 않아도 된다.",
    ]:
        base.add_bullet(doc, text)

    base.add_heading(doc, "Desired Outcome, Priority & Risk", 2)
    base.add_para(doc, "평범한 Windows 노트북에서도 1분 안에 스마트폰을 연결하고, 실제 차량 움직임과 cue 타이밍이 더 정확해지며, 다음 출장 때 자동으로 재연결되면 성공입니다.")
    add_ranked_items(doc, [
        ("High", "GNSS 부재로 현재 제품 접근 자체가 불가능"),
        ("High", "출장 중 작업 중단의 시간 비용"),
        ("Medium", "pairing·배터리·백그라운드 권한의 번거로움"),
        ("Medium", "스마트폰과 노트북 간 데이터 전송에 대한 privacy 우려"),
        ("Low", "세밀한 시각 테마"),
    ])
    base.add_label_para(doc, "Adoption Motivation", "기존 스마트폰만으로 호환성 문제를 해결하고, GNSS-only보다 움직임 cue의 정확도·반응성을 높일 가능성입니다.", base.BLUE)
    base.add_label_para(doc, "Adoption Barriers", "앱 2개 설치, Bluetooth/Wi‑Fi pairing, 모바일 OS 백그라운드 제한, 스마트폰 배터리, 연결 실패, privacy가 핵심입니다.", base.RED)
    base.add_label_para(doc, "Trust Requirements", "센서 필드·전송 방식·보관 여부 공개, 로컬 네트워크/직접 연결, 즉시 연결 해제, 스마트폰 앱의 배터리 영향 설명이 필요합니다.", base.NAVY)
    base.add_label_para(doc, "Ideal UX", "최초 QR 또는 코드 1회 연결 후 자동 재연결. 실패 시 이유와 해결 단계가 명확해야 합니다.", base.BLUE)
    base.add_table(doc, ["Must-have", "Nice-to-have", "관심 낮음"], [
        ("1분 내 pairing", "복수 폰 관리", "커뮤니티 기능"),
        ("자동 재연결", "USB 유선 fallback", "위치 기록 지도"),
        ("연결·배터리 상태", "센서 품질 진단", "계정 기반 동기화"),
        ("로컬·최소 데이터", "여행 모드 프리셋", "장식 테마"),
    ], [3120, 3120, 3120], font_size=8.8, header_fill=base.LIGHT_BLUE)
    base.add_label_para(doc, "Retention Trigger", "출장 때마다 빠르게 재연결되고 GNSS-only보다 cue가 신뢰할 만하며 배터리 영향이 낮을 때 유지합니다.", base.GREEN)
    base.add_label_para(doc, "Churn Trigger", "pairing 실패, 스마트폰 배터리 소모, 백그라운드 종료, privacy 불신, 체감 효과 없음이 반복될 때 삭제합니다.", base.RED)
    add_quote(doc, "노트북에 GPS가 없다는 이유로 못 쓰는 대신, 늘 들고 다니는 휴대폰으로 바로 연결되면 좋겠어요.")


def section_8_anti_persona(doc):
    base.add_heading(doc, "8. Anti-Persona", 1)
    base.add_heading(doc, "Anti-Persona A — 운전 중 화면을 보려는 사람", 2)
    base.add_callout(doc, "명시적 제외", "MotionCue는 승객용입니다. 운전자의 노트북·화면 사용을 돕는 방향은 안전 목적과 정면으로 충돌하므로 온보딩·문구·사용 안내에서 제외를 분명히 해야 합니다.", accent=base.RED, fill="FCEDED")
    base.add_para(doc, "이 사용자를 겨냥한 기능·메시지·자동화는 제품 위험을 키우고 핵심 승객 경험 학습을 왜곡합니다. 차량 움직임 감지 자체가 운전자 여부를 확정하지 못하므로 안전 문구와 테스트 모집 조건이 필요합니다.")

    base.add_heading(doc, "Anti-Persona B — 불편하면 즉시 화면을 포기하는 저빈도 승객", 2)
    base.add_para(doc, "월 1회 이하 이동 중 노트북을 열고, 조금 불편하면 창밖을 보거나 쉬는 것을 선호하며, 도착 후 작업해도 결과 손실이 거의 없는 사람입니다. 문제 강도·반복성·설치 동기가 낮아 retention을 학습하기 어렵습니다.")

    base.add_heading(doc, "현재 MVP에서의 실무 제외 — GNSS 없는 이상적 사용자", 2)
    base.add_para(doc, "이 사용자는 장기적으로 anti-persona가 아닙니다. 문제와 행동은 잘 맞지만 현재 하드웨어 제약 때문에 ‘MVP 베타 모집’에서는 제외됩니다. 이를 수요 부재로 분류하지 말고 ‘hardware-incompatible lead’로 별도 기록해야 합니다.")

    base.add_table(doc, ["겉보기 매력", "실제 제외 이유", "제품팀 처리"], [
        ("멀미 경험이 강한 운전자", "안전상 사용 맥락이 부적절", "승객 전용 명시, 리서치·마케팅 제외"),
        ("이동이 드문 여행자", "문제와 반복 사용이 약함", "초기 인터뷰 우선순위 낮춤"),
        ("노트북을 거의 안 여는 승객", "핵심 행동이 없음", "스마트폰 사용자 시장과 혼동하지 않음"),
        ("GNSS 없는 고통 사용자", "현재 MVP 실행 불가", "미래 IMU 후보로 별도 축적"),
    ], [2600, 3280, 3480], font_size=8.8, header_fill=base.LIGHT)


def section_9_early_adopter(doc):
    base.add_heading(doc, "9. Early Adopter 정의", 1)
    base.add_para(doc, "이상적인 early adopter는 주 3일 이상 30분 넘는 지상 교통수단을 승객으로 이용하고, 주 2회 이상 Windows 노트북을 실제로 열며, 최근 한 달 안에 불편 때문에 읽기·작성·코딩을 중단하거나 미룬 경험이 있고, 그럼에도 마감·업무 때문에 화면 사용을 계속하고 싶어 하는 사람입니다. 로컬 처리 설명을 이해한 뒤 tray utility 설치와 위치 권한을 허용하고, 동일한 이동 상황에서 2–3회 비교 테스트와 짧은 회고에 참여할 의지가 있어야 합니다.")

    base.add_heading(doc, "Early User Recruiting Criteria", 2)
    base.add_callout(doc, "필수 게이트 2개", "① 운전자가 아닌 승객  ② Windows 11 노트북에서 usable Satellite GNSS 확인. 둘 중 하나라도 실패하면 현재 MVP 베타가 아니라 인터뷰 또는 미래 IMU 대기군으로 분류합니다.", accent=base.RED, fill="FCEDED")
    base.add_para(doc, "필수 게이트를 통과한 뒤, 아래 7개 중 6개 이상을 만족해야 합니다.", bold=True, color=base.NAVY)
    for text in [
        "지상 교통수단 이용이 주 3일 이상이다.",
        "대표 이동 시간이 편도 30분 이상이다.",
        "이동 중 노트북을 주 2회 이상 실제 사용한다.",
        "최근 30일 내 화면 불편으로 작업을 중단·지연한 구체적 사례가 있다.",
        "이동 중 끝내야 하는 과제·업무가 있어 화면 사용을 포기하고 싶지 않다.",
        "로컬 처리·미저장 설명 후 위치 권한과 background utility 설치를 허용할 의사가 있다.",
        "2–3회의 실제 차량 테스트, 전후 상태 기록, 후속 인터뷰에 참여할 수 있다.",
    ]:
        base.add_bullet(doc, text)

    base.add_heading(doc, "User와 Customer 구분", 2)
    base.add_table(doc, ["구조", "User = Customer?", "현재 판단"], [
        ("무료 개인 유틸리티", "대체로 동일", "사용자 본인이 설치·권한·사용 지속을 결정"),
        ("개인 유료 구매", "대체로 동일", "지불 의사와 효과 인식은 별도 검증 필요"),
        ("대학 접근성 프로그램", "다를 수 있음", "학생이 user, 학교가 customer일 가능성; 현재 PMF 아님"),
        ("기업 직원 도구", "다름", "직원이 user, IT·복지·보안 조직이 buyer/gatekeeper; 가설 단계"),
        ("OEM/노트북 제조사", "다름", "최종 사용자가 user, 제조사가 customer; 장기 옵션일 뿐 현재 타깃 아님"),
    ], [2150, 1650, 5560], font_size=8.75, header_fill=base.LIGHT_BLUE)


def section_10_hardware(doc):
    base.add_heading(doc, "10. MVP Hardware Constraint", 1)
    base.add_heading(doc, "Ideal product persona", 2)
    base.add_para(doc, "이동 중 Windows 노트북 작업을 반복하고, 불편 때문에 실제 행동을 중단하지만, 학업·업무 이유로 계속 화면을 봐야 하는 승객입니다. 이 정의에는 GNSS 보유가 포함되지 않습니다. 문제 적합성을 설명하는 페르소나이기 때문입니다.")

    base.add_heading(doc, "MVP-compatible test persona", 2)
    base.add_para(doc, "위의 문제·행동 조건을 충족하면서 Windows 11에서 MotionCue가 요구하는 PositionSource=Satellite의 usable GNSS를 제공하고, 차량 안에서 충분한 update와 신호를 얻으며, 위치 권한·설치에 동의하는 사람입니다.")

    base.add_callout(doc, "Major Customer-Discovery Constraint", "내장 GNSS Windows 노트북이 이상적 사용자 집단에서 드물다면, 초기 MVP 테스터는 필요가 강한 사람의 대표 표본이 아니라 ‘우연히 호환 하드웨어를 가진 소수’로 편향될 수 있습니다. 이는 모집 난이도뿐 아니라 결과의 외적 타당성과 시장 reach를 제한합니다.", accent=base.RED, fill="FCEDED")

    base.add_heading(doc, "모집·분석 운영 원칙", 2)
    base.add_table(doc, ["단계", "확인", "분류/결정"], [
        ("1. 행동 스크리닝", "이동 빈도, 노트북 사용, 중단 사례, 지속 이유", "Need-fit / Non-need-fit"),
        ("2. OS·권한", "Windows 11, 개인/회사 기기, 설치 권한", "Installable / Policy-blocked"),
        ("3. 센서 진단", "Satellite source, 차량 내 availability·update·accuracy", "MVP-compatible / Hardware-incompatible"),
        ("4. 현장 테스트", "cue timing, 불편, 방해, 작업 지속, 오류", "Benefit signal / No signal / Technical invalid"),
        ("5. 결과 해석", "불편 감소 실패와 센서 실패를 분리", "제품가치·알고리즘·하드웨어 원인 구분"),
    ], [1700, 4140, 3520], font_size=8.75, header_fill=base.LIGHT)
    base.add_label_para(doc, "가설/조사 필요", "GNSS 장착 비율, 모델별 PositionSource 동작, 실제 버스·택시에서의 update rate와 signal loss는 먼저 장치 샘플 조사와 field logging으로 확인해야 합니다.", base.RED)


def section_11_smartphone(doc):
    base.add_heading(doc, "11. 미래 Smartphone IMU 적용 시 변화", 1)
    base.add_table(doc, ["차원", "현재: 내장 GNSS", "미래 가설: Smartphone IMU"], [
        ("접근 조건", "Windows 노트북 + usable Satellite GNSS", "일반 Windows 노트북 + 호환 스마트폰"),
        ("타깃 폭", "하드웨어로 크게 제한", "잠재적으로 크게 확대"),
        ("움직임 신호", "속도·heading 기반 coarse cue", "가속도·자이로 기반 더 빠른 cue 가능성"),
        ("설정 마찰", "위치 권한·GNSS 진단", "모바일 앱 설치·pairing·재연결·양쪽 권한"),
        ("신뢰 위험", "위치 추적·저장 우려", "기기 간 센서 전송·모바일 background·배터리 우려"),
        ("대표 페르소나", "GNSS 보유 장거리 버스 통학생", "GNSS 없는 일반 노트북 사용자까지 확대"),
    ], [1700, 3800, 3860], font_size=8.65, header_fill=base.LIGHT_BLUE)
    base.add_label_para(doc, "가설/조사 필요", "스마트폰 IMU가 addressable user base를 실질적으로 확대하고 cue 품질을 높일 가능성은 크지만, 2기기 설치·연결 마찰이 채택을 상쇄할 수 있습니다. GNSS 불호환 lead의 pairing 의향과 실제 연결 성공률로 검증해야 합니다.", base.RED)


def section_12_interviews(doc):
    base.add_heading(doc, "12. Customer Interview 질문", 1)
    base.add_para(doc, "1–11번은 제품을 설명하기 전에 과거 행동을 묻습니다. 12번 이후에만 설치·권한·개념 반응을 확인합니다. 답변은 가능한 한 ‘가장 최근 사례’와 횟수로 구체화합니다.")
    questions = [
        "가장 최근에 버스·택시·승용차의 승객으로 이동하면서 노트북을 사용했던 상황을 처음부터 설명해 주세요.",
        "그 이동은 어디서 어디까지였고, 총 이동 시간과 실제 노트북 사용 시간은 각각 얼마나 됐나요?",
        "이동 중 어떤 작업을 하려 했고, 그 일을 그때 끝내야 했던 이유는 무엇이었나요?",
        "화면을 보는 동안 불편하거나 집중하기 어려웠던 순간이 있었나요? 정확히 언제, 어떤 변화가 있었나요?",
        "그때 작업을 계속했나요, 멈췄나요, 다른 방식으로 바꿨나요? 실제로 한 행동을 순서대로 말해 주세요.",
        "작업을 멈추거나 미룬 결과로 이후 일정·과제·업무에 어떤 일이 생겼나요?",
        "비슷한 일이 지난 30일 동안 몇 번 있었나요? 이동 중 노트북을 연 횟수와 비교하면 어느 정도인가요?",
        "불편할 때 평소 사용하는 대안은 무엇이며, 각 대안에서 가장 아쉬운 점은 무엇인가요?",
        "그럼에도 이동 중 노트북을 계속 사용하려 한 가장 중요한 이유는 무엇이었나요? 반대로 그냥 포기한 때는 왜 그랬나요?",
        "최근 개인 또는 업무용 PC에 background utility를 설치한 사례가 있나요? 무엇을 확인하고 설치·삭제를 결정했나요?",
        "Windows 노트북이 개인 소유인가요, 회사·학교 관리 기기인가요? 앱 설치와 위치 권한을 스스로 결정할 수 있나요?",
        "노트북 앱이 위치 권한을 요청한다면 가장 먼저 어떤 점이 걱정되며, 어떤 설명이나 통제가 있어야 허용할 수 있나요?",
        "위치·움직임 처리가 로컬에서만 되고 계정·업로드·기록 저장이 없다고 설명해도 남는 우려는 무엇인가요?",
        "화면 가장자리에 차량 움직임을 나타내는 작은 점이 자동 표시되는 개념을 잠깐 보여드리면, 가장 먼저 확인하고 싶은 점과 거슬릴 것 같은 점은 무엇인가요?",
        "다음 2주 동안 실제 이동 2–3회에 설치해 비교해 본다면, 계속 설치할지 판단하기 위해 어떤 결과를 기록해야 할까요?",
    ]
    for question in questions:
        item = base.add_numbered(doc, question)
        item.paragraph_format.space_after = Pt(5)
        item.paragraph_format.line_spacing = 1.10
    add_small_note(doc, "인터뷰어 주의: ‘멀미를 줄여준다’고 먼저 약속하지 말고, 실제 과거 행동·결과·현재 대안을 충분히 들은 뒤 개념과 권한 반응을 확인합니다.")


def section_13_assumptions(doc):
    page_break(doc)
    base.add_heading(doc, "13. 검증해야 할 가설", 1)
    base.add_para(doc, "Confidence는 현재 문서에 존재하는 근거 수준입니다. 제품 전제는 High일 수 있지만, 사용자 행동과 효능은 인터뷰·로그·현장 실험 전에는 Low 또는 Unknown으로 유지합니다.")
    rows = [
        ("장거리 통학생이 버스에서 Windows 노트북을 자주 사용한다", "제품 아이디어와 세그먼트 논리뿐; 관찰 데이터 없음", "Low", "행동 인터뷰 12–15명, 최근 30일 사용 횟수 확인"),
        ("화면 불편이 작업 중단·지연으로 이어진다", "문제 가설은 명확하나 MotionCue 타깃 표본 근거 없음", "Low", "최근 사례, 중단 시점, 결과 비용을 인터뷰·일지로 기록"),
        ("사용자는 불편해도 생산성을 위해 화면을 계속 쓰고 싶다", "세그먼트 선정의 핵심 전제", "Low", "포기한 사례와 계속한 사례를 대조하고 대안 비용 확인"),
        ("대학생이 초기 테스트 모집에 가장 접근하기 쉽다", "채널 가설만 존재", "Medium", "2개 대학 채널별 모집 전환율·스크리닝 통과율 비교"),
        ("edge visual cue가 체감 불편 또는 작업 지속성을 개선한다", "유사 개념의 개연성만 있고 이 구현 증거 없음", "Unknown", "동일 노선 내 cue/no-cue 교차 테스트, 증상·중단 시간 측정"),
        ("cue가 작업을 방해하지 않을 정도로 미묘할 수 있다", "UI 의도만 존재", "Unknown", "강도별 distraction·가독성·즉시 Off 비율 측정"),
        ("사용자가 위치 권한을 받아들인다", "로컬·미저장 정책은 설계됨", "Low", "권한 설명 prototype과 실제 허용/거절 이유 테스트"),
        ("내장 GNSS 가용성이 MVP 모집에 충분하다", "Satellite-only 제약만 확정; 보급·차량 성능 자료 없음", "Unknown", "후보 기기 모델 조사, 30대 진단, 실제 차량 field logging"),
        ("GNSS-only 신호가 가감속·좌우 회전을 충분히 빠르게 표현한다", "기술 가설만 존재", "Unknown", "ground truth 대비 latency·direction accuracy·signal loss 측정"),
        ("Automatic background utility가 수동 실행보다 선호된다", "제품 방향과 예상 UX", "Low", "모드 prototype, false activation 허용도, 2주 유지 행동 확인"),
        ("로컬 처리·무계정이 신뢰와 설치에 실질적 영향을 준다", "명확한 privacy 제안은 존재", "Low", "설명 전후 설치 의향보다 실제 권한·설치 행동 비교"),
        ("스마트폰 IMU가 시장을 넓히고 품질을 높인다", "하드웨어 논리상 가능하지만 사용자·기술 증거 없음", "Unknown", "GNSS 불호환 lead pairing test와 sensor prototype field test"),
    ]
    base.add_table(doc, ["Assumption", "Evidence currently available", "Confidence", "How to validate"], rows, [2530, 2530, 1000, 3300], font_size=7.9, aligns=["left", "left", "center", "left"], header_fill=base.LIGHT_BLUE, add_after=False)
    terminal = doc.add_paragraph()
    terminal.paragraph_format.space_before = Pt(0)
    terminal.paragraph_format.space_after = Pt(0)
    terminal.paragraph_format.line_spacing = Pt(1)
    base.set_font(terminal.add_run(" "), size=1, color=base.WHITE)


def section_14_final(doc):
    page_break(doc)
    base.add_heading(doc, "14. 최종 Target Customer Statement", 1)
    base.add_callout(
        doc,
        "Target Customer Statement",
        "MotionCue의 초기 핵심 타깃은 주 3일 이상 30분 넘는 버스 통학 중 Windows 노트북으로 과제·문서 작업을 하다가 화면 불편 때문에 작업을 반복적으로 중단하거나 미루지만, 마감과 학업 시간 확보 때문에 화면 사용을 포기하고 싶지 않은 장거리 통학형 대학생 사용자다.",
        accent=base.BLUE,
        fill=base.LIGHT_BLUE,
    )
    base.add_para(doc, "MVP 베타 모집 시에는 위 문장에 ‘사용 가능한 내장 Satellite GNSS가 확인된 Windows 11 노트북 보유’ 조건을 추가합니다. 이 조건은 고객의 본질적 필요가 아니라 현재 구현의 테스트 제약입니다.")

    base.add_heading(doc, "지금 가장 먼저 검증해야 할 3가지", 1)
    top3 = [
        ("1", "행동·문제", "장거리 버스 통학생이 실제로 이동 중 Windows 노트북을 반복 사용하며, 불편으로 작업을 중단·지연하는 빈도와 결과 비용이 충분히 큰가?", "12–15명 최근 사례 인터뷰 + 1주 이동/작업 일지"),
        ("2", "하드웨어", "필요가 강한 후보 중 usable Satellite GNSS 노트북을 가진 비율과 실제 차량 안 신호 품질이 베타를 구성할 만큼 충분한가?", "기기 진단 30대 + 버스·택시 field logging"),
        ("3", "효능·방해", "GNSS-only edge cue가 no-cue 대비 작업 지속 또는 불편을 개선하면서 시각 방해·오작동을 허용 범위 안에 두는가?", "호환 사용자 5–10명, 동일 노선 교차 테스트"),
    ]
    base.add_table(doc, ["순위", "검증 축", "핵심 질문", "최소 검증"], top3, [650, 1200, 5200, 2310], font_size=8.6, aligns=["center", "center", "left", "left"], header_fill=base.LIGHT_BLUE, add_after=False)
    terminal = doc.add_paragraph()
    terminal.paragraph_format.space_before = Pt(0)
    terminal.paragraph_format.space_after = Pt(0)
    terminal.paragraph_format.line_spacing = Pt(1)
    base.set_font(terminal.add_run(" "), size=1, color=base.WHITE)


def build():
    doc = setup_doc()
    opening(doc)
    section_1_core_conclusion(doc)
    section_2_segments(doc)
    section_3_scoring(doc)
    section_4_primary_target(doc)
    section_5_primary_persona(doc)
    section_6_secondary_persona(doc)
    section_7_edge_persona(doc)
    section_8_anti_persona(doc)
    section_9_early_adopter(doc)
    section_10_hardware(doc)
    section_11_smartphone(doc)
    section_12_interviews(doc)
    section_13_assumptions(doc)
    section_14_final(doc)
    for paragraph in doc.paragraphs:
        paragraph.paragraph_format.widow_control = True
    doc.save(OUT)
    print("MotionCue persona document created")


if __name__ == "__main__":
    build()
