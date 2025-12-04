import aiohttp, os, json
from core.vietmap.schemas import VietmapSearchResponse, VietmapReverseResponse, VietmapPlaceResponse,\
    VietmapGeocodingResponseModel
from typing import Optional, Dict, Annotated, List, Any
from core import MapCoordinate
from pydantic import PositiveFloat, BaseModel, ConfigDict, Field, PlainSerializer

VIETMAP_API_KEY_ENVIRONMENT_NAME = "VIETMAP_API_KEY"
VIETMAP_API_DISPLAY_TYPE = 1 # New response type, see API for reference.
VIETMAP_SEARCH_URL = "https://maps.vietmap.vn/api/search/v4"

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
    
class VietmapHandlers:
    def __init__(self) -> None:
        api_key = os.getenv(VIETMAP_API_KEY_ENVIRONMENT_NAME)
        if not api_key:
            raise EnvironmentError("No Vietmap API key found in the environment variable!")
        self.__api_key = api_key
        self.__client = aiohttp.ClientSession()
    
    async def __sendRequest(self, url: str, params: Dict[str, str] = dict()) -> Optional[List[Dict[str, Any]]]:
        if self.__client.closed:
            return None
        async with self.__client.get(url, params=params) as session:
            session.raise_for_status()
            return await session.json()

    async def Search(self, input: VietmapSearchInputSchema) -> Optional[VietmapSearchResponse]:
        params = {k: v for k, v in input.model_dump().items() if v is not None}
        params.update([('apiKey', self.__api_key), ('display_type', VIETMAP_API_DISPLAY_TYPE)])
        res = await self.__sendRequest(url=VIETMAP_SEARCH_URL,
                                       params=params)
        if res is None:
            return None
        return [VietmapGeocodingResponseModel(**val) for val in res]
    
    async def Close(self):
        await self.__client.close()
        
    async def __aenter__(self):
        await self.__client.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc, tb):
        await self.__client.__aexit__(exc_type, exc, tb)