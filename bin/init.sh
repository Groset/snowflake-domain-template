#!/usr/bin/env bash
# init.sh — personalize the template for a new domain.
#
# Run once after creating a repo from the template.
# Substitutes <DOMAIN_NAME>, <PRIMARY_DB>, and <PRIMARY_SCHEMA> across the repo.
#
# Compatible with bash on Linux, macOS, WSL, and Git Bash on Windows.

set -euo pipefail

# Resolve repo root (parent of this script's directory)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== snowflake-domain-template — personalization ==="
echo
echo "This will substitute <DOMAIN_NAME>, <PRIMARY_DB>, and <PRIMARY_SCHEMA>"
echo "across the template files. Run once after cloning."
echo

# --- Prompt for values ---
read -r -p "Domain name        (e.g. il-customers): " DOMAIN_NAME
read -r -p "Primary database   (e.g. IL_Customers): " PRIMARY_DB
read -r -p "Primary schema     (e.g. PUBLIC):       " PRIMARY_SCHEMA

# Default schema if blank
PRIMARY_SCHEMA="${PRIMARY_SCHEMA:-PUBLIC}"

echo
echo "Will substitute:"
echo "  <DOMAIN_NAME>     -> $DOMAIN_NAME"
echo "  <PRIMARY_DB>      -> $PRIMARY_DB"
echo "  <PRIMARY_SCHEMA>  -> $PRIMARY_SCHEMA"
echo
read -r -p "Proceed? [y/N] " CONFIRM
case "$CONFIRM" in
  y|Y|yes|YES) ;;
  *) echo "Aborted."; exit 1 ;;
esac

# --- Substitute across tracked files (excluding this script and .git) ---
FILES_TO_PATCH=$(find . \
  -type f \
  \( -name "*.md" -o -name "*.yml" -o -name "*.yaml" -o -name "*.sql" \) \
  -not -path "./.git/*" \
  -not -path "./bin/*")

# If the primary schema is not PUBLIC, also rename the sql/public folder
if [ "$PRIMARY_SCHEMA" != "PUBLIC" ] && [ "$PRIMARY_SCHEMA" != "public" ]; then
  SCHEMA_LOWER=$(echo "$PRIMARY_SCHEMA" | tr '[:upper:]' '[:lower:]')
  if [ -d "sql/public" ]; then
    mv "sql/public" "sql/$SCHEMA_LOWER"
    echo "Renamed sql/public/ -> sql/$SCHEMA_LOWER/"
  fi
fi

# Perform substitutions
for f in $FILES_TO_PATCH; do
  # Use a portable in-place sed: write to a temp file then move
  sed \
    -e "s|<DOMAIN_NAME>|$DOMAIN_NAME|g" \
    -e "s|<PRIMARY_DB>|$PRIMARY_DB|g" \
    -e "s|<PRIMARY_SCHEMA>|$PRIMARY_SCHEMA|g" \
    "$f" > "$f.tmp"
  mv "$f.tmp" "$f"
done

echo
echo "Personalization complete."
echo
echo "Next steps:"
echo "  1. Review the changes:    git diff"
echo "  2. Read CLAUDE.md's 'First Steps' checklist."
echo "  3. Commit:                git add -A && git commit -m 'chore: personalize template'"
