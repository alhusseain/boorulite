import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';

/// Provider class that manages the block list state for the entire application.
/// This is the single source of truth for the block list while the app is running.
/// 
/// Uses ChangeNotifier to notify listeners when the block list changes,
/// enabling reactive UI updates across the app.
class BlockListProvider extends ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  
  /// The in-memory list of blocked tags.
  /// This is loaded from SharedPreferences on initialization and kept in sync.
  List<String> _blockList = [];

  /// Public getter for the block list.
  /// Returns a copy of the list to prevent external modification.
  List<String> get blockList => List.unmodifiable(_blockList);

  /// Constructor that initializes the provider by loading the block list from disk.
  BlockListProvider() {
    _loadBlockList();
  }

  /// Loads the block list from SharedPreferences into memory.
  /// This is called during initialization.
  Future<void> _loadBlockList() async {
    _blockList = await _preferencesService.getBlockList();
    notifyListeners();
  }

  /// Adds a tag to the block list.
  /// 
  /// [tag] - The tag to be added (e.g., 'naruto').
  /// 
  /// The tag is trimmed of whitespace and converted to lowercase for consistency.
  /// If the tag is empty or already exists in the list, no action is taken.
  /// After adding, the list is persisted to SharedPreferences and listeners are notified.
  Future<void> addTag(String tag) async {
    final trimmedTag = tag.trim().toLowerCase();
    
    // Validate: don't add empty tags or duplicates
    if (trimmedTag.isEmpty || _blockList.contains(trimmedTag)) {
      return;
    }

    _blockList.add(trimmedTag);
    await _preferencesService.saveBlockList(_blockList);
    notifyListeners();
  }

  /// Removes a tag from the block list.
  /// 
  /// [tag] - The tag to be removed (e.g., 'naruto').
  /// 
  /// If the tag exists in the list, it is removed. The list is then persisted
  /// to SharedPreferences and listeners are notified.
  Future<void> removeTag(String tag) async {
    if (_blockList.remove(tag)) {
      await _preferencesService.saveBlockList(_blockList);
      notifyListeners();
    }
  }
}

