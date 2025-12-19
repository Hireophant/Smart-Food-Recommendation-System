# 🤖 AI INTEGRATION GUIDE

> **Lời nói đầu:** Rồi, đây là một cái guide ngoài lề một chút, thì ở đây sẽ tập trung vào cách để làm cái luồng chạy AI.

Vâng vâng, tui biết mấy ông đang sợ nó phức tạp, hay chỉ muốn tới phần chính nhanh. Nhưng **"cứ từ từ"**, bình tĩnh đã. Mình phải bẻ nhỏ cái hộp AI này ra rồi mới biết cái luồng chạy của nó chứ. 🧩

---

## 📚 Phần 1: Hiểu về AI Conversation Patterns

Trước khi nhảy vào implement, mình cần hiểu AI nó chạy như nào. Có 3 pattern chính mà mình sẽ dùng:

---

### 💬 Pattern 1: One-shot (Đơn giản nhất)

**Mô tả:**
Bạn gửi AI một tin nhắn, nó trả về một tin nhắn, hết.

**Luồng:**
```
User: Input
  ↓
AI: Output
```

**🎯 Khi nào dùng:**
- Tác vụ đơn lẻ, không cần ngữ cảnh
- Ví dụ: Dịch một câu, tính toán đơn giản

---

### 🗨️ Pattern 2: Conversation Style (Có bộ nhớ)

**Mô tả:**
Bạn gửi AI một tin nhắn, **kèm với tất cả nội dung tin nhắn trước đó** theo đúng thứ tự (của bạn và của cả AI), rồi AI trả về tin nhắn "kế tiếp" trong đoạn hội thoại.

**Luồng:**
```
User: [History +] Input
  ↓
AI: Output 
```

**🎯 Khi nào dùng:**
- Cần ngữ cảnh từ các câu trước
- Chat bình thường với AI

---

### 🧠 Pattern 3: Conversation with Thinking Loop (Có công cụ)

**Mô tả:**
Bạn gửi AI một tin nhắn, kèm với:
- 📜 Tất cả nội dung tin nhắn trước đó
- 🛠️ Thông tin các công cụ mà nó có thể dùng

Rồi AI sẽ vào một vòng lặp **"suy nghĩ"** (reasoning) và cho ra output liên tục, cho đến khi suy nghĩ xong và có đáp án cuối cùng.

**Luồng:**
```
User: [History + Tools Definition] Input
  ↓
AI: Reasoning... (có thể gọi tools)
  ↓
AI: Final Output
```

**🎯 Khi nào dùng:**
- AI cần tra cứu thông tin
- AI cần thực hiện hành động (search, database query, API call)
- **→ Đây là pattern mình sẽ dùng cho ứng dụng!** ✅

---

## 🔧 Phần 2: Chi tiết Pattern 3 - Thinking Loop

Okay, giờ đi sâu vào Pattern 3 vì đây là cái mình sẽ xài. Hãy xem một ví dụ cụ thể:

### 📝 Ví dụ: Hỏi thời tiết và gợi ý hoạt động

#### 🛠️ Tools được cung cấp:

```python
# Tool 1: Lấy vị trí GPS
get_gps_location() -> str  
# Trả về: "lat,lng"

# Tool 2: Lấy thông tin thời tiết
get_weather(lat: float, lng: float) -> str
# Trả về: Mô tả thời tiết

# Tool 3: Bật/tắt chế độ suy nghĩ
set_reasoning(state: bool) -> str
# Bật: AI output sẽ được gửi lại tiếp mà không chờ user
# Output trong chế độ này có thể box lại hoặc ẩn đi
```

#### 🔄 Luồng Message đầy đủ (Backend Flow):

```
📨 M1: "Bây giờ có thích hợp để ra ngoài không?" (User)
     ↓

🤖 M2: [M1 +] "Mình sẽ xem tình hình thời tiết chỗ người dùng, nhưng trước hết thì mình cần vị trí của họ." (AI)
     + 🛠️ Tools Call:
         - ID "tool_001": set_reasoning(true)
         - ID "tool_002": get_gps_location()
     ↓

⚙️ M3: [M1 + M2 +] Tools Result:
         - "Enabled reasoning state, will not wait for user input" (Tool; ID "tool_001")
         - "10.031,109.373" (Tool; ID "tool_002")
     ↓

🤖 M4: [M1...M3 +] "Mình có được vị trí rồi, bây giờ mình sẽ xem tình hình thời tiết" (AI)
     + 🛠️ Tools Call:
         - ID "tool_003": get_weather(lat: 10.031, lng: 109.373)
     ↓

⚙️ M5: [M1...M4 +] Tools Result:
         - "Sunny weather, no wind" (Tool; ID "tool_003")
     ↓

🤖 M6: [M1...M5 +] "Vậy là thời tiết hiện đang nắng, không có gió, mình sẽ gợi ý cho người dùng vài hoạt động." (AI)
     ↓

🤖 M7: [M1...M6 +] "Hiện thì chỗ bạn trời khá nắng và không có gió, phù hợp để ra ngoài tập thể dục, công viên,..." (AI)
     + 🛠️ Tools Call:
         - ID "tool_004": set_reasoning(false)
     ↓

📨 M8: [M1...M7 +] "Đánh cầu lông thì sao?" (User)
     + ⚙️ Tools Result:
         - "Disabled reasoning state, will wait for user input" (Tool; ID "tool_004")
     ↓

🤖 M9: [M1...M8 +] "Ý kiến hay đấy, trời không gió nữa là quá phù hợp luôn! Bạn có thể kiếm một người bạn, hay vào sân vận động đánh cầu lông, gặp gỡ những người mới trong một ngày đẹp thế này." (AI)
```

---

#### 👁️ Output mà người dùng thấy (UI Layer):

```
👤 User: Bây giờ có thích hợp để ra ngoài không?

🤖 AI: 💭 Đang suy nghĩ...  ← (phần này làm collapsible hoặc không hiện cũng được)
    ├─ Mình sẽ xem tình hình thời tiết chỗ người dùng, nhưng trước hết thì mình cần vị trí của họ.
    ├─ 🛠️ Gọi get_gps_location()... → Kết quả: "10.031,109.373"
    ├─ Mình có được vị trí rồi, bây giờ mình sẽ xem tình hình thời tiết
    ├─ 🛠️ Gọi get_weather(lat: 10.031, lng: 109.373)... → Kết quả: "Sunny weather, no wind"
    └─ Vậy là thời tiết hiện đang nắng, không có gió, mình sẽ gợi ý cho người dùng vài hoạt động.

🤖 AI: Hiện thì chỗ bạn trời khá nắng và không có gió, phù hợp để ra ngoài tập thể dục, công viên,...

👤 User: Đánh cầu lông thì sao?

🤖 AI: Ý kiến hay đấy, trời không gió nữa là quá phù hợp luôn! Bạn có thể kiếm một người bạn, hay vào sân vận động đánh cầu lông, gặp gỡ những người mới trong một ngày đẹp thế này.
```

---

### 💡 Giải thích quan trọng

Vâng, mình biết là cái loop và tools ở trên không thực tế lắm, nhưng bạn hiểu ý tưởng rồi đúng không? 😄

**Điểm mấu chốt:**
- ✅ Chúng ta sẽ dùng tính năng **"function_calling"** (built-in của LLM)
- ✅ Kết hợp với một **vòng lặp suy nghĩ** (reasoning loop)
- ✅ AI có thể gọi nhiều tools liên tiếp cho đến khi có đáp án cuối cùng

---

### ⚡ Optimization: Cắt bớt Reasoning để tiết kiệm Token

Và để tiết kiệm token, ta cũng có thể **cắt luôn phần suy nghĩ** khi gửi message history:
#### 📝 Luồng tối ưu (bỏ qua reasoning messages):

```
📨 M1: "Bây giờ có thích hợp để ra ngoài không?" (User)
     ↓

🤖 M2...M6: [Reasoning messages - sẽ BỎ QUA khi gửi lại]
     ↓

🤖 M7: [M1 + M7 +] "Hiện thì chỗ bạn trời khá nắng và không có gió, phù hợp để ra ngoài tập thể dục, công viên,..." (AI)
     + 🛠️ Tools Call: set_reasoning(false)
     ↓

📨 M8: [M1 + M7 +] "Đánh cầu lông thì sao?" (User)  ← Chỉ giữ M1 và M7, bỏ M2...M6
     + ⚙️ Tools Result: "Disabled reasoning state"
     ↓

🤖 M9: [M1 + M7 + M8 +] "Ý kiến hay đấy, trời không gió nữa là quá phù hợp luôn! Bạn có thể kiếm một người bạn, hay vào sân vận động đánh cầu lông, gặp gỡ những người mới trong một ngày đẹp thế này." (AI)
```

**💰 Trade-off:**
- ✅ **Lợi:** Tiết kiệm **KHA KHÁ** token (reasoning messages thường dài!)
- ⚠️ **Hại:** Thiếu chút context từ quá trình suy nghĩ
- 🎯 **Kết luận:** Đáng để đánh đổi cho production! :)

---

### 📌 Lưu ý quan trọng

**Đối với ứng dụng của mình:**
- ✅ Sẽ xài **Pattern 3: Conversation with Thinking Loop** (có tools)
- ❌ **Không** setup MCP server các kiểu (quá phức tạp, cộng thêm lộ hết nữa thì toang 😅)
- 💡 Với lại giờ mà setup thì sửa backend nữa, hơi muộn rồi ấy nên có thể để đồ án tới

---

## 🚀 Phần 3: Implementation - Làm thế nào để tích hợp AI?

Okay, bây giờ vào **món chính**: Làm thế nào để implement AI trong cái App của mình?

### 📖 Trước hết: Đọc Backend API Docs

Phần backend thì xong rồi, khỏi phải bàn. Mấy ông có thể đọc cái docs ấy, hay copy cho AI giải thích cũng được.

#### 🔧 Cách 1: Chạy Server và xem docs trực tiếp

**Bước 1:** Chạy server backend (nhớ `cd` vào `Backend/` trước nhá):
```bash
uvicorn app:app --reload --port 8000
```

**Bước 2:** Mở web và xem docs:

| URL | Tính năng | Ưu điểm | Nhược điểm |
|-----|-----------|---------|------------|
| `localhost:8000/docs` | Swagger UI | 🎮 Interactive - gọi thử được luôn | 📄 Docs chưa đầy đủ lắm |
| `localhost:8000/redoc` | ReDoc UI | 📚 Docs đầy đủ, đẹp hơn | ❌ Không interact được |

#### 🤖 Cách 2: Dùng AI để giải thích API

**Bước 1:** Truy cập `localhost:8000/openapi.json`

**Bước 2:** Copy hết cái JSON đó

**Bước 3:** Quăng cho ChatGPT/Claude, kêu nó giải thích API cho

**💡 Pro tip:** Trick này cũng dùng được để nhờ AI giải thích mấy cái API khác nha!

---

### 🎯 Nhiệm vụ của Core Frontend AI

**Đơn giản thôi:**

```
Core Frontend AI = Wrapper cho Backend AI API
```

**Cụ thể:**
- 📋 Wrap API về AI cho Front-end:
  - `AI Generate` (gọi LLM)
  - `AI Available Models` (lấy danh sách model)
- ⚙️ Thực hiện các **"tác vụ AI"** (reasoning loop, tool execution)

---

### 🔗 Vấn đề: Stateful Dependency

Nếu mấy ông có ngó qua [Frontend Guide](Frontend/Frontend-Guide.md), thì cái AI này nó dính **Trường hợp 3** trong integration:

> **"Bị Depend bên trên" (Stateful)**

**Nghĩa là gì?**
- UI/UX không chỉ gọi AI
- Mà còn phải **lưu trạng thái** (conversation history)

---

### 💡 Giải pháp: Tách biệt trách nhiệm

Vậy, ta giải quyết cái vấn đề này như nào nhở? Well, hãy **tách cái vấn đề ra**:

```
Vấn đề lớn
  ├─ 🤖 Vấn đề 1: Gọi AI
  └─ 🛠️ Vấn đề 2: Thực hiện tools
```

**Phân công:**
- 🤖 **Backend AI:** Nhận messages → Generate → Trả về (không quan tâm tools là gì)
- 🛠️ **Frontend:** Thực hiện các tools khi AI yêu cầu (loop cho đến khi xong)

> Đúng, MÌNH BIẾT là làm MCP sẽ dễ hơn, nhưng giờ thì muộn rồi! 😅

**Cụ thể là như vầy:**

---

## 🏗️ Phần 4: Kiến trúc 3 tầng - Frontend AI

Okay, giờ đi chi tiết vào từng tầng. Nhớ đọc kỹ để hiểu cách chúng kết nối với nhau nha!

---

### ⚙️ Tầng 1: Core Front-end AI (Wrapper Layer)

**Vai trò:** Làm **Wrapper** cho Backend AI, hết, yeah! 😄

**Code ví dụ (pseudocode):**

```python
# 📦 Core Frontend AI Module

def get_available_models() -> List[AIModels]:
    """
    Lấy danh sách các AI models có sẵn từ Backend
    """
    # Calling backend API: GET /ai/models
    response = backend_api.get("/ai/models")
    return parse_models(response)


def ai_generate(
    model_name: str, 
    inputs: List[AIMessages], 
    tools: List[AIToolsDefinition]
) -> AIMessages:
    """
    Gọi AI để generate response
    
    Args:
        model_name: Tên model (vd: "gpt-4", "claude-3")
        inputs: List messages history
        tools: Định nghĩa các tools AI có thể dùng
        
    Returns:
        AIMessages: Response từ AI (có thể chứa tool_calls)
    """
    # Calling backend API: POST /ai/generate
    response = backend_api.post("/ai/generate", {
        "model": model_name,
        "messages": inputs,
        "tools": tools
    })
    return parse_ai_message(response)
```

**📌 Lưu ý:**
- Core chỉ lo **giao tiếp với Backend**, không lo logic UI
- Core **KHÔNG lưu state** (stateless)
- Bên trên sẽ quyết định lưu state như thế nào

---

### 💾 Quản lý State: Nên lưu ở đâu?

Còn về cách lưu messages, thì **tùy theo nhu cầu app**. Mình đây là phương pháp mình gợi ý theo từng tình huống:
#### 📋 Tình huống 1: One-shot / Single Conversation

**Khi nào dùng:**
- Chỉ có **một đoạn chat duy nhất**, không lưu nhiều đoạn chat
- Ví dụ: Chat đơn giản, không cần history nhiều conversation

**Cách làm:**
- ✅ Bên trên (Frontend/UI) giữ trạng thái luôn
- ✅ Bên dưới (Core) cứ stateless
- ✅ Muốn tạo chat mới? Chỉ cần reset state bên trên

**Code ví dụ:**

```python
# 🎨 UI/UX Layer hoặc Frontend Layer
class ChatUI:
    def __init__(self):
        self.messages: List[AIMessages] = []  # State lưu ở đây!
    
    def generate(self):
        # Gọi Core (stateless)
        output = CoreAI.ai_generate(
            model_name="gpt-4",
            inputs=self.messages,  # Truyền state xuống
            tools=[...]
        )
        
        self.messages.append(output)  # Cập nhật state
        return output
```

**✅ Ưu điểm:**
- Đơn giản, dễ implement
- UI có toàn quyền kiểm soát state

**⚠️ Nhược điểm:**
- Không scale nếu cần nhiều conversation

---

#### 📚 Tình huống 2: Multi-conversation (Session-based)

**Khi nào dùng:**
- Cần **nhiều đoạn chat** (như ChatGPT có nhiều conversation)
- User có thể switch giữa các conversation

**Cách làm:**
- ✅ **Phương pháp 3 - Hybrid** (đã đề cập trong Frontend Guide)
- ✅ Bên trên giữ **mỗi ID** conversation
- ✅ Bên dưới (Core) giữ **toàn bộ data**, map với ID

**Code ví dụ:**

```python
# ⚙️ Core Frontend AI (Session Manager)
class CoreAI:
    _conversations: Dict[str, List[AIMessages]] = {}
    
    @staticmethod
    def create_conversation() -> str:
        """Tạo conversation mới, trả về ID"""
        conv_id = generate_uuid()
        CoreAI._conversations[conv_id] = []
        return conv_id
    
    @staticmethod
    def generate_from_conversation(
        conversation_id: str,
        model_name: str,
        tools: List[AIToolsDefinition]
    ) -> AIMessages:
        """Generate từ conversation có sẵn"""
        # Lấy history
        inputs = CoreAI._conversations[conversation_id]
        
        # Gọi AI
        output = backend_api.post("/ai/generate", {
            "model": model_name,
            "messages": inputs,
            "tools": tools
        })
        
        # Auto append vào conversation
        CoreAI._conversations[conversation_id].append(output)
        return output


# 🎨 UI/UX Layer
class ChatUI:
    def __init__(self):
        # Chỉ giữ ID thôi, nhẹ!
        self.current_conv_id: str = CoreAI.create_conversation()
    
    def generate(self):
        # Gọi rất đơn giản!
        output = CoreAI.generate_from_conversation(
            conversation_id=self.current_conv_id,
            model_name="Default",
            tools=[...]
        )
        return output
    
    def switch_conversation(self, conv_id: str):
        """Chuyển conversation"""
        self.current_conv_id = conv_id
```

**✅ Ưu điểm:**
- Dễ dàng quản lý nhiều conversation
- UI đơn giản, chỉ giữ ID

**⚠️ Nhược điểm:**
- Phức tạp hơn một chút
- Core phải quản lý state

---

### 📊 Bảng so sánh 2 cách lưu state

| Tiêu chí | One-shot (State ở trên) | Multi-conv (Session-based) |
|----------|-------------------------|----------------------------|
| **Độ phức tạp** | ⭐ Đơn giản | ⭐⭐⭐ Trung bình |
| **Số conversation** | 1 | Nhiều |
| **State ở đâu** | UI/Frontend | Core (mapped by ID) |
| **Khi nào dùng** | Chat đơn giản | Cần nhiều conversation |

---

### 💻 Tầng 2: Front-end (Logic Layer)
**Vai trò:** Bên đây sẽ là bên **"cung cấp, hỗ trợ" logic cho UI**.

**Nhiệm vụ chính:**
- 🎯 Thay vì UI tự nhận diện, parse, gọi công cụ
- 🎯 UI sẽ gọi **gián tiếp** thông qua Front-end
- 🛠️ **Định nghĩa và thực hiện tools** (vì Frontend giao tiếp với mọi bên)
- ❌ **KHÔNG lưu trữ trạng thái** (để UI/UX quyết định)

**Tại sao không lưu state ở Frontend?**

> Nói thật, nếu nghĩ thì "chả biết Front-end nó lưu trạng thái chỗ nào" 🤔
>
> Tốt nhất là cho **UI/UX nó quyết định** cái trạng thái luôn. Do UI/UX nó còn phải **"hiện thông tin"** nữa mà, nên sẽ tiện cho UI/UX hơn.

---

#### 📝 Code ví dụ (One-shot pattern):

```python
# 💻 Frontend Layer
class Frontend:
    """
    Cung cấp interface đơn giản cho UI sử dụng
    """
    
    @staticmethod
    def generate(model: str, inputs: List[AIMessages]) -> AIMessages:
        """Wrapper để gọi AI qua Core"""
        return CoreAI.ai_generate(
            model_name=model, 
            inputs=inputs, 
            tools=Frontend._get_tools_definition()  # Tools do Frontend định nghĩa
        )
    
    @staticmethod
    def execute_tool(tool: AIToolCall) -> ToolResult:
        """
        Thực hiện tool call từ AI
        
        Logic thực thi tools nằm ở đây!
        """
        if tool.name == "get_weather":
            lat, lng = tool.arguments["lat"], tool.arguments["lng"]
            weather_data = WeatherAPI.get_weather(lat, lng)
            return ToolResult(id=tool.id, result=weather_data)
        
        elif tool.name == "search_restaurants":
            query = tool.arguments["query"]
            restaurants = DatabaseAPI.search(query)
            return ToolResult(id=tool.id, result=restaurants)
        
        # ... các tools khác
        
        else:
            return ToolResult(id=tool.id, error="Unknown tool")
    
    @staticmethod
    def _get_tools_definition() -> List[AIToolsDefinition]:
        """Định nghĩa các tools mà AI có thể dùng"""
        return [
            AIToolsDefinition(
                name="get_weather",
                description="Lấy thông tin thời tiết tại vị trí",
                parameters={
                    "lat": {"type": "number", "description": "Latitude"},
                    "lng": {"type": "number", "description": "Longitude"}
                }
            ),
            AIToolsDefinition(
                name="search_restaurants",
                description="Tìm kiếm nhà hàng theo từ khóa",
                parameters={
                    "query": {"type": "string", "description": "Từ khóa tìm kiếm"}
                }
            ),
            # ... các tools khác
        ]


# 🎨 UI/UX Layer
class ChatUI:
    def __init__(self):
        self.messages: List[AIMessages] = []  # State ở UI
    
    def ui_gen_loop(self, model: str, user_message: str):
        """
        Main loop xử lý chat với AI (có reasoning loop)
        """
        # 1️⃣ Hiển thị tin nhắn user
        self.show_message(side="user", message=user_message)
        self.messages.append(AIMessage(role="user", content=user_message))
        
        # 2️⃣ Reasoning Loop
        while True:
            # Gọi AI qua Frontend
            output = Frontend.generate(model=model, inputs=self.messages)
            self.messages.append(output)
            
            # Hiển thị response của AI
            self.show_message(side="assistant", message=output.content)
            
            # 3️⃣ Kiểm tra xem AI có cần gọi tools không?
            if not output.tool_calls:
                # Không có tools → Đã xong, thoát loop
                break
            
            # 4️⃣ Có tools → Thực hiện và gửi kết quả lại cho AI
            self.show_thinking_indicator()  # "Đang suy nghĩ..."
            
            tool_results = [
                Frontend.execute_tool(tool) 
                for tool in output.tool_calls
            ]
            
            # Có thể hiển thị kết quả tools nếu muốn
            # self.show_tool_results(tool_results)
            
            # Thêm kết quả vào messages và lặp lại
            self.messages.append(AIMessage(tool_results=tool_results))
            # Loop tiếp để AI xử lý kết quả...
    
    def show_message(self, side: str, message: str):
        """Update UI để hiển thị message"""
        pass  # Implementation tùy framework
    
    def show_thinking_indicator(self):
        """Hiển thị indicator "Đang suy nghĩ..." """
        pass
```

---

### 🎨 Tầng 3: UI/UX (Presentation Layer)

**Vai trò:** Hiển thị và tương tác với người dùng

Còn ông thì... err... vâng, nếu ông nhìn cái code mẫu ở trên thì cũng biết rồi đó... 😅

**Nhiệm vụ:**
- 📱 Ông sẽ dùng, tạo cái **flow loop** như ví dụ trên
- 🎨 Quản lý state (nếu dùng one-shot pattern)
- 👁️ Hiển thị messages, thinking indicator, tool results

Nah tui nói thật là tui chả biết nói gì nữa. AI, nếu có ý thì ghép vô giùm nhá... 🙏

---

## 📊 Tóm tắt kiến trúc

```
┌─────────────────────────────────────────────┐
│  🎨 UI/UX Layer                             │
│  - Quản lý state (messages)                 │
│  - Hiển thị chat interface                  │
│  - Gọi Frontend để generate/execute tools   │
└─────────────┬───────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────┐
│  💻 Frontend Layer                          │
│  - Cung cấp interface đơn giản cho UI       │
│  - Định nghĩa và thực hiện tools            │
│  - KHÔNG lưu state                          │
└─────────────┬───────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────┐
│  ⚙️ Core Frontend AI Layer                  │
│  - Wrapper cho Backend API                  │
│  - Stateless (hoặc Session-based nếu cần)  │
│  - Giao tiếp với Backend qua HTTP           │
└─────────────┬───────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────┐
│  🔌 Backend API                             │
│  - Gọi LLM API (OpenAI, Anthropic, etc.)   │
│  - Xử lý rate limiting, caching             │
│  - Bảo mật API keys                         │
└─────────────────────────────────────────────┘
```

---

## 🎬 Kết luận

Okay, thì đó là về **AI Integration Guide**! 🎉

**📌 Những điểm quan trọng cần nhớ:**

1. ✅ **Hiểu 3 patterns:** One-shot → Conversation → Thinking Loop
2. ✅ **Dùng Pattern 3** (với tools) cho ứng dụng
3. ✅ **Kiến trúc 3 tầng:** UI/UX → Frontend → Core AI
4. ✅ **State management:** Tùy nhu cầu (One-shot vs Multi-conversation)
5. ✅ **Frontend làm tools:** Định nghĩa và thực hiện
6. ✅ **Reasoning loop:** UI phải handle loop cho đến khi AI xong

**💡 Tips cuối:**
- 📖 Đọc Backend docs để hiểu API
- 🧪 Test từng tầng riêng lẻ trước khi integrate
- 🎨 UI/UX nên mock trước, swap sau
- 💰 Nhớ optimize token (cắt reasoning messages nếu cần)

---

**P/S:** Thề viết tay cái này mất 2 ngày trời bruh. 😭

Thế nhá, kèm với [Frontend Guide](Frontend/Frontend-Guide.md) thì coi như là... **tạm đủ guide** rồi đó! 🎊

**Code tốt nhá mn!** 🚀✨

---

## 📚 Tài liệu liên quan

- 📖 [Guideline chính](Guideline.md) - Hướng dẫn tổng quan dự án
- 💻 [Frontend Guide](Frontend/Frontend-Guide.md) - Chi tiết về Frontend development
- ⚙️ [Backend Guide](Backend/Backend-Guide.md) - Hướng dẫn Backend API

---

*Có thắc mắc gì cứ hỏi nha, mình ở đây! Good luck! 🍀*