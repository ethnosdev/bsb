# Feature Specification: Chapter Tabs (Unified Root Scaffold)

## 1. Overview & Goal

Enable seamless multi-location Bible reading through a persistent, browser-like tab system in the AppBar. Tabs allow quick switching between cross-references and study passages while preserving memory efficiency and avoiding navigation stack clutter.

---

## 2. Core User Experience & Behavior

### 2.1. Chip Display & Abbreviations
* **Chip Labels**: 3-character book abbreviation + chapter number (e.g., `GEN 1`, `ROM 8`, `1CO 13`).
* **Close Button (`x`)**:
  * Only the **currently active chip** displays an `x` button.
  * Inactive chips show only the label (saving width and preventing accidental touches).
  * The composite chip does not have an `x` button.
* **Tapping Chips**:
  * Tapping an **inactive chip** switches to that tab.
  * Tapping the **active chip** (outside the `x`) opens the `ChapterChooser` overlay for that book.
  * Tapping `x` closes the active tab.

### 2.2. Overflow & Composite Chip
* The AppBar uses responsive width detection (`LayoutBuilder` / width measuring).
* As long as all chips and the `+` button fit within the available AppBar width, individual chips are displayed.
* When space runs out, the individual chips collapse into a **single composite chip** indicating the active chapter plus the count of additional open tabs (e.g., `[ ROM 8  +4 ]`).
* **Composite Chip Modal**:
  * Tapping the composite chip opens a modal bottom sheet listing all open chapters (displaying full book names, e.g., "Romans 8").
  * Tapping an item switches to that chapter and dismisses the sheet.
  * Swiping an item away (`Dismissible`) closes that tab.
  * If the number of open tabs drops below the overflow threshold, the AppBar automatically expands back to individual chips.

### 2.3. Swiping & Navigation
* Horizontal swiping in the chapter reader advances to the previous/next chapter in the Bible as before.
* Swiping updates the active tab's book and chapter **in place** (e.g., `GEN 1` updates to `GEN 2`).

### 2.4. Adding Tabs & Duplicate Handling
* The AppBar includes a persistent `+` action button.
* Tapping `+` displays the `BookChooser` full-screen below the AppBar.
* If the user picks a chapter that is **already open**, the app switches focus to that existing tab rather than creating a duplicate.
* If a duplicate occurs naturally via chapter swiping during a session, it is tolerated in-memory. However, upon session persistence, the list is deduplicated so app restarts always have unique tabs.
* While the `BookChooser` is displayed via `+`, tapping any existing chip in the AppBar or tapping the cancel button returns to the active reading tab.

### 2.5. Tab Closure & LRU History Fallback
* When an active tab is closed, the app switches focus to the **most recently visited tab** (LRU history stack).
* When all tabs are closed (0 tabs), the AppBar shows the default `"Berean Standard Bible"` title with drawer hamburger icon, and the main body shows `BookChooser`.

---

## 3. Architecture & State Management

### 3.1. Unified Root Scaffold
* Eliminate `Navigator.push`/`pop` between `HomePage` and `TextScreen`.
* A single root `Scaffold`:
  * **AppBar**: Shows drawer icon or chips row / composite chip + `+` button.
  * **Body**: Toggles between:
    1. `BookChooser` (when 0 tabs are open or `isAddingTab == true`).
    2. `ChapterText` / `PageView` (for the active tab).
  * **Bottom Menu Bar**: Preserved when text is selected (highlights, notes, copy, original languages).

### 3.2. Lightweight `TabManager`
* Registered in `service_locator.dart` and `AppState`.
* **Model**:
  ```dart
  class BibleTab {
    final String id;
    int bookId;
    int chapter;
    double scrollOffset;

    String get label => '${bookIdToAbbreviationMap[bookId]} $chapter';
  }
  ```
* **State**:
  * `List<BibleTab> tabs`: Ordered list of open tabs.
  * `String? activeTabId`: Current tab ID.
  * `List<String> history`: Stack of recently focused tab IDs for LRU fallback.
  * `bool isAddingTab`: Flag toggled when `+` is tapped.
* **Memory Optimization**:
  * Only the active tab (or active ± 1 in the `PageView`) has a mounted widget tree.
  * Inactive tabs exist strictly as lightweight data models in memory.
* **Persistence**:
  * Serialized to `SharedPreferences` as a JSON string on any tab mutation (add, close, switch, swipe).
  * Automatically deduplicated prior to writing to storage.
  * Restored on app startup so users resume directly where they left off.

---

## 4. Implementation Steps

1. **Data Layer**:
   - Invert `bookAbbreviationToIdMap` to create `bookIdToAbbreviationMap`.
   - Implement `BibleTab` model and `TabManager` with persistence and LRU history.
2. **UI Components**:
   - Build `ChapterChip` with active/inactive states and close button.
   - Build `CompositeChapterChip` with modal bottom sheet using `Dismissible`.
   - Build responsive `ChapterChipsBar` with overflow measurement.
3. **Scaffold Unification**:
   - Refactor root screen to host both `BookChooser` and `TextScreen` views under the unified AppBar.
   - Connect chapter swipe listener to `TabManager.updateActiveChapter`.
   - Connect session restore on launch.
