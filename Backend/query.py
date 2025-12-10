import httpx
from fastapi import APIRouter, Query

router = APIRouter(prefix="/query", tags=["Query System"])

class QuerySystem:
    BASE_URL = "https://maps.vietmap.vn/api"

    def __init__(self, api_key: str):
        self.api_key = api_key

    async def geocode(self, address: str):
        async with httpx.AsyncClient() as client:
            res = await client.get(
                f"{self.BASE_URL}/search",
                params={"apikey": self.api_key, "text": address}
            )
        res.raise_for_status()
        return res.json()

    async def reverse_geocode(self, lat: float, lng: float):
        async with httpx.AsyncClient() as client:
            res = await client.get(
                f"{self.BASE_URL}/reverse",
                params={"apikey": self.api_key, "lat": lat, "lng": lng}
            )
        res.raise_for_status()
        return res.json()
