# 🚀 FRONTEND DEVELOPMENT GUIDE

### (The "How-to-not-block-each-other" Edition)

> **Tâm sự mỏng:** Trước hết, mình xin lỗi vụ bảo `Core Frontend` là optional nhé. Sau khi xem xét lại, app mình giờ "căng" quá (Supabase, AI, Backend...), một mình Frontend gánh hết là không xuể. Vậy nên, chúng ta sẽ chơi hệ **Decoupled** toàn diện luôn cho nó "mượt"!

---

## 📌 Luồng công việc tổng quát

Để anh em làm việc không ai phải đợi ai, chúng ta sẽ chia dây chuyền theo sơ đồ:
**`UI/UX ➔ Front-end ➔ Core Front-end`**

* **UI/UX:** Làm mặt tiền, lo trải nghiệm người dùng.
* **Front-end:** "Nhận việc" từ UI/UX, điều phối logic và gọi xuống Core.
* **Core Front-end:** Xử lý các tính năng "thật", kết nối API, Database, AI...

---

## 👥 Vai trò chi tiết (Ai làm việc nấy, đời sẽ tươi)

### 🎨 1. UI/UX: "Kỹ sư mặt tiền & Người định hướng tính năng"

Anh em UI/UX là người hiểu người dùng nhất, nên cứ thoải mái sáng tạo nhé!

* **Nhiệm vụ:** Thiết kế giao diện, đề xuất tính năng mới (Vibe AI thoải mái đi!).
* **Nguyên tắc "Hộp đen":** Đừng quan tâm code bên trong chạy thế nào. Cứ đặt **Placeholder** và gọi **Mock Handlers** như đã thống nhất trong [Guideline.md].
* **Tại sao phải dùng Handler?** Để lúc lắp logic thật, anh em chỉ cần thay đúng 1 chỗ, không phải đi "Ctrl+F" khắp cái codebase to tổ bố để sửa. Tin mình đi, làm vậy để tránh "lava code" (code rác) sau này đấy!

### 💻 2. Front-end: "Người điều phối (Orchestrator)"

Bạn chính là cầu nối, là người giữ cho code không bị rối như tơ vò.

* **Luồng logic:** `UI/UX ➔ Query System ➔ Handlers ➔ Core Module`.
* **Query System:** Đóng vai trò là "Lễ tân". UI/UX chỉ cần "yêu cầu công việc", Query System sẽ biết gọi Handler nào xử lý.
* **Lưu ý tối thượng:** Không để UI/UX tự viết logic gọi API hay xử lý data phức tạp. Chặn ngay từ đầu để sau này dễ refactor!

### ⚙️ 3. Core Front-end: "Cỗ máy vận hành"

Nhiệm vụ của bạn là biến những cái "Giả" của FE thành "Thật".

* **Nhiệm vụ:** Implement các module thực tế (Dart), gọi Backend API, kết nối Supabase.
* **Tính độc lập:** Viết module sao cho "thô" nhưng "chất", expose interface rõ ràng cho Front-end xài.

---

## 🏗️ Kiến trúc Handlers & Query System (Dart Example)

Vì app mình làm bằng Flutter nên mình làm demo bằng **Dart** luôn cho nó trực quan nhé:

### 1. Handlers (Nơi chứa logic chuyên môn)

```dart
// Interface/Data Model
class Restaurant {
  final String name;
  final String address;
  Restaurant(this.name, this.address);
}

// Handler thực hiện công việc cụ thể
class RestaurantHandler {
  Future<List<Restaurant>> search(String query) async {
    // FE có thể return Mock data ở đây trong khi đợi Core
    // Core xong thì thay bằng logic gọi API thực
    return [Restaurant("Cơm Tấm Sài Gòn", "123 Quận 1")];
  }
}

```

### 2. Query System (Trung tâm điều phối)

```dart
class QuerySystem {
  final _resHandler = RestaurantHandler();

  // UI/UX chỉ gọi hàm này, không cần biết bên trong có gì
  Future<List<Restaurant>> getRestaurants(String query) {
    return _resHandler.search(query);
  }
}

```

---

## 🔌 3 Dạng Integrate Core Module (Quan trọng!)

Khi anh em làm Core, sẽ gặp 3 kiểu "tình huống" sau:

### Dạng 1: Service Độc lập (API/Service ngoài)

* **Cách làm:** Cứ implement rồi expose interface ra là xong. Nhớ dùng Dart và không cần lo vụ lộ API Key (vì mình xử lý ở tầng khác rồi).

### Dạng 2: Depend tầng dưới (Đợi Backend xong mới làm được)

* **Giải pháp:** Cả hai bên (Core FE & Backend) thống nhất **Input/Output (Contract)**.
* Core FE cứ viết **Mock Data** trước để Frontend dùng. Khi nào Backend xong thì chỉ việc "thay ruột" là máy chạy êm ru.

### Dạng 3: Stateful (Cần lưu trạng thái - Ví dụ: Chatbot)

Nếu UI/UX gọi một module mà cần nhớ "lịch sử", hãy chọn 1 trong 3 chiến lược:

| Chiến lược | Đặc điểm | Khi nào dùng? |
| --- | --- | --- |
| **Bên trên giữ State** | Core chỉ nhận data và xử lý (Stateless). | Khi trạng thái đơn giản. |
| **Bên dưới giữ State** | Core tự lưu trữ, FE chỉ cần gọi "làm tiếp đi". | Khi không có nhu cầu "đa luồng/đa trạng thái". |
| **Hybrid (Khuyên dùng)** | FE giữ ID (SessionID), Core giữ data chi tiết theo ID đó. | Khi trạng thái phức tạp (như Chatbot nhiều cửa sổ). |

---

## 💡 Lời kết từ Tech Lead

"Mình là sinh viên, không phải dev Google, nên đừng áp lực quá!" 😄

Mục tiêu của cái Guideline này là để anh em **LÀM VIỆC SONG SONG**. Đừng ai đợi ai cả! FE cứ mock, UI cứ vẽ, Core cứ viết. Cuối cùng chúng ta chỉ cần ráp các "mối nối" lại là xong.

**Cố lên anh em, làm nhanh cái MVP rồi còn đi chơi! 🚀✨**

---

*Bản hướng dẫn này dựa trên [Guideline.md] và sẽ được cập nhật liên tục.*