#!/usr/bin/env bash
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME/.junie"
notify="$root/scripts/notify-send.sh"
test ! -e "$root/scripts/config.py"
test -f "$root/resources/junie-logo.svg"
hooks_file="$root/.hooks-enabled"
test -f "$hooks_file"
grep --fixed-strings 'PermissionRequest=true' "$hooks_file"
grep --fixed-strings 'Stop=true' "$hooks_file"
grep --fixed-strings 'StopFailure=true' "$hooks_file"
printf '%s\n' '{"hook_event_name":"Stop","last_assistant_message":"test event"}' | JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$notify" >/dev/null
disabled_output=$(printf '%s\n' '{"hook_event_name":"SessionEnd","last_assistant_message":"disabled"}' | JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$notify")
test -z "$disabled_output"
JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$notify" test '{"hook_event_name":"SessionEnd","last_assistant_message":"Test przez WSL — żółć ąćęłńóśźż"}' >/dev/null
JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$notify" - test '{"hook_event_name":"Stop","last_assistant_message":"dash test"}' >/dev/null
printf '%s\n' '{"hook_event_name":"Stop","last_assistant_message":"stdin test"}' | JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$notify" - >/dev/null
bash -n "$notify"
! grep -R --fixed-strings "/home/tomasz" "$root/scripts"
! grep -R --fixed-strings "wsl.exe -l -q" "$root/scripts"
! grep -R --fixed-strings 'Junie.CLI' "$root/scripts"
! grep --fixed-strings 'Microsoft.WindowsTerminal_8wekyb3d8bbwe' "$root/scripts/notify-send.sh"
! grep --fixed-strings 'idea64' "$root/scripts/notify-send.sh"
! grep --fixed-strings 'WindowsTerminal' "$root/scripts/notify-send.sh"
! grep --fixed-strings 'activationType=' "$root/scripts/notify-send.sh"
! grep -R --fixed-strings 'CLAUDE_PLUGIN_ROOT' "$root/scripts"
grep --fixed-strings 'resources/junie-logo.svg' "$notify"
grep --fixed-strings "'.junie/junie-logo.svg'" "$notify"
printf '%s\n' 'all tests passed'