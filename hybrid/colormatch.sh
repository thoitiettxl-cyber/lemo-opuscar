#!/bin/sh
# colormatch.sh — shift a clip's mean colour toward a target palette mean.
# Usage: sh colormatch.sh <input> <output> <R> <G> <B>
# Method (measured, not assumed):
#   1. Take the frame at half the clip duration (accurate seek) and
#      average it to 1x1 to get the source mean RGB (ffmpeg scale=1:1).
#   2. Per-channel gain = target/source, clamped to [0.5, 2.0].
#   3. Apply colorchannelmixer with those gains (video re-encode,
#      audio copied). Resolution and fps are unchanged; run
#      normalize.sh after it before concat.
#   4. Re-measure the output mid frame and print the values.
# Prints: SRC=, TGT=, GAIN=, AFTER=, MID=, DUR=. Exits non-zero if the
# source mean cannot be measured.
set -eu
if [ "$#" -ne 5 ]; then echo "usage: sh colormatch.sh <input> <output> <R> <G> <B>" >&2; exit 2; fi
IN="$1"; OUT="$2"; TR="$3"; TG="$4"; TB="$5"
mean_rgb() {
  # $1 = file, $2 = timestamp seconds -> prints "R G B"
  _F="$1"; _T="$2"
  ffmpeg -v error -i "$_F" -ss "$_T" -frames:v 1 -vf scale=1:1 -f rawvideo -pix_fmt rgb24 - 2>/dev/null | od -An -tu1 | tr -s ' ' | sed 's/^ //'
}
DUR="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")"
MID="$(awk -v d="$DUR" 'BEGIN{printf "%.3f", d/2}')"
SRC="$(mean_rgb "$IN" "$MID")"
set -- $SRC
if [ "$#" -ne 3 ]; then echo "colormatch: could not measure source mean RGB" >&2; exit 1; fi
SR="$1"; SG="$2"; SB="$3"
GAINS="$(awk -v sr="$SR" -v sg="$SG" -v sb="$SB" -v tr="$TR" -v tg="$TG" -v tb="$TB" 'BEGIN{
  gr=(sr>0)?tr/sr:2.0; gg=(sg>0)?tg/sg:2.0; gb=(sb>0)?tb/sb:2.0;
  if (gr<0.5) gr=0.5; if (gr>2.0) gr=2.0;
  if (gg<0.5) gg=0.5; if (gg>2.0) gg=2.0;
  if (gb<0.5) gb=0.5; if (gb>2.0) gb=2.0;
  printf "%.3f %.3f %.3f", gr, gg, gb}')"
set -- $GAINS; GR="$1"; GG="$2"; GB="$3"
timeout 300 ffmpeg -y -v error -i "$IN" -vf "colorchannelmixer=rr=${GR}:gg=${GG}:bb=${GB}" -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a copy "$OUT"
AFTER="$(mean_rgb "$OUT" "$MID")"
echo "SRC=$SR $SG $SB"
echo "TGT=$TR $TG $TB"
echo "GAIN=$GR $GG $GB"
echo "AFTER=$AFTER"
echo "MID=$MID DUR=$DUR"
