import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_handler.dart';
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
          return const MainScaffold();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
