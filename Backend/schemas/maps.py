from pydantic import ConfigDict, Field, BaseModel
from enum import Enum
from typing import List
from core.vietmap import (
    VietmapBoundariesType,
    VietmapBoundaries,
    VietmapEntryPoint,
    VietmapGeocodingResponseModel,
    VietmapPlaceResponseModel
)

class MapCoord(BaseModel):
    Latitude: float = Field(default=0.0, alias="lat", le=90, ge=-90,
                            description="The latitude of the map coordinate")
    Longitude: float = Field(default=0.0, alias="lon", le=180, ge=-180,
                             description="The longitude of the map coordinate")

class MapBoundariesType(str, Enum):
    Unknown = "unknown" # Special use, for handling unexpected case (most of the time no need)
    City = "city"
    District = "district"
    Ward = "ward"
    
    @staticmethod
    def FromVietmap(inputs: VietmapBoundariesType) -> "MapBoundariesType":
        if inputs == VietmapBoundariesType.City:
            return MapBoundariesType.City
        elif inputs == VietmapBoundariesType.District:
            return MapBoundariesType.District
        elif inputs == VietmapBoundariesType.Ward:
            return MapBoundariesType.Ward
        else:
            # Handle unexpected case here
            return MapBoundariesType.Unknown

class MapBoundaries(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    Type: MapBoundariesType = Field(serialization_alias="type",
                                    description="The type of boundaries (city, district, ward, or unknown if not known (rarely))")
    BoundariesId: int = Field(serialization_alias="boundaries_id",
                              description="The boundaries (different from object id, defined by API)")
    FullName: str = Field(default='', serialization_alias="full_name",
                          description="The full name of the boundary")
    
    @staticmethod
    def FromVietmap(inputs: VietmapBoundaries) -> "MapBoundaries":
        return MapBoundaries(
            Type=MapBoundariesType.FromVietmap(inputs.Type),
            BoundariesId=inputs.Id,
            FullName=inputs.FullName
        )

class MapEntryPoint(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Id: str = Field(default='', serialization_alias="id",
                    description="The id of the entry point object (defined by API)")
    Name: str = Field(default='', serialization_alias="name",
                      description="The name of the entry point object")
    
    @staticmethod
    def FromVietmap(inputs: VietmapEntryPoint) -> "MapEntryPoint":
        return MapEntryPoint(
            Id=inputs.ReferenceId,
            Name=inputs.Name
        )

class MapGeocodingResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    Id: str = Field(default='', serialization_alias="id",
                    description="The id of the object (defined by API)")
    Distance: float = Field(default=0.0, serialization_alias="distance_km",
                            description="The distance in km (if given an initial position, otherwise 0)")
    Name: str = Field(default='', serialization_alias="name",
                      description="The name of the object")
    Address: str = Field(default='', serialization_alias="address",
                         description="The address of the object")
    Display: str = Field(default='', serialization_alias="display",
                         description="The full details (name and address) of the object")
    Boundaries: List[MapBoundaries] = Field(default_factory=list, serialization_alias="boundaries",
                                            description="A list of boundaries the objects is in")
    EntryPoints: List[MapEntryPoint] = Field(default_factory=list, serialization_alias="entry_points",
                                                 description="A list of entry points of the objects (usually POIs), usually only available on popular places.")

    @staticmethod
    def FromVietmap(inputs: VietmapGeocodingResponseModel) -> "MapGeocodingResponseModel":
        return MapGeocodingResponseModel(
            Id=inputs.ReferenceId,
            Distance=inputs.Distance,
            Name=inputs.Name,
            Address=inputs.Address,
            Display=inputs.Display,
            Boundaries=[MapBoundaries.FromVietmap(m) for m in inputs.Boundaries],
            EntryPoints=[MapEntryPoint.FromVietmap(e) for e in inputs.EntryPoints]
        )

class MapPlaceDetails(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    HouseNumber: str = Field(serialization_alias="house_number",
                             description="House, or building number") # House or building number
    Street: str = Field(serialization_alias="street",
                        description="Street name")
    Address: str = Field(serialization_alias="address",
                         description="Additional address information (if provided)")
    City: MapBoundaries = Field(serialization_alias="city",
                                description="The city boundary information")
    District: MapBoundaries = Field(serialization_alias="district",
                                description="The district boundary information")
    Ward: MapBoundaries = Field(serialization_alias="ward",
                                description="The ward boundary information")
        
class MapPlaceResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    Address: str = Field(serialization_alias="address",
                         description="The address of the objects")
    Name: str = Field(serialization_alias="name",
                      description="The name of the objects")
    Latitude: float = Field(default=0.0, serialization_alias="lat", le=90, ge=-90,
                            description="The latitude of the object")
    Longitude: float = Field(default=0.0, serialization_alias="lon", le=180, ge=-180,
                            description="The longitude of the object")
    Details: MapPlaceDetails = Field(serialization_alias="details",
                                     description="The details of the objects")
    
    @staticmethod
    def FromVietmap(inputs: VietmapPlaceResponseModel) -> "MapPlaceResponseModel":
        return MapPlaceResponseModel(
            Address=inputs.Display,
            Name=inputs.Name,
            Latitude=inputs.Latitude,
            Longitude=inputs.Longitude,
            Details=MapPlaceDetails(
                HouseNumber=inputs.HouseNumber,
                Street=inputs.Street,
                Address=inputs.Address,
                City=MapBoundaries(
                    Type=MapBoundariesType.City,
                    BoundariesId=inputs.CityId,
                    FullName=inputs.CityName
                ),
                District=MapBoundaries(
                    Type=MapBoundariesType.District,
                    BoundariesId=inputs.DistrictId,
                    FullName=inputs.DistrictName
                ),
                Ward=MapBoundaries(
                    Type=MapBoundariesType.Ward,
                    BoundariesId=inputs.WardId,
                    FullName=inputs.WardName
                )
            )
        )
