#!/bin/sh
# make_card.sh — turn one still image into a silent video segment
# matching a concat target.
# Usage: sh make_card.sh [--size WxH] [--fps N] <image> <output> [duration_seconds, default 2]
# Defaults: 1920x1080, 24 fps. Video: looped still, H.264 yuv420p.
# Audio: silent stereo AAC at 48 kHz, so concat with clips works.
# Card stills are fitted (pad) to the target size, never cropped.
# The plain form `sh make_card.sh <image> <output> [duration]` keeps
# the old behaviour (1920x1080, 24 fps).
set -eu
SIZE=1920x1080; FPS=24
while [ "$#" -gt 0 ]; do
  case "$1" in
    --size) SIZE="$2"; shift 2 ;;
    --fps) FPS="$2"; shift 2 ;;
    --) shift; break ;;
    -*) echo "usage: sh make_card.sh [--size WxH] [--fps N] <image> <output> [duration]" >&2; exit 2 ;;
    *) break ;;
  esac
done
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then echo "usage: sh make_card.sh [--size WxH] [--fps N] <image> <output> [duration]" >&2; exit 2; fi
IMG="$1"; OUT="$2"; DUR="${3:-2}"
W="${SIZE%x*}"; H="${SIZE#*x}"
timeout 300 ffmpeg -y -v error -loop 1 -i "$IMG" -f lavfi -i "anullsrc=r=48000:cl=stereo" \
  -vf "scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}" \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p -r "$FPS" -video_track_timescale "$FPS" \
  -c:a aac -b:a 128k -ar 48000 -ac 2 -t "$DUR" -shortest "$OUT"
