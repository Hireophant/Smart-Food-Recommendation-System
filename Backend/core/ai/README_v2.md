# AI Module Documentation

## Overview

The AI module provides a **high-level conversational interface** for the Smart Tourism System.  
It allows applications to interact with an AI assistant that can understand user intent, learn user taste preferences, and recommend restaurants automatically.

The module internally handles:
- Natural language understanding
- Multi-turn conversation
- Tool calling (restaurant search, taste learning)
- User taste profile learning
- Rate limiting, TTL, and retry logic

**Import:** `from core.ai import *`

**Requirements:**  
Set the following environment variables before use:
```bash
GEMINI_API_KEY=your_api_key
GEMINI_MODEL=gemini-1.5-flash
```

## Quick Start
```python
from core.ai import AIHandler
from core.ai.schemas import InputRequest

ai = AIHandler()

response = await ai.chat(
    InputRequest(
        user_id="user_001",
        message="Gợi ý quán ăn gần tôi"
    )
)

print(response.message)
```
## Main Components
**AIHandler**

The main entry point for all AI interactions.

- Manages conversation history

- Communicates with Gemini model

- Automatically calls internal tools when needed

- Returns natural language responses

Key Schemas

- InputRequest: Input data sent to AI

- AI_Output_Result: Output returned from AI

- ToolCall: Tool calls decided by AI (for logging/debugging)

## What It Can Do
**1. Chat with AI**

Send a natural language message and receive a natural language response.

Input: `InputRequest`

- `user_id` (required): Unique identifier for user (anonymous ID is acceptable)

- `message` (required): User input text

Output: `AI_Output_Result`

Example:
```python
response = await ai.chat(
    InputRequest(
        user_id="user_001",
        message="Tôi thích ăn cay"
    )
)

print(response.message)
```
**2. Multi-turn Conversation**

Maintain context across multiple messages.

Input: `InputRequest`

- `conversation_id`: Continue previous conversation

- `previous_message_id`: Trace previous message

Example:
```python
# First turn
res1 = await ai.chat(
    InputRequest(
        user_id="user_001",
        message="Tôi thích món Việt"
    )
)

# Second turn
res2 = await ai.chat(
    InputRequest(
        user_id="user_001",
        message="Gợi ý quán ăn gần tôi",
        conversation_id=res1.conversation_id,
        previous_message_id=res1.message_id
    )
)

print(res2.message)
```

**3. Restaurant Recommendation**

AI automatically detects user intent and searches for suitable restaurants.

- Combines user preferences (taste, cuisine)

- Uses location and context

- Searches database first, falls back to external search if needed

Example:
```python
response = await ai.chat(
    InputRequest(
        user_id="user_001",
        message="Gợi ý quán bún bò gần đây"
    )
)

print(response.message)
```

**4. Taste Profile Learning**

AI learns user taste preferences through conversation.

Example:
```python
await ai.chat(
    InputRequest(
        user_id="user_001",
        message="Tôi không thích đồ ngọt"
    )
)

await ai.chat(
    InputRequest(
        user_id="user_001",
        message="Gợi ý món ăn phù hợp"
    )
)
```
AI will adapt recommendations automatically.

## Input Data Structure
InputRequest
```python
class InputRequest:
    user_id: str
    message: str
    conversation_id: Optional[str]
    previous_message_id: Optional[str]
```

| Field                 | Required | Description            |
| --------------------- | -------- | ---------------------- |
| `user_id`             | ✅        | Identify the user      |
| `message`             | ✅        | User input text        |
| `conversation_id`     | ❌        | Continue conversation  |
| `previous_message_id` | ❌        | Trace previous message |

## Output Data Structure
AI_Output_Result
```python
class AI_Output_Result:
    message: str
    tool_calls: List[ToolCall]
    conversation_id: str
    message_id: str
```
| Field             | Description                         |
| ----------------- | ----------------------------------- |
| `message`         | Final response text                 |
| `tool_calls`      | Tools invoked by AI (for debugging) |
| `conversation_id` | Conversation ID                     |
| `message_id`      | Message ID                          |

## Error Handling

The AI module always returns an `AI_Output_Result`.

If an error occurs:

- A friendly fallback message is returned in message

- Gemini API calls are retried internally

- Failed requests do not refresh conversation TTL

Example:
```python
response = await ai.chat(...)
print(response.message)
# "Xin lỗi, hệ thống đang gặp sự cố. Vui lòng thử lại sau."
```