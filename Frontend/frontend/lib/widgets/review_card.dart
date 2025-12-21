import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../models/user_profile_model.dart';
import '../pages/user_profile_view_page.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget hiển thị một review (đánh giá) của người dùng
class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Row
            Row(
              children: [
                // Avatar - Clickable
                GestureDetector(
                  onTap: () {
                    // Navigate to user profile
                    final mockUser = UserProfileModel.getMockUsers().first;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileViewPage(
                          user: mockUser,
                          isCurrentUser: false,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(review.userAvatar),
                    onBackgroundImageError: (exception, stackTrace) {},
                    child: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Rating - Clickable
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to user profile
                      final mockUser = UserProfileModel.getMockUsers().first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileViewPage(
                            user: mockUser,
                            isCurrentUser: false,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Star Rating
                            Row(
                              children: List.generate(5, (index) {
                                if (index < review.rating.floor()) {
                                  return const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                } else if (index < review.rating) {
                                  return const Icon(
                                    Icons.star_half,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                } else {
                                  return Icon(
                                    Icons.star_border,
                                    size: 16,
                                    color: isDarkMode
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  );
                                }
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeago.format(review.createdAt, locale: 'vi'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Comment Text
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),

            // Review Images (if any)
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(review.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
