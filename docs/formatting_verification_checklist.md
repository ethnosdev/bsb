# Verse Formatting Verification Checklist

This checklist contains key verses to inspect in your app to ensure formatting, styles, and layout render correctly with the newly generated database. It also highlights specific verses where the underlying USFM source files contain errors that you may wish to patch manually.

- Judges 1:6  (extra new line)
- Habakkuk 3:19  /mr -> /d
- Mt 3:15 
- Psalm 1:1
- Psalm 119

---

### 1. Source Text Glitches (Candidates for Manual Fix)

These verses contain formatting or syntax errors in the source USFM files (`database_builder/bsb_usfm/`). Check how they display in your UI; if they look awkward, you can manually patch the USFM source file and regenerate `database.db`.

| Passage           | File & Line               | What to Check in the App                                                                                                                                                                                                                   | Recommended Fix in `bsb_usfm/`                                                              |
| :---------------- | :------------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------ |
| **Judges 1:6**    | `bsb_usfm/JDG.usfm:16–17` | **Mid-sentence paragraph break**: Verse 6 is broken across two paragraphs (*"As Adoni-bezek"* on line 1, paragraph break, then *"fled, they pursued him..."* on line 2).                                                                   | Move `\p` to before `\v 6`.                                                                 |
| **1 Samuel 1:20** | `bsb_usfm/1SA.usfm:27`    | **Missing space after footnote**: Check if the text renders as `God.saying` without a space between the period/footnote caller and the word *"saying"*.                                                                                    | Change `\ft .\f*saying` to `\ft .\f* saying`.                                               |
| **Judges 16:14**  | `bsb_usfm/JDG.usfm:532`   | **Missing space after footnote**: Check if the text renders as `web.Then` without a space between the footnote caller and *"Then"*.                                                                                                        | Change `the web.\f*Then` to `the web.\f* Then`.                                             |
| **Habakkuk 3:19** | `bsb_usfm/HAB.usfm:179`   | **Liturgical note styled as major section**: The ending postscript (*"For the choirmaster. With stringed instruments."*) has marker `\mr`. Check whether it renders as an oversized section header instead of an italicized/centered note. | Change `\mr` to `\d` or `\pc`.                                                              |
| **Hebrews 11:29** | `bsb_usfm/HEB.usfm:289`   | **Cross-reference link**: Check whether tapping the section cross-reference `Joshua–Malachi` works, or if your app expects a target reference code (also check Heb 11:3, 11:7, 11:19, 11:22).                                              | Change `\r (\ref Joshua–Malachi\ref*)` to `\r (\ref Joshua–Malachi\|JOS 1:1-MAL 4:6\ref*)`. |

---

### 2. Words of Jesus (Clean Plain Text Verification)

All `\wj` and `\wj*` tags have been stripped by the generator so they do not produce rogue markup or break tokenizer alignment in the app. Verify that these verses render cleanly as plain text without stray backslashes, tags, or misplaced quotes:

| Passage | What to Check in the App |
| :--- | :--- |
| **Matthew 3:14–15** | Verify John's question in v14 concludes cleanly and Jesus' reply in v15 starts directly with *“Let it be so now,”* without any rogue `\wj` tag or extra blank line. |
| **Matthew 4:18–19** | Verify v18 cleanly concludes with *“...for they were fishermen.”* and v19 starts directly with *“Come, follow Me,”*. |
| **Matthew 16:16–17** | Peter's confession in v16 followed immediately by Jesus' reply across the verse boundary in v17. |
| **Luke 22:67–68** | Rapid dialogue without stray tags around verse numbers. |
| **Revelation 3:1–3** | Letters to the churches across embedded margin paragraphs (`pmo`) render cleanly without tags. |

---

### 3. Psalms Layout & Special Elements

| Passage                           | What to Check in the App                                                                                                                                                                                                   |
| :-------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Psalm 1:1**                     | Check the division header `BOOK I` (`ms`) and `Psalms 1–41` (`d`) above the psalm.                                                                                                                                         |
| **Psalm 8:1**                     | Check the superscription (*"For the choirmaster. According to Gittith..."* in `d`) followed by poetry line 1 (*"O LORD, our Lord, how majestic..."* in `q1`). Confirm verse 1 text starts on its own indented poetry line. |
| **Psalm 42:1, 73:1, 90:1, 107:1** | Check the division headers for Books II, III, IV, and V.                                                                                                                                                                   |
| **Psalm 119:1, 119:9, 119:17**    | Check that each 8-verse section displays both the Hebrew letter (`א`, `ב`, `ג`) and the transliterated English name (`ALEPH`, `BETH`, `GIMEL`) cleanly above the stanza.                                                   |
| **Psalm 3:2, 3:4, 3:8**           | Check the right-alignment and vertical spacing around *Selah* (`qr`).                                                                                                                                                      |

---

### 4. Centered Inscriptions & Structural Stanzas

| Passage                  | What to Check in the App                                                                                        |
| :----------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **Matthew 27:37**        | Inscription on the cross (*"THIS IS JESUS, THE KING OF THE JEWS."*) rendered centered as a single block (`pc`). |
| **John 19:19**           | Pilate's title (*"JESUS OF NAZARETH, THE KING OF THE JEWS."*) rendered centered as a single block (`pc`).       |
| **Revelation 17:5**      | Name on the forehead (*"BABYLON THE GREAT..."*) rendered centered as a single block (`pc`).                     |
| **Matthew 1:1–17**       | Genealogy of Jesus: verify the poetic indentation and stanza breaks between genealogical eras.                  |
| **Deuteronomy 27:15–26** | Curses (`li1`) and congregational responses (*"And let all the people say, 'Amen!' "* in `qr`).                 |

---

### 5. How to Apply Manual Source Fixes & Rebuild

If you choose to fix any of the source glitches manually:

1. Edit the relevant file in `database_builder/bsb_usfm/` (e.g. `JDG.usfm`, `1SA.usfm`, `HAB.usfm`).
2. Regenerate the database:
   ```bash
   cd database_builder
   dart bin/main.dart
   ```
3. Copy the updated database to the Flutter app:
   ```bash
   cp database_builder/database.db flutter_app/assets/database/database.db
   ```
