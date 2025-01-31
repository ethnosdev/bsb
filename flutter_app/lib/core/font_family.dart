import 'package:database_builder/database_builder.dart';

String fontFamilyForLanguage(Language language) {
  return (language == Language.greek) ? 'Galatia' : 'Ezra';
}
