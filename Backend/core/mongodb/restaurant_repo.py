import asyncio
from typing import List, Dict, Any

from core.mongodb.connection import MongoDB
from core.mongodb.handlers import MongoDBHandlers, MongoDBSearchInputSchema


def search_restaurants_in_db(
    query: str,
    latitude: float,
    longitude: float,
    radius_km: float = 5.0,
    limit: int = 10
) -> List[Dict[str, Any]]:
    """
    SYNC wrapper for async MongoDB restaurant search.
    Used by AI tools.
    """

    async def _search():
        db = MongoDB.get_database()
        handler = MongoDBHandlers(db)

        inputs = MongoDBSearchInputSchema(
            Text=query,
            Latitude=latitude,
            Longitude=longitude,
            Radius=radius_km * 1000,
            Limit=limit
        )

        result = await handler.Search(inputs)

        if not result.success:
            return []

        # Convert to plain dict (AI-friendly)
        return [r.model_dump() for r in result.restaurants]

    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

    return loop.run_until_complete(_search())
