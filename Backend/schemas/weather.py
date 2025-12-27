from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from core.openweatherapi import OpenWeatherWeatherResponseModel


class WeatherCoord(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Latitude: float = Field(default=0.0, serialization_alias="lat", description="Latitude")
    Longitude: float = Field(default=0.0, serialization_alias="lon", description="Longitude")


class WeatherTemperature(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Current: float = Field(default=0.0, serialization_alias="current_c", description="Current temperature in Celsius")
    FeelsLike: float = Field(default=0.0, serialization_alias="feels_like_c", description="Feels-like temperature in Celsius")
    Min: float = Field(default=0.0, serialization_alias="min_c", description="Min temperature in Celsius")
    Max: float = Field(default=0.0, serialization_alias="max_c", description="Max temperature in Celsius")


class WeatherWind(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Speed: float = Field(default=0.0, serialization_alias="speed_ms", description="Wind speed in meters/sec")
    DirectionDeg: Optional[int] = Field(
        default=None,
        serialization_alias="direction_deg",
        description="Wind direction in degrees (meteorological)",
    )
    Gust: Optional[float] = Field(default=None, serialization_alias="gust_ms", description="Wind gust in meters/sec")


class WeatherResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Coord: WeatherCoord = Field(default_factory=WeatherCoord, serialization_alias="coord")
    Temperature: WeatherTemperature = Field(default_factory=WeatherTemperature, serialization_alias="temperature")
    Wind: WeatherWind = Field(default_factory=WeatherWind, serialization_alias="wind")
    WeatherCondition: str = Field(default="", serialization_alias="weather_condition", description="Formatted weather condition string")
    Name: str = Field(default="", serialization_alias="name", description="City/place name")

    @staticmethod
    def FromOpenWeather(inputs: OpenWeatherWeatherResponseModel) -> "WeatherResponseModel":
        w = inputs.Weather[0] if inputs.Weather else None
        parts = []
        if w is not None:
            if w.Main:
                parts.append(w.Main)
            if w.Description and w.Description != w.Main:
                parts.append(w.Description)

        condition = " - ".join(parts).strip()

        return WeatherResponseModel(
            Coord=WeatherCoord(Latitude=inputs.Coord.Lat, Longitude=inputs.Coord.Lon),
            Temperature=WeatherTemperature(
                Current=inputs.Main.Temp,
                FeelsLike=inputs.Main.FeelsLike,
                Min=inputs.Main.TempMin,
                Max=inputs.Main.TempMax,
            ),
            Wind=WeatherWind(
                Speed=inputs.Wind.Speed,
                DirectionDeg=inputs.Wind.Deg,
                Gust=inputs.Wind.Gust,
            ),
            WeatherCondition=condition,
            Name=inputs.Name,
        )


class WeatherInfoFormattedModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    # Required by spec: a single variable named `result`.
    result: str = Field(default="", description="Formatted weather info string")


def format_weather_vietnamese(data: WeatherResponseModel) -> str:
    # Keep it simple and stable for later feeding into AI.
    lines = []
    lines.append(f"Thời tiết hiện tại: {data.Name}" if data.Name else "Thời tiết hiện tại")
    lines.append(f"Tọa độ: {data.Coord.Latitude}, {data.Coord.Longitude}")
    lines.append(
        "Nhiệt độ: "
        f"{data.Temperature.Current:.1f}°C (cảm giác như {data.Temperature.FeelsLike:.1f}°C), "
        f"thấp nhất {data.Temperature.Min:.1f}°C, cao nhất {data.Temperature.Max:.1f}°C"
    )
    wind_parts = []
    wind_parts.append(f"{data.Wind.Speed:.1f} m/s")
    if data.Wind.DirectionDeg is not None:
        wind_parts.append(f"hướng {data.Wind.DirectionDeg}°")
    if data.Wind.Gust is not None:
        wind_parts.append(f"giật {data.Wind.Gust:.1f} m/s")
    lines.append("Gió: " + ", ".join(wind_parts))
    if data.WeatherCondition:
        lines.append(f"Điều kiện: {data.WeatherCondition}")
    return "\n".join(lines).strip() + "\n"
