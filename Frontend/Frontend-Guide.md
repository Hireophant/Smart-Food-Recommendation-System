# FRONTEND DEVELOPMENT GUIDE

> **Okay, bắt đầu thôi nhở!** Tới giai đoạn này thì cũng hay lắm rồi! Trước hết thì mình cũng phải công nhận, mọi người siêng thật ấy. 👏

---

## 📖 Lời nói đầu: "Cuộc hành trình từ Tech Lead tập sự"

Vơi lại, đây cũng là lần đầu mình đi làm Tech Lead thử, và cũng như là Architect/Design ở tầng bên trên.

Mà nói thật nhá, mình mới năm 2, chưa học cơ sở dữ liệu hay công nghệ phần mềm, AI và cũng chưa quen dùng API. Vậy mà cái môn Tư duy tính toán nó bắt làm cái ứng dụng du lịch, nói thật chứ nhìn có khác gì "Đồ án tốt nghiệp" đâu.

Hồi ở thư viện ấy, mình có thấy một ông làm game, kiểu game RPG 2D đánh quái lên level đơn giản bằng RPG Maker thôi, vậy mà nó lại là "Đồ án tốt nghiệp" nghe mới sợ chứ! 😱

**Thôi thì, đến đây được cũng là hay rồi, bây giờ mình làm nhanh cái MVP nhá, mọi người cố lên!** 💪

---

## 🔄 Update quan trọng: Core Frontend không còn Optional!

Thì trước hết, trong cái Guideline chính ([Guideline.md](../Guideline.md)) của mình ấy, mình muốn xin lỗi cái vụ `Core Frontend` là optional.

Kiểu theo mình nghĩ ấy, là nếu như Frontend không nặng quá thì khỏi cần Core can thiệp, nhưng mà **bây giờ khác rồi**.

Phần Frontend không thể cứ giao cho một mình Frontend làm hết được, do còn nhiều phần như:
- 🗄️ **Supabase** để lấy data
- 🔌 **Gọi Backend** API
- 🤖 **Dùng AI** xử lý
- ...vâng, không xuể thật! 😅

**Vì thế, coi như mình xong phần Backend rồi đi, qua làm Frontend!**

✅ Đừng lo, mình test hết rồi, backend API hoạt động ổn rồi đấy!

---

## 🔄 Luồng làm việc tổng quan

Đầu tiên, nói về luồng làm việc, có thể nói là **gần giống như của Backend luôn ấy**. Chỉ đơn giản là:
- **Backend:** Cung cấp cho Frontend qua API
- **Frontend:** Cung cấp cho UI/UX những cái "data thật" để nó dùng thay vì Mock Handler, Placeholder như hiện tại

---

## 👥 Vai trò các bên liên quan

Chắc nói về vai trò của các bên liên quan trước nhở.

### 1️⃣ UI/UX: "Người vẽ tranh"
**Trách nhiệm:**
- ✨ Tất nhiên là thiết kế giao diện, làm cái mặt tiền
- 📋 Cung cấp cho Frontend và Core biết cần những thông tin gì
- 🎭 Các cái Mock Handlers / Placeholder hiện tại để ghép logic vào

### 2️⃣ Front-end: "Gần như Back-end"
**Trách nhiệm:**
- 🎁 Cung cấp cho UI/UX những cái thông tin nó cần
- 🔌 Và cung cấp bằng cách dùng Core

### 3️⃣ Core Front-end: "Người làm việc thật"
**Trách nhiệm:**
- ⚙️ Cung cấp cho Front-end những tính năng / thông tin cần

**Dependency chain:**
```
UI/UX → Front-end → Core Front-end
```

- `UI/UX` làm hiển thị và trải nghiệm người dùng, là mặt tiền
- `Front-end` cung cấp "logic" sử dụng cho UI/UX
- `Core Front-end` cung cấp "tính năng thật" cho Front-end sử dụng

**Lưu ý quan trọng:**
> Việc Integrate với bên ngoài (Front-end với Back-end/Database) là của **Core**, Front-end chỉ việc dùng và trích xuất thông tin cho UI/UX nó xài.

---

## 📝 Chi tiết từng vai trò

Rồi tiếp theo thì đi vào chi tiết của các bên thôi nhở. Phần trước thì nói chắc cũng có được cái nhìn tổng quát rồi, nhưng chi tiết thì như này (đừng lo, không có ép đâu).

---

### 🎨 1. UI/UX: "Người kiến trúc trải nghiệm"

Đây là bên sẽ làm cái mặt tiền, và có **ảnh hưởng lớn** đến việc ứng dụng sẽ có những tính năng gì!

**Tại sao á?** 🤔

Nghĩ thử xem:
- Đây là bên **dễ đồng cảm với người dùng nhất**
- Nếu có tính năng mới thì người làm UI/UX là bên có thể **"thấy được"** nó hoạt động một cách trực tiếp!

Vì lý do đấy, UI/UX cũng nên là bên quản lý và "thêm/gợi ý" tính năng, và cả thể dựa vào ý kiến của các bên khác như Back-end, Front-end, Core nữa, để thiết kế UI/UX hợp lý và hoàn chỉnh hơn.

#### ✅ Nguyên tắc làm việc

Các nguyên tắc làm việc thì có sẵn trong [Guideline](../Guideline.md), như là mấy cái Mock và Placeholder.

Nói thật, bây giờ mình nhìn thì thấy, **vâng mấy bạn làm tốt vl, tốt hơn mình nghĩ luôn.** 🎉

#### ❓ Tại sao tách ra thành Handler?

Còn nếu bạn thắc mắc là tại sao tách ra thành Handler như vậy, thì câu trả lời đơn giản là:

> **"Bên lắp dễ tìm chỗ lắp và dễ lắp hơn thay vì ngồi Ctrl+F/D/C/V"**

Vì tin mình đi, bạn không muốn **"vừa phải hiểu logic gọi"** mà **"vừa phải tìm chỗ lắp trong UI/UX"** trong một cái codebase to tổ bố đâu!

#### 💡 Khuyến khích sáng tạo!

Bạn làm tốt rồi, chỉ là app mình còn hơi... "lỏ" do ít tính năng quá.

Mình nghĩ có thể bạn đang kìm tính năng lại và chỉ làm những cái cần thiết, nhưng **thật sự thì bạn cứ thoải mái thêm tính năng**:
- ✅ Chỉ là nhớ Mock/Placeholder
- ✅ Báo cho team để tụi mình xem xét tính năng rồi lên kế hoạch được rồi
- 🎨 **Bạn tự do lắm, vibe AI thoải mái cái UI/UX đi!**
- 💭 Ý tưởng đồ thoải mái, nó là của bạn!
- ⭐ **Bạn là bên sáng tạo nhiều nhất trong này mà!**

---

### 💻 2. Front-end: "Kỹ sư kết nối"

Việc bạn làm thì... **chả khác Back-end lắm**, chỉ cực cho bạn một xíu là mình có sẵn một cái skeleton cho Back-end (tại nó là FastAPI, và hồi vài tháng trước mình có học và copy sẵn vài file từ một cái Back-end project nhỏ của mình qua làm Skeleton thôi).

#### 🔄 Luồng xử lý

Thì luồng vẫn như Back-end với Core:

```
UI/UX → Query System → Handlers → Core Module
```

**Chi tiết từng tầng:**

##### 📲 UI/UX → Query System
- UI/UX thay mấy cái Placeholder và Mock của nó qua `Query System`

##### 🎯 Query System (Trung tâm điều phối)
Query System thì có nhiều công dụng:
- 🎛️ Nó vừa là trung tâm, Orchestrator của Front-end với các `Handlers`
- 🔌 Vừa cung cấp một cái interface đơn giản cho UI/UX dùng

**⚠️ Lưu ý quan trọng:**
- ❌ **Không nên** để UI/UX làm logic gọi phức tạp ở đây
- ❌ **Không được phép** để UI/UX tự cho logic:
  - ❌ Gọi thẳng `Handlers`
  - ❌ Dùng thẳng API call như tự gọi API
  - ℹ️ Lưu ý: Mấy cái MapTiles như OSM không tính nhá, nó thuộc phạm vi design rồi do dùng FlutterMap

**🤔 Lý do:**

Chắc mấy bạn cũng đoán được rồi:
- Ông ấy làm UI/UX logic với design rồi
- Giờ mà kiêm thêm một phần logic thật nữa thì khoai lắm
- Cực dễ **"lỗi"** và sẽ **"rất khó sửa"** vì nó nằm thẳng trong code UI luôn rồi
- Thành **"lava code"** sớm luôn ấy

> Cách tốt nhất để sửa/refactor code là **"đừng để nó xảy ra"**, chặn ngay từ đầu.

**💡 Best Practice:**

Thế nên khi làm Query System, thì nên **expose các công việc** thay vì chỉ tính năng.

**Mục tiêu:** Khi UI/UX thay vào một Mock/Placeholder thì nó đơn giản và dễ hiểu nhất có thể.

##### 🔧 Handlers (Lớp trung gian)
Handlers thì là một lớp nằm trên Core Module, tương tự như trong Back-end:
- ⚡ **Enabling làm việc song song**
- 🎭 **Cho phép mock**
- 🔄 **Convert giữa các bên:**
  - Front-end cần format A
  - Core trả về format B
  - → Mình convert format B qua A trong Handler

##### ⚙️ Core Module (Tính năng thật)
Core Module thì đơn giản là cung cấp các tính năng thực (aka làm cho nó chạy thật).

#### 🎯 Tóm tắt theo tính năng

Nếu nói theo tính năng, luồng nó sẽ như vầy:

```
Hiển thị (UI/UX) 
  → Nhận Công việc (Query System) 
    → Cung cấp Tính năng (Handlers) 
      → Cung cấp tính năng "thật" theo kiểu "thô" (Core Module)
```

#### ⚠️ Lưu ý cho Front-end

**Bạn đang ở giữa, bạn đang kết nối giữa hai bên với nhau!** 🌉

Và cũng như guideline đã đề cập:
- ✅ Nếu bạn cần mà Core chưa có/chưa xong thì **Mock**
- 🎭 Tạo Handlers với data giả (Mock Handler)

**Về cách thiết kế:**

Về cách thiết kế Query System với Handlers, có trong [Guideline](../Guideline.md) rồi đấy, bạn làm cũng tốt rồi nên không cần đề cập lắm.

---

### ⚙️ 3. Core Frontend: "Người làm việc thật"

Cái này thì chi tiết sau về cách thực hiện thì **giống như khi làm Core Back-end** thôi chứ không có gì mới, theo [Guideline](../Guideline.md) nhá bạn.

---

## 🔌 3 Cách Integrate và Cung cấp Tính năng

Rồi, bây giờ là cái mà mấy bạn thắc mắc mấy ngày nay nè, mình **"Integrate"** và cung cấp tính năng kiểu gì?

Thì ở đây mình sẽ chia làm **3 dạng chính** khi làm Core Module nhá!

---

### 🔹 Dạng 1: Thông thường (Standalone)

**Đặc điểm:**
- API/Service ngoài
- Tính năng đơn thuần
- Không bị dependency bởi các bên nội bộ khác

**Cách thực hiện:**

Đơn giản, làm y chang như hồi ở Back-end:
1. ✅ Cứ implement rồi expose interface
   - Qua client hay các hàm
   - Để Front-end dùng
2. 📖 Có trong [Guideline](../Guideline.md) luôn ấy, lên đọc nếu cần
3. 🔄 Chỉ là thay vì:
   - ❌ Python và cần API Key
   - ✅ Đây là Dart và không cần API key thôi

**Ví dụ:**
- Weather API
- Map Tiles Service
- Static Configuration Loader

---

### 🔹 Dạng 2: Depend Tầng Dưới (Chained Dependency)

**Đặc điểm:**
- Cần phần khác ở tầng dưới trong dây chuyền hoàn thành để Integrate
- Ví dụ: Core Front-end (phần Back-end Module) cần Back-end xong để làm

**Cách thực hiện:**

Thì ý tưởng để làm cũng như khi làm Handlers, nhưng quy mô to hơn:

1. **📋 Bàn bạc và định nghĩa Interface**
   - Cả hai có thể bàn bạc xem có các tính năng gì
   - Input/Output chung của các tính năng là gì

2. **🎭 Bên trên Mock trước**
   - Bên trên thì cứ thực hiện làm Mock Data/Placeholder (kiểu gần giống UI/UX)
   - Rồi dùng nó expose

3. **🔄 Sau này thay từng phần**
   - Khi bên dưới xong phần nào
   - Thì bên trên thay, lắp vào Mock/Placeholder cho phần đó

4. **🔧 Convert nếu lệch format**
   - Nếu lệch format, thì cứ convert (trực tiếp hoặc gián tiếp)
   - ❌ **Đừng đổi Output của Module**

**Kết quả:**

Từ đó, mình biến nó sang **Dạng thông thường**. ✨

**Ví dụ:**
```dart
// 1. Định nghĩa Interface trước
abstract class RestaurantService {
  Future<List<Restaurant>> searchRestaurants(String query);
}

// 2. Mock Implementation (làm trước)
class MockRestaurantService implements RestaurantService {
  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    // Mock data
    return [
      Restaurant(name: "Test Restaurant 1", rating: 4.5),
      Restaurant(name: "Test Restaurant 2", rating: 4.0),
    ];
  }
}

// 3. Real Implementation (thay sau khi Backend xong)
class RealRestaurantService implements RestaurantService {
  final BackendClient _client;
  
  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    final response = await _client.get('/api/restaurants?q=$query');
    return response.data.map((json) => Restaurant.fromJson(json)).toList();
  }
}

// 4. Converter nếu format khác
Restaurant _convertFromBackend(Map<String, dynamic> json) {
  return Restaurant(
    name: json['restaurant_name'], // Backend dùng 'restaurant_name'
    rating: json['avg_rating'],     // Frontend cần 'rating'
  );
}
```

---

### 🔹 Dạng 3: Bị Depend Bên Trên (Stateful Dependency)

**Đặc điểm:**
- Bên trên không chỉ sử dụng, mà còn phải **lưu trữ trạng thái** khi sử dụng
- Ví dụ: UI/UX gọi LLM Chatbot Module thì cần trạng thái là đoạn chat hiện tại

**Giải pháp:**

Thường thì có nhiều cách để giải quyết vấn đề này, dưới đây là ba cách đơn giản:

---

#### 💾 Cách 1: Lưu trữ trạng thái bên trên

**Mô tả:**
- Bên trên sẽ là bên lưu trữ trạng thái
- Bên dưới thì giữ **"stateless"** khi gọi
- Khi bên trên sử dụng, thì chỉ cần gửi kèm trạng thái xuống bên dưới

**✅ Lợi ích:**
- Việc bên dưới đơn giản, không cần lưu trữ trạng thái
- Bên trên quản lý trạng thái trực tiếp

**❌ Nhược điểm:**
- Trạng thái bị quy định bởi Core Module, không decoupled cho lắm
- Việc lưu trữ có thể hơi quá cho bên trên

**🎯 Khi nào dùng:**
- Nếu trạng thái đơn giản

**Ví dụ:**
```dart
// Bên trên (UI) lưu trữ trạng thái
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _chatHistory = []; // Trạng thái lưu ở đây
  
  void _sendMessage(String text) async {
    // Gửi kèm toàn bộ lịch sử xuống Core
    final response = await ChatCore.sendMessage(
      message: text,
      history: _chatHistory, // Stateless Core, cần truyền state
    );
    
    setState(() {
      _chatHistory.add(Message(text: text, isUser: true));
      _chatHistory.add(Message(text: response, isUser: false));
    });
  }
}
```

---

#### 💾 Cách 2: Lưu trữ trạng thái bên dưới

**Mô tả:**
- Bên dưới sẽ là bên lưu trữ trạng thái
- Bên trên thì cứ khi gọi, không cần cấp trạng thái
- Khi bên dưới thực hiện, thì chỉ cần kèm thêm trạng thái đã lưu

**✅ Lợi ích:**
- Việc bên trên đơn giản, giống như "Dạng thông thường"

**❌ Nhược điểm:**
- Bên trên "khó" biết được trạng thái bên dưới (cần thêm một lớp Query)
- Khó có thể "đa trạng thái"

**🎯 Khi nào dùng:**
- Nếu không có "đa trạng thái"

**Ví dụ:**
```dart
// Core lưu trữ trạng thái
class ChatCore {
  static final List<Message> _chatHistory = []; // State lưu ở Core
  
  static Future<String> sendMessage(String text) async {
    // Tự động dùng _chatHistory đã lưu
    _chatHistory.add(Message(text: text, isUser: true));
    
    final response = await _callAI(_chatHistory);
    _chatHistory.add(Message(text: response, isUser: false));
    
    return response;
  }
  
  // Query để lấy state (nếu cần)
  static List<Message> getChatHistory() => List.from(_chatHistory);
}

// Bên trên rất đơn giản
class ChatScreen extends StatelessWidget {
  void _sendMessage(String text) async {
    final response = await ChatCore.sendMessage(text); // Đơn giản!
    // Core tự lo state
  }
}
```

---

#### 💾 Cách 3: Hybrid - Cả hai bên lưu trữ (Session-based)

**Mô tả:**
- Bên trên lưu trữ tối thiểu (e.g. ID trạng thái)
- Bên dưới lưu trữ phần chính
- Khi bên trên sử dụng, thì gửi kèm các thông tin trạng thái xuống bên dưới
- Khi bên dưới thực hiện, thì dùng các thông tin trạng thái được gửi xuống để lấy trạng thái hoàn chỉnh

**✅ Lợi ích:**
- Có lợi ích của cả Cách 1 & 2
- Linh hoạt nhất

**❌ Nhược điểm:**
- Hơi khó thực hiện hơn

**🎯 Khi nào dùng:**
- Nếu có "đa trạng thái"
- Và trạng thái lại "phức tạp"

**Ví dụ:**
```dart
// Core quản lý nhiều session
class ChatCore {
  static final Map<String, List<Message>> _sessions = {};
  
  // Tạo session mới
  static String createSession() {
    final sessionId = Uuid().v4();
    _sessions[sessionId] = [];
    return sessionId; // Trả ID về cho bên trên giữ
  }
  
  // Gửi tin nhắn trong session cụ thể
  static Future<String> sendMessage({
    required String sessionId,  // Bên trên chỉ cần nhớ ID
    required String text,
  }) async {
    final history = _sessions[sessionId]!; // Lấy state từ ID
    history.add(Message(text: text, isUser: true));
    
    final response = await _callAI(history);
    history.add(Message(text: response, isUser: false));
    
    return response;
  }
  
  // Query session
  static List<Message> getSessionHistory(String sessionId) {
    return List.from(_sessions[sessionId] ?? []);
  }
}

// Bên trên chỉ giữ ID nhẹ
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String _sessionId; // Chỉ lưu ID thôi, nhẹ!
  
  @override
  void initState() {
    super.initState();
    _sessionId = ChatCore.createSession(); // Tạo session
  }
  
  void _sendMessage(String text) async {
    // Gọi với sessionId
    final response = await ChatCore.sendMessage(
      sessionId: _sessionId,
      text: text,
    );
    setState(() {}); // UI update
  }
}
```

---

## 📊 Bảng so sánh 3 cách lưu trạng thái

| Tiêu chí | Cách 1: Trên | Cách 2: Dưới | Cách 3: Hybrid |
|----------|--------------|--------------|----------------|
| **Độ phức tạp bên trên** | ⚠️ Cao | ✅ Thấp | ✅ Thấp |
| **Độ phức tạp bên dưới** | ✅ Thấp | ⚠️ Cao | ⚠️ Trung bình |
| **Đa trạng thái** | ✅ Dễ | ❌ Khó | ✅ Dễ |
| **Decoupling** | ⚠️ Trung bình | ✅ Cao | ✅ Cao |
| **Khi nào dùng** | Trạng thái đơn giản | Trạng thái đơn, không đa | Trạng thái phức tạp, đa session |

---

## 📚 Tài liệu tham khảo

- 📖 [Guideline chính](../Guideline.md) - Hướng dẫn tổng quan
- ⚡ [Guideline ngắn](../Guideline-Short.md) - TL;DR version
- 🔧 [Backend Guide](../Backend/Backend-Guide.md) - Để hiểu cách Backend làm tương tự

---

## 🎬 Kết luận

Okay, đó là những gì mình muốn chia sẻ về Frontend Development! 

**Nhớ nhé:**
- 🎨 UI/UX: Cứ thoải mái sáng tạo, Mock/Placeholder là bạn
- 💻 Front-end: Bạn là cầu nối, Mock trước rồi Swap sau
- ⚙️ Core: Làm việc thật, theo từng dạng phù hợp

**Và quan trọng nhất:**
> ✨ **Đừng đợi nhau, làm song song, cuối ráp lại!**

Mọi người cố lên nha, làm nhanh cái MVP thôi! 💪

**P/S:** Chi tiết implement từng phần thì mình sẽ update thêm sau nhé. Giờ thì mấy bạn có foundation rồi đó, cứ bắt đầu code thôi! 🚀

---

*Có gì thắc mắc cứ hỏi nha, mình ở đây! Good luck! 🍀*