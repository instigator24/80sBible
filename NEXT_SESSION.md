# NT Slang Bible — Session Placeholder

**Last updated:** 2026-07-22

## Where things stand

Drafting a 1980s-slang paraphrase of the New Testament (WEB translation as source), for a Flutter app themed around 80s aesthetics.

**Done** — fully drafted with the expanded 80s vocabulary, compiled, and wired into the app:
- John (21 ch)
- Matthew (28 ch)
- Mark (16 ch)
- Luke (24 ch)
- Acts (28 ch)
- Romans (16 ch)
- 1 Corinthians (16 ch)
- 2 Corinthians (13 ch)
- Galatians (6 ch)
- Ephesians (6 ch)
- Philippians (4 ch)

**Not done** — needs drafting from scratch:
- Colossians, 1-2 Thessalonians, 1-2 Timothy, Titus, Philemon, Hebrews, James, 1-2 Peter, 1-2 John, Jude, Revelation
- 3 John was drafted once in an earlier pass but deleted during the vocabulary reset — needs to be redone too

## Next step

Continue with **Colossians** (or whichever book you want next), using the same pipeline:
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
