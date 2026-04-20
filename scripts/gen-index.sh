#!/bin/bash
# Auto-generate wiki/index.md from wiki/ filenames + first-line titles.
# No LLM needed — pure filesystem scan.
#
# Branches are auto-discovered by filename prefix (the part before the first hyphen).
# If you want a fixed branch order or display names, edit the BRANCHES override below.

WIKI_DIR="$(cd "$(dirname "$0")/../wiki" && pwd)"
INDEX="$WIKI_DIR/../index.md"

# ─── Branch order and display names ───
# Edit this array once your branch set stabilizes. Empty array = auto-discover
# branches by filename prefix (everything before first hyphen), and capitalize
# display names automatically.
declare -a BRANCHES=()

# ─── Auto-discover branches if not overridden ───
if [ ${#BRANCHES[@]} -eq 0 ]; then
  # Extract branch prefixes from filenames (everything before first hyphen)
  declare -A SEEN
  for f in "$WIKI_DIR"/*.md; do
    [ -f "$f" ] || continue
    slug=$(basename "$f" .md)
    [[ "$slug" == "index" || "$slug" == "log" || "$slug" == "_template" || "$slug" == "README" ]] && continue
    # Branch = filename up to first hyphen
    branch="${slug%%-*}"
    if [[ -z "${SEEN[$branch]}" ]]; then
      SEEN[$branch]=1
      # Display name = branch with hyphens->spaces and capitalized
      display=$(echo "$branch" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
      BRANCHES+=("$branch|$display")
    fi
  done
  # Sort branches alphabetically
  IFS=$'\n' BRANCHES=($(sort <<<"${BRANCHES[*]}"))
  unset IFS
fi

# ─── Count pages ───
PAGE_COUNT=0
for f in "$WIKI_DIR"/*.md; do
  [ -f "$f" ] || continue
  slug=$(basename "$f" .md)
  [[ "$slug" == "index" || "$slug" == "log" || "$slug" == "_template" || "$slug" == "README" ]] && continue
  ((PAGE_COUNT++))
done

# ─── Write header ───
echo "# Wiki Index" > "$INDEX"
echo "" >> "$INDEX"
echo "> Total pages: $PAGE_COUNT" >> "$INDEX"
echo "> Auto-generated: $(date '+%Y-%m-%d %H:%M')" >> "$INDEX"
echo "" >> "$INDEX"
echo "---" >> "$INDEX"
echo "" >> "$INDEX"

# ─── Write branches ───
for entry in "${BRANCHES[@]}"; do
  PREFIX="${entry%%|*}"
  DISPLAY="${entry##*|}"

  # Find matching files
  FILES=()
  for f in "$WIKI_DIR"/${PREFIX}-*.md; do
    [ -f "$f" ] || continue
    FILES+=("$f")
  done

  [ ${#FILES[@]} -eq 0 ] && continue

  echo "## $DISPLAY (${#FILES[@]} pages)" >> "$INDEX"
  echo "" >> "$INDEX"
  echo "| Slug | Title |" >> "$INDEX"
  echo "|------|-------|" >> "$INDEX"

  for f in $(printf '%s\n' "${FILES[@]}" | sort); do
    slug=$(basename "$f" .md)
    title=$(head -1 "$f" | sed 's/^# //')
    echo "| [[$slug]] | $title |" >> "$INDEX"
  done

  echo "" >> "$INDEX"
done

echo "Index generated: $PAGE_COUNT pages → $INDEX"
