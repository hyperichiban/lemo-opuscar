#!/bin/sh
# Our fork: offline-first setup for the Lemo-Opuscar library.
#   sh scripts/setup-local.sh [--check-only] [offline] [online] [deps [voice] [music]]
# Delegates package installs to plugin/skills/lemo-opuscar/scripts/setup.sh,
# then (offline, the default) warms the caches an offline film needs:
# Kokoro voice model + one default instrument library.
# Never installs system software: missing Node/ffmpeg/Python is reported, not fixed.
# Prints LIB=<path> on its last line, same contract as setup.sh.
set -e
cd "$(dirname "$0")/.."
LIB=$(pwd -P)
# Windows consoles default to cp1252: upstream asset scripts print Unicode
# (e.g. fetch.sh progress arrows). Force UTF-8 for every child Python.
export PYTHONIOENCODING=utf-8 PYTHONUTF8=1

MODE=offline
CHECK_ONLY=""
TIERS="voice music"
for a in "$@"; do
  case $a in
    --check-only) CHECK_ONLY=1 ;;
    offline|online) MODE=$a ;;
    deps|voice|music) TIERS="$TIERS $a" ;;
    *) echo "usage: sh scripts/setup-local.sh [--check-only] [offline] [online] [deps [voice] [music]]"; exit 1 ;;
  esac
done
# DEFAULT_LIB: override with INSTRUMENT_LIB=<lib> (freepats karoryfer salamander vcsl vsco2ce)
DEFAULT_LIB=${INSTRUMENT_LIB:-freepats}

# Windows: uv builds .venv/Scripts, upstream expects .venv/bin. Mirror the
# interpreter (a real copy: CPython finds pyvenv.cfg up-tree) so setup.sh
# and fetch.sh run unmodified. Re-checked every run: setup.sh recreates a
# broken .venv from scratch, which would drop the mirror.
win_mirror() {
  case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ;; *) return 0 ;; esac
  if [ ! -x .venv/Scripts/python.exe ]; then
    if command -v uv >/dev/null; then uv venv --quiet --python 3.12 .venv
    else echo "✗ uv is needed on Windows for the first venv (or create .venv with Scripts/python.exe yourself)"; exit 1; fi
  fi
  if [ ! -x .venv/bin/python.exe ]; then
    mkdir -p .venv/bin && cp .venv/Scripts/python.exe .venv/bin/python.exe
  fi
}

# 1. System tools: report only.
miss=""
if command -v node >/dev/null; then
  ver=$(node -v); major=$(node -p 'process.versions.node.split(".")[0]')
  echo "node $ver"
  [ "$major" -ge 20 ] || miss="$miss node20+(found $ver)"
else miss="$miss node20+"; fi
if command -v ffmpeg >/dev/null; then echo "ffmpeg $(ffmpeg -version 2>/dev/null | head -1)"; else miss="$miss ffmpeg"; fi
if command -v uv >/dev/null; then echo "uv $(uv --version 2>/dev/null)";
elif command -v python3 >/dev/null; then echo "python3 $(python3 -V 2>&1)"; else miss="$miss python3.11+(or uv)"; fi
if [ -n "$miss" ]; then echo "✗ missing:$miss (install these yourself; this script never installs system software)"; exit 1; fi
[ -n "$CHECK_ONLY" ] && { echo "LIB=$LIB"; exit 0; }

SETUP="plugin/skills/lemo-opuscar/scripts/setup.sh"
win_mirror
if [ "$MODE" = online ]; then
  echo "mode: online (edge-tts + fresh libraries need a connection)"
  sh "$SETUP" deps $TIERS
  echo "LIB=$LIB"
  exit 0
fi

# 2. Offline (default): packages first, then the offline caches.
echo "mode: offline"
sh "$SETUP" deps $TIERS
[ -f core/tts/kokoro-v1.0.onnx ] && [ -f core/tts/voices-v1.0.bin ] \
  || { echo "warming voice cache…"; sh tools/fetch.sh voice; }
if [ -d core/audio/instruments ] && [ -n "$(ls -A core/audio/instruments 2>/dev/null)" ]; then
  echo "instruments cache present"
else
  echo "warming instruments cache ($DEFAULT_LIB)…"
  sh tools/fetch.sh instruments "$DEFAULT_LIB"
fi
echo "offline ready: Kokoro + '$DEFAULT_LIB' cached"
echo "LIB=$LIB"
