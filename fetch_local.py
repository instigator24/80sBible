#!/usr/bin/env python3
"""Fetch a WEB-translation book from a local eng-web.usfx.xml file into
review/<book>-NN.md templates, as an alternative to fetch.py's bible-api.com
calls (avoids rate limiting; same public-domain WEB text bible-api.com serves).

Download the source once with:
  curl -sL "https://raw.githubusercontent.com/seven1m/open-bibles/cf5da281ba9f92508e6cf8d950e031f2acb82335/eng-web.usfx.xml" -o eng-web.usfx.xml

Each passage is written with an empty **Draft:** line for a human (or an
assistant working alongside the author) to fill in with a 1980s-slang
paraphrase (the app's theme is 80s-styled throughout).
"""

import argparse
import os
import re

PASSAGE_SIZE = 4  # target verses per chunk (last chunk in a chapter may be smaller)


def load_book_xml(xml_path: str, book_id: str) -> str:
    with open(xml_path, "r", encoding="utf-8") as f:
        data = f.read()
    m = re.search(
        rf'<book id="{book_id}">(.*?)(?=<book id="|\Z)', data, re.DOTALL
    )
    if not m:
        raise ValueError(f"book id {book_id!r} not found in {xml_path}")
    return m.group(1)


def strip_inline_tags(text: str) -> str:
    # Drop footnote and cross-reference spans entirely.
    text = re.sub(r"<f\b[^>]*>.*?</f>", "", text, flags=re.DOTALL)
    text = re.sub(r"<x\b[^>]*>.*?</x>", "", text, flags=re.DOTALL)
    # Drop any remaining tags (paragraph markers, etc).
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def parse_chapters(book_xml: str) -> dict:
    """Return {chapter_num: [{"verse": n, "text": ...}, ...]}."""
    chapters = {}
    chapter_splits = re.split(r'<c id="(\d+)"/>', book_xml)
    # chapter_splits = [prefix, "1", chapter1_body, "2", chapter2_body, ...]
    for i in range(1, len(chapter_splits), 2):
        chapter_num = int(chapter_splits[i])
        body = chapter_splits[i + 1]
        verses = []
        verse_splits = re.split(r'<v id="(\d+)"/>', body)
        # verse_splits = [prefix, "1", verse1_body, "2", verse2_body, ...]
        for j in range(1, len(verse_splits), 2):
            verse_num = int(verse_splits[j])
            raw = verse_splits[j + 1]
            raw = raw.split("<ve/>")[0]
            text = strip_inline_tags(raw)
            if text:
                verses.append({"verse": verse_num, "text": text})
        chapters[chapter_num] = verses
    return chapters


def chunk_verses(verses: list) -> list:
    chunks = []
    for i in range(0, len(verses), PASSAGE_SIZE):
        chunks.append(verses[i:i + PASSAGE_SIZE])
    return chunks


def write_chapter_review(book_name: str, book_slug: str, chapter: int, verses: list) -> None:
    path = f"review/{book_slug}-{chapter:02d}.md"
    with open(path, "w", encoding="utf-8") as f:
        for chunk in chunk_verses(verses):
            verse_start = chunk[0]["verse"]
            verse_end = chunk[-1]["verse"]
            web_text = " ".join(v["text"].strip() for v in chunk)
            f.write(f"### {book_name} {chapter}:{verse_start}-{verse_end}\n")
            f.write(f"**WEB:** {web_text}\n")
            f.write("**Draft:** \n\n")
            f.write("---\n\n")
    print(f"wrote {path} ({len(verses)} verses)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--xml", type=str, default="eng-web.usfx.xml",
        help="Path to the local eng-web.usfx.xml file",
    )
    parser.add_argument(
        "--book-id", type=str, required=True,
        help="USFX book id, e.g. 'JAS', '1PE', '2JN', 'JUD'",
    )
    parser.add_argument(
        "--book-name", type=str, default=None,
        help="Display name for the book, e.g. '2 John' (default: --book-id)",
    )
    parser.add_argument(
        "--file-slug", type=str, default=None,
        help="Slug used in review/<slug>-NN.md filenames (default: --book-id lowercased)",
    )
    parser.add_argument(
        "--chapters", type=str, default=None,
        help="Comma-separated chapter numbers to process (default: all chapters in the book)",
    )
    args = parser.parse_args()

    book_name = args.book_name or args.book_id
    file_slug = args.file_slug or args.book_id.lower()

    os.makedirs("review", exist_ok=True)

    book_xml = load_book_xml(args.xml, args.book_id)
    chapters = parse_chapters(book_xml)

    chapter_nums = (
        [int(c) for c in args.chapters.split(",")]
        if args.chapters
        else sorted(chapters.keys())
    )

    for chapter in chapter_nums:
        print(f"Extracting {book_name} {chapter}...")
        write_chapter_review(book_name, file_slug, chapter, chapters[chapter])


if __name__ == "__main__":
    main()
