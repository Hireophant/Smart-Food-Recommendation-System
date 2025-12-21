/// Model thông tin người dùng
class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int level;
  final int likesCount;
  final int dishesCount;
  final int reviewsCount;
  final String bio;
  final DateTime joinedDate;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.level = 1,
    this.likesCount = 0,
    this.dishesCount = 0,
    this.reviewsCount = 0,
    this.bio = '',
    required this.joinedDate,
  });

  /// Mock data generator
  static UserProfileModel getMockCurrentUser() {
    return UserProfileModel(
      id: 'current_user',
      name: 'MasterChef',
      email: 'masterchef@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=68',
      level: 15,
      likesCount: 380,
      dishesCount: 42,
      reviewsCount: 28,
      bio: 'Yêu thích khám phá ẩm thực, đặc biệt là món Việt Nam truyền thống.',
      joinedDate: DateTime.now().subtract(const Duration(days: 365)),
    );
  }

  /// Mock data for other users
  static List<UserProfileModel> getMockUsers() {
    return [
      UserProfileModel(
        id: '1',
        name: 'Nguyễn Văn A',
        email: 'nguyenvana@example.com',
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
        level: 12,
        likesCount: 240,
        dishesCount: 35,
        reviewsCount: 42,
        bio: 'Food blogger | Reviewer | Saigon 🍜',
        joinedDate: DateTime.now().subtract(const Duration(days: 200)),
      ),
      UserProfileModel(
        id: '2',
        name: 'Trần Thị B',
        email: 'tranthib@example.com',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        level: 8,
        likesCount: 150,
        dishesCount: 28,
        reviewsCount: 35,
        bio: 'Khám phá món ngon khắp nơi 🌟',
        joinedDate: DateTime.now().subtract(const Duration(days: 150)),
      ),
    ];
  }
}
