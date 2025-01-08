import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  late SharedPreferences _prefs;

  bool get isDarkMode => _prefs.getBool('isDarkMode') ?? false;

  double get textSize => _prefs.getDouble('textSize') ?? 16.0;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setDarkMode(bool value) async {
    _prefs.setBool('isDarkMode', value);
  }

  Future<void> setTextSize(double size) async {
    _prefs.setDouble('textSize', size);
  }
}
