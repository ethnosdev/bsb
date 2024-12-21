# Paratext Markers Reference with Frequencies

This document shows the paratext markers that exist in the Paratext files in the `bsb_usfm` folder. The frequency count is the number in parentheses. The data was calculated using 

## `\b` - Paragraph Break (16281)
Used to indicate a blank line or a paragraph break between sections of text.

## `\c` - Chapter Number (1189)
Marks the beginning of a new chapter and is followed by the chapter number.

## `\d` - Descriptive Title (117)
Provides a descriptive heading or title for a chapter or book. (Psalms and Zechariah. For example, "A Psalm of David")

## `\h` - Running Header (66)
Specifies the text to be used in the running header of a page. This is the name of the book. Seems to be the same as toc1, toc2, and mt1.

## `\id` - Identification (66)
Contains the book ID at the beginning of each file. For example:

- \id PSA - Berean Standard Bible

## `\li1` - List Item Level 1 (1343)
Indicates a first-level item in a list. Genealogies and other lists.

## `\li2` - List Item Level 2 (194)
Indicates a second-level item in a list, nested under a level 1 item. Same as \li1 but a further level of nesting and indentation. Example: Numbers 26:21.

## `\m` - Continuation (margin) Paragraph (12273)
Continues a paragraph at the margin without indentation.

## `\mr` - Reference Range (5)
Marks the reference range in Psalms for the book of Psalms. Example:

```
\ms BOOK I
\mr Psalms 1—41
```

## `\ms` - Major Section Heading (5)
Denotes a major section or division within the books of Psalms. Example:

```
\ms BOOK I
\mr Psalms 1—41
```

## `\mt1` - Main Title Level 1 (66)
Same as \h. Used once in every book. Can ignore.

## `\pc` - Centered Paragraph (16)
Used almost exclusively for capitalized quotes like "MENE, MENE, TEKEL, PARSIN."

## `\pmo` - Embedded text opening. (233)
Starts a paragraph after something like "The Second Day" in the narrative of creation in Genesis 1.

## `\q1` - Poetry Line Level 1 (11562)
Indicates the first level of poetic lines.

## `\q2` - Poetry Line Level 2 (12549)
Indicates the second level of poetic lines, indented under level 1.

## `\qa` - Acrostic Heading (22)
Used for headings in an acrostic poem. Only in Psalm 119 for words like "ALEPH".

## `\qr` - Right-Aligned Text (223)
Marks text that should be right-aligned. For example, "Selah".

## `\r` - Section Reference (1324)
Provides a reference or heading for a section, often used for cross-references.

## `\s1` - Section Heading Level 1 (3017)
These are the section titles, not Biblical text.

## `\s2` - Section Heading Level 2 (80)
Denotes a second-level section heading, subordinate to level 1.

## `\toc1` - Table of Contents Entry Level 1 (66)
Same as \h. Used once in every book. Can ignore.

## `\toc2` - Table of Contents Entry Level 2 (66)
Same as \h. Used once in every book. Can ignore.

### `\v` - Verse Number (31086)
Marks the beginning of a verse and is followed by the verse number.
