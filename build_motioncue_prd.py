from pathlib import Path
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.section import WD_SECTION
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.enum.style import WD_STYLE_TYPE


OUT = Path(r"C:\Users\sukhe\Desktop\vehicle_mode_for_laptop\MotionCue_제품기획서_v0.1.docx")

# standard_business_brief preset + named Korean-font override
ASCII_FONT = "Calibri"
KO_FONT = "Malgun Gothic"
NAVY = "0B2545"
BLUE = "2E74B5"
DARK_BLUE = "1F4D78"
INK = "20242A"
MUTED = "667085"
LIGHT = "F2F4F7"
LIGHT_BLUE = "E8EEF5"
CALLOUT = "F4F6F9"
BORDER = "D6DCE5"
GOLD = "7A5A00"
RED = "9B1C1C"
GREEN = "1F5D42"
WHITE = "FFFFFF"


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, start=120, bottom=80, end=120):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for m, v in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{m}"))
        if node is None:
            node = OxmlElement(f"w:{m}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(v))
        node.set(qn("w:type"), "dxa")


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def set_cant_split(row):
    tr_pr = row._tr.get_or_add_trPr()
    if tr_pr.find(qn("w:cantSplit")) is None:
        tr_pr.append(OxmlElement("w:cantSplit"))


def set_table_borders(table, color=BORDER, size="6"):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.find(qn("w:tblBorders"))
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = borders.find(qn(f"w:{edge}"))
        if tag is None:
            tag = OxmlElement(f"w:{edge}")
            borders.append(tag)
        tag.set(qn("w:val"), "single")
        tag.set(qn("w:sz"), size)
        tag.set(qn("w:space"), "0")
        tag.set(qn("w:color"), color)


def set_table_geometry(table, widths_dxa, indent_dxa=120):
    total = sum(widths_dxa)
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    table.autofit = False
    tbl = table._tbl
    tbl_pr = tbl.tblPr
    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(total))
    tbl_w.set(qn("w:type"), "dxa")
    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), str(indent_dxa))
    tbl_ind.set(qn("w:type"), "dxa")
    layout = tbl_pr.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        tbl_pr.append(layout)
    layout.set(qn("w:type"), "fixed")

    grid = tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in widths_dxa:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)

    for row in table.rows:
        set_cant_split(row)
        for i, cell in enumerate(row.cells):
            width = widths_dxa[min(i, len(widths_dxa) - 1)]
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.find(qn("w:tcW"))
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(width))
            tc_w.set(qn("w:type"), "dxa")
            set_cell_margins(cell)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    set_table_borders(table)


def set_font(run, size=None, bold=None, color=INK, italic=None, font=ASCII_FONT):
    run.font.name = font
    run._element.get_or_add_rPr()
    rfonts = run._element.rPr.get_or_add_rFonts()
    rfonts.set(qn("w:ascii"), font)
    rfonts.set(qn("w:hAnsi"), font)
    rfonts.set(qn("w:eastAsia"), KO_FONT)
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic
    if color:
        run.font.color.rgb = RGBColor.from_string(color)
    lang = OxmlElement("w:lang")
    lang.set(qn("w:val"), "ko-KR")
    lang.set(qn("w:eastAsia"), "ko-KR")
    run._element.rPr.append(lang)


def set_style_font(style, ascii_font=ASCII_FONT, east_asia=KO_FONT):
    style.font.name = ascii_font
    style._element.get_or_add_rPr()
    rfonts = style._element.rPr.get_or_add_rFonts()
    rfonts.set(qn("w:ascii"), ascii_font)
    rfonts.set(qn("w:hAnsi"), ascii_font)
    rfonts.set(qn("w:eastAsia"), east_asia)


def configure_styles(doc):
    styles = doc.styles
    normal = styles["Normal"]
    set_style_font(normal)
    normal.font.size = Pt(11)
    normal.font.color.rgb = RGBColor.from_string(INK)
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.10

    for name, size, color, before, after in (
        ("Title", 28, NAVY, 0, 5),
        ("Subtitle", 13, MUTED, 0, 14),
        ("Heading 1", 16, BLUE, 16, 8),
        ("Heading 2", 13, BLUE, 12, 6),
        ("Heading 3", 12, DARK_BLUE, 8, 4),
    ):
        style = styles[name]
        set_style_font(style)
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor.from_string(color)
        style.font.bold = name != "Subtitle"
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True
        if name == "Title":
            ppr = style._element.get_or_add_pPr()
            pbdr = ppr.find(qn("w:pBdr"))
            if pbdr is not None:
                ppr.remove(pbdr)

    for style_name, size, color, italic in (
        ("Caption", 9, MUTED, False),
        ("Quote", 10.5, DARK_BLUE, True),
    ):
        style = styles[style_name]
        set_style_font(style)
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor.from_string(color)
        style.font.italic = italic
        style.paragraph_format.space_before = Pt(4)
        style.paragraph_format.space_after = Pt(4)

    if "Table Text" not in styles:
        style = styles.add_style("Table Text", WD_STYLE_TYPE.PARAGRAPH)
    else:
        style = styles["Table Text"]
    set_style_font(style)
    style.font.size = Pt(9.2)
    style.font.color.rgb = RGBColor.from_string(INK)
    style.paragraph_format.space_before = Pt(0)
    style.paragraph_format.space_after = Pt(2)
    style.paragraph_format.line_spacing = 1.05

    if "Table Header" not in styles:
        style = styles.add_style("Table Header", WD_STYLE_TYPE.PARAGRAPH)
    else:
        style = styles["Table Header"]
    set_style_font(style)
    style.font.size = Pt(9.1)
    style.font.bold = True
    style.font.color.rgb = RGBColor.from_string(NAVY)
    style.paragraph_format.space_before = Pt(0)
    style.paragraph_format.space_after = Pt(0)
    style.paragraph_format.line_spacing = 1.0

    if "Small Note" not in styles:
        style = styles.add_style("Small Note", WD_STYLE_TYPE.PARAGRAPH)
    else:
        style = styles["Small Note"]
    set_style_font(style)
    style.font.size = Pt(8.5)
    style.font.color.rgb = RGBColor.from_string(MUTED)
    style.paragraph_format.space_after = Pt(3)


def add_numbering(doc, kind="bullet"):
    numbering = doc.part.numbering_part.element
    abs_ids = [int(x.get(qn("w:abstractNumId"))) for x in numbering.findall(qn("w:abstractNum"))]
    num_ids = [int(x.get(qn("w:numId"))) for x in numbering.findall(qn("w:num"))]
    abs_id = max(abs_ids, default=0) + 1
    num_id = max(num_ids, default=0) + 1
    abstract = OxmlElement("w:abstractNum")
    abstract.set(qn("w:abstractNumId"), str(abs_id))
    multi = OxmlElement("w:multiLevelType")
    multi.set(qn("w:val"), "singleLevel")
    abstract.append(multi)
    lvl = OxmlElement("w:lvl")
    lvl.set(qn("w:ilvl"), "0")
    start = OxmlElement("w:start")
    start.set(qn("w:val"), "1")
    lvl.append(start)
    num_fmt = OxmlElement("w:numFmt")
    num_fmt.set(qn("w:val"), "bullet" if kind == "bullet" else "decimal")
    lvl.append(num_fmt)
    lvl_text = OxmlElement("w:lvlText")
    lvl_text.set(qn("w:val"), "•" if kind == "bullet" else "%1.")
    lvl.append(lvl_text)
    jc = OxmlElement("w:lvlJc")
    jc.set(qn("w:val"), "left")
    lvl.append(jc)
    ppr = OxmlElement("w:pPr")
    tabs = OxmlElement("w:tabs")
    tab = OxmlElement("w:tab")
    tab.set(qn("w:val"), "num")
    tab.set(qn("w:pos"), "720")
    tabs.append(tab)
    ppr.append(tabs)
    ind = OxmlElement("w:ind")
    ind.set(qn("w:left"), "720")
    ind.set(qn("w:hanging"), "360")
    ppr.append(ind)
    spacing = OxmlElement("w:spacing")
    spacing.set(qn("w:after"), "160")
    spacing.set(qn("w:line"), "280")
    spacing.set(qn("w:lineRule"), "auto")
    ppr.append(spacing)
    lvl.append(ppr)
    rpr = OxmlElement("w:rPr")
    rfonts = OxmlElement("w:rFonts")
    rfonts.set(qn("w:ascii"), ASCII_FONT)
    rfonts.set(qn("w:hAnsi"), ASCII_FONT)
    rfonts.set(qn("w:eastAsia"), KO_FONT)
    rpr.append(rfonts)
    lvl.append(rpr)
    abstract.append(lvl)
    existing_nums = numbering.findall(qn("w:num"))
    if existing_nums:
        numbering.insert(numbering.index(existing_nums[0]), abstract)
    else:
        numbering.append(abstract)
    num = OxmlElement("w:num")
    num.set(qn("w:numId"), str(num_id))
    abs_ref = OxmlElement("w:abstractNumId")
    abs_ref.set(qn("w:val"), str(abs_id))
    num.append(abs_ref)
    numbering.append(num)
    return num_id


def apply_num(paragraph, num_id):
    ppr = paragraph._p.get_or_add_pPr()
    num_pr = ppr.find(qn("w:numPr"))
    if num_pr is None:
        num_pr = OxmlElement("w:numPr")
        ppr.append(num_pr)
    ilvl = OxmlElement("w:ilvl")
    ilvl.set(qn("w:val"), "0")
    num = OxmlElement("w:numId")
    num.set(qn("w:val"), str(num_id))
    num_pr.append(ilvl)
    num_pr.append(num)


def add_bullet(doc, text, bold_prefix=None):
    p = doc.add_paragraph()
    apply_num(p, doc._bullet_num_id)
    if bold_prefix and text.startswith(bold_prefix):
        r = p.add_run(bold_prefix)
        set_font(r, bold=True)
        r = p.add_run(text[len(bold_prefix):])
        set_font(r)
    else:
        set_font(p.add_run(text))
    return p


def add_numbered(doc, text):
    p = doc.add_paragraph()
    apply_num(p, doc._decimal_num_id)
    set_font(p.add_run(text))
    return p


def add_para(doc, text="", bold=False, italic=False, color=INK, size=11, align=None, after=6):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(after)
    if align is not None:
        p.alignment = align
    set_font(p.add_run(text), size=size, bold=bold, italic=italic, color=color)
    return p


def add_label_para(doc, label, text, color):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    set_font(p.add_run(f"[{label}] "), bold=True, color=color)
    set_font(p.add_run(text), color=INK)
    return p


def add_callout(doc, title, text, accent=BLUE, fill=CALLOUT):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(8)
    p.paragraph_format.left_indent = Inches(0.14)
    p.paragraph_format.right_indent = Inches(0.08)
    p.paragraph_format.space_after = Pt(8)
    ppr = p._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    ppr.append(shd)
    pbdr = OxmlElement("w:pBdr")
    left = OxmlElement("w:left")
    left.set(qn("w:val"), "single")
    left.set(qn("w:sz"), "18")
    left.set(qn("w:space"), "5")
    left.set(qn("w:color"), accent)
    pbdr.append(left)
    ppr.append(pbdr)
    set_font(p.add_run(f"{title}  "), bold=True, color=accent)
    set_font(p.add_run(text))
    return p


def add_heading(doc, text, level=1):
    p = doc.add_paragraph(style=f"Heading {level}")
    set_font(p.add_run(text), size={1:16,2:13,3:12}[level], bold=True,
             color={1:BLUE,2:BLUE,3:DARK_BLUE}[level])
    return p


def add_caption(doc, text):
    p = doc.add_paragraph(style="Caption")
    set_font(p.add_run(text), size=9, color=MUTED)
    return p


def add_table(doc, headers, rows, widths, font_size=9.2, aligns=None, header_fill=LIGHT, add_after=True):
    table = doc.add_table(rows=1, cols=len(headers))
    set_table_geometry(table, widths)
    set_repeat_table_header(table.rows[0])
    for i, header in enumerate(headers):
        cell = table.rows[0].cells[i]
        set_cell_shading(cell, header_fill)
        p = cell.paragraphs[0]
        p.style = doc.styles["Table Header"]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER if aligns and aligns[i] == "center" else WD_ALIGN_PARAGRAPH.LEFT
        set_font(p.add_run(header), size=9.1, bold=True, color=NAVY)
    for row_data in rows:
        row = table.add_row()
        for i, value in enumerate(row_data):
            cell = row.cells[i]
            p = cell.paragraphs[0]
            p.style = doc.styles["Table Text"]
            if aligns:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER if aligns[i] == "center" else WD_ALIGN_PARAGRAPH.LEFT
            set_font(p.add_run(str(value)), size=font_size, color=INK)
    set_table_geometry(table, widths)
    if add_after:
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(2)
    return table


def add_hyperlink(paragraph, text, url):
    part = paragraph.part
    r_id = part.relate_to(url, "http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink", is_external=True)
    hyperlink = OxmlElement("w:hyperlink")
    hyperlink.set(qn("r:id"), r_id)
    run = OxmlElement("w:r")
    rpr = OxmlElement("w:rPr")
    color = OxmlElement("w:color")
    color.set(qn("w:val"), BLUE)
    rpr.append(color)
    underline = OxmlElement("w:u")
    underline.set(qn("w:val"), "single")
    rpr.append(underline)
    rfonts = OxmlElement("w:rFonts")
    rfonts.set(qn("w:ascii"), ASCII_FONT)
    rfonts.set(qn("w:hAnsi"), ASCII_FONT)
    rfonts.set(qn("w:eastAsia"), KO_FONT)
    rpr.append(rfonts)
    run.append(rpr)
    t = OxmlElement("w:t")
    t.text = text
    run.append(t)
    hyperlink.append(run)
    paragraph._p.append(hyperlink)


def add_page_field(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    set_font(paragraph.add_run("MotionCue 제품 기획서  |  "), size=8.5, color=MUTED)
    for field_name in ("PAGE", "NUMPAGES"):
        if field_name == "NUMPAGES":
            set_font(paragraph.add_run(" / "), size=8.5, color=MUTED)
        fld = OxmlElement("w:fldSimple")
        fld.set(qn("w:instr"), field_name)
        r = OxmlElement("w:r")
        t = OxmlElement("w:t")
        t.text = "1"
        r.append(t)
        fld.append(r)
        paragraph._p.append(fld)


def setup_doc():
    doc = Document()
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.82)
    section.bottom_margin = Inches(0.78)
    section.left_margin = Inches(1.0)
    section.right_margin = Inches(1.0)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)
    configure_styles(doc)
    doc._bullet_num_id = add_numbering(doc, "bullet")
    doc._decimal_num_id = add_numbering(doc, "decimal")
    header = section.header
    hp = header.paragraphs[0]
    hp.alignment = WD_ALIGN_PARAGRAPH.LEFT
    set_font(hp.add_run("MOTIONCUE  /  PRODUCT PLANNING DOCUMENT  v0.1"), size=8.3, bold=True, color=MUTED)
    footer = section.footer
    add_page_field(footer.paragraphs[0])
    core = doc.core_properties
    core.title = "MotionCue 제품 기획서 v0.1"
    core.subject = "Windows 11 노트북용 차량 움직임 시각 단서 애플리케이션"
    core.author = "MotionCue Product Planning"
    core.keywords = "MotionCue, Windows, GNSS, Vehicle Motion Cues, Product Plan"
    return doc


def summary_page(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after = Pt(2)
    set_font(p.add_run("PRODUCT PLANNING DOCUMENT"), size=9, bold=True, color=BLUE)
    p = doc.add_paragraph(style="Title")
    set_font(p.add_run("MotionCue"), size=28, bold=True, color=NAVY)
    p = doc.add_paragraph(style="Subtitle")
    set_font(p.add_run("Windows 11 노트북용 차량 움직임 시각 단서 애플리케이션"), size=13, color=MUTED)
    add_para(doc, "문서 버전 v0.1  |  기준일 2026-08-19  |  상태: 1차 제품 기획 초안", size=9.2, color=MUTED, after=10)
    add_callout(doc, "한 줄 정의", "이동 중 Windows 노트북 화면 가장자리에 차량의 큰 움직임을 반영한 점 애니메이션을 표시해, 사용자가 화면 작업을 계속할 때 느끼는 불편을 줄일 가능성을 검증하는 로컬 데스크톱 도구입니다.")
    rows = [
        ("Problem", "이동 차량에서 고정된 노트북 화면에 시선을 두면 실제 신체 움직임과 시각 정보가 어긋나 불편이 생기고, 읽기·작업을 중단하게 된다."),
        ("Target User", "버스·택시·승용차 등 지상 교통수단에서 노트북을 사용하는 승객. 특히 장거리 통학생, 통근자, 출장자와 화면 사용 시 불편을 자주 느끼는 사람."),
        ("Solution", "Windows 화면 가장자리의 미세한 원형 cue가 GNSS에서 추정한 가속·감속·좌/우 회전을 표현한다. 기본은 Automatic이며 tray에서 On/Off를 선택한다."),
        ("Core Value", "별도 기기나 계정 없이, 주 작업을 가리지 않고, 위치 기록을 저장하지 않으며, 이동 중 노트북 사용 지속 가능성을 높일 수 있다."),
        ("MVP", "Windows 11 + 노트북 내장 GNSS + Satellite source만 허용. 위치·속도·heading·timestamp로 큰 움직임만 추정하고 overlay를 표시한다."),
        ("Primary Risk", "내장 GNSS 보급률·실제 update rate·신호 손실과 노트북 방향 가정 때문에 cue가 늦거나 틀릴 수 있다. 이는 제품의 성립 여부를 결정하는 위험이다."),
        ("Validation Goal", "GNSS-only 방식이 실제 버스/택시 환경에서 충분히 빠르고 안정적인 cue를 만들며, 5–10명 테스트에서 불편 감소 신호와 낮은 시각 방해를 보이는지 확인한다."),
    ]
    add_table(doc, ["항목", "요약"], rows, [1740, 7620], font_size=9.0)
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after = Pt(3)
    set_font(p.add_run("문서 표기 규칙  "), size=8.5, bold=True, color=NAVY)
    for label, color, desc in (
        ("확정 사실", NAVY, "제공된 제품 전제 또는 공식 문서로 확인"),
        ("제품 결정", BLUE, "현재 초안이 선택한 방향"),
        ("가정", GOLD, "설계를 시작하기 위한 임시 전제"),
        ("가설/검증 필요", RED, "사용자·현장 데이터가 필요한 주장"),
    ):
        set_font(p.add_run(f"[{label}] "), size=8.3, bold=True, color=color)
        set_font(p.add_run(desc + "   "), size=8.3, color=MUTED)
    doc.add_page_break()


def section_1_5(doc):
    add_heading(doc, "1. Executive Summary", 1)
    add_label_para(doc, "확정 사실", "MotionCue는 Windows 11 노트북을 위한 desktop overlay 애플리케이션이다. 차량 탑승 중 화면 가장자리에 움직이는 원형 cue를 표시하며, 위치·motion 처리는 애플리케이션 내부에서 수행하고 계정·backend·cloud analytics를 요구하지 않는다.", NAVY)
    add_label_para(doc, "제품 결정", "MVP는 Windows Location API가 반환한 데이터 중 PositionSource가 Satellite인 경우만 motion 입력으로 인정한다. Wi‑Fi, Cellular, IPAddress, Default, Obfuscated, Unknown source는 움직임 추정에서 제외한다.", BLUE)
    add_label_para(doc, "가정", "속도 변화와 heading 변화의 시간 미분을 smoothing하면 급가속·감속과 큰 좌/우 회전을 약 1 Hz급 GNSS에서도 사용 가능한 수준으로 표현할 수 있다.", GOLD)
    add_label_para(doc, "가설/검증 필요", "시각 단서가 실제 Windows 노트북 사용자의 체감 불편을 낮추고 작업 지속 시간을 늘린다. 임상적 치료·예방 효과는 주장하지 않는다.", RED)
    add_callout(doc, "핵심 판단", "MotionCue의 첫 제품은 ‘완성된 motion-sickness solution’이 아니라 ‘GNSS-only 방식의 유용성을 검증하는 제한적 comfort/accessibility MVP’로 정의해야 합니다.", accent=NAVY, fill=LIGHT_BLUE)

    add_heading(doc, "2. Problem Definition", 1)
    add_para(doc, "이동 차량에서 노트북을 사용할 때 사용자의 시선은 화면이라는 고정된 시각 좌표계에 묶인다. 동시에 전정·체성 감각은 가속, 제동, 회전, 노면 움직임을 감지한다. 이 불일치는 일부 사용자에게 메스꺼움, 어지러움, 집중 저하 또는 작업 중단으로 이어질 수 있다. 감수성은 개인·좌석·노선·시선·작업 종류에 따라 크게 달라진다.")
    add_bullet(doc, "핵심 행동 문제: 사용자는 필요한 읽기·쓰기·업무를 끝내지 못하고 화면을 끄거나 자주 밖을 본다.", "핵심 행동 문제:")
    add_bullet(doc, "제품 기회: 주 콘텐츠를 가리지 않는 peripheral cue로 실제 이동 정보를 화면 경험에 보충한다.", "제품 기회:")
    add_bullet(doc, "표현 한계: ‘도움을 줄 수 있음’, ‘체감 불편 완화 가능성’으로 표현하며 치료·예방·보장 문구를 사용하지 않는다.", "표현 한계:")
    add_label_para(doc, "근거", "Apple은 공식 지원 문서에서 화면 가장자리 animated dots가 차량 움직임을 표현하고 motion sickness를 줄이는 데 도움이 될 수 있다고 설명한다. 관련 CHI 연구도 실제 차량 motion을 시각적으로 제공하는 접근을 탐색했지만, 모든 사용자에게 단일 최적 표현이 없음을 보고한다. [S1][S6]", NAVY)

    add_heading(doc, "3. User Problem Scenario", 1)
    scenarios = [
        ("Scenario A — 장거리 버스 통학생", "상황", "편도 50분 버스에서 과제 자료를 읽고 수정한다.", "현재 행동", "10–15분마다 화면을 끄고 창밖을 보거나 작업을 포기한다.", "Pain point", "제동·차선 변경이 잦을수록 화면 집중이 어려워진다.", "MotionCue 변화", "Automatic cue가 이동 중에만 나타나고 큰 가감속·회전을 주변 시야에 전달한다. 사용자는 cue를 의식적으로 조작하지 않고 작업 지속 여부를 판단한다."),
        ("Scenario B — 택시 뒷좌석 직장인", "상황", "30분 이동 중 문서 검토와 메신저 답변을 마쳐야 한다.", "현재 행동", "급회전 구간에서 화면을 내려놓고 도착 후 일을 미룬다.", "Pain point", "시간 압박은 높지만 별도 sensor를 설치하거나 설정할 여유가 없다.", "MotionCue 변화", "tray에 상주한 앱이 이동을 감지해 cue를 켜고 정차 후 숨긴다. 다만 택시 내부에서 GNSS가 불안정하면 즉시 unavailable 상태를 명확히 알린다."),
        ("Scenario C — 지상 교통 출장자", "상황", "공항버스·렌터카 조수석 등 낯선 노선에서 일정과 자료를 확인한다.", "현재 행동", "불편 가능성을 우려해 노트북 사용 자체를 피한다.", "Pain point", "기기마다 설정이 다르고 이동 환경의 신호 품질을 예측할 수 없다.", "MotionCue 변화", "첫 실행의 hardware check와 journey 중 quality indicator로 사용 가능 여부를 미리 이해한다. 실패할 때도 ‘왜 작동하지 않는지’를 알 수 있다."),
    ]
    for title, *parts in scenarios:
        add_heading(doc, title, 2)
        for i in range(0, len(parts), 2):
            p = doc.add_paragraph()
            set_font(p.add_run(parts[i] + ": "), bold=True, color=DARK_BLUE)
            set_font(p.add_run(parts[i+1]))
    add_callout(doc, "안전 경계", "운전자 사용을 지원하지 않습니다. onboarding과 Settings에 ‘승객용이며, 운전 중 사용 금지 / 차량 진행 방향을 향해 앉을 때 가장 적합’이라는 안내를 포함합니다.", accent=RED, fill="FDF2F2")

    add_heading(doc, "4. Existing Alternatives (Preliminary)", 1)
    add_label_para(doc, "검증 필요", "아래는 공식 Apple 기능과 일반적 사용자 대안을 중심으로 한 preliminary 분석이다. Windows용 직접 경쟁 앱의 시장 규모·가격·리뷰·특허·배포 상태는 별도 competitor research가 필요하다.", RED)
    rows = [
        ("노트북 사용 중단", "즉시 가능, 안전함", "생산성·읽기 목표를 포기", "대체재이자 가장 강한 경쟁 행동"),
        ("주기적으로 창밖 보기", "비용 없음", "작업 흐름이 끊기고 개인차 큼", "MotionCue와 병행 가능"),
        ("휴대폰/태블릿 전환", "일부 Apple 기기에서 유사 기능", "Windows 작업·키보드·대화면 맥락을 잃음", "완전 대체가 아님"),
        ("Apple Vehicle Motion Cues", "iPhone 및 지원 Mac laptop에서 system-level 제공", "Windows 사용자는 이용 불가", "카테고리 검증 신호이자 UX 기준점"),
        ("불편 감수", "설치·설정 없음", "사용 중단·피로·불안", "낮은 설치 의향의 원인"),
    ]
    add_table(doc, ["대안", "장점", "부족한 점", "제품 의미"], rows, [1700, 1900, 2900, 2860], font_size=8.7)
    add_para(doc, "2026년 8월 기준 Apple은 iPhone뿐 아니라 일부 Mac laptop에도 Vehicle Motion Cues를 제공한다. 따라서 ‘노트북 최초’가 아니라 ‘Windows-native 구현’이 정확한 포지셔닝이다. [S1][S2]", size=9, color=MUTED)

    add_heading(doc, "5. Product Value Proposition", 1)
    values = [
        ("Functional value", "가속·감속·큰 좌/우 회전을 화면 가장자리 cue로 표현"),
        ("Convenience value", "설치·location permission 후 Automatic; phone·USB·Bluetooth 없음"),
        ("Productivity value", "이동 중 읽기·검토·작업을 계속할 가능성 확대"),
        ("Accessibility / comfort value", "주 콘텐츠를 가리지 않는 주변 시야 단서와 개인화 옵션"),
        ("Privacy value", "계정·서버·telemetry 없이 앱 수준의 motion 처리를 local로 수행; raw location history 미저장"),
    ]
    add_table(doc, ["가치", "MotionCue가 제공하는 방식"], values, [2500, 6860], font_size=9.3)
    add_callout(doc, "Positioning statement", "차량 이동 중 Windows 노트북 작업을 계속하고 싶은 승객을 위해, MotionCue는 별도 기기 없이 노트북의 satellite GNSS를 사용해 화면 가장자리에 큰 차량 움직임을 나타내는 가벼운 로컬 overlay를 제공합니다.", accent=BLUE, fill=LIGHT_BLUE)


def section_6_10(doc):
    add_heading(doc, "6. Target Customer Overview", 1)
    add_label_para(doc, "가설/검증 필요", "아래 segment의 규모, GNSS 보유율, 지불 의향, 불편 빈도는 확인되지 않았다. 초기 모집·인터뷰 우선순위를 위한 hypothesis다.", RED)
    rows = [
        ("장거리 버스 통학생", "높음", "주 3–10회", "중간: 무료/저가 기대, GNSS 불확실", "과제·독서 지속"),
        ("통근 직장인", "중–높음", "주 2–10회", "중간: 회사 PC 설치 권한", "이동 시간 활용"),
        ("출장자", "중간", "월 1–6회", "낮–중간: 필요 순간이 명확", "택시·버스에서 업무 연속성"),
        ("Digital nomad / 이동 근무자", "중간", "환경별 편차", "중간: 다양한 기기·노선", "모바일 업무 도구"),
        ("화면 사용 시 불편 민감 사용자", "매우 높음", "탑승 때마다", "높음: 효과 불확실·악화 우려", "comfort/accessibility 가치"),
    ]
    add_table(doc, ["Segment", "Need", "빈도", "Adoption friction", "주요 가치"], rows, [2050, 900, 1250, 2650, 2510], font_size=8.5, aligns=["left","center","center","left","left"])
    add_callout(doc, "초기 타깃", "내장 GNSS가 확인된 Windows 11 노트북을 보유하고, 주 2회 이상 지상 교통에서 노트북을 쓰며, 불편 때문에 작업을 중단한 경험이 있는 승객.")

    add_heading(doc, "7. Jobs To Be Done", 1)
    add_heading(doc, "Functional jobs", 2)
    for text in (
        "When 버스나 택시에서 노트북으로 읽거나 일해야 할 때, I want to 차량의 큰 움직임을 화면 주변에서 함께 인지하고, so that 작업을 가능한 한 오래 이어가고 싶다.",
        "When 이동이 시작되거나 끝날 때, I want to 앱이 알아서 cue를 켜고 끄고, so that 매번 tray를 조작하지 않아도 된다.",
        "When GNSS가 사용할 수 없을 때, I want to 원인과 해결 가능 여부를 즉시 알고, so that 작동하지 않는 기능을 기다리지 않는다.",
    ): add_bullet(doc, text)
    add_heading(doc, "Emotional jobs", 2)
    for text in (
        "When 이동 중 화면 사용을 시작할 때, I want to 불편이 생길까 걱정하는 정도를 낮추고, so that 필요한 일을 시도할 수 있다.",
        "When location permission을 허용할 때, I want to 위치가 서버나 history로 남지 않는다고 이해하고, so that 안심하고 기능을 켤 수 있다.",
    ): add_bullet(doc, text)
    add_heading(doc, "Situational jobs", 2)
    for text in (
        "When 신호가 터널·도심 협곡에서 끊길 때, I want to cue가 갑자기 잘못 움직이지 않고 부드럽게 사라지길 원한다.",
        "When 전체화면 영상·문서·회의 앱을 사용할 때, I want to cue가 클릭을 가로채거나 내용을 가리지 않길 원한다.",
    ): add_bullet(doc, text)

    add_heading(doc, "8. Product Requirements", 1)
    req_rows = [
        ("Must", "Satellite GNSS gate", "PositionSource==Satellite만 허용; Accuracy/Speed/Heading/Timestamp quality check"),
        ("Must", "Motion estimation", "속도 변화→longitudinal cue, unwrapped heading 변화→좌/우 회전 cue; smoothing·outlier rejection"),
        ("Must", "Overlay rendering", "항상 위, click-through, per-monitor DPI 대응, 주 콘텐츠를 가리지 않는 edge dots, 안정적 FPS"),
        ("Must", "Automatic / On / Off", "기본 Automatic; On은 데이터가 유효할 때 cue 표시를 강제, Off는 수집·표시 중단"),
        ("Must", "System tray", "Automatic / On / Off / Settings / Quit와 상태 표시"),
        ("Must", "Unavailable handling", "권한 거부, hardware 없음, no fix, signal loss를 구분하고 Wi‑Fi/IP fallback 금지"),
        ("Must", "Local processing", "계정·backend·telemetry 없음, precise history 미저장"),
        ("Must", "Developer simulation", "production UI에서 숨긴 deterministic trace 재생·가감속·회전 simulation"),
        ("Should", "Start with Windows", "opt-in startup preference와 재시작 후 mode 유지"),
        ("Should", "Minimal appearance", "Regular/Dynamic, color, Larger Dots, More Dots; 기본값 우선"),
        ("Should", "Diagnostic export", "명시적 사용자 동작으로 derived quality log만 export; raw coordinates 기본 제외"),
        ("Could", "Multi-monitor", "primary display 우선 후 monitor별 overlay/선택 지원"),
        ("Could", "Smartphone IMU", "iPhone/Android 센서 source와 pairing"),
        ("Won't yet", "Fine vibration / bumps", "GNSS-only에서 표현하지 않음"),
        ("Won't yet", "Vehicle classification", "걷기/자전거/버스/택시 구분 없음"),
        ("Won't yet", "Cloud analytics / account", "제품 원칙상 제외"),
        ("Won't yet", "Medical claims", "임상 치료·예방·효과 보장 없음"),
    ]
    add_table(doc, ["Priority", "Requirement", "Acceptance intent"], req_rows, [1200, 2300, 5860], font_size=8.55)

    add_heading(doc, "9. MVP Scope", 1)
    add_heading(doc, "MVP가 증명해야 하는 것", 2)
    for text in (
        "Windows laptop의 Satellite GNSS가 실제 도로 환경에서 충분한 연속성과 update rate를 제공한다.",
        "속도·heading 변화만으로도 사용자가 방향을 이해할 수 있는 큰 움직임 cue를 만들 수 있다.",
        "Automatic activation과 edge overlay가 일반 Windows 작업을 방해하지 않는다.",
        "작은 사용자 테스트에서 체감 comfort·작업 지속 의향의 긍정 신호가 나온다.",
    ): add_bullet(doc, text)
    add_heading(doc, "MVP가 증명하지 않는 것", 2)
    for text in (
        "accelerometer/gyroscope 수준의 즉각성, bump·진동·짧은 회전 표현.",
        "Apple 구현과 동일한 효과 또는 임상적 유효성.",
        "GNSS가 없는 대다수 Windows 노트북에서의 시장성.",
        "smartphone IMU 연결·sensor fusion·상용 규모 distribution.",
    ): add_bullet(doc, text)
    add_callout(doc, "범위 문장", "MVP 성공 = ‘GNSS-only가 제한 조건 안에서 유용한 coarse motion cue를 제공한다’이며, ‘모든 Windows 노트북에서 Apple과 동등하게 작동한다’가 아닙니다.", accent=RED, fill="FDF2F2")

    add_heading(doc, "10. Key Product Hypotheses", 1)
    hyp_rows = [
        ("H1 Windows 수요", "높음", "높음", "15–20명 problem interview; fake-door landing page; 설치 의향 질문"),
        ("H2 cue가 체감 comfort 개선", "매우 높음", "매우 높음", "동일 노선 A/B crossover, 7점 척도·작업 지속 시간·중단 횟수"),
        ("H3 GNSS rate가 coarse cue에 충분", "매우 높음", "매우 높음", "3종 이상 GNSS laptop, open sky/도심/터널에서 trace·latency 측정"),
        ("H4 Automatic 선호", "중–높음", "중간", "manual vs Automatic 선호·override 횟수 관찰"),
        ("H5 tray-only UI 선호", "중간", "중간", "5초 task test, 설정 발견성·방해도 인터뷰"),
        ("H6 GNSS requirement 수용", "높음", "매우 높음", "대상 노트북 hardware audit, eligibility funnel, 이탈 이유"),
        ("H7 forward-facing 가정 수용", "높음", "높음", "좌석·laptop orientation별 direction identification test"),
        ("H8 privacy가 설치 결정을 돕는다", "중간", "중간", "local-only 설명 전/후 permission 수락 의향 비교"),
    ]
    add_table(doc, ["Hypothesis", "중요도", "불확실성", "Validation method"], hyp_rows, [2450, 1000, 1150, 4760], font_size=8.35, aligns=["left","center","center","left"])


def section_11_15(doc):
    add_heading(doc, "11. User Journey", 1)
    add_callout(doc, "Happy path", "Discovery → Download → Install → First launch → 위치 사용 이유 확인 → Windows permission → Satellite hardware/fix check → Automatic → 이동 감지 → cue 활성화 → 정상 작업 → 정차 지속 → cue fade-out", accent=BLUE, fill=LIGHT_BLUE)
    journey = [
        ("Discovery / Download", "문제와 제한 이해", "승객용·GNSS 필요·medical claim 없음", "과장된 효과 기대"),
        ("Install / First launch", "빠른 신뢰 형성", "local-only, 미저장, permission 이유", "location 거부"),
        ("Hardware check", "사용 가능성 확인", "Satellite source / no hardware / waiting for fix", "Wi‑Fi 위치를 GNSS로 오인"),
        ("Automatic idle", "평소에는 보이지 않음", "tray status만 유지", "stationary jitter로 activation"),
        ("Movement", "cue가 자연스럽게 등장", "2단계 fade-in, 품질이 낮으면 hold", "늦은 cue·잘못된 방향"),
        ("Normal use", "클릭·전체화면 방해 없음", "click-through, contrast adaptation", "visual distraction"),
        ("Journey end", "자동으로 사라짐", "정차 hysteresis 후 fade-out", "신호 손실을 정차로 오인"),
    ]
    add_table(doc, ["단계", "User goal", "제품 응답", "Failure risk"], journey, [1700, 1900, 3260, 2500], font_size=8.5)
    add_heading(doc, "Failure paths", 2)
    failures = [
        ("Permission denied", "tray에 ‘위치 권한 필요’; Windows Settings deep link; 재요청 spam 없음"),
        ("GNSS hardware / Satellite source 없음", "‘이 PC에서는 GNSS motion cue를 사용할 수 없음’; Wi‑Fi/IP로 대체하지 않음"),
        ("GPS fix 대기", "‘위성 신호 찾는 중’; timeout 후 사용 불가 안내, background에서 재시도 정책 검증"),
        ("Signal loss", "마지막 motion을 즉시 연장하지 않고 1–2초 hold 후 neutral/fade; 복귀 시 abrupt jump 방지"),
        ("Heading/Speed null", "position delta 기반 보조 추정은 Satellite+quality 기준 안에서만 허용; 품질 미달이면 cue 숨김"),
    ]
    add_table(doc, ["Failure", "UX / Product behavior"], failures, [2300, 7060], font_size=9.0)

    add_heading(doc, "12. UX Principles", 1)
    principles = [
        ("1. Invisible until needed", "일상 작업에서는 overlay를 숨기고 tray에만 존재한다."),
        ("2. Zero cognitive overhead", "기본 Automatic; 첫 설정 후 반복 조작을 요구하지 않는다."),
        ("3. Never interfere", "click-through, focus 미획득, taskbar·app input 방해 금지."),
        ("4. Subtle but legible", "주변 시야에서 읽히되 콘텐츠보다 우선하지 않는다. 대비·크기·개수는 제한적으로 조정한다."),
        ("5. Predictable motion", "noise·outlier를 직접 표시하지 않고 smoothing·hysteresis·rate limit로 안정화한다."),
        ("6. Privacy by default", "raw location 미저장, account/telemetry 없음, 진단 export는 사용자가 명시적으로 수행한다."),
        ("7. Graceful failure", "잘못된 cue보다 cue 없음이 낫다. source·permission·fix·signal loss를 구분한다."),
    ]
    add_table(doc, ["Principle", "의미"], principles, [2600, 6760], font_size=9.2)

    add_heading(doc, "13. Technical Product Constraints", 1)
    add_label_para(doc, "확정 사실", "Windows.Devices.Geolocation은 위치를 GNSS, Wi‑Fi, cellular, IP, user default 등 여러 source에서 제공하며, Heading과 Speed는 optional이다. ReportInterval 요청도 hardware가 보장하지 않는다. [S3][S4][S5]", NAVY)
    constraints = [
        ("GNSS sampling", "IMU보다 느리고 짧은 변화·bump를 놓침", "coarse cue만 약속; filtering window와 latency budget을 실측"),
        ("Hardware availability", "많은 laptop에 GNSS가 없을 가능성", "첫 실행 eligibility check; Phase 0에서 표본 hardware audit; phone IMU pivot gate"),
        ("Source ambiguity", "Windows가 network source로 전환 가능", "PositionSource==Satellite hard gate; Obfuscated 포함 fallback 거부"),
        ("Optional fields", "Speed/Heading null·NaN 가능", "Satellite position delta로 제한적 계산; quality 미달 시 unavailable"),
        ("Signal environment", "터널·실내·도심 협곡에서 fix/accuracy 저하", "hold → neutral → fade; route별 availability metric"),
        ("Laptop orientation", "화면 축이 차량 축과 다르면 좌/우 cue가 틀림", "MVP는 forward-facing 가정 명시; orientation test; future phone orientation/fusion"),
        ("Overlay / DPI", "fullscreen, multi-DPI, multi-monitor, virtual desktop", "WinUI/WPF spike; click-through topmost; primary monitor MVP; compatibility matrix"),
        ("Power", "High accuracy GNSS + continuous rendering은 battery 사용", "moving/On에서만 high accuracy; stationary backoff; FPS·CPU budget"),
        ("Privacy boundary", "앱 local 처리와 Windows location service 자체 동작은 별개", "‘MotionCue가 전송하지 않음’으로 정확히 표현; OS privacy link 제공"),
    ]
    add_table(doc, ["Constraint", "제품 영향", "대응"], constraints, [1900, 3200, 4260], font_size=8.35)
    add_heading(doc, "Candidate motion pipeline (제품 수준)", 2)
    doc._decimal_num_id = add_numbering(doc, "decimal")
    for step in (
        "Windows Geolocator에서 연속 sample 수신; foreground permission과 StatusChanged 처리.",
        "Source gate: Satellite만 통과. Accuracy, timestamp freshness, Speed/Heading availability를 검사.",
        "Outlier rejection: 비현실적 jump, stale timestamp, 낮은 accuracy, 비연속 sample 제거.",
        "Estimation: ΔSpeed/Δt로 longitudinal trend, unwrap(ΔHeading)/Δt로 turn trend 계산.",
        "Smoothing/state machine: deadband, low-pass, hysteresis, fade rule 적용.",
        "Renderer: cue vector를 edge dots 변위로 제한하고 DPI/contrast에 맞춰 표시.",
    ): add_numbered(doc, step)
    add_label_para(doc, "가정/초기 튜닝값", "이동 진입 speed 3.0 m/s, 정지 판단 1.5 m/s, 진입 유지 5초, 정지 유지 15초, accuracy 30 m 이내를 초기 candidate로 두되 Phase 0 trace로 수정한다. 문서의 확정 requirement가 아니다.", GOLD)

    add_heading(doc, "14. Competitive Advantage / Differentiation", 1)
    diff_rows = [
        ("Windows focus", "명확한 차별점", "Windows overlay·tray·DPI·배포를 최적화", "Apple이 아닌 Windows gap에 의존; 직접 경쟁 조사 필요"),
        ("Laptop-only GNSS", "편의 차별점", "phone pairing 없음", "GNSS 보급률과 성능이 낮으면 장점이 사라짐"),
        ("Local / no account", "신뢰·privacy 차별점", "앱 서버·telemetry 없음", "쉽게 복제 가능; moat 아님"),
        ("Automatic minimal UX", "사용성 차별점", "tray 중심, 거의 보이지 않음", "기능 자체보다 실행 품질이 중요"),
        ("Future multi-source architecture", "확장성", "GNSS→phone IMU→fusion 교체 가능", "구현 전에는 차별점이 아닌 방향성"),
        ("Open/independent potential", "채택·신뢰 가능성", "auditability·community device support", "수익모델·support 부담과 trade-off"),
    ]
    add_table(doc, ["요소", "현재 가치", "사용자 이점", "Moat 판단"], diff_rows, [1900, 1750, 2800, 2910], font_size=8.35)
    add_callout(doc, "정직한 결론", "현재의 differentiation은 ‘Windows에서의 availability + 단순성 + privacy’이며, 기술적 방어력은 낮습니다. 진짜 경쟁력은 다양한 Windows hardware에서 낮은 latency와 낮은 distraction을 재현하는 tuning dataset·compatibility knowledge에서 생길 수 있습니다.")

    add_heading(doc, "15. Success Metrics", 1)
    add_label_para(doc, "제품 결정", "production telemetry는 수집하지 않는다. MVP metric은 개발자 계측, 참가자 동의 기반 study log, 사용자가 직접 export한 derived diagnostics, 설문으로만 수집한다. Raw route·좌표는 기본 수집하지 않는다.", BLUE)
    tech = [
        ("Satellite fix availability", "open-sky route time 중 valid sample 비율", "≥80% (초기 gate)"),
        ("Effective update rate", "valid Satellite sample median", "≥1.0 Hz; p95 gap ≤2.5 s"),
        ("Cue response latency", "reference maneuver→visible cue", "median ≤1.5 s; p95 ≤3.0 s"),
        ("Direction accuracy", "큰 가감속/회전 event 분류", "≥80% event match"),
        ("False activation", "stationary desk 8시간", "≤1회 / 8 h"),
        ("Rendering", "60 Hz display 기준", "평균 60 FPS, p1 ≥45 FPS"),
        ("Resource", "idle / active", "idle CPU <0.5%; active <3%; memory <150 MB"),
        ("Reliability", "field-test session", "crash-free ≥99%"),
    ]
    add_caption(doc, "Technical metrics — 초기 feasibility threshold이며 Phase 0 baseline 후 조정")
    add_table(doc, ["Metric", "측정", "초기 기준"], tech, [2600, 3700, 3060], font_size=8.6)
    product = [
        ("Automatic preference", "study 종료 시 기본 mode 선택", "≥70% Automatic 선택"),
        ("Install retention", "7일·30일 follow-up 설문", "7일 ≥60%; 30일은 탐색"),
        ("Activation frequency", "participant diary / local summary export", "주행 노출 대비 사용률"),
        ("Eligibility rate", "모집 대상 Windows laptop 중 Satellite GNSS 가능", "시장성 gate; ≥25%가 초기 기준"),
    ]
    add_caption(doc, "Product metrics — 무텔레메트리 환경의 study-derived 지표")
    add_table(doc, ["Metric", "수집 방식", "판단 기준"], product, [2600, 3900, 2860], font_size=8.7)
    outcome = [
        ("Perceived comfort", "7점 불편도, no-cue 대비", "평균 ≥1.0점 개선 또는 SRM ≥0.5"),
        ("Continue-use ability", "작업 지속 시간·중단 횟수", "중앙값 20% 개선"),
        ("Distraction", "7점 방해도", "median ≤3; 심각 악화 0명 목표"),
        ("Use again", "동일 상황 재사용 의향", "≥70% yes/probably yes"),
    ]
    add_caption(doc, "User outcome metrics — 임상 endpoint가 아닌 초기 제품 신호")
    add_table(doc, ["Metric", "측정", "초기 기준"], outcome, [2600, 3800, 2960], font_size=8.7)


def section_16_20(doc):
    add_heading(doc, "16. User Validation Plan", 1)
    stages = [
        ("Stage 1 — Developer testing", "2–3대 GNSS laptop, 10회 이상 bus/taxi route", "simulated trace→실차; GNSS raw/derived quality, cue latency, event annotation, overlay compatibility", "feasibility trace와 결함 목록"),
        ("Stage 2 — Small user test", "5–10명, 불편 경험·GNSS laptop 보유", "동일/유사 노선 crossover: 10분 no-cue vs 10분 cue, 순서 counterbalance, 동일 reading task", "comfort·distraction·작업 지속 신호"),
        ("Stage 3 — Expanded beta", "20–50명, 기기·노선 다양화", "2주 diary, opt-in derived log export, 7일/14일 설문, issue interview", "compatibility·retention·segment evidence"),
    ]
    add_table(doc, ["Stage", "Sample / 환경", "Protocol", "Output"], stages, [1900, 2300, 3250, 1910], font_size=8.35)
    add_heading(doc, "Stage 2 권장 protocol", 2)
    doc._decimal_num_id = add_numbering(doc, "decimal")
    for text in (
        "사전 screening: 운전자가 아닌 승객, 최근 screen-related discomfort 경험, motion sickness 심각도, 약물·컨디션 기록.",
        "baseline: 탑승 전 불편도(0–10), 피로, 수면, 식사, 좌석, 진행 방향과 laptop orientation 기록.",
        "조건 A/B: cue Off와 Automatic을 10분씩 수행하되 순서를 절반씩 바꾼다. 동일 난이도 문서 탐색 task 사용.",
        "1분 단위 quick rating: nausea/어지러움/눈 피로/방해도. 안전상 중단 기준(예: 7/10 이상 또는 참가자 요청) 적용.",
        "행동 관찰: 창밖 보기, 화면 내리기, task error, 앱 상태 확인, cue 인식 여부.",
        "사후 interview: 도움이 된/방해된 motion, 늦음·방향 오류, preferred intensity, Automatic 신뢰, 재사용 의향.",
    ): add_numbered(doc, text)
    add_heading(doc, "Suggested survey questions", 2)
    for text in (
        "이 구간에서 화면 사용으로 인한 불편은 어느 정도였습니까? (0 전혀 없음–10 매우 심함)",
        "MotionCue가 차량 움직임을 이해하는 데 어느 정도 도움이 되었습니까? (1–7)",
        "점 움직임이 본문 읽기나 작업을 얼마나 방해했습니까? (1–7)",
        "cue가 실제 움직임보다 늦거나 반대 방향이라고 느낀 순간이 있었습니까? 구체적으로 언제였습니까?",
        "같은 이동 상황에서 다시 사용할 의향이 있습니까? 왜 그렇습니까?",
        "GNSS가 없는 PC라면 phone 연결을 추가로 설정할 의향이 있습니까?",
    ): add_bullet(doc, text)

    add_heading(doc, "17. Risks", 1)
    risks = [
        ("GNSS accuracy 부족", "H", "H", "Satellite+accuracy gate, outlier rejection, no-cue fallback", "P0"),
        ("Update frequency 부족", "H", "H", "실차 trace; latency gate; GNSS-only 중단 기준", "P0"),
        ("GNSS laptop 희소", "H", "H", "30대+ hardware audit, onboarding check, phone IMU pivot", "P0"),
        ("False Automatic", "M", "M", "speed hysteresis, stationary soak test", "P0/P1"),
        ("Cue distraction/악화", "M", "H", "subtle defaults, intensity limit, stop rule, A/B study", "P1"),
        ("사용자 benefit 없음", "M", "H", "5–10명 crossover; segment별 결과", "P1"),
        ("Overlay compatibility", "M", "H", "fullscreen/DPI/GPU matrix, click-through test", "P1"),
        ("Battery consumption", "M", "M", "moving-only high accuracy, idle backoff, power profiling", "P1"),
        ("Apple 제품과 혼동", "M", "M", "독립 제품·상표 검토, 비교 문구 절제", "P2"),
        ("Privacy perception", "M", "H", "local-only explanation, raw history 미저장, no telemetry", "P1"),
        ("Laptop orientation mismatch", "H", "H", "forward-facing 안내, wrong-way test, future orientation source", "P0"),
        ("시장 수요 불확실", "H", "H", "problem interview, eligibility funnel, landing-page test", "P0"),
    ]
    add_table(doc, ["Risk", "확률", "영향", "Mitigation", "검증"], risks, [2350, 650, 650, 4610, 1100], font_size=8.15, aligns=["left","center","center","left","center"])
    add_para(doc, "등급 H/M/L은 현재 정보 기반의 상대 평가이며, Stage 1 이후 evidence로 갱신한다.", size=8.5, color=MUTED)

    add_heading(doc, "18. Roadmap", 1)
    roadmap = [
        ("Phase 0 — Technical feasibility", "GNSS probe, sample logger, hardware/source check, route traces", "≥3 device / ≥10 ride trace, rate·latency·availability gate 통과"),
        ("Phase 1 — Simulated motion + overlay", "deterministic simulator, edge dots, click-through, DPI/fullscreen", "4개 motion case 재현, overlay compatibility baseline"),
        ("Phase 2 — GNSS MVP", "source gate, estimator, Automatic/On/Off, tray, loss handling", "end-to-end field test 및 technical metric 달성"),
        ("Phase 3 — Usability polish", "onboarding, status copy, appearance, startup, accessibility", "5-user usability test의 critical issue 0개"),
        ("Phase 4 — Closed beta", "20–50명, local diagnostic export, feedback workflow", "outcome·retention·device coverage decision"),
        ("Phase 5 — Smartphone IMU", "Android/iPhone source protocol, pairing, time sync, security", "latency·setup friction이 GNSS 대비 의미 있게 개선"),
        ("Phase 6 — Fusion / distribution", "source selection, sensor fusion, Store/open-source 검토", "support cost·privacy·market evidence 기반 go"),
    ]
    add_table(doc, ["Milestone", "Deliverables", "Exit criteria"], roadmap, [2600, 3800, 2960], font_size=8.5)
    add_callout(doc, "순서 원칙", "Phase 0에서 GNSS feasibility를 통과하지 못하면 Phase 2를 억지로 완성하지 않고 Phase 5의 phone IMU spike로 이동합니다. Overlay와 simulator(Phase 1)는 sensor source와 독립적이므로 재사용됩니다.")

    add_heading(doc, "19. Future Opportunities", 1)
    futures = [
        ("Android companion sensor", "강함", "보급률·sensor 접근성; pairing·background 제한 검증", "GNSS 실패 시 우선"),
        ("iPhone companion sensor", "강함", "iOS background·network·App Store 제약", "Android와 protocol 공통화"),
        ("Bluetooth sensor input", "중간", "추가 hardware가 MVP 편의성을 훼손", "특수 사용자/연구용"),
        ("Wi‑Fi sensor streaming", "강함", "latency·보안·network 전환", "phone IMU transport 후보"),
        ("Automatic source selection", "강함", "신뢰 가능한 health score 필요", "2개 source 이후"),
        ("GNSS + phone IMU fusion", "강함", "time sync·drift·orientation calibration", "core 품질 강화"),
        ("Multi-monitor", "낮–중간", "차량 내 외부 monitor 사용 빈도 검증", "요청 기반"),
        ("Accessibility integrations", "중간", "고대비·reduced motion·screen reader settings", "core UX 강화"),
        ("Microsoft Store", "중간", "신뢰·update 장점; packaging·정책", "beta 이후"),
        ("Open-source release", "중간", "신뢰·device contribution; support·clone 위험", "사업모델과 함께 결정"),
    ]
    add_table(doc, ["Opportunity", "Core 강화", "검증/제약", "권고"], futures, [2300, 1150, 3650, 2260], font_size=8.35)

    add_heading(doc, "20. Go / No-Go Criteria", 1)
    criteria = [
        ("Continue GNSS MVP", "3대+ device와 10회+ 주행에서 valid Satellite availability ≥80%, median rate ≥1 Hz, cue latency median ≤1.5 s, event match ≥80%; user test에서 평균 comfort ≥1점 개선 또는 명확한 정성 신호"),
        ("Pivot within GNSS", "rate는 충분하지만 false activation·smoothing·visual mapping 문제가 큼: estimator/threshold/cue design을 1–2회 iteration 후 재시험"),
        ("Abandon GNSS-only", "median rate <0.8 Hz, p95 gap >3 s, availability <60%, direction/event match <70% 중 2개 이상이 representative route/device에서 반복되거나, GNSS eligibility가 모집 표본의 25% 미만"),
        ("Move to smartphone IMU", "GNSS-only abandon 조건 충족 + 10명 중 ≥60%가 phone pairing을 수용 + prototype end-to-end latency <200 ms 및 연결 성공률 ≥95%"),
        ("Stop / No-Go product", "5–10명 crossover에서 benefit 신호가 없고 방해·악화 사례가 반복되며, target interview에서도 설치 의향이 낮음. sensor source를 바꿔도 해결될 근거가 없음"),
    ]
    add_table(doc, ["Decision", "Measurable condition (초기 기준)"], criteria, [2400, 6960], font_size=8.75)
    add_label_para(doc, "검증 필요", "위 수치는 작은 팀의 초기 의사결정을 돕는 provisional threshold다. Phase 0 baseline 분포와 사용성 pilot 전에 상업적 약속이나 의료적 기준으로 사용하지 않는다.", RED)


def sources_and_top5(doc):
    add_heading(doc, "Sources & Evidence Notes", 1)
    sources = [
        ("S1", "Apple Support — Use iPhone more comfortably while riding in a vehicle", "https://support.apple.com/guide/iphone/iphone-comfortably-riding-a-vehicle-iph55564cb22/26/ios/26", "animated edge dots, Automatic, appearance options, passenger safety language"),
        ("S2", "Apple Support — Change Motion settings for accessibility on Mac", "https://support.apple.com/guide/mac-help/change-motion-settings-for-accessibility-mchla3c4f1da/mac", "Mac laptop availability, local real-time processing note, forward-facing/safety guidance"),
        ("S3", "Microsoft Learn — Get the user's location", "https://learn.microsoft.com/en-us/windows/apps/develop/maps-and-location/get-location", "WinUI 3 geolocation, permission flow, PositionChanged/StatusChanged"),
        ("S4", "Microsoft Learn — Guidelines for location-aware apps", "https://learn.microsoft.com/en-us/windows/uwp/maps-and-location/guidelines-and-checklist-for-detecting-location", "ReportInterval is not guaranteed, high accuracy/power, accuracy bands and graceful errors"),
        ("S5", "Microsoft Learn — Windows.Devices.Geolocation namespace", "https://learn.microsoft.com/en-us/uwp/api/windows.devices.geolocation?view=winrt-28000", "location sources, optional GNSS speed/heading, accuracy expectations"),
        ("S6", "McGill, Ng & Brewster (CHI 2017) — I Am The Passenger", "https://eprints.gla.ac.uk/133167/", "in-car visual motion cues and sensory conflict; no single best presentation across users"),
        ("S7", "Xie, He & Wu (2023) — Inducers of motion sickness in vehicles", "https://doi.org/10.1016/j.trf.2023.10.013", "systematic review of vehicle motion-sickness inducers and sensory-conflict framing"),
    ]
    for sid, title, url, note in sources:
        p = doc.add_paragraph(style="Small Note")
        set_font(p.add_run(f"[{sid}] "), size=8.5, bold=True, color=NAVY)
        add_hyperlink(p, title, url)
        set_font(p.add_run(f" — {note}."), size=8.5, color=MUTED)
    add_para(doc, "Evidence boundary: Apple support pages confirm the feature and its UX, not MotionCue's effectiveness. Research cited here supports the plausibility of sensory-conflict and visual-cue approaches but does not validate this GNSS-only Windows implementation. MotionCue-specific benefit remains 검증 필요.", size=8.8, color=MUTED)

    add_heading(doc, "현재 가장 중요한 검증 질문 Top 5", 1)
    top5 = [
        ("1", "실제 Windows 노트북의 내장 GNSS가 버스·택시에서 어느 정도의 availability, update rate, accuracy와 latency를 제공하는가?", "GNSS-only architecture의 생존 여부를 결정한다."),
        ("2", "속도·heading 기반 coarse cue가 사용자에게 올바른 가속·감속·좌/우 회전으로 인식되며, no-cue 대비 체감 불편을 낮추는가?", "기술 가능성과 사용자 가치가 만나는 핵심 결과다."),
        ("3", "대상 Windows 사용자 중 satellite GNSS가 있는 노트북의 비율은 충분한가? 없다면 phone IMU pairing을 감수할 의향이 있는가?", "시장 reach와 pivot 우선순위를 정한다."),
        ("4", "Automatic mode가 stationary noise·신호 손실·터널에서 잘못 켜지거나 잘못된 cue를 보여주지 않는가?", "신뢰가 무너지면 최소 UI의 장점이 사라진다."),
        ("5", "edge dots의 방향·강도·개수·fade가 작업을 방해하지 않으면서 개인차를 수용하는 최소 설정은 무엇인가?", "benefit과 distraction의 균형, 제품 기본값을 정한다."),
    ]
    add_table(doc, ["순위", "검증 질문", "왜 지금 중요한가"], top5, [650, 5710, 3000], font_size=8.75, aligns=["center","left","left"], header_fill=LIGHT_BLUE, add_after=False)
    # Word reserves a terminal paragraph mark after a final table. Keep it tiny so it
    # remains on the same page instead of creating an otherwise blank trailing page.
    terminal = doc.add_paragraph()
    terminal.paragraph_format.space_before = Pt(0)
    terminal.paragraph_format.space_after = Pt(0)
    terminal.paragraph_format.line_spacing = Pt(1)
    set_font(terminal.add_run(" "), size=1, color=WHITE)


def build():
    doc = setup_doc()
    summary_page(doc)
    section_1_5(doc)
    section_6_10(doc)
    section_11_15(doc)
    section_16_20(doc)
    sources_and_top5(doc)
    for p in doc.paragraphs:
        p.paragraph_format.widow_control = True
    doc.save(OUT)
    print("MotionCue PRD created")


if __name__ == "__main__":
    build()
