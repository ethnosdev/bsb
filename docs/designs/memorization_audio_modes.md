# Memorization Audio Modes: Verse Pause & Repeat Passage

Status: **Implemented and verified** (2026-11-17).
Related: [Audio Verse Timings](audio_verse_timings.md).

---

## 1. Goal

Build on the per-verse audio timings (`audio_timings` SQLite table, `ChapterTimings`, and `BsbAudioHandler`) to add two Scripture memorization features:

1. **Pause-between-verses speed mode (`1.0x (with N second pause)`):** Play narration at `1.0x` speed while pausing a configurable number of seconds (default `5s`) *after* each verse so a user memorizing a passage can recall/quote each upcoming verse before hearing it.
2. **Repeat Passage mode & Play Mode picker sheet:** Replace tap-to-cycle on the Play Mode button with a modal bottom sheet picker (`_showPlayModePicker`), and add a **Repeat Passage** mode supporting single-chapter and cross-chapter ranges.
3. **Selection-based repeat in the reader (`More` → `Play`):** Selecting 1 verse and tapping `More` → `Play` enables **Repeat Verse**; selecting 2+ verses enables **Repeat Passage** for that range.

### Out of scope (non-goals)

- Custom playback speeds with pause (pause-between-verses always plays narration at `1.0x`).
- Automatic verse-length scaling for pauses (fixed user-selected integer seconds only).
- Pausing *before* the very first verse when starting playback (first verse plays immediately; pauses happen *after* each verse, between verses, and before looping).
- Modifying `audio_timings` data or Playlist audio playback.

---

## 2. Existing Code Reference

| Area | File | Current Behavior |
|---|---|---|
| Models | [audio_models.dart](../../flutter_app/lib/infrastructure/audio/audio_models.dart) | `AudioPlayMode` (`continuous`, `repeatChapter`, `stopAfterChapter`, `repeatVerse`), `SleepTimerOption`, `kAudioSpeedOptions`. |
| Timings | [verse_timings.dart](../../flutter_app/lib/infrastructure/audio/verse_timings.dart) | `VerseTiming` & `ChapterTimings` (`verseAt`, `timingFor`, `nextSeekTarget`, `previousSeekTarget`). |
| Audio handler | [bsb_audio_handler.dart](../../flutter_app/lib/infrastructure/audio/bsb_audio_handler.dart) | `BsbAudioHandler` wrapping `just_audio` `AudioPlayer`, `_repeatVerseTimer` (50 ms boundary loop for `repeatVerse`), `playFromVerse`, `skipToNextVerse`, `skipToPreviousVerse`. |
| Playback manager | [audio_playback_manager.dart](../../flutter_app/lib/infrastructure/audio/audio_playback_manager.dart) | UI-facing notifiers (`speedNotifier`, `playModeNotifier`, `currentVerseNotifier`, etc.), `setSpeed`, `setPlayMode`, `cyclePlayMode`, `setSleepTimer`. |
| Player sheet | [audio_player_modal_sheet.dart](../../flutter_app/lib/ui/audio/audio_player_modal_sheet.dart) | `_showSpeedPicker` & `_showSleepTimerPicker` (`showModalBottomSheet` with `ListTile` + radio icons); Play Mode chip currently calls `cyclePlayMode`. |
| Mini player | [audio_player_bottom_bar.dart](../../flutter_app/lib/ui/audio/audio_player_bottom_bar.dart) | Shows `formatDisplayTitle(mediaItem, verse)` and `Play`/`Pause`/`Skip` buttons driven by `playbackStateStream`. |
| Passage picker | [passage_range_picker_dialog.dart](../../flutter_app/lib/ui/playlists/widgets/passage_range_picker_dialog.dart) | `PassageRangePickerDialog.show(...)` returning `PassageRangePickerResult(reference, startWordId, endWordId)`. |
| Reader menu | [text_screen.dart](../../flutter_app/lib/ui/text/text_screen.dart) | `_handleMore(Reference reference)` handles `play` for text selections. |
| Settings | [user_settings.dart](../../flutter_app/lib/ui/settings/user_settings.dart) | Persists `_audioSpeedKey`, `_audioPlayModeKey`, `_audioSyncTextKey`, and last audio position in `SharedPreferences`. |

---

## 3. UX & Product Behavior

### 3.1 Speed Sheet: `1.0x (with N second pause)`

- The Speed modal bottom sheet (`_showSpeedPicker`) keeps `0.75x`, `1.0x (Normal)`, `1.25x`, `1.5x`, `1.75x`, `2.0x` and adds a row labeled **`1.0x (with N second pause)`** (default `N = 5`).
- Selecting any standard speed turns verse-pause off and sets player speed to that rate.
- Tapping `1.0x (with N second pause)` activates `1.0x` playback speed with between-verse pauses enabled and reveals an **inline duration selector** inside the same bottom sheet:
  - Quick preset chips (e.g., `3s`, `5s`, `8s`, `10s`, `15s`) and `-` / `+` 1-second stepper buttons (clamped to `1..60` seconds).
  - Adjusting `N` updates `UserSettings`, `AudioPlaybackManager`, and the row label live without closing the sheet.
- **Speed chip label:** Displays `1.0x (${N}s)` (e.g. `1.0x (5s)`) when pause-between-verses is active; otherwise `${speed}x`.

### 3.2 Timing & Countdown Feedback During Pause

- **First verse:** Plays immediately on start (no leading pause before the first verse).
- **Between verses:** When a verse finishes (`position >= timing.end`), playback enters the **verse-pause phase** for `N` seconds before playing the next verse.
- **Looping:** In `Repeat Verse`, `Repeat Passage`, and `Repeat Chapter`, playback also pauses `N` seconds *after* the final verse of the loop before jumping back to the start of the loop.
- **Exception (`1 Chapter` / `stopAfterChapter`):** When the final verse of the chapter finishes, playback stops immediately rather than waiting `N` seconds just to stop.
- **Player state & display during pause:**
  - The Play/Pause control stays in the **Playing** state (`Icons.pause`) so tapping Pause cancels/freezes playback cleanly rather than confusing the user into thinking playback stopped.
  - Both [`AudioPlayerModalSheet`](../../flutter_app/lib/ui/audio/audio_player_modal_sheet.dart) and [`AudioPlayerBottomBar`](../../flutter_app/lib/ui/audio/audio_player_bottom_bar.dart) show the **upcoming** verse reference and a subtle countdown label (e.g., `Next verse in 4s...`), and `MediaItem.artist` updates for lock-screen / notification visibility.
  - `currentVerseNotifier` advances to the upcoming verse reference during the pause so the text highlight (if synced/viewed) reflects what is about to play.
- **Interruptions during pause:**
  - **Pause:** Cancels the pause countdown and leaves the player genuinely paused at the upcoming verse's `start` timestamp; tapping Play later resumes immediately from that upcoming verse.
  - **Prev Verse / Next Verse / Seek / Chapter Skip:** Cancels the pause countdown and immediately seeks/plays the requested target.
  - **Sleep Timer expiry:** Cancels the pause countdown and stops playback cleanly.

### 3.3 Background / Screen-Off Playback Support

Calling `_player.pause()` alone on `just_audio` for `N` seconds emits `playing = false` to `audio_service` and allows iOS `AVAudioSession` / Android media service to treat playback as paused or suspend the process when the screen locks.

To keep screen-off memorization reliable:
- Keep `just_audio` pre-seeked & paused on the chapter MP3 while a dedicated lightweight companion `AudioPlayer` plays a bundled genuine silent PCM asset (`assets/audio/silence.wav`, looped) for the duration of the `N`-second countdown.
- `BsbAudioHandler` continues emitting `playing: true, processingState: AudioProcessingState.ready` on `playbackState` during the countdown.
- See Section 4.3 for audio-focus and pre-seek details so chapter narration resumes instantaneously with zero network re-buffering.

### 3.4 Play Mode Popup Sheet & `Repeat Passage`

- Tapping the Play Mode chip in `AudioPlayerModalSheet` opens a modal bottom sheet (`_showPlayModePicker`) matching `_showSpeedPicker` and `_showSleepTimerPicker` (drag handle, title, `ListTile` items with radio icons):
  1. `Continuous`
  2. `Repeat Chapter`
  3. `1 Chapter`
  4. `Repeat Verse`
  5. `Repeat Passage` (with active passage subtitle e.g. `Romans 8:31–39`, plus a trailing `Edit` button when configured)
- **Selecting `Repeat Passage` in the sheet:**
  - Opens [`PassageRangePickerDialog.show(...)`](../../flutter_app/lib/ui/playlists/widgets/passage_range_picker_dialog.dart) pre-filled with either the existing saved Repeat Passage range or the currently playing `(bookId, chapter, currentVerse)`.
  - If a Repeat Passage range is already saved and the user taps `Repeat Passage` while on another mode, switching activates the saved range (or tapping the trailing `Edit` button / tapping `Repeat Passage` while already selected opens `PassageRangePickerDialog` to change it).
  - Supports both **single-chapter** ranges (e.g., `Romans 8:31–39`) and **cross-chapter** ranges (e.g., `Romans 8:28–9:5`).
  - Once confirmed, sets mode to `repeatPassage`, persists the range, and jumps/starts playing at the passage's start verse (if not already playing inside that passage).
- **Play Mode chip label:** Shows compact reference via `bookIdToAbbreviationMap` when `repeatPassage` is active (e.g., `Rom 8:31–39` or `Rom 8:28–9:5`), or `Repeat Passage` if unset.
- **Exiting `Repeat Passage`:**
  - Switching to another Play Mode in `_showPlayModePicker`.
  - Pressing chapter Prev/Next (`skip_previous` / `skip_next`), which switches `repeatPassage` back to `continuous`.
- **Persistence:** Both the verse-pause settings (`enabled`, `seconds`) and `repeatPassage` range persist across app restarts via `SharedPreferences`.

### 3.5 Reader Selection (`More` → `Play`)

In [`text_screen.dart`](../../flutter_app/lib/ui/text/text_screen.dart), when the user selects text and taps `More` → `Play`:

- **Single verse selected** (no `endVerse`/`endChapter`, or `endVerse == verse` in the same chapter):
  - Sets Play Mode to `AudioPlayMode.repeatVerse` and calls `playFromVerse(reference.bookId, reference.chapter, reference.verse ?? 1)`.
- **Multiple verses selected** (`endChapter > chapter`, or `endVerse > verse`):
  - Sets `repeatPassage` to `reference`, sets Play Mode to `AudioPlayMode.repeatPassage`, and plays starting from `(reference.bookId, reference.chapter, reference.verse ?? 1)`.
- Normal continuous playback continues to be started from the chapter play button or by selecting `Continuous` in `_showPlayModePicker`.

---

## 4. Technical Architecture

### 4.1 Models (`audio_models.dart`)

Add `repeatPassage` to `AudioPlayMode`:

```dart
enum AudioPlayMode {
  continuous('Continuous', Icons.repeat),
  repeatChapter('Repeat Chapter', Icons.repeat_one),
  stopAfterChapter('1 Chapter', Icons.stop_circle_outlined),
  repeatVerse('Repeat Verse', Icons.replay),
  repeatPassage('Repeat Passage', Icons.repeat_on);
  // ...
}
```

Add `VersePauseState` and pause duration constants:

```dart
class VersePauseState {
  final bool isPaused;
  final int remainingSeconds;
  final int totalSeconds;
  final int? nextVerseRef; // packed BBCCCVVV

  const VersePauseState({
    this.isPaused = false,
    this.remainingSeconds = 0,
    this.totalSeconds = 5,
    this.nextVerseRef,
  });

  static const idle = VersePauseState();
}

const int kDefaultVersePauseSeconds = 5;
const int kMinVersePauseSeconds = 1;
const int kMaxVersePauseSeconds = 60;
const List<int> kVersePausePresetSeconds = [3, 5, 8, 10, 15];
```

Add `Reference? repeatPassage` formatting helpers (compact chip display using `bookIdToAbbreviationMap`, e.g., `Rom 8:31–39` vs `Reference.toString()` for full display).

### 4.2 Settings Persistence (`user_settings.dart`)

Add `SharedPreferences` keys:
- `_audioPauseBetweenVersesEnabledKey = 'audio_pause_between_verses_enabled'` (`bool`, default `false`)
- `_audioPauseBetweenVersesSecondsKey = 'audio_pause_between_verses_seconds'` (`int`, default `5`, clamped `1..60`)
- `_audioRepeatPassageStartVerseKey = 'audio_repeat_passage_start_verse'` (`int?`, packed `BBCCCVVV`)
- `_audioRepeatPassageEndVerseKey = 'audio_repeat_passage_end_verse'` (`int?`, packed `BBCCCVVV`)

Storing packed `BBCCCVVV` integers lets `Reference.fromVerseId(packedInt: start, packedIntEnd: end)` round-trip both single-chapter and cross-chapter passages cleanly with validation (`start <= end`, valid `bookId`, chapter within `bookIdToChapterCountMap`). If stored IDs are invalid or missing, clear them and fall back to `AudioPlayMode.continuous` if `repeatPassage` was saved.

### 4.3 Background-Safe Silent Pause Engine (`bsb_audio_handler.dart`)

1. **Bundled silence asset:** Add a tiny 1-second silent PCM WAV file at `flutter_app/assets/audio/silence.wav` and declare it in `flutter_app/pubspec.yaml` under `flutter.assets`.
2. **Companion `_silencePlayer`:**
   - Instantiate `AudioPlayer(handleInterruptions: false, androidApplyAudioAttributes: false)` so it does not compete with `_player`'s `AudioSession` interruption handling.
   - Preload `AssetAudioSource` / `setAsset('assets/audio/silence.wav')` with `LoopMode.one` lazily on first pause-mode activation (guarding initialization in tests or platforms without audio plugins if needed).
3. **Transition into verse pause (`_enterVersePause`):**
   - Triggered by the 50 ms boundary watcher when `currentPosition >= activeVerse.end` and `pauseBetweenVersesEnabled == true` (except when finishing the last verse under `stopAfterChapter` or `SleepTimerOption.endOfChapter`).
   - Compute the next target `(nextBookId, nextChapter, nextVerse, nextSeekPosition)`:
     - **`repeatVerse`:** `(currentBookId, currentChapter, currentVerse, currentVerseTiming.start)`.
     - **`repeatPassage` (not at end of passage):**
       - If more verses exist in the current chapter, next verse in `_currentTimings`.
       - If at end of current chapter and `currentChapter < passageEndChapter`, load `currentChapter + 1` and seek to its verse `1` `start`.
     - **`repeatPassage` (at end of passage):** `(passage.bookId, passage.chapter, passageStartVerse, passageStartTiming.start)`.
     - **`repeatChapter` (at last verse):** `(currentBookId, currentChapter, firstVerse, firstVerseTiming.start)`.
     - **`continuous` / `stopAfterChapter` (mid-chapter):** next verse in `_currentTimings`.
     - **`continuous` (at last verse):** next chapter `(nextBookId, nextChapter, 1, Duration.zero)` (standard chapter advance).
   - Prepare the next position while paused:
     - Same chapter: `await _player.pause()`, `await _player.seek(nextSeekPosition)`.
     - Different chapter (e.g., cross-chapter passage loop or advance): load the target chapter source in paused state and seek directly to the target verse start (for passage verse 1 or passage start verse) or `Duration.zero` (for continuous chapter advance).
   - Start `_silencePlayer.play()` and emit `_isInVersePause = true` + `VersePauseState(isPaused: true, remainingSeconds: N, totalSeconds: N, nextVerseRef: nextPackedVerse)`.
   - Force `playbackState` update so `playing == true` remains active for UI + lock screen.
   - Start a 1-second periodic `Timer` decrementing `remainingSeconds` (and updating `MediaItem.artist` e.g. `'Next: John 10:15 (4s)'`).
   - When `remainingSeconds` reaches `0`:
     - Stop `_silencePlayer`, reset `VersePauseState.idle`, and call `_player.play()` — audio starts immediately from the pre-seeked target verse.
4. **Speed interaction:**
   - When `pauseBetweenVersesEnabled` turns on, enforce `_player.setSpeed(1.0)`.
   - When `setSpeed(speed)` is called from normal speed options, disable `pauseBetweenVersesEnabled` (cancelling any active verse pause first and resuming or staying cleanly at current state) and apply `speed`.
5. **Cancellation helper (`_cancelVersePause({bool updateState = true})`):**
   - Stops countdown timer, pauses/stops `_silencePlayer`, clears `_isInVersePause`, resets `VersePauseState.idle`.
   - Called unconditionally by `pause()`, `stop()`, `seek()`, `skipToPreviousVerse()`, `skipToNextVerse()`, `skipToPrevious()`, `skipToNext()`, `playFromVerse()`, and `playChapter()`.
   - When `pause()` is called *during* a verse pause, `_player` is already pre-seeked to the upcoming verse's `start`, so `pause()` cancels `_silencePlayer` + timer and emits `playing: false` cleanly. Calling `play()` next resumes right at the upcoming verse.

### 4.4 Boundary Polling & `repeatPassage` Enforcement (`bsb_audio_handler.dart`)

Replace `_repeatVerseTimer` with a unified `_verseBoundaryTimer` (50 ms interval) active whenever `_currentTimings != null` and `_player.playing` (and not already in `_isInVersePause`), OR when `playMode == repeatVerse`, `playMode == repeatPassage`, or `pauseBetweenVersesEnabled == true`:

1. **Determine current/active verse:**
   - Track `_activeVerseTiming` using `_currentTimings.verseAt(position)` (remembering if `position < verses.first.start` during a chapter announcement before verse 1).
2. **Boundary checks per mode:**
   - **`repeatVerse`:** When `_lockedVerse` reaches `timing.end`:
     - If `pauseBetweenVersesEnabled`, enter `_enterVersePause` targeting `_lockedVerse.start`.
     - Otherwise seek directly back to `_lockedVerse.start`.
   - **`repeatPassage`:** Let `endChapter = passage.endChapter ?? passage.chapter`, `endVerse = passage.endVerse ?? passage.verse ?? _currentTimings.verses.last.verse`, `startVerse = passage.verse ?? 1`:
     - On `currentChapter == endChapter`, if position reaches `timingFor(endVerse).end`:
       - Target is passage start `(passage.bookId, passage.chapter, startVerse)`.
       - If `pauseBetweenVersesEnabled`, enter `_enterVersePause` to passage start; otherwise jump immediately (seek if `passage.chapter == currentChapter`, or load & seek if cross-chapter).
     - On `currentChapter < endChapter`, if position reaches `_currentTimings.verses.last.end`:
       - Target is `(passage.bookId, currentChapter + 1, 1)` skipping chapter announcement (`verse 1.start`) so multi-chapter passages flow cleanly.
       - If `pauseBetweenVersesEnabled`, enter `_enterVersePause`; otherwise advance immediately.
   - **Verse-to-verse pause (`continuous`, `repeatChapter`, `stopAfterChapter`) when `pauseBetweenVersesEnabled`:**
     - Watch the active verse's `end`. On crossing `end`:
       - If it is the last verse of the chapter:
         - `stopAfterChapter` → stop chapter cleanly.
         - `repeatChapter` → `_enterVersePause` targeting verse `1` of current chapter.
         - `continuous` → if next chapter exists, `_enterVersePause` targeting next chapter; else stop cleanly.
       - Otherwise → `_enterVersePause` targeting the next verse in `_currentTimings`.
3. **Chapter announcement handling:**
   - When playing a chapter from `Duration.zero` in `continuous` / `repeatChapter` / `stopAfterChapter`, position `0..verses.first.start` is the spoken chapter announcement; `verseAt` only triggers verse-end transitions once playback has entered a verse (`activeVerse != null`).
4. **Verse skip buttons (`fast_rewind` / `fast_forward`) in `repeatPassage`:**
   - Within the passage: skip to previous/next verse normally.
   - At passage start (`skipToPreviousVerse`) or passage end (`skipToNextVerse`): clamp/wrap cleanly inside the passage (e.g., `Next Verse` at `endVerse` wraps to `startVerse`; `Previous Verse` at `startVerse` seeks to `startVerse`).
   - Chapter skip buttons (`skip_previous` / `skip_next`): exit `repeatPassage` back to `continuous` and skip chapters as normal.

### 4.5 `AudioPlaybackManager` Additions (`audio_playback_manager.dart`)

Expose reactive state to UI widgets:
- `ValueNotifier<bool> pauseBetweenVersesEnabledNotifier`
- `ValueNotifier<int> pauseBetweenVersesSecondsNotifier`
- `ValueNotifier<VersePauseState> versePauseStateNotifier`
- `ValueNotifier<Reference?> repeatPassageNotifier`

Add methods:
- `Future<void> setPauseBetweenVerses({required bool enabled, int? seconds})`
- `Future<void> setRepeatPassage(Reference passage, {bool playImmediately = true})`
- Update `setSpeed(double speed)` to ensure `pauseBetweenVersesEnabledNotifier.value = false`.
- Update `setPlayMode(AudioPlayMode mode)`:
  - When switching away from `repeatVerse` / `repeatPassage` / etc., persist `_audioPlayModeKey`.
  - Expose helper `Future<void> playSelection(Reference reference)`:
    - Determines single-verse vs multi-verse selection, sets `repeatVerse` or `repeatPassage`, and plays from `(reference.bookId, reference.chapter, reference.verse ?? 1)`.
- Update `formatDisplayTitle(MediaItem? item, int? currentVerse)` (and countdown/subtitle helper) so UI shows upcoming verse during verse-pause cleanly without duplicating formatting logic across bottom bar and modal sheet.

### 4.6 `PassageRangePickerDialog` Reuse (`passage_range_picker_dialog.dart`)

Add optional `String? confirmButtonText` parameter to `PassageRangePickerDialog` and `PassageRangePickerDialog.show(...)`:
- Defaults to current behavior (`widget.initialReference == null ? 'Add to Playlist' : 'Save Reference'`).
- When called from Audio Play Mode picker, pass `confirmButtonText: 'Repeat Passage'`.

### 4.7 UI Changes (`audio_player_modal_sheet.dart`, `audio_player_bottom_bar.dart`, `text_screen.dart`)

1. **`_showSpeedPicker` (`audio_player_modal_sheet.dart`):**
   - Render `kAudioSpeedOptions` rows.
   - Render `1.0x (with $seconds second pause)` row below `1.0x (Normal)` (or at the bottom of the list).
   - Use `ValueListenableBuilder`s inside the bottom sheet so selecting/tapping it expands the inline duration controls (`kVersePausePresetSeconds` `ChoiceChip`s + `-` / `+` `IconButton`s).
2. **`_showPlayModePicker` (`audio_player_modal_sheet.dart`):**
   - Replace `onPressed: manager.cyclePlayMode` on the Play Mode `OutlinedButton.icon` chip with `onPressed: () => _showPlayModePicker(context)`.
   - Bottom sheet mirrors `_showSpeedPicker` / `_showSleepTimerPicker` styling (`showModalBottomSheet`, drag handle, `'Repeat Mode'` title, `ListTile` list).
   - For `AudioPlayMode.repeatPassage`:
     - Show saved passage range as subtitle if present.
     - Trailing edit icon (`Icons.edit`) opens `PassageRangePickerDialog.show(...)` pre-filled with existing passage or current `(bookId, chapter, currentVerse)`.
     - Tapping the `Repeat Passage` row when no range exists (or when already selected) opens `PassageRangePickerDialog.show(...)`; tapping it when switching back from another mode activates the saved range (or prompts if none).
3. **Countdown indicator (`audio_player_modal_sheet.dart` & `audio_player_bottom_bar.dart`):**
   - Observe `manager.versePauseStateNotifier`: when `isPaused`, show subtle badge/subtitle e.g. `Next verse in ${remainingSeconds}s...` and display the upcoming verse reference (`nextVerseRef`).
   - Do not show `Buffer` / `Paused` play icon while `isPaused` in verse pause; keep the Pause button shown so tapping it pauses playback.
4. **Reader `More` → `Play` (`text_screen.dart`):**
   - Update `case 'play':` in `_handleMore(Reference reference)` to call `getIt<AudioPlaybackManager>().playSelection(reference)`.

---

## 5. Phased Implementation Plan

1. **Phase 1 — Assets, Models & Settings:**
   - Create `flutter_app/assets/audio/silence.wav` and declare it in `flutter_app/pubspec.yaml`.
   - Update `audio_models.dart` (`AudioPlayMode.repeatPassage`, `VersePauseState`, pause constants, compact formatting helper).
   - Update `user_settings.dart` with pause-between-verses and repeat-passage getters/setters + validation.
2. **Phase 2 — Audio Engine & Manager:**
   - Implement unified `_verseBoundaryTimer`, `_enterVersePause`, `_silencePlayer` lifecycle, and single/cross-chapter `repeatPassage` handling in `bsb_audio_handler.dart`.
   - Update `audio_playback_manager.dart` with new notifiers, `setPauseBetweenVerses`, `setRepeatPassage`, `playSelection`, and title/countdown formatting.
3. **Phase 3 — UI & Selection Wiring:**
   - Add optional `confirmButtonText` to `passage_range_picker_dialog.dart`.
   - Update `_showSpeedPicker`, add `_showPlayModePicker`, update Play Mode chip label, and add verse-pause countdown UI in `audio_player_modal_sheet.dart` and `audio_player_bottom_bar.dart`.
   - Wire `_handleMore` → `play` in `text_screen.dart` to `playSelection`.
4. **Phase 4 — Verification & Docs:**
   - Add unit & widget tests in:
     - `flutter_app/test/audio_playback_manager_test.dart`
     - `flutter_app/test/audio_player_ui_test.dart`
     - `flutter_app/test/text_menu_more_test.dart`
     - Dedicated handler / settings unit tests as needed.
   - Run `flutter analyze` and `flutter test`.
   - Update `CHANGELOG.md` and mark this design doc implemented.
