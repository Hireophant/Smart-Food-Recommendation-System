from pydantic import Field, BaseModel, ConfigDict
from typing import Annotated

class MapCoordinate(BaseModel):
    model_config = ConfigDict(extra='ignore')
    
    Latitude: float = Field(ge=-90, le=90)
    Longitude: float = Field(ge=-180, le=180)
