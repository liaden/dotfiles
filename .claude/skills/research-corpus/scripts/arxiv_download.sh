#!/usr/bin/env bash
# Download arXiv LaTeX source tarballs into the *current repo* and convert them.
#
# Part of the `research-corpus` skill. Run from the target repo root; output
# lands in ./references/papers/{src,rst,typst} relative to the current dir.
#
# Usage:
#   arxiv_download.sh 2110.02345 2309.03364           # download + convert to RST
#   arxiv_download.sh --format typst 2110.02345       # convert to Typst instead
#
# The script:
#   1. Downloads <ID>.tar.gz to ./references/papers/src/ (skips if present)
#   2. Runs latex_to_rst.py from the skill dir (skips if output already exists)
#
# Rate-limiting: 3-second sleep between arxiv requests.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(pwd)/references/papers/src"

FMT="rst"
IDS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --format) FMT="$2"; shift 2 ;;
    --format=*) FMT="${1#*=}"; shift ;;
    -h|--help)
      echo "Usage: arxiv_download.sh [--format rst|typst] <arxiv-id> [<arxiv-id> ...]"; exit 0 ;;
    *) IDS+=("$1"); shift ;;
  esac
done

if [[ ${#IDS[@]} -eq 0 ]]; then
  echo "Usage: arxiv_download.sh [--format rst|typst] <arxiv-id> [<arxiv-id> ...]"
  exit 1
fi

mkdir -p "$SRC_DIR"

for id in "${IDS[@]}"; do
  tarball="$SRC_DIR/${id}.tar.gz"
  if [[ -f "$tarball" ]]; then
    echo "[src] $id — already downloaded"
  else
    echo "[src] downloading $id ..."
    curl -fsSL --retry 3 --retry-delay 5 \
      -H "User-Agent: research-corpus-downloader/1.0 (academic research aggregation)" \
      "https://arxiv.org/src/${id}" -o "$tarball"
    echo "      $(du -sh "$tarball" | cut -f1)"
    [[ ${#IDS[@]} -gt 1 ]] && sleep 3
  fi
done

echo ""
echo "Converting to ${FMT}..."
"$SCRIPT_DIR/latex_to_rst.py" --format "$FMT" "${IDS[@]}"
