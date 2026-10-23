#!/usr/bin/env bash
# Installs the Motion Design Director plugin for Claude Code (macOS / Linux / Git Bash).
#
#   1. checks that the Claude Code CLI is installed
#   2. adds the "motion-design-director" marketplace if it is not already added
#   3. installs ONLY the "motion-director" plugin
#   4. verifies the result
#
# The official Remotion plugin is NOT installed by this script: Claude Code installs it by itself
# because motion-director declares it as a dependency.
#
# It never edits git config, SSH config or known_hosts, and never removes or overwrites anything.
# It exports CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1 for its own process only, so the public GitHub
# repositories involved are cloned over HTTPS instead of SSH.
#
# Canonical install (this script is only a convenience):
#   claude plugin marketplace add eshaan-eshaan/motion-design-director
#   claude plugin install motion-director@motion-design-director
#
# Usage: install.sh [--source <owner/repo|path>] [--scope user|project|local] [--bare-command]
#   --bare-command  also copy the skill to your personal skills folder so the un-namespaced
#                   /motion-design command exists (skipped if it already exists; not auto-updated)

set -u

SOURCE="eshaan-eshaan/motion-design-director"
SCOPE="user"
BARE=0
MARKETPLACE="motion-design-director"
PLUGIN="motion-director"
PLUGIN_ID="$PLUGIN@$MARKETPLACE"

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE="${2:-}"; shift 2 ;;
    --scope) SCOPE="${2:-}"; shift 2 ;;
    --bare-command) BARE=1; shift ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done
case "$SCOPE" in user|project|local) ;; *) echo "--scope must be user, project or local" >&2; exit 2 ;; esac

step() { printf '==> %s\n' "$1"; }
ok()   { printf '    OK   %s\n' "$1"; }
warn() { printf '    WARN %s\n' "$1"; }
fail() { printf '    FAIL %s\n' "$1" >&2; [ -n "${2:-}" ] && printf '         %s\n' "$2" >&2; exit 1; }

# 1. Claude Code installed?
step "Checking for Claude Code"
command -v claude >/dev/null 2>&1 || fail 'The "claude" command was not found on PATH.' 'Install Claude Code first: https://code.claude.com/docs/en/quickstart , open a new terminal and run this script again.'
VER="$(claude --version 2>&1)" || fail 'Could not run "claude --version".' "$VER"
ok "Claude Code $VER"
claude plugin --help >/dev/null 2>&1 || fail 'This Claude Code version has no "claude plugin" commands.' 'Update Claude Code, then run this script again.'

# Clone public GitHub repos over HTTPS (this process only). Older Claude Code versions (seen on 2.1.212) fail with
# "SSH host key is not in your known_hosts" on machines that never connected to github.com over SSH; newer ones
# (2.1.309) fall back to HTTPS themselves. Respect an explicit user setting.
export CLAUDE_CODE_PLUGIN_PREFER_HTTPS="${CLAUDE_CODE_PLUGIN_PREFER_HTTPS:-1}"

# 2. Marketplace
step "Adding the $MARKETPLACE marketplace ($SCOPE scope)"
if claude plugin marketplace list 2>&1 | grep -q "$MARKETPLACE"; then
  ok "Marketplace already added; refreshing it"
  OUT="$(claude plugin marketplace update "$MARKETPLACE" 2>&1)" || warn "Could not refresh the marketplace (continuing with the cached copy): $OUT"
else
  OUT="$(claude plugin marketplace add "$SOURCE" --scope "$SCOPE" 2>&1)" \
    || fail "Could not add the marketplace from '$SOURCE'." "$OUT
         Check the source value, your network connection, and that git is installed (git --version)."
  ok "Marketplace added from $SOURCE"
fi

# 3. Install only the primary plugin; Claude Code resolves the Remotion dependency.
step "Installing $PLUGIN_ID (Claude Code adds the official Remotion plugin as its dependency)"
OUT="$(claude plugin install "$PLUGIN_ID" --scope "$SCOPE" 2>&1)"; RC=$?
printf '    %s\n' "$OUT"
[ $RC -eq 0 ] || fail "claude plugin install failed (exit code $RC)." 'If the message mentions a git clone, check your network and that git is installed, then run this script again.'

# 4. Verify (parses the human-readable `claude plugin list`)
step "Verifying"
LIST="$(claude plugin list 2>&1)"
block() { printf '%s\n' "$LIST" | awk -v id="$1" '/❯/ { on = index($0, id) > 0 } on { print }'; }
PB="$(block "$PLUGIN_ID")"
[ -n "$PB" ] || fail "$PLUGIN_ID is not in the installed plugin list." 'Run "claude plugin list" to see what was installed.'
if printf '%s\n' "$PB" | grep -q 'failed to load'; then
  fail "$PLUGIN_ID is installed but failed to load:" "$(printf '%s\n' "$PB" | grep 'Error:')
         Fix the cause above (usually a failed git clone of the Remotion dependency), then run:  claude plugin install remotion@$MARKETPLACE"
fi
printf '%s\n' "$PB" | grep -q 'enabled' || fail "$PLUGIN_ID is installed but not enabled." "Run: claude plugin enable $PLUGIN_ID"
ok "$PLUGIN_ID is enabled"

REMOTION_IDS="$(printf '%s\n' "$LIST" | grep -o '❯ remotion@[^ ]*' | sed 's/❯ //')"
COUNT=0
for rid in $REMOTION_IDS; do
  RB="$(block "$rid")"
  if printf '%s\n' "$RB" | grep -q 'enabled' && ! printf '%s\n' "$RB" | grep -q 'failed to load'; then
    ok "Official Remotion plugin: $rid is enabled"; COUNT=$((COUNT+1))
  fi
done
[ "$COUNT" -ge 1 ] || fail 'The official Remotion plugin is not enabled, so the dependency did not resolve.' "Run: claude plugin install remotion@$MARKETPLACE"
if [ "$COUNT" -gt 1 ]; then
  warn 'More than one copy of the Remotion plugin is enabled. This is harmless (newer Claude Code versions de-duplicate the skills, older ones list each twice).'
  for rid in $REMOTION_IDS; do
    [ "$rid" = "remotion@$MARKETPLACE" ] || warn "To keep a single copy, you can run:  claude plugin uninstall $rid"
  done
fi

# 5. Optional bare /motion-design command (personal skill copy)
if [ "$BARE" -eq 1 ]; then
  step "Adding the optional bare /motion-design command"
  CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  DEST="$CFG/skills/motion-design"
  SRC_DIR="$(ls -d "$CFG/plugins/cache/$MARKETPLACE/$PLUGIN"/*/ 2>/dev/null | sort -V | tail -1)skills/motion-design"
  if [ -e "$DEST" ]; then
    warn "$DEST already exists; leaving it untouched."
  elif [ ! -d "$SRC_DIR" ]; then
    warn 'Could not locate the installed skill files; skipping the bare command.'
  else
    mkdir -p "$CFG/skills" && cp -R "$SRC_DIR" "$DEST" \
      && ok "Copied the skill to $DEST (this copy does not auto-update; delete it to remove /motion-design)" \
      || warn 'Copy failed; skipping the bare command.'
  fi
fi

echo
echo "Done."
echo "  Restart Claude Code, or run /reload-plugins in a session that is already open."
echo "  Then, inside a Remotion project:  /motion-director:motion-design <your brief>"
echo "  You also need Node.js and Git, and a Remotion project (the skill can create one for you)."
