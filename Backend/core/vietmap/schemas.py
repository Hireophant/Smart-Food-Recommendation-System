from enum import Enum
from pydantic import BaseModel, ConfigDict, Field, field_validator
from typing import List, Tuple, Optional
from dataclasses import dataclass

@dataclass
class MapCoordinate:
    """
    Represents geographic coordinates.
    
    Usage:
        coords = MapCoordinate(Latitude=21.0285, Longitude=105.8542)
    """
    Latitude: float
    Longitude: float

class VietmapBoundariesType(int, Enum):
    City = 0
    District = 1
    Ward = 2

class VietmapBoundaries(BaseModel):
    """
    Administrative boundary information (city, district, or ward).
    
    Attributes:
        Type: Boundary type (City=0, District=1, Ward=2)
        Id: Boundary ID
        FullName: Full name of the boundary
    """
    model_config = ConfigDict(extra="ignore")
    
    Type: VietmapBoundariesType = Field(default=VietmapBoundariesType.City, validation_alias="type")
    Id: int = Field(default=0, validation_alias="id")
    FullName: str = Field(default='', validation_alias="full_name")
    
class VietmapEntryPoint(BaseModel):
    model_config = ConfigDict(extra="ignore")

    ReferenceId: str = Field(default='', validation_alias="ref_id")
    Name: str = Field(default='', validation_alias="name")
    
class VietmapGeocodingResponseModel(BaseModel):
    """
    Geocoding result from Search, Autocomplete, or Reverse operations.
    
    Attributes:
        ReferenceId: Unique reference ID for the place (use with Place method)
        Distance: Distance from query point in kilometers
        Address: Full address string
        Name: Place name
        Display: Display name
        Boundaries: List of administrative boundaries (city, district, ward)
        Categories: List of place categories
        EntryPoints: List of entry points for the location
    """
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
    """
    Detailed place information from Place method.
    
    Attributes:
        Display: Display name
        Name: Place name
        HouseNumber: House or building number
        Street: Street name
        Address: Full address
        CityId: City ID
        CityName: City name
        DistrictId: District ID
        DistrictName: District name
        WardId: Ward ID
        WardName: Ward name
        Latitude: Geographic latitude
        Longitude: Geographic longitude
    """
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
VietmapAutocompleteResponse = List[VietmapGeocodingResponseModel]

class VietmapRouteInstructionSign(int, Enum):
    UTurn = -98
    LeftUTurn = -8
    KeepLeft = -7
    TurnSharpLeft = -3
    TurnLeft = -2
    TurnSlightLeft = -1
    ContinueOnStreet = 0
    TurnSlightRight = 1
    TurnRight = 2
    TurnSharpRight = 3
    KeepRight = 7
    RightUTurn = 8
    Unknown = 32767
    
    @staticmethod
    def FromInteger(val: int) -> "VietmapRouteInstructionSign":
        try:
            return VietmapRouteInstructionSign(val)
        except Exception:
            return VietmapRouteInstructionSign.Unknown
        
class VietmapRouteStatusCode(str, Enum):
    Unknown = ""
    Ok = "OK"
    InvalidRequest = "INVALID_REQUEST"
    OverDailyLimit = "OVER_DAILY_LIMIT"
    MaxPointsExceed = "MAX_POINTS_EXCEED"
    ErrorUnknown = "ERROR_UNKNOWN"
    ZeroResults = "ZERO_RESULTS"

    @staticmethod
    def FromString(val: str) -> "VietmapRouteStatusCode":
        try:
            return VietmapRouteStatusCode(val)
        except Exception:
            return VietmapRouteStatusCode.Unknown

class VietmapRouteInstructionModel(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    Distance: float = Field(default=0, validation_alias="distance")
    Heading: int = Field(default=0, validation_alias="heading")
    InstructionSign: VietmapRouteInstructionSign = Field(default=VietmapRouteInstructionSign.Unknown, validation_alias="sign")
    Interval: Tuple[int, int] = Field(default=(0, 0), validation_alias="interval")
    InstructionText: str = Field(default="", validation_alias="text")
    TimeMs: int = Field(default=0, validation_alias="time")
    StreetName: str = Field(default="", validation_alias="street_name")

    @field_validator("InstructionSign", mode="before")
    @classmethod
    def __sign_validate(cls, v):
        return VietmapRouteInstructionSign.FromInteger(int(v))

class VietmapRoutePathModel(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    Distance: float = Field(default=0, validation_alias="distance")
    Weight: float = Field(default=0, validation_alias="weight")
    TimeMs: int = Field(default=0, validation_alias="time")
    Transfers: int = Field(default=0, validation_alias="transfers")
    BoundingBox: Tuple[float, float, float, float] = Field(default=(0, 0, 0, 0), validation_alias="bbox")
    Points: List[Tuple[float, float]] = Field(default_factory=list, validation_alias="points")
    Instructions: List[VietmapRouteInstructionModel] = Field(default_factory=list, validation_alias="instructions")

class VietmapRouteResult(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    License: str = Field(default="", validation_alias="license")
    Code: VietmapRouteStatusCode = Field(default=VietmapRouteStatusCode.Unknown, validation_alias="code")
    Messages: Optional[str] = Field(default=None, validation_alias="messages")
    Paths: List[VietmapRoutePathModel] = Field(default_factory=list, validation_alias="paths")
    
    @field_validator("Code", mode="before")
    @classmethod
    def __code_validate(cls, v):
        return VietmapRouteStatusCode.FromString(str(v))