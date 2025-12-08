# Frontend Explanation - Smart Food Recommendation System

## 1. Architecture Overview
Dự án được xây dựng theo kiến trúc **Layered Architecture** đơn giản, tuân thủ nguyên tắc **"Interface First"** (Giao diện trước - Cài đặt sau) để đảm bảo việc phát triển giao diện (Frontend) không bị phụ thuộc chặt chẽ vào Backend.

### Các thành phần chính:
- **Pages (Màn hình)**: Chứa giao diện người dùng chính (`DiscoverPage`, `MapPage`, `RestaurantDetailPage`).
- **Widgets (Thành phần UI)**: Các widget tái sử dụng (`RestaurantCard`, `FilterBar`).
- **Models (Dữ liệu)**: Định nghĩa cấu trúc dữ liệu (`RestaurantItem`, `MenuItem`).
- **Handlers (Xử lý logic)**: Lớp trung gian chịu trách nhiệm lấy và xử lý dữ liệu.
    - `FoodSearchHandler`: Interface định nghĩa các hành động (tìm kiếm, lấy chi tiết, lấy menu).
    - `MockFoodSearchHandler`: Class cài đặt interface này, sử dụng **Mock Data** (dữ liệu giả lập) và **OSM API** (OpenStreetMap) để phục vụ UI ngay lập tức.

---

## 2. User Flow (Luồng người dùng)

### A. Khám phá (Discover Page)
- **Mục đích**: Người dùng tìm kiếm và xem danh sách nhà hàng.
- **Tính năng**:
    - **Tìm kiếm**: Nhập từ khóa (ví dụ: "Pho", "Cafe") để tìm. Hệ thống sẽ tìm trong dữ liệu giả lập VÀ gọi API thực từ OpenStreetMap (Nominatim).
    - **Bộ lọc (Filter)**: Các chip chọn nhanh (Đang mở cửa, Cà phê...).
    - **Danh sách**: Hiển thị dạng lưới (Grid) các `RestaurantCard`.
    - **Navigation**:
        - Bấm vào một thẻ nhà hàng -> Chuyển đến **Bản đồ** (Map Page) và focus vào nhà hàng đó.
        - Bấm icon bản đồ trên thanh công cụ -> Chuyển đến **Bản đồ** xem tổng quan.

### B. Bản đồ (Map Page)
- **Mục đích**: Xem vị trí nhà hàng trực quan trên bản đồ.
- **Thư viện**: Sử dụng `flutter_map` và `latlong2` để hiển thị gạch bản đồ từ OpenStreetMap (OSM).
- **Tính năng**:
    - Hiển thị các điểm ghim (Marker) cho các nhà hàng.
    - **Tương tác**: Bấm vào Pin sẽ hiện hộp thoại thông tin sơ lược.
    - **Chọn**: Bấm nút "Chọn" trong hộp thoại để xem chi tiết nhà hàng.

### C. Chi tiết Nhà hàng (Restaurant Detail Page)
- **Mục đích**: Xem thông tin chi tiết và thực đơn.
- **Tính năng**:
    - Hiển thị ảnh bìa, tên, đánh giá.
    - **Thực đơn (Menu)**: Danh sách các món ăn (giả lập).

---

## 3. Key Dependencies (Thư viện chính)

| Thư viện | Mục đích |
| :--- | :--- |
| `flutter_map` | Hiển thị bản đồ OpenStreetMap. |
| `latlong2` | Xử lý tọa độ địa lý (Latitude/Longitude). |
| `http` | Gọi API tìm kiếm địa điểm từ Nominatim (OSM). |

## 4. Ghi chú quan trọng
- **Ảnh (Images)**: Sử dụng đường dẫn ảnh thật từ **Unsplash** (Network Image) để giao diện đẹp và thực tế.
- **Dữ liệu**:
    - Các nhà hàng "Hot" (THAIYEN, Cafe de Flore...) là dữ liệu cứng (Hardcoded Mock Data) để đảm bảo demo luôn đẹp.
    - Kết quả tìm kiếm có thể trả về địa điểm thật từ OSM nếu từ khóa phù hợp.
