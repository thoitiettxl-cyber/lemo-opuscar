---
name: lemo-opuscar
description: Direct and produce a short film made entirely in code, in one of the styles of the Lemo-Opuscar library (e.g. Impasto Oil Painting 油画厚涂, Watercolor Brush 水彩笔刷, Ukiyo-e 浮世绘, Satellite Briefing 卫星简报, Exploded Teardown 产品拆解). Use when the user asks for a video, film, short, promo, explainer or animation (视频、短片、动画、宣传片) in a named style, including explainers built from real material such as satellite imagery, laser scans, CAD files or archive scans (数据解说、科普、产品拆解), and new films cut from real archive footage and documents (剪辑与纪实, e.g. 用档案影像剪一支新闻片); when they want a film about their own topic and haven't chosen a style (help them choose); when they want to change a style into their own, make their own style from a blank page, or use a style they saved (改风格、从空白开始、我的风格); when they start the skill without saying what they want; or when they ask which film styles there are. Not for plain editing, trimming or converting the user's existing video files.
---

# Lemo-Opuscar

The styles, guides and tools live in the Lemo-Opuscar library (github.com/lemomo-ai/lemo-opuscar). This skill fetches it and hands you over to it.

1. **Get the library.** Run `sh "<skill base directory>/scripts/setup.sh"`. It clones or updates the library and prints `LIB=<path>` on its last line. Library location, in order: `$LEMO_OPUSCAR_HOME` if set; else `~/workspace/lemo-opuscar` if it is a library (this VM's workspace clone — preferred, so a second copy is never cloned to `~/lemo-opuscar`); else the clone the user is standing in; else `~/lemo-opuscar` (cloned on first use). On this VM, `LEMO_OPUSCAR_HOME` is also exported by `~/.config/heal/tool-env.sh` to `~/workspace/lemo-opuscar`, so tool shells and `BASH_ENV=tool-env.sh bash -c` agree on the same library.
2. **Install the core tools early.** Start `sh "<skill base directory>/scripts/setup.sh" deps` right away, in the background if you can: it takes a few minutes the first time. Add `deps voice` or `deps music` later, only if the film needs them (`$LIB/TECHNIQUE.md` §1). Report missing system tools (Node, ffmpeg, Python) in your one round of questions; don't install system software yourself. Packages a style needs (its `STYLE.md` lists them) you install yourself, into the project folder.
3. **Follow the library.** Read `$LIB/AGENTS.md` and do what it says, starting with **Start** (the user's own styles in `~/lemo-my-styles/`; when they started the skill without writing anything, the language question first, then the ways in): finding the style or making their own, the one round of questions, the treatment, production and delivery.

What changes in skill mode:

| | |
|---|---|
| Project folder | `<name>/` in the folder the user started from (lowercase letters, digits, hyphens; avoid `#` and `?` in the path). Wherever the guides say `films/<name>/`, read this folder |
| Running tools | from `$LIB`, with the project's absolute path: `cd "$LIB" && node core/render/still.mjs "<project>" 1.5 3` |
| Library files in pages | absolute URLs: `/core/lib.js`, `/node_modules/three/…` (the project is served at `/@film/`) |
| Library files in scripts and `build.sh` | `$LIB/…`, with `LIB=<path>` at the top of `build.sh`; never `../..` |
| Demo source | not downloaded. `sh "<skill base directory>/scripts/setup.sh" demo <slug>`, only after your `TREATMENT.md` is written, to read its techniques; it is not meant to be rendered. An Edit & Documentary style is the exception: fetch it before the treatment to use the material tools its `STYLE.md` names in `demo/tools/` (`$LIB/AGENTS.md`, "Treatment first") |

## Hybrid workflow (code segments + native generated media)

When a film mixes lemo-opuscar code segments with native image/video
generation, do not share one style pipeline between them: code-rendered
segments go first and last, one generated motion segment goes in the
middle, and they meet only at assembly. The workspace clone's
`hybrid/` directory documents this (`hybrid/HYBRID.md`, plus
`normalize.sh`, `make_card.sh`, `assemble.sh`, `mix_voice.sh`,
`colormatch.sh` — all POSIX sh, ffmpeg, target 1920x1080, 24 fps,
H.264 yuv420p, AAC 48 kHz stereo; see HYBRID.md for the exact commands
and the demo/stress-test evidence). `hybrid/` is a local extension in
the workspace clone (hybrid branch, PR #1), not part of the upstream
plugin edition: if `$LIB/hybrid/` does not exist in the library you
resolved, say so and do not invent its scripts — use the workspace
clone at `~/workspace/lemo-opuscar` instead. Code cards are rendered
with `core/render/still.mjs`, generated clips are normalized before
concat (so mismatched params cannot fail the concat), and the final
film is checked with ffprobe + extracted frames, never by assumed
playback. Native media limits still apply (image generation at most
4 images per request; video clips about 10 s, duration not
controllable, at most 6 per user message).

Deliver what `$LIB/DIRECTOR.md` §11 lists, in the project folder, and tell the user where it is.
