#!/bin/bash
# Wiki Lint - Programmatic Layer
# 檢查四項：ghost links、orphan pages、format violations、outdated markers
# 產出 lint-report.md

WIKI_DIR="$(cd "$(dirname "$0")/../wiki" && pwd)"
REPORT="$WIKI_DIR/../lint-report.md"
ERRORS=0
WARNINGS=0

echo "# Wiki Lint Report" > "$REPORT"
echo "" >> "$REPORT"
echo "> Generated: $(date '+%Y-%m-%d %H:%M')" >> "$REPORT"
echo "" >> "$REPORT"

# Collect all wiki slugs (filename without .md)
declare -A SLUGS
for f in "$WIKI_DIR"/*.md; do
  [ -f "$f" ] || continue
  slug=$(basename "$f" .md)
  # Skip index and log
  [[ "$slug" == "index" || "$slug" == "log" || "$slug" == "_template" || "$slug" == "README" ]] && continue
  SLUGS["$slug"]=1
done

# ─── 1. Ghost Links ───
# Find [[links]] that point to non-existent pages
echo "## 1. Ghost Links（指向不存在頁面的連結）" >> "$REPORT"
echo "" >> "$REPORT"
FOUND_GHOST=0

for f in "$WIKI_DIR"/*.md; do
  [ -f "$f" ] || continue
  slug=$(basename "$f" .md)
  [[ "$slug" == "index" || "$slug" == "log" || "$slug" == "_template" || "$slug" == "README" ]] && continue

  # Extract all [[...]] links
  while IFS= read -r link; do
    # Strip the display text if present (e.g. [[slug|display]])
    target="${link%%|*}"
    if [[ -z "${SLUGS[$target]}" ]]; then
      echo "- \`$slug\` → \`[[$target]]\` (not found)" >> "$REPORT"
      FOUND_GHOST=1
      ((ERRORS++))
    fi
  done < <(grep -o '\[\[[^]]*\]\]' "$f" 2>/dev/null | sed 's/^\[\[//;s/\]\]$//')
done

if [ $FOUND_GHOST -eq 0 ]; then
  echo "None." >> "$REPORT"
fi
echo "" >> "$REPORT"

# ─── 2. Orphan Pages ───
# Pages with zero incoming links from other wiki pages
echo "## 2. Orphan Pages（沒有任何頁面連結過來的頁面）" >> "$REPORT"
echo "" >> "$REPORT"
FOUND_ORPHAN=0

# Collect all outgoing links
declare -A INCOMING
for slug in "${!SLUGS[@]}"; do
  INCOMING["$slug"]=0
done

for f in "$WIKI_DIR"/*.md; do
  [ -f "$f" ] || continue
  slug=$(basename "$f" .md)
  [[ "$slug" == "index" || "$slug" == "log" || "$slug" == "_template" || "$slug" == "README" ]] && continue

  while IFS= read -r link; do
    target="${link%%|*}"
    if [[ -n "${SLUGS[$target]}" ]]; then
      INCOMING["$target"]=$(( ${INCOMING[$target]:-0} + 1 ))
    fi
  done < <(grep -o '\[\[[^]]*\]\]' "$f" 2>/dev/null | sed 's/^\[\[//;s/\]\]$//')
done

for slug in $(echo "${!SLUGS[@]}" | tr ' ' '\n' | sort); do
  if [[ "${INCOMING[$slug]}" == "0" ]]; then
    echo "- \`$slug\`" >> "$REPORT"
    FOUND_ORPHAN=1
    ((WARNINGS++))
  fi
done

if [ $FOUND_ORPHAN -eq 0 ]; then
  echo "None." >> "$REPORT"
fi
echo "" >> "$REPORT"

# ─── 3. Format Violations ───
echo "## 3. Format Violations（格式違規）" >> "$REPORT"
echo "" >> "$REPORT"
FOUND_FORMAT=0

for f in "$WIKI_DIR"/*.md; do
  [ -f "$f" ] || continue
  slug=$(basename "$f" .md)
  [[ "$slug" == "index" || "$slug" == "log" || "$slug" == "_template" || "$slug" == "README" ]] && continue

  # 3a. First line must be # title
  first_line=$(head -1 "$f")
  if [[ ! "$first_line" =~ ^#\  ]]; then
    echo "- \`$slug\`: first line is not \`# title\` → \`$first_line\`" >> "$REPORT"
    FOUND_FORMAT=1
    ((ERRORS++))
  fi

  # 3b. Filename must be lowercase with hyphens only
  if [[ "$slug" =~ [A-Z_] ]]; then
    echo "- \`$slug\`: filename contains uppercase or underscore" >> "$REPORT"
    FOUND_FORMAT=1
    ((ERRORS++))
  fi

  # 3c. Check for raw URLs in wiki links (should be [[slug]] not [text](url))
  # This is a soft check — markdown links to external sites are fine
done

if [ $FOUND_FORMAT -eq 0 ]; then
  echo "None." >> "$REPORT"
fi
echo "" >> "$REPORT"

# ─── 4. Outdated Markers ───
# Only flag temporal words that carry version/tool-specific claims likely to expire.
# Generic narrative uses of 現在/目前 (historical contrast, rhetorical) are intentionally excluded.
echo "## 4. Outdated Markers（時效性用語）" >> "$REPORT"
echo "" >> "$REPORT"
FOUND_OUTDATED=0

PATTERNS='最新版|目前最新|currently v|latest v|just released|剛出|剛推出|截至 [0-9]{4}'

for f in "$WIKI_DIR"/*.md; do
  [ -f "$f" ] || continue
  slug=$(basename "$f" .md)
  [[ "$slug" == "index" || "$slug" == "log" || "$slug" == "_template" || "$slug" == "README" ]] && continue

  matches=$(grep -nE "$PATTERNS" "$f" 2>/dev/null)
  if [ -n "$matches" ]; then
    echo "### \`$slug\`" >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "$matches" >> "$REPORT"
    echo '```' >> "$REPORT"
    FOUND_OUTDATED=1
    ((WARNINGS++))
  fi
done

if [ $FOUND_OUTDATED -eq 0 ]; then
  echo "None." >> "$REPORT"
fi
echo "" >> "$REPORT"

# ─── Summary ───
echo "---" >> "$REPORT"
echo "" >> "$REPORT"
echo "**Summary**: $ERRORS errors, $WARNINGS warnings across ${#SLUGS[@]} wiki pages" >> "$REPORT"

echo "Lint complete: $ERRORS errors, $WARNINGS warnings. Report: $REPORT"
