import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Import Provider

import '../core/supabase_handler.dart';
import '../widgets/glass_container.dart';
import '../pages/login_page.dart'; // Import Handler
import '../pages/edit_profile_page.dart'; // Import Edit Page
import '../providers/theme_provider.dart'; // Import ThemeProvider
import '../handlers/user_handler.dart'; // Import UserHandler

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Stats từ UserHandler
  UserStats? _userStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserStats();
  }

  Future<void> _loadUserProfile() async {
    final user = SupabaseHandler().currentUser;
    if (user != null) {
      // Try to get fresh Signed URL first
      final signedUrl = await SupabaseHandler().getAvatarUrl(user.id);

      if (signedUrl != null) {
        if (mounted) {
          setState(() {
            _avatarUrl = signedUrl;
          });
        }
      } else {
        // Fallback to metadata if no fresh signed URL (though likely expired)
        final metaAvatar = user.userMetadata?['avatar_url'];
        if (metaAvatar != null && mounted) {
          setState(() {
            _avatarUrl = metaAvatar;
          });
        }
      }
    }
  }

  /// Load stats từ UserHandler (theo Guideline: UI gọi Handler)
  Future<void> _loadUserStats() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await UserHandler.getUserStats(context);
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('ProfilePage: Failed to load stats: $e');
      if (mounted) {
        setState(() {
          _userStats = UserStats.empty();
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    try {
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

      // Upload and get the new Signed URL directly
      final newUrl = await SupabaseHandler().uploadAvatar(file);

      // Evict the old image from cache if it exists
      if (_avatarUrl != null) {
        await NetworkImage(_avatarUrl!).evict();
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        setState(() {
          _isUploading = false;
          _avatarUrl = newUrl;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
        );
      }
    } catch (e) {
      debugPrint('Avatar Error: $e');
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        setState(() => _isUploading = false);
        messenger.showSnackBar(
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseHandler().currentUser;
    final email = user?.email ?? 'foodie@example.com';
    final name = user?.userMetadata?['full_name'] ?? 'Yêu Ẩm Thực';

    // Check global theme state
    final isDarkTheme = context.watch<ThemeProvider>().isDarkMode;

    const bgImage =
        'https://images.unsplash.com/photo-1543353071-873f17a7a088?q=80&w=1920&auto=format&fit=crop';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          // Refresh button to reload stats
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserStats,
            tooltip: 'Làm mới thống kê',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.network(bgImage, fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ), // Darker overlay
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
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
                            padding: const EdgeInsets.only(bottom: 24),
                            child: GestureDetector(
                              onTap: () => _pickAndUploadAvatar(context),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).primaryColor,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.5),
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
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Đổi ảnh",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
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

                      // --- Name ---
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- Stats Row ---
                      _isLoadingStats
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white70,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                  "ĐÃ ĐÁNH GIÁ",
                                  "${_userStats?.ratedCount ?? 0}",
                                  Icons.rate_review,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white24,
                                ),
                                _buildStatItem(
                                  "YÊU THÍCH",
                                  "${_userStats?.favoritesCount ?? 0}",
                                  Icons.favorite,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white24,
                                ),
                                _buildStatItem(
                                  "CHECK-IN",
                                  "${_userStats?.checkInCount ?? 0}",
                                  Icons.place,
                                ),
                              ],
                            ),

                      const SizedBox(height: 40),

                      // --- Menu Items ---
                      GlassContainer(
                        blur: 10,
                        opacity: 0.1,
                        child: Column(
                          children: [
                            _buildMenuItem(
                              context,
                              icon: Icons.person_outline,
                              label: "Hồ sơ của tôi",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfilePage(),
                                  ),
                                );
                              },
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.location_on_outlined,
                              label: "Địa chỉ của tôi",
                              onTap: () {
                                // Placeholder: Select address for recommendations
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Chức năng chọn địa điểm đang phát triển',
                                    ),
                                  ),
                                );
                              },
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            _buildMenuItem(
                              context,
                              icon: isDarkTheme
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              label: "Giao diện: ${isDarkTheme ? 'Tối' : 'Sáng'}",
                              onTap: () =>
                                  context.read<ThemeProvider>().toggleTheme(),
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.help_outline,
                              label: "Trợ giúp & Hỗ trợ",
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- Logout Button ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                              ),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _signOut(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Đăng xuất",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.white.withValues(alpha: 0.3),
        size: 14,
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
