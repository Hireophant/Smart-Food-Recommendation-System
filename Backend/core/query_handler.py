"""Query System Handler - Handles restaurant search and filtering operations."""

from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
from core.database.mongodb import MongoDB
from core.models.restaurant import RestaurantInDB
from core import MapCoordinate


class QueryFilter(BaseModel):
    """Filter criteria for restaurant queries."""
    model_config = ConfigDict(extra="ignore")
    
    category: Optional[str] = Field(default=None, description="Filter by category (e.g., Cafe, Restaurant)")
    min_rating: Optional[float] = Field(default=None, ge=0, le=5, description="Minimum rating filter")
    max_rating: Optional[float] = Field(default=None, ge=0, le=5, description="Maximum rating filter")
    district: Optional[str] = Field(default=None, description="Filter by district")
    province: Optional[str] = Field(default=None, description="Filter by province/city")
    max_distance: Optional[float] = Field(default=None, description="Maximum distance in meters")
    limit: int = Field(default=10, ge=1, le=100, description="Number of results to return")
    skip: int = Field(default=0, ge=0, description="Number of results to skip for pagination")


class QueryResult(BaseModel):
    """Result from a query operation."""
    success: bool
    data: Optional[List[Dict[str, Any]]] = None
    total_count: int = 0
    returned_count: int = 0
    error: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class QuerySystemHandler:
    """Handler for restaurant query operations."""
    
    def __init__(self):
        """Initialize the query system handler."""
        self.db = MongoDB
        self.restaurant_collection = "restaurants"
    
    async def search_by_name(
        self, 
        query: str, 
        filters: Optional[QueryFilter] = None
    ) -> QueryResult:
        """
        Search restaurants by name with optional filters.
        
        Args:
            query: Search term for restaurant name
            filters: Optional QueryFilter for additional filtering
            
        Returns:
            QueryResult containing matched restaurants
        """
        try:
            if not query or not query.strip():
                return QueryResult(
                    success=False,
                    error="Query string cannot be empty"
                )
            
            # Build base search query
            search_query = {
                "name": {"$regex": query, "$options": "i"}  # Case-insensitive search
            }
            
            # Apply additional filters
            search_query.update(self._build_filter_query(filters))
            
            # Execute query
            collection = self.db.get_collection(self.restaurant_collection)
            total_count = await collection.count_documents(search_query)
            
            skip_val = filters.skip if filters else 0
            limit_val = filters.limit if filters else 10
            
            results = await collection.find(search_query).skip(skip_val).limit(limit_val).to_list(None)
            
            return QueryResult(
                success=True,
                data=self._format_results(results),
                total_count=total_count,
                returned_count=len(results)
            )
        
        except Exception as e:
            return QueryResult(
                success=False,
                error=f"Search failed: {str(e)}"
            )
    
    async def search_by_category(
        self,
        category: str,
        filters: Optional[QueryFilter] = None
    ) -> QueryResult:
        """
        Search restaurants by category.
        
        Args:
            category: Category to search for
            filters: Optional QueryFilter for additional filtering
            
        Returns:
            QueryResult containing matched restaurants
        """
        try:
            if not category or not category.strip():
                return QueryResult(
                    success=False,
                    error="Category cannot be empty"
                )
            
            search_query = {
                "category": {"$regex": category, "$options": "i"}
            }
            
            # Apply additional filters
            search_query.update(self._build_filter_query(filters))
            
            collection = self.db.get_collection(self.restaurant_collection)
            total_count = await collection.count_documents(search_query)
            
            skip_val = filters.skip if filters else 0
            limit_val = filters.limit if filters else 10
            
            results = await collection.find(search_query).skip(skip_val).limit(limit_val).to_list(None)
            
            return QueryResult(
                success=True,
                data=self._format_results(results),
                total_count=total_count,
                returned_count=len(results)
            )
        
        except Exception as e:
            return QueryResult(
                success=False,
                error=f"Category search failed: {str(e)}"
            )
    
    async def search_by_location(
        self,
        latitude: float,
        longitude: float,
        max_distance: float = 5000,
        filters: Optional[QueryFilter] = None
    ) -> QueryResult:
        """
        Search restaurants by geolocation within a distance radius.
        
        Args:
            latitude: Latitude of center point
            longitude: Longitude of center point
            max_distance: Maximum distance in meters (default 5000)
            filters: Optional QueryFilter for additional filtering
            
        Returns:
            QueryResult containing nearby restaurants
        """
        try:
            if not (-90 <= latitude <= 90):
                return QueryResult(
                    success=False,
                    error="Invalid latitude value"
                )
            if not (-180 <= longitude <= 180):
                return QueryResult(
                    success=False,
                    error="Invalid longitude value"
                )
            
            # Build geospatial query
            search_query = {
                "location": {
                    "$near": {
                        "$geometry": {
                            "type": "Point",
                            "coordinates": [longitude, latitude]
                        },
                        "$maxDistance": max_distance
                    }
                }
            }
            
            # Apply additional filters
            search_query.update(self._build_filter_query(filters))
            
            collection = self.db.get_collection(self.restaurant_collection)
            total_count = await collection.count_documents(search_query)
            
            skip_val = filters.skip if filters else 0
            limit_val = filters.limit if filters else 10
            
            results = await collection.find(search_query).skip(skip_val).limit(limit_val).to_list(None)
            
            return QueryResult(
                success=True,
                data=self._format_results(results),
                total_count=total_count,
                returned_count=len(results)
            )
        
        except Exception as e:
            return QueryResult(
                success=False,
                error=f"Location search failed: {str(e)}"
            )
    
    async def search_by_rating(
        self,
        min_rating: float = 0.0,
        max_rating: float = 5.0,
        filters: Optional[QueryFilter] = None
    ) -> QueryResult:
        """
        Search restaurants by rating range.
        
        Args:
            min_rating: Minimum rating (0-5)
            max_rating: Maximum rating (0-5)
            filters: Optional QueryFilter for additional filtering
            
        Returns:
            QueryResult containing restaurants within rating range
        """
        try:
            if not (0 <= min_rating <= 5) or not (0 <= max_rating <= 5):
                return QueryResult(
                    success=False,
                    error="Rating values must be between 0 and 5"
                )
            if min_rating > max_rating:
                return QueryResult(
                    success=False,
                    error="Minimum rating cannot be greater than maximum rating"
                )
            
            search_query = {
                "rating": {
                    "$gte": min_rating,
                    "$lte": max_rating
                }
            }
            
            # Apply additional filters
            search_query.update(self._build_filter_query(filters))
            
            collection = self.db.get_collection(self.restaurant_collection)
            total_count = await collection.count_documents(search_query)
            
            skip_val = filters.skip if filters else 0
            limit_val = filters.limit if filters else 10
            
            results = await collection.find(search_query).skip(skip_val).limit(limit_val).to_list(None)
            
            return QueryResult(
                success=True,
                data=self._format_results(results),
                total_count=total_count,
                returned_count=len(results)
            )
        
        except Exception as e:
            return QueryResult(
                success=False,
                error=f"Rating search failed: {str(e)}"
            )
    
    async def combined_search(
        self,
        search_term: Optional[str] = None,
        location: Optional[Dict[str, float]] = None,
        filters: Optional[QueryFilter] = None
    ) -> QueryResult:
        """
        Combined search with name, location, and filters.
        
        Args:
            search_term: Search term for name/category
            location: Dict with 'latitude' and 'longitude' keys
            filters: Optional QueryFilter for additional filtering
            
        Returns:
            QueryResult containing matched restaurants
        """
        try:
            search_query = {}
            
            # Add name search if provided
            if search_term and search_term.strip():
                search_query["$or"] = [
                    {"name": {"$regex": search_term, "$options": "i"}},
                    {"category": {"$regex": search_term, "$options": "i"}}
                ]
            
            # Add location search if provided
            if location:
                max_dist = filters.max_distance if filters and filters.max_distance else 5000
                search_query["location"] = {
                    "$near": {
                        "$geometry": {
                            "type": "Point",
                            "coordinates": [location.get("longitude"), location.get("latitude")]
                        },
                        "$maxDistance": max_dist
                    }
                }
            
            # Apply additional filters
            search_query.update(self._build_filter_query(filters))
            
            collection = self.db.get_collection(self.restaurant_collection)
            total_count = await collection.count_documents(search_query)
            
            skip_val = filters.skip if filters else 0
            limit_val = filters.limit if filters else 10
            
            results = await collection.find(search_query).skip(skip_val).limit(limit_val).to_list(None)
            
            return QueryResult(
                success=True,
                data=self._format_results(results),
                total_count=total_count,
                returned_count=len(results)
            )
        
        except Exception as e:
            return QueryResult(
                success=False,
                error=f"Combined search failed: {str(e)}"
            )
    
    async def get_restaurant_by_id(self, restaurant_id: str) -> QueryResult:
        """
        Get a specific restaurant by ID.
        
        Args:
            restaurant_id: MongoDB ObjectId as string
            
        Returns:
            QueryResult containing the restaurant details
        """
        try:
            from bson import ObjectId
            
            if not restaurant_id:
                return QueryResult(
                    success=False,
                    error="Restaurant ID cannot be empty"
                )
            
            try:
                object_id = ObjectId(restaurant_id)
            except Exception:
                return QueryResult(
                    success=False,
                    error="Invalid restaurant ID format"
                )
            
            collection = self.db.get_collection(self.restaurant_collection)
            result = await collection.find_one({"_id": object_id})
            
            if result:
                return QueryResult(
                    success=True,
                    data=[self._format_single_result(result)],
                    total_count=1,
                    returned_count=1
                )
            else:
                return QueryResult(
                    success=False,
                    error=f"Restaurant with ID {restaurant_id} not found"
                )
        
        except Exception as e:
            return QueryResult(
                success=False,
                error=f"Failed to retrieve restaurant: {str(e)}"
            )
    
    async def get_all_categories(self) -> QueryResult:
        """
        Get all available restaurant categories.
        
        Returns:
            QueryResult containing list of unique categories
        """
        try:
            collection = self.db.get_collection(self.restaurant_collection)
            categories = await collection.distinct("category")
            
            return QueryResult(
                success=True,
                data=[{"categories": sorted(categories)}],
                returned_count=len(categories)
            )
        
        except Exception as e:
            return QueryResult(
                success=False,
                error=f"Failed to retrieve categories: {str(e)}"
            )
    
    async def get_statistics(self) -> QueryResult:
        """
        Get statistics about restaurants in the database.
        
        Returns:
            QueryResult containing database statistics
        """
        try:
            collection = self.db.get_collection(self.restaurant_collection)
            
            pipeline = [
                {
                    "$group": {
                        "_id": None,
                        "total_restaurants": {"$sum": 1},
                        "avg_rating": {"$avg": "$rating"},
                        "max_rating": {"$max": "$rating"},
                        "min_rating": {"$min": "$rating"},
                        "categories_count": {"$addToSet": "$category"}
                    }
                }
            ]
            
            results = await collection.aggregate(pipeline).to_list(None)
            
            if results:
                stats = results[0]
                stats["unique_categories"] = len(stats.get("categories_count", []))
                return QueryResult(
                    success=True,
                    data=[stats],
                    returned_count=1
                )
            else:
                return QueryResult(
                    success=False,
                    error="No restaurants found in database"
                )
        
        except Exception as e:
            return QueryResult(
                success=False,
                error=f"Failed to retrieve statistics: {str(e)}"
            )
    
    def _build_filter_query(self, filters: Optional[QueryFilter]) -> Dict[str, Any]:
        """
        Build MongoDB filter query from QueryFilter object.
        
        Args:
            filters: QueryFilter object
            
        Returns:
            Dictionary with MongoDB filter query
        """
        query = {}
        
        if not filters:
            return query
        
        if filters.category:
            query["category"] = {"$regex": filters.category, "$options": "i"}
        
        if filters.district:
            query["district"] = {"$regex": filters.district, "$options": "i"}
        
        if filters.province:
            query["province"] = {"$regex": filters.province, "$options": "i"}
        
        if filters.min_rating is not None or filters.max_rating is not None:
            rating_query = {}
            if filters.min_rating is not None:
                rating_query["$gte"] = filters.min_rating
            if filters.max_rating is not None:
                rating_query["$lte"] = filters.max_rating
            if rating_query:
                query["rating"] = rating_query
        
        return query
    
    def _format_results(self, results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Format MongoDB results for API response."""
        return [self._format_single_result(result) for result in results]
    
    def _format_single_result(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """Format a single MongoDB result."""
        result["id"] = str(result.pop("_id", None))
        return result
