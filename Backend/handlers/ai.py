from __future__ import annotations

import json
import uuid
from typing import List

from core.llm.handlers import (
    FunctionCallRequest,
    FunctionCallResult,
    LLM,
    LLMMessage,
    LLMMessageRole,
)
from core.llm.tools import Function as LLMFunction
from core.llm.tools import FunctionParams as LLMFunctionParams
from core.llm.tools import ToolDefinition as LLMToolDefinition
from core.llm.models import Models
from schemas.ai import (
    AIFunctionCallRequestSchema,
    AIFunctionCallResultSchema,
    AIFunctionParamsSchema,
    AIFunctionSchema,
    AIAvailableModelInfoSchema,
    AIGenerateRequestSchema,
    AIMessageRole,
    AIMessageSchema,
    AIToolDefinitionSchema,
)


class AIHandler:
    """AI handlers for generation tasks (static handlers)."""

    @staticmethod
    def __role_to_llm(role: AIMessageRole) -> LLMMessageRole:
        if role == AIMessageRole.User:
            return LLMMessageRole.User
        if role == AIMessageRole.Assistant:
            return LLMMessageRole.Assistant
        if role == AIMessageRole.System:
            return LLMMessageRole.System
        return LLMMessageRole.NoRole

    @staticmethod
    def __role_from_llm(role: LLMMessageRole) -> AIMessageRole:
        if role == LLMMessageRole.User:
            return AIMessageRole.User
        if role == LLMMessageRole.System:
            return AIMessageRole.System
        return AIMessageRole.Assistant

    @staticmethod
    def __tool_params_to_llm(params: AIFunctionParamsSchema) -> LLMFunctionParams:
        return LLMFunctionParams(
            Type=params.Type,
            Properties=params.Properties,
            Required=params.Required,
            Description=params.Description,
        )

    @staticmethod
    def __tool_to_llm(tool: AIToolDefinitionSchema) -> LLMToolDefinition:
        return LLMToolDefinition(
            Function=LLMFunction(
                Name=tool.Function.Name,
                Description=tool.Function.Description,
                Parameters=AIHandler.__tool_params_to_llm(tool.Function.Parameters),
                Strict=tool.Function.Strict,
            ),
            Type='function',
        )

    @staticmethod
    def __tool_call_req_to_llm(call: AIFunctionCallRequestSchema) -> FunctionCallRequest:
        return FunctionCallRequest(
            FunctionName=call.FunctionName,
            FunctionArgs=call.FunctionArgs,
            CallId=call.CallId or str(uuid.uuid4()),
        )

    @staticmethod
    def __tool_call_res_to_llm(res: AIFunctionCallResultSchema) -> FunctionCallResult:
        if isinstance(res.Result, str):
            content = res.Result
        else:
            try:
                content = json.dumps(res.Result, ensure_ascii=False)
            except TypeError:
                content = str(res.Result)

        return FunctionCallResult(CallId=res.CallId, Result=content)

    @staticmethod
    def __message_to_llm(msg: AIMessageSchema) -> LLMMessage:
        return LLMMessage(
            Role=AIHandler.__role_to_llm(msg.Role),
            Message=msg.Message,
            ToolCalls=[AIHandler.__tool_call_req_to_llm(c) for c in msg.ToolCalls],
            ToolResult=[AIHandler.__tool_call_res_to_llm(r) for r in msg.ToolResult],
        )

    @staticmethod
    def __message_from_llm(msg: LLMMessage) -> AIMessageSchema:
        return AIMessageSchema(
            role=AIHandler.__role_from_llm(msg.Role),
            message=msg.Message,
            tool_calls=[
                AIFunctionCallRequestSchema(
                    function_name=c.FunctionName,
                    function_args=c.FunctionArgs,
                    call_id=c.CallId,
                )
                for c in msg.ToolCalls
            ],
            tool_result=[
                AIFunctionCallResultSchema(
                    call_id=r.CallId,
                    result=r.Result,
                )
                for r in msg.ToolResult
            ],
        )

    @staticmethod
    async def Generate(model_name: str, payload: AIGenerateRequestSchema) -> AIMessageSchema:
        messages: List[LLMMessage] = [AIHandler.__message_to_llm(m) for m in payload.Inputs]
        tools: List[LLMToolDefinition] = [AIHandler.__tool_to_llm(t) for t in payload.Tools]

        result = await LLM.Generate(
            model_name=model_name,
            inputs=messages,
            tools=tools,
            system_prompts=payload.SystemPrompts,
        )

        return AIHandler.__message_from_llm(result)

    @staticmethod
    async def GetAvailableModels() -> List[AIAvailableModelInfoSchema]:
        return [
            AIAvailableModelInfoSchema(
                name=m.Name,
                model_name=m.ModelName,
                description=m.Description,
            )
            for m in Models.GetAllModels()
        ]
