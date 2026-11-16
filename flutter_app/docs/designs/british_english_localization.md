# BSB Runtime British English Localization

* **Author:** suragch
* **Status:** Proposed
* **Date:** 2026-11-14

--------------------------------------------------------------------------------

## Overview

This design adds an opt-in **British English Spelling** setting to the Berean Standard Bible (BSB) Flutter app. Because the published BSB uses standard American English spelling and no official British edition exists, text adaptation runs at read time inside the app rather than modifying the bundled canonical SQLite database ([assets/database/database.db](../../assets/database/database.db)).

A **Bible Text** section in [SettingsPage](../../lib/ui/settings/settings_page.dart) informs users that enabling the option adapts displayed Scripture at read time and differs from the standard published BSB text, while pre-recorded audio and third-party lexicons remain unchanged.

*(Runtime **Yahweh** divine-name adaptation is deferred out of this design; prior findings for that future work are recorded outside this repository in `BSB_Yahweh_Localization_Gaps.md`.)*

--------------------------------------------------------------------------------

## The Problem

While the Berean Standard Bible text is dedicated to the public domain (CC0), shipping an altered SQLite database inside an app branded as the **Berean Standard Bible** creates two problems:

1. **Translation Attribution Integrity:** Modifying the canonical database on disk obscures the boundary between the published BSB text and an optional orthographic adaptation requested by the user.
2. **Database Bloat & Schema Maintenance:** Maintaining a parallel text column and duplicate FTS4 full-text index inside `assets/database/database.db` adds 5–10 MB to the bundled app asset and complicates schema upgrades.

Unconditional global find-and-replace is also insufficient because:

* Unconstrained replacements corrupt American vs. British meaning in context (`practice` noun vs. `practise` verb; `story` narrative vs. `storey` architectural level; present/infinitive `spit` vs. past tense `spat`) or alter word token counts (`anymore` -> `any more`), which would shift sequential `wordId` (`BBCCCVVVWWW`: book `BB`, chapter `CCC`, verse `VVV`, zero-based token index `WWW`) coordinates assigned by [UsfmParser.getWords()](../../../../scripture/lib/src/flutter/usfm/usfm_parser.dart) and used by persisted highlights, notes, and trimmed playlists.
* The standalone reference specification (`BSB_British_English_Localization_Report.md`) omitted 17 spelling variants present in `assets/database/database.db` (across verses, headings, and footnotes) and keyed contextual verses by English book names (`'Psalm 119:56'`), risking `'Psalm'` vs. `'Psalms'` mismatches against `book_id.dart`.
* Transforming text only inside UI widgets leaves `verses_search` FTS4 queries unable to match British search terms (`favour`, `judgements`, `storey`), while unfiltered alias matching returns unhighlighted cards when [BibleSearchService.computeMatchSpans](../../lib/infrastructure/search/bible_search_service.dart#L39-L75) searches `"favor"` inside `"favour"`. Furthermore, some British target words (`burnt` [265 rows] vs. `burned` [157 rows]; `dwelt` [14 rows] vs. `dwelled` [1 row]) already appear alongside convertible American forms in canonical `verses_search`.

--------------------------------------------------------------------------------

## Goals

* **Canonical Database & Sibling Package Preservation:** Keep [assets/database/database.db](../../assets/database/database.db) (`_databaseVersion = 31`) and the sibling `../../scripture` package (referenced in [pubspec.yaml](../../pubspec.yaml#L45-L47), owning shared USFM parsing and `UsfmWidget` rendering) unmodified so standard BSB text remains the canonical source of truth.
* **Accurate British English Adaptation:** Apply the 170 unambiguous single-token dictionary entries (excluding `anymore` -> `any more`), 4 contextual verse disambiguation rules covering 5 word forms (`practice`, `practices`, `story`, `stories`, `spit`), and 17 corpus-verified additions (`192` transformed word forms total) across verses, section headings, footnotes, and interlinear glosses while preserving lowercase, TitleCase, and ALLCAPS casing.
* **Zero Word-ID Shift:** Keep every token replacement 1-to-1 so `BBCCCVVVWWW` coordinates for persisted highlights, note anchors, and trimmed playlists (sub-verse selections created via `trimPassageLines`) never shift.
* **Consistent Multi-Surface Display:** Reflect the toggle across the chapter reader ([ChapterManager](../../lib/ui/text/chapter/chapter_manager.dart)), section headings list, cross-reference popups ([ReferenceModalSheet](../../lib/ui/hebrew_greek/reference_modal_sheet.dart)), clipboard copies, playlist presentation ([PlaylistPresentationPage](../../lib/ui/playlists/playlist_presentation_page.dart)), Hebrew/Greek interlinear cards ([PassageCards](../../lib/ui/hebrew_greek/passage_cards.dart), [VersePageManager](../../lib/ui/hebrew_greek/verse_page_manager.dart)), and similar verses ([SimilarVersesPage](../../lib/ui/hebrew_greek/similar_verses/similar_verses_page.dart)), refreshing open screens and re-opening cached views when toggled.
* **Displayed-Text Full-Text Search:** Allow users to search British spellings, partial prefixes, and quoted phrases (`favour`, `burnt offering`, `honou`, `"his favour"`, `storey`) against the existing FTS4 index without relying on optional `SQLITE_ENABLE_FTS3_PARENTHESIS` compile flags, returning results and highlight spans matching what is displayed on screen.
* **Explicit BSB Deviation Notice:** Display a **Bible Text** settings section explaining that enabling the toggle adapts displayed text from the standard BSB at read time, while pre-recorded audio and third-party lexicons remain unchanged.

--------------------------------------------------------------------------------

## Non-Goals

* **Altering Bundled BSB Data or Schema:** Modifying, regenerating, or duplicating tables inside `assets/database/database.db`.
* **Yahweh Divine-Name Localization:** Replacing `the LORD` / `LORD` / `GOD` with `Yahweh` / `Yah` (deferred; documented in external `BSB_Yahweh_Localization_Gaps.md`).
* **Audio Re-Recording or Synthesis:** Modifying pre-recorded audio chapters played by [AudioPlaybackManager](../../lib/infrastructure/audio/audio_playback_manager.dart).
* **Third-Party Reference Texts:** Modifying the Brown-Driver-Briggs Hebrew lexicon, Abbott-Smith Greek lexicon (`lexicon_entry` table), or external historical texts (`Jasher`, `1 Esdras`, `1 Enoch` in [extrabiblical_texts.dart](../../lib/infrastructure/extrabiblical_texts.dart)).
* **Rewriting Saved Annotation Snapshots:** Altering creation-time text snapshots (`highlights.text` and `notes.passage_text`) already stored in `user_annotations.db`. *(Note: In [HighlightsAndNotesPage._fetchSnippets](../../lib/ui/annotations/highlights_and_notes_page.dart#L150-L209), legacy highlights/notes with null or empty stored snippets backfill from `getTextForRange()` / `getVerseText()` and save that result into `user_annotations.db`, permanently capturing whichever spelling mode is active when first viewed.)*
* **Cross-Variant Search Aliasing:** Returning verses rendered with British words (`favour`) when searching replaced American forms (`favor`) while British mode is enabled.

--------------------------------------------------------------------------------

## Open Questions

None.

--------------------------------------------------------------------------------

## Critical User Journeys (CUJs)

### CUJ 1: Enabling British Spelling & Reading Across Surfaces

* **Given:** A user on standard BSB settings reads chapters with open tabs, a playlist open, and an interlinear word card inspected.
* **When:** The user opens Settings, reads the BSB deviation notice in **Bible Text**, toggles **British English Spelling** ON, and navigates back.
* **Then:** Active reader tabs, section headings, footnotes (`metres`, `litres`), clipboard copies, playlists, newly opened Hebrew/Greek interlinear word cards, and similar-verse cards display British spellings (`favour`, `judgements`, `honour`, contextual `practise`/`storey`/`spat`) immediately, while `anymore` and noun `practice` / narrative `story` / present/infinitive `spit` remain unchanged.

### CUJ 2: Toggling Settings With Highlights, Notes, and Trimmed Playlists

* **Given:** A user has created highlights, notes, and trimmed playlist passages under either standard BSB or British mode.
* **When:** The user switches **British English Spelling** ON and later OFF.
* **Then:** Existing in-chapter highlights, note marker icons, and trimmed playlist boundaries remain anchored on the same words with zero coordinate shift, saved `BibleTab.sectionHeading` values still scroll to matching headings in either direction, and creation-time text snapshots in Highlights & Notes retain their stored text.

### CUJ 3: Searching Localized Text

* **Given:** **British English Spelling** is enabled.
* **When:** The user searches for `favour`, `burnt offering`, partial prefix `honou`, contextual `storey`, or exact phrase `"his favour"`.
* **Then:** Search retrieves all matching verses (including both canonical `burnt` and converted `burned` -> `burnt`), highlights exact spans in the localized snippets, respects the requested result limit after Dart post-filtering, and excludes replaced American forms (`favor` when rendered as `favour`) as well as non-contextual `story` verses when searching `storey`.

--------------------------------------------------------------------------------

## Technical Plan (Architecture)

The design introduces one pure-Dart stateless utility in `lib/infrastructure/` (`BsbTextLocalizer`), propagates a single boolean flag (`useBritishSpelling`) from [AppState](../../lib/app_state.dart) into [DatabaseHelper](../../lib/infrastructure/database.dart), [BibleSearchService](../../lib/infrastructure/search/bible_search_service.dart), and reactive UI listeners inside `flutter_app`, keeping dependencies strictly acyclic and leaving `assets/database/database.db` and `../../scripture` untouched.

### System Architecture & Data Flow

```text
UserSettings (SharedPreferences: 'useBritishSpelling')
  └─> AppState (syncs DatabaseHelper in init() and BEFORE notifying listeners)
        ├──> DatabaseHelper (_useBritishSpelling, clears _chapterWordsCache on change)
        │      │
        │      ├── Read Path: getChapter / getRange / getVerseText
        │      │     SQLite (bible table) ─> BsbTextLocalizer.localize ─> UsfmLine / snippet
        │      │     (getTextForRange inherits localization via getChapterWords -> getChapter)
        │      │
        │      ├── Headings Path: getSectionHeadings & ChapterText._matchesHeading
        │      │     BsbTextLocalizer.localizeHeading (unconditional normalization in _matchesHeading)
        │      │
        │      ├── Interlinear Path: getOriginalLanguageData
        │      │     SQLite (interlinear+english) ─> BsbTextLocalizer.localize ─> resolveWordClusters
        │      │
        │      └── Search Path: DatabaseHelper.searchVerses (candidate retrieval + localization, honors limit)
        │            <─ BibleSearchService.searchVerses (passes limit: null if British, filters with \b checks,
        │                 computes match spans, applies limit in Dart)
        │
        └──> Listeners & Stale Checks
               ├── ChapterManager (live listener on useBritishSpellingNotifier)
               ├── PlaylistPresentationPage (live listener on useBritishSpellingNotifier)
               ├── SimilarVersesPage (ValueListenableBuilder on useBritishSpellingNotifier + _contentCache bool key)
               └── SearchManager (lazy staleness check in init(), avoids background queries in Settings)
```

### 1. Text Localization Utility (`BsbTextLocalizer`)

`BsbTextLocalizer` is a pure-Dart stateless utility (`lib/infrastructure/bsb_text_localizer.dart`) with zero UI dependencies:

* **Native Packed Integer Keys (`BBCCCVVV`):** All four contextual verse sets use compile-time `const Set<int>` packed `BBCCCVVV` integers matching `DatabaseHelper`'s native reference keys (`Reference.packedVerse`), avoiding English book-name parsing and `'Psalm'`/`'Psalms'` mismatches. Three sets are inclusion sets (converted only inside those verses: plural verb `practices -> practises`, architectural `story/stories -> storey/storeys`, past/participle `spit -> spat`), and one is an exclusion set (`practice` stays a noun inside 9 listed verses and becomes `practise` elsewhere). See **Appendix A** for exact tables and 35 verified IDs.
* **Single-Sweep Dictionary & Shared Casing Helper:** Runs contextual disambiguation first, followed by a single compiled case-insensitive `\b(...)\b` dictionary sweep covering all 170 unambiguous report entries (excluding `anymore -> any more`) plus the 17 corpus additions. Both contextual and dictionary replacements use one shared case-matching helper checking ALLCAPS (`original == original.toUpperCase()`) before TitleCase (`original[0] == original[0].toUpperCase()`), preserving lowercase, TitleCase, and ALLCAPS.
* **Two Public Text Entry Points:**
  * `localize(int packedVerse, String text)`: transforms verse lines (including inline USFM `\f...\f*` footnotes such as `metres`, `litres`, `capitalised`, `revocalisation`), plain verse snippets (`getVerseText`, `searchVerses`), and individual interlinear glosses (`OriginalWord.englishGloss`). USFM tags (`\f`, `\fr`, `\ft`, `\wj`, `\q1`, etc.) never collide with dictionary keys.
  * `localizeHeading(String text)`: runs the unambiguous dictionary regex directly for section headings (`\s1`/`\s2`) in `getSectionHeadings()` and heading comparison in `ChapterText._matchesHeading`. Verified against `database.db` that zero headings or Psalm `\d` superscriptions contain `practice`, `story`/`stories`, or `spit`.
* **Interlinear Cluster Ordering:** In [database.dart](../../lib/infrastructure/database.dart#L158-L215), `getOriginalLanguageData()` converts each Hebrew/Greek word row and calls [resolveWordClusters(words)](../../lib/infrastructure/word_cluster.dart) so multi-word `vvv` cluster companions ([verse_element.dart](../../lib/infrastructure/verse_element.dart)) inherit the English `partOfTranslation` string. `BsbTextLocalizer.localize(reference.packedVerse, englishGloss)` must execute **before** `resolveWordClusters(words)` so companion cluster chips inherit British spelling.

### 2. Layering, Cache Ownership & Heading Normalization

* **One-Way Infrastructure Coupling:** `DatabaseHelper` never imports `lib/ui/`, `AppState`, or `BibleSearchService`. It holds `bool _useBritishSpelling = false`, exposes `bool get useBritishSpelling => _useBritishSpelling;`, and exposes `void setUseBritishSpelling(bool enabled)` which clears `_chapterWordsCache` whenever `_useBritishSpelling != enabled`.
* **Uncached On-Demand Readers vs. Cached Surfaces:** `getTextForRange()` delegates to `getChapterWords()` -> `getChapter()`, so annotation backfills automatically read localized words. Uncached on-demand surfaces ([ReferenceModalSheet](../../lib/ui/hebrew_greek/reference_modal_sheet.dart), clipboard copy helpers, [PassageCards](../../lib/ui/hebrew_greek/passage_cards.dart), and [VersePageManager](../../lib/ui/hebrew_greek/verse_page_manager.dart) pushed from chapter words) read freshly on open and require no reactive listeners.
* **Symmetric Heading Normalization:** `ChapterText._matchesHeading(String text, String target)` ([chapter_text.dart](../../lib/ui/text/chapter/chapter_text.dart#L699-L714)) unconditionally passes both `text` and `target` through `BsbTextLocalizer.localizeHeading(...)` before punctuation stripping and lowercasing, ensuring saved `BibleTab.sectionHeading` strings match rendered headings across both OFF -> ON and ON -> OFF toggles without reading settings state.
* **Zero Word-ID Change:** Because omitting `anymore -> any more` keeps every token 1-to-1, `UsfmParser.getWords()`, `trimPassageLines()`, `ChapterManager` highlights/notes, and `DatabaseHelper.getTextForRange()` preserve canonical `BBCCCVVVWWW` coordinates with zero mapping.

### 3. Parenthesis-Free FTS4 Candidate Expansion & Single-Pass Post-Filtering

Unmodified `verses_search` stays indexed on canonical American BSB text. To preserve a one-way dependency (`BibleSearchService` -> `DatabaseHelper` -> `BsbTextLocalizer`), candidate retrieval and strict matching split cleanly:

1. **Candidate Expansion (`DatabaseHelper._sanitizeFtsQuery` & `searchVerses`):**
   * **Single non-prefix terms (`favour`, `storey`):** When canonical `database.db` has 0 British occurrences (`favour` -> `favor`, `storey` -> `story`), emit only the single mapped canonical word (no `OR` needed). When canonical collisions exist (`burnt`: 265 canonical + 157 `burned`; `dwelt`: 14 canonical + 1 `dwelled`), emit `['burnt', 'burned']` / `['dwelt', 'dwelled']`.
   * **Prefix tokens (`clean*`):** Expand to `[token, ...americanStems]` keeping only American stems that do **not** already start with `token` (e.g., `honou*` adds `honor*`, whereas `fa*` already matches `favor*` without expansion), deduplicated in order.
   * **Exact & Quoted Phrases (`isExact: true` or `"..."` inside non-exact queries):** If no word inside the phrase expands to a different canonical term (e.g., `"in the"`), retain the `"..."` FTS4 phrase quote for SQL selectivity. If at least one word expands (e.g., `"his favour"`, `"burnt offering"`), break the phrase into sanitized word-only token groups (stripping punctuation such as apostrophes in `"King's favour"` and dropping bare FTS operator keywords `AND`/`OR`/`NOT`/`NEAR`).
   * **Parenthesis-Free SQL Execution (`INTERSECT`):** Never emit `(` or `)`. If a query has only one token group with multiple `OR` terms (e.g., `burnt* OR burned*`), run a flat single `MATCH ?`. Whenever multiple token groups are combined with `AND` and any group has multiple `OR` alternatives, run `SELECT docid FROM verses_search WHERE text MATCH ?` per group joined with SQLite `INTERSECT`, then join matched `docid`s to `bible` with `scopeClause`. `DatabaseHelper.searchVerses()` always honors its passed `limit` argument and runs `BsbTextLocalizer.localize(packedVerse, clean)` on each returned snippet.
2. **Strict Single-Pass Verification (`BibleSearchService.searchVerses`):**
   * When `_dbHelper.useBritishSpelling` is `true`, `BibleSearchService.searchVerses()` passes `limit: null` to `_dbHelper.searchVerses(...)` so candidate fetching is never truncated on false positives (such as canonical `story` for `storey` or `practice` for `practise`) before Dart verification, then slices `.take(limit)` at the end.
   * Using one shared private query-token parser inside `BibleSearchService` (shared with `computeMatchSpans`): return `[]` if parsed tokens are empty (`"???"`); verify quoted/`isExact` phrases with strict `\b...\b` boundaries (**without** the existing boundary-less fallback at lines 70–74 of `bible_search_service.dart`, preventing `"his favour"` from matching `"this favour"`); verify unquoted single- and multi-token queries with `\b$token` word-start matching; compute `matchSpans`; and discard rows where any required token/phrase fails or `matchSpans.isEmpty`.

### 4. Settings UI, Initialization Ordering & Screen Refresh

* **`UserSettings` & `AppState`:** Add `_useBritishSpellingKey = 'useBritishSpelling'` and public `useBritishSpelling` getter/setter on [UserSettings](../../lib/ui/settings/user_settings.dart) (`false` by default, deleting the `SharedPreferences` key when `false` to match `wordsOfJesusInRed`). In `AppState`, wire `useBritishSpellingNotifier` into `notifyListeners` / `dispose()`, sync `_dbHelper?.setUseBritishSpelling(...)` inside `AppState.init()` (fixing cold-start order after `DatabaseHelper.init()` in [main.dart](../../lib/main.dart#L14-L17)), and in `setUseBritishSpelling(bool value)` call `_dbHelper?.setUseBritishSpelling(value)` **synchronously before** assigning `useBritishSpellingNotifier.value = value`.
* **`SettingsPage`:** Insert a **Bible Text** section immediately above `Backup` (after a `Divider`) containing a `SwitchListTile` titled `'British English Spelling'` and an inline caption explaining the read-time departure from standard BSB while audio and lexicons stay unchanged.
* **Screen Refresh:** Subscribe `ChapterManager` (with `(0, 0)` and `_disposed` guards) and `PlaylistPresentationPage` (with `mounted` and `setState(() { _passageCache.clear(); _isLoading = true; })` guards) to `useBritishSpellingNotifier`; use lazy staleness detection inside `SearchManager.init()` (comparing `_lastSearchUseBritishSpelling != _searchService.useBritishSpelling`) so toggling in Settings does not trigger background full-Bible queries; and key `SimilarVerseManager._contentCache` + `SimilarVersesPage` `FutureBuilder` on `useBritishSpelling` via `ValueListenableBuilder<bool>`.

--------------------------------------------------------------------------------

## Alternatives Considered

### Alternative A: Precomputing a Separate British Column / FTS4 Index in `assets/database/database.db`

* **Pros:** Zero runtime regex transformation cost and single-step SQLite FTS4 matching without Dart post-filtering.
* **Cons:** Adds 5–10 MB to the bundled database asset, requires regenerating `database.db` (`_databaseVersion`), and mixes canonical BSB storage with optional spelling variants.
* **Reason for Rejection:** Rejected to keep `assets/database/database.db` (`_databaseVersion = 31`) unmodified on disk.

### Alternative B: Applying Regex Replacements in Individual Flutter Widgets

* **Pros:** Leaves `DatabaseHelper` untouched.
* **Cons:** Scatters localization logic across `UsfmWidget`, `PassageCards`, `SimilarVersesPage`, `SearchPage`, clipboard helpers, and section heading dialogs; risks missing non-widget copy paths; and cannot resolve British search queries against canonical FTS4 text.
* **Reason for Rejection:** Rejected in favor of centralizing read-time localization inside `DatabaseHelper` via `BsbTextLocalizer`.

### Alternative C: Allowing Cross-Variant Search Aliasing Without Dart Post-Filtering

* **Pros:** Simpler FTS4 query pipeline without passing `limit: null` or filtering candidates in Dart.
* **Cons:** Searching `"favor"` when `"favour"` is displayed returns verses where `BibleSearchService.computeMatchSpans` finds zero match spans (producing unhighlighted result cards), and searching `"storey"` returns narrative `"story"` verses in Genesis 39 unless filtered in Dart.
* **Reason for Rejection:** Rejected to keep strict displayed-text matching and valid highlight spans via `BibleSearchService`.

### Alternative D: Re-Localizing Persisted Highlight and Note Snapshots on Read

* **Pros:** Keeps saved snippet text on Highlights & Notes synchronized with the active spelling toggle.
* **Cons:** Rewrites or re-processes historical snapshots recorded when the user created the note or highlight.
* **Reason for Rejection:** Rejected to preserve creation-time snapshots in `highlights.text` and `notes.passage_text`, using `getTextForRange()` only for backfilling empty legacy snippets.

--------------------------------------------------------------------------------

## Risks & Limits

* **SQLite `FTS3_PARENTHESIS` Build Variance:** Android and iOS system SQLite builds may omit `SQLITE_ENABLE_FTS3_PARENTHESIS`. Avoided by never emitting `(` or `)` in FTS4 `MATCH` clauses and combining expanded token groups via SQLite `INTERSECT`.
* **Short-Prefix & High-Frequency Candidate Volume:** Dropping SQL `LIMIT` when `_dbHelper.useBritishSpelling` is `true` relies on Dart localization and `\b` filtering over candidate rows (`SearchManager` already passes `limit: null` in standard mode). Short prefixes (`>= 2` chars) deduplicate stems so prefixes like `fa*` that already match `favor*` do not fan out into extra `OR` clauses.
* **Punctuation & FTS Operator Injection in Search Input:** Breaking quoted or exact phrases into unquoted `INTERSECT` token groups could throw FTS4 syntax errors on apostrophes (`"King's favour"`), punctuation (`"???"`), or bare keywords (`AND`/`OR`/`NOT`/`NEAR`). Mitigated by stripping non-`\w` characters, filtering empty token lists (`return []`), and removing standalone FTS operator keywords from expanded token groups. No new network, privilege, or storage-permission boundary is introduced.
* **Database Corpus Drift:** Static contextual sets (`35` `BBCCCVVV` IDs) and the 187 dictionary keys target `_databaseVersion = 31`. Any future rebuild of `database.db` adding or renumbering verses must re-run the corpus audit test in `test/bsb_text_localizer_test.dart`.

--------------------------------------------------------------------------------

## Non-Functional Requirements

* **Runtime Overhead & Initialization:** Compiled regular expressions and packed `const Set<int>` contextual sets in `BsbTextLocalizer` are static and initialized once per isolate; contextual verse checks run in $O(1)$ integer set lookups, and dictionary sweeps scan once per line without duplicate pass work between `DatabaseHelper` and `BibleSearchService`.
* **Rollout & Backward Compatibility:** `useBritishSpelling` defaults to `false` when absent from `SharedPreferences` and removes its key when set to `false`, resulting in immediate reversion to standard BSB text when disabled. `assets/database/database.db` (`_databaseVersion = 31`) and `user_annotations.db` schemas remain unchanged.
* **Diagnostics & Observability:** Log structured warnings in debug/diagnostic logs when `DatabaseHelper.searchVerses()` catches an FTS4 SQL error (including `_useBritishSpelling` state and generated candidate SQL/MATCH expression).

--------------------------------------------------------------------------------

## Additional Resources

* [concepts_brief.md](../../concepts_brief.md)
* External report (outside repo): `BSB_British_English_Localization_Report.md` (complete word tables and `BBCCCVVV` sets are reproduced in Appendix A below)
* Deferred divine-name notes (outside repo): `BSB_Yahweh_Localization_Gaps.md`

--------------------------------------------------------------------------------

## Detailed Implementation Plan

### Phase 1: Localization Engine, Dependencies & Corpus Verification

**Checkpoint Gate:** `flutter analyze && flutter test test/bsb_text_localizer_test.dart` must pass cleanly before Phase 2.

#### 1. [pubspec.yaml](../../pubspec.yaml) (Modify)

* **Scope:** Test Dependencies
* **Proposed Changes:** Add `sqflite_common_ffi` under `dev_dependencies` so `flutter test` suites can open `assets/database/database.db` via `databaseFactoryFfi` without relying on platform channels.

#### 2. `lib/infrastructure/bsb_text_localizer.dart` (Create)

* **Scope:** British English Localization Utility (Pure Dart, `lib/infrastructure/`)
* **Proposed Changes:**
  * Declare compile-time `const Set<int>` `BBCCCVVV` sets from Appendix A: `_nounPracticeVerses` (9 exclusion verses), `_verbPracticesVerses` (16 inclusion verses), `_storeyVerses` (3 inclusion verses), and `_pastSpitVerses` (7 inclusion verses).
  * Declare `const Map<String, String> _ukDictionary` containing all `170` unambiguous single-token report pairs (excluding `anymore -> any more`) plus all `17` corpus additions (`187` dictionary entries total; `192` transformed word forms counting the 5 contextual forms in the 4 sets) from Appendix A.
  * Declare case-insensitive regexes for the contextual words (`practice`, `practices`, `story`, `stories`, `spit`) and one compiled case-insensitive `\b(...)\b` `_ukRegex` built from `_ukDictionary.keys`.
  * Implement shared casing helper `_matchCase(String original, String replacement)` that checks `original == original.toUpperCase()` (returning `replacement.toUpperCase()`) **before** checking `original[0] == original[0].toUpperCase()` (returning capitalized TitleCase), defaulting otherwise to `replacement`.
  * Implement `static String localize(int packedVerse, String text)`:
    1. If `!_nounPracticeVerses.contains(packedVerse)`, replace `\bpractice\b` -> `_matchCase(m, 'practise')`.
    2. If `_verbPracticesVerses.contains(packedVerse)`, replace `\bpractices\b` -> `_matchCase(m, 'practises')`.
    3. If `_storeyVerses.contains(packedVerse)`, replace `\bstory\b` -> `_matchCase(m, 'storey')` and `\bstories\b` -> `_matchCase(m, 'storeys')`.
    4. If `_pastSpitVerses.contains(packedVerse)`, replace `\bspit\b` -> `_matchCase(m, 'spat')`.
    5. Run `_ukRegex` across `text`, mapping matched lowercase tokens via `_ukDictionary` through `_matchCase`.
  * Implement `static String localizeHeading(String text)`: runs `_ukRegex` via `_matchCase` for headings (`getSectionHeadings()` and `ChapterText._matchesHeading`).
  * Implement FTS expansion helper `static List<String> expandFtsToken(String cleanWord, {bool isPrefix = false})`:
    * Invert all `187` `_ukDictionary` pairs plus the `5` contextual British targets (`practise: practice`, `practises: practices`, `storey: story`, `storeys: stories`, `spat: spit`) into `_britishToAmerican` (`Map<String, List<String>>` supporting one-to-many collisions).
    * Precompute `_canonicalCollisionTargets = {'burnt', 'dwelt'}` (`265` and `14` canonical rows in `database.db`).
    * Accepting a lowercase alphanumeric word (`cleanWord`, empty returns `[]`):
      * When `!isPrefix`: look up `_britishToAmerican[cleanWord]`; if missing return `[cleanWord]`; if `_canonicalCollisionTargets.contains(cleanWord)` return `[cleanWord, ...americanForms]` deduplicated; otherwise return `[...americanForms]` (1:1 replacement, e.g. `favour` -> `['favor']`).
      * When `isPrefix`: find any keys `k` in `_britishToAmerican` starting with `cleanWord`, collect mapped `americanForms` where `!american.startsWith(cleanWord)` (avoiding redundant stems when FTS prefix `token*` already matches `american*`), and return `[cleanWord, ...deduplicatedStems]`.

#### 3. `test/bsb_text_localizer_test.dart` (Create)

* **Scope:** Unit & Full SQLite Corpus Audit Tests (`test/`)
* **Proposed Changes:**
  * Unit tests for all `170` dictionary entries, `17` corpus additions, all `35` contextual verse IDs (`_nounPracticeVerses` vs verb `practise`, `_verbPracticesVerses` vs noun `practices`, `_storeyVerses` vs Genesis 39 narrative `story`, `_pastSpitVerses` vs 5 present/infinitive `spit` verses), preservation of `anymore`, lowercase / TitleCase / ALLCAPS precedence (`HONOR` -> `HONOUR`, `Practice` -> `Practise`, `SPIT` -> `SPAT`), `localizeHeading`, and `expandFtsToken` (1:1 non-prefix `favour` -> `['favor']`, collision `burnt` -> `['burnt', 'burned']`, prefix `honou` vs `fa`).
  * Full corpus audit opening `assets/database/database.db` read-only via `sqflite_common_ffi`: verify **zero token-count delta across all 31,086 verses** compared to `UsfmParser.getWords()`, and verify interlinear gloss localization updates `OriginalWord.partOfTranslation` on `vvv` cluster companions.

---

### Phase 2: Database Access Layer & Displayed-Text Search

**Checkpoint Gate:** `flutter analyze && flutter test test/bible_search_localization_test.dart test/bible_search_service_test.dart` must pass cleanly before Phase 3.

#### 4. [database.dart](../../lib/infrastructure/database.dart) (Modify)

* **Scope:** Data Access Layer (`DatabaseHelper`)
* **Proposed Changes:**
  * Hold `bool _useBritishSpelling = false;` with `bool get useBritishSpelling => _useBritishSpelling;` and `void setUseBritishSpelling(bool enabled)` (clearing `_chapterWordsCache` whenever `_useBritishSpelling != enabled`). Keep `DatabaseHelper` free of imports from `lib/ui/`, `AppState`, or `BibleSearchService`.
  * Add `@visibleForTesting void setDatabaseForTesting(Database db)` and `@visibleForTesting int get chapterWordsCacheLength => _chapterWordsCache.length;` for FFI tests.
  * When `_useBritishSpelling` is `true`, pass verse text/lines through `BsbTextLocalizer.localize(packedVerse, text)` in `getChapter()`, `getRange()`, and `getVerseText()`, and pass section heading titles through `BsbTextLocalizer.localizeHeading(title)` in `getSectionHeadings()`.
  * In `getOriginalLanguageData(Reference reference)`, apply `BsbTextLocalizer.localize(reference.packedVerse, englishGloss)` **before** instantiating `OriginalWord` and calling `resolveWordClusters(words)` (line 214) so cluster companions inherit the British `partOfTranslation`.
  * Update `static List<String> _buildFtsCandidateClauses(String query, {bool isExact = false, bool useBritishSpelling = false})` (alongside `_sanitizeFtsQuery`):
    * When `!useBritishSpelling`, preserve existing single-clause `_sanitizeFtsQuery` behavior unchanged.
    * When `useBritishSpelling == true`:
      * Strip non-`\w` characters inside unquoted words and skip empty tokens or bare FTS operator keywords (`AND`, `OR`, `NOT`, `NEAR`).
      * For `isExact: true` or `"quoted phrase"` segments: split into cleaned words; if **no** word expands via `BsbTextLocalizer.expandFtsToken(w, isPrefix: false)` beyond `[w]`, keep the canonical `"$phrase"` FTS4 token; if at least one word expands, expand each cleaned word into a non-prefix group (`w1 OR w2`).
      * For unquoted non-exact tokens: call `BsbTextLocalizer.expandFtsToken(clean, isPrefix: true)` mapping each term to `'$term*'`.
      * Format each group without parentheses as `'term1 OR term2'` (flat `OR`).
  * Update `searchVerses()`:
    * When only one group exists, run a single `WHERE text MATCH ?` SQL query; when multiple groups exist and at least one group contains `OR`, build `SELECT docid FROM verses_search WHERE text MATCH ?` per group joined by `INTERSECT`, joined to `bible` (`JOIN bible b ON b.reference = matched.docid`) with `scopeClause`, preserving `ORDER BY` / optional `LIMIT ?` (always honoring the `limit` parameter passed by the caller!).
    * When `_useBritishSpelling` is `true`, localize returned verse snippets via `BsbTextLocalizer.localize(packedVerse, clean)` before constructing `SearchResult`.
    * Log `_useBritishSpelling` and the candidate clauses when catching SQLite FTS exceptions.

#### 5. [bible_search_service.dart](../../lib/infrastructure/search/bible_search_service.dart) (Modify)

* **Scope:** Search Post-Filter & Highlight Span Verification (`BibleSearchService`)
* **Proposed Changes:**
  * Expose `bool get useBritishSpelling => _dbHelper.useBritishSpelling;` on `BibleSearchService`.
  * Extract one shared private query-token parser `_parseQueryTokens(String query, {bool isExact = false})` returning quoted/exact phrases and clean unquoted tokens, shared by `computeMatchSpans` and strict filtering.
  * Update `computeMatchSpans(..., {bool isExact = false, bool strictExactBoundary = false})`: when `strictExactBoundary` is `true`, omit the boundary-less regex fallback (`lines 70–74`), requiring strict `\b...\b` boundaries for exact phrases.
  * Add `static bool matchesLocalizedText(String localizedText, String query, {bool isExact = false})`:
    * Parse tokens via `_parseQueryTokens`; return `false` immediately if no valid tokens exist (`"???"`).
    * For `isExact: true`, return strict `\b...\b` phrase match non-empty (`strictExactBoundary: true`).
    * For non-exact queries, require every quoted phrase token to match with `\b...\b` and every unquoted token (single or multi-token) to match with word-start prefix `\b$escaped` (`caseSensitive: false`).
  * Update `BibleSearchService.searchVerses()`:
    * When `_dbHelper.useBritishSpelling` is `true`: pass `limit: null` to `_dbHelper.searchVerses(...)` so false positives (`story` for `storey`, `practice` for `practise`) never starve true results; filter results keeping rows where `matchesLocalizedText(result.text, query, isExact: isExact)` is `true` and `computeMatchSpans(..., strictExactBoundary: true)` is non-empty; then slice `.take(limit)` in Dart if `limit != null`.

#### 6. `test/bible_search_localization_test.dart` (Create alongside [bible_search_service_test.dart](../../test/bible_search_service_test.dart))

* **Scope:** FTS4 Search & Post-Filter Tests (`test/`)
* **Proposed Changes:** Using FFI `DatabaseHelper` + `BibleSearchService` against `assets/database/database.db`, verify:
  * Single 1:1 British query (`favour`, `judgements`) returns all expected converted rows and highlights spans.
  * Canonical-collision query (`burnt`, `burnt offering`, `dwelt`) returns both canonical `burnt`/`dwelt` rows and converted `burned`/`dwelled` rows via parenthesis-free `OR` and `INTERSECT`.
  * Partial prefix query (`honou`, `enqui`) returns British-localized rows.
  * Contextual disambiguation query (`storey` excludes Genesis 39 `story`; `practise` excludes 9 noun verses).
  * Exact & mixed queries (`"his favour"` with `isExact: true` and `isExact: false`; `"his favour" kingdom`; `"King's favour"` with apostrophe; `"this favour"` rejected for `"his favour"`; `"???"` returning `[]`).
  * Exclusion of replaced canonical terms (`favor` returns `[]` when British mode is enabled) and Dart `limit` enforcement after post-filtering.

---

### Phase 3: Preferences, AppState, UI Surfaces & Widget Tests

**Checkpoint Gate:** `flutter analyze && flutter test` across the full suite must pass cleanly.

#### 7. [user_settings.dart](../../lib/ui/settings/user_settings.dart) (Modify)

* **Scope:** Preference Persistence (`UserSettings`)
* **Proposed Changes:** Add `static const String _useBritishSpellingKey = 'useBritishSpelling';` plus public `bool get useBritishSpelling => _prefs.getBool(_useBritishSpellingKey) ?? false;` and `Future<void> setUseBritishSpelling(bool value)` removing `_useBritishSpellingKey` when `value == false` (matching `wordsOfJesusInRed`), leaving existing preferences unchanged unless toggled.

#### 8. [app_state.dart](../../lib/app_state.dart) (Modify)

* **Scope:** App-Wide Reactive State (`AppState`)
* **Proposed Changes:**
  * Accept optional `DatabaseHelper? dbHelper` in constructor (`DatabaseHelper? get _effectiveDbHelper => _dbHelper ?? (getIt.isRegistered<DatabaseHelper>() ? getIt<DatabaseHelper>() : null);`).
  * Add `final useBritishSpellingNotifier = ValueNotifier<bool>(false);` and `bool get useBritishSpelling => useBritishSpellingNotifier.value;`.
  * Register `useBritishSpellingNotifier.addListener(notifyListeners)` in constructor and call `removeListener` + `dispose()` in `AppState.dispose()`.
  * In `init()`, load `final british = userSettings.useBritishSpelling;`, call `_effectiveDbHelper?.setUseBritishSpelling(british)`, then assign `useBritishSpellingNotifier.value = british`.
  * Add `Future<void> setUseBritishSpelling(bool value) async`: call `_effectiveDbHelper?.setUseBritishSpelling(value)` **synchronously first**, then set `useBritishSpellingNotifier.value = value`, then `await userSettings.setUseBritishSpelling(value)`.

#### 9. [settings_page.dart](../../lib/ui/settings/settings_page.dart) (Modify)

* **Scope:** Settings UI (`SettingsPage`)
* **Proposed Changes:** Insert a **Bible Text** section header (`Theme.of(context).textTheme.titleSmall` primary bold, matching `Appearance` / `Backup`) directly above the `Backup` divider (`line 374`), containing:
  * `SwitchListTile` with `title: const Text('British English Spelling')`, bound to `value: appState.useBritishSpelling` and `onChanged: appState.setUseBritishSpelling`.
  * Inline `Padding` caption `Text` below the switch: `'Enabling this adapts displayed Scripture at read time and differs from the standard BSB text. Pre-recorded audio and third-party lexicons remain unchanged.'`

#### 10. [chapter_manager.dart](../../lib/ui/text/chapter/chapter_manager.dart) (Modify)

* **Scope:** Chapter Data Coordinator (`ChapterManager`)
* **Proposed Changes:**
  * Add `bool _disposed = false;` and optional `AppState? _appState;` resolved in constructor via `getIt.isRegistered<AppState>() ? getIt<AppState>() : null`.
  * Subscribe `_onLocalizationChanged` to `_appState?.useBritishSpellingNotifier`; guard `_onLocalizationChanged` with `if (_currentBookId != 0 && _currentChapter != 0)` before calling `requestText(...)`.
  * In `requestText`, check `if (_disposed) return;` after awaits before updating `ValueNotifier`s; in `dispose()`, set `_disposed = true` and remove listener from `_appState?.useBritishSpellingNotifier`.

#### 11. [chapter_text.dart](../../lib/ui/text/chapter/chapter_text.dart) (Modify)

* **Scope:** Chapter Reader Widget (`ChapterText`)
* **Proposed Changes:** Update `_matchesHeading(String text, String target)` to pass both `text` and `target` unconditionally through `BsbTextLocalizer.localizeHeading(...)` before punctuation stripping and lowercasing so persisted `BibleTab.sectionHeading` values match in both toggle directions.

#### 12. [playlist_presentation_page.dart](../../lib/ui/playlists/playlist_presentation_page.dart) (Modify)

* **Scope:** Playlist Presentation UI (`PlaylistPresentationPage`)
* **Proposed Changes:** Subscribe `_onLocalizationChanged` to `_appState?.useBritishSpellingNotifier` and detach in `dispose()`. When fired, check `if (!mounted) return;`, execute `setState(() { _passageCache.clear(); _isLoading = true; });`, and call `_loadPassages()`.

#### 13. [search_manager.dart](../../lib/ui/search/search_manager.dart) (Modify)

* **Scope:** Search State Coordinator (`SearchManager`)
* **Proposed Changes:** Track `bool? _lastSearchUseBritishSpelling;` updated whenever `_executeSearch` runs (and cleared in `clearSearch()`). In `SearchManager.init()`, if `_currentQuery.trim().length >= 2` and `_lastSearchUseBritishSpelling != _searchService.useBritishSpelling`, invoke `_executeSearch(_currentQuery.trim())` so returning to `SearchPage` refreshes stale results lazily without running background queries while in Settings.

#### 14. [similar_verse_manager.dart](../../lib/ui/hebrew_greek/similar_verses/similar_verse_manager.dart) & [similar_verses_page.dart](../../lib/ui/hebrew_greek/similar_verses/similar_verses_page.dart) (Modify)

* **Scope:** Similar Verses Cache & Page Rebuild (`SimilarVerseManager`, `SimilarVersesPage`)
* **Proposed Changes:**
  * In `SimilarVerseManager`: keep the class decoupled from `ChangeNotifier` and `AppState`; expand `_contentCache` key from `(int, WordSearchMode, int)` to `(int, WordSearchMode, int, bool)` including `_dbHelper.useBritishSpelling`.
  * In `SimilarVersesPage`: if `getIt.isRegistered<AppState>()`, wrap the `FutureBuilder` verse cards with `ValueListenableBuilder<bool>` on `getIt<AppState>().useBritishSpellingNotifier` (defaulting `false` when unregistered in tests) and include the boolean in `ValueKey('${reference.packedVerse}_${manager.searchModeNotifier.value.name}_$useBritish')`.

#### 15. [settings_page_test.dart](../../test/settings_page_test.dart) (Modify)

* **Scope:** Settings UI, Persistence & Reload Widget Tests (`test/`)
* **Proposed Changes:** Verify the **Bible Text** section header, `'British English Spelling'` `SwitchListTile`, exact BSB deviation notice caption, `UserSettings` persistence and key deletion when reset to `false`, `AppState` cold-start sync + synchronous `DatabaseHelper` update before notifier firing, `DatabaseHelper.chapterWordsCacheLength` clearing, `ChapterManager` reload + disposal guard, and `SearchManager.init()` stale-query refresh.

### Verification Plan

* **Phase 1 Check:** `flutter analyze && flutter test test/bsb_text_localizer_test.dart`
* **Phase 2 Check:** `flutter analyze && flutter test test/bible_search_localization_test.dart test/bible_search_service_test.dart`
* **Phase 3 & Full Suite Check:** `flutter analyze && flutter test`
* **Manual Verification:** Launch app on emulator/simulator, toggle **British English Spelling** ON and OFF (including cold restart with setting ON), verify reader chapters, section heading jumps (`ChapterText._matchesHeading`) in both toggle directions, footnote dialogs, Hebrew/Greek interlinear word cards, Search (`Exact` on/off, `"his favour"`, `burnt offering`), Highlight & Note creation/toggling, and Playlist presentation & trimming.

--------------------------------------------------------------------------------

## Appendix A: Explicit British English Lookup Tables (`database.db` v31 Verified)

### 1. Contextual Verse Sets (`const Set<int>` Packed `BBCCCVVV` IDs)

* **`_nounPracticeVerses` (9 Exclusion Verses — retain `practice`; convert elsewhere to `practise`):**
  * `5027026` (Deut 27:26), `18001005` (Job 1:5), `19119056` (Ps 119:56), `26033031` (Ezek 33:31), `26033032` (Ezek 33:32), `46011016` (1 Cor 11:16), `49004019` (Eph 4:19), `50004009` (Phil 4:9), `59003016` (Jas 3:16)
* **`_verbPracticesVerses` (16 Inclusion Verses — convert `practices` -> `practises`; retain elsewhere):**
  * `5018010` (Deut 18:10), `16009029` (Neh 9:29), `19015002` (Ps 15:2), `19101007` (Ps 101:7), `23032006` (Isa 32:6), `26018024` (Ezek 18:24), `26018026` (Ezek 18:26), `28006010` (Hos 6:10), `40005019` (Matt 5:19), `43003021` (John 3:21), `62002029` (1 John 2:29), `62003004` (1 John 3:4), `62003007` (1 John 3:7), `62003008` (1 John 3:8), `66021027` (Rev 21:27), `66022015` (Rev 22:15)
* **`_storeyVerses` (3 Inclusion Verses — convert `story` -> `storey`, `stories` -> `storeys`):**
  * `26041007` (Ezek 41:7), `26042006` (Ezek 42:6), `44020009` (Acts 20:9)
* **`_pastSpitVerses` (7 Inclusion Verses — convert `spit` -> `spat`; retain present/infinitive elsewhere):**
  * `4012014` (Num 12:14), `40026067` (Matt 26:67), `40027030` (Matt 27:30), `41007033` (Mark 7:33), `41008023` (Mark 8:23), `42018032` (Luke 18:32), `43009006` (John 9:6)

### 2. Corpus Audit Additions (17 Entries Beyond Report)

| American (BSB) | British Replacement | Occurrences / Scope |
| :--- | :--- | :--- |
| `baptizes` | `baptises` | 1x (Verse) |
| `capitalized` | `capitalised` | 6x (Footnote) |
| `centimeters` | `centimetres` | 52x (Footnote) |
| `dwelled` | `dwelt` | 1x (Verse) |
| `inquiring` | `enquiring` | 3x (Verse) |
| `judgments` | `judgements` | 58x (Verse/Heading) |
| `kilometers` | `kilometres` | 18x (Footnote) |
| `liters` | `litres` | 78x (Footnote) |
| `meters` | `metres` | 144x (Footnote) |
| `organizes` | `organises` | 1x (Verse) |
| `revocalization` | `revocalisation` | 1x (Footnote) |
| `revocalizations` | `revocalisations` | 1x (Footnote) |
| `sandaled` | `sandalled` | 1x (Verse) |
| `smelled` | `smelt` | 3x (Verse) |
| `unplowed` | `unploughed` | 2x (Verse) |
| `unsandaled` | `unsandalled` | 1x (Verse) |
| `worshipers` | `worshippers` | 7x (Verse) |

### 3. Unambiguous Report Dictionary (170 Entries, Excluding `anymore`)

* **Full 170-entry American -> British map (`'american': 'british'`):**
  `among: amongst`, `armor: armour`, `armory: armoury`, `authorization: authorisation`, `authorized: authorised`, `baptize: baptise`, `baptized: baptised`, `baptizing: baptising`, `behavior: behaviour`, `beveled: bevelled`, `burned: burnt`, `canceled: cancelled`, `center: centre`, `channeled: channelled`, `chiseled: chiselled`, `clamor: clamour`, `clamoring: clamouring`, `colored: coloured`, `colorful: colourful`, `colors: colours`, `counseled: counselled`, `counselor: counsellor`, `counselors: counsellors`, `criticized: criticised`, `defense: defence`, `defenses: defences`, `defenseless: defenceless`, `demeanor: demeanour`, `disheveled: dishevelled`, `dishonor: dishonour`, `dishonorable: dishonourable`, `dishonored: dishonoured`, `dishonoring: dishonouring`, `dishonors: dishonours`, `distill: distil`, `dreamed: dreamt`, `emphasize: emphasise`, `endeavor: endeavour`, `enroll: enrol`, `favor: favour`, `favorable: favourable`, `favorably: favourably`, `favored: favoured`, `favorite: favourite`, `favoritism: favouritism`, `favors: favours`, `fertilize: fertilise`, `fervor: fervour`, `flavor: flavour`, `fulfill: fulfil`, `fulfillment: fulfilment`, `fulfills: fulfils`, `gray: grey`, `harbor: harbour`, `harbored: harboured`, `harbors: harbours`, `honor: honour`, `honorable: honourable`, `honorably: honourably`, `honored: honoured`, `honoring: honouring`, `honors: honours`, `inquire: enquire`, `inquired: enquired`, `inquires: enquires`, `inquiry: enquiry`, `install: instal`, `instill: instil`, `jeopardize: jeopardise`, `jeopardized: jeopardised`, `jewelry: jewellery`, `judgment: judgement`, `labor: labour`, `labored: laboured`, `laborer: labourer`, `laborers: labourers`, `labors: labours`, `leaped: leapt`, `learned: learnt`, `leveled: levelled`, `license: licence`, `marveling: marvelling`, `marveled: marvelled`, `marvelous: marvellous`, `mobilize: mobilise`, `mobilized: mobilised`, `mobilizing: mobilising`, `molded: moulded`, `molding: moulding`, `molds: moulds`, `moldy: mouldy`, `multicolored: multicoloured`, `mustache: moustache`, `neighbor: neighbour`, `neighboring: neighbouring`, `neighbors: neighbours`, `odor: odour`, `offense: offence`, `offenses: offences`, `organized: organised`, `paneled: panelled`, `paneling: panelling`, `paralyzed: paralysed`, `parceled: parcelled`, `plow: plough`, `plowed: ploughed`, `plowing: ploughing`, `plowman: ploughman`, `plowmen: ploughmen`, `plows: ploughs`, `plowshare: ploughshare`, `plowshares: ploughshares`, `practiced: practised`, `practicing: practising`, `pretense: pretence`, `pretenses: pretences`, `pulverized: pulverised`, `quarreled: quarrelled`, `quarreling: quarrelling`, `realize: realise`, `realized: realised`, `realizes: realises`, `realizing: realising`, `recognize: recognise`, `recognized: recognised`, `recognizes: recognises`, `recognizing: recognising`, `revelers: revellers`, `reveling: revelling`, `rumor: rumour`, `rumors: rumours`, `savior: saviour`, `savor: savour`, `scepter: sceptre`, `scepters: sceptres`, `scrutinize: scrutinise`, `shriveled: shrivelled`, `signaled: signalled`, `signaling: signalling`, `skillful: skilful`, `skillfully: skilfully`, `smolder: smoulder`, `smoldering: smouldering`, `smolders: smoulders`, `somber: sombre`, `spilled: spilt`, `splendor: splendour`, `sulfur: sulphur`, `symbolizes: symbolises`, `sympathize: sympathise`, `sympathized: sympathised`, `terrorize: terrorise`, `totaled: totalled`, `toward: towards`, `tranquility: tranquillity`, `traveled: travelled`, `traveler: traveller`, `travelers: travellers`, `traveling: travelling`, `tumor: tumour`, `tumors: tumours`, `unauthorized: unauthorised`, `valor: valour`, `vapor: vapour`, `vigor: vigour`, `willful: wilful`, `willfully: wilfully`, `worshiper: worshipper`, `worshiped: worshipped`, `worshiping: worshipping`.
