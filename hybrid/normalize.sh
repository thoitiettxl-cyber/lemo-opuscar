#!/bin/sh
# normalize.sh — normalize one video to a concat target.
# Usage: sh normalize.sh [--fit|--fill] [--size WxH] [--fps N] <input> <output>
# Defaults: --fit, 1920x1080, 24 fps. Audio: AAC 48 kHz stereo.
# --fit: scale down to fit inside WxH, pad to WxH (bars, no crop).
# --fill: scale up to cover WxH, centre-crop to WxH (no bars, crops).
# Target params are a demo choice, not a tool limit. The plain form
# `sh normalize.sh <input> <output>` keeps the old behaviour (fit,
# 1920x1080, 24 fps). Assumes the input has an audio stream
# (generated clips do: synthesized sound). Exits non-zero on failure.
set -eu
MODE=fit; SIZE=1920x1080; FPS=24
while [ "$#" -gt 0 ]; do
  case "$1" in
    --fit) MODE=fit; shift ;;
    --fill) MODE=fill; shift ;;
    --size) SIZE="$2"; shift 2 ;;
    --fps) FPS="$2"; shift 2 ;;
    --) shift; break ;;
    -*) echo "usage: sh normalize.sh [--fit|--fill] [--size WxH] [--fps N] <input> <output>" >&2; exit 2 ;;
    *) break ;;
  esac
done
if [ "$#" -ne 2 ]; then echo "usage: sh normalize.sh [--fit|--fill] [--size WxH] [--fps N] <input> <output>" >&2; exit 2; fi
IN="$1"; OUT="$2"
W="${SIZE%x*}"; H="${SIZE#*x}"
if [ "$MODE" = fill ]; then
  VF="scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H},fps=${FPS}"
else
  VF="scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}"
fi
timeout 300 ffmpeg -y -v error -i "$IN" \
  -vf "$VF" \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p -r "$FPS" -video_track_timescale "$FPS" \
  -c:a aac -b:a 128k -ar 48000 -ac 2 \
  -movflags +faststart "$OUT"
