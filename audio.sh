#!/bin/bash

echo "Link: "
read -r link

echo 'Download as playlist? (type "yes" or skip)'
read -r isPlaylist

# Fix 1: Correct variable assignment (no $) and comparison syntax (spaces needed)
if [ "$isPlaylist" = "yes" ]; then
  playlist_arg="--yes-playlist"
else
  playlist_arg="--no-playlist"
fi

# Fix 2: Logic split.
# If checking formats, we likely get an ID (number). If blindly downloading, we get an extension (text).
if [ "$playlist_arg" = "--no-playlist" ]; then
  # Standard flag is -F, not --list-formats (though both work, -F is shorter)
  #  yt-dlp -F "$link"
  echo "Choose an available audio format ID (e.g., 140) or extension (e.g., m4a): "
  read -r format
else
  echo "Choose a download format (type in a supported format like m4a, mp3, mp4 or webm): "
  read -r format
fi

echo "Choose path (default is ~/Music): "
read -r path

# Fix 3: Handle empty path AND tilde expansion manually
if [ -z "$path" ]; then
  path="$HOME/Music"
else
  # Bash 'read' does not expand '~' automatically. This regex replaces it with $HOME.
  path="${path/#\~/$HOME}"
fi

# Fix 4: Dynamic Command Construction
# The original code hardcoded "ba[ext=$format]", which fails if you type "mp3"
# (YouTube has no mp3 source) or if you type an ID like "140".

if [[ "$format" =~ ^[0-9]+$ ]]; then
  # If user typed a NUMBER (Format ID from the list)
  dl_args="-f $format -x"
else
  # If user typed TEXT (mp3, m4a), we download best audio and convert
  dl_args="-f bestaudio -x --audio-format $format"
fi

# Fix 5: Command Ordering
# - Removed '-f $isPlaylist' (this was breaking the command).
# - Placed $playlist_arg as a standalone flag.
# - Uses constructed $dl_args for correct format handling.

yt-dlp -U --update-to nightly --abort-on-error --verbose \
  $playlist_arg \
  $dl_args \
  "$link" \
  -P "$path"
rm *.part
