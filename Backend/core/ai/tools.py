"""
AI Tools - Function Definitions and Executors
Implements tools that AI can call during conversation.
"""

from typing import Dict, Any, List
from .schemas import UserTasteProfile

# Fix import for standalone execution
try:
    from ...utils import Logger
except ImportError:
    class Logger:
        @staticmethod
        def info(msg): print(f"ℹ️  INFO: {msg}")
        @staticmethod
        def error(msg): print(f"❌ ERROR: {msg}")
        @staticmethod
        def success(msg): print(f"✅ SUCCESS: {msg}")
        @staticmethod
        def LogInfo(msg): Logger.info(msg)
        @staticmethod
        def LogError(msg): Logger.error(msg)


# ============================================================================
# TOOL DEFINITIONS (For Gemini Function Calling)
# ============================================================================

TOOL_DEFINITIONS = [
    {
        "name": "update_user_taste_profile",
        "description": """Update user's food taste profile based on conversation.
        
Use this when user expresses preferences about:
- Cuisines they like/dislike (Vietnamese, Japanese, Korean, etc.)
- Spice tolerance (mild, medium, hot, extreme)
- Dietary restrictions (vegetarian, vegan, halal, gluten-free)
- Allergies (peanuts, shellfish, dairy, etc.)
- Price preferences (budget, mid-range, premium)
- Specific dishes they love or hate

Examples:
- User: "Tôi thích ăn cay" → update_user_taste_profile(category="spice_level", value="hot", sentiment="love")
- User: "Tôi ăn chay" → update_user_taste_profile(category="dietary", value="vegetarian", sentiment="neutral")
- User: "Không thích hải sản" → update_user_taste_profile(category="cuisine", value="seafood", sentiment="dislike")
""",
        "parameters": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "enum": ["cuisine", "spice_level", "dietary", "allergy", "price", "dish"],
                    "description": "Category of preference to update"
                },
                "value": {
                    "type": "string",
                    "description": "The preference value (e.g., 'Vietnamese', 'hot', 'vegetarian')"
                },
                "sentiment": {
                    "type": "string",
                    "enum": ["love", "like", "neutral", "dislike", "hate"],
                    "description": "User's sentiment toward this preference"
                }
            },
            "required": ["category", "value", "sentiment"]
        }
    },
    {
        "name": "search_restaurants",
        "description": """Search for restaurants based on criteria.
        
Use this when user asks to:
- Find restaurants nearby
- Search for specific cuisine type
- Look for restaurants in a specific area
- Find restaurants matching preferences

This tool will query the MongoDB database and return matching restaurants.
""",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Search query (e.g., 'phở', 'Japanese restaurant')"
                },
                "cuisine": {
                    "type": "string",
                    "description": "Cuisine type filter (optional)"
                },
                "max_results": {
                    "type": "integer",
                    "description": "Maximum number of results to return",
                    "default": 5
                },
                "latitude": {
                    "type": "number",
                    "description": "User's latitude for nearby search (optional)"
                },
                "longitude": {
                    "type": "number",
                    "description": "User's longitude for nearby search (optional)"
                },
                "radius_km": {
                    "type": "number",
                    "description": "Search radius in kilometers",
                    "default": 5.0
                }
            },
            "required": ["query"]
        }
    },
    {
        "name": "get_user_taste_profile",
        "description": """Retrieve user's current taste profile.
        
Use this when you need to:
- Check what user likes/dislikes before making recommendations
- Understand user's dietary restrictions
- Verify user's preferences

Returns the complete taste profile including cuisines, spice level, dietary restrictions, etc.
""",
        "parameters": {
            "type": "object",
            "properties": {
                "user_id": {
                    "type": "string",
                    "description": "User identifier"
                }
            },
            "required": ["user_id"]
        }
    }
]


# ============================================================================
# TOOL EXECUTORS
# ============================================================================

class ToolExecutor:
    """
    Executes tools called by AI.
    In-memory storage for MVP (replace with Redis/MongoDB in production).
    """
    
    # In-memory storage
    _taste_profiles: Dict[str, UserTasteProfile] = {}
    
    @classmethod
    def execute_tool(cls, function_name: str, function_args: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a tool and return result.
        
        Args:
            function_name: Name of the function to execute
            function_args: Arguments for the function
            
        Returns:
            Tool execution result
        """
        Logger.info(f"Executing tool: {function_name} with args: {function_args}")
        
        if function_name == "update_user_taste_profile":
            return cls._update_taste_profile(function_args)
        elif function_name == "get_user_taste_profile":
            return cls._get_taste_profile(function_args)
        elif function_name == "search_restaurants":
            return cls._search_restaurants(function_args)
        else:
            return {
                "error": f"Unknown tool: {function_name}",
                "success": False
            }
    
    @classmethod
    def _update_taste_profile(cls, args: Dict[str, Any]) -> Dict[str, Any]:
        """
        Update user taste profile.
        
        Args from AI:
            category: cuisine/spice_level/dietary/allergy/price/dish
            value: The preference value
            sentiment: love/like/neutral/dislike/hate
        
        Note: user_id comes from conversation context, injected by service
        """
        # Extract user_id (injected by service layer)
        user_id = args.get("user_id", "unknown")
        category = args.get("category")
        value = args.get("value")
        sentiment = args.get("sentiment")
        
        # Get or create profile
        if user_id not in cls._taste_profiles:
            cls._taste_profiles[user_id] = UserTasteProfile(user_id=user_id)
        
        profile = cls._taste_profiles[user_id]
        
        # Update based on category
        if category == "cuisine":
            if sentiment in ["love", "like"]:
                if value not in profile.cuisines:
                    profile.cuisines.append(value)
            elif sentiment in ["dislike", "hate"]:
                if value in profile.cuisines:
                    profile.cuisines.remove(value)
                    
        elif category == "spice_level":
            profile.spice_level = value
            
        elif category == "dietary":
            if value not in profile.dietary_restrictions:
                profile.dietary_restrictions.append(value)
                
        elif category == "allergy":
            if value not in profile.allergies:
                profile.allergies.append(value)
                
        elif category == "price":
            profile.price_preference = value
            
        elif category == "dish":
            if sentiment in ["love", "like"]:
                if value not in profile.favorite_dishes:
                    profile.favorite_dishes.append(value)
            elif sentiment in ["dislike", "hate"]:
                if value not in profile.dislikes:
                    profile.dislikes.append(value)
        
        Logger.success(f"Updated taste profile for {user_id}: {category}={value} ({sentiment})")
        
        return {
            "success": True,
            "message": f"Updated {category} preference to {value}",
            "user_id": user_id,
            "category": category,
            "value": value
        }
    
    @classmethod
    def _get_taste_profile(cls, args: Dict[str, Any]) -> Dict[str, Any]:
        """Get user's taste profile"""
        user_id = args.get("user_id", "unknown")
        
        if user_id in cls._taste_profiles:
            profile = cls._taste_profiles[user_id]
            # Return simple dict without datetime fields
            return {
                "success": True,
                "profile": {
                    "user_id": profile.user_id,
                    "preferred_cuisines": profile.preferred_cuisines,
                    "spice_level": profile.spice_level,
                    "dietary_restrictions": profile.dietary_restrictions,
                    "allergies": profile.allergies,
                    "favorite_dishes": profile.favorite_dishes,
                    "dislikes": profile.dislikes,
                    "budget_range": profile.budget_range
                }
            }
        else:
            # Return empty profile
            return {
                "success": True,
                "profile": {
                    "user_id": user_id,
                    "preferred_cuisines": [],
                    "spice_level": None,
                    "dietary_restrictions": [],
                    "allergies": [],
                    "favorite_dishes": [],
                    "dislikes": [],
                    "budget_range": None
                },
                "message": "No profile found, returning empty profile"
            }
    
    @classmethod
    def _search_restaurants(cls, args: Dict[str, Any]) -> Dict[str, Any]:
        """
        Search restaurants (mock implementation).
        TODO: Integrate with MongoDB handlers
        """
        query = args.get("query", "")
        max_results = args.get("max_results", 5)
        
        Logger.info(f"Searching restaurants: query='{query}', max={max_results}")
        
        # Mock data for now
        # TODO: Replace with actual MongoDB query
        mock_results = [
            {
                "name": "Phở Thìn",
                "cuisine": "Vietnamese",
                "rating": 4.5,
                "price_range": "budget",
                "address": "13 Lò Đúc, Hai Bà Trưng, Hà Nội",
                "distance_km": 0.8
            },
            {
                "name": "Bún Chả Hương Liên",
                "cuisine": "Vietnamese",
                "rating": 4.7,
                "price_range": "budget",
                "address": "24 Lê Văn Hưu, Hai Bà Trưng, Hà Nội",
                "distance_km": 1.2
            }
        ]
        
        return {
            "success": True,
            "results": mock_results[:max_results],
            "total_found": len(mock_results)
        }
