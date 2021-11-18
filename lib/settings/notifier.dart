import 'package:flutter/cupertino.dart';
import 'package:openauth/settings/provider.dart';

class PreferenceNotifier extends ChangeNotifier {
  final UserPreferenceHandler _handler = UserPreferenceHandler();
  Preferences _preferences = Preferences();
  Preferences get preferences => _preferences;

  PreferenceNotifier() {
    load();
  }

  void load() async {
    _preferences = await _handler.getPreferences();
  }

  changeTheme(UserTheme theme) {
    _preferences.theme = theme;
    _handler.setTheme(theme);
    notifyListeners();
  }
}
