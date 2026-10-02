#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/.." && pwd)"
bin="${EROGEDOTS_TEST_BIN:-$root/picker-rs/target/release}"
tmp="$(mktemp -d)"
trap 'rm -r -- "$tmp"' EXIT
cat > "$tmp/niri" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == 'msg -j workspaces' ]]; then
    if [[ -f "$TEST_DATA/focused" ]]; then focused=false; empty=true; else focused=true; empty=false; fi
    printf '[{"id":11,"idx":1,"output":"DP-1","is_focused":%s},{"id":22,"idx":2,"output":"DP-1","is_focused":%s}]\n' "$focused" "$empty"
elif [[ "$*" == 'msg -j windows' ]]; then
    printf '[{"workspace_id":11}]\n'
elif [[ "$*" == 'msg action focus-workspace 2' ]]; then
    touch "$TEST_DATA/focused"
    printf '%s\n' "$*" >> "$TEST_DATA/actions"
elif [[ "$*" == 'msg action focus-workspace 1' ]]; then
    printf '%s\n' "$*" >> "$TEST_DATA/actions"
fi
STUB
cat > "$tmp/ghostty" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$TEST_DATA/arguments"
exit 7
STUB
chmod +x "$tmp/niri" "$tmp/ghostty"
result=0
TEST_DATA="$tmp" PATH="$tmp:$PATH" "$bin/title-terminal" printf '%s' 'literal; shell text' > "$tmp/result" || result=$?
[[ "$result" == 7 ]]
jq -e '.origin == 11' "$tmp/result" >/dev/null
[[ "$(tail -1 "$tmp/actions")" == 'msg action focus-workspace 1' ]]
rg -q '^literal; shell text$' "$tmp/arguments"
printf 'PASS: floating terminal keeps argument boundaries, reports exit status and restores the original workspace\n'
