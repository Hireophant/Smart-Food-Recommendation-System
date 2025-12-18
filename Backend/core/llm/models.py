import json, os, openai
from typing import Dict, List, Optional, Tuple
from pydantic import BaseModel, Field, ValidationError, ConfigDict
from utils import Logger

class ClientInfo(BaseModel):
    """Typed information describing a model client configuration entry."""

    Name: str = Field(alias="name", description="Representative name of the client.")
    ApiKeyEnv: str = Field(alias="api_key_env", description="Environment API key name used to find API key for generating requests.")
    BaseUrl: Optional[str] = Field(default=None, alias="base_url", description="Optional base URL override.")
    Description: Optional[str] = Field(default=None, alias="description", description="Optional description of the client.")

    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

class ModelInfo(BaseModel):
    """Typed information describing a model configuration entry."""

    Name: str = Field(alias="name", description="Representative name of the model.")
    ModelName: str = Field(alias="model_name", description="The fully qualified name used by the provider.")
    ClientName: str = Field(alias="client_name", description="Name of the client that owns this model.")
    TokenLimit: Optional[int] = Field(default=None, alias="token_limit", description="Optional token limit for the model.")
    Creativity: Optional[float] = Field(default=None, alias="creativity", ge=0.0, le=1.0, description="Creativity between 0 and 1.")
    Description: Optional[str] = Field(default=None, alias="description", description="Optional description of the model.")

    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)


class ModelsConfig(BaseModel):
    """Top-level configuration describing available clients and models."""

    clients: List[ClientInfo] = Field(default_factory=list, description="Collection of configured clients.")
    models: List[ModelInfo] = Field(default_factory=list, description="Collection of configured models.")


class Models:
    """The Models class, contain static informations about a models."""
    MODELS_FILE_PATH = os.path.join('data', 'configs', 'models.json')
    """The path of the models config files."""
    
    __availableClients: Dict[str, Tuple[ClientInfo, Optional[openai.AsyncOpenAI]]] = {}
    __availableModels: Dict[str, ModelInfo] = {}
    
    @staticmethod
    def LoadModels() -> bool:
        """Load configured clients and models from disk."""
        try:
            payload = Models.__read_models_payload()
            config = ModelsConfig.model_validate(payload)
            Models.__hydrate_clients(config.clients)
            Models.__hydrate_models(config.models)
            return True
        except FileNotFoundError:
            Logger.LogError(f"Models: Config file not found at '{Models.MODELS_FILE_PATH}'.")
        except json.JSONDecodeError as exc:
            Logger.LogException(exc, "Models: Failed to decode models config")
        except ValidationError as exc:
            Logger.LogException(exc, "Models: Models config validation failed")
        except ValueError as exc:
            Logger.LogError(str(exc))
        except Exception as exc:
            Logger.LogException(exc, "Models: Failed to load models")
        return False

    @staticmethod
    def __read_models_payload() -> Dict[str, object]:
        """Read the raw models configuration payload from disk."""
        with open(Models.MODELS_FILE_PATH, 'r', encoding='utf-8') as file:
            return json.load(file)

    @staticmethod
    def __hydrate_clients(clients: List[ClientInfo]) -> None:
        """Populate in-memory client cache from configuration values."""
        Models.__availableClients.clear()
        if not clients:
            raise ValueError("Models: No client provided, must have at least 1 client!")

        for client in clients:
            if client.Name in Models.__availableClients:
                raise ValueError(f"Models: Multiple Client Info with name '{client.Name}'")
            Models.__availableClients[client.Name] = (client, None)

    @staticmethod
    def __hydrate_models(models: List[ModelInfo]) -> None:
        """Populate in-memory model cache from configuration values."""
        Models.__availableModels.clear()
        if not models:
            raise ValueError("Models: No model provided, must have at least 1 model!")

        for model in models:
            if model.Name in Models.__availableModels:
                raise ValueError(f"Models: Multiple Model Info with name '{model.Name}'")
            if model.ClientName not in Models.__availableClients:
                raise ValueError(
                    f"Models: No provided Client have name '{model.ClientName}' (from Model name '{model.Name}')"
                )
            Models.__availableModels[model.Name] = model
        
    @staticmethod
    def GetModelInfoWithName(name: str) -> Optional[ModelInfo]:
        """Get the info of a loaded model with the given name.

        Args:
            name (str): The name of the model to query.

        Returns:
            Optional[ModelInfo]: The Model Info, or None if not having (or not initialized).
        """
        return Models.__availableModels.get(name)
    
    @staticmethod
    def GetClientInfoWithName(name: str) -> Optional[ClientInfo]:
        """Get the info of a loaded client with the given name.

        Args:
            name (str): The name of the client to query.

        Returns:
            Optional[ClientInfo]: The Client Info, or None if not having (or not initialized).
        """
        entry = Models.__availableClients.get(name)
        return entry[0] if entry else None

    @staticmethod
    def GetClientWithName(name: str) -> Optional[openai.AsyncOpenAI]:
        """Get the client of a loaded client with the given name.

        Args:
            name (str): The name of the client to query.

        Returns:
            Optional[openai.OpenAI]: The client, or None if not having (or not initialized).
        """
        entry = Models.__availableClients.get(name)
        if not entry:
            return None

        client_info, client_instance = entry
        if not client_instance:
            api_key = os.getenv(client_info.ApiKeyEnv, None)
            if not api_key:
                raise EnvironmentError(f"Environment variables '{client_info.ApiKeyEnv}' not found!")
            client_instance = openai.AsyncOpenAI(
                api_key=os.getenv(client_info.ApiKeyEnv),
                base_url=client_info.BaseUrl
            )
            Models.__availableClients[name] = (client_info, client_instance)

        return client_instance

    @staticmethod
    def GetAllClients() -> List[ClientInfo]:
        """Get the informations of all loaded clients. Will return empty list if not initialized."""
        return [value[0] for value in Models.__availableClients.values()]

    @staticmethod
    def GetAllModels() -> List[ModelInfo]:
        """Get the informations of the loaded models. Will return empty list if not initialized."""
        return list(Models.__availableModels.values())