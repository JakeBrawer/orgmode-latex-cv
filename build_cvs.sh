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
sed -i 's/\\hfill/\\quad/g' "${ATS_BASE}.tex"
sed -i -E 's/\\quad ([A-Za-z]+ 20[0-9]{2}--[A-Za-z]+|[0-9]{4}--[0-9]{4}|[A-Za-z]+ 20[0-9]{2})/, \1/g' "${ATS_BASE}.tex"
sed -i -E 's/,} ,/,}/g; s/\} ,/\},/g; s/ ,/,/g; s/, ,/,/g' "${ATS_BASE}.tex"

build_pdf "$HUMAN_BASE"
build_pdf "$ATS_BASE"

mkdir -p "$(dirname "$WEBSITE_CV_PATH")"
cp "${HUMAN_BASE}.pdf" "$WEBSITE_CV_PATH"

echo "Built ${HUMAN_BASE}.pdf"
echo "Built ${ATS_BASE}.pdf"
echo "Copied ${HUMAN_BASE}.pdf to ${WEBSITE_CV_PATH}"
