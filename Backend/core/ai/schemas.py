"""
AI Schemas - Strict Architecture Compliance
Implements exact schemas from architecture diagrams.
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime
import uuid


# ============================================================================
# ARCHITECTURE-COMPLIANT SCHEMAS
# ============================================================================

class ToolCall(BaseModel):
    """
    Tool/Function call from AI.
    Represents AI's decision to use an external function.
    """
    function_name: str = Field(..., alias="name", description="Name of the function to call")
    function_args: Dict[str, Any] = Field(..., alias="args", description="Function arguments as dict")
    call_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Unique call identifier")
    
    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "function_name": "update_user_taste_profile",
                "function_args": {"category": "cuisine", "value": "Vietnamese", "sentiment": "love"},
                "call_id": "call_abc123"
            }
        }


class ToolResult(BaseModel):
    """
    Result from tool execution.
    Sent back to AI for further reasoning.
    """
    call_id: str = Field(..., description="Matches ToolCall.call_id")
    function_name: str = Field(..., description="Function that was executed")
    result: Any = Field(..., description="Execution result (can be dict, list, string, etc.)")
    success: bool = Field(default=True, description="Whether execution succeeded")
    error: Optional[str] = Field(None, description="Error message if failed")
    
    class Config:
        json_schema_extra = {
            "example": {
                "call_id": "call_abc123",
                "function_name": "update_user_taste_profile",
                "result": {"status": "updated", "profile": {"cuisines": ["Vietnamese"]}},
                "success": True
            }
        }


class InputRequest(BaseModel):
    """
    Input request to AI system.
    Matches architecture diagram exactly.
    """
    user_id: str = Field(..., description="User identifier for session management")
    message: str = Field(..., description="Current user prompt/message")
    previous_message_id: Optional[str] = Field(
        None,
        alias="prev_mess_id",
        description="ID of previous message in conversation"
    )
    conversation_id: Optional[str] = Field(
        None,
        description="Conversation thread identifier (auto-generated if None)"
    )
    tool_results: List[ToolResult] = Field(
        default_factory=list,
        description="Results from previous tool calls (for multi-turn)"
    )
    
    # Optional context (not in strict spec but useful)
    context: Optional[Dict[str, Any]] = Field(
        None,
        description="Additional context (restaurant data, location, etc.)"
    )
    
    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "user_id": "user_123",
                "message": "Tìm quán phở gần đây",
                "previous_message_id": "msg_abc",
                "conversation_id": "conv_xyz",
                "tool_results": []
            }
        }


class AI_Output_Result(BaseModel):
    """
    Output from AI system.
    Matches architecture diagram exactly.
    """
    message: str = Field(..., description="AI's text response")
    tool_calls: List[ToolCall] = Field(
        default_factory=list,
        description="List of function calls AI wants to execute"
    )
    conversation_id: str = Field(..., description="Conversation thread ID")
    message_id: str = Field(
        default_factory=lambda: f"msg_{uuid.uuid4().hex[:12]}",
        description="Unique message identifier"
    )
    
    # Metadata (not in strict spec but useful)
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    model_used: str = Field(default="gemini-1.5-flash")
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "Tôi tìm thấy 3 quán phở gần bạn. Bạn có muốn xem chi tiết không?",
                "tool_calls": [],
                "conversation_id": "conv_xyz",
                "message_id": "msg_abc123def"
            }
        }


# ============================================================================
# SYSTEM CONFIG
# ============================================================================

class SystemConfig(BaseModel):
    """
    System configuration for AI.
    Includes prompt engineering and tool definitions.
    """
    prompt_engineer: str = Field(
        ...,
        alias="system_prompt",
        description="System prompt that defines AI behavior"
    )
    tool_definitions: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="List of available tools/functions AI can call"
    )
    max_history_messages: int = Field(
        default=20,
        description="Maximum conversation history to include"
    )
    
    class Config:
        populate_by_name = True


# ============================================================================
# CONVERSATION HISTORY
# ============================================================================

class ConversationMessage(BaseModel):
    """Single message in conversation history"""
    message_id: str
    role: str = Field(..., description="user/model/tool")
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    tool_calls: List[ToolCall] = Field(default_factory=list)
    tool_results: List[ToolResult] = Field(default_factory=list)


class ConversationHistory(BaseModel):
    """Conversation history for a user"""
    conversation_id: str
    user_id: str
    messages: List[ConversationMessage] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_updated: datetime = Field(default_factory=datetime.utcnow)


# ============================================================================
# TASTE PROFILE (As Structured Data, Not Schema for API)
# ============================================================================

class UserTasteProfile(BaseModel):
    """
    User taste profile stored in database.
    Updated via update_user_taste_profile tool.
    """
    user_id: str
    cuisines: List[str] = Field(default_factory=list)
    spice_level: Optional[str] = None
    dietary_restrictions: List[str] = Field(default_factory=list)
    allergies: List[str] = Field(default_factory=list)
    price_preference: Optional[str] = None
    favorite_dishes: List[str] = Field(default_factory=list)
    dislikes: List[str] = Field(default_factory=list)
    last_updated: datetime = Field(default_factory=datetime.utcnow)
    
    def to_context_string(self) -> str:
        """Convert to compact string for AI context"""
        parts = []
        if self.cuisines:
            parts.append(f"Cuisines: {', '.join(self.cuisines)}")
        if self.spice_level:
            parts.append(f"Spice: {self.spice_level}")
        if self.dietary_restrictions:
            parts.append(f"Diet: {', '.join(self.dietary_restrictions)}")
        if self.price_preference:
            parts.append(f"Budget: {self.price_preference}")
        if self.favorite_dishes:
            parts.append(f"Loves: {', '.join(self.favorite_dishes[:3])}")
        return " | ".join(parts) if parts else "No preferences"
