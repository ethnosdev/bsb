# 🧪 Highlighting & Notes Manual Testing Guide

Use this checklist to manually test and verify the highlighting and note-taking features in the BSB app.

---

## 1. Basic Highlighting

- [ ] **Create a highlight:**
  1. Long-press any word in a verse (the entire verse will be selected, and the bottom bar will slide up).
  2. Tap **Highlight** on the bottom bar.
  3. Pick a color (e.g., **Yellow**).
  4. **Verify:** The selection clears automatically, and the text is painted with a continuous, smooth yellow highlight that covers both the words and the spaces between them.
- [ ] **Multi-word / Handle dragging:**
  1. Long-press to select a verse.
  2. Drag the start or end handles to select only a few words across a line break.
  3. Highlight in **Green**.
  4. **Verify:** Only the selected words are highlighted.

---

## 2. Overlap & Override Logic (Stress Testing)

- [ ] **Override tail:**
  1. Highlight words 1–10 in **Yellow**.
  2. Select words 7–15 and highlight in **Blue**.
  3. **Verify:** Words 1–6 remain Yellow; words 7–15 become Blue.
- [ ] **Middle split:**
  1. Highlight a long sentence in **Green**.
  2. Select 2–3 words right in the middle and highlight in **Pink**.
  3. **Verify:** The highlight cleanly splits into three sections (Green → Pink → Green).
- [ ] **Same-color merge:**
  1. Highlight words 1–5 in **Yellow**.
  2. Select words 4–10 and highlight in **Yellow**.
  3. **Verify:** They merge into a single seamless Yellow highlight (words 1–10).

---

## 3. Clearing / Removing Highlights

- [ ] **Clear partial highlight:**
  1. Select a section of an existing highlight.
  2. Tap **Highlight** → tap the **Clear** button (circle with the reset/slash icon).
  3. **Verify:** Only the selected portion of the highlight disappears, leaving any unselected portions intact.

---

## 4. Notes Creation & Inline Marker

- [ ] **Create a note:**
  1. Select a verse or phrase.
  2. Tap **Note** on the bottom bar.
  3. **Verify:** The modal sheet opens showing the reference header (e.g. *Genesis 1:1*), an italicized preview of the selected text, and a focused text field.
  4. Type a short note and tap **Save**.
  5. **Verify:** An inline note marker (`✎`) appears immediately next to the end of the selected passage.
- [ ] **Tap note marker to view/edit:**
  1. Single-tap the `✎` icon directly.
  2. **Verify:** The note sheet opens with your previous content loaded.
  3. Edit the text and tap **Save**.
- [ ] **Delete a note:**
  1. Tap the `✎` icon.
  2. Tap the **Trash can** icon in the top right of the sheet.
  3. **Verify:** The note is deleted and the `✎` marker disappears from the text.

---

## 5. Interaction, Touch Targets & Coexistence

- [ ] **Enlarged Note Touch Target (44×44 dp):**
  1. Without zooming in, tap the `✎` icon directly with your thumb or finger.
  2. **Verify:** The hit target is generous (44×44 dp touch box) and easily triggers on the first attempt without needing pinpoint precision.
- [ ] **Note + Highlight on same verse:**
  1. Add both a highlight and a note to the same verse.
  2. **Verify:** The text is highlighted and the `✎` marker sits neatly at the end of the phrase.
- [ ] **Selection over existing highlight:**
  1. Long-press on an already-highlighted verse.
  2. **Verify:** The semi-transparent selection layer overlays the highlight without flickering or obstructing the text.
- [ ] **Footnotes and Notes together (Direct Taps vs Word Taps):**
  1. Find a verse that has a footnote marker (`*`) (e.g., Genesis 1:1 or Matthew 1:1).
  2. Select that word or verse and add a note.
  3. **Direct Tap on `*`:** Tap directly on the footnote asterisk.
     - **Verify:** Opens the Translation Footnote sheet immediately.
  4. **Direct Tap on `✎`:** Tap directly on the pencil icon.
     - **Verify:** Opens the Note Editor sheet immediately.
  5. **Word Tap Disambiguation (Option 1):** Single-tap the text of the word that has *both* a footnote and a note attached.
     - **Verify:** A disambiguation bottom sheet appears titled with the verse reference, presenting two options:
       - **My Note** (with note preview)
       - **Translation Footnote** (with footnote preview)
     - Tap each option to verify it navigates to the respective sheet.
  6. **Single Annotation Word Taps:**
     - Single-tap a word with *only* a footnote → directly opens the footnote sheet.
     - Single-tap a word with *only* a note → directly opens the note sheet.

---

## 6. Persistence & Adaptive Light/Dark Mode Contrast

- [ ] **Adaptive Contrast in Dark Mode:**
  1. Highlight verses using each color: **Yellow**, **Green**, **Blue**, **Pink**, and **Purple**.
  2. Switch the app theme to **Dark Mode** (or toggle your system dark mode).
  3. **Verify:** The white text remains crisp, legible, and easy to read. Highlighting shifts dynamically to deep, translucent tones (e.g. rich amber for yellow, deep emerald for green) rather than bright blinding pastels.
- [ ] **Adaptive Contrast in Light Mode:**
  1. Switch back to **Light Mode**.
  2. **Verify:** Highlighting seamlessly adapts back to soft pastels with high contrast against black text.
- [ ] **Instant Theme Reactivity:**
  1. Toggle themes while viewing a highlighted chapter.
  2. **Verify:** The colors adapt immediately without needing to reload or reopen the chapter.
- [ ] **Swipe navigation:**
  1. Add a highlight and note on Chapter 1.
  2. Swipe to Chapter 2, then swipe back to Chapter 1.
  3. **Verify:** Your annotations are immediately visible.
- [ ] **App restart:**
  1. Fully close and relaunch the app.
  2. Navigate back to the chapter.
  3. **Verify:** All highlights and notes persist from `user_annotations.db`.

