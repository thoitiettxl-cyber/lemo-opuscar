# Hybrid pipeline: lemo-opuscar code segments + native generated media

Status: demo-verified (films/lighthouse-demo/, 2026-10-23) and
stress-tested (films/hybrid-test-a|b|c/, 2026-10-23). Planning doc;
it does not replace DIRECTOR.md, TECHNIQUE.md, or styles/<style>/STYLE.md.

## Idea

Lemo-opuscar renders deterministically from code. Native image/video
generation does not: its output is fresh generation, never a frame-exact
animation of a storyboard. So the two never share one style pipeline.
They meet only at assembly: code-rendered segments first and last,
one generated motion segment in the middle.

## Stages

- Stage 0, Brief and style lock (agent + lemo-opuscar docs, no media).
  Input: topic + style name. Output: short brief + STYLE.md invariant list.
- Stage 1, Hero image (native image generation).
  Input: plain-language text prompt for one hero shot.
  Output: 1 image. It is the poster and the video seed.
- Stage 2, Motion clip (native video generation).
  Input: Stage 1 image + short motion text, or text alone.
  Output: 1 clip, about 10 seconds (duration is not controllable),
  with synthesized sound. No audio input is accepted.
  Text-only clips also work; test (b) used two text-only shots.
- Stage 3, Code cards (lemo-opuscar core/render/still.mjs).
  Input: STYLE.md + card text. Output: code-rendered title and closing
  frames at 1920x1080 (or the film target size). The Stage 1 image is
  a visual reference for art direction only; the renderer never
  ingests it as a frame.
  Card pages must expose window.READY and window.render(t), use no
  external resources, and live in the film's project folder, never in
  styles/.
- Stage 4, Normalize + assemble (ffmpeg, see scripts below).
  Input: code card stills + generated clip.
  Output: one short film. Cards get a silent audio track; the clip is
  normalized first, so concat does not fail on mismatched params.
  Optional passes: colour-match (before normalize) and voice mix
  (after assemble, video copy + audio re-encode).
- Stage 5, Check (ffprobe + extracted frames, not playback).
  Input: raw clip + final film. Output: measured duration, resolution,
  fps, and audio values, plus a fix list. The agent cannot watch video
  playback, so frame inspection is the check.

## Scripts (hybrid/)

All scripts are POSIX sh, fail fast (set -eu), and use a 300 s timeout
per ffmpeg call. Target params are a demo choice, not a tool limit:
1920x1080, 24 fps, H.264 yuv420p, AAC 48 kHz stereo. All segments
must share these params before concat.

- `sh hybrid/normalize.sh [--fit|--fill] [--size WxH] [--fps N] <clip-in> <clip-normalized>`
  Defaults: --fit, 1920x1080, 24 fps. --fit scales down to fit inside
  WxH and pads (bars, no crop). --fill scales up to cover WxH and
  centre-crops (no bars, crops). Forces fps, re-encodes video to
  H.264 yuv420p and audio to AAC 48 kHz stereo. Assumes the input has
  an audio stream; generated clips do (synthesized sound).
  The plain form `sh hybrid/normalize.sh <in> <out>` keeps the old
  behaviour (fit, 1920x1080, 24 fps).
- `sh hybrid/make_card.sh [--size WxH] [--fps N] <still.jpg> <segment-out> [seconds=2]`
  Loops one still into a video segment of the given duration with a
  silent stereo AAC track at 48 kHz, at the target params. Card
  stills are fitted (pad), never cropped.
- `sh hybrid/assemble.sh <final-out> <segment1> [segment2 ...]`
  Concats already-normalized segments with `ffmpeg -f concat -c copy`.
  Segment paths must not contain single quotes (concat list quoting).
- `sh hybrid/mix_voice.sh <film> <voice> <output> [film_volume=0.4] [voice_volume=1.0]`
  Mixes a voiceover over a film's existing audio. Voice starts at
  0 s, padded with silence to the film length (measured with
  ffprobe, not assumed). Video is copied; only audio is re-encoded
  to AAC 48 kHz stereo. normalize=0 is required: amix normalize
  (default on) divides by the input count and would halve both
  tracks, making the volume arguments lie.
- `sh hybrid/colormatch.sh <clip-in> <clip-out> <R> <G> <B>`
  Shifts a clip's mean colour toward a target palette mean (R, G, B).
  Measures the mid-frame mean (ffmpeg scale=1:1), applies
  per-channel gains (target/source, clamped to [0.5, 2.0]) via
  colorchannelmixer, then re-measures and prints SRC/TGT/GAIN/AFTER.
  Resolution and fps are unchanged; run normalize.sh after it
  before concat.

## Demo commands (lighthouse, from the repo root)

```sh
# 1-2. Generate hero image, then one clip from it (native tools, 1 + 1).
#    Outputs land in films/lighthouse-demo/ as lighthouse-hero.jpg
#    and lighthouse-clip.mp4 (exact clip name comes from the tool).

# 3. Render code cards (repo root is the static server root).
node core/render/still.mjs films/lighthouse-demo/title 0 \
  --size 1920x1080 --prefix title_ --out films/lighthouse-demo/cards
node core/render/still.mjs films/lighthouse-demo/closing 0 \
  --size 1920x1080 --prefix closing_ --out films/lighthouse-demo/cards

# 4. Normalize + card segments + assemble.
sh hybrid/normalize.sh films/lighthouse-demo/lighthouse-clip.mp4 \
  films/lighthouse-demo/clip-normalized.mp4
sh hybrid/make_card.sh films/lighthouse-demo/cards/title_0.jpg \
  films/lighthouse-demo/title.mp4 2
sh hybrid/make_card.sh films/lighthouse-demo/cards/closing_0.jpg \
  films/lighthouse-demo/closing.mp4 2
sh hybrid/assemble.sh films/lighthouse-demo/final.mp4 \
  films/lighthouse-demo/title.mp4 \
  films/lighthouse-demo/clip-normalized.mp4 \
  films/lighthouse-demo/closing.mp4

# 5. Report measured values, never assumptions.
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,avg_frame_rate,sample_rate,channels \
  -show_entries format=duration -of default=noprint_wrappers=1 \
  films/lighthouse-demo/lighthouse-clip.mp4
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,avg_frame_rate,sample_rate,channels \
  -show_entries format=duration -of default=noprint_wrappers=1 \
  films/lighthouse-demo/final.mp4
```

## Stress tests (2026-10-23, films/hybrid-test-a|b|c/)

- (a) Portrait Swiss, crop-fill. Raw clip 768x1152 (the model kept
  the seed's portrait aspect), normalized --fill --size 1080x1920,
  Swiss cards rendered at 1080x1920. Final: 1080x1920, 24 fps,
  AAC 48 kHz stereo, 14.082683 s. Clip frame fills the frame with
  no bars. Cards are flat (no gradients, no shadows) per STYLE.md.
- (b) Two clips + TTS voiceover. Shots are text-only generations,
  1280x720 each, 10 s each. Cards watercolor grammar (the test is
  multi-clip + voice, not style). Voice: lemo core/tts/tts.py
  (Kokoro, offline, voice af_bella, 2.245 s, 24 kHz mono).
  film_noVO 24.082683 s; final after voice mix 24.082683 s,
  1920x1080, 24 fps, AAC 48 kHz stereo. Voice presence verified
  by volumedetect, not by listening: final is +20 dB vs film_noVO
  in the voice window [0, 2.245 s].
  Found and fixed: amix normalize (default on) halved both tracks
  (post-voice window measured -14.0 dB vs film_noVO, expected
  -8.0 dB for 0.4). Fix: normalize=0 in mix_voice.sh; re-measured
  -7.9 dB, matching 0.4.
  Duration accounting (measured stream durations, (b) film_noVO):
  video 24.041667 s, audio 24.073333 s, format 24.082683 s.
  Segment audio sums to 24.052 s (each normalized clip audio
  10.026 s vs video 10.000 s). The format overrun vs the video
  sum is 0.082683 s in all three finals (1- and 2-clip alike);
  its pieces are the clip audio overruns, one extra video frame
  tick (0.041667 s), one trailing AAC frame (0.021333 s), and a
  ~0.009 s container remainder (medium confidence; packet-level
  inspection would be needed for exact accounting).
- (c) Blueprint colour match. Target palette mean (99, 126, 174)
  from the STYLE.md example trio (#18336B, #2A58A6, #E7F0F9).
  Raw clip 1152x768, 10 s. Mid-frame mean SRC (23, 63, 114);
  gains (2.000, 2.000, 1.526) with R and G clamped at 2.0;
  AFTER (40, 119, 168). RGB distance to target: 115.52 -> 59.72
  (-48.3%). R falls short of target because gains clamp and
  highlights clip (white lines cannot exceed 255). The clip
  segment is pillarboxed (fit default); --fill would remove bars.

## Limits (honest)

- Video clips are about 10 seconds each, duration not controllable;
  at most 6 successful clips per user message; at most 4 images per
  chat request. A longer film needs more clips or more code segments.
- Generated footage is watercolor-like at best, never watercolor in
  lemo-opuscar's code sense. Do not label it as a lemo-opuscar frame.
- Media generation is rollout-gated with no preflight check; a failed
  generation is reported, never replaced with fake media.
- Lemo-opuscar styles are tuned for Claude Opus 5.5 (README warning);
  reproduction by another model may differ.
- The demo cards are minimal CSS watercolor-grammar frames, not the
  watercolor demo engine. The demo engine's story is unrelated to the
  demo topic, and reusing it would bend the topic toward the demo.
- Default output resolution and format of native generation are not
  stated in the docs read for this pipeline; that is why Stage 4
  normalizes instead of assuming.
- Colour-match is a per-channel gain, not a full grade: it moves the
  frame mean toward the palette mean but cannot reach a dark target
  when gains clamp or highlights clip.
- Clip motion is spot-checked (extracted frames), never watched;
  voice is level-checked (volumedetect), never listened to.

## Repo rules observed

- Film work lives in films/<name>/, which is gitignored; hybrid/
  was committed on branch feat/hybrid-media-workflow and PR #1 was
  opened by Boss (2026-10-23). Further hybrid/ fixes go on that
  branch as a patch until Boss pushes; never push without approval.
- Never build inside styles/. Never copy a demo's story, arc, shots,
  props, or timeline; write the film's own treatment first.
