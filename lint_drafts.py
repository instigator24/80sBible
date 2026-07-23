#!/usr/bin/env python3
"""Automated QA pass over the compiled data/*.json slang drafts.

Checks for:
  - empty/missing slang_text
  - suspiciously short slang_text vs web_text (possible truncation bug)
  - banned 2020s-slang terms leaking into the 1980s-voice drafts
  - the excluded "oh my god" exclamation
  - per-book vocabulary frequency, to flag over-reliance on a tiny core
    rotation instead of the expanded 80s vocab list

Doesn't check subjective quality (that's a human/agent read-through job) —
this is meant to catch mechanical/objective issues fast, before a deeper
book-by-book review.
"""

import json
import re
from collections import Counter
from pathlib import Path

DATA_DIR = Path(__file__).parent / "data"

# 2020s/modern slang that shouldn't appear in a 1980s-voice paraphrase.
# Only terms that are unambiguous even as whole-word/whole-phrase matches —
# dropped "based", "on god", "mid", "sus" as standalone single words since
# they collide too often with ordinary English ("based on", "trust on God",
# "midday", "Jesus"/"discuss") even with word boundaries applied.
BANNED_TERMS = [
    "no cap", "lowkey", "highkey", "hits different", "stay woke",
    "rizz", "bussin", "cringe", "yeet", "slay", "goated", "simp",
    "delulu", "fr fr", "deadass", "spill the tea", "understood the assignment",
    "main character energy", "it's giving", "living rent free",
    "vibe check", "npc energy", "ratio'd", "glow up", "girlboss",
]

EXCLUDED_PHRASES = ["oh my god"]

# Distinctive core-rotation slang words the project's memory flags as
# over-used in the original (reset) drafts. Deliberately excludes
# structural/grammatical informality ("outta", "gonna", "'cause", "dude")
# since those are part of the voice's register throughout and used in
# nearly every sentence regardless of vocabulary variety — counting them
# would just measure sentence count, not word-choice repetition.
CORE_ROTATION = [
    "totally", "radical", " rad ", "bogus", "no way", "for real", "gnarly",
    "tubular", "psych", "chill", "grody", "as if", "way harsh",
]

EXPANDED_VOCAB = [
    "epic", "psychedelic", "bodacious", "choice", "fresh", "neato", "wicked",
    "hella", "gag me", "barf", "bite me", "what's your damage", "dipstick",
    "spaz", "wastoid", "couch potato", "zeek", "betty", "dudette", "trippin",
    "no duh", "chill pill", "bounce", "cowabunga", "don't have a cow",
    "like a boss", "party on", "talk to the hand", "get a clue",
    "i'm so sure", "oh snap", "righteous", "eat my shorts", "fer sure",
]


def load_book(path: Path) -> list:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def main() -> None:
    issues = []
    book_stats = {}

    for path in sorted(DATA_DIR.glob("*.json")):
        passages = load_book(path)
        book_name = path.stem
        core_hits = 0
        expanded_hits = 0
        total_words = 0

        for p in passages:
            ref = f"{p['book']} {p['chapter']}:{p['verse_start']}-{p['verse_end']}"
            slang = p.get("slang_text", "") or ""
            web = p.get("web_text", "") or ""
            lower = slang.lower()

            if not slang.strip():
                issues.append((book_name, ref, "EMPTY_DRAFT", ""))
                continue

            # Truncation check: draft dramatically shorter than source text
            # (the compile.py greedy-regex bug from project history).
            if len(slang) < 0.4 * len(web) and len(web) > 40:
                issues.append((
                    book_name, ref, "SUSPICIOUSLY_SHORT",
                    f"web={len(web)} chars, draft={len(slang)} chars"
                ))

            for term in BANNED_TERMS:
                if re.search(r"\b" + re.escape(term) + r"\b", lower):
                    issues.append((book_name, ref, "BANNED_MODERN_SLANG", term))

            for phrase in EXCLUDED_PHRASES:
                if re.search(r"\b" + re.escape(phrase) + r"\b", lower):
                    issues.append((book_name, ref, "EXCLUDED_PHRASE", phrase))

            total_words += len(slang.split())
            for term in CORE_ROTATION:
                core_hits += lower.count(term.strip())
            for term in EXPANDED_VOCAB:
                expanded_hits += lower.count(term)

        book_stats[book_name] = {
            "passages": len(passages),
            "total_words": total_words,
            "core_hits": core_hits,
            "expanded_hits": expanded_hits,
            "core_per_1k": round(core_hits / total_words * 1000, 1) if total_words else 0,
            "expanded_per_1k": round(expanded_hits / total_words * 1000, 1) if total_words else 0,
        }

    print("=" * 70)
    print("MECHANICAL ISSUES")
    print("=" * 70)
    if not issues:
        print("None found.")
    else:
        for book, ref, kind, detail in issues:
            print(f"[{kind}] {book} — {ref}" + (f" ({detail})" if detail else ""))

    print()
    print("=" * 70)
    print("VOCABULARY BALANCE (core rotation vs expanded list, per 1000 words)")
    print("=" * 70)
    print(f"{'book':<18} {'passages':>8} {'words':>7} {'core/1k':>8} {'expand/1k':>10} {'ratio':>7}")
    for book, stats in book_stats.items():
        ratio = (
            round(stats["core_hits"] / stats["expanded_hits"], 2)
            if stats["expanded_hits"] else float("inf")
        )
        print(
            f"{book:<18} {stats['passages']:>8} {stats['total_words']:>7} "
            f"{stats['core_per_1k']:>8} {stats['expanded_per_1k']:>10} {ratio:>7}"
        )

    print()
    print(f"Total issues found: {len(issues)}")


if __name__ == "__main__":
    main()
