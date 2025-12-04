"""Restaurant data models."""

from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class GeoLocation(BaseModel):
    """GeoJSON Point format for MongoDB geospatial queries."""
    type: str = Field(default="Point", description="GeoJSON type")
    coordinates: List[float] = Field(description="[longitude, latitude]")
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "type": "Point",
            "coordinates": [105.8391546, 21.042939]
        }
    })


class RestaurantCreate(BaseModel):
    """Schema for creating a new restaurant."""
    name: str = Field(description="Restaurant name")
    category: str = Field(description="Restaurant category (e.g., Cafe, Restaurant)")
    address: str = Field(description="Street address")
    latitude: float = Field(description="Latitude coordinate", ge=-90, le=90)
    longitude: float = Field(description="Longitude coordinate", ge=-180, le=180)
    rating: Optional[float] = Field(default=None, description="Rating (0-5)", ge=0, le=5)
    google_maps_link: Optional[str] = Field(default=None, description="Google Maps URL")
    district: Optional[str] = Field(default=None, description="District")
    province: Optional[str] = Field(default=None, description="Province/City")
    full_location: Optional[str] = Field(default=None, description="Full location string")
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "name": "THAIYEN CAFE Quán Thánh",
            "category": "Cafe",
            "address": "Quận Ba Đình, Thành phố Hà Nội",
            "latitude": 21.042939,
            "longitude": 105.8391546,
            "rating": 4.7,
            "district": "Quận Ba Đình",
            "province": "Thành phố Hà Nội"
        }
    })


class RestaurantInDB(RestaurantCreate):
    """Restaurant model as stored in MongoDB."""
    id: Optional[str] = Field(default=None, alias="_id", description="MongoDB ObjectId")
    location: GeoLocation = Field(description="GeoJSON location for geospatial queries")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "_id": "507f1f77bcf86cd799439011",
                "name": "THAIYEN CAFE Quán Thánh",
                "category": "Cafe",
                "address": "Quận Ba Đình, Thành phố Hà Nội",
                "latitude": 21.042939,
                "longitude": 105.8391546,
                "location": {
                    "type": "Point",
                    "coordinates": [105.8391546, 21.042939]
                },
                "rating": 4.7,
                "district": "Quận Ba Đình",
                "province": "Thành phố Hà Nội",
                "created_at": "2025-12-04T00:00:00Z",
                "updated_at": "2025-12-04T00:00:00Z"
            }
        }
    )


class Restaurant(BaseModel):
    """Restaurant model for API responses."""
    id: str = Field(description="Restaurant ID")
    name: str = Field(description="Restaurant name")
    category: str = Field(description="Restaurant category")
    address: str = Field(description="Street address")
    latitude: float = Field(description="Latitude")
    longitude: float = Field(description="Longitude")
    rating: Optional[float] = Field(default=None, description="Rating (0-5)")
    google_maps_link: Optional[str] = Field(default=None, description="Google Maps URL")
    district: Optional[str] = Field(default=None, description="District")
    province: Optional[str] = Field(default=None, description="Province/City")
    full_location: Optional[str] = Field(default=None, description="Full location")
    distance: Optional[float] = Field(default=None, description="Distance from user (km)")
    
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "id": "507f1f77bcf86cd799439011",
                "name": "THAIYEN CAFE Quán Thánh",
                "category": "Cafe",
                "address": "Quận Ba Đình, Thành phố Hà Nội",
                "latitude": 21.042939,
                "longitude": 105.8391546,
                "rating": 4.7,
                "district": "Quận Ba Đình",
                "province": "Thành phố Hà Nội",
                "distance": 1.5
            }
        }
    )
