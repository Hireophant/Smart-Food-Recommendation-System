from __future__ import annotations

import os
from typing import Any, Dict, Optional, cast

import aiohttp
from fastapi import HTTPException, status

from utils import Logger
from core.openweatherapi.schemas import OpenWeatherWeatherResponseModel


OPENWEATHER_API_KEY_ENVIRONMENT_NAME = "OPENWEATHER_API_KEY"
OPENWEATHER_WEATHER_URL = "https://api.openweathermap.org/data/2.5/weather"


class OpenWeatherClient:
	"""Async client for OpenWeather current weather API.

	- API key is loaded from environment variable `OPENWEATHER_API_KEY`.
	- Requests are made with `units=metric`.

	Usage:
		async with OpenWeatherClient() as client:
			w = await client.Weather(lat=10.8, lon=106.6)
	"""

	def __init__(self) -> None:
		api_key = os.getenv(OPENWEATHER_API_KEY_ENVIRONMENT_NAME)
		if not api_key:
			raise EnvironmentError("No OpenWeather API key found in the environment variable!")
		self.__api_key = api_key
		self.__client = aiohttp.ClientSession()

	async def __sendRequestDict(self, url: str, params: Dict[str, Any]) -> Optional[Dict[str, Any]]:
		if self.__client.closed:
			raise HTTPException(
				status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
				detail="OpenWeather client session is closed!",
			)

		async with self.__client.get(url, params=params) as session:
			if session.status == status.HTTP_404_NOT_FOUND:
				raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
			if session.status == status.HTTP_401_UNAUTHORIZED:
				raise HTTPException(
					status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
					detail="Authorization failed for OpenWeather API (possibly wrong API key)",
				)
			if session.status == status.HTTP_429_TOO_MANY_REQUESTS:
				raise HTTPException(
					status_code=status.HTTP_429_TOO_MANY_REQUESTS,
					detail="OpenWeather API rate limit exceeded",
				)
			if not session.ok:
				try:
					text = await session.text()
				except Exception:
					text = ""
				Logger.LogError(
					f"OpenWeather API response with code '{session.status}', reason '{session.reason}', body '{text}'"
				)
				raise HTTPException(
					status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
					detail="Failed to query from OpenWeather API",
				)

			res = await session.json()
			return None if res is None else cast(Dict[str, Any], res)

	def __finalize_params(self, raw_params: Dict[str, Any]) -> None:
		raw_params.update({"appid": self.__api_key})
		raw_params.update({"units": "metric"})

	async def Weather(self, lat: float, lon: float) -> Optional[OpenWeatherWeatherResponseModel]:
		params: Dict[str, Any] = {"lat": lat, "lon": lon}
		self.__finalize_params(params)

		res = await self.__sendRequestDict(OPENWEATHER_WEATHER_URL, params=params)
		return None if res is None else OpenWeatherWeatherResponseModel(**res)

	async def Close(self) -> None:
		await self.__client.close()

	async def __aenter__(self):
		await self.__client.__aenter__()
		return self

	async def __aexit__(self, exc_type, exc, tb):
		await self.__client.__aexit__(exc_type, exc, tb)

