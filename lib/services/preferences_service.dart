import 'package:shared_preferences/shared_preferences.dart';

/// Service class that encapsulates all SharedPreferences logic.
/// This maintains separation of concerns by keeping persistence logic separate from UI and state management.
class PreferencesService {
  /// The key used to store the block list in SharedPreferences.
  static const String kBlockListKey = 'block_list';

  /// Saves the block list to SharedPreferences.
  /// 
  /// [blockList] - The list of tags to be blocked (e.g., ['naruto', 'one_piece']).
  /// 
  /// Returns a Future that completes when the save operation is finished.
  Future<void> saveBlockList(List<String> blockList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(kBlockListKey, blockList);
  }

  /// Retrieves the block list from SharedPreferences.
  /// 
  /// Returns a Future that completes with the list of blocked tags.
  /// If no block list exists, returns an empty list.
  Future<List<String>> getBlockList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(kBlockListKey) ?? [];
  }

  /// Saves a string value to SharedPreferences.
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Retrieves a string value from SharedPreferences.
  Future<String> getString(String key, String defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  /// Saves a boolean value to SharedPreferences.
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Retrieves a boolean value from SharedPreferences.
  Future<bool> getBool(String key, bool defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Saves an integer value to SharedPreferences.
  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Retrieves an integer value from SharedPreferences.
  Future<int> getInt(String key, int defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  /// Key for storing the profile image path.
  static const String kProfileImagePathKey = 'profile_image_path';

  /// Saves the profile image path to SharedPreferences.
  /// 
  /// [imagePath] - The local file path to the profile image.
  /// 
  /// Returns a Future that completes when the save operation is finished.
  Future<void> saveProfileImagePath(String imagePath) async {
    await setString(kProfileImagePathKey, imagePath);
  }

  /// Retrieves the profile image path from SharedPreferences.
  /// 
  /// Returns a Future that completes with the profile image path.
  /// If no path exists, returns an empty string.
  Future<String> getProfileImagePath() async {
    return await getString(kProfileImagePathKey, '');
  }
}

