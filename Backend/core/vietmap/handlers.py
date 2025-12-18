import aiohttp, os, json
from core.vietmap.schemas import (
    VietmapSearchResponse,
    VietmapReverseResponse,
    VietmapPlaceResponse,
    VietmapGeocodingResponseModel,
    VietmapAutocompleteResponse,
    MapCoordinate,
    VietmapRouteResult
)
from typing import Optional, Dict, Annotated, List, Any, cast, Tuple, Union
from pydantic import PositiveFloat, BaseModel, ConfigDict, Field, PlainSerializer
from fastapi import status, HTTPException
from utils import Logger
from enum import StrEnum
from dataclasses import dataclass, field

VIETMAP_API_KEY_ENVIRONMENT_NAME = "VIETMAP_API_KEY"
VIETMAP_API_DISPLAY_TYPE = 1 # New response type, see API for reference.
VIETMAP_SEARCH_URL = "https://maps.vietmap.vn/api/search/v4"
VIETMAP_AUTOCOMPLETE_URL = "https://maps.vietmap.vn/api/autocomplete/v4"
VIETMAP_PLACE_URL = "https://maps.vietmap.vn/api/place/v4"
VIETMAP_REVERSE_URL = "https://maps.vietmap.vn/api/reverse/v4"
VIETMAP_ROUTE_URL = "https://maps.vietmap.vn/api/route/v3"

def MapCoordinateToVietmapString(coord: MapCoordinate) -> str:
    return f"{coord.Latitude},{coord.Longitude}"

VietmapCoordinate = Annotated[
    MapCoordinate,
    PlainSerializer(lambda mc: MapCoordinateToVietmapString(mc), return_type="str")
]

class VietmapSearchInputSchema(BaseModel):
    """
    Input parameters for Search and Autocomplete operations.
    
    Usage:
        # Basic search
        VietmapSearchInputSchema(Text="restaurant")
        
        # Search with location focus
        VietmapSearchInputSchema(
            Text="cafe",
            Focus=MapCoordinate(Latitude=21.0285, Longitude=105.8542)
        )
        
        # Search within radius
        VietmapSearchInputSchema(
            Text="hotel",
            CircleCenter=MapCoordinate(Latitude=21.0285, Longitude=105.8542),
            CircleRadius=2.5  # kilometers
        )
    """
    model_config = ConfigDict(extra="ignore")
    
    Text: str = Field(serialization_alias='text')
    Focus: Optional[VietmapCoordinate] = Field(default=None, serialization_alias='focus')
    Layers: Optional[str] = Field(default=None, serialization_alias='layers')
    CircleCenter: Optional[VietmapCoordinate] = Field(default=None, serialization_alias='circle_center')
    CircleRadius: Optional[PositiveFloat] = Field(default=None, serialization_alias='circle_radius')
    Categories: Optional[str] = Field(default=None, serialization_alias='cats')
    CityId: Optional[int] = Field(default=None, serialization_alias='cityId')
    DistId: Optional[int] = Field(default=None, serialization_alias='distId')
    WardId: Optional[int] = Field(default=None, serialization_alias='wardId')
    
VietmapAutocompleteInputSchema = VietmapSearchInputSchema

class VietmapRouteVehicleType(StrEnum):
    Car = "car"
    Motorcycle = "motorcycle"
    Truck = "truck"

class VietmapRouteAvoidType(StrEnum):
    Toll = "toll"
    Ferry = "ferry"
    
VietmapRouteAvoid = Annotated[
    List[VietmapRouteAvoidType],
    PlainSerializer(lambda l: ','.join(str(i) for i in set(l)), return_type=str)
]


class VietmapRouteInputOptions(BaseModel):
    Vehicle: VietmapRouteVehicleType = Field(default=VietmapRouteVehicleType.Car, serialization_alias="vehicle")
    Avoid: Optional[VietmapRouteAvoid] = Field(default=None, serialization_alias="avoid")

@dataclass
class VietmapRouteInput:
    Point: List[VietmapCoordinate] = field(default_factory=list)
    Options: Optional[VietmapRouteInputOptions] = None

class VietmapClient:
    """
    Async client for interacting with Vietmap API services.
    
    Provides methods for geocoding, reverse geocoding, place details, and autocomplete.
    Requires VIETMAP_API_KEY environment variable to be set.
    
    Usage:
        async with VietmapClient() as client:
            results = await client.Search(VietmapSearchInputSchema(Text="Hanoi"))
    """
    def __init__(self) -> None:
        api_key = os.getenv(VIETMAP_API_KEY_ENVIRONMENT_NAME)
        if not api_key:
            raise EnvironmentError("No Vietmap API key found in the environment variable!")
        self.__api_key = api_key
        self.__client = aiohttp.ClientSession()
    
    async def __sendRequest(self, url: str, params: Union[Dict[str, Any], List[Tuple[str, Any]]] = dict()) -> Any:
        if self.__client.closed:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                detail="Vietmap client session is closed!")
        async with self.__client.get(url, params=params) as session:
            if session.status == status.HTTP_404_NOT_FOUND: # Not found
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                                    detail="Not found")
            elif session.status == status.HTTP_401_UNAUTHORIZED: # Unauthorize (possibly wrong API key)
                raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                    detail="Authorization failed for Vietmap API (possibly wrong API key)")
            elif not session.ok:
                Logger.LogError(f"Vietmap API response with code '{session.status}', with reason '{session.reason}'")
                raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                    detail=f"Failed to query from Vietmap API")
            
            return await session.json()
    
    async def __sendRequestList(self, url: str, params: Union[Dict[str, Any], List[Tuple[str, Any]]] = dict()) -> Optional[List[Dict[str, Any]]]:
        res = await self.__sendRequest(url, params=params)
        return None if res is None else cast(List[Dict[str, Any]], res)
    
    async def __sendRequestDict(self, url: str, params: Union[Dict[str, Any], List[Tuple[str, Any]]] = dict()) -> Optional[Dict[str, Any]]:
        res = await self.__sendRequest(url, params=params)
        return None if res is None else cast(Dict[str, Any], res)
    
    def __finalize_params(self, raw_params: Dict[str, Any], include_display: bool = True):
        raw_params.update([('apiKey', self.__api_key)])
        if include_display:
            raw_params.update([('display_type', VIETMAP_API_DISPLAY_TYPE)])

    async def Search(self, inputs: VietmapSearchInputSchema) -> Optional[VietmapSearchResponse]:
        """
        Search for places by text query with optional filters.
        
        Args:
            inputs: Search parameters including text query and optional filters
        
        Returns:
            List of geocoding results or None if no results found
        
        Example:
            search_input = VietmapSearchInputSchema(
                Text="coffee shop",
                Focus=MapCoordinate(Latitude=21.0285, Longitude=105.8542),
                CircleRadius=5.0
            )
            results = await client.Search(search_input)
        """
        params = {k: v for k, v in inputs.model_dump(by_alias=True).items() if v is not None}
        if 'text' in params:
            params.update([('text', '"' + params['text'] + '"')])
        self.__finalize_params(params)
        
        res = await self.__sendRequestList(url=VIETMAP_SEARCH_URL, params=params)
        if res is None:
            return None
        return [VietmapGeocodingResponseModel(**val) for val in res]
    
    async def Autocomplete(self, inputs: VietmapSearchInputSchema) -> Optional[VietmapAutocompleteResponse]:
        """
        Get autocomplete suggestions for partial text input.
        
        Args:
            inputs: Autocomplete parameters including partial text query
        
        Returns:
            List of autocomplete suggestions or None if no results found
        
        Example:
            autocomplete_input = VietmapAutocompleteInputSchema(
                Text="Ha Noi",
                CityId=1  # Limit to specific city
            )
            suggestions = await client.Autocomplete(autocomplete_input)
        """
        params = {k: v for k, v in inputs.model_dump(by_alias=True).items() if v is not None}
        if 'text' in params:
            params.update([('text', '"' + params['text'] + '"')])
        self.__finalize_params(params)
        
        res = await self.__sendRequestList(url=VIETMAP_AUTOCOMPLETE_URL, params=params)
        return None if res is None else [VietmapGeocodingResponseModel(**val) for val in res]
    
    async def Place(self, ref_id: str) -> Optional[VietmapPlaceResponse]:
        """
        Get detailed information about a specific place by reference ID.
        
        Args:
            ref_id: Reference ID from Search or Autocomplete results
        
        Returns:
            Detailed place information or None if not found
        
        Example:
            # First get ref_id from search results
            search_results = await client.Search(VietmapSearchInputSchema(Text="Hanoi Opera House"))
            ref_id = search_results[0].ReferenceId
            
            # Then get detailed place info
            place_details = await client.Place(ref_id)
        """
        params = {"refId": ref_id}
        self.__finalize_params(params)
        
        res = await self.__sendRequestDict(url=VIETMAP_PLACE_URL, params=params)
        return None if res is None else VietmapPlaceResponse(**res)
    
    async def Reverse(self, coords: MapCoordinate) -> Optional[VietmapReverseResponse]:
        """
        Reverse geocode coordinates to get place information.
        
        Args:
            coords: Map coordinates (latitude and longitude)
        
        Returns:
            List of places at or near the coordinates or None if not found
        
        Example:
            coords = MapCoordinate(Latitude=21.0285, Longitude=105.8542)
            places = await client.Reverse(coords)
        """
        params = {"lat": coords.Latitude, "lng": coords.Longitude}
        self.__finalize_params(params)
        
        res = await self.__sendRequestList(VIETMAP_REVERSE_URL, params=params)
        return None if res is None else [VietmapGeocodingResponseModel(**val) for val in res]
    
    async def Route(self, inputs: VietmapRouteInput) -> Optional[VietmapRouteResult]:
        params_d = {}
        if inputs.Options is not None:
            params_d = {k:v for k, v in inputs.Options.model_dump(by_alias=True).items() if v is not None}
        self.__finalize_params(params_d, include_display=False)
        params = list(params_d.items())
        params.extend(('point', MapCoordinateToVietmapString(p)) for p in inputs.Point)
        
        res = await self.__sendRequestDict(VIETMAP_ROUTE_URL, params=params)
        return None if res is None else VietmapRouteResult(**res)
    
    async def Close(self):
        await self.__client.close()
        
    async def __aenter__(self):
        await self.__client.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc, tb):
        await self.__client.__aexit__(exc_type, exc, tb)