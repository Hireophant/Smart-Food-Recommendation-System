from enum import Enum
from typing import Any, Dict, List, Optional, Union, Literal
from pydantic import BaseModel, ConfigDict, Field

AIFunctionParamsNativeSchema = Union[
    "AIFunctionParamsStringSchema",
    "AIFunctionParamsIntegerSchema",
    "AIFunctionParamsNumberSchema",
    "AIFunctionParamsBooleanSchema"
]

AIFunctionParamsNativeEnumSchema = Union[
    "AIFunctionParamsStringEnumSchema",
    "AIFunctionParamsIntegerEnumSchema",
    "AIFunctionParamsNumberEnumSchema",
]

AIFunctionParamsSchema = Union[
    "AIFunctionParamsObjectSchema",
    "AIFunctionParamsNativeSchema",
    "AIFunctionParamsNativeEnumSchema",
    "AIFunctionParamsArraySchema"
]

class AIMessageRole(str, Enum):
    User = "user"
    Assistant = "assistant"
    System = "system"
    
class AIFunctionParamsType(str, Enum):
    Object = "object"
    String = "string"
    Integer = "integer"
    Number = "number"
    Boolean = "boolean"
    Array = "array"

class AIFunctionParamsObjectSchema(BaseModel):
    """Minimal JSON-schema for object params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.Object] = Field(default=AIFunctionParamsType.Object, alias="type")
    Properties: Dict[str, AIFunctionParamsSchema] = Field(default_factory=dict, alias="properties")
    Required: List[str] = Field(default_factory=list, alias="required")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionParamsStringSchema(BaseModel):
    """Minimal JSON-schema for string type params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.String] = Field(default=AIFunctionParamsType.String, alias="type")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionParamsIntegerSchema(BaseModel):
    """Minimal JSON-schema for native type params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.Integer] = Field(default=AIFunctionParamsType.Integer, alias="type")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionParamsNumberSchema(BaseModel):
    """Minimal JSON-schema for native type params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.Number] = Field(default=AIFunctionParamsType.Number, alias="type")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionParamsBooleanSchema(BaseModel):
    """Minimal JSON-schema for native type params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.Boolean] = Field(default=AIFunctionParamsType.Boolean, alias="type")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionParamsStringEnumSchema(BaseModel):
    """Minimal JSON-schema for string enum params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.String] = Field(default=AIFunctionParamsType.String, alias="type")
    Enum: List[str] = Field(default_factory=list, alias="enum")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionParamsIntegerEnumSchema(BaseModel):
    """Minimal JSON-schema for integer enum params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.Integer] = Field(default=AIFunctionParamsType.Integer, alias="type")
    Enum: List[int] = Field(default_factory=list, alias="enum")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionParamsNumberEnumSchema(BaseModel):
    """Minimal JSON-schema for number enum params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.Number] = Field(default=AIFunctionParamsType.Number, alias="type")
    Enum: List[float] = Field(default_factory=list, alias="enum")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionParamsArraySchema(BaseModel):
    """Minimal JSON-schema for array params."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    
    Type: Literal[AIFunctionParamsType.Array] = Field(default=AIFunctionParamsType.Array, alias="type")
    Items: AIFunctionParamsSchema = Field(alias="items")
    Description: Optional[str] = Field(default=None, alias="description")

class AIFunctionSchema(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    Name: str = Field(alias="name")
    Description: Optional[str] = Field(default=None, alias="description")
    Parameters: AIFunctionParamsObjectSchema = Field(default_factory=AIFunctionParamsObjectSchema, alias="parameters")
    Strict: Optional[bool] = Field(default=None, alias="strict")


class AIToolDefinitionSchema(BaseModel):
    """Tool wrapper: `{type: 'function', function: {...}}`."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    Function: AIFunctionSchema = Field(alias="function")
    Type: str = Field(default="function", alias="type")


class AIFunctionCallRequestSchema(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    FunctionName: str = Field(alias="function_name")
    FunctionArgs: str = Field(alias="function_args")
    CallId: Optional[str] = Field(default=None, alias="call_id")


class AIFunctionCallResultSchema(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    CallId: str = Field(alias="call_id")
    Result: Any = Field(alias="result")


class AIMessageSchema(BaseModel):
    """A chat message with optional tool calls/results (OpenAI-style)."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    Role: Optional[AIMessageRole] = Field(default=None, alias="role")
    Message: Optional[str] = Field(default=None, alias="message")
    ToolCalls: List[AIFunctionCallRequestSchema] = Field(default_factory=list, alias="tool_calls")
    ToolResult: List[AIFunctionCallResultSchema] = Field(default_factory=list, alias="tool_result")


class AIGenerateRequestSchema(BaseModel):
    """POST body for `POST /ai/{model_name}`."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    Inputs: List[AIMessageSchema] = Field(default_factory=list, alias="inputs")
    Tools: List[AIToolDefinitionSchema] = Field(default_factory=list, alias="tools")
    SystemPrompts: Optional[str] = Field(default=None, alias="system_prompts")


class AIAvailableModelInfoSchema(BaseModel):
    """Public model info returned by the API."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    Name: str = Field(alias="name", description="Configured model name (case-sensitive).")
    ModelName: str = Field(alias="model_name", description="Provider model identifier.")
    Description: Optional[str] = Field(default=None, alias="description", description="Optional model description.")
