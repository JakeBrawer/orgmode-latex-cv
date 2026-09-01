#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

SOURCE_ORG="brawer_cv.org"
SOURCE_TEX="brawer_cv.tex"
HUMAN_BASE="Jake_Brawer_CV_human"
ATS_BASE="Jake_Brawer_CV_ATS"
WEBSITE_CV_PATH="${WEBSITE_CV_PATH:-/home/jake/src/jakebrawer.github.io/assets/pdfs/brawer_cv.pdf}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command '$1' not found" >&2
    exit 1
  fi
}

build_pdf() {
  local base="$1"

  rm -f "${base}.aux" "${base}.bcf" "${base}.bbl" "${base}.blg" \
        "${base}.log" "${base}.out" "${base}.run.xml"

  pdflatex -interaction=nonstopmode -halt-on-error "${base}.tex"
  biber "$base"
  pdflatex -interaction=nonstopmode -halt-on-error "${base}.tex"
  pdflatex -interaction=nonstopmode -halt-on-error "${base}.tex"
}

require_cmd emacs
require_cmd pdflatex
require_cmd biber

emacs --batch "$SOURCE_ORG" \
  --eval '(progn (require (quote ox-latex)) (org-latex-export-to-latex))'

cp "$SOURCE_TEX" "${HUMAN_BASE}.tex"
cp "$SOURCE_TEX" "${ATS_BASE}.tex"
sed -i 's/\\usepackage{fa_orgmode_cv}/\\usepackage{fa_orgmode_cv_ats}/' "${ATS_BASE}.tex"
# Parsers extract entries best as separate lines: title, then
# employer/school, then dates. \hfill (which right-aligns the date onto
# the employer line) becomes a line break so dates stand alone.
sed -i 's/\\hfill/\\\\/g' "${ATS_BASE}.tex"
sed -i -E 's/,\} \\\\/\} \\\\/g' "${ATS_BASE}.tex"
# Full institution names and a standard job title for entity matching.
sed -i 's/\\subsection{Yale}/\\subsection{Yale University}/' "${ATS_BASE}.tex"
sed -i 's/\\subsection{Vassar}/\\subsection{Vassar College}/' "${ATS_BASE}.tex"
sed -i 's/{Postdoc}/{Postdoctoral Researcher}/' "${ATS_BASE}.tex"
# Date ranges spelled the way parsers expect: "X - Y" and "Present".
sed -i -E 's/([0-9]{4}) ?-- ?Current/\1 - Present/' "${ATS_BASE}.tex"
sed -i -E 's/([0-9]{4}) ?-- ?([A-Za-z0-9])/\1 - \2/g' "${ATS_BASE}.tex"

# ATS-only rewrites so the extracted text is what parsers expect:
# 1. Contact links become literal text (ATS parsers don't read link
#    annotations, so "email"/"linkedin" alone hides the actual address),
#    and the cell number is appended after the email.
sed -i -E 's/\\href\{mailto:([^}]+)\}\{[^}]+\}/\1 \/ 917-608-3204/g' "${ATS_BASE}.tex"
sed -i -E 's/\\href\{(https?:\/\/[^}]+)\}\{[^}]+\}/\\url{\1}/g' "${ATS_BASE}.tex"
# 2. Name without ", Ph.D." suffix so name parsing stays clean.
sed -i 's/{Jake Brawer, Ph\.D\./{Jake Brawer/g' "${ATS_BASE}.tex"
# 3. The \LaTeX logo extracts as garbled shifted glyphs; use plain text.
sed -i 's/\\LaTeX/LaTeX/g' "${ATS_BASE}.tex"
# 4. ASCII punctuation: en/em dashes break date parsing and keyword
#    matching (e.g. "human-robot"); smart quotes become straight quotes.
sed -i "s/--/-/g; s/–/-/g; s/—/-/g; s/\`\`/\"/g; s/''/\"/g" "${ATS_BASE}.tex"

build_pdf "$HUMAN_BASE"
build_pdf "$ATS_BASE"

mkdir -p "$(dirname "$WEBSITE_CV_PATH")"
cp "${HUMAN_BASE}.pdf" "$WEBSITE_CV_PATH"

echo "Built ${HUMAN_BASE}.pdf"
echo "Built ${ATS_BASE}.pdf"
echo "Copied ${HUMAN_BASE}.pdf to ${WEBSITE_CV_PATH}"
