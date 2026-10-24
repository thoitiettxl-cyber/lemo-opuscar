#!/bin/sh
# assemble.sh — concat already-normalized segments with -c copy.
# Usage: sh assemble.sh <output> <segment1> [segment2 ...]
# All segments must share codec, resolution, fps, and audio params
# (see normalize.sh / make_card.sh). Segment paths must not contain
# single quotes (concat list quoting). Exits non-zero on failure.
set -eu
if [ "$#" -lt 2 ]; then echo "usage: sh assemble.sh <output> <segment1> [segment2 ...]" >&2; exit 2; fi
OUT="$1"; shift
LIST="$(mktemp)"
trap 'rm -f "$LIST"' EXIT INT TERM
for f in "$@"; do
  case "$f" in
    /*) printf "file '%s'\n" "$f" >> "$LIST" ;;
    *) printf "file '%s'\n" "$PWD/$f" >> "$LIST" ;;
  esac
done
timeout 300 ffmpeg -y -v error -f concat -safe 0 -i "$LIST" -c copy "$OUT"
