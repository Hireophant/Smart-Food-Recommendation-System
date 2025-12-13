from fastapi import APIRouter, Depends, status, HTTPException, Request
from middleware.auth import VerifyAccessToken
from middleware.rate_limit import limiter
from query import QuerySystem
from schemas import ObjectResponseSchema, CollectionsResponseSchema
from schemas.errors import ErrorResponseSchema
from schemas.maps import MapGeocodingResponseModel, MapPlaceResponseModel
from pydantic import Field, StringConstraints, PositiveFloat
from typing import Annotated, Optional

router = APIRouter(prefix="/maps", tags=["Maps Informations"])

LatitudeConstraint = Annotated[float, Field(le=90, ge=-90)]
LongitudeConstraint = Annotated[float, Field(le=180, ge=-180)]
QueryTextConstraint = Annotated[str, StringConstraints(strip_whitespace=True)]
IdConstraint = Annotated[str, StringConstraints(strip_whitespace=True)]

@router.get(
    "/search", name="Maps Search", status_code=status.HTTP_200_OK,
    response_model=CollectionsResponseSchema[MapGeocodingResponseModel],
    description="Performing map search with the given input",
    responses={
        status.HTTP_401_UNAUTHORIZED : {"model" : ErrorResponseSchema },
        status.HTTP_422_UNPROCESSABLE_ENTITY : { "model" : ErrorResponseSchema },
        status.HTTP_500_INTERNAL_SERVER_ERROR : { "model" : ErrorResponseSchema },
    }
)
@limiter.limit("20/minute")
async def search(request: Request,
                 query: Annotated[QueryTextConstraint, Field(description="The query text to search (will strip whitespace)")],
                 focus_lat: Annotated[Optional[LatitudeConstraint], Field(description="The focus point latitude (if given, must also provide longitude)")] = None,
                 focus_lon: Annotated[Optional[LongitudeConstraint], Field(description="The focus point longitude (if given, must also provide latitude)")] = None,
                 search_center_lat: Annotated[Optional[LatitudeConstraint], Field(description="The search center point latitude (if given, must also provide longitude)")] = None,
                 search_center_lon: Annotated[Optional[LongitudeConstraint], Field(description="The search center point longitude (if given, must also provide latitude)")] = None,
                 search_radius: Annotated[Optional[PositiveFloat], Field(description="The radius of the search area (in meters)")] = None,
                 city_id: Annotated[Optional[int], Field(description="The city id to search")] = None,
                 district_id: Annotated[Optional[int], Field(description="The district id to search")] = None,
                 ward_id: Annotated[Optional[int], Field(description="The ward id to search")] = None,
                 _ = Depends(VerifyAccessToken)):
    result = await QuerySystem.MapsSearch(
        query=query,
        focus_lat=focus_lat,
        focus_lon=focus_lon,
        search_center_lat=search_center_lat,
        search_center_lon=search_center_lon,
        search_radius=search_radius,
        city_id=city_id,
        district_id=district_id,
        ward_id=ward_id
    )
    if result is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail="Failed to performing maps search!")
    return CollectionsResponseSchema[MapGeocodingResponseModel](data=result)

@router.get(
    "/autocomplete", name="Autocomplete", status_code=status.HTTP_200_OK,
    response_model=CollectionsResponseSchema[MapGeocodingResponseModel],
    description="Get a list of autocompletion address for the given input",
    responses={
        status.HTTP_401_UNAUTHORIZED : {"model" : ErrorResponseSchema },
        status.HTTP_422_UNPROCESSABLE_ENTITY : { "model" : ErrorResponseSchema },
        status.HTTP_500_INTERNAL_SERVER_ERROR : { "model" : ErrorResponseSchema },
    }
)
@limiter.limit("20/minute")
async def autocomplete(request: Request,
                       query: Annotated[QueryTextConstraint, Field(description="The query text to search (will strip whitespace)")],
                       focus_lat: Annotated[Optional[LatitudeConstraint], Field(description="The focus point latitude (if given, must also provide longitude)")] = None,
                       focus_lon: Annotated[Optional[LongitudeConstraint], Field(description="The focus point longitude (if given, must also provide latitude)")] = None,
                       search_center_lat: Annotated[Optional[LatitudeConstraint], Field(description="The search center point latitude (if given, must also provide longitude)")] = None,
                       search_center_lon: Annotated[Optional[LongitudeConstraint], Field(description="The search center point longitude (if given, must also provide latitude)")] = None,
                       search_radius: Annotated[Optional[PositiveFloat], Field(description="The radius of the search area (in meters)")] = None,
                       city_id: Annotated[Optional[int], Field(description="The city id to search")] = None,
                       district_id: Annotated[Optional[int], Field(description="The district id to search")] = None,
                       ward_id: Annotated[Optional[int], Field(description="The ward id to search")] = None,
                       _ = Depends(VerifyAccessToken)):
    result = await QuerySystem.MapsAutocomplete(
        query=query,
        focus_lat=focus_lat,
        focus_lon=focus_lon,
        search_center_lat=search_center_lat,
        search_center_lon=search_center_lon,
        search_radius=search_radius,
        city_id=city_id,
        district_id=district_id,
        ward_id=ward_id
    )
    if result is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail="Failed to performing maps autocomplete!")
    return CollectionsResponseSchema[MapGeocodingResponseModel](data=result)
        
@router.get(
    "/place", name="Place", status_code=status.HTTP_200_OK,
    response_model=ObjectResponseSchema[MapPlaceResponseModel],
    description="Get the details information of a certain place object",
    responses={
        status.HTTP_401_UNAUTHORIZED : {"model" : ErrorResponseSchema },
        status.HTTP_404_NOT_FOUND : {"model" : ErrorResponseSchema },
        status.HTTP_422_UNPROCESSABLE_ENTITY : { "model" : ErrorResponseSchema },
        status.HTTP_500_INTERNAL_SERVER_ERROR : { "model" : ErrorResponseSchema },
    }
)
@limiter.limit("20/minute")
async def place(request: Request,
                ids: Annotated[IdConstraint, Field(description="The object id to query details (will strip whitespace)")],
                _ = Depends(VerifyAccessToken)):
    result = await QuerySystem.MapsPlace(id=ids)
    if result is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail="Failed to performing maps places!")
    return ObjectResponseSchema[MapPlaceResponseModel](data=result)

@router.get(
    "/reverse", name="Reverse Geocoding", status_code=status.HTTP_200_OK,
    response_model=CollectionsResponseSchema[MapGeocodingResponseModel],
    description="Reverse from a map coordinate to maps object",
    responses={
        status.HTTP_401_UNAUTHORIZED : {"model" : ErrorResponseSchema },
        status.HTTP_422_UNPROCESSABLE_ENTITY : { "model" : ErrorResponseSchema },
        status.HTTP_500_INTERNAL_SERVER_ERROR : { "model" : ErrorResponseSchema },
    }
)
@limiter.limit("20/minute")
async def reverse(request: Request,
                  lat: Annotated[LatitudeConstraint, Field(description="The latitude of the coordinate to reverse")],
                  lon: Annotated[LongitudeConstraint, Field(description="The longitude of the coordinate to reverse")],
                  _ = Depends(VerifyAccessToken)):
    result = await QuerySystem.MapsReverse(lat=lat, lon=lon)
    if result is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail="Failed to performing maps reverses!")
    return CollectionsResponseSchema[MapGeocodingResponseModel](data=result)