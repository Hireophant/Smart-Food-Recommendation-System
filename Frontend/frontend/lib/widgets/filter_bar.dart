import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = [
      "Đang mở cửa",
      "Cà phê",
      "Phở & Bún",
      "Cơm",
      "Bánh Mì",
      "Đánh giá cao",
      "Giá rẻ",
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length + 1, // +1 for "More Filters"
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == filters.length) {
            return _buildChip("Bộ lọc", isMore: true);
          }
          return _buildChip(
            filters[index],
            isSelected: index == 0,
          ); // Mock selection
        },
      ),
    );
  }

  Widget _buildChip(
    String label, {
    bool isSelected = false,
    bool isMore = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2C2C2C)
            : Colors.transparent, // Selected bg
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF444444),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        children: [
          if (isSelected) ...[
            const Icon(Icons.check, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[400],
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
