# How to update the text of the BSB

Occasionally, the BSB team makes minor revisions to the text of the BSB. These should be incorporated into the app database.

## Check for updates

The CHANGELOG is located here:

- https://bereanbible.com/changelog.txt

Scroll to the bottom and see if there are any updates newer than in the app.

## Download source files

Download the USFM files and the Translation Tables

- https://berean.bible/downloads.htm

## Prepare translation tables

- Open the file bsb_tables.xlsx
- Check a verse to make sure it has the latest updates.
- Sort the rows by Heb Sort then Greek Sort columns (not by the default BSB Sort column)
- Save as a CVS file with Tab field delimiters.
- Store in `database_builder/bsb_tables/` folder.

## Prepare USFM files

- Unzip download
- Store in `database_builder/bsb_usfm/` folder.
- Check the Git diff to make sure it looks as expected.

## Create the database

- Run `database_builder/bin/main.dart` (which calls the `createDatabase` function)
- Copy `database.db` into `flutter_app/assets/database` and replace the old database.

## Update database version

This triggers the app to delete old database and use the new one when users upgrade

- In `flutter_app/lib/infrastructure/database.dart`, increment the `_databaseVersion` int.

## Check the formatting

- Check the formatting of verses and paragraphs to make sure it is still the same.
- Check Genesis 1, Psalms, footnotes, etc.
- If any USFM markers changed in the source text, the parsing code may need to be updated.

## Update the BSB version in the About Page

It should read something like this:

> BSB version: 3rd printing (7-31-2026)

