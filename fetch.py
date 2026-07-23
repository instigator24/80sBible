#!/usr/bin/env python3
"""Fetch a WEB-translation book from bible-api.com into review/<book>-NN.md
templates.

Each passage is written with an empty **Draft:** line for a human (or an
assistant working alongside the author) to fill in with a 1980s-slang
paraphrase (the app's theme is 80s-styled throughout).
"""

import argparse
import os

import requests

BIBLE_API_URL = (
    "https://bible-api.com/{book}+{chapter}"
    "?translation=web&single_chapter_book_matching=indifferent"
)
PASSAGE_SIZE = 4  # target verses per chunk (last chunk in a chapter may be smaller)


def fetch_chapter(book: str, chapter: int) -> list:
    """Fetch all verses in a chapter, returning a list of {"verse": n, "text": ...}.

    For single-chapter books (Obadiah, Philemon, 2 John, 3 John, Jude),
    bible-api.com's "book+chapter" shorthand is ambiguous between "chapter 1"
    and "verse 1" and defaults to verse 1 only. The
    single_chapter_book_matching=indifferent param (per bible-api.com's docs)
    makes it always return the whole chapter, avoiding that ambiguity for
    every book uniformly.
    """
    resp = requests.get(BIBLE_API_URL.format(book=book, chapter=chapter), timeout=30)
    resp.raise_for_status()
    data = resp.json()
    return data["verses"]


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
        "--book", type=str, default="john",
        help="bible-api.com book slug, e.g. 'john' or '3+john' (default: john)",
    )
    parser.add_argument(
        "--book-name", type=str, default=None,
        help="Display name for the book, e.g. '3 John' (default: --book, title-cased)",
    )
    parser.add_argument(
        "--file-slug", type=str, default=None,
        help="Slug used in review/<slug>-NN.md filenames (default: derived from --book)",
    )
    parser.add_argument(
        "--chapters", type=str, default="1",
        help="Comma-separated chapter numbers to process (default: 1)",
    )
    args = parser.parse_args()

    book_name = args.book_name or args.book.replace("+", " ").title()
    file_slug = args.file_slug or args.book.replace("+", "-").lower()
    chapters = [int(c) for c in args.chapters.split(",")]

    os.makedirs("review", exist_ok=True)

    for chapter in chapters:
        print(f"Fetching {book_name} {chapter}...")
        verses = fetch_chapter(args.book, chapter)
        write_chapter_review(book_name, file_slug, chapter, verses)


if __name__ == "__main__":
    main()
