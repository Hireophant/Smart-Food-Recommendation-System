from fastapi import APIRouter, Depends, status, HTTPException, Request, Query
from middleware.auth import VerifyAccessToken
from middleware.rate_limit import limiter
from query import QuerySystem
from schemas import CollectionsResponseSchema, ObjectResponseSchema
from schemas.errors import ErrorResponseSchema
from schemas.data import (
    DataRestaurantResponseModel,
    DataFoodResponseModel,
    DataRestaurantsFormattedModel,
    DataFoodsFormattedModel,
)
from pydantic import Field, StringConstraints, PositiveFloat, PositiveInt
from typing import Annotated, Optional, List

router = APIRouter(prefix="/data", tags=["Data Informations"])

LatitudeConstraint = Annotated[float, Field(le=90, ge=-90)]
LongitudeConstraint = Annotated[float, Field(le=180, ge=-180)]
QueryTextConstraint = Annotated[str, StringConstraints(strip_whitespace=True)]
RatingConstraint = Annotated[float, Field(ge=0, le=5)]
LimitConstraint = Annotated[int, Field(ge=1, le=100)]

@router.get(
    "/restaurant/search", name="Restaurant Search", status_code=status.HTTP_200_OK,
    response_model=CollectionsResponseSchema[DataRestaurantResponseModel],
    description="Performing restaurant search in the database with the given filters and input",
    responses={
        status.HTTP_401_UNAUTHORIZED : {"model" : ErrorResponseSchema },
        status.HTTP_422_UNPROCESSABLE_ENTITY : { "model" : ErrorResponseSchema },
        status.HTTP_500_INTERNAL_SERVER_ERROR : { "model" : ErrorResponseSchema },
    }
)
@limiter.limit("20/minute")
async def restaurant_search(request: Request,
                            focus_lat: Annotated[Optional[LatitudeConstraint], Field(description="The focus point latitude to search (optional, for distance calculation)")] = None,
                            focus_lon: Annotated[Optional[LongitudeConstraint], Field(description="The focus point longitude to search (optional, for distance calculation)")] = None,
                            query: Annotated[Optional[QueryTextConstraint], Field(description="The text query to filter")] = None,
                            radius: Annotated[PositiveFloat, Field(description="The search radius from the focus point, in meters")] = 5000,
                            min_rating: Annotated[RatingConstraint, Field(description="The minimum rating score to filter")] = 0,
                            category: Annotated[Optional[QueryTextConstraint], Field(description="The category text query to filter")] = None,
                            tags: Annotated[Optional[QueryTextConstraint], Field(description="The tags text query to filter (matches restaurant tags)")] = None,
                            province: Annotated[Optional[QueryTextConstraint], Field(description="The province text query to filter")] = None,
                            district: Annotated[Optional[QueryTextConstraint], Field(description="The district text query to filter")] = None,
                            limit: Annotated[LimitConstraint, Field(description="The maximum number of result to return")] = 10,
                            _=Depends(VerifyAccessToken)):
    result = await QuerySystem.DataRestaurantSearch(
        focus_latitude=focus_lat,
        focus_longitude=focus_lon,
        query=query,
        radius=radius,
        min_rating=min_rating,
        category=category,
        tags=tags,
        province=province,
        district=district,
        limit=limit
    )
    return CollectionsResponseSchema[DataRestaurantResponseModel](data=result)


@router.get(
    "/restaurant/search/formatted",
    name="Restaurant Search (Formatted)",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[DataRestaurantsFormattedModel],
    description="Perform restaurant search and return formatted string for AI",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("20/minute")
async def restaurant_search_formatted(
    request: Request,
    focus_lat: Annotated[
        Optional[LatitudeConstraint],
        Field(description="The focus point latitude to search (optional, for distance calculation)"),
    ] = None,
    focus_lon: Annotated[
        Optional[LongitudeConstraint],
        Field(description="The focus point longitude to search (optional, for distance calculation)"),
    ] = None,
    query: Annotated[Optional[QueryTextConstraint], Field(description="The text query to filter")] = None,
    radius: Annotated[PositiveFloat, Field(description="The search radius from the focus point, in meters")] = 5000,
    min_rating: Annotated[RatingConstraint, Field(description="The minimum rating score to filter")] = 0,
    category: Annotated[Optional[QueryTextConstraint], Field(description="The category text query to filter")] = None,
    tags: Annotated[
        Optional[QueryTextConstraint],
        Field(description="The tags text query to filter (matches restaurant tags)"),
    ] = None,
    province: Annotated[Optional[QueryTextConstraint], Field(description="The province text query to filter")] = None,
    district: Annotated[Optional[QueryTextConstraint], Field(description="The district text query to filter")] = None,
    limit: Annotated[LimitConstraint, Field(description="The maximum number of result to return")] = 10,
    _=Depends(VerifyAccessToken),
):
    result = await QuerySystem.DataRestaurantSearchFormatted(
        focus_latitude=focus_lat,
        focus_longitude=focus_lon,
        query=query,
        radius=radius,
        min_rating=min_rating,
        category=category,
        tags=tags,
        province=province,
        district=district,
        limit=limit,
    )
    return ObjectResponseSchema[DataRestaurantsFormattedModel](data=result)


@router.get(
    "/restaurant/byids",
    name="Restaurant By Ids",
    status_code=status.HTTP_200_OK,
    response_model=CollectionsResponseSchema[DataRestaurantResponseModel],
    description="Fetch a list of restaurants by their database IDs",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("60/minute")
async def restaurant_by_ids(request: Request,
                            ids: Annotated[List[str],
                                           Query(min_length=1,
                                                 max_length=200,
                                                 description="Repeatable restaurant ids (e.g. ?ids=a&ids=b)")],
                            limit: Annotated[int, Query(ge=1, le=200, description="Maximum number of results")] = 100,
                            _ = Depends(VerifyAccessToken)):
    result = await QuerySystem.DataRestaurantsByIds(ids=ids, limit=limit)
    return CollectionsResponseSchema[DataRestaurantResponseModel](data=result)


@router.get(
    "/restaurant/byids/formatted",
    name="Restaurant By Ids (Formatted)",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[DataRestaurantsFormattedModel],
    description="Fetch restaurants by IDs and return formatted string for AI",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("60/minute")
async def restaurant_by_ids_formatted(
    request: Request,
    ids: Annotated[
        List[str],
        Query(min_length=1, max_length=200, description="Repeatable restaurant ids (e.g. ?ids=a&ids=b)"),
    ],
    limit: Annotated[int, Query(ge=1, le=200, description="Maximum number of results")] = 100,
    _=Depends(VerifyAccessToken),
):
    result = await QuerySystem.DataRestaurantsByIdsFormatted(ids=ids, limit=limit)
    return ObjectResponseSchema[DataRestaurantsFormattedModel](data=result)


@router.get(
    "/food/search",
    name="Food Search",
    status_code=status.HTTP_200_OK,
    response_model=CollectionsResponseSchema[DataFoodResponseModel],
    description="Search foods in the database with optional filters",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("30/minute")
async def food_search(
    request: Request,
    query: Annotated[Optional[QueryTextConstraint], Field(description="The text query to filter")] = None,
    category: Annotated[Optional[QueryTextConstraint], Field(description="The food category text query to filter")] = None,
    loai: Annotated[Optional[QueryTextConstraint], Field(description="The food type (loai) text query to filter")] = None,
    kieu_ten_mon: Annotated[Optional[QueryTextConstraint], Field(description="The kieu_ten_mon text query to filter")] = None,
    tags: Annotated[Optional[QueryTextConstraint], Field(description="The tags text query to filter")] = None,
    limit: Annotated[LimitConstraint, Field(description="The maximum number of result to return")] = 20,
    _=Depends(VerifyAccessToken)):
    result = await QuerySystem.FoodSearch(
        text=query,
        category=category,
        loai=loai,
        kieu_ten_mon=kieu_ten_mon,
        tags=tags,
        limit=limit,
    )
    return CollectionsResponseSchema[DataFoodResponseModel](data=result)


@router.get(
    "/food/byids",
    name="Food By Ids",
    status_code=status.HTTP_200_OK,
    response_model=CollectionsResponseSchema[DataFoodResponseModel],
    description="Fetch a list of foods by their database ObjectIds",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("60/minute")
async def food_by_ids(
    request: Request,
    ids: Annotated[
        List[str],
        Query(min_length=1, max_length=200, description="Repeatable food ids (e.g. ?ids=a&ids=b)"),
    ],
    limit: Annotated[int, Query(ge=1, le=200, description="Maximum number of results")] = 100,
    _=Depends(VerifyAccessToken),
):
    result = await QuerySystem.FoodsByIds(ids=ids, limit=limit)
    return CollectionsResponseSchema[DataFoodResponseModel](data=result)


@router.get(
    "/food/search/formatted",
    name="Food Search (Formatted)",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[DataFoodsFormattedModel],
    description="Search foods and return formatted string for AI",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("30/minute")
async def food_search_formatted(
    request: Request,
    query: Annotated[Optional[QueryTextConstraint], Field(description="The text query to filter")] = None,
    category: Annotated[Optional[QueryTextConstraint], Field(description="The food category text query to filter")] = None,
    loai: Annotated[Optional[QueryTextConstraint], Field(description="The food type (loai) text query to filter")] = None,
    kieu_ten_mon: Annotated[
        Optional[QueryTextConstraint],
        Field(description="The kieu_ten_mon text query to filter"),
    ] = None,
    tags: Annotated[Optional[QueryTextConstraint], Field(description="The tags text query to filter")] = None,
    limit: Annotated[LimitConstraint, Field(description="The maximum number of result to return")] = 20,
    _=Depends(VerifyAccessToken),
):
    result = await QuerySystem.FoodSearchFormatted(
        text=query,
        category=category,
        loai=loai,
        kieu_ten_mon=kieu_ten_mon,
        tags=tags,
        limit=limit,
    )
    return ObjectResponseSchema[DataFoodsFormattedModel](data=result)


@router.get(
    "/food/byids/formatted",
    name="Food By Ids (Formatted)",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[DataFoodsFormattedModel],
    description="Fetch foods by IDs and return formatted string for AI",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("60/minute")
async def food_by_ids_formatted(
    request: Request,
    ids: Annotated[
        List[str],
        Query(min_length=1, max_length=200, description="Repeatable food ids (e.g. ?ids=a&ids=b)"),
    ],
    limit: Annotated[int, Query(ge=1, le=200, description="Maximum number of results")] = 100,
    _=Depends(VerifyAccessToken),
):
    result = await QuerySystem.FoodsByIdsFormatted(ids=ids, limit=limit)
    return ObjectResponseSchema[DataFoodsFormattedModel](data=result)