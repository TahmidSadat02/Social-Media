import 'package:flutter/material.dart';
import '../../../supabase_config.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/validators.dart';

class AuthController extends ChangeNotifier {
  final supabase = SupabaseConfig.client;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  String _mapAuthError(Object error) {
    final raw = error.toString();
    final normalized = raw.toLowerCase();

    if (normalized.contains('failed host lookup') ||
        normalized.contains('socketexception')) {
      return 'Unable to connect to the server. Check internet access and verify Supabase URL/key in configuration.';
    }

    if (normalized.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }

    if (normalized.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }

    return raw;
  }

  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;

      final session = supabase.auth.currentSession;
      if (session != null) {
        await _loadUserProfile(session.user.id);
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _error = _mapAuthError(e);
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final emailError = Validators.validateEmail(email);
      if (emailError != null) {
        _error = emailError;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final passwordError = Validators.validatePassword(password);
      if (passwordError != null) {
        _error = passwordError;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final usernameError = Validators.validateUsername(username);
      if (usernameError != null) {
        _error = usernameError;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Sign up with Supabase
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      // Create profile in database
      await supabase.from('profiles').insert({
        'id': response.user!.id,
        'username': username,
        'full_name': username,
        'created_at': DateTime.now().toIso8601String(),
      });

      _currentUser = UserModel(
        id: response.user!.id,
        username: username,
        fullName: username,
        createdAt: DateTime.now(),
      );

      _isAuthenticated = true;
    } catch (e) {
      _error = _mapAuthError(e);
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }

      await _loadUserProfile(response.user!.id);
      _isAuthenticated = true;
    } catch (e) {
      _error = _mapAuthError(e);
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      await supabase.auth.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      _error = _mapAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    final response =
        await supabase.from('profiles').select().eq('id', userId).single();

    _currentUser = UserModel.fromJson(response);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
