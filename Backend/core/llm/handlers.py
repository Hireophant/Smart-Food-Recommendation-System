import uuid, openai
import enum
from openai.types.chat import (
    ChatCompletionMessageParam,
    ChatCompletionToolParam,
    ChatCompletionMessageFunctionToolCall,
    ChatCompletionMessageFunctionToolCallParam,
    ChatCompletionToolMessageParam
)
from openai.types.shared_params import FunctionDefinition, FunctionParameters
from typing import List, cast, Optional, Any
from core.llm.models import Models, ModelInfo
from core.llm.tools import ToolDefinition, FunctionParams
from dataclasses import dataclass, field
from enum import Enum

@dataclass
class FunctionCallRequest:
    FunctionName: str
    FunctionArgs: str
    CallId: str = field(default_factory=lambda: str(uuid.uuid4()))
    
    def ToOpenAI(self) -> ChatCompletionMessageFunctionToolCallParam:
        return {
            "type" : "function",
            "id" : self.CallId,
            "function" : {
                "name" : self.FunctionName,
                "arguments" : self.FunctionArgs
            }
        }
    
    @staticmethod
    def FromOpenAI(p: ChatCompletionMessageFunctionToolCallParam) -> "FunctionCallRequest":
        return FunctionCallRequest(
            FunctionName=p["function"]["name"],
            FunctionArgs=p["function"]["arguments"],
            CallId=p["id"]
        )

@dataclass
class LLMResult:
    Message: ChatCompletionMessageParam
    ToolCalls: List[FunctionCallRequest] = field(default_factory=list)

class LLMMessageRole(Enum):
    NoRole = 0
    User = 1
    Assistant = 2
    System = 3

@dataclass
class FunctionCallResult:
    CallId: str
    Result: str
    
    def ToOpenAI(self) -> ChatCompletionToolMessageParam:
        return {
            "role" : "tool",
            "tool_call_id" : self.CallId,
            "content" : str(self.Result)
        }
    
    @staticmethod
    def FromOpenAI(p: ChatCompletionToolMessageParam) -> "FunctionCallResult":
        return FunctionCallResult(
            CallId=p["tool_call_id"],
            Result=str(p["content"])
        )

@dataclass
class LLMMessage:
    Role: LLMMessageRole
    Message: Optional[str] = None
    ToolCalls: List[FunctionCallRequest] = field(default_factory=list)
    ToolResult: List[FunctionCallResult] = field(default_factory=list)
    
    def GetMainMessage(self) -> Optional[ChatCompletionMessageParam]:
        if self.Role == LLMMessageRole.User:
            return {
                "role" : "user",
                "content" : str(self.Message)
            }
        elif self.Role == LLMMessageRole.System:
            return {
                "role" : "system",
                "content" : str(self.Message)
            }
        elif self.Role == LLMMessageRole.Assistant:
            result: ChatCompletionMessageParam = {
                "role": "assistant",
                "content": str(self.Message),
            }

            # Important: if there are no tool calls, do not send an empty array.
            if self.ToolCalls:
                result["tool_calls"] = [tool.ToOpenAI() for tool in self.ToolCalls]

            return result
        else:
            return None
        
    def GetToolResultMessages(self) -> List[ChatCompletionMessageParam]:
        return [res.ToOpenAI() for res in self.ToolResult]    
    
    def ToOpenAI(self) -> List[ChatCompletionMessageParam]:
        result: List[ChatCompletionMessageParam] = list()
        
        # Main message
        main_message = self.GetMainMessage()
        if main_message:
            result.append(main_message)
            
        # Tool results
        result += self.GetToolResultMessages()
        
        return result

class LLM:
    @staticmethod
    def __to_jsonable(value: Any) -> Any:
        """Best-effort conversion to a JSON-serializable structure.

        The OpenAI client ultimately sends payloads through HTTPX which
        requires the request body to be JSON-serializable. Our tool schemas
        may contain Pydantic models (e.g. AIFunctionParamsStringSchema).
        """

        if value is None or isinstance(value, (str, int, float, bool)):
            return value

        if isinstance(value, enum.Enum):
            return value.value

        if isinstance(value, dict):
            return {str(k): LLM.__to_jsonable(v) for k, v in value.items()}

        if isinstance(value, (list, tuple, set)):
            return [LLM.__to_jsonable(v) for v in value]

        # Pydantic BaseModel (or compatible) support without importing pydantic here.
        model_dump = getattr(value, "model_dump", None)
        if callable(model_dump):
            dumped = model_dump(by_alias=True, exclude_none=True)
            return LLM.__to_jsonable(dumped)

        # Dataclasses or other objects that provide a dict-like representation.
        to_dict = getattr(value, "dict", None)
        if callable(to_dict):
            dumped = to_dict()
            return LLM.__to_jsonable(dumped)

        # Last resort: stringify (better than crashing the whole request).
        return str(value)

    @staticmethod
    def __convert_tool_params_to_openai(param: FunctionParams) -> FunctionParameters:
        return {
            "type" : param.Type,
            "properties" : LLM.__to_jsonable(param.Properties),
            "required" : LLM.__to_jsonable(param.Required),
            "description" : str(param.Description)
        }
    
    @staticmethod
    def __convert_tool_to_openai(tool: ToolDefinition) -> ChatCompletionToolParam:
        return ChatCompletionToolParam(
            function=FunctionDefinition(
                name=tool.Function.Name,
                description=str(tool.Function.Description),
                parameters=LLM.__convert_tool_params_to_openai(tool.Function.Parameters),
                strict=tool.Function.Strict
            ),
            type="function"
        )
        
    @staticmethod
    async def Generate(model_name: str, inputs: List[LLMMessage],
                       tools: List[ToolDefinition] = list(),
                       system_prompts: Optional[str] = None) -> LLMMessage:
        
        info = Models.GetModelInfoWithName(model_name) # Required Models loaded
        if not info:
            raise ValueError(f"Cannot find model '{model_name}'")
        model_info = cast(ModelInfo, info)
        # This can be sure to exists, since already check (query from model info)
        client = cast(openai.AsyncOpenAI, Models.GetClientWithName(model_info.ClientName))
        
        converted_inputs: List[ChatCompletionMessageParam] = list()
        if system_prompts is not None:
            converted_inputs.extend(LLMMessage(
                Role=LLMMessageRole.System,
                Message=system_prompts
            ).ToOpenAI())
            
        for i in inputs:
            converted_inputs.extend(i.ToOpenAI())
        
        request_kwargs: dict[str, Any] = {
            "messages": converted_inputs,
            "model": model_info.ModelName,
            "temperature": model_info.Creativity,
        }

        # Important: if there are no tools, do not send an empty array.
        if tools:
            request_kwargs["tools"] = [LLM.__convert_tool_to_openai(t) for t in tools]

        response = await client.chat.completions.create(**request_kwargs)
        
        output = response.choices[0].message
        return LLMMessage(
            Role=LLMMessageRole.Assistant,
            Message=output.content,
            ToolCalls=[
                FunctionCallRequest(
                    FunctionName=tool.function.name,
                    FunctionArgs=tool.function.arguments,
                    CallId=tool.id
                )
                for tool in cast(List[ChatCompletionMessageFunctionToolCall], output.tool_calls)
            ] if output.tool_calls else list()
        )