import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  static final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/admob.readonly',
      'https://www.googleapis.com/auth/adsense.readonly',
    ],
  );

  GoogleSignInAccount? _user;
  bool _isLoading = true;

  GoogleSignInAccount? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<void> trySilentSignIn() async {
    try {
      _user = await _googleSignIn.signInSilently();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn() async {
    try {
      _user = await _googleSignIn.signIn();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign in error: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }

  Future<String?> getAccessToken() async {
    if (_user == null) return null;
    final auth = await _user!.authentication;
    return auth.accessToken;
  }
}
