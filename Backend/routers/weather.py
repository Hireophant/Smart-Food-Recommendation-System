from fastapi import APIRouter, Depends, status, HTTPException, Request
from middleware.auth import VerifyAccessToken
from middleware.rate_limit import limiter
from query import QuerySystem
from schemas import ObjectResponseSchema
from schemas.errors import ErrorResponseSchema
from schemas.weather import WeatherResponseModel, WeatherInfoFormattedModel
from pydantic import Field
from typing import Annotated

router = APIRouter(prefix="/weather", tags=["Weather"])

LatitudeConstraint = Annotated[float, Field(le=90, ge=-90)]
LongitudeConstraint = Annotated[float, Field(le=180, ge=-180)]


@router.get(
    "",
    name="Weather (Object)",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[WeatherResponseModel],
    description="Get current weather information from OpenWeather API",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("20/minute")
async def weather_object(
    request: Request,
    lat: Annotated[LatitudeConstraint, Field(description="Latitude")],
    lon: Annotated[LongitudeConstraint, Field(description="Longitude")],
    _=Depends(VerifyAccessToken),
):
    try:
        result = await QuerySystem.WeatherObject(lat=lat, lon=lon)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to perform weather query: {type(e).__name__}: {str(e)}",
        )

    if result is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to perform weather query!",
        )
    return ObjectResponseSchema[WeatherResponseModel](data=result)


@router.get(
    "/formatted",
    name="Weather (Formatted)",
    status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[WeatherInfoFormattedModel],
    description="Get current weather information formatted as a readable string",
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponseSchema},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponseSchema},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponseSchema},
    },
)
@limiter.limit("20/minute")
async def weather_formatted(
    request: Request,
    lat: Annotated[LatitudeConstraint, Field(description="Latitude")],
    lon: Annotated[LongitudeConstraint, Field(description="Longitude")],
    _=Depends(VerifyAccessToken),
):
    try:
        result = await QuerySystem.WeatherFormatted(lat=lat, lon=lon)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to perform weather query: {type(e).__name__}: {str(e)}",
        )

    if result is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to perform weather query!",
        )
    return ObjectResponseSchema[WeatherInfoFormattedModel](data=result)
