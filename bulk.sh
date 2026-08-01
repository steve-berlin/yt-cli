#!/usr/bin/env bash
# Bulk downloader: reads a .txt file of links, downloads them all in parallel.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bulk.sh LINKS.txt [flags]

  -a, --audio FMT     audio only, converted to FMT (default: flac)
  -f, --format SPEC   yt-dlp -f selector for video (default: best)
  -P, --path DIR      output directory (default: .)
  -j, --jobs N        parallel downloads (default: 4)
      --playlist      expand playlist links (default: single video only)
      --archive FILE  skip-already-downloaded archive (default: .yt-cli-archive.txt)
      --no-archive    do not skip anything
  -U, --update        update yt-dlp once before downloading
  -h, --help          this text

The .txt file holds one link per line; blank lines and #comments are ignored.
EOF
}

file=""
audio=""
format=""
path="."
jobs=4
playlist="--no-playlist"
archive=".yt-cli-archive.txt"
update=0

while [ $# -gt 0 ]; do
  case "$1" in
  -a | --audio)
    audio="${2:-flac}"
    shift 2
    ;;
  -f | --format)
    format="$2"
    shift 2
    ;;
  -P | --path)
    path="$2"
    shift 2
    ;;
  -j | --jobs)
    jobs="$2"
    shift 2
    ;;
  --playlist)
    playlist="--yes-playlist"
    shift
    ;;
  --archive)
    archive="$2"
    shift 2
    ;;
  --no-archive)
    archive=""
    shift
    ;;
  -U | --update)
    update=1
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "Unknown flag: $1" >&2
    usage >&2
    exit 2
    ;;
  *)
    file="$1"
    shift
    ;;
  esac
done

[ -n "$file" ] || {
  usage >&2
  exit 2
}
[ -r "$file" ] || {
  echo "Cannot read file: $file" >&2
  exit 2
}
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || {
  echo "--jobs must be a positive integer, got: $jobs" >&2
  exit 2
}
command -v yt-dlp >/dev/null || {
  echo "yt-dlp is not installed" >&2
  exit 127
}

# Update once here, never inside a job: N parallel self-updates corrupt the binary.
[ "$update" -eq 1 ] && yt-dlp -U --update-to nightly

args=(--no-abort-on-error --continue --no-update "$playlist" -P "$path")
[ -n "$archive" ] && args+=(--download-archive "$archive")

if [ -n "$audio" ]; then
  args+=(-f bestaudio -x --audio-format "$audio")
elif [ -n "$format" ]; then
  args+=(-f "$format")
fi

mkdir -p -- "$path"

# One yt-dlp per link, $jobs at a time. Comments and blank lines dropped first.
grep -vE '^[[:space:]]*(#|$)' -- "$file" |
  xargs -r -d '\n' -P "$jobs" -I {} yt-dlp "${args[@]}" -- {}
