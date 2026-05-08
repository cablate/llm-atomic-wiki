# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Quick commands

All scripts live in `scripts/` and require Bash (Git Bash or WSL on Windows).

```bash
# After every Ingest or Compile run — in this order:
bash scripts/gen-index.sh                    # rebuild index.md
bash scripts/log-append.sh "what you did"    # append to log.md

# After Compile, also run:
bash scripts/lint.sh                         # programmatic Lint → lint-report.md
```

### Claude Code skills (invoke from chat)

| Skill | When to use |
|-------|-------------|
| `/ingest` | Extract atoms from raw/ material |
| `/compile` | Synthesize atoms into wiki pages |
| `/query` | Answer a question from the wiki |
| `/lint` | Run both programmatic + LLM Lint layers |
| `/refresh` | Rebuild index.md + append log.md |
| `/branch-plan` | Design or audit branch structure |

---

## Schema for LLMs operating this repo

You are operating on a knowledge base built on the LLM Wiki pattern (Karpathy 2026), with four optimizations: an atom layer, topic-branch organization, two-layer Lint, and parallel-compile naming locks.

Read everything below before touching anything. Mental model, operations, file formats, lifecycle rules, and what you must never do.

---

## Mental model

Three storage layers, one navigation layer, one log layer:

```
raw/                  sources you may read but never write
atoms/                knowledge atoms, organized by topic-branch
  <branch-1>/         one folder per topic
  <branch-2>/         each contains atoms (source of truth)
  ...
wiki/                 compiled pages from atoms, derived cache
index.md              auto-generated wiki navigation
log.md                append-only change history
```

Atoms are immutable. Wiki is rebuildable from atoms. If a wiki page is wrong, fix the underlying atom and recompile, never patch the wiki.

Each branch folder under `atoms/` holds the atoms for that topic, plus an optional `_archive/` for superseded atoms.

---

## Atom format (spec)

### Frontmatter (YAML, required)

```yaml
---
id: <branch>/<descriptive-slug>
type: explanation | opinion | tutorial | myth-busting | case-study | comparison
depth: beginner | intermediate | advanced
source_type: post | reply | thread | transcript | article | note | screenshot | audio
source_ids: []
reuse_score: high | medium | low
tags: []
created: YYYY-MM-DD
---
```

| Field | Notes |
|-------|-------|
| `id` | Format `<branch>/<slug>`. Slug all lowercase, hyphens only. Must be unique within branch. |
| `type` | What kind of knowledge this atom carries. Pick one. |
| `depth` | Audience level. Used in gap analysis. |
| `source_type` | Where the raw came from. Extend the enum if your sources differ. |
| `source_ids` | Stable identifiers (URLs, paths, post IDs). Atoms without source attribution are not auditable. |
| `reuse_score` | `high` = standalone-publishable, `medium` = needs companions, `low` = niche. |
| `tags` | Cross-cutting concerns. Used to surface related atoms across branches. |
| `created` | ISO date. Used for chronological ordering and stale-detection. |

Optional fields you may add: `confidence` (high/medium/low), `superseded_by` (id of replacement atom), `archived` (boolean).

### Filename

Pattern: `YYYY-MM-DD-<descriptive-slug>.md`

- Date prefix gives natural chronological order in `ls`.
- Slug all lowercase, hyphens only — no underscores, no spaces, no uppercase.
- Slug should be 3–6 words describing the core claim.

### Body

- One core claim per atom. If two independent claims share a paragraph, split into two atoms.
- Refine, don't copy. Strip filler from the source; preserve the author's voice and stance.
- Cite source at the end if you want traceability beyond `source_ids`.

### Lifecycle (immutable)

Atoms are immutable. Do not edit after creation.

When knowledge evolves:
1. Create a new atom with the updated claim.
2. Add `superseded_by: <new-atom-id>` to the old atom's frontmatter.
3. Move the old atom to `atoms/<branch>/_archive/`.
4. Recompile any wiki page that referenced the old atom.

Never delete an atom outright. Use `_archive/`. Final deletion is a separate, conscious decision.

See `atoms/_template.md` for a copyable starter.

---

## Wiki page format (spec)

### Filename

Pattern: `<branch>-<topic-slug>.md`

- Branch prefix lets `gen-index.sh` group pages.
- All lowercase, hyphens only.
- Lives flat in `wiki/`, not in subfolders.

### First line

Must be `# Title`. `gen-index.sh` reads this for the index entry. Lint flags violations.

### Wiki links

Pattern: `[[slug]]` or `[[slug|display text]]`

- The slug must equal an existing wiki filename without `.md`.
- Lint flags ghost links and orphan pages.

### Body structure

```markdown
# Page Title

Opening paragraph: why this matters, common misconception, what you'll get.

## Section
Integrated content from multiple atoms, written as coherent prose.
First mention of a related concept gets a [[wiki-link]]; subsequent
mentions in the same page don't repeat it.

## Section
Continue.

---

**See also**
- [[related-page]] — one-line description

---
*Compiled from atoms: branch/atom-slug-1, branch/atom-slug-2, ...*
```

### Length

- Target 1500–2500 words per page.
- Past 2500 words: consider splitting.
- Below 800 words: consider merging or staying at atom level.

### Temporal markers

In time-sensitive claims, use one of:
- Specific date: `as of 2026-04`, `截至 2026-04`
- Version number: `v3.5`, `Claude 3.5 Sonnet`

Avoid bare `currently` / `latest` / `now` / `目前` / `現在` in time-sensitive contexts. Lint regex flags only `<temporal word> <version/date>` combinations to avoid false-positive flooding from rhetorical use.

See `wiki/_template.md` for a copyable starter.

---

## Branch design (spec)

### When to add a branch (all four required)

1. **Independence** — the topic doesn't fit cleanly under any existing branch.
2. **Scale** — you expect 5+ atoms in this branch.
3. **Clear boundary** — you can write a one-paragraph rule for "what belongs, what doesn't".
4. **Teaching independence** — the branch could anchor a 30-minute talk on its own.

If only 1–2 atoms fit a candidate topic, use tags instead.

### When to merge or remove

- **Hollow** — branch holds <3 atoms with no growth trajectory.
- **Overlap** — >50% of atoms also tagged with another branch → merge or redefine.
- **Subset** — branch A's content is essentially a subset of branch B → merge.

### When to split

- **Bloat** — single branch exceeds 30 atoms and content naturally clusters.
- **Teaching need** — preparing a course reveals the branch needs to split.

### One atom, one branch

If an atom spans two branches, pick the one matching the core claim. Use `tags` for the secondary topic.

### Operations checklist

When adding/merging/splitting:
1. Document the rationale (one-paragraph note in `log.md`).
2. Update branch lists in any docs that enumerate them.
3. Move affected atoms (update their frontmatter `id`).
4. Confirm no orphan tags or broken `[[ ]]` references remain.

---

## Operations

You execute four operations on demand:

### Ingest

User adds new material to `raw/` (or any source location). You read it, classify each segment ("extract" / "skip" / "deferred"), then extract the "extract" segments into atoms under the matching `atoms/<branch>/` folder.

Constraints:
- One atom equals one claim.
- Use the frontmatter format above. Do not invent fields.
- Place atoms in the matching topic-branch. If no branch fits, list as deferred candidate; do not invent branches without user approval.
- Preserve the author's voice. Personal knowledge base, not neutral encyclopedia.
- Atoms are immutable once created.

### Compile

Take a set of related atoms and produce a wiki page synthesizing them.

Constraints:
- Group by topic, not one atom per page. Typical wiki page = 3–8 atoms.
- Filename `<branch>-<topic-slug>.md`, all lowercase, hyphens only.
- First line must be `# title`.
- Use `[[wiki-link]]` for cross-references. Slug inside `[[ ]]` must equal an existing wiki filename without `.md`.
- For temporal claims, use specific dates or version numbers.
- Footer lists source atoms by id.

If multiple agents compile in parallel: a coordinator pre-locks the slug list. Each agent fills assigned slugs, never names files.

### Query

User asks a question. You read `index.md` to locate relevant wiki pages, load only those (not the whole wiki), and answer based on them. If the answer requires synthesis worth retaining, propose writing it back as a new atom.

Constraints:
- Do not load the entire wiki by default. Use `index.md` to scope.
- Cite which pages you drew from.
- Distinguish "this is in the wiki" from "this is my synthesis on top of the wiki".

### Lint

Two layers, run in order:

**Programmatic Lint** (`scripts/lint.sh`) — runs first, no LLM needed. Checks ghost links, orphan pages, format violations, outdated markers. Output: `lint-report.md`.

**LLM Lint** — runs after programmatic Lint passes. Read `index.md` plus all wiki pages and check:
- **Contradictions** — page A says "X is best practice", page B says "X is deprecated". Flag both with paths and quoted segments.
- **Concept gaps** — multiple pages reference a concept that has no dedicated page. Propose as candidate.
- **Expired claims** — version numbers, dates, temporal markers in time-sensitive contexts. Verify or flag.
- **Weak orphans** — pages with weak conceptual link to the rest, even if technically linked.

Append findings to `lint-report.md` under an `## LLM Lint` section, sorted by severity (contradictions > concept gaps > expired claims > weak orphans).

---

## After every change

Run these in order:

```bash
./scripts/gen-index.sh                    # rebuild index
./scripts/log-append.sh "what you did"    # record change
```

Then if you compiled or modified wiki pages:

```bash
./scripts/lint.sh                         # programmatic Lint
```

If `lint.sh` reports errors (not just warnings), fix them before declaring done.

---

## Source attribution patterns

Three options for `source_ids`:

```yaml
# URL-based (public content)
source_ids: ["https://example.com/post/12345"]

# File-based (private materials)
source_ids: ["lectures/2026-04-12-skill-design.md"]

# Hash-based (when source stability matters)
source_ids: ["sha256:abc123..."]
```

Use hash IDs when you need to detect that a source was modified after extraction.

---

## What you must not do

- **Edit atoms after creation.** They are immutable. Create a new atom, archive the old one.
- **Write to `raw/`.** It is read-only from your perspective.
- **Invent branches without user approval.** Branch design has independence/scale/boundary criteria.
- **Use bold/italic to compensate for unclear writing.** If a sentence needs emphasis to be understood, rewrite the sentence.
- **Patch wiki pages to hide atom-layer problems.** If the wiki is wrong because an atom is wrong, fix the atom.
- **Compile in parallel without a slug lock.** You will produce naming collisions.
- **Treat the wiki as source of truth.** It is a derived cache. The atoms are truth.
- **Silently delete atoms or wiki pages.** Move to `_archive/`, never `rm`.

---

## Customizing for your domain

The defaults ship with reasonable opinionated choices. To adapt:

- **Add `source_type` values** for your sources (e.g. `email`, `slack`, `obsidian`).
- **Add `type` values** if your knowledge has categories beyond the seven defaults.
- **Adjust temporal regex** in `scripts/lint.sh` to match your conventions.
- **Define your own branch boundary table** in your fork's `STORY.md` or methodology notes.
- **Tune length thresholds** if your wiki style is denser or looser than 1500–2500 words.

Document any deviation — rules and scripts are coupled, divergence without documentation will confuse future contributors (including future-you).

---

## When in doubt

Defer to the user. This repo represents their knowledge, organized to their standards. Your job is to operate the pipeline reliably, not to make judgment calls about what their knowledge should look like. If something feels ambiguous, surface it instead of guessing.

---

*This schema corresponds to Karpathy's CLAUDE.md role in the original LLM Wiki gist, extended with the four optimizations this repo adds (atom layer, topic-branches, two-layer Lint, parallel-compile naming locks).*
