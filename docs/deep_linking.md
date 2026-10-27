# Deep Linking Guide

The Berean Standard Bible (BSB) app supports deep linking via the custom URL scheme `bsb://`. External applications on Android and iOS can open specific chapters and optionally navigate directly to a verse within the BSB app.

---

## URL Structure

Links follow a path-based URI format:

```text
bsb://bible/<bookId>/<chapter>
bsb://bible/<bookId>/<chapter>/<verse>
```

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `<bookId>` | Integer | Yes | The numeric ID of the Bible book (from `1` for Genesis to `66` for Revelation). |
| `<chapter>` | Integer | Yes | The chapter number (1-based, up to the book's total chapter count). |
| `<verse>` | Integer | No | The verse number (1-based, up to the chapter's total verse count). |

### Examples

* `bsb://bible/43/3` — Opens John chapter 3
* `bsb://bible/43/3/16` — Opens John chapter 3 and scrolls verse 16 to the top
* `bsb://bible/1/1/1` — Opens Genesis 1:1
* `bsb://bible/19/23` — Opens Psalm 23
* `bsb://bible/66/22/21` — Opens Revelation 22:21

---

## App Behavior

* **Tab Management**: If the requested chapter is already open in a tab, the app switches directly to that tab. If not, a new tab is created and focused.
* **Verse Navigation**: When a verse number is supplied, the app automatically scrolls the verse into view at the top of the passage.
* **Modal / Subpage Dismissal**: If the user is currently viewing a modal bottom sheet, dialog, or subpage (such as Settings or Search), the app dismisses it so the scripture is immediately visible.
* **Validation**: If an invalid book ID (e.g. `< 1` or `> 66`), out-of-range chapter, or out-of-range verse is provided, the app remains on the current screen and displays an `Invalid Bible link` notification.

---

## Book ID Reference Table

| Book ID | Book Name | Abbreviation | Total Chapters |
|:---:|---|:---:|:---:|
| **1** | Genesis | GEN | 50 |
| **2** | Exodus | EXO | 40 |
| **3** | Leviticus | LEV | 27 |
| **4** | Numbers | NUM | 36 |
| **5** | Deuteronomy | DEU | 34 |
| **6** | Joshua | JOS | 24 |
| **7** | Judges | JDG | 21 |
| **8** | Ruth | RUT | 4 |
| **9** | 1 Samuel | 1SA | 31 |
| **10** | 2 Samuel | 2SA | 24 |
| **11** | 1 Kings | 1KI | 22 |
| **12** | 2 Kings | 2KI | 25 |
| **13** | 1 Chronicles | 1CH | 29 |
| **14** | 2 Chronicles | 2CH | 36 |
| **15** | Ezra | EZR | 10 |
| **16** | Nehemiah | NEH | 13 |
| **17** | Esther | EST | 10 |
| **18** | Job | JOB | 42 |
| **19** | Psalms | PSA | 150 |
| **20** | Proverbs | PRO | 31 |
| **21** | Ecclesiastes | ECC | 12 |
| **22** | Song of Solomon | SNG | 8 |
| **23** | Isaiah | ISA | 66 |
| **24** | Jeremiah | JER | 52 |
| **25** | Lamentations | LAM | 5 |
| **26** | Ezekiel | EZK | 48 |
| **27** | Daniel | DAN | 12 |
| **28** | Hosea | HOS | 14 |
| **29** | Joel | JOL | 3 |
| **30** | Amos | AMO | 9 |
| **31** | Obadiah | OBA | 1 |
| **32** | Jonah | JON | 4 |
| **33** | Micah | MIC | 7 |
| **34** | Nahum | NAM | 3 |
| **35** | Habakkuk | HAB | 3 |
| **36** | Zephaniah | ZEP | 3 |
| **37** | Haggai | HAG | 2 |
| **38** | Zechariah | ZEC | 14 |
| **39** | Malachi | MAL | 4 |
| **40** | Matthew | MAT | 28 |
| **41** | Mark | MRK | 16 |
| **42** | Luke | LUK | 24 |
| **43** | John | JHN | 21 |
| **44** | Acts | ACT | 28 |
| **45** | Romans | ROM | 16 |
| **46** | 1 Corinthians | 1CO | 16 |
| **47** | 2 Corinthians | 2CO | 13 |
| **48** | Galatians | GAL | 6 |
| **49** | Ephesians | EPH | 6 |
| **50** | Philippians | PHP | 4 |
| **51** | Colossians | COL | 4 |
| **52** | 1 Thessalonians | 1TH | 5 |
| **53** | 2 Thessalonians | 2TH | 3 |
| **54** | 1 Timothy | 1TI | 6 |
| **55** | 2 Timothy | 2TI | 4 |
| **56** | Titus | TIT | 3 |
| **57** | Philemon | PHM | 1 |
| **58** | Hebrews | HEB | 13 |
| **59** | James | JAS | 5 |
| **60** | 1 Peter | 1PE | 5 |
| **61** | 2 Peter | 2PE | 3 |
| **62** | 1 John | 1JN | 5 |
| **63** | 2 John | 2JN | 1 |
| **64** | 3 John | 3JN | 1 |
| **65** | Jude | JUD | 1 |
| **66** | Revelation | REV | 22 |

---

## Code Examples

### Flutter (using `url_launcher`)

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> openBsbPassage(int bookId, int chapter, [int? verse]) async {
  final path = verse != null ? '$bookId/$chapter/$verse' : '$bookId/$chapter';
  final uri = Uri.parse('bsb://bible/$path');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    // Optionally redirect to App Store / Play Store if BSB is not installed
  }
}

// Example usage:
// openBsbPassage(43, 3, 16); // John 3:16
```

#### Android Configuration for Calling App

On Android 11+ (API level 30+), external apps querying custom schemes must declare the scheme in their `AndroidManifest.xml`:

```xml
<manifest>
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="bsb" />
        </intent>
    </queries>
</manifest>
```

#### iOS Configuration for Calling App

If your iOS app uses `canOpenURL` to check whether the BSB app is installed, add `bsb` to `LSApplicationQueriesSchemes` in `Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>bsb</string>
</array>
```

---

### Android (Kotlin)

```kotlin
import android.content.Intent
import android.net.Uri

fun openBsb(bookId: Int, chapter: Int, verse: Int? = null) {
    val path = if (verse != null) "$bookId/$chapter/$verse" else "$bookId/$chapter"
    val uri = Uri.parse("bsb://bible/$path")
    val intent = Intent(Intent.ACTION_VIEW, uri)
    context.startActivity(intent)
}
```

---

### iOS (Swift)

```swift
import UIKit

func openBsb(bookId: Int, chapter: Int, verse: Int? = nil) {
    let path = verse != nil ? "\(bookId)/\(chapter)/\(verse!)" : "\(bookId)/\(chapter)"
    guard let url = URL(string: "bsb://bible/\(path)") else { return }
    
    if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
    }
}
```
