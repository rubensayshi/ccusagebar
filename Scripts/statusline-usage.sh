#!/bin/bash
# CCUsageBar statusLine producer.
#
# Claude Code injects a JSON payload into your statusLine command on stdin.
# When you're a Pro/Max subscriber, that payload carries a `rate_limits` block
# with the real 5-hour and 7-day utilization — the same numbers behind /usage,
# sourced from Anthropic's API response headers. This script extracts that block
# and writes it to ~/.claude/usage-status.json, which the CCUsageBar menu bar app
# reads. No keychain token, no extra API call, no session conflict.
#
# Usage — source/call it from your own ~/.claude/statusline-command.sh:
#
#   input=$(cat)
#   /path/to/ccusagebar/scripts/statusline-usage.sh "$input"
#   # ... your own statusline rendering using "$input" ...
#
# Accepts the payload as $1, or falls back to stdin.

input="${1:-$(cat)}"

[[ -z "$input" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Only write when a rate_limits block is present (absent outside an active
# session, or for non-subscriber plans).
echo "$input" | jq -e '.rate_limits' >/dev/null 2>&1 || exit 0

out="$HOME/.claude/usage-status.json"
tmp="$out.tmp.$$"

echo "$input" | jq -c '
  .rate_limits as $rl
  | {
      updated: (now | floor),
      five_hour: ($rl.five_hour  | if . then {utilization: .used_percentage, resets_at: .resets_at} else null end),
      seven_day: ($rl.seven_day | if . then {utilization: .used_percentage, resets_at: .resets_at} else null end)
    }
' > "$tmp" 2>/dev/null && mv -f "$tmp" "$out" || rm -f "$tmp"
