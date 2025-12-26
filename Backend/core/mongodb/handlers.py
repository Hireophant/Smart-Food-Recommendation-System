"""
MongoDB handlers for restaurant search operations.
Follows the same pattern as VietMap handlers for consistent frontend integration.
"""

import re
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, ConfigDict, Field, PositiveFloat
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from bson.errors import InvalidId


class MongoDBSearchInputSchema(BaseModel):
    """Input schema for MongoDB restaurant search."""
    model_config = ConfigDict(extra="ignore")
    
    Text: Optional[str] = Field(default=None, description="Search text for name, category, address, tags")
    Latitude: Optional[float] = Field(default=None, description="User's latitude (optional, for distance calculation)")
    Longitude: Optional[float] = Field(default=None, description="User's longitude (optional, for distance calculation)")
    Radius: PositiveFloat = Field(default=5000.0, description="Search radius in meters (default 5km)")
    MinRating: Optional[float] = Field(default=None, ge=0.0, le=5.0, description="Minimum rating filter")
    Category: Optional[str] = Field(default=None, description="Filter by category")
    Tags: Optional[str] = Field(default=None, description="Filter by tags (substring match against restaurant tags)")
    Province: Optional[str] = Field(default=None, description="Filter by province")
    District: Optional[str] = Field(default=None, description="Filter by district")
    Limit: int = Field(default=20, ge=1, le=100, description="Maximum number of results")


class MongoDBRestaurantResponse(BaseModel):
    """Response model for a single restaurant."""
    model_config = ConfigDict(extra="ignore")
    
    id: str = Field(description="Restaurant ID")
    name: str = Field(description="Restaurant name")
    category: str = Field(description="Restaurant category")
    rating: float = Field(description="Restaurant rating")
    address: str = Field(description="Full address")
    province: str = Field(description="Province")
    district: str = Field(description="District")
    ward: Optional[str] = Field(default=None, description="Ward")
    tags: List[str] = Field(default_factory=list, description="Tags for recommendation")
    location: Dict[str, Any] = Field(description="GeoJSON location")
    distance: Optional[float] = Field(default=None, description="Distance from user in meters")
    distance_km: Optional[float] = Field(default=None, description="Distance from user in kilometers")
    link: Optional[str] = Field(default=None, description="Google Maps link")
    score: Optional[float] = Field(default=None, description="Relevance score (if text search)")


class MongoDBSearchResponse(BaseModel):
    """Response model for search results."""
    model_config = ConfigDict(extra="ignore")
    
    success: bool = Field(description="Whether the search was successful")
    count: int = Field(description="Number of results returned")
    query_info: Dict[str, Any] = Field(description="Information about the query")
    restaurants: List[MongoDBRestaurantResponse] = Field(description="List of restaurants")
    error: Optional[str] = Field(default=None, description="Error message if failed")


class MongoDBGetByIdsInputSchema(BaseModel):
    """Input schema for fetching restaurants by a list of IDs."""
    model_config = ConfigDict(extra="ignore")

    Ids: List[str] = Field(min_length=1, max_length=200, description="List of restaurant IDs")
    Limit: int = Field(default=100, ge=1, le=200, description="Maximum number of results")


class MongoDBHandlers:
    """
    MongoDB handlers for restaurant search operations.
    Optimized for geospatial and text search queries.
    """
    
    def __init__(self, database: AsyncIOMotorDatabase) -> None:
        """
        Initialize MongoDB handlers.
        
        Args:
            database: AsyncIOMotorDatabase instance from MongoDB.get_database()
        """
        self.__db = database
        self.__collection = database.restaurants

    @staticmethod
    def __contains_ci(value: Optional[str]) -> Optional[Dict[str, str]]:
        """Build a safe case-insensitive MongoDB regex that matches substrings."""
        if value is None:
            return None
        value = str(value).strip()
        if not value:
            return None
        # Escape to avoid treating user input as regex syntax.
        return {"$regex": re.escape(value), "$options": "i"}
    
    async def __build_pipeline(self, inputs: MongoDBSearchInputSchema) -> List[Dict[str, Any]]:
        """
        Build optimized aggregation pipeline based on input parameters.
        
        Strategy:
        - If text search: Use $match with $text (MUST be first), then calculate distance manually
        - If no text: Use $geoNear (faster, can be first stage)
        - Apply other filters
        - Sort by relevance/distance
        """
        pipeline = []
        has_coords = inputs.Latitude is not None and inputs.Longitude is not None
        
        if inputs.Text:
            # STRATEGY A: Text search with distance calculation
            # Stage 1: Text search (MUST be first when using $text)
            pipeline.append({
                "$match": {
                    "$text": {"$search": inputs.Text}
                }
            })
            
            # Stage 2: Add text score
            pipeline.append({
                "$addFields": {
                    "textScore": {"$meta": "textScore"}
                }
            })
            
            if has_coords:
                # Stage 3: Calculate distance using $geoNear alternative
                pipeline.append({
                    "$addFields": {
                        "distance": {
                            "$let": {
                                "vars": {
                                    "lon1": {"$arrayElemAt": ["$location.coordinates", 0]},
                                    "lat1": {"$arrayElemAt": ["$location.coordinates", 1]},
                                    "lon2": inputs.Longitude,
                                    "lat2": inputs.Latitude
                                },
                                "in": {
                                    "$multiply": [
                                        6371000,  # Earth radius in meters
                                        {
                                            "$acos": {
                                                "$add": [
                                                    {
                                                        "$multiply": [
                                                            {"$sin": {"$degreesToRadians": "$$lat1"}},
                                                            {"$sin": {"$degreesToRadians": "$$lat2"}}
                                                        ]
                                                    },
                                                    {
                                                        "$multiply": [
                                                            {"$cos": {"$degreesToRadians": "$$lat1"}},
                                                            {"$cos": {"$degreesToRadians": "$$lat2"}},
                                                            {"$cos": {
                                                                "$degreesToRadians": {
                                                                    "$subtract": ["$$lon2", "$$lon1"]
                                                                }
                                                            }}
                                                        ]
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                }
                            }
                        }
                    }
                })

                # Stage 4: Filter by distance radius
                pipeline.append({
                    "$match": {
                        "distance": {"$lte": inputs.Radius}
                    }
                })
            
            # Stage 5: Apply other filters
            match_conditions = []
            if inputs.MinRating is not None:
                match_conditions.append({"rating": {"$gte": inputs.MinRating}})
            if inputs.Category:
                category_regex = self.__contains_ci(inputs.Category)
                if category_regex is not None:
                    # Your dataset uses broad categories (e.g. "Quán ăn"), while dish types
                    # are stored in tags; treat Category as (category OR tags) to match user expectation.
                    match_conditions.append({"$or": [{"category": category_regex}, {"tags": category_regex}]})
            if inputs.Tags:
                tags_regex = self.__contains_ci(inputs.Tags)
                if tags_regex is not None:
                    match_conditions.append({"tags": tags_regex})
            if inputs.Province:
                province_regex = self.__contains_ci(inputs.Province)
                if province_regex is not None:
                    match_conditions.append({"province": province_regex})
            if inputs.District:
                district_regex = self.__contains_ci(inputs.District)
                if district_regex is not None:
                    match_conditions.append({"district": district_regex})
            
            if match_conditions:
                pipeline.append({
                    "$match": {"$and": match_conditions}
                })
            
        else:
            # STRATEGY B: No text search
            if has_coords:
                # Use $geoNear when coordinates are available (faster)
                geo_conditions: List[Dict[str, Any]] = []

                # Add filters to $geoNear query
                if inputs.MinRating is not None:
                    geo_conditions.append({"rating": {"$gte": inputs.MinRating}})

                if inputs.Category:
                    category_regex = self.__contains_ci(inputs.Category)
                    if category_regex is not None:
                        geo_conditions.append({"$or": [{"category": category_regex}, {"tags": category_regex}]})

                if inputs.Tags:
                    tags_regex = self.__contains_ci(inputs.Tags)
                    if tags_regex is not None:
                        geo_conditions.append({"tags": tags_regex})

                if inputs.Province:
                    province_regex = self.__contains_ci(inputs.Province)
                    if province_regex is not None:
                        geo_conditions.append({"province": province_regex})

                if inputs.District:
                    district_regex = self.__contains_ci(inputs.District)
                    if district_regex is not None:
                        geo_conditions.append({"district": district_regex})

                geo_query: Optional[Dict[str, Any]] = None
                if len(geo_conditions) == 1:
                    geo_query = geo_conditions[0]
                elif len(geo_conditions) > 1:
                    geo_query = {"$and": geo_conditions}

                geo_near_stage = {
                    "$geoNear": {
                        "near": {
                            "type": "Point",
                            "coordinates": [inputs.Longitude, inputs.Latitude]
                        },
                        "distanceField": "distance",
                        "maxDistance": inputs.Radius,
                        "spherical": True,
                        "key": "location"
                    }
                }

                if geo_query:
                    geo_near_stage["$geoNear"]["query"] = geo_query

                pipeline.append(geo_near_stage)
            else:
                # Without coordinates, fall back to plain filtering.
                match_conditions = []
                if inputs.MinRating is not None:
                    match_conditions.append({"rating": {"$gte": inputs.MinRating}})
                if inputs.Category:
                    category_regex = self.__contains_ci(inputs.Category)
                    if category_regex is not None:
                        match_conditions.append({"$or": [{"category": category_regex}, {"tags": category_regex}]})
                if inputs.Tags:
                    tags_regex = self.__contains_ci(inputs.Tags)
                    if tags_regex is not None:
                        match_conditions.append({"tags": tags_regex})
                if inputs.Province:
                    province_regex = self.__contains_ci(inputs.Province)
                    if province_regex is not None:
                        match_conditions.append({"province": province_regex})
                if inputs.District:
                    district_regex = self.__contains_ci(inputs.District)
                    if district_regex is not None:
                        match_conditions.append({"district": district_regex})

                if match_conditions:
                    pipeline.append({"$match": {"$and": match_conditions}})
        
        # Stage 3: Add distance in kilometers (or set to null if no coords)
        if has_coords:
            pipeline.append({
                "$addFields": {
                    "distance_km": {"$divide": ["$distance", 1000]}
                }
            })
        else:
            pipeline.append({
                "$addFields": {
                    "distance": None,
                    "distance_km": None
                }
            })
        
        # Stage 4: Sort by relevance
        if inputs.Text:
            if has_coords:
                pipeline.append({
                    "$sort": {
                        "textScore": -1,
                        "distance": 1
                    }
                })
            else:
                pipeline.append({
                    "$sort": {
                        "textScore": -1,
                        "rating": -1
                    }
                })
        else:
            if has_coords:
                pipeline.append({
                    "$sort": {
                        "distance": 1,
                        "rating": -1
                    }
                })
            else:
                pipeline.append({
                    "$sort": {
                        "rating": -1
                    }
                })
        
        # Stage 5: Limit results
        pipeline.append({"$limit": inputs.Limit})
        
        # Stage 6: Project only needed fields
        pipeline.append({
            "$project": {
                "id": {"$toString": "$_id"},
                "name": 1,
                "category": 1,
                "rating": 1,
                "address": 1,
                "province": 1,
                "district": 1,
                "ward": 1,
                "tags": 1,
                "location": 1,
                "distance": 1,
                "distance_km": 1,
                "link": 1,
                "textScore": 1,
                "_id": 0
            }
        })
        
        return pipeline
    
    async def Search(self, inputs: MongoDBSearchInputSchema) -> MongoDBSearchResponse:
        """
        Search for restaurants near a location with optional filters.
        
        Args:
            inputs: MongoDBSearchInputSchema with search parameters
            
        Returns:
            MongoDBSearchResponse with list of restaurants
            
        Example:
            >>> handler = MongoDBHandlers(db)
            >>> result = await handler.Search(MongoDBSearchInputSchema(
            ...     Text="bún bò",
            ...     Latitude=10.762622,
            ...     Longitude=106.660172,
            ...     Radius=5000,
            ...     MinRating=4.0
            ... ))
        """
        try:
            # Build aggregation pipeline
            pipeline = await self.__build_pipeline(inputs)
            
            # Execute query
            cursor = self.__collection.aggregate(pipeline)
            results = await cursor.to_list(length=inputs.Limit)
            
            # Transform results to response models
            restaurants = []
            for doc in results:
                restaurants.append(MongoDBRestaurantResponse(
                    id=doc.get("id", ""),
                    name=doc.get("name", ""),
                    category=doc.get("category", "Unknown"),
                    rating=doc.get("rating", 0.0),
                    address=doc.get("address", ""),
                    province=doc.get("province", ""),
                    district=doc.get("district", ""),
                    ward=doc.get("ward"),
                    tags=doc.get("tags", []),
                    location=doc.get("location", {}),
                    distance=doc.get("distance"),
                    distance_km=doc.get("distance_km"),
                    link=doc.get("link"),
                    score=doc.get("textScore")
                ))
            
            # Build response
            return MongoDBSearchResponse(
                success=True,
                count=len(restaurants),
                query_info={
                    "text": inputs.Text,
                    "location": {
                        "latitude": inputs.Latitude,
                        "longitude": inputs.Longitude
                    } if (inputs.Latitude is not None and inputs.Longitude is not None) else None,
                    "radius_meters": inputs.Radius,
                    "radius_km": inputs.Radius / 1000,
                    "min_rating": inputs.MinRating,
                    "category": inputs.Category,
                    "tags": inputs.Tags,
                    "province": inputs.Province,
                    "district": inputs.District,
                    "limit": inputs.Limit
                },
                restaurants=restaurants
            )
            
        except Exception as e:
            return MongoDBSearchResponse(
                success=False,
                count=0,
                query_info={},
                restaurants=[],
                error=str(e)
            )
    
    async def SearchNearby(
        self,
        latitude: float,
        longitude: float,
        radius: float = 5000.0,
        min_rating: Optional[float] = None,
        category: Optional[str] = None,
        limit: int = 20
    ) -> MongoDBSearchResponse:
        """
        Simplified method to search nearby restaurants without text filter.
        
        Args:
            latitude: User's latitude
            longitude: User's longitude
            radius: Search radius in meters (default 5km)
            min_rating: Minimum rating filter (optional)
            category: Category filter (optional)
            limit: Maximum number of results
            
        Returns:
            MongoDBSearchResponse with list of nearby restaurants
        """
        inputs = MongoDBSearchInputSchema(
            Latitude=latitude,
            Longitude=longitude,
            Radius=radius,
            MinRating=min_rating,
            Category=category,
            Limit=limit
        )
        return await self.Search(inputs)
    
    async def SearchByText(
        self,
        text: str,
        latitude: float,
        longitude: float,
        radius: float = 10000.0,
        min_rating: Optional[float] = None,
        limit: int = 20
    ) -> MongoDBSearchResponse:
        """
        Simplified method to search restaurants by text near a location.
        
        Args:
            text: Search query (dish name, restaurant name, etc.)
            latitude: User's latitude
            longitude: User's longitude
            radius: Search radius in meters (default 10km)
            min_rating: Minimum rating filter (optional)
            limit: Maximum number of results
            
        Returns:
            MongoDBSearchResponse with list of matching restaurants
        """
        inputs = MongoDBSearchInputSchema(
            Text=text,
            Latitude=latitude,
            Longitude=longitude,
            Radius=radius,
            MinRating=min_rating,
            Limit=limit
        )
        return await self.Search(inputs)
    
    async def GetTopRated(
        self,
        latitude: float,
        longitude: float,
        radius: float = 10000.0,
        category: Optional[str] = None,
        limit: int = 10
    ) -> MongoDBSearchResponse:
        """
        Get top-rated restaurants near a location.
        
        Args:
            latitude: User's latitude
            longitude: User's longitude
            radius: Search radius in meters (default 10km)
            category: Category filter (optional)
            limit: Maximum number of results
            
        Returns:
            MongoDBSearchResponse with list of top-rated restaurants
        """
        inputs = MongoDBSearchInputSchema(
            Latitude=latitude,
            Longitude=longitude,
            Radius=radius,
            MinRating=4.0,  # Only highly rated
            Category=category,
            Limit=limit
        )
        return await self.Search(inputs)

    async def GetByIds(self, inputs: MongoDBGetByIdsInputSchema) -> MongoDBSearchResponse:
        """Fetch restaurants by a list of MongoDB document IDs.

        Notes:
        - Preserves the input order when possible.
        - Validates that all provided IDs are valid ObjectId strings.
        """
        try:
            ids_raw = [str(x).strip() for x in (inputs.Ids or []) if str(x).strip()]
            if not ids_raw:
                raise ValueError("Ids must be a non-empty list")

            try:
                object_ids = [ObjectId(x) for x in ids_raw]
            except InvalidId as exc:
                raise ValueError(f"Invalid restaurant id in list: {exc}")

            pipeline: List[Dict[str, Any]] = [
                {"$match": {"_id": {"$in": object_ids}}},
                {
                    "$addFields": {
                        "__order": {
                            "$indexOfArray": [ids_raw, {"$toString": "$_id"}]
                        }
                    }
                },
                {"$sort": {"__order": 1}},
                {"$limit": int(inputs.Limit)},
                {
                    "$project": {
                        "id": {"$toString": "$_id"},
                        "name": 1,
                        "category": 1,
                        "rating": 1,
                        "address": 1,
                        "province": 1,
                        "district": 1,
                        "ward": 1,
                        "tags": 1,
                        "location": 1,
                        "distance": 1,
                        "distance_km": 1,
                        "link": 1,
                        "textScore": 1,
                        "_id": 0,
                    }
                },
            ]

            cursor = self.__collection.aggregate(pipeline)
            results = await cursor.to_list(length=int(inputs.Limit))

            restaurants: List[MongoDBRestaurantResponse] = []
            for doc in results:
                restaurants.append(
                    MongoDBRestaurantResponse(
                        id=doc.get("id", ""),
                        name=doc.get("name", ""),
                        category=doc.get("category", "Unknown"),
                        rating=doc.get("rating", 0.0),
                        address=doc.get("address", ""),
                        province=doc.get("province", ""),
                        district=doc.get("district", ""),
                        ward=doc.get("ward"),
                        tags=doc.get("tags", []),
                        location=doc.get("location", {}),
                        distance=doc.get("distance"),
                        distance_km=doc.get("distance_km"),
                        link=doc.get("link"),
                        score=doc.get("textScore"),
                    )
                )

            return MongoDBSearchResponse(
                success=True,
                count=len(restaurants),
                query_info={"ids": ids_raw, "limit": int(inputs.Limit)},
                restaurants=restaurants,
            )
        except Exception as e:
            return MongoDBSearchResponse(
                success=False,
                count=0,
                query_info={},
                restaurants=[],
                error=str(e),
            )
