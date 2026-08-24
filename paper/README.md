# MotionCue Paper Workspace

This directory contains the English undergraduate-thesis manuscript for MotionCue.

## Format decision

The working manuscript uses the official ICCV 2025 two-column LaTeX style as a visual and bibliographic baseline. It is not currently an ICCV submission.

- Official author guidelines: https://iccv.thecvf.com/Conferences/2025/AuthorGuidelines
- Official author kit downloaded from: https://media.eventhosts.cc/Conferences/ICCV2025/ICCV2025-Author-Kit-Feb.zip
- Vendored, unmodified style assets: `vendor/iccv2025/`
- MotionCue-authored manuscript: `main.tex`, `sections/`, and `references.bib`

The conference's eight-page limit, anonymous-review identity removal, paper ID, and rebuttal rules do not apply to this undergraduate thesis. Page numbers remain enabled for draft review. If Yeungnam University requires a title or approval page for final deposit, that front matter can be added without changing the two-column body.

## Build

From this directory, with a current TeX distribution installed:

```powershell
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
```

The generated PDF and auxiliary LaTeX files are build artifacts and should not be treated as source.

## Accuracy rule

The draft must not imply that Study A or Study B has been completed until actual validated data exist. Unresolved values use `TBD` or visible draft notes. Device model, OS build, application version, protocol version, GATT PDU, route code, exclusions, and analysis versions must be frozen in the Methods section before final analysis.
