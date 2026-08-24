#!/usr/bin/env bash
# Push GitHub Actions secrets and variables from one or more secrets files.
#
# Lines annotated with "# var" are pushed as repo variables (gh variable set).
# All other non-empty lines are pushed as encrypted secrets (gh secret set).
# Pass --secrets-file multiple times to merge files; later files win on duplicate keys.
#
# Usage:
#   push-secrets.sh [--repo OWNER/REPO] [--secrets-file PATH] ...
#
# Defaults:
#   --repo          current repo (detected from git remote origin)
#   --secrets-file  .secrets in the current directory

set -euo pipefail

REPO=""
SECRETS_FILES=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo)         REPO="$2";                    shift 2 ;;
    --secrets-file) SECRETS_FILES+=("$2");        shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# Default to .secrets if no files given
if [[ ${#SECRETS_FILES[@]} -eq 0 ]]; then
  SECRETS_FILES=(".secrets")
fi

REPO_FLAG=()
if [[ -n "$REPO" ]]; then
  REPO_FLAG=(--repo "$REPO")
fi

# Associative arrays: key → value, key → is_var flag
declare -A values
declare -A is_vars

for f in "${SECRETS_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: secrets file not found: $f" >&2
    exit 1
  fi

  echo "Loading $f..."

  while IFS= read -r line; do
    is_var=0
    [[ "$line" =~ \#[[:space:]]*var([[:space:]]|$) ]] && is_var=1

    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ -z "$line" ]] && continue
    [[ "$line" != *=* ]] && continue

    key="${line%%=*}"
    val="${line#*=}"
    values["$key"]="$val"
    is_vars["$key"]="$is_var"
  done < "$f"
done

REPO_LABEL="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo 'current repo')}"
echo ""
echo "Pushing to $REPO_LABEL..."
echo ""

for key in "${!values[@]}"; do
  val="${values[$key]}"

  if [[ -z "$val" ]]; then
    echo "  skip (empty):  $key"
    continue
  fi

  if [[ "${is_vars[$key]}" -eq 1 ]]; then
    echo "  variable:      $key"
    gh variable set "$key" --body "$val" "${REPO_FLAG[@]}"
  else
    echo "  secret:        $key"
    gh secret set "$key" --body "$val" "${REPO_FLAG[@]}"
  fi
done

echo ""
echo "Done. Verify with:"
echo "  gh secret list ${REPO_FLAG[*]-}"
echo "  gh variable list ${REPO_FLAG[*]-}"
