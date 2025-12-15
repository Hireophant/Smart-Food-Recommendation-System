"""
AI Module - Architecture-Compliant Function Calling Agent
Exports all public interfaces for the AI chatbot system.
"""

from .connection import AIClient
from .handler import AIHandler
from .schemas import (
    InputRequest,
    AI_Output_Result,
    ToolCall,
    ToolResult,
    SystemConfig,
    UserTasteProfile
)
from .tools import TOOL_DEFINITIONS, ToolExecutor

__all__ = [
    "AIClient",
    "AIHandler",
    "InputRequest",
    "AI_Output_Result",
    "ToolCall",
    "ToolResult",
    "SystemConfig",
    "UserTasteProfile",
    "TOOL_DEFINITIONS",
    "ToolExecutor",
]
