"""
AI Connection Manager - Google Gemini Client Singleton
Handles Gemini API client initialization and connection lifecycle.
"""

import os
import sys
from typing import Optional
import google.generativeai as genai
from google.generativeai import GenerativeModel

# Add parent directory to path for standalone execution
if __name__ == "__main__" or "Backend.core" not in sys.modules:
    sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

try:
    from utils import Logger
except ImportError:
    # Fallback logger for standalone execution
    class Logger:
        @staticmethod
        def info(msg): print(f"ℹ️  INFO: {msg}")
        @staticmethod
        def error(msg): print(f"❌ ERROR: {msg}")
        @staticmethod
        def warning(msg): print(f"⚠️  WARNING: {msg}")
        @staticmethod
        def success(msg): print(f"✅ SUCCESS: {msg}")


class AIClient:
    """
    Singleton manager for Google Gemini AI client.
    Ensures single model instance across application lifecycle.
    
    Features:
    - Gemini 2.5 Flash (Latest model - Dec 2024)
    - FREE tier with generous limits (1M tokens context window)
    - Best multilingual support (Vietnamese)
    - Fastest response time
    - Advanced function calling capabilities
    """
    
    _instance: Optional['AIClient'] = None
    _model: Optional[GenerativeModel] = None
    _initialized: bool = False
    _model_name: str = "gemini-2.5-flash"  # Gemini 2.5 Flash (latest stable)
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    @classmethod
    async def initialize(cls) -> None:
        """
        Initialize Gemini AI client from environment variables.
        Called once during application startup.
        
        Environment Variables:
            GEMINI_API_KEY: API key for Google Gemini
            GEMINI_MODEL: Model name (default: gemini-2.0-flash-exp)
        
        Raises:
            ValueError: If GEMINI_API_KEY not set
        """
        if cls._initialized:
            Logger.LogInfo("AIClient already initialized")
            return
        
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY environment variable not set")
        
        # Configure Gemini API
        genai.configure(api_key=api_key)
        
        # Get model name from env or use default
        cls._model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
        
        # Initialize model with generation config
        generation_config = {
            "temperature": 0.7,  # Balance between creativity and consistency
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 2048,
        }
        
        cls._model = genai.GenerativeModel(
            model_name=cls._model_name,
            generation_config=generation_config
        )
        
        cls._initialized = True
        Logger.LogInfo(f"AIClient initialized successfully with model: {cls._model_name}")
    
    @classmethod
    def get_model(cls) -> GenerativeModel:
        """
        Get the Gemini model instance.
        
        Returns:
            GenerativeModel: Active Gemini model
            
        Raises:
            RuntimeError: If client not initialized
        """
        if not cls._initialized or cls._model is None:
            raise RuntimeError("AIClient not initialized. Call AIClient.initialize() first")
        return cls._model
    
    @classmethod
    async def close(cls) -> None:
        """
        Close Gemini client connection.
        Called during application shutdown.
        
        Note: Gemini SDK doesn't require explicit connection cleanup,
        but we reset singleton state for consistency.
        """
        cls._model = None
        cls._initialized = False
        Logger.LogInfo("AIClient connection closed")
