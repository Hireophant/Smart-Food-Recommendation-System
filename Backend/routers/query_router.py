"""Query System Router - API endpoints for restaurant queries."""

from fastapi import APIRouter, Query as QueryParam, HTTPException, status
from typing import Optional, Dict
from core.query_handler import QuerySystemHandler, QueryFilter, QueryResult


router = APIRouter(prefix="/api/query", tags=["Query System"])
query_handler = QuerySystemHandler()


@router.get("/search/name", response_model=QueryResult)
async def search_by_name(
    q: str = QueryParam(..., min_length=1, description="Search term"),
    category: Optional[str] = QueryParam(None, description="Filter by category"),
    min_rating: Optional[float] = QueryParam(None, ge=0, le=5, description="Minimum rating"),
    max_rating: Optional[float] = QueryParam(None, ge=0, le=5, description="Maximum rating"),
    district: Optional[str] = QueryParam(None, description="Filter by district"),
    province: Optional[str] = QueryParam(None, description="Filter by province"),
    limit: int = QueryParam(10, ge=1, le=100, description="Results limit"),
    skip: int = QueryParam(0, ge=0, description="Results offset")
):
    """
    Search restaurants by name with optional filters.
    
    Example: `/api/query/search/name?q=Cafe&category=Cafe&limit=10`
    """
    filters = QueryFilter(
        category=category,
        min_rating=min_rating,
        max_rating=max_rating,
        district=district,
        province=province,
        limit=limit,
        skip=skip
    )
    
    result = await query_handler.search_by_name(q, filters)
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.error
        )
    
    return result


@router.get("/search/category", response_model=QueryResult)
async def search_by_category(
    category: str = QueryParam(..., min_length=1, description="Category to search"),
    min_rating: Optional[float] = QueryParam(None, ge=0, le=5, description="Minimum rating"),
    max_rating: Optional[float] = QueryParam(None, ge=0, le=5, description="Maximum rating"),
    limit: int = QueryParam(10, ge=1, le=100, description="Results limit"),
    skip: int = QueryParam(0, ge=0, description="Results offset")
):
    """
    Search restaurants by category.
    
    Example: `/api/query/search/category?category=Cafe&limit=20`
    """
    filters = QueryFilter(
        min_rating=min_rating,
        max_rating=max_rating,
        limit=limit,
        skip=skip
    )
    
    result = await query_handler.search_by_category(category, filters)
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.error
        )
    
    return result


@router.get("/search/location", response_model=QueryResult)
async def search_by_location(
    latitude: float = QueryParam(..., ge=-90, le=90, description="Latitude"),
    longitude: float = QueryParam(..., ge=-180, le=180, description="Longitude"),
    max_distance: float = QueryParam(5000, ge=100, description="Max distance in meters"),
    category: Optional[str] = QueryParam(None, description="Filter by category"),
    min_rating: Optional[float] = QueryParam(None, ge=0, le=5, description="Minimum rating"),
    max_rating: Optional[float] = QueryParam(None, ge=0, le=5, description="Maximum rating"),
    limit: int = QueryParam(10, ge=1, le=100, description="Results limit"),
    skip: int = QueryParam(0, ge=0, description="Results offset")
):
    """
    Search restaurants by location (geospatial query).
    
    Example: `/api/query/search/location?latitude=21.0285&longitude=105.8542&max_distance=3000`
    """
    filters = QueryFilter(
        category=category,
        min_rating=min_rating,
        max_rating=max_rating,
        max_distance=max_distance,
        limit=limit,
        skip=skip
    )
    
    result = await query_handler.search_by_location(latitude, longitude, max_distance, filters)
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.error
        )
    
    return result


@router.get("/search/rating", response_model=QueryResult)
async def search_by_rating(
    min_rating: float = QueryParam(0, ge=0, le=5, description="Minimum rating"),
    max_rating: float = QueryParam(5, ge=0, le=5, description="Maximum rating"),
    category: Optional[str] = QueryParam(None, description="Filter by category"),
    district: Optional[str] = QueryParam(None, description="Filter by district"),
    province: Optional[str] = QueryParam(None, description="Filter by province"),
    limit: int = QueryParam(10, ge=1, le=100, description="Results limit"),
    skip: int = QueryParam(0, ge=0, description="Results offset")
):
    """
    Search restaurants by rating range.
    
    Example: `/api/query/search/rating?min_rating=4.0&max_rating=5.0&limit=15`
    """
    filters = QueryFilter(
        category=category,
        district=district,
        province=province,
        limit=limit,
        skip=skip
    )
    
    result = await query_handler.search_by_rating(min_rating, max_rating, filters)
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.error
        )
    
    return result


@router.get("/search/combined", response_model=QueryResult)
async def combined_search(
    q: Optional[str] = QueryParam(None, description="Search term"),
    latitude: Optional[float] = QueryParam(None, ge=-90, le=90, description="Latitude"),
    longitude: Optional[float] = QueryParam(None, ge=-180, le=180, description="Longitude"),
    max_distance: Optional[float] = QueryParam(None, ge=100, description="Max distance in meters"),
    category: Optional[str] = QueryParam(None, description="Filter by category"),
    min_rating: Optional[float] = QueryParam(None, ge=0, le=5, description="Minimum rating"),
    max_rating: Optional[float] = QueryParam(None, ge=0, le=5, description="Maximum rating"),
    district: Optional[str] = QueryParam(None, description="Filter by district"),
    province: Optional[str] = QueryParam(None, description="Filter by province"),
    limit: int = QueryParam(10, ge=1, le=100, description="Results limit"),
    skip: int = QueryParam(0, ge=0, description="Results offset")
):
    """
    Combined search with name, location, and filters.
    
    Example: `/api/query/search/combined?q=Cafe&latitude=21.0285&longitude=105.8542&max_distance=5000&category=Cafe&min_rating=4.0`
    """
    filters = QueryFilter(
        category=category,
        min_rating=min_rating,
        max_rating=max_rating,
        district=district,
        province=province,
        max_distance=max_distance,
        limit=limit,
        skip=skip
    )
    
    location = None
    if latitude is not None and longitude is not None:
        location = {"latitude": latitude, "longitude": longitude}
    
    result = await query_handler.combined_search(q, location, filters)
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.error
        )
    
    return result


@router.get("/restaurant/{restaurant_id}", response_model=QueryResult)
async def get_restaurant_by_id(restaurant_id: str):
    """
    Get restaurant details by ID.
    
    Example: `/api/query/restaurant/507f1f77bcf86cd799439011`
    """
    result = await query_handler.get_restaurant_by_id(restaurant_id)
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=result.error
        )
    
    return result


@router.get("/categories", response_model=QueryResult)
async def get_all_categories():
    """
    Get all available restaurant categories.
    
    Example: `/api/query/categories`
    """
    result = await query_handler.get_all_categories()
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=result.error
        )
    
    return result


@router.get("/statistics", response_model=QueryResult)
async def get_statistics():
    """
    Get restaurant database statistics.
    
    Example: `/api/query/statistics`
    """
    result = await query_handler.get_statistics()
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=result.error
        )
    
    return result
