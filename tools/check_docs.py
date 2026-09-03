#!/usr/bin/env python3
"""check_docs.py — validate the docs/ MDX tree.

Read-only. Checks, for every docs/**/*.mdx:
  • YAML-ish frontmatter exists and has title + description
  • every relative markdown link [..](..) resolves on disk (anchors/URLs skipped)

Usage:  python3 tools/check_docs.py
Exit 0 if clean, 1 if any problems.
"""
from __future__ import annotations
import os, re, sys
from urllib.parse import unquote

# Windows pipes default to cp1252, which cannot encode the ✓/✗ glyphs below -
# the check would pass and then die on its own success message.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "docs")
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")

problems: list[str] = []
n_files = n_links = 0

for dirpath, _, files in os.walk(DOCS):
    for fn in files:
        if not fn.endswith(".mdx"):
            continue
        n_files += 1
        path = os.path.join(dirpath, fn)
        rel = os.path.relpath(path, ROOT)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()

        # frontmatter
        if not text.startswith("---"):
            problems.append(f"{rel}: missing frontmatter")
        else:
            fm = text.split("---", 2)[1]
            for key in ("title:", "description:"):
                if key not in fm:
                    problems.append(f"{rel}: frontmatter missing {key}")

        # links
        for target in LINK.findall(text):
            t = target.strip()
            if t.startswith(("http://", "https://", "#", "mailto:")):
                continue
            t = unquote(t.split("#", 1)[0])
            if not t:
                continue
            n_links += 1
            resolved = os.path.normpath(os.path.join(dirpath, t))
            if not os.path.exists(resolved):
                problems.append(f"{rel}: broken link -> {target}")

print(f"checked {n_files} .mdx files, {n_links} internal links")
if problems:
    print(f"\n{len(problems)} problem(s):")
    for p in problems:
        print("  ✗", p)
    sys.exit(1)
print("✓ all good")
