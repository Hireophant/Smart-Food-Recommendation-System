"De dung dc ham nho: pip install google-search-results"
import os
from typing import List, Dict, Any
from serpapi import GoogleSearch


def search_food_from_query(query: str, location: str = "Ho Chi Minh City") -> List[Dict[str, Any]]:
    """
    Input:
        query: text mô tả nhu cầu ăn uống của người dùng
        location: khu vực tìm kiếm (default HCM)

    Output:
        List các quán ăn/món ăn đã được chuẩn hoá JSON cùng các thông tin cần thiết
    """

    api_key = os.getenv("SERPAPI_API_KEY")
    if not api_key:
        raise ValueError("Missing SERPAPI_API_KEY environment variable")

    params = {
        "engine": "google_maps",
        "q": query,
        "location": location,
        "hl": "vi",
        "api_key": api_key
    }

    search = GoogleSearch(params)
    response = search.get_dict()

    results: List[Dict[str, Any]] = []

    # Ưu tiên Google Maps local results
    for item in response.get("local_results", []):
        results.append({
            "name": item.get("title"),
            "address": item.get("address"),
            "dish": query,
            "price_range": item.get("price"),
            "rating": item.get("rating"),
            "reviews": item.get("reviews"),
            "latitude": item.get("gps_coordinates", {}).get("latitude"),
            "longitude": item.get("gps_coordinates", {}).get("longitude"),
            "open_now": item.get("open_state"),
            "source": "google_maps",
            "url": item.get("website") or item.get("link")
        })

    # Fallback nếu không có local_results
    if not results:
        for item in response.get("organic_results", []):
            results.append({
                "name": item.get("title"),
                "address": None,
                "dish": query,
                "price_range": None,
                "rating": None,
                "reviews": None,
                "latitude": None,
                "longitude": None,
                "open_now": None,
                "source": item.get("source"),
                "url": item.get("link")
            })

    return results
