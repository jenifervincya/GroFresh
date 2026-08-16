/// Minimal in-memory session state.
/// TODO(WIRING): once shared_preferences is added, persist token/userId/role
/// here on login so the app doesn't force re-login on every restart.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  String? userId;
  String? phone;
  String? name;
  String? role; // 'farmer' | 'buyer'
  String? authToken;

  bool get isLoggedIn => authToken != null;

  void clear() {
    userId = null;
    phone = null;
    name = null;
    role = null;
    authToken = null;
  }
}
