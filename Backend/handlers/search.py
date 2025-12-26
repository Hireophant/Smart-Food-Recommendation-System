from typing import Optional

from core.serp.search import SerpClient
from schemas.search import (
    SearchLocationModel,
    SearchOrganicResultModel,
    SearchResponseModel,
    SearchResultFormattedModel,
)


class SearchHandler:
    """Handlers for SERP search operations (static handlers)."""

    _MAX_LIMIT = 5

    @staticmethod
    def __cap_limit(limit: Optional[int]) -> int:
        if limit is None:
            return SearchHandler._MAX_LIMIT
        if limit <= 0:
            return 0
        return min(limit, SearchHandler._MAX_LIMIT)

    @staticmethod
    async def Search(
        query: str,
        location: str = "Vietnam",
        max_locations: Optional[int] = None,
        max_results: Optional[int] = None,
    ) -> SearchResponseModel:
        max_locations_c = SearchHandler.__cap_limit(max_locations)
        max_results_c = SearchHandler.__cap_limit(max_results)

        client = SerpClient()
        data = await client.Search(
            query=query,
            location=location,
            max_locations=max_locations_c,
            max_results=max_results_c,
        )

        return SearchResponseModel(
            Query=data.query,
            Location=data.location,
            Locations=[
                SearchLocationModel(
                    Name=loc.name,
                    Address=loc.address,
                    Type=loc.place_type,
                    Description=loc.description,
                    Rating=loc.rating,
                    Reviews=loc.reviews,
                    Price=loc.price,
                    Latitude=loc.latitude,
                    Longitude=loc.longitude,
                    PlaceId=loc.place_id,
                    PlaceIdSearch=loc.place_id_search,
                    Url=loc.url,
                )
                for loc in data.locations
            ],
            OrganicResults=[
                SearchOrganicResultModel(
                    Title=o.title,
                    Snippet=o.snippet,
                    Link=o.link,
                    Source=o.source,
                )
                for o in data.organic_results
            ],
        )

    @staticmethod
    async def SearchFormatted(
        query: str,
        location: str = "Vietnam",
        max_locations: Optional[int] = None,
        max_results: Optional[int] = None,
    ) -> SearchResultFormattedModel:
        max_locations_c = SearchHandler.__cap_limit(max_locations)
        max_results_c = SearchHandler.__cap_limit(max_results)

        client = SerpClient()
        formatted = await client.SearchFormatted(
            query=query,
            location=location,
            max_locations=max_locations_c,
            max_results=max_results_c,
        )
        return SearchResultFormattedModel(result=formatted)
