#!/bin/bash

DOWNLOADS="$HOME/Downloads"
NOW=$(date +%s)
MONTH_AGO=$((NOW - 30*24*3600))
TWO_WEEKS_AGO=$((NOW - 14*24*3600))
deleted_count=0

while IFS= read -r -d '' item; do
  # Timestamps
  mod_epoch=$(stat -f %m "$item" 2>/dev/null || echo 0)
  add_raw=$(mdls -raw -name kMDItemDateAdded "$item" 2>/dev/null)
  open_raw=$(mdls -raw -name kMDItemLastUsedDate "$item" 2>/dev/null)

  to_epoch() { [ -n "$1" ] && date -j -f "%Y-%m-%d %H:%M:%S %z" "$1" +%s 2>/dev/null || echo ""; }
  add_epoch=$(to_epoch "$add_raw")
  open_epoch=$(to_epoch "$open_raw")

  [ -z "$add_epoch" ] && add_epoch=$mod_epoch
  [ -z "$open_epoch" ] && open_epoch=0

  # Folder freshness check
  if [ -d "$item" ]; then
    if find "$item" -type f -newermt "-14 days" -print -quit | grep -q .; then
      continue
    fi
  fi

  # Trash if old and untouched
  if [ "$add_epoch" -lt "$MONTH_AGO" ] && [ "$mod_epoch" -lt "$TWO_WEEKS_AGO" ] && [ "$open_epoch" -lt "$TWO_WEEKS_AGO" ]; then
    if command -v trash >/dev/null 2>&1; then
      trash "$item"
    else
      osascript -e "tell application \"Finder\" to move (POSIX file \"$item\") to trash"
    fi
    deleted_count=$((deleted_count + 1))
  fi
done < <(find "$DOWNLOADS" -mindepth 1 -maxdepth 1 -print0)

if [ "$deleted_count" -gt 0 ]; then
  if [ "$deleted_count" -eq 1 ]; then
    file_label="file"
  else
    file_label="files"
  fi
  message="Deleted $deleted_count $file_label"
else
  message="No files to delete"
fi

osascript -e "display notification \"$message\" with title \"Downloads Cleaner\""
echo "$message"
