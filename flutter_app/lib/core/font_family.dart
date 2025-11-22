import 'package:database_builder/database_builder.dart';
import 'package:flutter/widgets.dart';

String fontFamilyForLanguage(Language language) {
  return (language == Language.greek) ? 'Galatia' : 'Ezra';
}

class CustomIcons {
  static IconData aleph = IconData(0xe800, fontFamily: 'CustomIcons');
  static IconData alpha = IconData(0xe801, fontFamily: 'CustomIcons');
}
