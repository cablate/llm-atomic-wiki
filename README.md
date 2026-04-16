# llm-atomic-wiki

> Built on top of **Andrej Karpathy's [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)**.
> All credit to him for the pattern — this repo is what I learned by running it end-to-end, plus four small additions that helped at scale.

**584 posts · 8,668 replies · 630 atoms · 83 wiki pages · 11 branches**

The repo gives you the framework — methodology, schema, scripts, folder structure. Fork it and run it on your own materials. My actual content stays private; the kit is what you get.

🇹🇼 [中文版 README](README.zh-TW.md) · 📖 [the story behind this repo](STORY.md)

---

## What this adds on top of Karpathy's pattern

Karpathy's gist captures the core pattern in beautifully minimal form. The four additions below came from problems I hit while running it at scale — they extend his pattern, they don't replace it.

```
Karpathy:   raw ─→ wiki
This repo:  raw ─→ atoms (organized into topic-branches) ─→ wiki
```

Four additions:

**1. Atom layer.** Karpathy goes raw → wiki in one compile step. I added atoms in between — one atom equals one claim, with frontmatter (source, type, depth, tags, date). Atoms are the source of truth; wiki is a derived cache. When a wiki page gets a fact wrong, you go back to the atom, not the raw source. This solves the "loss of information" and "false sense of source of truth" problems that commenter `frosk1` raised on the original gist.

**2. Topic-branches at the atom layer.** Karpathy's wiki is flat. I organize atoms by topic into branch folders at the repo root (one folder per branch), then compile to flat wiki pages with topic prefixes (`wiki/<branch>-<subtopic>.md`). The atom layer becomes browsable; the wiki layer stays index-friendly.

**3. Two-layer Lint.** Karpathy lumps "find contradictions, ghost links, orphan pages, outdated claims" into a single Lint operation. I split it. A programmatic layer (`scripts/lint.sh`) handles deterministic checks (ghost links, orphan pages, format violations, outdated markers) in seconds. An LLM layer handles semantic checks (contradictions, expired claims). The programmatic layer runs first so the LLM doesn't waste attention on format issues.

**4. Parallel-compile naming lock.** Karpathy compiles one page at a time. When N agents compile in parallel, they invent different filenames for the same content (`mcp-plus-skills.md` vs `mcp-plus-skills-architecture.md`). The fix is to pre-lock the slug namespace before fanning out. Agents fill content into pre-named slots; they do not name files.

---

## Proof

| Stage | Numbers |
|-------|---------|
| Raw input | 584 posts + 8,668 replies + lecture/course materials |
| Filter pass-through | Posts 70–90% kept, replies ~13% kept (87% noise) |
| Atoms extracted | 630 (immutable, source of truth) |
| Branches | 11 (one folder at repo root per topic) |
| Wiki pages compiled | 83 (3–8 atoms per page) |
| Lint warnings (tightened) | 16 (down from 47 before regex was tightened) |
| Largest branch | 101 atoms |
| Smallest branch | 23 atoms |

---

## How it works

```
┌─────────┐  Ingest    ┌────────────┐  Compile   ┌─────────┐
│  raw/   │ ─────────▶ │ <branch>/  │ ─────────▶ │  wiki/  │
│         │  (LLM      │ atom.md    │  (LLM      │ flat    │
│ sources │  extract)  │ atom.md    │  group)    │ pages   │
└─────────┘            │ ...        │            └────┬────┘
                       └────────────┘                 │
                                                      │
                                ┌─────────────────────┼─────────────────────┐
                                ▼                     ▼                     ▼
                          gen-index.sh           lint.sh              log-append.sh
                              │                     │                     │
                              ▼                     ▼                     ▼
                          index.md           lint-report.md            log.md
```

Compare to Karpathy's loop:

```
Karpathy:   raw → wiki → {Ingest, Query, Lint}
This repo:  raw → atoms → wiki → {Ingest, Query, programmatic Lint, LLM Lint}
```

Atoms are where the real work happens. Wiki is rebuildable from atoms; atoms are not rebuildable from wiki.

---

## What's in this repo

```
llm-atomic-wiki/
├── README.md              ← you are here
├── README.zh-TW.md        ← Chinese version
├── STORY.md / STORY.zh-TW.md  ← the personal story, bilingual
├── METHODOLOGY.md         ← 6-phase pipeline (English)
├── METHODOLOGY.zh-TW.md   ← original Chinese methodology
├── CLAUDE.md              ← schema for the LLM operating this repo
├── LICENSE
│
├── raw/                   ← drop your source materials here (gitignored)
│
├── <branch-1>/            ← one folder per topic-branch, atoms inside (gitignored)
├── <branch-2>/            ← e.g. ai-agent/, ai-skills/, mcp/, ...
├── ...
│
├── wiki/                  ← compiled pages, flat (gitignored)
│
├── index.md               ← auto-generated navigation (gitignored)
├── log.md                 ← change log, append-only (gitignored)
│
├── templates/
│   ├── atom.md            ← copy when creating a new atom
│   └── wiki-page.md       ← copy when creating a new wiki page
│
└── scripts/
    ├── lint.sh            ← programmatic Lint
    ├── gen-index.sh       ← rebuild index.md from wiki/
    ├── log-append.sh      ← append a change entry to log.md
    └── README.md
```

The framework files (READMEs, METHODOLOGY, CLAUDE, scripts, templates) are versioned. Your actual content (raw, branch folders, wiki, generated index/log) is gitignored — this is intentional and load-bearing. The repo is the kit, not the data.

---

## Quickstart

1. **Fork this repo.**
2. **Read `METHODOLOGY.md`** — six phases from raw to wiki, plus the maintenance loop.
3. **Read `CLAUDE.md`** — the formal spec (atom format, wiki format, branch rules, operations, what not to do).
4. **Edit `.gitignore`** — replace the listed branch names with your own.
5. **Drop materials into `raw/`** — any text format. PDFs, transcripts, post dumps, articles.
6. **Drive the pipeline with an LLM** — point Claude Code (or your agent) at `CLAUDE.md` and ask it to ingest a batch.
7. **Run the scripts** after each compile:
   ```bash
   ./scripts/gen-index.sh        # rebuild wiki index
   ./scripts/lint.sh             # programmatic health check
   ./scripts/log-append.sh "..." # record what changed
   ```
8. **Run an LLM Lint pass** weekly or after major ingests — see `METHODOLOGY.md`.

The whole loop is `Ingest → Compile → Index/Log → Lint → Query`. Re-run as you accumulate materials.

---

## Deep dives

- **[STORY.md](STORY.md)** — the personal story: why I ran it, what worked, what surprised me.
- **[METHODOLOGY.md](METHODOLOGY.md)** — the six-phase pipeline (skeleton → segment-classify → extract → quality pass → external check → wiki compile) and the three maintenance operations.
- **[METHODOLOGY.zh-TW.md](METHODOLOGY.zh-TW.md)** — the original Chinese methodology document, longer-form.
- **[CLAUDE.md](CLAUDE.md)** — the formal spec for any LLM operating this repo.

---

## Why this matters (and when it doesn't)

Karpathy's thesis is that knowledge should be a persistent, compounded artifact — not regenerated from raw sources on every query. Compile beats RAG, in his framing. I agree, but with conditions:

- **Knowledge volume under ~200 wiki pages.** Past that, index.md scans degrade and you need vector search alongside.
- **Knowledge is relatively stable.** This is a cognitive map, not breaking news. Update cadence in days/weeks, not minutes.
- **There's a single owner with a point of view.** Personal knowledge, not a hundred-author aggregation.
- **Quality matters more than coverage.** 50 pages written tight beat 500 pages written shallow.

Outside these conditions, RAG is often the better fit. The two are not exclusive — compile your stable core, RAG your long tail.

A frame that I think gets undersold: Karpathy's real contribution isn't wiki quality. It's that **LLMs don't get bored maintaining the wiki**. The bookkeeping tax that kills most personal knowledge systems is the maintenance, not the structure. LLMs change the cost structure of maintenance — and that's the unlock the gist points at, more than any specific format choice.

---

## Credit & License

The pattern, the schema, the operations (Ingest / Query / Lint), the philosophy of compile-over-retrieve — all that is **[Andrej Karpathy's](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)**. If you find this repo useful, his gist is the thing to read first.

This repo is MIT-licensed — see [LICENSE](LICENSE) — and consists of:
- Four small additions to Karpathy's pattern (atom layer, topic-branches, two-layer Lint, parallel-compile lock)
- A reference implementation methodology
- A bilingual README and a story doc

If you fork it and find it useful, a star on Karpathy's original gist is more deserved than one on this repo.
