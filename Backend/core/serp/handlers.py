import os
import aiohttp
from utils import Logger


class SerpHandler:
    """
    CORE SERP handler:
    - Gọi SERP API thật
    - Không mock
    - Nếu thiếu key hoặc API lỗi → raise Exception
    """

    async def search(self, query: str) -> dict:
        api_key = os.getenv("SERPAPI_KEY")
        if not api_key:
            raise RuntimeError("SERPAPI_KEY is not set.")

        url = "https://serpapi.com/search.json"
        params = {
            "q": query,
            "hl": "vi",
            "num": 10,
            "api_key": api_key
        }

        async with aiohttp.ClientSession() as session:
            async with session.get(url, params=params) as resp:
                if resp.status != 200:
                    raise RuntimeError(f"SerpAPI error: {resp.status}")
                return await resp.json()
