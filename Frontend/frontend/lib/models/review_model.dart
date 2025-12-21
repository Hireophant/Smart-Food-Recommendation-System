/// Model cho đánh giá (Review) của người dùng về nhà hàng
class ReviewModel {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images; // Optional review images

  ReviewModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images = const [],
  });

  /// Mock data generator for testing
  static List<ReviewModel> getMockReviews() {
    return [
      ReviewModel(
        id: '1',
        userName: 'Nguyễn Văn A',
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        rating: 5.0,
        comment:
            'Nhà hàng rất tuyệt vời! Đồ ăn ngon, phục vụ tận tình. Sẽ quay lại lần sau.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        images: [
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        ],
      ),
      ReviewModel(
        id: '2',
        userName: 'Trần Thị B',
        userAvatar: 'https://i.pravatar.cc/150?img=5',
        rating: 4.5,
        comment:
            'Món ăn ngon, không gian ấm cúng. Giá cả hợp lý. Đáng để thử!',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        images: [],
      ),
      ReviewModel(
        id: '3',
        userName: 'Lê Minh C',
        userAvatar: 'https://i.pravatar.cc/150?img=12',
        rating: 4.0,
        comment:
            'Khá ổn, nhưng phải chờ lâu một chút. Món ăn thì ngon.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        images: [
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
        ],
      ),
      ReviewModel(
        id: '4',
        userName: 'Phạm Thu D',
        userAvatar: 'https://i.pravatar.cc/150?img=20',
        rating: 5.0,
        comment:
            'Tuyệt vời! Đây là nhà hàng yêu thích của tôi. Món gì cũng ngon.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        images: [],
      ),
      ReviewModel(
        id: '5',
        userName: 'Hoàng Văn E',
        userAvatar: 'https://i.pravatar.cc/150?img=33',
        rating: 3.5,
        comment: 'Bình thường, không có gì đặc biệt lắm.',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        images: [],
      ),
    ];
  }
}
