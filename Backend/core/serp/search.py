import os
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

from serpapi.google_search import GoogleSearch
from starlette.concurrency import run_in_threadpool


SERP_API_KEY_ENVIRONMENT_NAME = "SERP_API_KEY"


@dataclass(frozen=True)
class SerpLocationItem:
    name: str
    address: Optional[str] = None
    place_type: Optional[str] = None
    description: Optional[str] = None
    rating: Optional[float] = None
    reviews: Optional[int] = None
    price: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    place_id: Optional[str] = None
    place_id_search: Optional[str] = None
    url: Optional[str] = None


@dataclass(frozen=True)
class SerpOrganicItem:
    title: str
    snippet: Optional[str] = None
    link: Optional[str] = None
    source: Optional[str] = None


@dataclass(frozen=True)
class SerpSearchData:
    query: str
    location: str
    locations: List[SerpLocationItem]
    organic_results: List[SerpOrganicItem]
    raw: Dict[str, Any]


class SerpClient:
    """Client for SERP API (SerpApi) Google search.

    - API key is loaded from environment variable `SERP_API_KEY`.
    - Returns Vietnamese formatted output for end users.
    """

    def __init__(self) -> None:
        api_key = os.getenv(SERP_API_KEY_ENVIRONMENT_NAME)
        if not api_key:
            raise EnvironmentError(
                f"Thiếu API key cho SERP. Hãy đặt biến môi trường {SERP_API_KEY_ENVIRONMENT_NAME}."
            )
        self._api_key = api_key

    def _google_search(self, query: str, location: str) -> Dict[str, Any]:
        params: Dict[str, Any] = {
            "engine": "google",
            "q": query,
            "location": location,
            "hl": "vi",
            "gl": "vn",
            "google_domain": "google.com",
            "api_key": self._api_key,
        }
        search = GoogleSearch(params)
        return search.get_dict()

    @staticmethod
    def _apply_limit(items: List[Any], max_items: Optional[int]) -> List[Any]:
        if max_items is None:
            return items
        if max_items <= 0:
            return []
        return items[:max_items]

    @staticmethod
    def _extract_places(response: Dict[str, Any]) -> List[SerpLocationItem]:
        local_results = response.get("local_results")
        places_raw: List[Dict[str, Any]] = []

        # Newer SERP format (as in your sample): { local_results: { places: [...] } }
        if isinstance(local_results, dict):
            raw = local_results.get("places")
            if isinstance(raw, list):
                places_raw = [p for p in raw if isinstance(p, dict)]
        # Older/other formats sometimes return list directly
        elif isinstance(local_results, list):
            places_raw = [p for p in local_results if isinstance(p, dict)]

        places: List[SerpLocationItem] = []
        for item in places_raw:
            title = item.get("title")
            if not title:
                continue

            gps = item.get("gps_coordinates") if isinstance(item.get("gps_coordinates"), dict) else {}
            lat = gps.get("latitude") if isinstance(gps, dict) else None
            lng = gps.get("longitude") if isinstance(gps, dict) else None

            places.append(
                SerpLocationItem(
                    name=str(title),
                    address=item.get("address"),
                    place_type=item.get("type"),
                    description=item.get("description"),
                    rating=item.get("rating"),
                    reviews=item.get("reviews"),
                    price=item.get("price"),
                    latitude=lat,
                    longitude=lng,
                    place_id=item.get("place_id"),
                    place_id_search=item.get("place_id_search"),
                    url=item.get("website") or item.get("link") or item.get("place_id_search"),
                )
            )

        return places

    @staticmethod
    def _extract_organic_results(response: Dict[str, Any]) -> List[SerpOrganicItem]:
        organic: List[SerpOrganicItem] = []
        raw_list = response.get("organic_results")
        if not isinstance(raw_list, list):
            return organic

        for item in raw_list:
            if not isinstance(item, dict):
                continue
            title = item.get("title")
            if not title:
                continue

            raw_snippet = item.get("snippet")
            if raw_snippet is None:
                raw_snippet = item.get("snippet_highlighted_words")

            snippet: Optional[str]
            if isinstance(raw_snippet, list):
                snippet = "; ".join(str(s) for s in raw_snippet if s)
            else:
                snippet = None if raw_snippet is None else str(raw_snippet)

            organic.append(
                SerpOrganicItem(
                    title=str(title),
                    snippet=snippet,
                    link=item.get("link"),
                    source=item.get("source"),
                )
            )

        return organic

    def SearchSync(self, query: str,
                   location: str = "Vietnam",
                   max_locations: Optional[int] = 5,
                   max_results: Optional[int] = 5) -> SerpSearchData:
        response = self._google_search(query=query, location=location)

        locations = self._apply_limit(self._extract_places(response), max_locations)
        organic = self._apply_limit(self._extract_organic_results(response), max_results)

        return SerpSearchData(
            query=query,
            location=location,
            locations=locations,
            organic_results=organic,
            raw=response,
        )

    async def Search(self, query: str,
                     location: str = "Vietnam",
                     max_locations: Optional[int] = 5,
                     max_results: Optional[int] = 5) -> SerpSearchData:
        return await run_in_threadpool(
            lambda: self.SearchSync(
                query=query,
                location=location,
                max_locations=max_locations,
                max_results=max_results,
            )
        )

    def SearchFormattedSync(self, query: str,
                            location: str = "Vietnam",
                            max_locations: Optional[int] = 5,
                            max_results: Optional[int] = 5) -> str:
        data = self.SearchSync(
            query=query,
            location=location,
            max_locations=max_locations,
            max_results=max_results,
        )
        return format_serp_vietnamese(data)

    async def SearchFormatted(self, query: str,
                              location: str = "Vietnam",
                              max_locations: Optional[int] = 5,
                              max_results: Optional[int] = 5) -> str:
        return await run_in_threadpool(
            lambda: self.SearchFormattedSync(
                query=query,
                location=location,
                max_locations=max_locations,
                max_results=max_results,
            )
        )


def _fmt_rating(rating: Optional[float], reviews: Optional[int]) -> Optional[str]:
    if rating is None:
        return None
    if reviews is None:
        return f"⭐ {rating}"
    return f"⭐ {rating} ({reviews} đánh giá)"


def format_serp_vietnamese(
    data: SerpSearchData,
) -> str:
    lines: List[str] = []
    lines.append(f"Kết quả tìm kiếm cho: \"{data.query}\"")
    lines.append(f"Khu vực: {data.location}")

    locations = data.locations
    if locations:
        lines.append("")
        lines.append("Địa điểm gợi ý:")
        for idx, loc in enumerate(locations, start=1):
            parts: List[str] = []
            if loc.address:
                parts.append(loc.address)
            if loc.place_type:
                parts.append(str(loc.place_type))
            rating_s = _fmt_rating(loc.rating, loc.reviews)
            if rating_s:
                parts.append(rating_s)
            if loc.price:
                parts.append(f"Giá: {loc.price}")
            if loc.description:
                parts.append(str(loc.description))

            suffix = f" — {' | '.join(parts)}" if parts else ""
            lines.append(f"{idx}. {loc.name}{suffix}")
    else:
        lines.append("")
        lines.append("Địa điểm gợi ý: (không tìm thấy)")

    results = data.organic_results
    if results:
        lines.append("")
        lines.append("Nội dung tìm thấy:")
        for idx, item in enumerate(results, start=1):
            title_line = item.title
            if item.source:
                title_line = f"{title_line} ({item.source})"
            lines.append(f"{idx}. {title_line}")
            if item.snippet:
                lines.append(f"   {item.snippet}")
            if item.link:
                lines.append(f"   {item.link}")
    else:
        lines.append("")
        lines.append("Nội dung tìm thấy: (không có kết quả phù hợp)")

    return "\n".join(lines).strip() + "\n"


# Backward-compat shim (old function name). Returns a small list of dicts.
def search_food_from_query(query: str, location: str = "Vietnam") -> List[Dict[str, Any]]:
    client = SerpClient()
    data = client.SearchSync(query=query, location=location, max_locations=5, max_results=5)
    results: List[Dict[str, Any]] = []

    for loc in data.locations:
        results.append(
            {
                "name": loc.name,
                "address": loc.address,
                "dish": query,
                "price_range": loc.price,
                "rating": loc.rating,
                "reviews": loc.reviews,
                "latitude": loc.latitude,
                "longitude": loc.longitude,
                "open_now": None,
                "source": "google",
                "url": loc.url,
            }
        )

    if not results:
        for item in data.organic_results:
            results.append(
                {
                    "name": item.title,
                    "address": None,
                    "dish": query,
                    "price_range": None,
                    "rating": None,
                    "reviews": None,
                    "latitude": None,
                    "longitude": None,
                    "open_now": None,
                    "source": item.source,
                    "url": item.link,
                }
            )

    return results
