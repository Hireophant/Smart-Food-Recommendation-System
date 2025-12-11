"""Vietmap API Router - Provides geocoding, search, and place services."""

from fastapi import APIRouter, Query, HTTPException, status
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from core.vietmap.handlers import VietmapHandlers, VietmapSearchInputSchema, VietmapAutocompleteInputSchema
from core.vietmap.schemas import (
    VietmapSearchResponse, 
    VietmapAutocompleteResponse,
    VietmapPlaceResponse,
    VietmapReverseResponse
)
from core import MapCoordinate
import os


router = APIRouter(prefix="/api/vietmap", tags=["Vietmap Services"])


# Request/Response Models for API
class SearchRequest(BaseModel):
    """Request model for Vietmap search."""
    model_config = ConfigDict(extra="ignore")
    
    text: str = Field(description="Search text (address, place name, etc.)")
    focus_lat: Optional[float] = Field(None, ge=-90, le=90, description="Focus point latitude")
    focus_lng: Optional[float] = Field(None, ge=-180, le=180, description="Focus point longitude")
    layers: Optional[str] = Field(None, description="Filter by layers (e.g., 'venue,address')")
    circle_center_lat: Optional[float] = Field(None, ge=-90, le=90, description="Circle search center latitude")
    circle_center_lng: Optional[float] = Field(None, ge=-180, le=180, description="Circle search center longitude")
    circle_radius: Optional[float] = Field(None, gt=0, description="Circle search radius in km")
    categories: Optional[str] = Field(None, description="Filter by categories")
    city_id: Optional[int] = Field(None, description="Filter by city ID")
    dist_id: Optional[int] = Field(None, description="Filter by district ID")
    ward_id: Optional[int] = Field(None, description="Filter by ward ID")


class AutocompleteRequest(BaseModel):
    """Request model for Vietmap autocomplete."""
    model_config = ConfigDict(extra="ignore")
    
    text: str = Field(description="Text to autocomplete")
    focus_lat: Optional[float] = Field(None, ge=-90, le=90, description="Focus point latitude")
    focus_lng: Optional[float] = Field(None, ge=-180, le=180, description="Focus point longitude")
    categories: Optional[str] = Field(None, description="Filter by categories")


class ReverseGeocodeRequest(BaseModel):
    """Request model for reverse geocoding."""
    model_config = ConfigDict(extra="ignore")
    
    latitude: float = Field(ge=-90, le=90, description="Latitude coordinate")
    longitude: float = Field(ge=-180, le=180, description="Longitude coordinate")


class VietmapErrorResponse(BaseModel):
    """Error response model."""
    success: bool = False
    error: str
    detail: Optional[str] = None


# Initialize Vietmap handler (will be created per request to avoid session issues)
def get_vietmap_handler() -> VietmapHandlers:
    """Create a new Vietmap handler instance."""
    try:
        return VietmapHandlers()
    except EnvironmentError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Vietmap configuration error: {str(e)}"
        )


@router.post("/search", response_model=VietmapSearchResponse)
async def search_location(request: SearchRequest):
    """
    Search for locations using Vietmap API.
    
    Supports various search parameters including:
    - Text search (address, place name, POI)
    - Focus point for relevance ranking
    - Circle-based geographic filtering
    - Administrative boundary filtering (city, district, ward)
    - Category filtering
    
    Example request:
    ```json
    {
        "text": "Cafe Hanoi",
        "focus_lat": 21.0285,
        "focus_lng": 105.8542,
        "categories": "cafe",
        "city_id": 1
    }
    ```
    """
    handler = get_vietmap_handler()
    
    try:
        # Build focus coordinate if provided
        focus = None
        if request.focus_lat is not None and request.focus_lng is not None:
            focus = MapCoordinate(Latitude=request.focus_lat, Longitude=request.focus_lng)
        
        # Build circle center if provided
        circle_center = None
        if request.circle_center_lat is not None and request.circle_center_lng is not None:
            circle_center = MapCoordinate(
                Latitude=request.circle_center_lat, 
                Longitude=request.circle_center_lng
            )
        
        # Create input schema
        search_input = VietmapSearchInputSchema(
            Text=request.text,
            Focus=focus,
            Layers=request.layers,
            CircleCenter=circle_center,
            CircleRadius=request.circle_radius,
            Categories=request.categories,
            CityId=request.city_id,
            DistId=request.dist_id,
            WardId=request.ward_id
        )
        
        # Execute search
        result = await handler.Search(search_input)
        
        if result is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No results found"
            )
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Search failed: {str(e)}"
        )
    finally:
        await handler.Close()


@router.get("/search", response_model=VietmapSearchResponse)
async def search_location_get(
    text: str = Query(..., description="Search text"),
    focus_lat: Optional[float] = Query(None, ge=-90, le=90, description="Focus latitude"),
    focus_lng: Optional[float] = Query(None, ge=-180, le=180, description="Focus longitude"),
    layers: Optional[str] = Query(None, description="Filter layers"),
    circle_center_lat: Optional[float] = Query(None, ge=-90, le=90, description="Circle center latitude"),
    circle_center_lng: Optional[float] = Query(None, ge=-180, le=180, description="Circle center longitude"),
    circle_radius: Optional[float] = Query(None, gt=0, description="Circle radius (km)"),
    categories: Optional[str] = Query(None, description="Categories filter"),
    city_id: Optional[int] = Query(None, description="City ID filter"),
    dist_id: Optional[int] = Query(None, description="District ID filter"),
    ward_id: Optional[int] = Query(None, description="Ward ID filter")
):
    """
    Search for locations using GET method.
    
    Same functionality as POST /search but using query parameters.
    
    Example: `/api/vietmap/search?text=Cafe%20Hanoi&focus_lat=21.0285&focus_lng=105.8542`
    """
    request = SearchRequest(
        text=text,
        focus_lat=focus_lat,
        focus_lng=focus_lng,
        layers=layers,
        circle_center_lat=circle_center_lat,
        circle_center_lng=circle_center_lng,
        circle_radius=circle_radius,
        categories=categories,
        city_id=city_id,
        dist_id=dist_id,
        ward_id=ward_id
    )
    
    return await search_location(request)


@router.post("/autocomplete", response_model=VietmapAutocompleteResponse)
async def autocomplete_location(request: AutocompleteRequest):
    """
    Get autocomplete suggestions for location search.
    
    Provides fast, type-ahead suggestions as the user types.
    
    Example request:
    ```json
    {
        "text": "Cafe Ha",
        "focus_lat": 21.0285,
        "focus_lng": 105.8542
    }
    ```
    """
    handler = get_vietmap_handler()
    
    try:
        # Build focus coordinate if provided
        focus = None
        if request.focus_lat is not None and request.focus_lng is not None:
            focus = MapCoordinate(Latitude=request.focus_lat, Longitude=request.focus_lng)
        
        # Create input schema
        autocomplete_input = VietmapAutocompleteInputSchema(
            Text=request.text,
            Focus=focus,
            Categories=request.categories
        )
        
        # Execute autocomplete
        result = await handler.Autocomplete(autocomplete_input)
        
        if result is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No suggestions found"
            )
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Autocomplete failed: {str(e)}"
        )
    finally:
        await handler.Close()


@router.get("/autocomplete", response_model=VietmapAutocompleteResponse)
async def autocomplete_location_get(
    text: str = Query(..., description="Text to autocomplete"),
    focus_lat: Optional[float] = Query(None, ge=-90, le=90, description="Focus latitude"),
    focus_lng: Optional[float] = Query(None, ge=-180, le=180, description="Focus longitude"),
    categories: Optional[str] = Query(None, description="Categories filter")
):
    """
    Get autocomplete suggestions using GET method.
    
    Example: `/api/vietmap/autocomplete?text=Cafe%20Ha&focus_lat=21.0285&focus_lng=105.8542`
    """
    request = AutocompleteRequest(
        text=text,
        focus_lat=focus_lat,
        focus_lng=focus_lng,
        categories=categories
    )
    
    return await autocomplete_location(request)


@router.get("/place/{ref_id}", response_model=VietmapPlaceResponse)
async def get_place_details(ref_id: str):
    """
    Get detailed information about a specific place using its reference ID.
    
    The reference ID is typically obtained from search or autocomplete results.
    
    Example: `/api/vietmap/place/1234567890abcdef`
    """
    handler = get_vietmap_handler()
    
    try:
        result = await handler.Place(ref_id)
        
        if result is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Place with reference ID '{ref_id}' not found"
            )
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve place details: {str(e)}"
        )
    finally:
        await handler.Close()


@router.post("/reverse", response_model=VietmapReverseResponse)
async def reverse_geocode(request: ReverseGeocodeRequest):
    """
    Reverse geocode: convert coordinates to address information.
    
    Given a latitude and longitude, returns the nearest address/place information.
    
    Example request:
    ```json
    {
        "latitude": 21.0285,
        "longitude": 105.8542
    }
    ```
    """
    handler = get_vietmap_handler()
    
    try:
        coords = MapCoordinate(
            Latitude=request.latitude,
            Longitude=request.longitude
        )
        
        result = await handler.Reverse(coords)
        
        if result is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No address found for the given coordinates"
            )
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Reverse geocoding failed: {str(e)}"
        )
    finally:
        await handler.Close()


@router.get("/reverse", response_model=VietmapReverseResponse)
async def reverse_geocode_get(
    latitude: float = Query(..., ge=-90, le=90, description="Latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Longitude")
):
    """
    Reverse geocode using GET method.
    
    Example: `/api/vietmap/reverse?latitude=21.0285&longitude=105.8542`
    """
    request = ReverseGeocodeRequest(latitude=latitude, longitude=longitude)
    return await reverse_geocode(request)


@router.get("/health")
async def health_check():
    """
    Check if Vietmap API is properly configured.
    
    Returns the status of the Vietmap API key configuration.
    """
    try:
        api_key = os.getenv("VIETMAP_API_KEY")
        if not api_key:
            return {
                "status": "error",
                "message": "VIETMAP_API_KEY not configured",
                "configured": False
            }
        
        return {
            "status": "ok",
            "message": "Vietmap API is properly configured",
            "configured": True,
            "api_key_length": len(api_key)
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e),
            "configured": False
        }
