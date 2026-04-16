# I ran Karpathy's LLM Wiki. Here's what I learned.

In 2025, Andrej Karpathy pushed out an idea: stop re-searching raw sources every time you query an AI. Pay the token cost once to compile your knowledge into a wiki, then just read the wiki from then on.

He wrote the pattern up as a gist. Ten-thousand-plus stars. But it's an idea file, not an implementation guide. He didn't walk the full path from raw material to finished artifact, and he didn't run the system long enough to hit maintenance problems.

I did.

🇹🇼 [中文原文](STORY.zh-TW.md)


## Scale

Input: 584 social posts, 8,668 replies, plus old lecture materials, course materials, and a pile of prior notes.

Filtered through an LLM against a specific ruleset, the output was 630-odd knowledge atoms — one claim per atom — grouped by topic into 11 branches, then compiled into 83 wiki pages.

Full procedure in METHODOLOGY.md.


## When Compile > RAG

Karpathy's claim is that knowledge should be a persistent, compounding artifact, not regenerated on every query. The claim holds, but only under specific conditions.

Volume under 200 wiki pages. Past that, the LLM loses efficiency scanning `index.md` and you need a real search mechanism alongside it.

Knowledge is relatively stable. You're organizing a cognitive map, not breaking news.

A single point of view. It's personal knowledge, not an aggregation of a hundred different voices.

Quality over coverage. 50 pages written tight beat 500 pages written shallow.

If your case doesn't meet these, RAG is probably the better fit. The two don't exclude each other — compile your stable core, RAG the long tail.


## Problems he didn't hit

Karpathy defined three maintenance operations: Ingest (add material), Query (look things up), Lint (health check). He never got to the point of actually handling the details.


### Lint's signal-to-noise

The first Lint version used a loose regex to catch temporal words — "currently", "latest", "now", "目前". Across 83 pages it produced 47 warnings.

Forty-odd of those were rhetorical uses inside prose, like "you used to need WSL, now you don't". Not stale claims — just how people write. Only 7 were actually worth a second look.

A report that's 85% noise gets opened three times, then ignored forever.

I tightened the pattern to only match temporal words paired with versions or dates — "as of 2025-06", "latest version", "just released". Warnings dropped to 16, every one a real dated claim worth verifying.

There's a deeper point here. Karpathy's wiki leans encyclopedic, so "avoid vague temporal words" is reasonable for him. But a conversational knowledge base will naturally use "now" and "currently" all the time. If you enforce the lint rule hard enough to convert every one of those into "as of 2026-04", the prose stops sounding like a person wrote it. Lint should match your writing style, not overwrite it.


### Parallel-compile naming collisions

Karpathy writes alone, one page at a time. No collisions.

Run 11 agents compiling in parallel and the same set of atoms gets two different filenames from two different agents — one calls it `mcp-plus-skills.md`, the other `mcp-plus-skills-architecture.md`.

Fix: pre-lock the slug list before fan-out. Agents fill assigned slugs with content; they don't name files. Any parallel-producer scenario needs namespace coordination up front.


### Programmatic Lint vs LLM Lint

Karpathy says Lint should catch contradictions, orphan pages, ghost links, and stale claims. He doesn't split which ones can be automated.

Ghost links, orphan pages, format violations — deterministic problems, handled by a shell script in seconds.

Contradiction detection and staleness judgment need semantic understanding. Those go to the LLM.

Run the script first so the LLM reads a clean document. Without the split, its attention gets eaten by format issues instead of the things actually worth judging.


## What came out of it

630+ scattered knowledge points became an 83-page cross-referenced wiki. Finding something is now reading the index. When I ask an AI to help write, I drop the relevant wiki pages in as context. Maintenance is incremental — no rebuild.

The bigger return wasn't the wiki itself. It was seeing my own knowledge map clearly once it was organized — where I thought I was solid but actually had gaps, where my views had gone stale without me noticing, where a topic I assumed mattered turned out to have little to say.


## Running it yourself

METHODOLOGY.md has the full procedure. Point an AI at it with your own materials and it can run.

`scripts/` has three scripts: `lint.sh` for health checks, `gen-index.sh` to rebuild the index, `log-append.sh` to append change entries.

---

Built on Andrej Karpathy's [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) pattern, iterated through real-world use.
