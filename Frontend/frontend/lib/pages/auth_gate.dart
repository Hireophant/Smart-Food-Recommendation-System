import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../core/supabase_handler.dart';
import '../providers/favorites_provider.dart';
import '../providers/reviews_provider.dart';
import 'login_page.dart';
import 'main_scaffold.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // 🔓 LOGIN ENABLED
    // ============================================================
    // Authentication is now active. Users will be redirected to
    // LoginPage if no valid JWT is found.
    // ============================================================

    return StreamBuilder<AuthState>(
      stream: SupabaseHandler().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // You could show a loading screen here.
          // For now, we can just show a circular indicator in a Scaffold.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;
        debugPrint(
          'Auth Session Check: ${session != null ? "Valid JWT found" : "No JWT found"}',
        );

        if (session != null) {
          // User logged in - initialize FavoritesProvider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final favoritesProvider = Provider.of<FavoritesProvider>(
              context,
              listen: false,
            );
            if (!favoritesProvider.isInitialized) {
              favoritesProvider.initialize();
            }
            
            // Initialize ReviewsProvider
            final reviewsProvider = Provider.of<ReviewsProvider>(
              context,
              listen: false,
            );
            if (!reviewsProvider.isInitialized) {
              reviewsProvider.initialize();
            }
          });
          return const MainScaffold();
        } else {
          // User logged out - reset FavoritesProvider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final favoritesProvider = Provider.of<FavoritesProvider>(
              context,
              listen: false,
            );
            favoritesProvider.reset();
            
            // Reset ReviewsProvider
            final reviewsProvider = Provider.of<ReviewsProvider>(
              context,
              listen: false,
            );
            reviewsProvider.reset();
          });
          return const LoginPage();
        }
      },
    );
  }
}
