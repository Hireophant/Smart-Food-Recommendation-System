from typing import Optional
from core.serp.handlers import SerpHandler
from core.serp.extractors import SerpExtractor


class SerpStaticHandler:
    """
    Static wrapper for SERP search operations.
    """
    
    _handler: Optional[SerpHandler] = None
    
    @classmethod
    async def initialize(cls):
        """Initialize the SERP handler."""
        cls._handler = SerpHandler()
    
    @classmethod
    async def search_food(cls, query: str) -> dict:
        """
        Search for food-related results.
        Returns raw SERP API response.
        """
        if cls._handler is None:
            await cls.initialize()
        
        assert cls._handler is not None
        response = await cls._handler.search(query)
        return response
    
    @classmethod
    async def search_food_snippets(cls, query: str) -> list:
        """
        Search and extract food-related snippets.
        Returns list of food snippets from results.
        """
        response = await cls.search_food(query)
        snippets = SerpExtractor.extract_snippets(response)
        return snippets
