from typing import List, Optional

from fastapi import status
from fastapi.exceptions import HTTPException
from pydantic import BaseModel

from core.mongodb import (
    MongoDB,
    MongoDBFoodHandlers,
    MongoDBFoodSearchInputSchema,
    MongoDBFoodGetByIdsInputSchema,
)
from schemas.data import (
    DataFoodResponseModel,
    DataFoodsFormattedModel,
    format_foods_vietnamese,
)


FOOD_DEFAULT_SEARCH_LIMIT = 20

FoodSearchResult = List[DataFoodResponseModel]


class FoodFilter(BaseModel):
    Text: Optional[str] = None
    Category: Optional[str] = None
    Loai: Optional[str] = None
    KieuTenMon: Optional[str] = None
    Tags: Optional[str] = None


class FoodHandlers:
    def __init__(self) -> None:
        self.__mongo_handler = MongoDBFoodHandlers(MongoDB.get_database())

    async def FoodSearch(
        self,
        filters: Optional[FoodFilter] = None,
        limit: Optional[int] = None,
    ) -> FoodSearchResult:
        _filters = filters or FoodFilter()
        inputs = MongoDBFoodSearchInputSchema(
            Text=_filters.Text,
            Category=_filters.Category,
            Loai=_filters.Loai,
            KieuTenMon=_filters.KieuTenMon,
            Tags=_filters.Tags,
            Limit=limit or FOOD_DEFAULT_SEARCH_LIMIT,
        )

        resp = await self.__mongo_handler.Search(inputs)
        if not resp.success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to perform food search from MongoDB Handler! The handler responses: {resp.error}",
            )

        return [DataFoodResponseModel.FromMongoDB(m) for m in resp.foods]

    async def FoodsByIds(self, ids: List[str], limit: Optional[int] = None) -> FoodSearchResult:
        inputs = MongoDBFoodGetByIdsInputSchema(
            Ids=ids,
            Limit=limit or 100,
        )
        resp = await self.__mongo_handler.GetByIds(inputs)
        if not resp.success:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Failed to query foods by ids! The handler responses: {resp.error}",
            )
        return [DataFoodResponseModel.FromMongoDB(m) for m in resp.foods]

    async def FoodSearchFormatted(
        self,
        filters: Optional[FoodFilter] = None,
        limit: Optional[int] = None,
    ) -> DataFoodsFormattedModel:
        data = await self.FoodSearch(filters=filters, limit=limit)
        return DataFoodsFormattedModel(
            result=format_foods_vietnamese(data, title="Kết quả tìm kiếm món ăn"),
        )

    async def FoodsByIdsFormatted(
        self,
        ids: List[str],
        limit: Optional[int] = None,
    ) -> DataFoodsFormattedModel:
        data = await self.FoodsByIds(ids=ids, limit=limit)
        return DataFoodsFormattedModel(
            result=format_foods_vietnamese(data, title="Kết quả món ăn theo danh sách ID"),
        )
