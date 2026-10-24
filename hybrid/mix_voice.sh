#!/bin/sh
# mix_voice.sh — mix a voiceover over a film's existing audio.
# Usage: sh mix_voice.sh <film> <voice> <output> [film_volume=0.4] [voice_volume=1.0]
# Voice starts at 0 s and is padded with silence to the film length
# (film duration measured with ffprobe, not assumed).
# Video is copied; only audio is re-encoded (AAC 48 kHz stereo).
# Both inputs are converted to 48 kHz stereo inside the filter graph
# so amix sees matching rates and layouts. normalize=0 is required:
# amix normalize (default on) divides by the input count, which would
# halve both tracks and make the volume arguments lie.
set -eu
if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then echo "usage: sh mix_voice.sh <film> <voice> <output> [film_volume] [voice_volume]" >&2; exit 2; fi
FILM="$1"; VOICE="$2"; OUT="$3"; FV="${4:-0.4}"; VV="${5:-1.0}"
DUR="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$FILM")"
timeout 300 ffmpeg -y -v error -i "$FILM" -i "$VOICE" -filter_complex \
  "[0:a]volume=${FV},aformat=sample_rates=48000:channel_layouts=stereo[a0];[1:a]volume=${VV},aformat=sample_rates=48000:channel_layouts=stereo,apad,atrim=0:${DUR}[a1];[a0][a1]amix=inputs=2:duration=first:dropout_transition=0:normalize=0[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 128k -ar 48000 -ac 2 "$OUT"
