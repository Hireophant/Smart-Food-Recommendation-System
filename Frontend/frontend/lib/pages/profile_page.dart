import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/favorites_provider.dart';

/// Model đại diện cho User Profile
class UserProfile {
  final String name;
  final String email;
  final String? avatarUrl;
  final String joinDate;
  final int reviewsCount;
  final int photosCount;

  UserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.joinDate,
    this.reviewsCount = 0,
    this.photosCount = 0,
  });
}

/// Trang Profile - Hiển thị thông tin người dùng và settings
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Mock user data - Sẽ thay thế bằng dữ liệu thật từ backend/auth
  final UserProfile _userProfile = UserProfile(
    name: 'Food Lover',
    email: 'foodlover@example.com',
    avatarUrl: null,
    joinDate: 'December 2025',
    reviewsCount: 42,
    photosCount: 128,
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng chỉnh sửa sắp ra mắt!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context),
            const SizedBox(height: 16),

            // Stats Section
            _buildStatsSection(context, favoritesProvider),
            const SizedBox(height: 16),

            // Settings & Options
            _buildSettingsSection(context, themeProvider),
            const SizedBox(height: 16),

            // Activity Section
            _buildActivitySection(context),
            const SizedBox(height: 16),

            // Account Actions
            _buildAccountActions(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: _userProfile.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      _userProfile.avatarUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person, size: 50, color: Color(0xFF1ABC9C)),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _userProfile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            _userProfile.email,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 8),

          // Join Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Đã tham gia ${_userProfile.joinDate}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    FavoritesProvider favoritesProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.favorite,
              count: favoritesProvider.totalFavorites,
              label: 'Yêu thích',
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.rate_review,
              count: _userProfile.reviewsCount,
              label: 'Đánh giá',
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.photo_library,
              count: _userProfile.photosCount,
              label: 'Ảnh',
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildSettingsTile(
              context,
              icon: Icons.dark_mode,
              title: 'Chế độ tối',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              context,
              icon: Icons.notifications,
              title: 'Thông báo',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cài đặt thông báo sắp ra mắt!'),
                    ),
                  );
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              context,
              icon: Icons.language,
              title: 'Ngôn ngữ',
              subtitle: 'Tiếng Việt',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cài đặt ngôn ngữ sắp ra mắt!')),
                );
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              context,
              icon: Icons.location_on,
              title: 'Vị trí',
              subtitle: 'Hanoi, Vietnam',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cài đặt vị trí sắp ra mắt!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Hoạt động',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildActivityTile(
              context,
              icon: Icons.history,
              title: 'Lịch sử tìm kiếm',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lịch sử tìm kiếm sắp ra mắt!')),
                );
              },
            ),
            const Divider(height: 1),
            _buildActivityTile(
              context,
              icon: Icons.bookmark,
              title: 'Tìm kiếm đã lưu',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tìm kiếm đã lưu sắp ra mắt!')),
                );
              },
            ),
            const Divider(height: 1),
            _buildActivityTile(
              context,
              icon: Icons.map,
              title: 'Địa điểm đã đến',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Địa điểm đã đến sắp ra mắt!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildActionTile(
              context,
              icon: Icons.privacy_tip,
              title: 'Chính sách quyền riêng tư',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chính sách quyền riêng tư sắp ra mắt!'),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              context,
              icon: Icons.help,
              title: 'Trợ giúp & Hỗ trợ',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trợ giúp & Hỗ trợ sắp ra mắt!'),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              context,
              icon: Icons.info,
              title: 'Giới thiệu',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              context,
              icon: Icons.logout,
              title: 'Đăng xuất',
              textColor: Colors.red,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildActivityTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.chevron_right, color: textColor),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Về Ứng dụng'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hệ thống gợi ý món ăn thông minh'),
            SizedBox(height: 8),
            Text('Phiên bản 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Hệ thống gợi ý nhà hàng sử dụng AI, truy vấn địa lý và thuật toán tính điểm thông minh.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đăng xuất thành công')),
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
