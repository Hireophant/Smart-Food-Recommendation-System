from fastapi import APIRouter, Depends, status, HTTPException, Request
from middleware.auth import VerifyAccessToken
from middleware.rate_limit import limiter
from query import QuerySystem
from schemas import ObjectResponseSchema, CollectionsResponseSchema
from schemas.ai import AIGenerateRequestSchema, AIMessageSchema, AIAvailableModelInfoSchema
from schemas.errors import ErrorResponseSchema
from pydantic import Field, StringConstraints
from typing import Annotated, Optional

router = APIRouter(prefix="/ai", tags=["AI"])

ModelNameConstraint = Annotated[str, StringConstraints(strip_whitespace=True)]


@router.post(
    "",
    name="AI Generate",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[AIMessageSchema],
    description="Generate an AI response for a given chat history and tool state",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("20/minute")
async def generate(request: Request,
                   body: AIGenerateRequestSchema,
                   model: Annotated[Optional[ModelNameConstraint], Field(description="Model name (case-sensitive). Default is 'Default'.")] = "Default",
                   _ = Depends(VerifyAccessToken)):
    try:
        result = await QuerySystem.AIGenerate(model_name=str(model or "Default"), payload=body)
    except ValueError as exc:
        # Models.GetModelInfoWithName may raise this (unknown model)
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))
    except EnvironmentError as exc:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc))

    if result is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to generate AI response!")

    return ObjectResponseSchema[AIMessageSchema](data=result)


@router.get(
    "/models",
    name="AI Available Models",
    status_code=status.HTTP_200_OK,
    response_model=CollectionsResponseSchema[AIAvailableModelInfoSchema],
    description="List available configured AI models (limited fields).",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("60/minute")
async def models(request: Request):
    try:
        result = await QuerySystem.AIGetAvailableModels()
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc))
    return CollectionsResponseSchema[AIAvailableModelInfoSchema](data=result)
