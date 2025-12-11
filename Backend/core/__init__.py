# Core module for Smart Food Recommendation System

from pydantic import BaseModel, Field, ConfigDict


class MapCoordinate(BaseModel):
    """Represents a geographic coordinate (latitude, longitude)."""
    model_config = ConfigDict(extra="ignore")
    
    Latitude: float = Field(description="Latitude coordinate", ge=-90, le=90)
    Longitude: float = Field(description="Longitude coordinate", ge=-180, le=180)
    
    def __str__(self) -> str:
        return f"{self.Latitude},{self.Longitude}"
