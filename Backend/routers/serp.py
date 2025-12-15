from fastapi import APIRouter, Depends, status, Request
from middleware.auth import VerifyAccessToken
from middleware.rate_limit import limiter
from query import QuerySystem
from schemas.errors import ErrorResponseSchema
from pydantic import Field, StringConstraints
from typing import Annotated

router = APIRouter(prefix="/serp", tags=["SERP Search"])

QueryTextConstraint = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]

@router.get(
    "/search", name="SERP Search", status_code=status.HTTP_200_OK,
    response_model=dict,
    description="Perform a SERP search and return raw API response",
    responses={
        status.HTTP_401_UNAUTHORIZED : {"model" : ErrorResponseSchema },
        status.HTTP_422_UNPROCESSABLE_ENTITY : { "model" : ErrorResponseSchema },
        status.HTTP_500_INTERNAL_SERVER_ERROR : { "model" : ErrorResponseSchema },
    }
)
@limiter.limit("10/minute")
async def serp_search(request: Request,
                      query: Annotated[QueryTextConstraint, Field(description="The search query text")],
                      _ = Depends(VerifyAccessToken)):
    result = await QuerySystem.SerpSearch(query=query)
    return result

@router.get(
    "/snippets", name="SERP Food Snippets", status_code=status.HTTP_200_OK,
    response_model=list,
    description="Perform a SERP search and return food-related snippets only",
    responses={
        status.HTTP_401_UNAUTHORIZED : {"model" : ErrorResponseSchema },
        status.HTTP_422_UNPROCESSABLE_ENTITY : { "model" : ErrorResponseSchema },
        status.HTTP_500_INTERNAL_SERVER_ERROR : { "model" : ErrorResponseSchema },
    }
)
@limiter.limit("10/minute")
async def serp_food_snippets(request: Request,
                             query: Annotated[QueryTextConstraint, Field(description="The search query text")],
                             _ = Depends(VerifyAccessToken)):
    result = await QuerySystem.SerpFoodSnippets(query=query)
    return result
