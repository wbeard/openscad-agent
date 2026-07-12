#!/usr/bin/env python3
"""BM25 search over local CAD documentation (BOSL2 wiki, build123d docs, fogleman/sdf).

Run with the CAD venv python: ~/.venv-cad3d/bin/python docsearch.py "query"

Usage:
  docsearch.py "fillet edges of a box" [--lib build123d] [-n 5] [--rebuild]

Libraries: bosl2 | build123d | sdf | all (default)
Corpus root: ~/.cad-docs (see --corpus). Index is cached and auto-rebuilt
when the corpus changes.
"""

import argparse
import os
import pickle
import re
import sys

CORPUS_DEFAULT = os.path.expanduser("~/.cad-docs")

SOURCES = {
    "bosl2": "bosl2-wiki",
    "build123d": "build123d-repo/docs",
    "sdf": "sdf-README.md",
}

TOKEN_RE = re.compile(r"[a-zA-Z_$][a-zA-Z0-9_]*|\d+")
HEADING_RE = re.compile(r"^(#{1,4} .+|[^\s].{0,120}\n[=~^\-]{3,}\s*)$", re.M)
MAX_CHUNK_CHARS = 3000


def tokenize(text):
    return [t.lower() for t in TOKEN_RE.findall(text)]


def chunk_file(path, lib):
    """Split a doc file into heading-delimited chunks (subsplit if huge)."""
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return []
    positions = [m.start() for m in HEADING_RE.finditer(text)] or [0]
    if positions[0] != 0:
        positions.insert(0, 0)
    positions.append(len(text))
    chunks = []
    for start, end in zip(positions, positions[1:]):
        section = text[start:end].strip()
        if len(section) < 40:
            continue
        title = section.splitlines()[0].strip("# ").strip()
        for i in range(0, len(section), MAX_CHUNK_CHARS):
            part = section[i:i + MAX_CHUNK_CHARS]
            chunks.append({"lib": lib, "path": path, "title": title, "text": part})
    return chunks


def collect_chunks(corpus):
    chunks = []
    for lib, rel in SOURCES.items():
        root = os.path.join(corpus, rel)
        if os.path.isfile(root):
            chunks.extend(chunk_file(root, lib))
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if not d.startswith((".", "_"))]
            for fn in sorted(filenames):
                if fn.endswith((".md", ".rst", ".txt")):
                    chunks.extend(chunk_file(os.path.join(dirpath, fn), lib))
    return chunks


def corpus_fingerprint(corpus):
    total = 0
    for lib, rel in SOURCES.items():
        root = os.path.join(corpus, rel)
        if os.path.isfile(root):
            total += os.path.getmtime(root) + os.path.getsize(root)
        elif os.path.isdir(root):
            for dirpath, dirnames, filenames in os.walk(root):
                dirnames[:] = [d for d in dirnames if not d.startswith((".", "_"))]
                for fn in filenames:
                    p = os.path.join(dirpath, fn)
                    total += os.path.getsize(p)
    return int(total)


def load_index(corpus, rebuild=False):
    from rank_bm25 import BM25Okapi
    cache = os.path.join(corpus, ".docsearch-index.pkl")
    fp = corpus_fingerprint(corpus)
    if not rebuild and os.path.exists(cache):
        try:
            with open(cache, "rb") as f:
                data = pickle.load(f)
            if data.get("fingerprint") == fp:
                return data["chunks"], data["bm25"]
        except Exception:
            pass
    chunks = collect_chunks(corpus)
    if not chunks:
        sys.exit(f"No documentation found under {corpus}. See cad-docs SKILL.md for corpus setup.")
    bm25 = BM25Okapi([tokenize(c["title"] + "\n" + c["text"]) for c in chunks])
    with open(cache, "wb") as f:
        pickle.dump({"fingerprint": fp, "chunks": chunks, "bm25": bm25}, f)
    return chunks, bm25


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("query")
    ap.add_argument("--lib", default="all", choices=["all", *SOURCES])
    ap.add_argument("-n", type=int, default=5, help="number of results (default 5)")
    ap.add_argument("--corpus", default=CORPUS_DEFAULT)
    ap.add_argument("--rebuild", action="store_true", help="force index rebuild")
    args = ap.parse_args()

    chunks, bm25 = load_index(args.corpus, args.rebuild)
    scores = bm25.get_scores(tokenize(args.query))
    ranked = sorted(range(len(chunks)), key=lambda i: -scores[i])

    shown = 0
    for i in ranked:
        c = chunks[i]
        if args.lib != "all" and c["lib"] != args.lib:
            continue
        if scores[i] <= 0:
            break
        rel = os.path.relpath(c["path"], args.corpus)
        print(f"═══ [{c['lib']}] {c['title']}  ({rel}, score {scores[i]:.1f}) ═══")
        print(c["text"].strip()[:2500])
        print()
        shown += 1
        if shown >= args.n:
            break
    if shown == 0:
        print("No matches. Try different keywords (function names work best).")


if __name__ == "__main__":
    main()
