#!/usr/bin/env bash
# Push GitHub Actions secrets and variables from a local secrets file.
#
# Lines annotated with "# var" are pushed as repo variables (gh variable set).
# All other non-empty lines are pushed as encrypted secrets (gh secret set).
#
# Usage:
#   push-secrets.sh [--repo OWNER/REPO] [--secrets-file PATH]
#
# Defaults:
#   --repo          current repo (detected from git remote origin)
#   --secrets-file  .secrets in the current directory

set -euo pipefail

REPO=""
SECRETS_FILE=".secrets"

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo)         REPO="$2";         shift 2 ;;
    --secrets-file) SECRETS_FILE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "Error: secrets file not found: $SECRETS_FILE" >&2
  exit 1
fi

REPO_FLAG=()
if [[ -n "$REPO" ]]; then
  REPO_FLAG=(--repo "$REPO")
fi

echo "Loading from $SECRETS_FILE → ${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo 'current repo')}"
echo ""

while IFS= read -r line; do
  # Detect "# var" annotation before stripping
  is_var=0
  [[ "$line" =~ \#[[:space:]]*var([[:space:]]|$) ]] && is_var=1

  # Strip inline comments and whitespace
  line="${line%%#*}"
  line="${line//[[:space:]]/}"
  [[ -z "$line" ]] && continue
  [[ "$line" != *=* ]] && continue

  key="${line%%=*}"
  val="${line#*=}"

  if [[ -z "$val" ]]; then
    echo "  skip (empty):  $key"
    continue
  fi

  if [[ "$is_var" -eq 1 ]]; then
    echo "  variable:      $key"
    gh variable set "$key" --body "$val" "${REPO_FLAG[@]}"
  else
    echo "  secret:        $key"
    gh secret set "$key" --body "$val" "${REPO_FLAG[@]}"
  fi
done < "$SECRETS_FILE"

echo ""
echo "Done. Verify with:"
echo "  gh secret list ${REPO_FLAG[*]}"
echo "  gh variable list ${REPO_FLAG[*]}"
