# Frontend Explanation - Smart Food Recommendation System

## 1. Architecture Overview (Updated)
Dự án áp dụng **Layered Architecture** với **Query System** làm trung tâm điều phối.

### Các tầng chính:
- **Presentation (UI)**:
    - **Components**: `DishCard` (hiển thị món ăn), `RestaurantCard`, `Pages`.
    - **Logic**: UI chỉ gọi `QuerySystem`, không gọi trực tiếp Handler.
- **Application Logic (Facades)**:
    - `QuerySystem`: Class trung gian (Singleton), cung cấp các hàm logic nghiệp vụ cao cấp (`getAllDishes`, `findRestaurantsByDish`).
- **Data Access (Handlers)**:
    - `FoodSearchHandler`: Interface giao tiếp với nguồn dữ liệu (Mock hoặc API thật).

---

## 2. User Flow (Luồng người dùng Mới)

### A. Trang chủ (Discover Page) - "Dish First"
- **Giao diện**: Light Mode, Tông màu Teal/Green (FoodFinder style).
- **Hero Banner**: "Find your perfect dish" tạo ấn tượng thị giác.
- **Tìm kiếm**: Tập trung vào tìm món ăn (Phở, Cơm tấm...).
- **Danh sách món**: Hiển thị lưới các món ăn hấp dẫn (`DishCard`) thay vì danh sách nhà hàng hỗn độn.
- **Hành động**: Người dùng chọn **Món ăn** mình muốn ăn trước.

### B. Tìm nhà hàng (Map Page)
- **Context**: Sau khi chọn món (VD: Phở Bò), chuyển sang màn hình Bản đồ.
- **Logic**: `QuerySystem` lọc ra các nhà hàng có bán món đó.
- **Hiển thị**: Ghim (Pin) các nhà hàng trên bản đồ OpenStreetMap.
- **Chi tiết**: Bấm vào Pin để xem tóm tắt thông tin nhà hàng.

### C. Chi tiết nhà hàng (Restaurant Detail Page)
- Hiển thị menu chi tiết và thông tin quán.

---

## 3. Key Changes (So với phiên bản cũ)
- **Flow**: Đổi từ "Tìm Nhà hàng -> Xem Menu" sang "Tìm Món -> Xem Nhà hàng".
- **Design**: Chuyển từ Dark Mode (Hacker/Tech feel) sang **Light Mode + Teal** (Clean/Foodie feel).
- **Architecture**: Thêm `QuerySystem` để decouple UI khỏi việc gọi data raw.

## 4. Dữ liệu giả lập (Mock Data)
- **Dish Data**: Các món ăn phổ biến (Phở, Bún bò, Sushi...) được định nghĩa trong `DishModel`.
- **Mapping**: Hệ thống giả lập việc "tìm quán bán món này" thông qua ID mapping đơn giản.
