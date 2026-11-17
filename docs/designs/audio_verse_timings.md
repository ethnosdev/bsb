# Audio Verse Timings: Design & Implementation Plan

Status: **Implemented and verified** (2026-11-17).
Audience: agents/developers implementing the feature. This document is self-contained.

---

## 1. Goal

Use per-verse audio timings for the Souer BSB narration to:

1. Highlight the verse currently being read and auto-scroll to it.
2. Let the user start audio at a selected verse ("Play").
3. Show the live verse reference (e.g. `John 10:14`) in the player UI and lock screen.
4. Add previous/next **verse** buttons to the expanded player.
5. Add a **Repeat Verse** play mode (loop the current verse, for memorization).

Timings are **bundled in the app's SQLite database**. They are not downloaded at runtime.

### Out of scope (explicitly rejected or deferred)

- Clipping playlist passages to their verse range.
- Verse tick marks on the progress bar (too dense, e.g. Psalm 119 has 176 verses).
- Looping a multi-verse range (only single-verse looping via the play mode).
- Multiple narrators (Souer only, though the schema can be extended later with a DB version bump).
- Server-hosted or over-the-air timing updates. A timing fix ships with an app release.
- A separate "Highlight current verse" setting.

---

## 2. Background: Current State of the Code

| Area | File | Notes |
|---|---|---|
| Audio URL | [audio_url_resolver.dart](../../flutter_app/lib/infrastructure/audio/audio_url_resolver.dart) | Streams `https://bsb.ethnos.dev/audio/souer/BSB_43_Jhn_010.mp3`. Holds `bookIdToSouerPrefix`. |
| Audio handler | [bsb_audio_handler.dart](../../flutter_app/lib/infrastructure/audio/bsb_audio_handler.dart) | `audio_service` handler wrapping `just_audio`. Owns `playMode`, `stopAtEndOfChapter`, `currentBookId/currentChapter`. Builds `MediaItem(title, album, extras: {bookId, chapter})`. Notification controls: skipToPrevious, rewind, play/pause, fastForward, skipToNext. |
| Playback manager | [audio_playback_manager.dart](../../flutter_app/lib/infrastructure/audio/audio_playback_manager.dart) | UI-facing notifiers (`speedNotifier`, `playModeNotifier`, `syncTextNotifier`, …). Listens to `mediaItem` and calls `onChapterChanged` when Sync Text is on. Saves position every 5 s. |
| Models | [audio_models.dart](../../flutter_app/lib/infrastructure/audio/audio_models.dart) | `AudioPlayMode { continuous, repeatChapter, stopAfterChapter }` with storage strings, and `SleepTimerOption`. |
| Player UI | [audio_player_bottom_bar.dart](../../flutter_app/lib/ui/audio/audio_player_bottom_bar.dart), [audio_player_modal_sheet.dart](../../flutter_app/lib/ui/audio/audio_player_modal_sheet.dart) | Bottom bar shows `mediaItem.title`. Expanded sheet has the Sync Text toggle, progress bar (`audio_video_progress_bar`), chapter skip, ±10 s buttons, and speed/sleep/play-mode chips. |
| Chapter text | [chapter_text.dart](../../flutter_app/lib/ui/text/chapter/chapter_text.dart) | Renders `UsfmWidget` (from the sibling `scripture` package) with `highlights: List<HighlightRange>`. Already has `_scrollToTargetVerse`, the `VerseScrubber` overlay, and user-drag detection via `ScrollStartNotification.dragDetails`. |
| Selection menu | [text_screen.dart](../../flutter_app/lib/ui/text/text_screen.dart) | Selection bar: Highlight / Note / Copy / Hebrew-Greek / More. `_handleMore` shows a popup with `compare`, `cross_reference`, `add_to_playlist`, `memorize`. |
| DB (app) | [database.dart](../../flutter_app/lib/infrastructure/database.dart) | Copies `assets/database/database.db` on first run. If `_databaseVersion` (currently **31**) differs from the installed DB, the app deletes the installed DB and re-copies it. `_chapterBounds(bookId, chapter)` gives packed reference bounds. |
| DB builder | [create_database.dart](../../database_builder/lib/src/create_database.dart), [schema.dart](../../database_builder/lib/src/schema.dart) | Builds tables in order: bible → verses_search → foreign → interlinear → lexicon → indexes. Vendored sources live in `database_builder/bsb_usfm/`, `bsb_tables/`, `lexicon/`. |
| `HighlightRange` | `../scripture/lib/src/flutter/paragraph.dart` | `{int startId, int endId, Color color}`: background fill only. Word IDs are packed `BBCCCVVVWWW`. |

Packed verse reference format everywhere: `BBCCCVVV` as an int (e.g. John 10:14 = `43010014`).

DB build/install procedure (from [getting_started.md](../getting_started.md) and [howto_update_bsb_text.md](../howto_update_bsb_text.md)):
`cd database_builder && dart run bin/main.dart && cp database.db ../flutter_app/assets/database/database.db`, then bump `_databaseVersion`.

---

## 3. Source Data: Isochron Exports

Location (outside this repo):
`/Users/suragch/Dev/ethnosdev/isochron/isochron_projects/BSB/Souer/exported_timings/{OT,NT}/`

- 1,189 files (929 OT + 260 NT), one per chapter, named `BSB_<BB>_<Abc>_<CCC>_timing.txt` (e.g. `BSB_43_Jhn_010_timing.txt`). The folders also contain `.DS_Store`, which must be ignored.
- Format (tab-separated, times in **seconds** with up to 3 decimals):

```text
\id Jhn
\c 010
\level phrase
4.7	12.95	43010001
12.95	16.69	43010002
...
266.77	271.656	43010042
```

- `\level phrase` appears in every file, but **every row is exactly one whole verse**.
- 31,086 rows in total, an exact 1-to-1 match with the 31,086 distinct verse references in `bible` (`reference % 1000 > 0`), with zero duplicates.
- Rows within a chapter are contiguous (`|end_ms[i] − start_ms[i+1]| <= 1 ms`) with strictly increasing verse numbers and positive durations (`start_ms < end_ms`).
- Audio before the first row's start (about 3.5–5 s) is the spoken chapter announcement (e.g. "John chapter 10").
- The Isochron project setting `boundaryLeadInMs: 190` is **already applied** to the exported start times. Use the times as-is, with no extra pre-roll in the app.
- Size: 714 KB raw, 233 KB gzipped, roughly 0.4 MB as a SQLite table (the existing DB is 66 MB).
- Tolerate CRLF line endings and blank lines when parsing.

### ✅ Resolved Isochron export bugs (fixed & re-exported 2026-11-17)

Three issues in the initial export were investigated and fixed at the source before re-exporting:

1. **Numbered-book chapter IDs (214 files):** `IdGenerator.extractBookAndChapter` in Isochron previously used `RegExp(r'\d+')` across the track stem, mistaking the leading digit of `1Sa`, `2Ki`, `3Jn`, etc. for the chapter number. Fixed in `isochron_app` (`2.1.2`, commit `6878c77`) by tokenizing stems before parsing book/chapter tokens.
2. **Omitted verse numbers shifting IDs (15 NT chapters):** `IdGenerator.generateId` assumes `verseNum = lineIndex + 1`, which shifted IDs after omitted verses in 15 NT chapters (e.g. Matthew 17:21, Mark 9:44/46). Fixed in the `Souer` Isochron project by prepending exact `BBCCCVVV\t` IDs from `database.db` to all 1,189 `collections/{OT,NT}/text/*.txt` files, setting `"defaultHasIds": true` in `project.json`, and updating 5,965 `id` fields across the 229 affected `collections/*/alignments/*_timing.json` files.
3. **Unaligned verse in Exodus 16:2:** Exodus 16:2 had `-1	-1	02016002`. The verse was aligned in Isochron (`15.769`–`19.64`), and Isochron `2.1.2` now warns at export time and omits unaligned rows if forced.

**Re-export verification (2026-11-17):** Checked all 1,189 re-exported files (`31,086` rows) against `flutter_app/assets/database/database.db` using all 9 rules from §4.3 — **0 errors, 0 duplicates, 0 missing or extra verses, and contiguous timings throughout**. Keep the strict validator in §4.3 in place anyway so future re-exports are always guarded.

---

## 4. Data Pipeline (database_builder)

### 4.1 Vendored source

Copy the **re-exported, corrected** files into this repo and commit them:

```text
database_builder/audio_timings/souer/OT/BSB_01_Gen_001_timing.txt
...
database_builder/audio_timings/souer/NT/BSB_66_Rev_022_timing.txt
```

Exclude `.DS_Store`. After any future re-export, re-copy the files, rebuild the DB, and bump `_databaseVersion`.

### 4.2 Schema

Add to [schema.dart](../../database_builder/lib/src/schema.dart):

```sql
CREATE TABLE IF NOT EXISTS audio_timings (
  reference INTEGER PRIMARY KEY,   -- BBCCCVVV
  start_ms  INTEGER NOT NULL,
  end_ms    INTEGER NOT NULL
)
```

- Convert with `(seconds * 1000).round()`.
- No separate index is needed, since `reference` is the rowid key and chapter queries use `reference >= ? AND reference < ?`.
- Narrator column: intentionally omitted (Souer only). Adding one later is a schema change plus a DB version bump.

### 4.3 Builder step + strict validation

New file `database_builder/lib/src/audio_timings_table.dart`, called from `createDatabase()` **after** `createBsbTable` (validation needs the `bible` table).

The build **must fail** (throw, after collecting **all** violations and printing them) if any of the following is true:

1. A filename doesn't match `BSB_(\d\d)_(\w{3})_(\d{3})_timing\.txt`.
2. The `\id` value ≠ the filename abbreviation, or the `\c` value ≠ the filename chapter.
3. A row's ID book/chapter (`ref ~/ 1000`) ≠ the file's book/chapter.
4. A reference appears more than once (globally).
5. Within a chapter, verse numbers aren't strictly increasing.
6. A row has `start_ms >= end_ms` or `start_ms < 0`.
7. Within a chapter, rows aren't contiguous: `|end_ms[i] − start_ms[i+1]| > 1` (allow 1 ms for rounding).
8. The set of timing references ≠ the set of `SELECT DISTINCT reference FROM bible WHERE reference % 1000 > 0`. Report both directions: missing timings and timings for nonexistent verses.
9. The file count ≠ 1,189.

If run against a bad export (such as the earlier unpatched export with wrong chapter IDs and duplicates), this validator must fail on rules 3 and 4; that makes a good test fixture.

### 4.4 App DB version

After rebuilding and copying the DB, bump `_databaseVersion` in [database.dart](../../flutter_app/lib/infrastructure/database.dart) (31 → 32, or whatever is next at implementation time).

---

## 5. App Data Layer

### 5.1 Query

In [database.dart](../../flutter_app/lib/infrastructure/database.dart):

```dart
Future<ChapterTimings> getChapterTimings(int bookId, int chapter)
```

This uses `_chapterBounds`, orders by `reference`, and returns an empty `ChapterTimings` if there are no rows (defensive; the strict build should make that impossible).

### 5.2 Model

New file `flutter_app/lib/infrastructure/audio/verse_timings.dart`:

```dart
class VerseTiming { final int verse; final Duration start; final Duration end; }

class ChapterTimings {
  final int bookId, chapter;
  final List<VerseTiming> verses; // sorted by start

  /// Binary search. Returns null if position < first verse start (chapter announcement).
  /// Positions at or past the last verse's end return the last verse.
  int? verseAt(Duration position);

  VerseTiming? timingFor(int verse);
  bool get isEmpty;
}
```

### 5.3 Ownership

- `BsbAudioHandler` loads `ChapterTimings` whenever it loads a chapter (in `playChapter`). Inject the loader as a function so tests can stub it. The handler owns timings because Repeat Verse enforcement must keep working with the UI in the background.
- The handler exposes a `currentVerse` stream (`int?`, de-duplicated) derived from the player position.
- `AudioPlaybackManager` exposes `ValueNotifier<int?> currentVerseNotifier` and `ChapterTimings? currentTimings` for the UI.

---

## 6. Feature Specifications

### 6.1 Current-verse highlight

- **When shown:** whenever the chapter on screen (`bookId`, `chapter`) equals the chapter loaded in the player, whether **playing or paused**. Hidden when the player is closed (`isPlayerVisible == false`) and during the chapter announcement (`currentVerse == null`).
- **Independent of Sync Text:** the highlight shows even when Sync Text is off.
- **Rendering:** a faint background tint built with the existing `HighlightRange` mechanism, with no changes to the `scripture` package.
  - Color: a theme color at low alpha, e.g. `colorScheme.primary.withValues(alpha: 0.12)`. Tune it for light and dark themes.
  - Range: all words of the verse. Expected IDs: `startId = ref * 1000`, `endId = ref * 1000 + 999`. **Verify** that `scripture` matches highlights by numeric range comparison rather than exact word-ID lookup. If it doesn't, compute the first and last real word IDs of the verse (see `extractWordsFromLines` in `passage_trim_helper.dart`).
  - **Prepend** the audio range to the `highlights` list so user highlights paint over it and keep their colors. Verify the paint order in `scripture/lib/src/flutter/paragraph.dart`.

### 6.2 Auto-scroll (only when Sync Text is ON)

- Sync Text keeps its existing meaning (the reader follows the audio to the playing chapter) and **additionally** controls verse auto-scroll.
- On each verse change, auto-scroll only if the current verse is about to leave the visible area (consider the top padding and the bottom audio bar). Scroll smoothly so the verse sits about **one third** of the way down the viewport.
- **Manual-scroll override:** when the user drags (existing `ScrollStartNotification` with `dragDetails != null`), pause auto-scroll. Resume at the next verse change once **≥ 10 s** have passed since the user's last scroll interaction, or immediately when the user taps a **"jump to current verse"** chip.
- The chip appears only while auto-scroll is paused **and** the current verse is off-screen. Place it bottom-center, above the audio bar. Tapping it scrolls to the verse and resumes auto-scroll.
- Reuse the existing verse-position logic behind `_scrollToTargetVerse` where possible.

### 6.3 "Play" from the selection menu

- Add a `PopupMenuItem` with `value: 'play'` and the label **"Play"** to `_handleMore` in [text_screen.dart](../../flutter_app/lib/ui/text/text_screen.dart). This is the More menu, not a primary selection-bar button.
- Starts audio at the **first selected verse**, then plays on normally (through the chapter, following the current play mode).
- Verse 1 starts at **0:00**, so the chapter announcement is included. Any other verse starts at its `start_ms`.
- Use the selection's own book and chapter (relevant in playlist tabs).
- New manager/handler API: `playFromVerse(int bookId, int chapter, int verse)`. If that chapter is already loaded, seek to the verse and play. Otherwise call `playChapter(..., initialPosition: …)`. Show the player bar.

### 6.4 Live verse reference

- **In-app (bottom bar + expanded player title):** `John 10:14`, updated live. During the announcement, or if timings are missing, show `John 10`.
- **Lock screen / notification:** keep `MediaItem.title = 'John 10'` and set `artist = 'Verse 14'` (null during the announcement). Push an updated `MediaItem` on each verse change.
- ⚠️ **Pitfall:** `AudioPlaybackManager` listens to `mediaItem` and calls `onChapterChanged`. Once the `artist` updates every verse, that listener fires every verse. **De-duplicate on (bookId, chapter)** so the reader doesn't re-navigate every few seconds. Also preserve `id`, `album`, `title`, `duration`, and `extras` when copying the item (`mediaItem.value!.copyWith(artist: …)`).

### 6.5 Previous/next verse buttons

- In the expanded player ([audio_player_modal_sheet.dart](../../flutter_app/lib/ui/audio/audio_player_modal_sheet.dart)), **replace** the −10 s/+10 s buttons with previous/next verse buttons. Chapter skip buttons stay.
- The lock-screen and notification controls are **unchanged** (rewind/fastForward still do ±10 s there).
- **Next verse:** seek to the next verse's `start_ms`. During the announcement, go to verse 1's `start_ms`.
- **Previous verse:** if more than **2 s** into the current verse, restart it. Otherwise seek to the previous verse's `start_ms`. On verse 1 (within 2 s) or during the announcement, seek to 0:00.
- No tick marks on the progress bar.

### 6.6 Repeat Verse play mode

- Add `AudioPlayMode.repeatVerse` with label `'Repeat Verse'`, storage string `'repeatVerse'`, and an icon distinct from `repeatChapter`'s `Icons.repeat_one` (e.g. `Icons.replay`). Update `fromString`, `toStorageString`, `cyclePlayMode`, and the expanded player's play-mode chips (check whether they iterate `AudioPlayMode.values`).
- It is persisted like the other play modes.
- **Loop target:** the verse containing the current position, re-evaluated whenever the user seeks, uses Play-from-verse, or presses the verse buttons. If the position is in the announcement, the target is verse 1.
- **Loop behavior:** when the position reaches the target's `end_ms`, seek back to the target's `start_ms`. For verse 1 that is its `start_ms`, **not** 0:00, so the announcement is not repeated.
- ⚠️ **Precision:** the default position stream ticks about every 200 ms, so the start of the next verse could leak through. While in Repeat Verse, use a faster position stream (`just_audio` `createPositionStream(minPeriod: …, maxPeriod: …)` at about 50 ms) or schedule the seek precisely.
- ⚠️ **Last verse:** its `end_ms` is about the file's duration, so the player may report `completed` before the position check fires. In Repeat Verse mode, handle completion by seeking to the last verse's start and playing. **Never** advance to the next chapter.

---

## 7. Defaults Chosen Without Explicit Discussion (owner may veto)

- **Cycle order:** Continuous → Repeat Chapter → 1 Chapter → **Repeat Verse** → Continuous (the new mode is appended at the end).
- **Next verse on the last verse:** the button is disabled (it does not jump to the next chapter).
- **Sleep timer "End of chapter" while in Repeat Verse:** the owner approved "End of chapter still works", but its exact meaning is ambiguous because the chapter never ends in this mode. Proposed: stop at the end of the current loop iteration. **Confirm with the owner before implementing.**
- **Highlight color:** `colorScheme.primary` at about 12% alpha.

---

## 8. Tests

Builder (`database_builder/test/`):
- Validator accepts a small, valid multi-chapter fixture.
- Validator rejects each rule in §4.3 with its own fixture, including the real-world failure (a `\c 002` file whose IDs say chapter 1, and duplicates).
- Seconds → ms rounding (`271.656` → `271656`).

App (`flutter_app/test/`):
- `ChapterTimings.verseAt`: before the first start → null; exactly at a boundary → the later verse; mid-verse; past the end → the last verse; empty timings.
- `AudioPlayMode.repeatVerse`: storage round-trip and cycle order.
- Previous/next verse seek targets (2 s rule, verse 1, announcement, last verse).
- `playFromVerse`: verse 1 → 0:00; verse N → `start_ms`; same chapter vs. different chapter.
- `MediaItem` artist updates don't re-trigger `onChapterChanged` (de-dupe).
- Highlight is present only when the displayed chapter matches the loaded audio chapter, and is absent when the player is closed.
- Update existing `audio_player_ui_test.dart`, `audio_playback_manager_test.dart`, and `text_menu_more_test.dart` for the new buttons and menu item.

---

## 9. Implementation Order

1. **Done (2026-11-17):** **Isochron** — fixed bugs 1–3 (§3), repaired Souer project IDs, re-exported, and verified 100% coverage & continuity.
2. **Done (2026-11-17):** **Vendor** — copied the 1,189 verified files into `database_builder/audio_timings/souer/` (§4.1).
3. **Done (2026-11-17):** **Builder** — added `audio_timings` schema, table builder, and strict validator, with tests (§4.2–4.3).
4. **Done (2026-11-17):** **Rebuild** — rebuilt `database.db`, copied it to `flutter_app/assets/database/database.db`, and bumped `_databaseVersion` to `32` (§4.4).
5. **Done (2026-11-17):** **App data layer** — `getChapterTimings`, `VerseTiming`/`ChapterTimings`, handler loading, and `currentVerseStream`/`currentVerseNotifier` (§5).
6. **Done (2026-11-17):** **Features** — live verse reference (§6.4), highlight (§6.1), auto-scroll + Jump chip (§6.2), Play from selection (§6.3), verse skip buttons (§6.5), and Repeat Verse mode (§6.6).
7. **Done (2026-11-17):** Updated `CHANGELOG.md`.
