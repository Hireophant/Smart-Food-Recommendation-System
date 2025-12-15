from pydantic import BaseModel, ConfigDict, Field, PositiveFloat
from typing import Optional, List, Dict, Any
from core.mongodb import MongoDBRestaurantResponse

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