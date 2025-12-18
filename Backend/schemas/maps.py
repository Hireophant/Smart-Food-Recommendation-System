from pydantic import ConfigDict, Field, BaseModel
from enum import Enum
from typing import List, Optional, Tuple
from core.vietmap import (
    VietmapBoundariesType,
    VietmapBoundaries,
    VietmapEntryPoint,
    VietmapGeocodingResponseModel,
    VietmapPlaceResponseModel,
    VietmapRouteResult,
    VietmapRoutePathModel,
    VietmapRouteInstructionModel,
    VietmapRouteInstructionSign,
    VietmapRouteStatusCode,
    VietmapRouteVehicleType,
    VietmapRouteAvoidType
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


class MapRouteOptions(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Vehicle: VietmapRouteVehicleType = Field(
        default=VietmapRouteVehicleType.Car,
        validation_alias="vehicle",
        serialization_alias="vehicle",
        description="Routing vehicle type (car, motorcycle, truck)"
    )
    Avoid: Optional[List[VietmapRouteAvoidType]] = Field(
        default=None,
        validation_alias="avoid",
        serialization_alias="avoid",
        description="Things to avoid (e.g. toll, ferry)"
    )


class MapRouteRequestModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Points: List[MapCoord] = Field(
        ...,
        min_length=2,
        max_length=15,
        validation_alias="points",
        serialization_alias="points",
        description="Route points (2..15). Each point is {lat, lon}."
    )
    Options: Optional[MapRouteOptions] = Field(
        default=None,
        validation_alias="options",
        serialization_alias="options",
        description="Route options"
    )


class MapRouteInstruction(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Distance: float = Field(default=0.0, serialization_alias="distance",
                            description="Instruction distance (meters, as returned by Vietmap)")
    Heading: int = Field(default=0, serialization_alias="heading",
                         description="Heading in degrees")
    InstructionSign: VietmapRouteInstructionSign = Field(
        default=VietmapRouteInstructionSign.Unknown,
        serialization_alias="sign",
        description="Turn/sign code"
    )
    Interval: Tuple[int, int] = Field(default=(0, 0), serialization_alias="interval",
                                      description="Polyline interval indices")
    InstructionText: str = Field(default="", serialization_alias="text",
                                 description="Human readable instruction")
    TimeMs: int = Field(default=0, serialization_alias="time",
                        description="Instruction duration in milliseconds")
    StreetName: str = Field(default="", serialization_alias="street_name",
                            description="Street name")

    @staticmethod
    def FromVietmap(inputs: VietmapRouteInstructionModel) -> "MapRouteInstruction":
        return MapRouteInstruction(
            Distance=inputs.Distance,
            Heading=inputs.Heading,
            InstructionSign=inputs.InstructionSign,
            Interval=inputs.Interval,
            InstructionText=inputs.InstructionText,
            TimeMs=inputs.TimeMs,
            StreetName=inputs.StreetName
        )


class MapRoutePath(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Distance: float = Field(default=0.0, serialization_alias="distance",
                            description="Path distance (meters, as returned by Vietmap)")
    Weight: float = Field(default=0.0, serialization_alias="weight",
                          description="Path weight (as returned by Vietmap)")
    TimeMs: int = Field(default=0, serialization_alias="time",
                        description="Path duration in milliseconds")
    Transfers: int = Field(default=0, serialization_alias="transfers",
                           description="Number of transfers (if applicable)")
    BoundingBox: Tuple[float, float, float, float] = Field(default=(0, 0, 0, 0), serialization_alias="bbox",
                                                           description="Bounding box")
    Points: List[Tuple[float, float]] = Field(default_factory=list, serialization_alias="points",
                                              description="Route geometry points")
    Instructions: List[MapRouteInstruction] = Field(default_factory=list, serialization_alias="instructions",
                                                    description="Turn-by-turn instructions")

    @staticmethod
    def FromVietmap(inputs: VietmapRoutePathModel) -> "MapRoutePath":
        return MapRoutePath(
            Distance=inputs.Distance,
            Weight=inputs.Weight,
            TimeMs=inputs.TimeMs,
            Transfers=inputs.Transfers,
            BoundingBox=inputs.BoundingBox,
            Points=list(inputs.Points),
            Instructions=[MapRouteInstruction.FromVietmap(i) for i in inputs.Instructions]
        )


class MapRouteResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    License: str = Field(default="", serialization_alias="license",
                         description="License string")
    Code: VietmapRouteStatusCode = Field(default=VietmapRouteStatusCode.Unknown, serialization_alias="code",
                                        description="Routing status code")
    Messages: Optional[str] = Field(default=None, serialization_alias="messages",
                                   description="Optional message")
    Paths: List[MapRoutePath] = Field(default_factory=list, serialization_alias="paths",
                                     description="Route paths")

    @staticmethod
    def FromVietmap(inputs: VietmapRouteResult) -> "MapRouteResponseModel":
        return MapRouteResponseModel(
            License=inputs.License,
            Code=inputs.Code,
            Messages=inputs.Messages,
            Paths=[MapRoutePath.FromVietmap(p) for p in inputs.Paths]
        )
