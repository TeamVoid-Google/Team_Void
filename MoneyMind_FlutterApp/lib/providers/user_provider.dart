import 'package:flutter/foundation.dart';
import '../models/community_models.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  bool get isLoggedIn => _currentUser != null;
  
  // In a real app, this would be populated from local storage, 
  // user login, or an authentication service
  Future<void> initialize() async {
    // For demonstration purposes, we're creating a default user
    // In a real application, you would retrieve the user information from storage or API
    _currentUser = User(
      id: 1,
      username: 'Your name',
      handle: '@Your_name',
      bio: 'Financial enthusiast',
      profileImage: 'assets/profile.png',
    );
    notifyListeners();
  }
  
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
  
  void updateUser({
    String? username,
    String? bio,
    String? profileImage,
  }) {
    if (_currentUser == null) return;
    
    _currentUser = User(
      id: _currentUser!.id,
      username: username ?? _currentUser!.username,
      handle: _currentUser!.handle,
      bio: bio ?? _currentUser!.bio,
      profileImage: profileImage ?? _currentUser!.profileImage,
    );
    
    notifyListeners();
  }
  
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}