import 'package:shared_preferences/shared_preferences.dart';

// MockUser class to simulate Firebase User
class MockUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });
}

// Simple authentication service without Firebase
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Mock user storage
  MockUser? _currentUser;
  bool _isAuthenticated = false;
  final _users = <String, String>{}; // email -> password

  // Get current user
  MockUser? get currentUser => _currentUser;

  // Auth state changes stream - not implemented for simplicity
  Stream<MockUser?> get authStateChanges => 
      Stream.fromFuture(Future.value(_isAuthenticated ? _currentUser : null));

  // Sign in with email and password
  Future<MockUser?> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    // Check if user exists and password matches
    if (_users.containsKey(email) && _users[email] == password) {
      _currentUser = MockUser(
        uid: email.hashCode.toString(),
        email: email,
        displayName: email.split('@').first,
      );
      _isAuthenticated = true;
      return _currentUser;
    } else {
      throw Exception('Invalid email or password');
    }
  }

  // Register with email and password
  Future<MockUser?> registerWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    // Check if user already exists
    if (_users.containsKey(email)) {
      throw Exception('email-already-in-use');
    }
    
    // Create new user
    _users[email] = password;
    _currentUser = MockUser(
      uid: email.hashCode.toString(),
      email: email,
      displayName: email.split('@').first,
    );
    _isAuthenticated = true;
    return _currentUser;
  }

  // Sign in with Google - simplified mock
  Future<MockUser?> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    const email = 'google_user@example.com';
    // Always succeed for testing
    _currentUser = MockUser(
      uid: email.hashCode.toString(),
      email: email,
      displayName: 'Google User',
      photoURL: 'https://ui-avatars.com/api/?name=Google+User&background=random',
    );
    _isAuthenticated = true;
    return _currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    _currentUser = null;
    _isAuthenticated = false;
  }

  // Store login state for persistence
  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Check login state for persistence
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    if (!_users.containsKey(email)) {
      throw Exception('No user found with this email');
    }
    
    // In a real app, this would send an email
    print('Password reset requested for $email');
  }

  // Add some test users
  void addTestUsers() {
    _users['test@example.com'] = 'password123';
    _users['user@example.com'] = 'password123';
  }
} 