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
    final user = currentUser;
    if (user == null) throw 'User not logged in';

    // Use fixed filename to overwrite previous avatar
    final fileName = '${user.id}/avatar.jpg';

    try {
      // 1. Upload file to 'avatars' bucket (Private)
      await client.storage
          .from('avatars')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // 2. Clear valid signed URL from cache if possible, or just generate a new one.
      // Since we just uploaded, we want a fresh URL.
      // createSignedUrl params: path, expiresIn (seconds)
      final signedUrl = await client.storage
          .from('avatars')
          .createSignedUrl(fileName, 60 * 60 * 24); // Valid for 24 hours

      // 3. Update User Metadata (Optional for private buckets, but good for caching path?)
      // We will store the full signed URL, but know that it expires.
      // Ideally, we just store the path, but sticking to existing pattern for now.
      await client.auth.updateUser(
        UserAttributes(data: {'avatar_url': signedUrl}),
      );

      return signedUrl;
    } catch (e) {
      throw 'Upload failed: $e';
    }
  }

  // Fetch a fresh signed URL
  Future<String?> getAvatarUrl(String userId) async {
    try {
      final fileName = '$userId/avatar.jpg';
      // Generated signed URL valid for 24h
      final signedUrl = await client.storage
          .from('avatars')
          .createSignedUrl(fileName, 60 * 60 * 24);
      return signedUrl;
    } catch (e) {
      // If file doesn't exist or other error, return null
      return null;
    }
  }
}
