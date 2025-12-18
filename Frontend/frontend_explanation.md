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

## 2. User Flow (Luồng người dùng Mới - Updated Dec 2024)

### A. Trang chủ (Discover Page) - "Restaurant & Dish Discovery"
- **Giao diện**: Light Mode, Tông màu Teal/Green (#1ABC9C).
- **Map tích hợp**: Bản đồ OpenStreetMap hiển thị ngay trên đầu trang với pins nhà hàng.
- **Search & Filter**: 
  - Search bar với nút filter (tune icon)
  - Advanced Filter Sheet với 10 tags (Vietnamese, Asian, Western, Cafe, Dessert, Vegan, Cheap, Luxury, Cozy, Family)
  - Selected tags hiển thị dưới dạng chips có thể xóa
- **Tương tác Map**:
  - Tap vào pin nhà hàng → Hiển thị Quick View (ảnh, rating, khoảng cách)
  - Quick View có nút "Xem chi tiết" → Chuyển đến Restaurant Detail Page
- **Danh sách món ăn**: Lưới các món ăn (`DishCard`) bên dưới map.
- **Hành động chính**: Người dùng có thể:
  1. Tìm nhà hàng qua map + filter
  2. Chọn món ăn → Xem nhà hàng bán món đó

### B. Tìm nhà hàng theo món (Restaurant List Page)
- **Context**: Sau khi chọn món (VD: Phở Bò) từ Discover Page.
- **Logic**: `QuerySystem` lọc ra các nhà hàng có bán món đó.
- **Hiển thị**: Danh sách nhà hàng với ảnh, rating, khoảng cách.
- **Hành động**: Tap vào restaurant card → Restaurant Detail Page.

### C. Chi tiết nhà hàng (Restaurant Detail Page)
- Hiển thị menu chi tiết và thông tin quán.

### D. Chatbot (Chat Page)
- **Trợ lý ảo**: Chatbot UI với message bubbles, quick replies.
- **Mock responses**: Keyword matching cho demo (TODO: Backend integration).
- **Typing indicator**: Hiệu ứng typing animation khi bot trả lời.

---

## 3. Key Changes (So với phiên bản cũ)
- **Flow**: Dual discovery - "Tìm Nhà hàng qua Map/Filter" HOẶC "Tìm Món → Xem Nhà hàng".
- **Design**: Chuyển từ Dark Mode sang **Light Mode + Teal (#1ABC9C)** (Clean/Foodie feel).
- **Architecture**: Thêm `QuerySystem` để decouple UI khỏi việc gọi data raw.
- **Map Integration**: Bản đồ nhúng trực tiếp trong Discover Page thay vì tab riêng.
- **Filter System**: Advanced filter với tag-based filtering và search.
- **Chatbot**: Thêm trợ lý ảo với UI hoàn chỉnh (mock data).

## 4. Dữ liệu giả lập (Mock Data)
- **Dish Data**: Các món ăn phổ biến (Phở, Bún bò, Sushi...) được định nghĩa trong `DishModel`.
- **Restaurant Data**: Mock restaurants với coordinates, ratings, tags.
- **Chat Responses**: Keyword-based mock chatbot responses.
- **Mapping**: Hệ thống giả lập việc "tìm quán bán món này" thông qua ID mapping đơn giản.

## 5. Tính năng hiện tại
### Completed Features:
✅ Search bar với filter button  
✅ Advanced filter sheet (10 tags)  
✅ Map với restaurant pins (OpenStreetMap)  
✅ Quick view modal khi tap pin  
✅ Vietnamese localization 100%  
✅ Light mode với Teal theme  
✅ Chatbot UI với mock responses  
✅ Favorites system  
✅ Restaurant detail page  

### Files đã xóa (không còn dùng):
- ❌ `map_page.dart` - Đã tích hợp vào discover_page
- ❌ `restaurant_search_map_page.dart` - Đã merge vào discover_page
- ❌ `filter_bar.dart` - Thay bằng advanced_filter_sheet

### TODO (Backend Integration):
- [ ] Connect to real restaurant API
- [ ] Integrate actual chatbot AI
- [ ] User authentication
- [ ] Real-time location
- [ ] Favorites sync with backend
