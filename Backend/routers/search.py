from fastapi import APIRouter, Depends, status, HTTPException, Request
from middleware.auth import VerifyAccessToken
from middleware.rate_limit import limiter
from query import QuerySystem
from schemas import ObjectResponseSchema
from schemas.errors import ErrorResponseSchema
from schemas.search import SearchResponseModel, SearchResultFormattedModel
from pydantic import Field, StringConstraints
from typing import Annotated, Optional

router = APIRouter(prefix="/search", tags=["Search"])

QueryTextConstraint = Annotated[str, StringConstraints(strip_whitespace=True)]
LocationConstraint = Annotated[str, StringConstraints(strip_whitespace=True)]


@router.get(
    "",
    name="Search (Object)",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[SearchResponseModel],
    description="Search for food/restaurants via SERP API and return structured result",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("20/minute")
async def search_object(
    request: Request,
    query: Annotated[QueryTextConstraint, Field(description="The query text to search (will strip whitespace)")],
    location: Annotated[Optional[LocationConstraint], Field(description="Search location (default: Vietnam)")] = "Vietnam",
    max_locations: Annotated[
        Optional[int],
        Field(description="Max locations to include (0..5, default capped at 5)", ge=0),
    ] = None,
    max_results: Annotated[
        Optional[int],
        Field(description="Max organic results to include (0..5, default capped at 5)", ge=0),
    ] = None,
    _=Depends(VerifyAccessToken),
):
    result = await QuerySystem.SearchObject(
        query=query,
        location=location or "Vietnam",
        max_locations=max_locations,
        max_results=max_results,
    )
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to perform search!",
        )
    return ObjectResponseSchema[SearchResponseModel](data=result)


@router.get(
    "/formatted",
    name="Search (Formatted)",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[SearchResultFormattedModel],
    description="Search for food/restaurants via SERP API and return formatted Vietnamese text",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("20/minute")
async def search_formatted(
    request: Request,
    query: Annotated[QueryTextConstraint, Field(description="The query text to search (will strip whitespace)")],
    location: Annotated[Optional[LocationConstraint], Field(description="Search location (default: Vietnam)")] = "Vietnam",
    max_locations: Annotated[
        Optional[int],
        Field(description="Max locations to include (0..5, default capped at 5)", ge=0),
    ] = None,
    max_results: Annotated[
        Optional[int],
        Field(description="Max organic results to include (0..5, default capped at 5)", ge=0),
    ] = None,
    _=Depends(VerifyAccessToken),
):
    result = await QuerySystem.SearchFormatted(
        query=query,
        location=location or "Vietnam",
        max_locations=max_locations,
        max_results=max_results,
    )
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to perform search!",
        )
    return ObjectResponseSchema[SearchResultFormattedModel](data=result)
