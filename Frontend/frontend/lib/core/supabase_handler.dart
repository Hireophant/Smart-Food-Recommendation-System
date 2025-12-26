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

  // Storage & Profile Methods
  Future<String> uploadAvatar(dynamic file) async {
    // Note: 'file' should be of type File (dart:io).
    // Using dynamic to avoid importing dart:io here if not strictly needed,
    // but typically you would verify the type.

    final user = currentUser;
    if (user == null) throw 'User not logged in';

    // Use fixed filename to overwrite previous avatar
    final fileName = '${user.id}/avatar.jpg';

    try {
      // 1. Upload file to 'avatars' bucket
      // Ensure specific policy in Supabase Storage allow public read/write for auth users
      // Set upsert: true to overwrite existing file
      await client.storage
          .from('avatars')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // 2. Get Public URL
      final urlPath = client.storage.from('avatars').getPublicUrl(fileName);

      // Append timestamp to force UI refresh (bypass cache)
      final imageUrl = '$urlPath?v=${DateTime.now().millisecondsSinceEpoch}';

      // 3. Update User Metadata
      await client.auth.updateUser(
        UserAttributes(data: {'avatar_url': imageUrl}),
      );

      return imageUrl;
    } catch (e) {
      throw 'Upload failed: $e';
    }
  }

  String getPublicAvatarUrl(String userId) {
    // derived from fixed filename logic
    return client.storage.from('avatars').getPublicUrl('$userId/avatar.jpg');
  }
}
