from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class OpenWeatherCoordModel(BaseModel):
	model_config = ConfigDict(extra="ignore")

	Lon: float = Field(default=0.0, validation_alias="lon")
	Lat: float = Field(default=0.0, validation_alias="lat")


class OpenWeatherWeatherItemModel(BaseModel):
	model_config = ConfigDict(extra="ignore")

	Id: int = Field(default=0, validation_alias="id")
	Main: str = Field(default="", validation_alias="main")
	Description: str = Field(default="", validation_alias="description")
	Icon: Optional[str] = Field(default=None, validation_alias="icon")


class OpenWeatherMainModel(BaseModel):
	model_config = ConfigDict(extra="ignore")

	Temp: float = Field(default=0.0, validation_alias="temp")
	FeelsLike: float = Field(default=0.0, validation_alias="feels_like")
	TempMin: float = Field(default=0.0, validation_alias="temp_min")
	TempMax: float = Field(default=0.0, validation_alias="temp_max")


class OpenWeatherWindModel(BaseModel):
	model_config = ConfigDict(extra="ignore")

	Speed: float = Field(default=0.0, validation_alias="speed")
	Deg: Optional[int] = Field(default=None, validation_alias="deg")
	Gust: Optional[float] = Field(default=None, validation_alias="gust")


class OpenWeatherWeatherResponseModel(BaseModel):
	"""Subset of OpenWeather current weather response we actually use."""

	model_config = ConfigDict(extra="ignore")

	Coord: OpenWeatherCoordModel = Field(default_factory=OpenWeatherCoordModel, validation_alias="coord")
	Weather: List[OpenWeatherWeatherItemModel] = Field(default_factory=list, validation_alias="weather")
	Main: OpenWeatherMainModel = Field(default_factory=OpenWeatherMainModel, validation_alias="main")
	Wind: OpenWeatherWindModel = Field(default_factory=OpenWeatherWindModel, validation_alias="wind")
	Name: str = Field(default="", validation_alias="name")

