from __future__ import annotations

from core.openweatherapi import OpenWeatherClient
from schemas.weather import WeatherResponseModel, WeatherInfoFormattedModel, format_weather_vietnamese


class WeatherHandler:
    """Handlers for weather operations (static handlers)."""

    @staticmethod
    async def Weather(lat: float, lon: float) -> WeatherResponseModel:
        async with OpenWeatherClient() as client:
            result = await client.Weather(lat=lat, lon=lon)
            if result is None:
                # Core client only returns None on empty json, keep as internal failure.
                raise RuntimeError("Failed to query OpenWeather API")
            return WeatherResponseModel.FromOpenWeather(result)

    @staticmethod
    async def WeatherFormatted(lat: float, lon: float) -> WeatherInfoFormattedModel:
        data = await WeatherHandler.Weather(lat=lat, lon=lon)
        return WeatherInfoFormattedModel(result=format_weather_vietnamese(data))
