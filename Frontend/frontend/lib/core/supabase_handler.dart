import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHandler {
  static const String _url = 'https://ftmdiauggnfkzcrdarfs.supabase.co';
  static const String _anonKey =
      'sb_publishable_kA5nw0Ktcev5IqOgcZxM6Q_dRGgVLqz';

  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Auth Methods
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<bool> signInWithGoogle() async {
    // Note: This requires Google Auth to be configured in Supabase dashboard
    // and deep links to be set up in the app.
    // For this environment, we implement the method call.
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
