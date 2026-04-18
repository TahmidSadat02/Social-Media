import 'package:flutter/material.dart';
import '../../../supabase_config.dart';
import '../../../models/user_model.dart';

class SearchController extends ChangeNotifier {
  final supabase = SupabaseConfig.client;

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  List<UserModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get error => _error;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _isSearching = true;
      _error = null;
      notifyListeners();

      final response = await supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .limit(20);

      _searchResults =
          (response as List).map((u) => UserModel.fromJson(u)).toList();
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
