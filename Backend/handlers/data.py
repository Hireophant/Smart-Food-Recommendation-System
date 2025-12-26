from core.mongodb import MongoDB, MongoDBHandlers, MongoDBSearchInputSchema, MongoDBGetByIdsInputSchema
from schemas.data import DataRestaurantResponseModel
from typing import Optional, List
from pydantic import PositiveFloat, BaseModel
from fastapi import status
from fastapi.exceptions import HTTPException

DATA_DEFAULT_SEARCH_RADIUS = 5000
DATA_DEFAULT_SEARCH_LIMIT = 10

DataRestaurantSearchResult = List[DataRestaurantResponseModel]

class DataRestaurantFilter(BaseModel):
    Query: Optional[str] = None
    Radius: Optional[PositiveFloat] = None
    MinRating: Optional[float] = None
    Category: Optional[str] = None
    Tags: Optional[str] = None
    Province: Optional[str] = None
    District: Optional[str] = None

class DataHandlers:
    def __init__(self) -> None:
        self.__mongo_handler = MongoDBHandlers(MongoDB.get_database())
    
    async def RestaurantSearch(self, focus_latitude: Optional[float],
                               focus_longitude: Optional[float],
                               filters: Optional[DataRestaurantFilter] = None,
                               limit: Optional[int] = None) -> DataRestaurantSearchResult:
        _filters = filters or DataRestaurantFilter()
        inputs = MongoDBSearchInputSchema(
            Text=_filters.Query,
            Latitude=focus_latitude,
            Longitude=focus_longitude,
            Radius=_filters.Radius or DATA_DEFAULT_SEARCH_RADIUS,
            MinRating=_filters.MinRating,
            Category=_filters.Category,
            Tags=_filters.Tags,
            Province=_filters.Province,
            District=_filters.District,
            Limit=limit or DATA_DEFAULT_SEARCH_LIMIT
        )
        resp = await self.__mongo_handler.Search(inputs)
        if not resp.success:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                detail=f"Failed to perform search from MongoDB Handler! The handler responses: {resp.error}")
        
        return [DataRestaurantResponseModel.FromMongoDB(m) for m in resp.restaurants]

    async def RestaurantsByIds(self, ids: List[str], limit: Optional[int] = None) -> DataRestaurantSearchResult:
        inputs = MongoDBGetByIdsInputSchema(
            Ids=ids,
            Limit=limit or 100,
        )
        resp = await self.__mongo_handler.GetByIds(inputs)
        if not resp.success:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Failed to query restaurants by ids! The handler responses: {resp.error}",
            )
        return [DataRestaurantResponseModel.FromMongoDB(m) for m in resp.restaurants]