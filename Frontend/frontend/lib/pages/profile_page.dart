import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/supabase_handler.dart';
import '../widgets/glass_container.dart';
import '../pages/login_page.dart'; // For navigation after logout

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final user = SupabaseHandler().currentUser;
    if (user != null) {
      final metaAvatar = user.userMetadata?['avatar_url'];
      if (metaAvatar != null) {
        setState(() {
          _avatarUrl = metaAvatar;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    try {
      // Pick and scale image (limit to ~500px and 70% quality to ensure < 1MB)
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (image == null) return;

      final File file = File(image.path);

      setState(() {
        _isUploading = true;
      });

      // 1. Upload
      await SupabaseHandler().uploadAvatar(file);

      // 2. Construct URL manually to ensure we use the 'avatar.jpg' source
      final user = SupabaseHandler().currentUser;
      if (user != null) {
        final publicUrl = SupabaseHandler().getPublicAvatarUrl(user.id);
        // Append timestamp to bust cache
        final newUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

        // 3. Evict previous image from cache
        if (_avatarUrl != null) {
          await NetworkImage(_avatarUrl!).evict();
        }

        if (mounted) {
          setState(() {
            _isUploading = false;
            _avatarUrl = newUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Avatar Error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        // Show detailed error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await SupabaseHandler().signOut();
    if (context.mounted) {
      // Pop all routes and go to Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseHandler().currentUser;
    final email = user?.email ?? 'MasterChef';
    final name = user?.userMetadata?['full_name'] ?? 'Guest Player';

    // Background Image URL (Dark/Premium Food Theme)
    const bgImage =
        'https://images.unsplash.com/photo-1543353071-873f17a7a088?q=80&w=1920&auto=format&fit=crop';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background
          Positioned.fill(child: Image.network(bgImage, fit: BoxFit.cover)),
          // 2. Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          // 3. Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // --- Avatar & Title ---
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 24,
                        ), // Space for "Change Avatar" text
                        child: GestureDetector(
                          onTap: () => _pickAndUploadAvatar(context),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.amber,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.5),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: _avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : const NetworkImage(
                                          'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
                                        ),
                                  onBackgroundImageError:
                                      (exception, stackTrace) {
                                        debugPrint(
                                          'Image Load Error: $exception',
                                        );
                                        debugPrint('Failed URL: $_avatarUrl');
                                      },
                                  child: _isUploading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Colors.white70,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Đổi ảnh đại diện",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Name ---
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Roboto', // Or user preferred font
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Stats Row (Game Style) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("LEVEL", "15", Icons.military_tech),
                      _buildStatItem("LIKES", "380", Icons.favorite),
                      _buildStatItem("DISHES", "42", Icons.restaurant_menu),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- Main Actions ---
                  GlassContainer(
                    blur: 10,
                    opacity: 0.1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            "QUESTS",
                            style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 2,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _buildGameButton(
                          context,
                          label: "MY FAVORITES",
                          icon: Icons.star,
                          color: Colors.orangeAccent,
                          onTap: () {},
                        ),
                        const SizedBox(height: 16),
                        _buildGameButton(
                          context,
                          label: "FOOD HISTORY",
                          icon: Icons.history,
                          color: Colors.blueAccent,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Logout Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => _signOut(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 10),
                          Text(
                            "LOG OUT",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGameButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
