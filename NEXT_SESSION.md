# NT Slang Bible — Session Placeholder

**Last updated:** 2026-07-23

## Where things stand

**THE ENTIRE NEW TESTAMENT IS DONE.** All 27 books are fully drafted with the expanded 80s vocabulary, compiled, and wired into the app:

- John (21 ch), Matthew (28 ch), Mark (16 ch), Luke (24 ch), Acts (28 ch), Romans (16 ch), 1 Corinthians (16 ch), 2 Corinthians (13 ch), Galatians (6 ch), Ephesians (6 ch), Philippians (4 ch), Colossians (4 ch), 1 Thessalonians (5 ch), 2 Thessalonians (3 ch), 1 Timothy (6 ch), 2 Timothy (4 ch), Titus (3 ch), Philemon (1 ch), Hebrews (13 ch), James (5 ch), 1 Peter (5 ch), 2 Peter (3 ch), 1 John (5 ch), 2 John (1 ch), 3 John (1 ch), Jude (1 ch), Revelation (22 ch).

`flutter test` passes (85/85). Every book is in `kBookAssetPaths` in `app/lib/data/bible_books.dart`.

The last 3 books (3 John, Jude, Revelation) were drafted using 8 parallel subagents at the user's request, each given the full style guide (80s slang vocabulary list, anti-modern-slang rules, chapter-specific tone notes) directly in its prompt, plus an instruction to read `data/john.json` for voice calibration.

**A full proofreading pass is also now done (2026-07-23).** Process: wrote `lint_drafts.py` (mechanical QA — empty/truncated drafts, banned modern-slang leakage, vocabulary-balance ratio per book), ran it clean, then dispatched 27 parallel subagents (one per book) to closely read and fix every `review/<slug>-NN.md` file against faithfulness/voice/variety/correctness criteria. Recompiled everything afterward; `flutter test` still passes (85/85), `lint_drafts.py` still clean. See the `project-nt-slang-progress` memory for the detailed list of bugs found and fixed (a few real content bugs — dropped passages, duplicated paragraphs, an invented gendered phrase in Revelation — plus a systemic "too flat/formal, not enough actual slang words" issue in several epistles, and a serious one in Mark 14-15 where the crucifixion narrative had lost its slang voice entirely).

## Next step

**There's no more NT drafting or proofreading work queued up.** If you're picking this up in a new session, possible next steps:
- A second proofreading pass, or a narrower spot-check, if you want more confidence
- Old Testament drafting — a much bigger undertaking. `kAllBibleBooks` in `bible_books.dart` currently omits OT books on purpose (NT-first release); would need to re-add the OT book list there first
- Whatever the user asks for next

Don't assume more NT books remain without checking `kBookAssetPaths` against the full NT canon list first. `lint_drafts.py` in the project root can be rerun any time for a quick mechanical health check.

## Tooling notes (for reference)

**Fetching:** `fetch_local.py` reads WEB text straight out of a local `eng-web.usfx.xml` file (no bible-api.com calls, no rate-limit risk). This was the proven method for every book from James onward:
```
python3 fetch_local.py --book-id <3-letter USFX code> --book-name "<Name>" --file-slug <slug>
```
If `eng-web.usfx.xml` is missing from the project root, redownload it:
```
curl -sL "https://raw.githubusercontent.com/seven1m/open-bibles/cf5da281ba9f92508e6cf8d950e031f2acb82335/eng-web.usfx.xml" -o eng-web.usfx.xml
```
`fetch.py` (the original bible-api.com version) still works too, fixed on 2026-07-23 to pass `single_chapter_book_matching=indifferent` for single-chapter books.

**Drafting via subagents:** if delegating drafting to subagents in a future session (e.g., for OT books), give each subagent the full style guide inline in its prompt (see the reference-80s-slang-vocab and feedback-slang-style memories, or just copy from this session's subagent prompts) plus an instruction to Read `data/john.json` for calibration — subagents don't have access to this memory system.
1. `python3 fetch.py --book <slug> --book-name "<Name>" --chapters 1,2,3,...` to pull WEB text into `review/<slug>-NN.md` skeletons
2. Draft each chapter's `**Draft:**` lines with the expanded 80s slang vocabulary (see the `reference-80s-slang-vocab` memory) — vary word choice, don't lean on the same 5-6 terms, calibrate against `data/john.json` for voice
3. `python3 compile.py --book-name "<Name>" [--file-slug <slug>]` → `data/<slug>.json`
4. `cp data/<slug>.json app/assets/data/`
5. Add `'assets/data/<slug>.json'` to `kBookAssetPaths` in `app/lib/data/bible_books.dart`
6. `cd app && flutter test` to confirm
7. Rebuild/relaunch the app on the emulator if you want to see it live: `flutter run -d emulator-5554 --debug`

## Gotchas worth remembering

- **Rate limits:** bible-api.com throws 429s partway through a book — retry the failed chapter(s) in a background loop (`until ... do sleep 15; done`).
- **Subagent cap:** the session's 200-agent limit can be hit partway through a book — when that happens, just keep drafting directly with Read/Edit instead of spawning more agents.
- **compile.py regex:** the `slang_text` capture must stay greedy (`.+` with `re.DOTALL`, no trailing `\n` anchor) or multi-line drafts silently truncate to their first line. Already fixed — don't regress it if you touch compile.py.
- **Romans-style doxology quirk:** some books' WEB text from bible-api.com may place content in unexpected verse slots or leave a genuinely empty verse stub — if a `**WEB:**` line is truly empty, delete that section rather than inventing a paraphrase for it.
- **Flutter test lock:** if `flutter test` hangs with `Could not acquire the lock to .dart_tool/hooks_runner/shared/objective_c/.lock`, a stale process from an earlier turn is holding it — `ps aux | grep flutter`, kill it, then `rm -f app/.dart_tool/hooks_runner/shared/objective_c/.lock` and retry.
- **Old Testament is intentionally hidden** from the book picker (`kAllBibleBooks` in `bible_books.dart`) — the app releases NT-first. Don't re-add OT books without being asked.

## Full details

See the `project-nt-slang-progress` memory (auto-loaded each session) for the complete history, including why everything got reset once already (early drafts leaned on too small a slang vocabulary) — see also the `reference-80s-slang-vocab` and `feedback-slang-style` memories for the voice/vocabulary requirements.
