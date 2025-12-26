import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../models/review_model.dart';
import '../widgets/review_card.dart';
import '../widgets/rating_summary_widget.dart';
import 'map_routing_page.dart';
import 'package:latlong2/latlong.dart';

class RestaurantDetailPage extends StatefulWidget {
  final RestaurantItem restaurant;

  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late List<ReviewModel> _reviews;
  late double _averageRating;
  late int _totalReviews;

  @override
  void initState() {
    super.initState();
    _reviews = ReviewModel.getMockReviews();
    _calculateRatingStats();
  }

  void _calculateRatingStats() {
    if (_reviews.isEmpty) {
      _averageRating = 0;
      _totalReviews = 0;
      return;
    }

    double sum = 0;
    for (var review in _reviews) {
      sum += review.rating;
    }
    _averageRating = sum / _reviews.length;
    _totalReviews = _reviews.length;
  }

  void _addReview(double rating, String comment) {
    setState(() {
      _reviews.insert(
        0,
        ReviewModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userName: 'Bạn',
          userAvatar: 'https://i.pravatar.cc/150?img=68',
          rating: rating,
          comment: comment,
          createdAt: DateTime.now(),
          images: [],
        ),
      );
      _calculateRatingStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.restaurant.imageUrl.startsWith('http')
                      ? Image.network(
                          widget.restaurant.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Image load error: $error');
                            return Container(
                              color: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[300],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant,
                                      size: 80,
                                      color: isDarkMode
                                          ? Colors.grey[600]
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Không thể tải ảnh',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          widget.restaurant.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[300],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant,
                                      size: 80,
                                      color: isDarkMode
                                          ? Colors.grey[600]
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Không thể tải ảnh',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),

          // Restaurant Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Name
                  Text(
                    widget.restaurant.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        widget.restaurant.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.restaurant.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Description Section
                  Center(
                    child: Text(
                      "Giới thiệu",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Nhà hàng ${widget.restaurant.name} là một trong những địa điểm ẩm thực nổi tiếng tại ${widget.restaurant.address}. "
                    "Với không gian ấm cúng và thực đơn đa dạng, chúng tôi cam kết mang đến trải nghiệm ẩm thực tuyệt vời nhất cho quý khách.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapRoutingPage(
                              restaurantName: widget.restaurant.name,
                              restaurantLocation: LatLng(
                                widget.restaurant.latitude,
                                widget.restaurant.longitude,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text("Chỉ đường"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Pill shape
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ======== REVIEWS & RATING SECTION ========
                  Center(
                    child: Text(
                      "Đánh giá & Bình luận",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating Summary
                  RatingSummaryWidget(
                    averageRating: _averageRating,
                    totalReviews: _totalReviews,
                    ratingDistribution: {
                      5: _reviews.where((r) => r.rating == 5).length,
                      4: _reviews
                          .where((r) => r.rating >= 4 && r.rating < 5)
                          .length,
                      3: _reviews
                          .where((r) => r.rating >= 3 && r.rating < 4)
                          .length,
                      2: _reviews
                          .where((r) => r.rating >= 2 && r.rating < 3)
                          .length,
                      1: _reviews.where((r) => r.rating < 2).length,
                    },
                  ),
                  const SizedBox(height: 16),

                  // Write Review Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showWriteReviewDialog(context, isDarkMode);
                      },
                      icon: const Icon(Icons.rate_review, color: Colors.white),
                      label: const Text('Viết đánh giá'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reviews List
                  ..._reviews
                      .map((review) => ReviewCard(review: review))
                      .toList(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog(BuildContext context, bool isDarkMode) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text(
            'Viết đánh giá',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Chia sẻ trải nghiệm của bạn...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // TODO: Add image picker
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement image picker functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tính năng upload ảnh đang được phát triển',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.add_photo_alternate,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  label: Text(
                    'Thêm ảnh (Sắp có)',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập nội dung đánh giá'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                _addReview(rating, commentController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cảm ơn đánh giá của bạn!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }
}
