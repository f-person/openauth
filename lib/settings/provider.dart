import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserTheme { light, dark, amoled, dracula, nord }

extension UserThemeExtension on UserTheme {
  String get value {
    switch (this) {
      case UserTheme.light:
        return 'light';
      case UserTheme.dark:
        return 'dark';
      case UserTheme.amoled:
        return 'amoled';
      case UserTheme.dracula:
        return 'dracula';
      case UserTheme.nord:
        return 'nord';
    }
  }

  static UserTheme parse(String theme) {
    switch (theme) {
      case 'light':
        return UserTheme.light;
      case 'dark':
        return UserTheme.dark;
      case 'amoled':
        return UserTheme.amoled;
      case 'dracula':
        return UserTheme.dracula;
      case 'nord':
        return UserTheme.nord;
      default:
        throw Error();
    }
  }
}

class Preferences {
  UserTheme theme;
  bool isSecretsHidden;
  bool isFirstLaunch;
  bool isAppProtected;

  Preferences(
      {this.theme = UserTheme.light,
      this.isSecretsHidden = true,
      this.isFirstLaunch = true,
      this.isAppProtected = false});
}

class UserPreferenceHandler {
  SharedPreferences? _preferences;

  static const themeKey = "theme";
  static const secretsHiddenKey = "secretsHidden";
  static const firstLaunchKey = "firstLaunch";
  static const appProtectedKey = "isAppProtected";

  void _initPreferences() async {
    if (_preferences != null) {
      _preferences = await SharedPreferences.getInstance();
    }
  }

  Future<Preferences> getPreferences() async {
    UserTheme _theme = await getTheme();
    return Preferences(theme: _theme);
  }

  Future setFirstLaunch(bool isFirstLaunch) async {
    _initPreferences();
    return await _preferences?.setBool(firstLaunchKey, isFirstLaunch);
  }

  Future<bool> getSecretsHidden() async {
    _initPreferences();
    bool _isSecretsHidden =
        _preferences?.getBool(UserPreferenceHandler.secretsHiddenKey) ?? true;
    return _isSecretsHidden;
  }

  Future setSecretsHidden(bool secretsHidden) async {
    _initPreferences();
    return await _preferences?.setBool(
        UserPreferenceHandler.secretsHiddenKey, secretsHidden);
  }

  Future<UserTheme> getTheme() async {
    _initPreferences();
    String? _theme = _preferences?.getString(UserPreferenceHandler.themeKey);
    return _theme != null ? UserThemeExtension.parse(_theme) : UserTheme.light;
  }

  Future setTheme(UserTheme theme) async {
    _initPreferences();
    return await _preferences?.setString(themeKey, theme.value.toString());
  }

  Future setAppProtected(bool isProtected) async {
    _initPreferences();
    return await _preferences?.setBool(appProtectedKey, isProtected);
  }
}

class PassphraseHandler {
  static const _accessControl = "access";

  static Future setPassphrase(String password) async {
    const storage = FlutterSecureStorage();
    await storage.write(
        key: _accessControl, value: base64Encode(password.codeUnits));
  }

  static Future<String?> getPassphrase() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: _accessControl);
  }
}
