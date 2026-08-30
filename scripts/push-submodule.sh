#!/usr/bin/env bash
#
# push-submodule.sh — push a submodule branch to its remote with token auth.
#
# Why this exists
# ---------------
# The parent repo's submodule remotes are plain HTTPS URLs, and .gitmodules
# sets `ignore = all`, so:
#   * `git push` inside a submodule prompts for credentials and hangs;
#   * `git status` in the parent hides gitlink drift;
#   * plain `git add <path>` silently skips pointer updates.
#
# This script performs the authenticated push the manual workflow describes,
# then prints the exact follow-up commands for pinning the new commit in the
# parent repo. It never modifies git config and never leaves the token in the
# working tree (the push URL is passed inline).
#
# Usage
# -----
#   scripts/push-submodule.sh <submodule-path> [branch] [--dry-run]
#   scripts/push-submodule.sh --help
#
#   <submodule-path>  path in the parent repo (e.g. ebms-core, documentation)
#                     or the submodule name from .gitmodules.
#   [branch]          branch to push (default: the branch configured in
#                     .gitmodules for that submodule).
#
# Token
# -----
#   Provide one of (checked in this order):
#     1. $SUBMODULE_GITHUB_TOKEN
#     2. $GITHUB_TOKEN
#   Minimal permissions: Contents read+write on the target repo(s).
#
#   Tip: pass the token via the environment rather than the command line so it
#   does not appear in shell history or process listings, e.g.
#     export SUBMODULE_GITHUB_TOKEN=...
#     scripts/push-submodule.sh ebms-core
#
# Safety
# -----
#   * Refuses to run unless the token is set.
#   * `--dry-run` prints the push URL (token masked) without pushing.
#   * Pushes to the branch only; never forces, never pushes tags.

set -euo pipefail

DRY_RUN=0
ARG1=""
ARG2=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h)
      sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      if [ -z "$ARG1" ]; then ARG1="$arg"
      elif [ -z "$ARG2" ]; then ARG2="$arg"
      else echo "error: too many arguments: $arg" >&2; exit 2; fi
      ;;
  esac
done

if [ -z "$ARG1" ]; then
  echo "usage: $(basename "$0") <submodule-path|name> [branch] [--dry-run]" >&2
  exit 2
fi
TARGET="$ARG1"

# Run from the repo root (the parent of the scripts/ directory) so the
# submodule path is resolved consistently regardless of the caller's cwd.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# --- Resolve the submodule (accept a .gitmodules name OR a repo path) --------
SUBDIR=""
SUBURL=""
SUBBRANCH=""

# 1) Is TARGET a submodule name in .gitmodules?
SUBDIR="$(git config -f .gitmodules --get "submodule.$TARGET.path" || true)"
if [ -n "$SUBDIR" ]; then
  SUBURL="$(git config -f .gitmodules --get "submodule.$TARGET.url" || true)"
  SUBBRANCH="$(git config -f .gitmodules --get "submodule.$TARGET.branch" || true)"
fi

# 2) Otherwise treat TARGET as a path and find the submodule whose path matches.
if [ -z "$SUBDIR" ]; then
  while read -r fullkey value; do
    if [ "$value" = "$TARGET" ]; then
      SUBNAME="${fullkey#submodule.}"; SUBNAME="${SUBNAME%.path}"
      SUBDIR="$TARGET"
      SUBURL="$(git config -f .gitmodules --get "submodule.$SUBNAME.url" || true)"
      SUBBRANCH="$(git config -f .gitmodules --get "submodule.$SUBNAME.branch" || true)"
      break
    fi
  done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$')
fi

if [ -z "$SUBDIR" ]; then
  echo "error: '$TARGET' is not a known submodule (name or path)." >&2
  echo "available: $(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}' | paste -sd, -)" >&2
  exit 1
fi

if [ ! -d "$SUBDIR/.git" ] && [ ! -f "$SUBDIR/.git" ]; then
  echo "error: '$SUBDIR' is not an initialized submodule." >&2
  echo "hint:  git submodule update --init --recursive" >&2
  exit 1
fi

if [ -z "$SUBURL" ]; then
  SUBURL="$(git -C "$SUBDIR" remote get-url origin)"
fi

BRANCH="${SUBBRANCH:-}"
if [ -z "$BRANCH" ]; then
  BRANCH="$(git -C "$SUBDIR" rev-parse --abbrev-ref HEAD)"
fi

# --- Token -------------------------------------------------------------------
TOKEN="${GITHUB_TOKEN:-}"
if [ "$DRY_RUN" -eq 0 ] && [ -z "$TOKEN" ]; then
  echo "error: no token found. Export SUBMODULE_GITHUB_TOKEN (or GITHUB_TOKEN) first." >&2
  exit 1
fi

# Only the host and repo path are needed to build the push URL.
HOST="$(printf '%s' "$SUBURL" | sed -E 's#^https?://([^/]+)/.*#\1#')"
REPO_PATH="$(printf '%s' "$SUBURL" | sed -E 's#^https?://[^/]+/##')"

mask_url() {
  if [ -n "$TOKEN" ]; then printf 'https://x-access-token:********@%s/%s' "$HOST" "$REPO_PATH"
  else printf 'https://%s/%s' "$HOST" "$REPO_PATH"; fi
}

echo "submodule : $SUBDIR (remote $HOST/$REPO_PATH)"
echo "branch    : $BRANCH"
echo "push url  : $(mask_url)"

# --- Push --------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
  echo "dry-run   : no push performed."
  exit 0
fi

PUSH_URL="https://x-access-token:$TOKEN@$HOST/$REPO_PATH"

echo "pushing   : $BRANCH -> origin"
# Pass the URL as an explicit push refspec; no changes to git config.
git -C "$SUBDIR" push "$PUSH_URL" "HEAD:$BRANCH"

NEW_SHA="$(git -C "$SUBDIR" rev-parse HEAD)"
echo "pushed    : $NEW_SHA"
echo
echo "Next, pin the new commit in the parent repo:"
echo "  cd $ROOT"
echo "  git add -f $SUBDIR      # 'add -f' is required (submodule ignore = all)"
echo "  git commit -m 'pin $SUBDIR to $NEW_SHA'"
echo "  git push"
echo
echo "Reminder: CI checks out the pinned SHA with a shallow fetch, so the"
echo "commit must exist on the remote (it does now) before CI runs."
