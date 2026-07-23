#!/usr/bin/env python3
"""Parse top_50_bible_stories.md into data/stories.json."""

import argparse
import json
import re
import sys

ENTRY_RE = re.compile(
    r"^(?P<num>\d+)\.\s+\*\*(?P<title>.+?)\*\*\s+\((?P<reference>.+?)\)\s*\n"
    r"\s*-\s+(?P<summary>.+)$",
    re.MULTILINE,
)

SEGMENT_RE = re.compile(
    r"^(?:(?P<book>(?:[123]\s)?[A-Za-z]+(?:\s[A-Za-z]+)*)\s+)?"
    r"(?P<chapter_start>\d+):(?P<verse_start>\d+)"
    r"(?:\s*[-–]\s*(?:(?P<chapter_end>\d+):)?(?P<verse_end>\d+))?\s*$"
)


def parse_references(raw: str) -> list:
    """Split a reference string on ';' into one dict per range, inheriting
    the book name from the previous segment when a later segment omits it
    (e.g. "Genesis 25:19-34; 27:1-45" or "Job 1:1 - 2:13; 42:1-17")."""
    segments = [s.strip() for s in raw.split(";")]
    references = []
    current_book = None
    for seg in segments:
        match = SEGMENT_RE.match(seg)
        if not match:
            raise ValueError(f"unparseable reference segment: {seg!r} (from {raw!r})")
        book = match.group("book")
        if book:
            current_book = book
        elif current_book is None:
            raise ValueError(
                f"reference segment has no book and none to inherit: {seg!r} (from {raw!r})"
            )
        chapter_start = int(match.group("chapter_start"))
        verse_start = int(match.group("verse_start"))
        chapter_end_raw = match.group("chapter_end")
        chapter_end = int(chapter_end_raw) if chapter_end_raw else chapter_start
        verse_end_raw = match.group("verse_end")
        verse_end = int(verse_end_raw) if verse_end_raw else verse_start
        references.append({
            "book": current_book,
            "chapter_start": chapter_start,
            "verse_start": verse_start,
            "chapter_end": chapter_end,
            "verse_end": verse_end,
        })
    return references


def parse_stories(text: str) -> list:
    ot_match = re.search(
        r"## The Old Testament\n(.*?)\n## The New Testament", text, re.DOTALL
    )
    nt_match = re.search(
        r"## The New Testament\n(.*?)\n## Possible Next Steps", text, re.DOTALL
    )
    if not ot_match or not nt_match:
        raise ValueError("could not locate Old/New Testament sections")

    stories = []
    for testament, section in (("old", ot_match.group(1)), ("new", nt_match.group(1))):
        for match in ENTRY_RE.finditer(section):
            reference_display = match.group("reference").strip()
            stories.append({
                "id": int(match.group("num")),
                "testament": testament,
                "title": match.group("title").strip(),
                "reference_display": reference_display,
                "references": parse_references(reference_display),
                "summary": match.group("summary").strip(),
            })
    stories.sort(key=lambda s: s["id"])
    return stories


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="top_50_bible_stories.md")
    parser.add_argument("--output", default="data/stories.json")
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        text = f.read()

    stories = parse_stories(text)
    if len(stories) != 50:
        sys.exit(f"expected 50 stories, parsed {len(stories)}")

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(stories, f, indent=2, ensure_ascii=False)

    print(f"wrote {args.output} ({len(stories)} stories)")


if __name__ == "__main__":
    main()
