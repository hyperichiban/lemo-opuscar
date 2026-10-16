# LOCAL.md — Offline / Online Mode Switch

Additive file for our fork. Upstream `DIRECTOR.md`, `TECHNIQUE.md` and
every `styles/*/STYLE.md` stay untouched. Read this alongside them.

## Modes

| | Online (default upstream) | Offline (local) |
|---|---|---|
| Voice ZH | `core/tts/tts_zh.py` (edge-tts, needs connection) | `core/tts/tts.py` (Kokoro, offline) |
| Voice check | `core/tts/asr_check.py` (faster-whisper) | same, local |
| Music samples | `tools/fetch.sh instruments <lib>` fresh | pre-cached libs only; else `core/audio/pluck.py` synth |
| Missing asset | fetch it | fail with the asset name + the exact warmup command, no silent downgrade |

Pick the mode in the one round of questions (`AGENTS.md`, Workflow).
Chinese voice: say up front that offline Kokoro sounds plain and online
edge-tts needs a connection (`DIRECTOR.md` §1).

## Cost rules (every film)

1. Storyboard gate default: 6–9 key shots via `core/render/sheet.py`,
   wait for approval — even if the user didn't ask.
2. One style context only: `DIRECTOR.md` + `TECHNIQUE.md` + one
   `styles/<slug>/STYLE.md`. Never bulk-load the library (~159k tokens).
3. Drafts at 1280x720 with the existing `--size WxH` render flag; exactly
   one 1920x1080 final pass.
4. Reuse `core/` + cached fonts/samples; text steps (treatment, cue map,
   `.srt` via `core/render/srt.py`, `readcheck.mjs`) go to free/local
   models first.

## Offline setup

```sh
sh scripts/setup-local.sh        # checks tools, warms voice+music caches
sh scripts/setup-local.sh deps voice
sh scripts/setup-local.sh deps music
```

Deliverables are unchanged (`DIRECTOR.md` §11): `<name>.mp4`, `poster.jpg`,
`<name>.srt`, `TREATMENT.md`, `CREDITS`, source + one-command `build.sh`.
