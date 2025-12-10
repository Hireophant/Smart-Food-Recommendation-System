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

## 6. Query System: Trung tâm điều phối công việc (Optional - cho FE/BE)

### 6.1. Query System là gì?
**Query System** là một lớp trung gian nằm bên trên tầng Handlers, đóng vai trò là "trung tâm điều phối" - nhận yêu cầu công việc từ một bên và giao việc cho đúng Handler xử lý.

*Phần này là tùy chọn (Optional), chủ yếu dành cho Front-end/Back-end. Core và UI/UX chỉ cần biết sơ qua là được.*

**Ví dụ minh họa:**
Hãy tưởng tượng bạn đi khám bệnh lần đầu - bạn chưa biết mình cần vào phòng khám nào. Đầu tiên, bạn sẽ gặp **"lễ tân/tiếp tân"**, kể triệu chứng, và lễ tân sẽ chuyển bạn tới đúng **"chuyên khoa/phòng khám"** phù hợp.

- **Query System** = Lễ tân (trung tâm điều phối)
- **Handlers** = Các chuyên khoa/phòng khám

### 6.2. Tại sao nên có Query System?

Giả sử có hai bên: **A** (người dùng) và **B** (người cung cấp dịch vụ).
**B** có hai Handler:
- `QueryHandler`: có các chức năng `QueryBook`, `QueryAuthor`
- `StoreHandler`: có các chức năng `StoreBook`, `StoreAuthor`

**A** muốn dùng ba tính năng: `QueryBook`, `QueryAuthor`, và `StoreBook`.

#### Cách đơn giản (không dùng Query System):
**A** gọi trực tiếp:
```python
# A phải biết chính xác Handler nào có chức năng gì
result1 = QueryHandler().QueryBook(...)
result2 = QueryHandler().QueryAuthor(...)
result3 = StoreHandler().StoreBook(...)
```

**Vấn đề phát sinh:**

1. **A phải biết quá nhiều chi tiết cấu trúc nội bộ của B:**
   - A không chỉ biết "công việc cần làm" mà còn phải biết "Handler nào làm việc đó".
   - Nếu B thay đổi cấu trúc (ví dụ: đổi từ `StoreHandler` sang `NewStoreHandler`), A cũng phải sửa code theo.
   - Về phía B: các Handler trở nên "cứng nhắc" vì có bên ngoài đang dùng trực tiếp. Muốn thay đổi thì phải lo ảnh hưởng tới tất cả bên dùng, hoặc bị buộc phải over-engineer ngay từ đầu để cover mọi tình huống.

2. **Vấn đề bảo mật/giới hạn chức năng:**
   - Nếu A dùng thẳng Handler, toàn bộ chức năng của Handler đều bị lộ ra ngoài.
   - Khó kiểm soát được việc A chỉ nên dùng một số chức năng nhất định.

#### Giải pháp: Query System

**Query System** đứng ở giữa A và các Handler của B. A chỉ cần nói "công việc cần làm", không cần biết Handler nào sẽ xử lý.

```python
# A chỉ cần gọi Query System
result1 = QuerySystem().QueryBook(...)
result2 = QuerySystem().QueryAuthor(...)
result3 = QuerySystem().StoreBook(...)
```

**Lợi ích:**

- **A không cần biết cách làm, chỉ cần biết công việc:**
  Giả sử ban đầu để làm công việc X, B phải làm Y. Sau này B thay đổi, để làm X thì phải làm Z và W.
  → A không cần quan tâm, nó chỉ nhờ B "làm công việc X". B tự biết cách làm mới như thế nào.

- **Dễ dàng thay đổi cấu trúc nội bộ:**
  B có thể thoải mái thay đổi Handler, thêm/bớt bước xử lý bên trong mà không ảnh hưởng tới A.

- **Kiểm soát bảo mật tốt hơn:**
  Query System chỉ "nhận" những công việc được phép từ A. Các chức năng khác của Handler sẽ không bị lộ ra ngoài.

### 6.3. Ví dụ code minh họa

```python
# ===== Các Handler của B =====

class QueryHandler:
    def QueryBook(self, *args):
        # Logic query book
        ...

    def QueryAuthor(self, *args):
        # Logic query author
        ...

class StoreHandler:
    def StoreBook(self, *args):
        # Logic store book
        ...

    def StoreAuthor(self, *args):
        # Logic store author
        ...

# ===== Handler mới (ví dụ khi B muốn thay đổi cách làm) =====

class NewStoreHandler:
    def StoreBook(self, *args):
        # Logic store book mới
        ...

    def ProcessBook(self, *args):
        # Bước xử lý bổ sung (phải gọi sau StoreBook)
        ...

    def StoreAuthor(self, *args):
        # Logic store author
        ...

# ===== Query System của B (cung cấp cho A) =====

class QuerySystem:
    """
    Chỉ expose các công việc mà B cho phép A làm.
    A chỉ cần biết tên công việc, không cần biết Handler nào xử lý.
    """

    def QueryBook(self, *args):
        # Gọi Handler tương ứng
        return QueryHandler().QueryBook(*args)

    def QueryAuthor(self, *args):
        return QueryHandler().QueryAuthor(*args)

    def StoreBook(self, *args):
        # Phiên bản cũ (đơn giản)
        # StoreHandler().StoreBook(*args)

        # Phiên bản mới (thay đổi logic bên trong, A không cần sửa code)
        handler = NewStoreHandler()
        handler.StoreBook(*args)
        handler.ProcessBook(*args)  # Thêm bước xử lý mới

# ===== Code bên A (người dùng) =====

# Khi cần query book
result = QuerySystem().QueryBook(...)

# Khi cần query author
result = QuerySystem().QueryAuthor(...)

# Khi cần store book
# ✅ Lưu ý: Dù B thay đổi logic bên trong (từ StoreHandler sang NewStoreHandler),
# A vẫn không cần sửa code này
result = QuerySystem().StoreBook(...)
```

### 6.4. Khi nào nên dùng Query System?

**Nên dùng:**
- Giữa **UI/UX** và **Front-end**: Front-end cung cấp Query System để UI/UX gọi các "công việc" mà không cần biết logic bên trong.
- Trong nội bộ **Back-end**: Giữa **Router/Route** và **Handlers**. Router chỉ nhận input từ Front-end và "nhờ Query System làm công việc", thay vì Router trực tiếp gọi Handler.

**Lưu ý cho Back-end:**
- Trong một số trường hợp, Query System có thể hơi dư thừa vì **Router/Route** đã đóng vai trò trung gian giữa Front-end và Back-end.
- Tuy nhiên, vẫn có thể áp dụng Query System giữa Router và Handlers để:
  - Tách bạch rõ ràng: Router chỉ xử lý HTTP request/response, Query System quản lý logic "gọi đúng Handler".
  - Dễ dàng thay đổi cách thức xử lý công việc mà không ảnh hưởng tới Router.

---
code vui vẻ nhá