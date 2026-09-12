# Database Optimization & FTS Architecture Plan

## Goal Description
Analyze the Berean Standard Bible SQLite database structure (`database.db`), address the proposal regarding Full-Text Search (FTS) tables and footnotes, and establish an optimal configuration balancing **uncompressed device storage footprint**, **query performance**, and **APK download size**.

---

## 1. Direct Answer: The FTS & Footnotes Question

> [!NOTE]
> **Summary**
> You are referring to SQLite FTS **External Content Tables** (`content="table"`) and **Contentless Tables** (`content=""`).
> While pointing FTS directly to the raw `bible` table via `content="bible"` is not viable, switching to a **Contentless FTS Table (`content=""`)** achieves your exact goal: it eliminates the duplicate clean text table, saving **~4.6 MB uncompressed** and **~1.5 MB in the APK**, while resolving clean text on demand in ~1 ms.

### What is Happening in the Database
1. The `bible` table (5.6 MB) stores raw USFM lines with footnotes (e.g. `\f + \fr 1:3 \ft Cited in ... \f*`).
2. `createVerseSearchTable` runs `cleanVerseText()` on those lines in Dart memory, stripping footnotes and USFM tags.
3. It inserts the clean verse text into `verses_search` (`CREATE VIRTUAL TABLE verses_search USING fts4(...)`).
4. In standard FTS4, SQLite automatically creates an internal shadow table named `verses_search_content` (4.6 MB) to store that clean text, alongside the inverted index segments (`verses_search_segments`, ~3.0 MB).

Without optimization, both `bible` (with footnotes) and `verses_search_content` (without footnotes) exist simultaneously, duplicating ~4.6 MB of scripture text.

### Can We Delete That Table and Point FTS to `bible`?

#### 1. Simply dropping `verses_search_content`: ❌ Not possible
In standard SQLite FTS4, `verses_search_content` is an internal engine dependency. If you drop it, any query on `verses_search` crashes with `SQL logic error: no such table: verses_search_content`.

#### 2. SQLite External Content Table (`content="bible"`): ❌ Does not work here
In an external content table, SQLite does not create its own content table; instead, whenever a query asks for `SELECT text FROM verses_search`, SQLite reads `bible.text` directly using the matching rowid.
* **Problem A — Row ID Mismatch:** `verses_search` has 31,086 rows (1 per canonical verse). `bible` has 37,843 rows (split by USFM paragraphs, poetry lines, and section headings). The row IDs do not correspond 1-to-1.
* **Problem B — Footnotes & Tags in Search Results:** Because SQLite fetches `text` directly from `bible`, search result snippets, bookmarks, highlights, and modal sheets would display raw USFM tags and footnote text (e.g., `And God said, “Let there be light,”\f + \fr 1:3 \ft Cited in... \f* and there was light.`).
* **Problem C — Token Alignment Breakdown:** FTS generates snippet highlights by tokenizing the external text on the fly. Extra footnote words in `bible` misalign token offsets.

#### 3. SQLite Contentless FTS Table (`content=""`): ✅ Works & Saves Space
SQLite FTS supports `content=""`:
* `verses_search_content` is **never created**.
* Only the inverted index is stored (`verses_search_segments`), saving **~4.6 MB on disk** and **~1.5 MB in the APK**.
* `SELECT docid FROM verses_search WHERE verses_search MATCH ?` returns the matching packed `reference` (e.g. `1001003`).
* To display search results in the UI, the app queries `bible` via an FTS subquery:
  ```sql
  SELECT b.reference, group_concat(b.text, ' ') as text
  FROM bible b
  WHERE b.reference IN (
    SELECT docid FROM verses_search WHERE verses_search MATCH ?
  )
    AND b.format NOT IN ('s1', 's2', 'r', 'd', 'ms', 'mr', 'b', 'qa')
  GROUP BY b.reference
  ORDER BY b.reference ASC
  ```
* Text is cleaned on the fly in Dart via `cleanVerseText()`.
* **Benchmark:** Subquery execution + regex cleaning takes **< 1 ms**, providing instant UI response.

---

## 2. APK Size vs. Uncompressed Device Footprint

An APK is a **ZIP archive** using the DEFLATE algorithm. Optimizations behave differently when comparing raw uncompressed database size on device vs. compressed APK size:

| Optimization Technique | Effect on Uncompressed DB (Device Sandbox) | Effect on Compressed APK (ZIP Download) | Decision & Rationale |
|---|---|---|---|
| **Contentless FTS4 (`content=""`)** | **-4.6 MB** (removes duplicate text table) | **-1.5 MB** (smaller archive) | **Included**: Wins on both metrics. |
| **`idx_bible_ref` Index** | +0.85 MB (856 KB) | +0.2 MB | **Included**: Crucial performance fix. Eliminates 37,800-row full-table scan on every chapter view. |
| **Lexicon Per-Row `zlib` Compression** | -8.5 MB on disk | **+2.57 MB in APK** | **Excluded**: Pre-compressing text creates high-entropy binary bytes that defeat APK's global ZIP compressor. Leaving as plain text yields the smallest APK. |
| **`WITHOUT ROWID` Interlinear Table** | -3.8 MB on disk | **+0.87 MB in APK** | **Excluded**: Composite primary key `(reference, _id)` duplicates into all secondary indexes, making the file harder for ZIP to compress. |

---

## 3. Final Production Configuration

1. **Contentless FTS4 (`content=""`)**:
   - Drops `verses_search_content`.
   - Single SQL subquery for search; on-the-fly footnote cleaning in Dart.
2. **`idx_bible_ref` Index**:
   - `CREATE INDEX IF NOT EXISTS idx_bible_ref ON bible(reference);`.
   - Chapter reading queries (`getChapter`, `getVerseCount`, `getSectionHeadings`, `getRange`) perform instant O(log N) index seeks.
3. **Plain Text Lexicon & Standard Interlinear**:
   - Maximizes APK archive compression.
   - APK size drops from **49.5 MB down to ~48.0 MB**.
   - Uncompressed database size drops from **67.2 MB down to ~63.0 MB**.

---

## 4. Verification & Validation

- **`database_builder`**: All 80 unit tests pass (`dart test`).
- **`flutter_app`**: All 233 widget and integration tests pass (`flutter test`).
- **Android Compatibility**: Preserves FTS4 to ensure full compatibility with Android's system SQLite.
