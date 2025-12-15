"""MongoDB connection and configuration for Smart Food Recommendation System."""

import os
from typing import Optional
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import MongoClient
from pydantic import BaseModel, Field, ConfigDict


class MongoConfig(BaseModel):
    """MongoDB configuration model."""
    model_config = ConfigDict(extra='ignore', populate_by_name=True)
    
    host: str = Field(default="localhost", alias="host")
    port: int = Field(default=27017, alias="port") 
    database: str = Field(default="smart_food_db", alias="database")
    username: Optional[str] = Field(default=None, alias="username")
    password: Optional[str] = Field(default=None, alias="password")
    connection_string: Optional[str] = Field(default=None, alias="connectionString")


class MongoDB:
    """MongoDB connection manager for async operations."""
    
    _client: Optional[AsyncIOMotorClient] = None
    _database: Optional[AsyncIOMotorDatabase] = None
    _sync_client: Optional[MongoClient] = None
    _config: Optional[MongoConfig] = None
    
    @classmethod
    async def initialize(cls, config: Optional[MongoConfig] = None) -> bool:
        """
        Initialize MongoDB connection.
        
        Args:
            config: MongoDB configuration. If None, will try to get from environment.
            
        Returns:
            bool: True if connection successful, False otherwise.
        """
        try:
            # Import here to avoid circular dependency
            from utils import Logger
            
            if config is None:
                # Try to get from environment variables
                connection_string = os.getenv("MONGODB_CONNECTION_STRING")
                if connection_string:
                    config = MongoConfig(connectionString=connection_string)
                else:
                    # Use defaults
                    config = MongoConfig()
            
            cls._config = config
            
            # Build connection string if not provided
            if config.connection_string:
                connection_uri = config.connection_string
            else:
                if config.username and config.password:
                    connection_uri = f"mongodb://{config.username}:{config.password}@{config.host}:{config.port}/{config.database}"
                else:
                    connection_uri = f"mongodb://{config.host}:{config.port}"
            
            # Create async client for runtime operations
            cls._client = AsyncIOMotorClient(connection_uri)
            cls._database = cls._client[config.database]
            
            # Create sync client for data loading/migration operations
            cls._sync_client = MongoClient(connection_uri)
            
            # Test connection
            await cls._client.admin.command('ping')
            
            Logger.LogInfo(f"MongoDB connected successfully to database: {config.database}")
            return True
            
        except Exception as e:
            try:
                from utils import Logger
                Logger.LogException(e, "Failed to initialize MongoDB connection")
            except:
                print(f"Failed to initialize MongoDB: {e}")
            return False
    
    @classmethod
    async def close(cls):
        """Close MongoDB connection."""
        try:
            from utils import Logger
            
            if cls._client:
                cls._client.close()
            if cls._sync_client:
                cls._sync_client.close()
                
            Logger.LogInfo("MongoDB connection closed")
        except Exception as e:
            try:
                from utils import Logger
                Logger.LogException(e, "Error closing MongoDB connection")
            except:
                print(f"Error closing MongoDB: {e}")
    
    @classmethod
    def get_database(cls) -> AsyncIOMotorDatabase:
        """
        Get async database instance for runtime operations.
        
        Returns:
            AsyncIOMotorDatabase: The database instance.
            
        Raises:
            Exception: If MongoDB is not initialized.
        """
        if cls._database is None:
            raise Exception("MongoDB not initialized! Call MongoDB.initialize() first.")
        return cls._database
    
    @classmethod
    def get_sync_client(cls) -> MongoClient:
        """
        Get sync client for data loading/migration operations.
        
        Returns:
            MongoClient: The sync MongoDB client.
            
        Raises:
            Exception: If MongoDB is not initialized.
        """
        if cls._sync_client is None:
            raise Exception("MongoDB not initialized! Call MongoDB.initialize() first.")
        return cls._sync_client
    
    @classmethod
    def get_sync_database(cls):
        """
        Get sync database instance for data loading operations.
        
        Returns:
            Database: The sync database instance.
            
        Raises:
            Exception: If MongoDB is not initialized.
        """
        if cls._sync_client is None or cls._config is None:
            raise Exception("MongoDB not initialized! Call MongoDB.initialize() first.")
        return cls._sync_client[cls._config.database]
    
    @classmethod
    async def create_indexes(cls):
        """Create database indexes for optimal query performance."""
        try:
            from utils import Logger
            
            db = cls.get_database()
            restaurants = db.restaurants
            
            # 1. Geospatial index for location-based queries (CRITICAL for nearby search)
            await restaurants.create_index([("location", "2dsphere")])
            Logger.LogInfo("Created geospatial index on 'location'")
            
            # 2. Text index for name, category, and address search
            await restaurants.create_index([
                ("name", "text"),
                ("category", "text"),
                ("address", "text")
            ], name="text_search_index")
            Logger.LogInfo("Created text search index")
            
            # 3. Compound index for category + rating queries
            await restaurants.create_index([
                ("category", 1),
                ("rating", -1)
            ], name="category_rating_index")
            Logger.LogInfo("Created compound index on 'category' and 'rating'")
            
            # 4. Compound index for location-based filtering
            await restaurants.create_index([
                ("province", 1),
                ("district", 1),
                ("rating", -1)
            ], name="location_rating_index")
            Logger.LogInfo("Created compound index on 'province', 'district', and 'rating'")
            
            # 5. Single field index on rating for sorting
            await restaurants.create_index([("rating", -1)], name="rating_index")
            Logger.LogInfo("Created index on 'rating'")
            
            Logger.LogInfo("All MongoDB indexes created successfully")
            
        except Exception as e:
            try:
                from utils import Logger
                Logger.LogException(e, "Failed to create MongoDB indexes")
            except:
                print(f"Failed to create indexes: {e}")
    
    @classmethod
    async def drop_collection(cls, collection_name: str):
        """
        Drop a collection (use with caution!).
        
        Args:
            collection_name: Name of the collection to drop.
        """
        try:
            from utils import Logger
            
            db = cls.get_database()
            await db[collection_name].drop()
            Logger.LogInfo(f"Dropped collection: {collection_name}")
            
        except Exception as e:
            try:
                from utils import Logger
                Logger.LogException(e, f"Failed to drop collection: {collection_name}")
            except:
                print(f"Failed to drop collection: {e}")
