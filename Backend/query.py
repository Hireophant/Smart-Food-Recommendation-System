from handlers.maps import *

class QuerySystem:
    """The centralized backend query system."""
    
    # Here is what we call converter, adapter,...
    @staticmethod
    def __lat_lon_to_coord(lat: Optional[float], lon: Optional[float], name: str) -> Optional[MapCoord]:
        if (lat is not None) ^ (lon is not None):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                                detail=f"If given {name}, both latitude and longitude must be provided!")
        elif lat is not None and lon is not None:
            return MapCoord(lat=lat, lon=lon)
        return None

    @staticmethod
    async def MapsSearch(query: str,
                         focus_lat: Optional[float] = None,
                         focus_lon: Optional[float] = None,
                         search_center_lat: Optional[float] = None,
                         search_center_lon: Optional[float] = None,
                         search_radius: Optional[PositiveFloat] = None,
                         city_id: Optional[int] = None,
                         district_id: Optional[int] = None,
                         ward_id: Optional[int] = None) -> Optional[MapSearchResponse]:
        
        focus = QuerySystem.__lat_lon_to_coord(focus_lat, focus_lon, "Focus")
        search_center = QuerySystem.__lat_lon_to_coord(search_center_lat, search_center_lon, "Search Center")
        
        return await MapsHandler.Search(
            query=query,
            focus=focus,
            search_center=search_center,
            search_radius=search_radius,
            city_id=city_id,
            district_id=district_id,
            ward_id=ward_id
        )

    @staticmethod
    async def MapsAutocomplete(query: str,
                               focus_lat: Optional[float] = None,
                               focus_lon: Optional[float] = None,
                               search_center_lat: Optional[float] = None,
                               search_center_lon: Optional[float] = None,
                               search_radius: Optional[PositiveFloat] = None,
                               city_id: Optional[int] = None,
                               district_id: Optional[int] = None,
                               ward_id: Optional[int] = None) -> Optional[MapAutocompleteResponse]:
        
        focus = QuerySystem.__lat_lon_to_coord(focus_lat, focus_lon, "Focus")
        search_center = QuerySystem.__lat_lon_to_coord(search_center_lat, search_center_lon, "Search Center")
        
        return await MapsHandler.Autocomplete(
            query=query,
            focus=focus,
            search_center=search_center,
            search_radius=search_radius,
            city_id=city_id,
            district_id=district_id,
            ward_id=ward_id
        )
        
    @staticmethod
    async def MapsReverse(lat: float, lon: float) -> Optional[MapReverseResponse]:
        return await MapsHandler.Reverse(MapCoord(lat=lat, lon=lon))
        
    @staticmethod
    async def MapsPlace(id: str) -> Optional[MapPlaceResponseModel]:
        return await MapsHandler.Place(id)