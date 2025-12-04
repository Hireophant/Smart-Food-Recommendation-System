from enum import Enum
from pydantic import BaseModel, ConfigDict, Field
from typing import List

class VietmapBoundariesType(int, Enum):
    City = 0
    District = 1
    Ward = 2

class VietmapBoundaries(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    Type: VietmapBoundariesType = Field(default=VietmapBoundariesType.City, validation_alias="type")
    Id: int = Field(default=0, validation_alias="id")
    FullName: str = Field(default='', validation_alias="full_name")
    
class VietmapEntryPoint(BaseModel):
    model_config = ConfigDict(extra="ignore")

    ReferenceId: str = Field(default='', validation_alias="ref_id")
    Name: str = Field(default='', validation_alias="name")
    
class VietmapGeocodingResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    ReferenceId: str = Field(default='', validation_alias="ref_id")
    Distance: float = Field(default=0, validation_alias="distance") # In Kilometer
    Address: str = Field(default='', validation_alias="address")
    Name: str = Field(default='', validation_alias="name")
    Display: str = Field(default='', validation_alias="display")
    Boundaries: List[VietmapBoundaries] = Field(default_factory=list, validation_alias="boundaries")
    Categories: List[str] = Field(default_factory=list, validation_alias="categories")
    EntryPoints: List[VietmapEntryPoint] = Field(default_factory=list, validation_alias="entry_points")
    
class VietmapPlaceResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Display: str = Field(default='', validation_alias="display")
    Name: str = Field(default='', validation_alias="name")
    HouseNumber: str = Field(default='', validation_alias="hs_num") # House or building number
    Street: str = Field(default='', validation_alias="street")
    Address: str = Field(default='', validation_alias="address")
    CityId: int = Field(default=0, validation_alias="city_id")
    CityName: str = Field(default='', validation_alias="city")
    DistrictId: int = Field(default=0, validation_alias="district_id")
    DistrictName: str = Field(default='', validation_alias="district")
    WardId: int = Field(default=0, validation_alias="ward_id")
    WardName: str = Field(default='', validation_alias="ward")
    Latitude: float = Field(default=0, validation_alias='lat')
    Longitude: float = Field(default=0, validation_alias='lng')
    
VietmapSearchResponse = List[VietmapGeocodingResponseModel]
VietmapPlaceResponse = VietmapPlaceResponseModel
VietmapReverseResponse = List[VietmapGeocodingResponseModel]