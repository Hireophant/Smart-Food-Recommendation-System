# GUIDELINE NHANH - DECOUPLED DEVELOPMENT

> **TL;DR:** Làm song song, không đợi nhau. Dùng Mock → Swap thật sau. Chill thôi! 😎

---

## 🎯 Triết lý: "Interface First - Implementation Later"

**Wrapper/Handler** = Lớp trung gian giữa các tầng
- **Chưa có API?** → Mock data tạm
- **Có API rồi?** → Thay ruột Wrapper, code gọi không đổi

---

## 👥 Ai làm gì?

| Team | Làm gì |
|------|--------|
| **UI/UX** | Design + Placeholder cho data động |
| **Front-end** | Mock Handler → Chạy UI trước, API sau |
| **Back-end** | Proxy API nhạy cảm (hide keys) |
| **Core** | Logic thật (DB, Auth, Processing) |

---

## 🔄 Quy trình làm việc

### 🎨 UI/UX: Dùng Placeholder
```python
# ❌ Hardcode
label.text = "Nhà hàng ABC"

# ✅ Dùng hàm
def get_ui_title(): return "Placeholder"
label.text = get_ui_title()
```

### 💻 Front-end: Mock Data
```python
class RestaurantHandler:
    def search(self, keyword):
        # TODO: Sẽ thay bằng API thật
        return [
            {"name": "Test 1", "address": "123 Fake St"},
            {"name": "Test 2", "address": "456 Mock Ave"}
        ]
```

### ⚙️ Core/Backend: Thay Logic Thật
```python
class RestaurantHandler:
    def search(self, keyword):
        # ✅ Query thật từ DB
        return db.query('restaurants').filter(keyword)
```

---

## 🔌 Xử lý Format Mismatch: Converter

```python
# Backend trả format khác FE cần? → Dùng Adapter
def backend_to_frontend(data):
    return {
        "display_name": data['full_name'],
        "lat": data['coords']['lat']
    }

# Sử dụng
raw = backend_api.get_data()
clean = backend_to_frontend(raw)
```

---

## 💡 Best Practices

✅ **Giao tiếp:** Thống nhất Input/Output trước khi code  
✅ **Song song:** FE mock, BE code thật, cuối ráp lại  
✅ **Clean Code:** Tên hàm/biến rõ ràng, dễ đọc  
✅ **Đừng đợi:** Ai cũng làm được việc của mình ngay

---

## 🎯 Query System (Optional - FE/BE chính)

### Là gì?
**Lễ tân điều phối** - Nhận yêu cầu → Giao đúng Handler

```
Bạn → Lễ tân (Query System) → Phòng khám (Handler)
```

### Tại sao?
- **A gọi trực tiếp Handler B:** A phải biết Handler nào làm gì → Rối
- **A gọi qua Query System:** A chỉ cần nói công việc → Đơn giản

### Code ví dụ
```python
# ❌ Không dùng Query System
result1 = QueryHandler().QueryBook(...)
result2 = StoreHandler().StoreBook(...)

# ✅ Dùng Query System
result1 = QuerySystem().QueryBook(...)
result2 = QuerySystem().StoreBook(...)
# → Đổi Handler bên trong, A không cần sửa code
```

### Khi nào dùng?
- UI/UX ↔ Front-end
- Router ↔ Handlers (Backend)

---

## 🗂️ Khu vực làm việc

### Phân chia workspace
```
Frontend/
  ├── (FE làm)
  └── Core/ (Core làm - FE đừng sửa)

Backend/
  ├── (BE làm)
  └── core/ (Core làm - BE đừng sửa)
```

### Quy tắc
1. **Làm trong khu của mình** - Đừng sửa code khu người khác
2. **Cần sửa khu khác?** → Xin phép trước
3. **Dùng `.gitignore`** - Tránh push `__pycache__`, `.env`, etc.

### Tại sao?
✅ Tránh conflict  
✅ Dễ tìm bug → Biết ai chịu trách nhiệm  
✅ Làm song song hiệu quả

---

## 🏗️ 3 Cách Thiết kế Handler

### 1️⃣ Static - Đơn giản, không cần state
```python
class Handler:
    @staticmethod
    def GetBook(): ...

Handler.GetBook()
```

### 2️⃣ Object - Cần state riêng
```python
class Handler:
    def __init__(self):
        self.state = {}
    def GetBook(self): ...

handler = Handler()
handler.GetBook()
```

### 3️⃣ Singleton - Khởi tạo 1 lần, dùng global
```python
class Handler:
    _instance = None
    def __new__(cls):
        if not cls._instance:
            cls._instance = super().__new__(cls)
        return cls._instance
    def __init__(self):
        if not hasattr(self, "_init"):
            self._init = True
            self.global_state = {}

Handler().GetBook()
```

**Chọn gì?**
- Static → Đủ xài là dùng
- Object → Cần state riêng mỗi lần
- Singleton → Cần state global, init 1 lần

---

## ⬛ Quy tắc Hộp Đen (Black-box)

**Câu hỏi:** Xài ChatGPT, bạn có cần biết bên trong nó chạy thế nào?

→ **KHÔNG!** Chỉ cần biết:
- Input gì?
- Output gì?
- Xài như nào?

**Áp dụng:**
- Guideline chỉ quy định **Input/Output**
- **Ruột bên trong làm sao cũng được**
- Không ép coding convention
- Mình là SV, không phải Google 😄

---

## 💬 Giao tiếp giữa các bên

### Mỗi bên cần cung cấp:

| Team | Cung cấp gì |
|------|-------------|
| **Core** | Module gì, làm được gì, Input/Output (schemas), cách gọi |
| **Backend** | Routes/API (có auto-docs thì OK) |
| **Frontend** | Tính năng/chức năng cung cấp |
| **UI/UX** | Cần nhận gì từ FE |

### Docs
- ✅ Core: Mỗi Module 1 file
- ⚠️ Backend: Tùy chọn (có auto-docs)
- ✅ Frontend: Mỗi tính năng 1 file
- ✅ UI/UX: Mô tả cần gì

---

## 🚀 Quy trình tổng quát

1. **Thống nhất Interface** (Input/Output) giữa các team
2. **FE tạo Mock Handler** → Chạy UI ngay
3. **BE/Core viết logic thật** → Song song với FE
4. **Merge:** Thay ruột Handler hoặc dùng Converter
5. **Test:** Đảm bảo ghép nối mượt mà

**Đừng ai đợi ai!** Làm song song tất cả! 💪

---

**📌 Lưu ý:** Guideline này vẫn đang update. Có thắc mắc? Hỏi team! 

**Code vui nhé!** 🚀✨
