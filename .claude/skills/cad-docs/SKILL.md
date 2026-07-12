---
name: cad-docs
description: Search local CAD library documentation (BOSL2 wiki, build123d docs, fogleman/sdf README) with BM25. Use before writing code with an unfamiliar API, or after an API error, instead of guessing signatures.
allowed-tools:
  - Bash(*/docsearch.py*)
  - Read
---

# CAD Documentation Search (local doc-RAG)

BM25 keyword search over locally cloned documentation for the three CAD libraries used in this repo. Grounding API usage in real docs measurably reduces code errors — query it instead of guessing.

## When to Use

- **Before** using an API you haven't used in this session (exact parameter names, defaults, anchor semantics)
- **After** any API error or assertion — search the error's function name
- When choosing between similar functions (e.g. `position` vs `attach`, `extrude_to` vs `loft`)

## Usage

```bash
~/.venv-cad3d/bin/python .claude/skills/cad-docs/scripts/docsearch.py "<query>" [--lib bosl2|build123d|sdf] [-n 5]
```

Function names make the best queries:

```bash
docsearch.py "screw_hole counterbore teardrop" --lib bosl2
docsearch.py "fillet edges filter_by selector" --lib build123d
docsearch.py "smooth union blend k" --lib sdf
```

Output is the top-N doc chunks with source file and relevance score. Read them, then write the code.

## Corpus

Lives in `~/.cad-docs/` (index auto-rebuilds when files change; `--rebuild` forces it):

| Library | Source | Refresh |
|---------|--------|---------|
| bosl2 | `bosl2-wiki/` | `git -C ~/.cad-docs/bosl2-wiki pull` |
| build123d | `build123d-repo/docs/` | `git -C ~/.cad-docs/build123d-repo pull` |
| sdf | `sdf-README.md` | `curl -sL https://raw.githubusercontent.com/fogleman/sdf/main/README.md -o ~/.cad-docs/sdf-README.md` |

First-time setup on a new machine:

```bash
mkdir -p ~/.cad-docs && cd ~/.cad-docs
git clone --depth 1 https://github.com/BelfrySCAD/BOSL2.wiki.git bosl2-wiki
git clone --depth 1 --filter=blob:none --sparse https://github.com/gumyr/build123d.git build123d-repo
git -C build123d-repo sparse-checkout set docs
curl -sL https://raw.githubusercontent.com/fogleman/sdf/main/README.md -o sdf-README.md
```
