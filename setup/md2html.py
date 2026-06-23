#!/usr/bin/env python3
"""md2html.py — minimal, dependency-free Markdown -> HTML fragment.

Scoped to the constructs used in docs/keybindings-cheatsheet.mdx:
YAML frontmatter strip, ATX headings, --- hr, GFM pipe tables, fenced code,
blockquotes, paragraphs, and inline code/bold/links. Not a general converter.
Reads stdin, writes stdout.
"""
import html
import re
import sys

INLINE_CODE = re.compile(r"`([^`]+)`")
BOLD = re.compile(r"\*\*([^*]+)\*\*")
LINK = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")


def inline(text: str) -> str:
    # Protect code spans from other substitutions.
    spans: list[str] = []

    def stash(m: re.Match) -> str:
        spans.append("<code>" + html.escape(m.group(1)) + "</code>")
        return f"\x00{len(spans) - 1}\x00"

    text = INLINE_CODE.sub(stash, text)
    text = html.escape(text)
    text = BOLD.sub(r"<strong>\1</strong>", text)
    text = LINK.sub(r'<a href="\2">\1</a>', text)
    text = re.sub(r"\x00(\d+)\x00", lambda m: spans[int(m.group(1))], text)
    return text


def split_row(line: str) -> list[str]:
    line = line.strip().strip("|")
    return [c.strip() for c in line.split("|")]


def main() -> None:
    src = sys.stdin.read().split("\n")
    # Strip YAML frontmatter.
    if src and src[0].strip() == "---":
        end = next((i for i in range(1, len(src)) if src[i].strip() == "---"), -1)
        if end != -1:
            src = src[end + 1:]

    out: list[str] = []
    i, n = 0, len(src)
    while i < n:
        line = src[i]
        stripped = line.strip()

        if stripped.startswith("```"):
            i += 1
            code: list[str] = []
            while i < n and not src[i].strip().startswith("```"):
                code.append(html.escape(src[i]))
                i += 1
            i += 1
            out.append("<pre><code>" + "\n".join(code) + "</code></pre>")
            continue

        if re.fullmatch(r"-{3,}", stripped):
            out.append("<hr>")
            i += 1
            continue

        m = re.match(r"(#{1,6})\s+(.*)", stripped)
        if m:
            lvl = len(m.group(1))
            out.append(f"<h{lvl}>{inline(m.group(2))}</h{lvl}>")
            i += 1
            continue

        # GFM table: header row, separator row of ---|---, then body.
        if "|" in line and i + 1 < n and re.match(r"^\s*\|?[\s:|-]+\|[\s:|-]+$", src[i + 1]):
            header = split_row(line)
            i += 2
            rows: list[list[str]] = []
            while i < n and "|" in src[i] and src[i].strip():
                rows.append(split_row(src[i]))
                i += 1
            t = ["<table><thead><tr>"]
            t += [f"<th>{inline(c)}</th>" for c in header]
            t.append("</tr></thead><tbody>")
            for r in rows:
                t.append("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>")
            t.append("</tbody></table>")
            out.append("".join(t))
            continue

        if stripped.startswith(">"):
            quote: list[str] = []
            while i < n and src[i].strip().startswith(">"):
                quote.append(src[i].strip()[1:].strip())
                i += 1
            out.append("<blockquote>" + inline(" ".join(quote)) + "</blockquote>")
            continue

        if stripped == "":
            i += 1
            continue

        # Paragraph: gather until blank / block boundary.
        para: list[str] = []
        while i < n and src[i].strip() and not re.match(r"\s*(#|>|```|-{3,}$)", src[i]):
            if "|" in src[i] and i + 1 < n and re.match(r"^\s*\|?[\s:|-]+\|[\s:|-]+$", src[i + 1]):
                break
            para.append(src[i].strip())
            i += 1
        if para:
            out.append("<p>" + inline(" ".join(para)) + "</p>")
        else:
            i += 1

    sys.stdout.write("\n".join(out))


if __name__ == "__main__":
    main()
