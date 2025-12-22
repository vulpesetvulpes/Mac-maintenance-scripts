#!/bin/bash
# Deletes Desktop screenshots older than 14 days and untouched for 14 days.

DESKTOP="$HOME/Desktop"
NOW=$(date +%s)
TWO_WEEKS_AGO=$((NOW - 14*24*3600))

to_epoch() {
  [[ -n "$1" ]] && date -j -f "%Y-%m-%d %H:%M:%S %z" "$1" +%s 2>/dev/null || echo ""
}

find "$DESKTOP" -mindepth 1 -maxdepth 1 -type f \
  \( -iname "screenshot *" -o -iname "screen shot *" \) -print0 |
while IFS= read -r -d '' item; do
  mod_epoch=$(stat -f %m "$item" 2>/dev/null || echo 0)
  birth_epoch=$(stat -f %B "$item" 2>/dev/null || echo 0)
  add_raw=$(mdls -raw -name kMDItemDateAdded "$item" 2>/dev/null)
  open_raw=$(mdls -raw -name kMDItemLastUsedDate "$item" 2>/dev/null)

  add_epoch=$(to_epoch "$add_raw")
  open_epoch=$(to_epoch "$open_raw")

  [[ -z "$add_epoch" || "$add_epoch" -eq 0 ]] && add_epoch=$birth_epoch
  [[ -z "$open_epoch" ]] && open_epoch=0
  [[ "$add_epoch" -eq 0 ]] && add_epoch=$mod_epoch

  if [[ "$add_epoch" -lt "$TWO_WEEKS_AGO" && \
        "$mod_epoch" -lt "$TWO_WEEKS_AGO" && \
        "$open_epoch" -lt "$TWO_WEEKS_AGO" ]]; then
    trash "$item"
  fi
done
