# Memorization Audio Modes: Verse Pause, Context & Repeat Controls

Status: **Implemented and verified** (2026-11-18).
Related: [Audio Verse Timings](audio_verse_timings.md).

---

## 1. Goal

Build on the per-verse audio timings (`audio_timings` SQLite table, `ChapterTimings`, and `BsbAudioHandler`) to provide clean Scripture memorization and flexible playback control:

1. **Pause-between-verses speed mode (`1.0x (with N second pause)`):** Play narration at `1.0x` speed while pausing a configurable number of seconds (default `5s`) *after* each verse so a user memorizing a passage can recall/quote each upcoming verse before hearing it.
2. **Orthogonal Context & Repeat popup pickers:** Replace Play Mode tap-cycling with two modal bottom sheet pickers:
   - **Context** (`AudioPlayContext`: `chapter`, `range`, `verse`) — defines the active playback unit (`Chapter`, compact range like `ROM 8:31–39`, or `Verse 14`). `Range` is shown only when a multi-verse selection was set in the current session.
   - **Repeat** (`AudioRepeatBehavior`: `continueOn`, `stop`, `repeat`) — defines what happens when reaching the end of the active Context unit: keep playing past it across chapters (`Continue`), stop once finished (`Stop`), or loop the unit (`Repeat`).
3. **Natural entry points (`More` → `Play` vs AppBar `Play Audio`):**
   - Long-press text selection `More` → `Play` plays the selected single verse or range **once** (`Context = Verse` or `Range`, `Repeat = Stop`).
   - AppBar `Play Audio` enters `Chapter` context and restores the saved chapter-level `Repeat` preference (default `Continue`).

Together, these two axes cover all 7 natural behaviors:
- Verse once (`Verse` + `Stop`)
- Range once (`Range` + `Stop`)
- Chapter once (`Chapter` + `Stop`)
- Repeat verse (`Verse` + `Repeat`)
- Repeat range (`Range` + `Repeat`)
- Repeat chapter (`Chapter` + `Repeat`)
- Continuous across chapters (`Chapter` + `Continue`)

---

## 2. Architecture & Behavior

### 2.1 Models (`audio_models.dart`)

- **`AudioPlayContext`**: `chapter`, `range`, `verse`.
- **`AudioRepeatBehavior`**: `continueOn` (`Continue`), `stop` (`Stop`), `repeat` (`Repeat`), with `fromString` migrating legacy storage values (`'continuous'`, `'repeatChapter'`, `'stopAfterChapter'`).
- **`VersePauseState` & constants**: `kDefaultVersePauseSeconds = 5`, `kMinVersePauseSeconds = 1`, `kMaxVersePauseSeconds = 60`, `kVersePausePresetSeconds = [3, 5, 8, 10, 15]`, and `formatCompactPassageReference(Reference)`.

### 2.2 Persistence (`user_settings.dart`)

- Persists `_audioPauseBetweenVersesEnabledKey`, `_audioPauseBetweenVersesSecondsKey`, and chapter-level `_audioPlayModeKey` (`AudioRepeatBehavior.toStorageString()`).
- Transient `Verse` / `Range` selections are session-scoped and are not restored across app restarts; changing `Repeat` while in `Verse` or `Range` context does not overwrite the saved chapter-level preference.

### 2.3 Background-Safe Silent Pause Engine (`bsb_audio_handler.dart`)

- Bundles 1-second silent PCM audio at [`silence.wav`](../../flutter_app/assets/audio/silence.wav) (declared in [`pubspec.yaml`](../../flutter_app/pubspec.yaml)).
- Uses a non-blocking `_playFireAndForget(...)` helper (since `just_audio`'s `AudioPlayer.play()` returns a `Future` that completes only when playback stops/pauses).
- When entering verse pause (`_enterVersePause`):
  1. Immediately pauses and pre-seeks the main narrator `_player` to the upcoming verse's `start` timestamp.
  2. Broadcasts `PlaybackState.playing = true` and countdown `VersePauseState` (`Next verse in Ns...` in UI and lock-screen `MediaItem.artist`).
  3. Plays `silence.wav` in `LoopMode.one` via a dedicated companion player (`handleInterruptions: false, androidApplyAudioAttributes: false`) to keep iOS/Android background audio sessions active when locked.
- Guards against minor backward MP3 frame-alignment jitter (`<500 ms`) when resuming at verse boundaries so boundaries do not double-pause.

### 2.4 Boundary Transitions (`bsb_audio_handler.dart` & `audio_playback_manager.dart`)

- **`Continue` past `Verse` or `Range`:** When playback crosses past the end of a `Verse` or `Range` under `AudioRepeatBehavior.continueOn`, Context automatically switches to `AudioPlayContext.chapter` so the chip accurately reflects continuous multi-chapter playback.
- **`Stop` with verse pauses:** `Stop` pauses immediately when reaching the end of the active unit (verse, range, or chapter) with no trailing pause, seeking cleanly back to the start of that unit.
- **Chapter Prev/Next (`skipToPrevious` / `skipToNext`):** Clears any session `Range`, resets Context to `Chapter`, and restores `defaultChapterRepeat`.

### 2.5 Player & Reader UI

- [`AudioPlayerModalSheet`](../../flutter_app/lib/ui/audio/audio_player_modal_sheet.dart):
  - Simplified header/footer chrome (drag handle only; removed Collapse button, `"Audio Player"` title, Sync Text button, and `"Go to Chapter"` button).
  - Displays Speed, Sleep, Context, and Repeat chips in a centered `Wrap` row.
  - Speed sheet includes `1.0x (with N second pause)` with inline duration stepper/preset chips.
  - Context sheet shows `Chapter`, `Range` (only when a session range is active), and `Verse`.
  - Repeat Mode sheet shows `Continue`, `Stop`, and `Repeat` with dynamic unit descriptions (e.g., `Stop after Verse 14`, `Repeat ROM 8:31–39`).
  - Countdown banner (`Next verse in Ns...`) displays in both the expanded sheet and [`AudioPlayerBottomBar`](../../flutter_app/lib/ui/audio/audio_player_bottom_bar.dart).
- **Tab-Bound Automatic Syncing ([`HomePage`](../../flutter_app/lib/ui/home/home.dart), [`TabManager`](../../flutter_app/lib/ui/tabs/tab_manager.dart), [`ChapterText`](../../flutter_app/lib/ui/text/chapter/chapter_text.dart)):**
  - Removed the manual Sync Text toggle (`syncTextNotifier` / `_audioSyncTextKey`); syncing follows playback automatically.
  - Tracks `audioTabIdNotifier` so chapter advances update only the tab where audio was started (leaving additional open tabs undisturbed), and closing that tab stops/closes the audio player.
  - Navigating away inside the audio-playing tab pauses chapter syncing and displays a floating **`Return to chapter N`** (or **`Return to <Book> N`**) `ActionChip` that returns the tab and re-enables syncing.
- [`TextScreen`](../../flutter_app/lib/ui/text/text_screen.dart):
  - Selection `More` → `Play` calls `AudioPlaybackManager.playSelection(reference)`.
