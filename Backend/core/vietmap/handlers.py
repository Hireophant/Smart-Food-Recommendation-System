import aiohttp, os, json
from core.vietmap.schemas import VietmapSearchResponse, VietmapReverseResponse, VietmapPlaceResponse,\
    VietmapGeocodingResponseModel, VietmapAutocompleteResponse
from typing import Optional, Dict, Annotated, List, Any, cast
from core import MapCoordinate
from pydantic import PositiveFloat, BaseModel, ConfigDict, Field, PlainSerializer

VIETMAP_API_KEY_ENVIRONMENT_NAME = "VIETMAP_API_KEY"
VIETMAP_API_DISPLAY_TYPE = 1 # New response type, see API for reference.
VIETMAP_SEARCH_URL = "https://maps.vietmap.vn/api/search/v4"
VIETMAP_AUTOCOMPLETE_URL = "https://maps.vietmap.vn/api/autocomplete/v4"
VIETMAP_PLACE_URL = "https://maps.vietmap.vn/api/place/v4"
VIETMAP_REVERSE_URL = "https://maps.vietmap.vn/api/reverse/v4"

VietmapCoordinate = Annotated[
    MapCoordinate,
    PlainSerializer(lambda mc: f"{mc.Latitude},{mc.Longitude}", return_type="str")
]

class VietmapSearchInputSchema(BaseModel):
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

class VietmapHandlers:
    def __init__(self) -> None:
        api_key = os.getenv(VIETMAP_API_KEY_ENVIRONMENT_NAME)
        if not api_key:
            raise EnvironmentError("No Vietmap API key found in the environment variable!")
        self.__api_key = api_key
        self.__client = aiohttp.ClientSession()
    
    async def __sendRequest(self, url: str, params: Dict[str, Any] = dict()) -> Optional[Any]:
        if self.__client.closed:
            return None
        async with self.__client.get(url, params=params) as session:
            session.raise_for_status()
            return await session.json()
    
    async def __sendRequestList(self, url: str, params: Dict[str, Any] = dict()) -> Optional[List[Dict[str, Any]]]:
        res = await self.__sendRequest(url, params=params)
        return None if res is None else cast(List[Dict[str, Any]], res)
    
    async def __sendRequestDict(self, url: str, params: Dict[str, Any] = dict()) -> Optional[Dict[str, Any]]:
        res = await self.__sendRequest(url, params=params)
        return None if res is None else cast(Dict[str, Any], res)
    
    def __finalize_params(self, raw_params: Dict[str, Any]):
        raw_params.update([('apiKey', self.__api_key), ('display_type', VIETMAP_API_DISPLAY_TYPE)])

    async def Search(self, inputs: VietmapSearchInputSchema) -> Optional[VietmapSearchResponse]:
        params = {k: v for k, v in inputs.model_dump().items() if v is not None}
        self.__finalize_params(params)
        
        res = await self.__sendRequestList(url=VIETMAP_SEARCH_URL, params=params)
        if res is None:
            return None
        return [VietmapGeocodingResponseModel(**val) for val in res]
    
    async def Autocomplete(self, inputs: VietmapSearchInputSchema) -> Optional[VietmapAutocompleteResponse]:
        params = {k: v for k, v in inputs.model_dump().items() if v is not None}
        self.__finalize_params(params)
        
        res = await self.__sendRequestList(url=VIETMAP_AUTOCOMPLETE_URL, params=params)
        return None if res is None else [VietmapGeocodingResponseModel(**val) for val in res]
    
    async def Place(self, ref_id: str) -> Optional[VietmapPlaceResponse]:
        params = {"ref_id": ref_id}
        self.__finalize_params(params)
        
        res = await self.__sendRequestDict(url=VIETMAP_PLACE_URL, params=params)
        return None if res is None else VietmapPlaceResponse(**res)
    
    async def Reverse(self, coords: MapCoordinate) -> Optional[VietmapReverseResponse]:
        params = {"lat": coords.Latitude, "lon": coords.Longitude}
        self.__finalize_params(params)
        
        res = await self.__sendRequestList(VIETMAP_REVERSE_URL, params=params)
        return None if res is None else [VietmapGeocodingResponseModel(**val) for val in res]
    
    async def Close(self):
        await self.__client.close()
        
    async def __aenter__(self):
        await self.__client.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc, tb):
        await self.__client.__aexit__(exc_type, exc, tb)