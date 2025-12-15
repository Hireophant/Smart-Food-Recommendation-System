# DECOUPLED DEVELOPMENT GUIDELINES

> **Mục tiêu:** Giúp các bộ phận (Core, BE, FE, UI/UX) làm việc song song, giảm thiểu sự phụ thuộc (block) lẫn nhau và dễ dàng mở rộng dự án.

---

## 📌 Triết lý chung: "Interface First - Implementation Later"

Để tránh việc Frontend phải ngồi chơi đợi Backend, hay UI đợi Logic, chúng ta có thể sử dụng phương pháp **Đóng gói (Wrapper/Handler)**:

- **Giao tiếp qua lớp trung gian:** Mọi giao tiếp giữa các tầng nên thông qua các hàm/lớp trung gian (Wrapper).
- **Chưa sẵn sàng?** → Mock Data (dữ liệu giả) từ Wrapper để làm tạm.
- **Sẵn sàng rồi?** → Chỉ cần thay logic bên trong Wrapper, không động đến code gọi bên ngoài.

---

## 👥 Phân chia trách nhiệm

| Bộ phận | Vai trò chính | Nhiệm vụ cụ thể |
|---------|---------------|------------------|
| **UI/UX** | Mặt tiền, Giao diện | Thiết kế thẩm mỹ, đặt các Placeholder cho dữ liệu động |
| **Front-end** | Logic hiển thị, Wiring | Kết nối UI với dữ liệu. Tạo Mock Handlers để chạy UI trước khi có API thật |
| **Back-end** | Proxy, Secure Tools | Đóng vai trò Proxy Server. Cung cấp API cần giấu key hoặc logic nhạy cảm |
| **Core** | Logic cốt lõi, Hạ tầng | Setup Supabase (Auth, DB Schema), viết logic xử lý chính |

---

## 🔄 Quy trình thực hiện (The Wrapper Pattern)

### 🎨 Đối với UI/UX: "Placeholder là bạn"

Không hardcode cứng nhắc text trong code giao diện nếu text đó có khả năng thay đổi. Hãy biến nó thành biến số hoặc hàm trả về.

**Gợi ý:**
- Gặp các trường như Title, Label, Description → Đặt Placeholder hoặc comment rõ ràng
- Tách nội dung cần hiển thị ra khỏi code giao diện (View)

**Ví dụ:**
```python
❌ Bad: Hardcode trực tiếp trong UI logic
label.text = "Nhà hàng Cơm Tấm Sài Gòn"

✅ Good: Dùng hàm wrapper để lấy dữ liệu (dễ dàng swap sau này)
def get_ui_title(context_params...) -> str:
    return "Placeholder Title"  # FE sẽ thay thế logic này sau

# Trong UI code
label.text = get_ui_title(params...)
```

---

### 💻 Đối với Front-end: "Fake it until you make it"

Frontend không cần đợi Core/Backend viết xong API mới làm việc. Hãy tự tạo **Interface (Handler)** và trả về dữ liệu giả.

**Gợi ý:**
- Định nghĩa rõ đầu vào (Input) và đầu ra (Output) mong muốn
- Viết một Class/Function giả lập việc gọi API

**Ví dụ:**
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
    results = handler.search(keyword)  # Code chạy mượt mà dù chưa có Backend
    display_results(results)
```

---

### ⚙️ Đối với Core & Back-end: "Fill in the blank"

Nhiệm vụ của Core là biến những cái "Giả" ở trên thành "Thật".

**Gợi ý:**
- **Core (Supabase/Logic):** Implement logic thực tế vào Handler mà Frontend đã định nghĩa
- **Back-end (Proxy):** Expose các endpoint cho tác vụ nhạy cảm (VD: gọi 3rd party API cần Secret Key)

**Ví dụ:**
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

---

## 🔌 Xử lý Mismatch (Converters)

Khi ghép nối (Merge), thường xảy ra: *Frontend cần format A, nhưng Backend/Core trả về format B*.

**Giải pháp:** Dùng **Converter (Adapter Pattern)**. Không sửa logic gốc của cả 2 bên, hãy sửa ở giữa.

### Chiến lược 1: Convert Trực tiếp

*Dùng cho logic đơn giản*
```python
backend_data = backend_api.get_data()

# Convert ngay tại chỗ
frontend_model = FrontendInput(
    display_name=backend_data['full_name'], # Mapping fields
    geo_lat=backend_data['location']['lat']
)
```

### Chiến lược 2: Converter Reusable

*Khuyên dùng - Tách logic convert ra riêng để code gọn gàng và tái sử dụng*
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

---

## 💡 Lưu ý quan trọng (Best Practices)

### 💬 Giao tiếp là chìa khóa
- Trước khi implement tính năng mới, nên thống nhất Input/Output (Data contract)
- Nếu tự tạo Wrapper để làm tính năng mới, nên báo cho team để đánh giá tính khả thi

### 🔀 Làm việc song song (Parallel Workflow)
- FE cứ mock data mà chạy UI
- BE/Core cứ viết logic xử lý data
- Cuối cùng ráp lại bằng cách thay ruột Handler hoặc dùng Converter
- **Đừng ai đợi ai cả!**

### 🗄️ Supabase Context
- Auth, Security Rules (RLS), Table Structure là trách nhiệm của Core
- Frontend nên gọi Supabase SDK qua các Handler đã được Core cấu hình

### ✨ Clean Code
- Không bắt buộc quá khắt khe, nhưng ưu tiên sự rõ ràng (Readability)
- Tên biến/hàm nên mô tả đúng chức năng (VD: `get_user_profile` thay vì `get_data`)

---

## 🎯 Query System: Trung tâm điều phối công việc

> **Lưu ý:** Phần này là tùy chọn (Optional), chủ yếu dành cho Front-end/Back-end. Core và UI/UX chỉ cần biết sơ qua là được.

### Query System là gì?

**Query System** là một lớp trung gian nằm bên trên tầng Handlers, đóng vai trò "trung tâm điều phối" - nhận yêu cầu công việc từ một bên và giao việc cho đúng Handler xử lý.

**Ví dụ dễ hiểu:**

Tưởng tượng bạn đi khám bệnh lần đầu:
- Bạn chưa biết cần vào phòng khám nào
- Gặp **"lễ tân"** → kể triệu chứng → lễ tân chuyển tới đúng **"phòng khám"**

```
Query System = Lễ tân (điều phối)
Handlers = Các phòng khám (chuyên môn)
```

### Tại sao nên có Query System?

**Bối cảnh:**
- **A** (người dùng) và **B** (người cung cấp dịch vụ)
- **B** có hai Handler:
  - `QueryHandler`: chứa `QueryBook`, `QueryAuthor`
  - `StoreHandler`: chứa `StoreBook`, `StoreAuthor`
- **A** muốn dùng: `QueryBook`, `QueryAuthor`, `StoreBook`

#### ❌ Cách đơn giản (không dùng Query System)
**A** gọi trực tiếp:
```python
# A phải biết chính xác Handler nào có chức năng gì
result1 = QueryHandler().QueryBook(...)
result2 = QueryHandler().QueryAuthor(...)
result3 = StoreHandler().StoreBook(...)
```

**Vấn đề gì xảy ra?**

**1. A phải biết quá nhiều chi tiết nội bộ của B:**
- A không chỉ biết "công việc cần làm" mà còn phải biết "Handler nào làm"
- B thay đổi cấu trúc (VD: `StoreHandler` → `NewStoreHandler`) → A phải sửa code theo
- Handler trở nên cứng nhắc, khó thay đổi vì sợ ảnh hưởng bên ngoài

**2. Vấn đề bảo mật:**
- A dùng thẳng Handler → toàn bộ chức năng đều lộ ra
- Khó kiểm soát A chỉ dùng một số chức năng nhất định

#### ✅ Giải pháp: Query System

**Query System** đứng ở giữa A và các Handler của B. A chỉ cần nói "công việc cần làm", không cần biết Handler nào sẽ xử lý.

```python
# A chỉ cần gọi Query System
result1 = QuerySystem().QueryBook(...)
result2 = QuerySystem().QueryAuthor(...)
result3 = QuerySystem().StoreBook(...)
```

**Lợi ích:**

✅ **A chỉ cần biết công việc, không cần biết cách làm**
- Ban đầu: Làm X → gọi Y
- Sau này: Làm X → gọi Z và W
- A không cần quan tâm, cứ nhờ "làm X" là được

✅ **B dễ dàng thay đổi cấu trúc nội bộ**
- Thoải mái đổi Handler, thêm/bớt bước xử lý
- Không ảnh hưởng tới A

✅ **Kiểm soát bảo mật tốt hơn**
- Query System chỉ expose những công việc được phép
- Chức năng khác của Handler không bị lộ

### Ví dụ code minh họa

```python
# ========== Các Handler của B ==========

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

### Khi nào nên dùng Query System?

**💡 Gợi ý sử dụng:**

**1. Giữa UI/UX và Front-end**
- FE cung cấp Query System
- UI/UX gọi "công việc" mà không cần biết logic bên trong

**2. Trong nội bộ Back-end** (giữa Router và Handlers)
- Router nhận input từ FE
- Nhờ Query System làm công việc
- Thay vì Router gọi trực tiếp Handler

**📝 Lưu ý cho Back-end:**

Trong một số trường hợp, Query System có thể hơi dư thừa vì Router đã đóng vai trò trung gian.

Tuy nhiên, vẫn có thể áp dụng để:
- ✅ Tách bạch rõ ràng: Router xử lý HTTP, Query System quản lý logic
- ✅ Dễ thay đổi cách xử lý mà không ảnh hưởng Router

---

# 📋 CHI TIẾT CHO TỪNG BÊN

## 🗂️ Khu vực làm việc (Workspace Boundaries)

Để tránh các bên xâm phạm code lẫn nhau (VD: Core đi sửa code Backend), nên phân chia rõ phạm vi làm việc.

### 🎨 Phía Front-end và UI/UX

Tùy Framework, cách chia có thể khác nhau. Chủ yếu gồm:

```
UI/
  └── (Quản lý bởi UI/UX)
      Các bên khác hạn chế sửa code khu vực này.

Frontend/
  ├── (Quản lý bởi Front-end)
  │   Các bên khác hạn chế sửa code khu vực này.
  │
  └── Core/ (Optional)
      └── (Quản lý bởi Core team)
          Nếu Core viết modules/handlers cho Frontend dùng trực tiếp
          (thay vì qua Backend), sẽ làm ở đây.
          Frontend hạn chế sửa code khu vực này.
```

### ⚙️ Phía Back-end

Tương tự, Back-end chia thành:

```
Backend/
  ├── (Quản lý bởi Back-end team)
  │   Các bên khác hạn chế sửa code khu vực này, trừ...
  │
  └── core/
      └── (Quản lý bởi Core team của Backend)
          Backend và các bên khác hạn chế sửa code khu vực này.
```

### 🔧 Quy tắc cho Core

Core bao gồm nhiều Modules. Để tránh chồng chéo, mỗi Module nên có phần riêng:

```
Core/
  ├── Module1/
  │   └── (Phần của Module 1)
  ├── Module2/
  │   └── (Phần của Module 2)
  └── ...
```

**💡 Gợi ý:**
- Các module nên **độc lập**, không quá nhiều liên quan
- Module quá phức tạp? Chia thành **sub-module**:

```
Core/
  └── UnionModule/
      ├── Sub-Module1/
      └── Sub-Module2/
          └── Sub-Sub-Module1/ (Không khuyến khích)
```

**📌 Lưu ý:**
- Nên giữ **tối đa 2 tầng** (tránh Sub-Sub-Module) cho đơn giản
- Module quá dày? Chia sub-module rồi gom lại (tùy chọn, không bắt buộc)

### ⚖️ Quy luật khu vực làm việc

#### a. Làm việc trong phạm vi của mình
- **Chỉ nên làm việc "trong" khu vực của mình.**
- Kể cả khi muốn gọi `init/deinit` (ví dụ: Core MongoDB muốn khởi tạo, thì nhờ Backend làm hoặc xin Backend làm giúp, **đừng tự thêm vào**).
- Nếu cần viết models/schemas, thì viết trong khu vực của mình luôn.
- Đối với Core: nếu được phân một Module thì chỉ làm trong Module đó, không chạm vào module khác hay tạo module cùng cấp.

#### b. Xin phép trước khi "chen vào"
- Nếu muốn "xin chen vào" hoặc "làm giúp" trong khu vực khác, hãy **xin phép bên quản lý khu vực đó trước**.

#### c. Sử dụng `.gitignore`
- Trong khu vực làm việc của mình, **nên có file `.gitignore`**.
- **Mục đích:** Tránh push những file không mong muốn lên GitHub (như `__pycache__`, `node_modules`, `.env`, v.v.).
- **Lưu ý:** Một project có thể có nhiều file `.gitignore` ở các thư mục khác nhau. Mỗi file sẽ ignore relative với thư mục nó nằm trong.
- **Quan trọng:** Đừng push file `.gitignore` lên GitHub nếu nó chứa config cá nhân hoặc không cần thiết cho team.

### 🤔 Tại sao cần phân chia khu vực?

✅ **Tránh nhầm lẫn**
- "Ơ, ai sửa code của mình thế???"

✅ **Dễ tìm lỗi**
- Có bug → biết ai chịu trách nhiệm

✅ **Tăng tính độc lập**
- Làm việc song song hiệu quả hơn
- Giảm conflict (VD: Backend edit `app.py`, Core cũng edit → conflict!)

---

## 🏗️ Thiết kế Handlers và Query System

Có 3 cách implement: **Static**, **Object**, **Singleton**.

> Dưới đây minh họa cho Handler. Query System cũng thiết kế tương tự.

### 1️⃣ Cách 1: Static

**Khi nào dùng:** Đơn giản, không cần khởi tạo hay giữ state

```python
class StaticHandlerEx:
    @staticmethod
    def GetBook(*args):
        # Logic get book
        ...
    
    @staticmethod
    def SetBook(*args):
        # Logic set book
        ...

# Sử dụng
StaticHandlerEx.GetBook(...)
StaticHandlerEx.SetBook(...)
```

### 2️⃣ Cách 2: Object

**Khi nào dùng:** Cần giữ **state riêng** cho mỗi lần gọi, hoặc khởi tạo mỗi lần dùng

```python
class ObjectHandlerEx:
    def __init__(self, *args):
        # Lưu state cho session hiện tại
        self.state = ...
        
        # Khởi tạo session mới
        self.init_session(...)
    
    def GetBook(self, *args):
        # Logic get book
        ...
    
    def SetBook(self, *args):
        # Logic set book
        ...

# Sử dụng
handler = ObjectHandlerEx(...)
handler.GetBook(...)
handler.SetBook(...)
```

### 3️⃣ Cách 3: Singleton

**Khi nào dùng:** Cần **khởi tạo một lần duy nhất** trong suốt chương trình (lazy initialization)

```python
class SingletonHandlerEx:
    _instance = None  # Giữ instance duy nhất

    def __new__(cls, *args, **kwargs):
        # Chỉ tạo instance một lần duy nhất
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, *args):
        # Chỉ khởi tạo một lần
        if not hasattr(self, "_initialized"):
            self._initialized = True
            
            # Khởi tạo global state
            self.initialize()
            self.global_state = 1
    
    def initialize(self):
        # Logic khởi tạo
        ...
    
    def GetBook(self, *args):
        # Logic get book
        ...
    
    def SetBook(self, *args):
        # Logic set book
        ...

# Sử dụng
SingletonHandlerEx().global_state = 2
print(SingletonHandlerEx().global_state)  # Output: 2

# Lưu ý: initialize() chỉ được gọi một lần duy nhất
```

### 💡 Lựa chọn thiết kế phù hợp

**Gợi ý:**

✅ **Ưu tiên đơn giản**
- Static đủ dùng? Đừng dùng Object hay Singleton

✅ **Chọn đúng tình huống:**
- **Static** → Không cần state, không thay đổi
- **Object** → Cần state riêng mỗi lần gọi
- **Singleton** → Khởi tạo một lần, dùng chung state global

---

## ⬛ Quy tắc Hộp đen (Black-box Rule)

### Câu hỏi vui

Khi dùng ChatGPT, Gemini, Claude, bạn có biết bên trong nó chạy thế nào?

*"Input feed vào, forward qua layers, attention mechanisms..."*

**NAHHH, biết làm gì?**

Câu hỏi đúng: **"Lúc xài, bạn CẦN biết nó chạy thế nào không?"**

→ **KHÔNG!** Chỉ cần biết:
- Tính năng gì?
- Input/Output gì?
- Xài thế nào?

**Chấm hết.**

---

### Áp dụng vào đây

✅ **Guideline chỉ quy định Input/Output**
- Cái ruột bên trong? **Làm thế nào cũng được!**
- Team chỉ quan tâm đầu vào/đầu ra
- **Không có coding convention phức tạp**
- Không ép style code

> Mình là sinh viên, không phải dev Google/Microsoft. Thế thôi! 😄

---

## 💬 Giao tiếp giữa các bên

### Core cung cấp cho Backend/Frontend

Core có thể cung cấp:
- Một đống functions
- Client classes (giống Handler)

**Các cách thiết kế Client:**

*(Tương tự Handler - xem phần trên)*

**Client Tĩnh (Static):**
```python
class StaticClient:
    @staticmethod
    def DoTask(*args):
        ...
    
    @staticmethod
    def AnotherTask(*args):
        ...

# Sử dụng
StaticClient.DoTask(...)
```

**Client Object:**
```python
class ObjectClient:
    def __init__(self, *args):
        self.session = ...
        self.initialize_connection(...)
    
    def DoTask(self, *args):
        ...
    
    def AnotherTask(self, *args):
        ...

# Sử dụng
client = ObjectClient(...)
client.DoTask(...)
```

**Client Singleton:**
```python
class SingletonClient:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, *args):
        if not hasattr(self, "_initialized"):
            self._initialized = True
            self.connection = self.establish_connection()
    
    def establish_connection(self):
        # Logic kết nối
        ...
    
    def DoTask(self, *args):
        ...
    
    def AnotherTask(self, *args):
        ...

# Sử dụng
SingletonClient().DoTask(...)
```

### Chi tiết giao tiếp

Mỗi bên cần cung cấp thông tin **Input/Output** rõ ràng:

| Bên | Cần cung cấp |
|-----|--------------|
| **Core** | Module gì, module làm được "công việc gì", Input/Output từng "công việc" (schemas), "gọi như nào" |
| **Back-end** | Giống Core, nhưng là route/routers (có thể không cần do có auto-gen docs) |
| **Front-end** | Giống Core, nhưng là tính năng/chức năng cung cấp |
| **UI/UX** | Cần nhận những gì từ Front-end |

### 📚 Tài liệu (Documentation)

Mỗi Module nên viết file docs:
- ✅ Core: Mỗi Module một file
- ⚠️ Backend: Tùy chọn (có auto-gen docs thì không cần)
- ✅ Frontend: Mỗi Module/tính năng một file
- ✅ UI/UX: Mô tả cần gì từ FE

> Template docs sẽ cung cấp sau trong file riêng

---

**📌 Lưu ý cuối:** Guideline này vẫn đang được mở rộng và cập nhật theo tình hình thực tế dự án.

---

**Code vui vẻ nhá!** 🚀✨