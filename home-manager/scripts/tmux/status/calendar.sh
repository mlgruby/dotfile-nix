#!/usr/bin/env bash

tmux_status_collect_calendar() {
  calendar_status=""
  calendar_bg="#fabd2f"
  calendar_fg="#1d2021"

  local db_path="${HOME}/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"
  [ -r "$db_path" ] || return 0
  command -v sqlite3 >/dev/null 2>&1 || return 0

  # Query next non-all-day meeting from personal/work accounts that has not ended yet.
  local row
  row="$(
    sqlite3 -noheader -list "$db_path" "
      SELECT
        ci.summary || '|' ||
        CAST(ROUND((oc.occurrence_date - (strftime('%s', 'now') - 978307200)) / 60) AS INT) || '|' ||
        strftime('%H:%M', datetime(oc.occurrence_end_date + 978307200, 'unixepoch', 'localtime'))
      FROM OccurrenceCache oc
      JOIN CalendarItem ci ON oc.event_id = ci.ROWID
      WHERE oc.calendar_id IN (SELECT ROWID FROM Calendar WHERE title LIKE '%@%')
        AND oc.occurrence_end_date > (strftime('%s', 'now') - 978307200)
        AND ci.all_day = 0
      ORDER BY oc.occurrence_date ASC
      LIMIT 1;
    " 2>/dev/null || true
  )"

  [ -n "$row" ] || return 0

  local summary mins_until end_time
  summary="${row%%|*}"
  local rest="${row#*|}"
  mins_until="${rest%%|*}"
  end_time="${rest#*|}"

  # Truncate summary if long
  if [ "${#summary}" -gt 20 ]; then
    summary="${summary:0:19}…"
  fi

  # Meeting is currently in progress
  if [ "$mins_until" -le 0 ] 2>/dev/null; then
    calendar_bg="#fb4934"
    calendar_fg="#ffffff"
    calendar_status="󰃭 NOW: ${summary} (ends ${end_time})"
  # Meeting is starting in 5 minutes or less (urgent alert)
  elif [ "$mins_until" -le 5 ] 2>/dev/null; then
    calendar_bg="#fb4934"
    calendar_fg="#ffffff"
    calendar_status="󰃭 in ${mins_until}m: ${summary}"
  # Meeting is starting in 30 minutes or less (notice alert)
  elif [ "$mins_until" -le 30 ] 2>/dev/null; then
    calendar_bg="#fabd2f"
    calendar_fg="#1d2021"
    calendar_status="󰃭 in ${mins_until}m: ${summary}"
  else
    # More than 30 mins away: silent on statusbar
    calendar_status=""
  fi
}
