import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPostsService extends ChangeNotifier {
  static final SavedPostsService _instance = SavedPostsService._internal();
  static SavedPostsService get instance => _instance;

  SavedPostsService._internal();

  static const String _savedPostsKey = 'lunara_saved_posts';
  Set<int> _savedPostIds = {};

  Set<int> get savedPostIds => _savedPostIds;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStrings = prefs.getStringList(_savedPostsKey) ?? [];
      _savedPostIds = savedStrings.map((s) => int.tryParse(s) ?? 0).where((id) => id != 0).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SavedPostsService: $e');
    }
  }

  bool isSaved(int postId) {
    return _savedPostIds.contains(postId);
  }

  Future<void> toggleSave(int postId) async {
    if (_savedPostIds.contains(postId)) {
      _savedPostIds.remove(postId);
    } else {
      _savedPostIds.add(postId);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStrings = _savedPostIds.map((id) => id.toString()).toList();
      await prefs.setStringList(_savedPostsKey, savedStrings);
    } catch (e) {
      debugPrint('Error saving post ID: $e');
    }
  }
}
