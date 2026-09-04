# How to update the text of the BSB

Occasionally, the BSB team makes minor revisions to the text of the BSB. These should be incorporated into the app database.

## Check for updates

The CHANGELOG is located here:

- https://bereanbible.com/changelog.txt

Scroll to the bottom and see if there are any updates newer than in the app. The About page in the app tells the current text version.

## Download source files

Download the USFM files and the Translation Tables

- https://berean.bible/downloads.htm

## Prepare translation tables

- Open the file bsb_tables.xlsx
- Check a verse to make sure it has the latest updates.
- Sort the rows by Heb Sort then Greek Sort columns (not by the default BSB Sort column)
- Save as a CSV file with Tab field delimiters.
- Store in `database_builder/bsb_tables/` folder.

## Prepare USFM files

- Unzip download
- Store in `database_builder/bsb_usfm/` folder.
- Check the Git diff to make sure it looks as expected.

## Manual source file edits

It is highly preferable that the source files be edited by the BSB team at the source, but if there are mistakes that haven't been fixed yet then edit them here.

Known errors:

- Judges 1:6 (move \p marker to the beginning of verse 6)
- Habakkuk 3:19 (change /mr marker to /d)

## Create and verify the database

- Run `database_builder/bin/main.dart` (which calls the `createDatabase` function)
- Run `dart test` in `database_builder/` to verify that the generated database passes all integrity, canon, text hygiene, and interlinear checks.
- Copy `database.db` into `flutter_app/assets/database` and replace the old database.

## Update database version

This triggers the app to delete the old database and use the new one when users upgrade:

- In `flutter_app/lib/infrastructure/database.dart`, increment the `_databaseVersion` int.

## Check the formatting

Check the formatting of verses and paragraphs to make sure they are still the same:

- Genesis 1: 
  - Primary titles
  - Secondary titles
  - Indented paragraphs
  - Verse 5 split over two paragraphs
  - Footnotes are clickable as well as links within footnotes
  - Verse 6 footnote contains italicized text.
- Deuteronomy 27:15–26
  - Curses (`li1`) and congregational responses (`qr`)
- Judges 1:6
  - Paragraph starts at beginning of verse, not middle.
- Psalms 1 
  - Three different heading types
  - q1 and q2 indentation
- Psalm 119
  - Acrostic titles
- Hab 3
  - Selah formatting and footnote
  - End of chapter "For the choirmaster..."
- Matthew 1
  - Lists of people indentation
  - Normal paragraphs are margin indented
- Matthew 3:15
  - Words of Jesus don't have any special format markers
- Matthew 27:37
  - Inscription on the cross

## Update the BSB version in the About Page

It should read something like this:

> BSB version: 3rd printing (7-31-2026)

