# DECOUPLED DEVELOPMENT GUIDELINES
Mục tiêu: Giúp các bộ phận (Core, BE, FE, UI/UX) làm việc song song, giảm thiểu sự phụ thuộc (block) lẫn nhau và dễ dàng mở rộng dự án.

## 1. Triết lý chung: "Interface First - Implementation Later"
Để tránh việc Frontend phải ngồi chơi đợi Backend, hay UI đợi Logic, chúng ta sử dụng phương pháp Đóng gói (Wrapper/Handler).
- Mọi giao tiếp giữa các tầng phải thông qua các hàm/lớp trung gian (Wrapper).
- Nếu tính năng chưa sẵn sàng? Dùng Mock Data (dữ liệu giả) trả về từ Wrapper.
- Khi tính năng sẵn sàng? Chỉ cần thay logic bên trong Wrapper, không sửa code gọi bên ngoài.

## 2. Phân chia trách nhiệm (Roles)

| Bộ phận | Vai trò chính | Context cụ thể |
|---|---|---|
|**UI/UX**|Mặt tiền, Giao diện|Thiết kế thẩm mỹ, đặt các Placeholder cho dữ liệu động.|
|**Front-end**|Logic hiển thị, Wiring|Kết nối UI với dữ liệu. Tạo các Mock Handlers để chạy UI trước khi có API thật.|
|**Back-end**|Proxy, Secure Tools|Đóng vai trò Proxy Server. Cung cấp các API cần giấu key hoặc các logic mà Client không được phép làm trực tiếp.|
|**Core**|Logic cốt lõi, Hạ tầng|Setup Supabase (Auth, DB Schema), viết logic xử lý chính, cung cấp implementation thật cho các Handlers.|
## 3. Quy trình thực hiện (The Wrapper Pattern)
### 3.1. Đối với UI/UX: "Placeholder là bạn"
Không hardcode cứng nhắc text trong code giao diện nếu text đó có khả năng thay đổi. Hãy biến nó thành biến số hoặc hàm trả về.

**Quy tắc:**
- Gặp các trường như Title, Label, Description -> Đặt Placeholder hoặc comment rõ ràng.
- Tách nội dung cần hiển thị ra khỏi code giao diện (View).
```python
❌ Bad: Hardcode trực tiếp trong UI logic
label.text = "Nhà hàng Cơm Tấm Sài Gòn"

# ✅ Good: Dùng hàm wrapper để lấy dữ liệu (dễ dàng swap sau này)
def get_ui_title(context_params...) -> str:
    return "Placeholder Title" # FE sẽ thay thế logic này sau

# Trong UI code
label.text = get_ui_title(params...)
```

### 3.2. Đối với Front-end: "Fake it until you make it"
Frontend không cần đợi Core/Backend viết xong API mới làm việc. Hãy tự tạo **Interface (Handler)** và trả về dữ liệu giả.

**Quy tắc:**
- Định nghĩa rõ đầu vào (Input) và đầu ra (Output) mong muốn.
- Viết một Class/Function giả lập việc gọi API.
```python
# Định nghĩa Data Model mong muốn
class RestaurantResult:
    def __init__(self, name, address):
        self.name = name
        self.address = address

# Tạo một Handler GIẢ (Mock)
class RestaurantHandler:
    def search(self, keyword) -> List[RestaurantResult]:
        # TODO: Sẽ được thay thế bằng logic gọi API thật từ Core/Backend
        return [
            RestaurantResult(name="Test Restaurant 1", address="123 Fake St"),
            RestaurantResult(name="Test Restaurant 2", address="456 Mock Ave"),
        ]

# Sử dụng ngay trong code chính (Business Logic)
def on_user_search(keyword):
    handler = RestaurantHandler()
    results = handler.search(keyword) # Code chạy mượt mà dù chưa có Backend
    display_results(results)
```
### 3.3. Đối với Core & Back-end: "Fill in the blank"
Nhiệm vụ của Core là biến những cái "Giả" ở trên thành "Thật".

**Quy tắc:**
- **Với Core (Supabase/Logic):** Implement logic thực tế vào bên trong các hàm của Handler mà Frontend đã định nghĩa (hoặc tạo Handler mới match với interface đó).
- **Với Back-end (Proxy):** Expose các endpoint cho những tác vụ nhạy cảm (VD: Gọi 3rd party API cần Secret Key).
```python
# Core team vào sửa lại Class Handler cũ của Frontend
class RestaurantHandler:
    def __init__(self):
        self.supabase = create_client(...) # Core setup Supabase

    def search(self, keyword) -> List[RestaurantResult]:
        # ✅ Logic thật: Query từ Supabase hoặc gọi qua Backend Proxy
        response = self.supabase.table('restaurants').select('*').ilike('name', f'%{keyword}%').execute()
        return parse_response(response)
```

## 4. Xử lý Mismatch (Converters)
Khi ghép nối (Merge), thường xuyên xảy ra việc: *Frontend cần format A, nhưng Backend/Core trả về format B*.

**Giải pháp:** Dùng Converter (Adapter Pattern). Không sửa logic gốc của cả 2 bên, hãy sửa ở giữa.

- **Chiến lược 1:** Convert Trực tiếp (Cho logic đơn giản)
```python
backend_data = backend_api.get_data()

# Convert ngay tại chỗ
frontend_model = FrontendInput(
    display_name=backend_data['full_name'], # Mapping fields
    geo_lat=backend_data['location']['lat']
)
```
- **Chiến lược 2:** Converter Reusable (Khuyên dùng). Ta tách logic convert ra riêng để code gọn gàng và tái sử dụng được.
```python
# File: converters.py
def backend_to_frontend_adapter(be_data) -> FrontendInput:
    return FrontendInput(
        display_name=be_data.get('full_name', 'Unknown'),
        geo_lat=be_data.get('coords', {}).get('lat', 0.0)
    )

# File: main_logic.py
raw_data = backend_api.search(...)
clean_input = backend_to_frontend_adapter(raw_data) # Code rất sạch
process_ui(clean_input)
```

## 5. Lưu ý quan trọng (Best Practices)
- **Giao tiếp là chìa khóa:**
    + Trước khi implement tính năng mới, hãy thống nhất Input/Output (Data contract).
    + Nếu tự tạo Wrapper để làm tính năng mới, hãy báo cho team để đánh giá tính khả thi về mặt kỹ thuật.
- **Làm việc song song (Parallel Workflow):**
    + FE cứ mock data mà chạy UI.
    + BE/Core cứ viết logic xử lý data.
    + Cuối cùng ráp lại bằng cách thay ruột Handler hoặc dùng Converter. Đừng ai đợi ai cả.
- **Supabase Context:**
    + Auth, Security Rules (RLS), Table Structure là trách nhiệm của Core.
    + Frontend chỉ gọi Supabase SDK qua các Handler đã được Core cấu hình hoặc hướng dẫn.
- **Clean Code:**
    + Không bắt buộc quá khắt khe, nhưng ưu tiên sự rõ ràng (Readability).
    + Tên biến/hàm nên mô tả đúng chức năng (e.g., `get_user_profile` thay vì `get_data`).

---
Code vui vẻ nhá