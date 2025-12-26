import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Import Provider

import '../core/supabase_handler.dart';
import '../widgets/glass_container.dart';
import '../pages/login_page.dart';
import '../handlers/restaurant_handler.dart'; // Import Handler
import '../models/food_model.dart'; // Import Model
import '../widgets/restaurant_card.dart';
import '../pages/restaurant_detail_page.dart';
import '../pages/edit_profile_page.dart'; // Import Edit Page
import '../providers/theme_provider.dart'; // Import ThemeProvider

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  List<RestaurantItem> _navigationHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadHistory();
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

  void _loadHistory() {
    // Mocking navigation history by taking a subset of mock restaurants
    // In a real app, this would come from a local storage or backend service tracking clicks
    final allRestaurants = MockRestaurantHandler.mockRestaurants;
    if (allRestaurants.length >= 5) {
      setState(() {
        _navigationHistory = allRestaurants.sublist(0, 5); // Take first 5
      });
    } else {
      setState(() {
        _navigationHistory = allRestaurants;
      });
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

      await SupabaseHandler().uploadAvatar(file);

      final user = SupabaseHandler().currentUser;
      if (user != null) {
        final publicUrl = SupabaseHandler().getPublicAvatarUrl(user.id);
        final newUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

        if (_avatarUrl != null) {
          await NetworkImage(_avatarUrl!).evict();
        }

        if (mounted) {
          setState(() {
            _isUploading = false;
            _avatarUrl = newUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Avatar Error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
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
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.network(bgImage, fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ), // Darker overlay
          ),

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
                                      ).primaryColor.withOpacity(0.5),
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
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Stats Row ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("ĐÃ ĐÁNH GIÁ", "15", Icons.rate_review),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStatItem("YÊU THÍCH", "38", Icons.favorite),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStatItem("CHECK-IN", "42", Icons.place),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- Navigation History Section ---
                  // "lịch sử tui clidk vào nhà hàng chọn để coi đường đi"
                  if (_navigationHistory.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Lịch sử xem đường đi",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _navigationHistory.length,
                        itemBuilder: (context, index) {
                          final restaurant = _navigationHistory[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            child: RestaurantCard(
                              item: restaurant,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantDetailPage(
                                      restaurant: restaurant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

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
                          color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.1),
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
                        backgroundColor: Colors.redAccent.withOpacity(0.2),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.5),
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
            color: Colors.white.withOpacity(0.6),
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
        color: Colors.white.withOpacity(0.3),
        size: 14,
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
