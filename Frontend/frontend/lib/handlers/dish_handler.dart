import '../models/dish_model.dart';
// Note: This file uses local assets. Ensure pubspec.yaml includes assets/images/

class DishHandler {
  static List<DishItem> allDishes = [
    DishItem(
      id: '1',
      name: 'Cơm Tấm',
      description: 'Cơm tấm là món cơm nấu từ gạo tấm (hạt gạo vỡ), thường ăn kèm sườn nướng, bì, chả trứng và trứng ốp la. Đây là bữa sáng – trưa quen thuộc của người Sài Gòn nhờ hương vị đậm đà của thịt nướng than và nước mắm chua ngọt. Hạt cơm tơi, mềm kết hợp cùng miếng sườn ướp ngọt thơm tạo nên nét đặc trưng khó quên.',
      imageUrl: 'assets/images/com_tam.png',
      tags: ['Cơm Tấm', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '2',
      name: 'Hủ Tiếu',
      description: 'Hủ tiếu là món mì sợi gạo của miền Nam, chịu ảnh hưởng ẩm thực Hoa – Campuchia. Tô hủ tiếu có thể dùng dạng nước hoặc khô, thường kèm tôm, thịt, gan, trứng cút và tóp mỡ. Nước dùng hầm xương trong, ngọt thanh nhưng đậm đà. Người Sài Gòn ăn hủ tiếu mọi buổi trong ngày, từ gánh hủ tiếu gõ bình dân đến tiệm hủ tiếu Nam Vang nổi tiếng.',
      imageUrl: 'assets/images/hu_tieu.png',
      tags: ['Hủ Tiếu', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '3',
      name: 'Bánh Mì',
      description: 'Bánh mì Sài Gòn đã trở thành món ăn đường phố nổi tiếng toàn cầu – một ổ bánh mì giòn rụm kẹp nhân thịt chả, pate, bơ, dưa chua, rau thơm và chan chút nước xốt đậm đà. Bánh mì Sài Gòn có phần ruột vừa phải, vỏ mỏng giòn để ôm trọn “mười mấy tầng nhân” hấp dẫn. Mỗi tiệm bánh mì lại có bí quyết pate, xíu mại, chả lụa riêng, tạo nên hương vị đa dạng cho món ăn bình dân này.',
      imageUrl: 'assets/images/banh_mi.png',
      tags: ['Bánh Mì', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '4',
      name: 'Phở',
      description: 'Phở tuy có nguồn gốc Hà Nội nhưng đã sớm trở thành món ăn yêu thích ở Sài Gòn. Phở Sài Gòn mang nét riêng với nước dùng trong và hơi ngọt, thường ăn kèm rau thơm, giá trụng và chén tương đen, tương ớt. Một tô phở nóng với bánh phở mềm, thịt bò thái mỏng, hành ngò thơm lừng là lựa chọn hoàn hảo cho bữa sáng đủ đầy.',
      imageUrl: 'assets/images/pho.png',
      tags: ['Phở', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '5',
      name: 'Bún Bò Huế',
      description: 'Bún bò Huế gốc cố đô Huế nhưng rất được ưa chuộng ở Sài Gòn. Tô bún bò đúng điệu gồm bún sợi to, nước dùng đỏ cam thơm sả và mắm ruốc, vị đậm đà cay nồng. Nhân gồm thịt bắp bò, chả cua, huyết heo, giò heo. Khi ăn vắt thêm chanh, thêm sa tế ớt và rau sống (bắp chuối, giá, rau thơm) để dậy vị. Nhiều quán bún bò Huế ngon tại Sài Gòn do chính người Huế nấu, giữ được hương vị đặc trưng.',
      imageUrl: 'assets/images/bun_bo_hue.png',
      tags: ['Bún Bò Huế', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '6',
      name: 'Súp Cua',
      description: 'Súp cua – món ăn chơi “dễ chiều” của người Sài Gòn, thường được bán ở các xe đẩy hoặc quán nhỏ buổi xế chiều. Chén súp sệt sệt với thịt cua xé, trứng cút, nấm, đôi khi thêm óc heo, trứng bắc thảo… được rắc tiêu, ngò thơm phức, ăn nóng rất bổ dưỡng. Súp cua phù hợp cho cả người lớn lẫn trẻ nhỏ, vừa ngon miệng vừa giàu đạm canxi.',
      imageUrl: 'assets/images/sup_cua.png',
      tags: ['Súp Cua', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '7',
      name: 'Bánh Cuốn',
      description: 'Bánh cuốn – món bánh làm từ bột gạo hấp tráng mỏng, cuộn nhân thịt băm mộc nhĩ – là bữa sáng quen thuộc của người Sài Gòn. Bánh cuốn Sài Gòn chịu ảnh hưởng ẩm thực Bắc nên thường ăn kèm chả lụa, nem chua, đặc biệt không thể thiếu bát nước mắm chua ngọt pha loãng và hành phi vàng thơm rắc lên bánh. Biến tấu có bánh cuốn trứng (đập trứng vào bột khi tráng) hay bánh cuốn ngọt lá dứa.',
      imageUrl: 'assets/images/banh_cuon.png',
      tags: ['Bánh Cuốn', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '8',
      name: 'Phá Lấu',
      description: 'Phá lấu – món ăn vặt “huyền thoại” của học sinh Sài Gòn – thực chất là lòng bò heo hầm mềm trong nước dừa và ngũ vị hương. Một phần phá lấu bò đầy đủ có khăn lông, tổ ong, lá sách, gan… thái miếng vừa ăn, nước phá lấu sền sệt đậm đà, chấm kèm bánh mì hoặc mì gói. Mùi thơm béo của nước cốt dừa quyện với vị ngọt dai của nội tạng khiến ai thử một lần đều nhớ mãi. Ngoài món phá lấu nước truyền thống, giới trẻ còn biến tấu phá lấu xào me, phá lấu chiên, xiên nướng rất hấp dẫn.',
      imageUrl: 'assets/images/pha_lau.png',
      tags: ['Phá Lấu', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '9',
      name: 'Chè',
      description: 'Chè Sài Gòn vô cùng phong phú, kết tinh từ văn hóa ba miền và cộng đồng người Hoa. Từ các món chè “ta” như chè đậu trắng, chè trôi nước, xôi chè… đến chè Tàu như sâm bổ lượng, hột gà trà, cao quy linh đều có đủ. Chè thường được ăn như món tráng miệng hoặc quà chiều giải nhiệt. Cầm cốc chè mát lạnh ngọt thanh, vừa ăn vừa tán gẫu vỉa hè là thú vui bình dị của bao thế hệ người Sài Gòn.',
      imageUrl: 'assets/images/che.png',
      tags: ['Chè', 'Street Food', 'Authentic'],
    ),
    DishItem(
      id: '10',
      name: 'Bún Riêu',
      description: 'Crab and tomato noodle soup.',
      imageUrl: 'assets/images/bun_rieu.png',
      tags: ['Noodle', 'Crab', 'Soup'],
    ),
    DishItem(
      id: '11',
      name: 'Bún Thịt Nướng',
      description: 'Cold vermicelli with grilled pork and herbs.',
      imageUrl: 'assets/images/bun_thit_nuong.png',
      tags: ['Noodle', 'BBQ', 'Dry'],
    ),
    DishItem(
      id: '12',
      name: 'Bún Mắm',
      description: 'Fermented fish noodle soup with seafood.',
      imageUrl: 'assets/images/bun_mam.png',
      tags: ['Noodle', 'Fermented', 'Seafood'],
    ),
    DishItem(
      id: '13',
      name: 'Bánh Canh Cua',
      description: 'Thick tapioca noodles with crab broth.',
      imageUrl: 'assets/images/banh_canh_cua.png',
      tags: ['Noodle', 'Crab', 'Thick'],
    ),
    DishItem(
      id: '14',
      name: 'Bánh Khọt',
      description: 'Mini savory pancakes with shrimp.',
      imageUrl: 'assets/images/banh_khot.png',
      tags: ['Crispy', 'Pancake', 'Snack'],
    ),
    DishItem(
      id: '15',
      name: 'Bánh Tráng Trộn',
      description: 'Mixed rice paper salad with mango and beef jerky.',
      imageUrl: 'assets/images/banh_trang_tron.png',
      tags: ['Salad', 'Street Food', 'Spicy'],
    ),
    DishItem(
      id: '16',
      name: 'Gỏi Cuốn',
      description: 'Fresh spring rolls with shrimp and pork.',
      imageUrl: 'assets/images/goi_cuon.png',
      tags: ['Roll', 'Fresh', 'Healthy'],
    ),
    DishItem(
      id: '17',
      name: 'Ốc',
      description: 'Assorted snail dishes cooked in various sauces.',
      imageUrl: 'assets/images/oc.png',
      tags: ['Seafood', 'Street Food', 'Night'],
    ),
    DishItem(
      id: '18',
      name: 'Cơm Gà Xối Mỡ',
      description: 'Fried chicken with crispy skin and fried rice.',
      imageUrl: 'assets/images/com_ga.png',
      tags: ['Rice', 'Chicken', 'Lunch'],
    ),
    DishItem(
      id: '19',
      name: 'Cháo Lòng',
      description: 'Rice porridge with pork offal.',
      imageUrl: 'assets/images/chao_long.png',
      tags: ['Porridge', 'Offal', 'Breakfast'],
    ),
    DishItem(
      id: '20',
      name: 'Lẩu Cá Kèo',
      description: 'Hotpot with goby fish and river leaf creeper.',
      imageUrl: 'assets/images/lau_ca_keo.png',
      tags: ['Hotpot', 'Fish', 'Dinner'],
    ),
  ];

  Future<List<DishItem>> getAllDishes() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return allDishes;
  }

  Future<DishItem> getDishById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return allDishes.firstWhere((dish) => dish.id == id);
  }

  Future<List<DishItem>> searchDishes(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return allDishes
        .where((dish) =>
            dish.name.toLowerCase().contains(query.toLowerCase()) ||
            dish.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }
}
