#!/usr/bin/env python3
"""Compile reviewed review/<book>-*.md files into data/<book>.json."""

import argparse
import glob
import json
import re
import sys


def entry_pattern(book_name: str) -> re.Pattern:
    return re.compile(
        rf"### {re.escape(book_name)} (?P<chapter>\d+):(?P<verse_start>\d+)-(?P<verse_end>\d+)\n"
        r"\*\*WEB:\*\* (?P<web_text>.+?)\n"
        r"\*\*Draft:\*\* (?P<slang_text>.+)",
        re.DOTALL,
    )


def parse_file(path: str, book_name: str, entry_re: re.Pattern) -> list:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    entries = []
    sections = content.split("---\n")
    for section in sections:
        section = section.strip()
        if not section:
            continue
        match = entry_re.match(section + "\n")
        if not match:
            raise ValueError(f"malformed entry in {path}:\n{section}")
        entries.append({
            "book": book_name,
            "chapter": int(match.group("chapter")),
            "verse_start": int(match.group("verse_start")),
            "verse_end": int(match.group("verse_end")),
            "web_text": match.group("web_text").strip(),
            "slang_text": match.group("slang_text").strip(),
        })
    return entries


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--book-name", type=str, default="John",
        help="Display name for the book, matching the '### <Name> C:V-V' headers (default: John)",
    )
    parser.add_argument(
        "--file-slug", type=str, default=None,
        help="Slug used in review/<slug>-NN.md filenames (default: derived from --book-name)",
    )
    args = parser.parse_args()

    book_name = args.book_name
    file_slug = args.file_slug or book_name.replace(" ", "-").lower()

    paths = sorted(glob.glob(f"review/{file_slug}-*.md"))
    if not paths:
        sys.exit(f"No review/{file_slug}-*.md files found.")

    entry_re = entry_pattern(book_name)
    all_entries = []
    for path in paths:
        all_entries.extend(parse_file(path, book_name, entry_re))

    out_path = f"data/{file_slug}.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(all_entries, f, indent=2, ensure_ascii=False)

    print(f"wrote {out_path} ({len(all_entries)} passages from {len(paths)} files)")


if __name__ == "__main__":
    main()
