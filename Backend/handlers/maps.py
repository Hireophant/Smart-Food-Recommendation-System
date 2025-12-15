from core.vietmap import VietmapClient, VietmapSearchInputSchema, MapCoordinate
from schemas.maps import (
    MapGeocodingResponseModel,
    MapPlaceResponseModel,
    MapCoord
)
from typing import List, Optional
from pydantic import PositiveFloat

MapSearchResponse = List[MapGeocodingResponseModel]
MapAutocompleteResponse = List[MapGeocodingResponseModel]
MapReverseResponse = List[MapGeocodingResponseModel]
MapPlaceResponse = MapPlaceResponseModel

class MapsHandler:
    """Map handlers for map tasks (static handlers)."""
    
    @staticmethod
    async def Search(query: str,
                     focus: Optional[MapCoord] = None,
                     search_center: Optional[MapCoord] = None,
                     search_radius: Optional[PositiveFloat] = None,
                     city_id: Optional[int] = None,
                     district_id: Optional[int] = None,
                     ward_id: Optional[int] = None) -> Optional[MapSearchResponse]:
        inputs = VietmapSearchInputSchema(
            Text=query,
            Focus=None if not focus else MapCoordinate(focus.Latitude, focus.Longitude),
            Layers=None,
            CircleCenter=None if not search_center else MapCoordinate(search_center.Latitude, search_center.Longitude),
            CircleRadius=search_radius,
            Categories=None,
            CityId=city_id, DistId=district_id, WardId=ward_id
        )
        
        async with VietmapClient() as client:
            result = await client.Search(inputs)
            if result is None:
                return None
            return [MapGeocodingResponseModel.FromVietmap(m) for m in result]

    @staticmethod
    async def Autocomplete(query: str,
                           focus: Optional[MapCoord] = None,
                           search_center: Optional[MapCoord] = None,
                           search_radius: Optional[PositiveFloat] = None,
                           city_id: Optional[int] = None,
                           district_id: Optional[int] = None,
                           ward_id: Optional[int] = None) -> Optional[MapAutocompleteResponse]:
        inputs = VietmapSearchInputSchema(
            Text=query,
            Focus=None if not focus else MapCoordinate(focus.Latitude, focus.Longitude),
            Layers=None,
            CircleCenter=None if not search_center else MapCoordinate(search_center.Latitude, search_center.Longitude),
            CircleRadius=search_radius,
            Categories=None,
            CityId=city_id, DistId=district_id, WardId=ward_id
        )
        
        async with VietmapClient() as client:
            result = await client.Autocomplete(inputs)
            if result is None:
                return None
            return [MapGeocodingResponseModel.FromVietmap(m) for m in result]
        
    @staticmethod
    async def Reverse(coord: MapCoord) -> Optional[MapReverseResponse]:
        async with VietmapClient() as client:
            v_coord = MapCoordinate(coord.Latitude, coord.Longitude)
            result = await client.Reverse(v_coord)
            if result is None:
                return None
            return [MapGeocodingResponseModel.FromVietmap(m) for m in result]
        
    @staticmethod
    async def Place(id: str) -> Optional[MapPlaceResponseModel]:
        async with VietmapClient() as client:
            result = await client.Place(id)
            return None if not result else MapPlaceResponseModel.FromVietmap(result)