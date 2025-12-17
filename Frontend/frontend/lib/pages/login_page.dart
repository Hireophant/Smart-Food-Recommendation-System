import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_handler.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // removed unused isLoading

  Future<void> _signIn() async {
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
        return;
      }

      await SupabaseHandler().signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _googleSignIn() async {
    // This requires additional setup on Supabase and App-side (URL Schemes)
    // which might not be fully configured in this environment.
    bool success = await SupabaseHandler().signInWithGoogle();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In failed or cancelled'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsiveness
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Match design
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section with Image
            SizedBox(
              height: size.height * 0.45,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Circle (Green in design, requesting Orange)
                  Positioned(
                    top: -60,
                    child: Container(
                      width: size.width * 1.2,
                      height: size.width * 1.2,
                      decoration: const BoxDecoration(
                        // User asked for "Orange theme". Let's try to adapt logic.
                        // The user said "lamf cac trang nay theo tong mau cam" (make these pages in orange tones).
                        // Let's use a deep orange/teal combo or just orange.
                        // However, the uploaded images have specific colors.
                        // I will switch primary background elements to Orange as requested.
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Image
                  Positioned(
                    bottom: 20,
                    child: Image.asset(
                      'assets/images/hamburger_3d.png',
                      height: 250,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fastfood,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text Section
            Text(
              'Tìm Kiếm Nhà Hàng',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange, // Orange theme
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '', // Removed "App" as generic text is redundant
              style: GoogleFonts.poppins(
                fontSize: 16,
                letterSpacing: 2,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 30),

            // Inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Mật khẩu',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),

                  const SizedBox(height: 16),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {}, // TODO: Implement reset password
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text('hoặc'),

                  const SizedBox(height: 16),

                  // Register / Create Account
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.orange[50], // Light orange
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Tạo tài khoản',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Google Sign In
                  GestureDetector(
                    onTap: _googleSignIn,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, size: 30, color: Colors.blue),
                        Text(
                          "Đăng nhập bằng Google",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
