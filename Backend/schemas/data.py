from pydantic import BaseModel, ConfigDict, Field, PositiveFloat
from typing import Optional, List, Dict, Any
from core.mongodb import MongoDBRestaurantResponse, MongoDBFoodResponse


class DataRestaurantsFormattedModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    # Required by spec: a single variable named `result`.
    result: str = Field(default="", description="Formatted restaurants result")


class DataFoodsFormattedModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    # Required by spec: a single variable named `result`.
    result: str = Field(default="", description="Formatted foods result")

class DataLocationDetailsModel(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    Address: str = Field(serialization_alias="address", 
                         description="The full address of the restaurant")
    Province: str = Field(serialization_alias='province',
                          description="The province of the restaurants")
    District: str = Field(serialization_alias='district',
                          description="The district of the restaurants")
    Ward: Optional[str] = Field(default=None, serialization_alias="ward",
                                description="The ward of the restaurant (if having)")
    Latitude: float = Field(serialization_alias="lat", le=90, ge=-90,
                            description="The latitude of the map coordinate")
    Longitude: float = Field(serialization_alias="lon", le=180, ge=-180,
                             description="The longitude of the map coordinate")
    Distance: Optional[float] = Field(default=None, serialization_alias="distance",
                                      description="Distance from user in meters, if having")
    DistanceKm: Optional[float] = Field(default=None, serialization_alias="distance_km",
                                        description="Distance from user in kilometers")

class DataRestaurantResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    Id: str = Field(serialization_alias='id',
                    description="The id of the restaurant (defined by the database)")
    Score: Optional[float] = Field(default=None, serialization_alias="score",
                                   description="The relevant score of the search")
    Name: str = Field(serialization_alias='name',
                      description="The name of the restaurant")
    Category: str = Field(serialization_alias='category',
                          description="The category of the restaurants (defined by the database)")
    Rating: float = Field(serialization_alias='rating',
                          description="The rating of the restaurant (range [0.0, 5.0])")
    Location: DataLocationDetailsModel = Field(serialization_alias="location",
                                               description="The location details information of the restaurant")
    Tags: List[str] = Field(default_factory=list, serialization_alias="tags",
                            description="The list of tags of the restaurant")
    Link: Optional[str] = Field(default=None, serialization_alias="link",
                                description="The Google Maps Place links of the restaurant (if having)")
    
    @staticmethod
    def FromMongoDB(inputs: MongoDBRestaurantResponse) -> "DataRestaurantResponseModel":
        return DataRestaurantResponseModel(
            Id=inputs.id,
            Score=inputs.score,
            Name=inputs.name,
            Category=inputs.category,
            Rating=inputs.rating,
            Tags=inputs.tags,
            Link=inputs.link,
            Location=DataLocationDetailsModel(
                Address=inputs.address,
                Province=inputs.province,
                District=inputs.district,
                Ward=inputs.ward,
                Longitude=inputs.location["coordinates"][0],
                Latitude=inputs.location["coordinates"][1],
                Distance=inputs.distance,
                DistanceKm=inputs.distance_km
            )
        )


class DataFoodResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Id: str = Field(serialization_alias="id", description="The ObjectId of the food document")
    DishName: str = Field(serialization_alias="dish_name", description="Food name")
    Category: str = Field(serialization_alias="category", description="Dish category")
    KieuTenMon: str = Field(serialization_alias="kieu_ten_mon", description="How the dish is named")
    Loai: str = Field(serialization_alias="loai", description="Type of dish")
    Description: str = Field(
        default="No description",
        serialization_alias="description",
        description="Food description (defaults to 'No description' if missing)",
    )
    Tags: List[str] = Field(
        default_factory=list,
        serialization_alias="tags",
        description="Dish tags",
    )

    @staticmethod
    def FromMongoDB(inputs: MongoDBFoodResponse) -> "DataFoodResponseModel":
        return DataFoodResponseModel(
            Id=inputs.id,
            DishName=inputs.dish_name,
            Category=inputs.category,
            KieuTenMon=inputs.kieu_ten_mon,
            Loai=inputs.loai,
            Description=getattr(inputs, "description", None) or "No description",
            Tags=inputs.tags,
        )


def format_restaurants_vietnamese(
    restaurants: List[DataRestaurantResponseModel],
    *,
    title: str = "Kết quả nhà hàng",
) -> str:
    lines: List[str] = []
    lines.append(title)
    lines.append(f"Số lượng: {len(restaurants)}")

    if not restaurants:
        lines.append("(Không có kết quả)")
        return "\n".join(lines).strip() + "\n"

    for i, r in enumerate(restaurants, start=1):
        loc = r.Location

        addr_parts = [p for p in [loc.Address, loc.Ward, loc.District, loc.Province] if p]
        addr = ", ".join(addr_parts)

        meta: List[str] = []
        if r.Category:
            meta.append(r.Category)
        meta.append(f"⭐ {r.Rating:.1f}")
        if loc.DistanceKm is not None:
            meta.append(f"~{loc.DistanceKm:.2f} km")

        tags = ", ".join(r.Tags) if r.Tags else None

        lines.append(f"{i}. {r.Name} ({' | '.join(meta)})")
        if addr:
            lines.append(f"   Địa chỉ: {addr}")
        lines.append(f"   Tọa độ: {loc.Latitude}, {loc.Longitude}")
        if tags:
            lines.append(f"   Tags: {tags}")
        if r.Link:
            lines.append(f"   Link: {r.Link}")

    return "\n".join(lines).strip() + "\n"


def format_foods_vietnamese(
    foods: List[DataFoodResponseModel],
    *,
    title: str = "Kết quả món ăn",
) -> str:
    lines: List[str] = []
    lines.append(title)
    lines.append(f"Số lượng: {len(foods)}")

    if not foods:
        lines.append("(Không có kết quả)")
        return "\n".join(lines).strip() + "\n"

    for i, f in enumerate(foods, start=1):
        meta: List[str] = []
        if f.Category:
            meta.append(f.Category)
        if f.Loai:
            meta.append(f.Loai)
        if f.KieuTenMon:
            meta.append(f.KieuTenMon)

        tags = ", ".join(f.Tags) if f.Tags else None

        if meta:
            lines.append(f"{i}. {f.DishName} ({' | '.join(meta)})")
        else:
            lines.append(f"{i}. {f.DishName}")
        if f.Description:
            lines.append(f"   Mô tả: {f.Description}")
        if tags:
            lines.append(f"   Tags: {tags}")
        lines.append(f"   Id: {f.Id}")

    return "\n".join(lines).strip() + "\n"
