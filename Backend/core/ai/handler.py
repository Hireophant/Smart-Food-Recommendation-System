"""
AI Service - Function Calling Loop Implementation
Implements the complete architecture with tool execution.
"""

from typing import List, Dict, Any, Optional
import json
import uuid
from datetime import datetime

"RATE LIMITING PER CONVERSATION"
from collections import defaultdict
import time
MAX_CALLS_PER_CONVERSATION = 10
CONVERSATION_CALL_COUNT = defaultdict(int)

"CONVERSATION TTL (AUTO-EXPIRE CHAT)"
CONVERSATION_LAST_ACTIVE = {}
CONVERSATION_TTL_SECONDS = 1800  #30min

"RETRY LOGIC FOR GEMINI API FAILURES"
MAX_GEMINI_RETRIES = 2

from .connection import AIClient
from .schemas import (
    InputRequest,
    AI_Output_Result,
    ToolCall,
    ToolResult,
    SystemConfig,
    ConversationMessage,
    ConversationHistory,
    UserTasteProfile
)
from .tools import TOOL_DEFINITIONS, ToolExecutor

# Fix import for standalone execution
try:
    from ...utils import Logger
except ImportError:
    class Logger:
        @staticmethod
        def info(msg): print(f"INFO: {msg}")
        @staticmethod
        def error(msg): print(f"ERROR: {msg}")
        @staticmethod
        def warning(msg): print(f"WARNING: {msg}")


class AIHandler:
    """
    AI Handler with complete Function Calling Loop.
    
    Architecture Compliance:
    ✅ InputRequest with PrevMessID, ConversationID, ToolResults
    ✅ AI_Output_Result with MessageID, ConversationID, tool_calls
    ✅ SystemConfig with PromptEngineer and ToolDefinitions
    ✅ Function calling loop (multi-turn tool execution)
    ✅ History management (20 messages)
    ✅ Taste profile as TOOL (not post-processing)
    """
    
    # System Prompt - Food Recommendation Expert
    SYSTEM_PROMPT = """You are an expert Food Recommendation AI specializing in Vietnamese cuisine.

**YOUR CAPABILITIES:**
- Recommend restaurants based on user preferences
- Answer questions about food, dishes, and dining culture
- Learn user preferences through conversation
- Search for restaurants matching criteria

**STRICT RULES:**
1. ONLY answer food/restaurant/dining questions
2. If asked non-food questions, politely decline: "Xin lỗi, tôi chỉ chuyên về ẩm thực"
3. Use Vietnamese when user speaks Vietnamese
4. Be concise and helpful (2-4 sentences)
5. ALWAYS use tools when appropriate:
   - Use `update_user_taste_profile` when user expresses preferences
   - Use `search_restaurants` when user wants to find places
   - Use `get_user_taste_profile` before making recommendations

**IMPORTANT:** You have access to tools. Use them proactively!"""
    
    # In-memory storage (replace with Redis/MongoDB in production)
    _conversations: Dict[str, ConversationHistory] = {}
    
    def __init__(self):
        """Initialize AI service"""
        self.model = AIClient.get_model()
        self.config = SystemConfig(
            prompt_engineer=self.SYSTEM_PROMPT,
            tool_definitions=TOOL_DEFINITIONS,
            max_history_messages=20
        )
    
    # ========================================================================
    # MAIN CHAT METHOD - WITH FUNCTION CALLING LOOP
    # ========================================================================
    
    async def chat(self, request: InputRequest) -> AI_Output_Result:
        """
        Process chat request with complete function calling loop.
        
        ARCHITECTURE FLOW:
        1. Prepare context (History + System Prompt + Tool Definitions)
        2. Call Gemini with tools
        3. CHECK FOR FUNCTION CALLS ← KEY DIFFERENCE
        4. LOOP: Execute tools → Send results back → Get final response
        5. Return AI_Output_Result with MessageID and ConversationID
        
        Args:
            request: InputRequest with user message and metadata
            
        Returns:
            AI_Output_Result with response and tool calls
        """
        # Generate IDs
        conversation_id = request.conversation_id or f"conv_{uuid.uuid4().hex[:12]}"
        
        now = time.time()

        last_active = CONVERSATION_LAST_ACTIVE.get(conversation_id)
        if last_active and (now - last_active) > CONVERSATION_TTL_SECONDS:
            # Reset conversation
            self.history.clear_conversation(conversation_id)
            CONVERSATION_CALL_COUNT[conversation_id] = 0

        # RATE LIMIT
        CONVERSATION_CALL_COUNT[conversation_id] += 1
        if CONVERSATION_CALL_COUNT[conversation_id] > MAX_CALLS_PER_CONVERSATION:
            raise Exception("Rate limit exceeded for this conversation")

        message_id = f"msg_{uuid.uuid4().hex[:12]}"
        
        Logger.info(f"Processing chat for user {request.user_id} in conversation {conversation_id}")
        
        # 1. Get or create conversation history
        history = self._get_conversation_history(request.user_id, conversation_id)
        
        # 2. Get user's taste profile for context
        taste_profile = ToolExecutor._taste_profiles.get(
            request.user_id,
            UserTasteProfile(user_id=request.user_id)
        )
        
        # 3. Build messages for Gemini
        messages = self._build_gemini_messages(
            request=request,
            history=history,
            taste_profile=taste_profile
        )
        
        # 4. Convert tool definitions to Gemini format
        tools = self._build_gemini_tools()
        
        # 5. FUNCTION CALLING LOOP
        try:
            # Initial call to Gemini
            chat = self.model.start_chat(history=messages[:-1])
            
            # Send current message with tools
            response = None
            last_error = None
            for attempt in range(MAX_GEMINI_RETRIES):
                try:
                    response = await chat.send_message_async(
                        messages[-1]["parts"][0],
                        tools=tools if tools else None
                    )
                    break
                except Exception as e:
                    last_error = e
                    Logger.error(
                        f"Gemini API error (attempt {attempt + 1}/{MAX_GEMINI_RETRIES}): {e}"
                    )
            if response is None:
                raise last_error
            
            # Track all tool calls made
            all_tool_calls: List[ToolCall] = []
            
            # 6. CHECK FOR FUNCTION CALLS (THE CRITICAL LOOP)
            max_iterations = 5  # Prevent infinite loops
            iteration = 0
            
            while iteration < max_iterations:
                # Check if AI wants to call functions
                function_calls = self._extract_function_calls(response)
                
                if not function_calls:
                    # No more function calls, we have final response
                    break
                
                Logger.info(f"AI requested {len(function_calls)} function call(s)")
                
                # Execute all function calls
                tool_results = []
                for func_call in function_calls:
                    all_tool_calls.append(func_call)
                    
                    # EXECUTE THE TOOL
                    # Inject user_id for tools that need it
                    func_args = func_call.function_args.copy()
                    if "user_id" not in func_args and func_call.function_name in [
                        "update_user_taste_profile",
                        "get_user_taste_profile"
                    ]:
                        func_args["user_id"] = request.user_id
                    
                    result = ToolExecutor.execute_tool(
                        function_name=func_call.function_name,
                        function_args=func_args
                    )
                    
                    tool_result = ToolResult(
                        call_id=func_call.call_id,
                        function_name=func_call.function_name,
                        result=result,
                        success=result.get("success", True)
                    )
                    tool_results.append(tool_result)
                
                # SEND RESULTS BACK TO GEMINI
                # Build function response message
                function_response_parts = []
                for tr in tool_results:
                    function_response_parts.append({
                        "function_response": {
                            "name": tr.function_name,
                            "response": {
                                "content": json.dumps(tr.result, ensure_ascii=False)
                            }
                        }
                    })
                
                # Continue conversation with tool results
                response = await chat.send_message_async(
                    function_response_parts,
                    tools=tools if tools else None
                )
                
                iteration += 1
            
            # 7. Extract final text response
            final_message = response.text if hasattr(response, 'text') else ""
            
            # 8. Save to conversation history
            self._append_to_history(
                conversation_id=conversation_id,
                user_id=request.user_id,
                messages=[
                    ConversationMessage(
                        message_id=f"msg_{uuid.uuid4().hex[:12]}",
                        role="user",
                        content=request.message
                    ),
                    ConversationMessage(
                        message_id=message_id,
                        role="model",
                        content=final_message,
                        tool_calls=all_tool_calls
                    )
                ]
            )
            
            CONVERSATION_LAST_ACTIVE[conversation_id] = time.time()

            # 9. Return architecture-compliant response
            return AI_Output_Result(
                message=final_message,
                tool_calls=all_tool_calls,
                conversation_id=conversation_id,
                message_id=message_id
            )
            
        except Exception as e:
            Logger.error(f"Gemini API error: {str(e)}")
            
            # Return error response
            return AI_Output_Result(
                message=f"Xin lỗi, đã có lỗi xảy ra: {str(e)}",
                tool_calls=[],
                conversation_id=conversation_id,
                message_id=message_id
            )
    
    # ========================================================================
    # HELPER METHODS
    # ========================================================================
    
    def _extract_function_calls(self, response) -> List[ToolCall]:
        """
        Extract function calls from Gemini response.
        
        Gemini returns function calls in response.candidates[0].content.parts
        """
        function_calls = []
        
        try:
            # Check if response has function calls
            if not hasattr(response, 'candidates') or not response.candidates:
                return []
            
            candidate = response.candidates[0]
            if not hasattr(candidate, 'content') or not candidate.content:
                return []
            
            content = candidate.content
            if not hasattr(content, 'parts') or not content.parts:
                return []
            
            # Extract function calls from parts
            for part in content.parts:
                if hasattr(part, 'function_call'):
                    func_call = part.function_call
                    
                    # Convert to ToolCall schema
                    tool_call = ToolCall(
                        function_name=func_call.name,
                        function_args=dict(func_call.args),
                        call_id=f"call_{uuid.uuid4().hex[:8]}"
                    )
                    function_calls.append(tool_call)
        
        except Exception as e:
            Logger.error(f"Error extracting function calls: {e}")
        
        return function_calls
    
    def _build_gemini_messages(
        self,
        request: InputRequest,
        history: ConversationHistory,
        taste_profile: UserTasteProfile
    ) -> List[Dict[str, Any]]:
        """
        Build Gemini-compatible message list.
        
        Format:
        [
            {"role": "user", "parts": ["system prompt with taste context"]},
            {"role": "model", "parts": ["acknowledged"]},
            ... history messages ...
            {"role": "user", "parts": ["current message"]}
        ]
        """
        messages = []
        
        # System prompt injection with taste profile
        taste_context = taste_profile.to_context_string()
        system_instruction = f"{self.SYSTEM_PROMPT}\n\n**USER TASTE PROFILE:**\n{taste_context}"
        
        messages.append({
            "role": "user",
            "parts": [system_instruction]
        })
        messages.append({
            "role": "model",
            "parts": ["Understood. I'll help you find great food using my tools when needed."]
        })
        
        # Add history (last N messages)
        recent_messages = history.messages[-self.config.max_history_messages:]
        for msg in recent_messages:
            messages.append({
                "role": msg.role,
                "parts": [msg.content]
            })
        
        # Add current message with context
        current_message = request.message
        if request.context:
            context_str = json.dumps(request.context, ensure_ascii=False)
            current_message += f"\n\n[Additional Context: {context_str}]"
        
        messages.append({
            "role": "user",
            "parts": [current_message]
        })
        
        return messages
    
    def _build_gemini_tools(self) -> List[Any]:
        """
        Convert tool definitions to Gemini format.
        
        Gemini expects tools in specific format:
        https://ai.google.dev/gemini-api/docs/function-calling
        """
        try:
            import google.generativeai as genai
            
            # Convert our tool definitions to Gemini FunctionDeclaration
            tools = []
            for tool_def in TOOL_DEFINITIONS:
                tools.append(
                    genai.protos.FunctionDeclaration(
                        name=tool_def["name"],
                        description=tool_def["description"],
                        parameters=genai.protos.Schema(
                            type=genai.protos.Type.OBJECT,
                            properties={
                                k: genai.protos.Schema(
                                    type=self._convert_json_type_to_gemini(v.get("type")),
                                    description=v.get("description", ""),
                                    enum=v.get("enum", []) if v.get("enum") else None
                                )
                                for k, v in tool_def["parameters"]["properties"].items()
                            },
                            required=tool_def["parameters"].get("required", [])
                        )
                    )
                )
            
            return tools
        except Exception as e:
            Logger.error(f"Error building Gemini tools: {e}")
            return []
    
    def _convert_json_type_to_gemini(self, json_type: str):
        """Convert JSON schema type to Gemini Type enum"""
        try:
            import google.generativeai as genai
            
            type_mapping = {
                "string": genai.protos.Type.STRING,
                "integer": genai.protos.Type.INTEGER,
                "number": genai.protos.Type.NUMBER,
                "boolean": genai.protos.Type.BOOLEAN,
                "array": genai.protos.Type.ARRAY,
                "object": genai.protos.Type.OBJECT
            }
            return type_mapping.get(json_type, genai.protos.Type.STRING)
        except:
            return None
    
    def _get_conversation_history(
        self,
        user_id: str,
        conversation_id: str
    ) -> ConversationHistory:
        """Get or create conversation history"""
        key = f"{user_id}:{conversation_id}"
        
        if key not in self._conversations:
            self._conversations[key] = ConversationHistory(
                conversation_id=conversation_id,
                user_id=user_id
            )
        
        return self._conversations[key]
    
    def _append_to_history(
        self,
        conversation_id: str,
        user_id: str,
        messages: List[ConversationMessage]
    ) -> None:
        """Append messages to conversation history"""
        key = f"{user_id}:{conversation_id}"
        history = self._get_conversation_history(user_id, conversation_id)
        
        history.messages.extend(messages)
        history.last_updated = datetime.utcnow()
        
        # Keep only last 50 messages to prevent memory bloat
        if len(history.messages) > 50:
            history.messages = history.messages[-50:]
    
    # ========================================================================
    # PUBLIC API
    # ========================================================================
    
    def get_conversation_history(
        self,
        user_id: str,
        conversation_id: str
    ) -> Optional[ConversationHistory]:
        """Get conversation history (for debugging/admin)"""
        key = f"{user_id}:{conversation_id}"
        return self._conversations.get(key)
    
    def clear_conversation(
        self,
        user_id: str,
        conversation_id: str
    ) -> None:
        """Clear conversation history"""
        key = f"{user_id}:{conversation_id}"
        if key in self._conversations:
            del self._conversations[key]
            Logger.info(f"Cleared conversation {conversation_id} for user {user_id}")
