import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic> _currentUser = {};

  bool _hasSeenOnboarding = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  Map<String, dynamic> get currentUser => _currentUser;

  Future<void> initApp() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    final String? email = prefs.getString('user_email');
    if (email != null) {
      final user = await DatabaseService.instance.getUserByEmail(email);
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> login(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user['email']);

    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');

    _isAuthenticated = false;
    _currentUser = {};
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }
}
