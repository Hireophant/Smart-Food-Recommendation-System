"""Note: This 'utils' modules is a 'shared utility module',
and can be use by both Core and Backend side.

For any side, you can 'add' new utility to this module, but please refrain
to 'modified' or 'remove' utility from this module if possible."""

import logging.handlers
import dirtyjson, logging, os, sys, datetime, queue, uuid, time
from typing import Dict, List, cast, Any, Union, Optional
from pydantic import BaseModel, ConfigDict, Field

def GetWithDefault(d: dict, key, default = None):
    """Get a value associated with a key in a dictionary, or a default value if there's no key matched."""
    return d[key] if key in d else default

def SaferJsonObjectParse(raw_json: str, bound_check: bool = False) -> Dict[str, object]:
    """A safer Json Object parse, with can ignore some typos and error.

    Args:
        raw_json (str): The raw JSON string.
        bound_check (bool, optional): If this true, will clip and assumed the Json begin at the first '{' and end at the last '}'. Defaults to False.

    Returns:
        Dict[str, object]: The result parsed dict of the Json.
    """    
    #* To made AttributedDict to dict, recursively.
    def dict_from_attributed(obj):
        if isinstance(obj, dict):
            return {k: dict_from_attributed(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [dict_from_attributed(i) for i in obj]
        else:
            return obj
    
    curr_json = raw_json[raw_json.index('{'):raw_json.rindex('}') + 1] if bound_check else raw_json
    res = dirtyjson.loads(curr_json, encoding='utf-8')
    return cast(Dict[str, object], dict_from_attributed(res))
    

class Logger:
    """The Logger class, use for logging."""
    __logger: Optional[logging.Logger] = None
    
    __log_queue: Optional[queue.Queue] = None
    __queue_handler: Optional[logging.handlers.QueueHandler] = None
    __queue_listener: Optional[logging.handlers.QueueListener] = None    
    
    @staticmethod
    def Initialize():
        """Initialize the Logger."""
        formatter = logging.Formatter("[%(asctime)s] %(name)s - %(levelname)s: %(message)s",
                                        datefmt="%d-%m-%Y %H:%M:%S")
        
        logging_config = Config.Get().Logging
        dir_name = os.path.join(os.getcwd(), logging_config.File.Folder)
        if not os.path.isdir(dir_name):
            os.makedirs(dir_name, exist_ok=True)
            
        Logger.__log_queue = queue.Queue()
        Logger.__queue_handler = logging.handlers.QueueHandler(Logger.__log_queue)
        
        Logger.__queue_listener = logging.handlers.QueueListener(Logger.__log_queue, Logger.__queue_handler)
        Logger.__queue_listener.start()
        
        Logger.__logger = logging.Logger(logging_config.Name)
        Logger.__logger.addHandler(Logger.__queue_handler)
        
        if logging_config.Console.Enabled:
            console_handler = logging.StreamHandler(sys.stderr)
            console_handler.setLevel(logging.DEBUG if logging_config.Console.DebugMode else logging.INFO)
            console_handler.setFormatter(formatter)
            Logger.__logger.addHandler(console_handler)
            
        if logging_config.File.Enabled:
            curr_time = datetime.datetime.now()
            file_name = curr_time.strftime(logging_config.File.NameFormat)
            
            file_handler = logging.FileHandler(os.path.join(dir_name, file_name), encoding='utf-8')
            file_handler.setLevel(logging.DEBUG if logging_config.File.DebugMode else logging.INFO)
            file_handler.setFormatter(formatter)
            Logger.__logger.addHandler(file_handler)
        
    @staticmethod
    def LogDebug(msg: str):
        """Log a Debug message."""
        if Logger.__logger:
            Logger.__logger.debug(msg)

    @staticmethod
    def LogInfo(msg: str):
        """Log an Informative message."""
        if Logger.__logger:
            Logger.__logger.info(msg)

    @staticmethod
    def LogWarning(msg: str):
        """Log a Warning message."""
        if Logger.__logger:
            Logger.__logger.warning(msg)

    @staticmethod
    def LogError(msg: str):
        """Log an Error message."""
        if Logger.__logger:
            Logger.__logger.error(msg)

    @staticmethod
    def LogException(ex: Exception, msg: Optional[str] = None):
        """Log an Exception with the messages."""
        if Logger.__logger:
            exception_type = type(ex).__name__
            exception_message = f"{msg + ' - ' if msg else ''}{exception_type}: {str(ex)}"
            Logger.__logger.error(exception_message)


class LoggingConsoleConfig(BaseModel):
    """Console logging configuration."""
    model_config = ConfigDict(extra='ignore', populate_by_name=True)
    Enabled: bool = Field(default=False, alias='enabled')
    DebugMode: bool = Field(default=False, alias='debugMode')


class LoggingFileConfig(BaseModel):
    """File logging configuration."""
    model_config = ConfigDict(extra='ignore', populate_by_name=True)
    Enabled: bool = Field(default=False, alias='enabled')
    DebugMode: bool = Field(default=False, alias='debugMode')
    Folder: str = Field(default=os.path.join('data', 'logs'), alias='folder')
    NameFormat: str = Field(default="%Y%m%d-%H%M%S.log", alias='nameFormat')


class LoggingConfig(BaseModel):
    """Top-level logging configuration."""
    model_config = ConfigDict(extra='ignore', populate_by_name=True)
    Name: str = Field(default="Backend", alias='name')
    Console: LoggingConsoleConfig = Field(default_factory=LoggingConsoleConfig, alias='console')
    File: LoggingFileConfig = Field(default_factory=LoggingFileConfig, alias='file')

class SecurityConfig(BaseModel):
    """Top-level security configuration."""
    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    JWTAlgorithm: str = Field(default="HS256", alias="jwtAlgorithm")

class MongoDBConfig(BaseModel):
    """MongoDB configuration."""
    model_config = ConfigDict(extra="ignore", populate_by_name=True)
    Host: str = Field(default="localhost", alias="host")
    Port: int = Field(default=27017, alias="port")
    Database: str = Field(default="smart_food_db", alias="database")
    Username: Optional[str] = Field(default=None, alias="username")
    Password: Optional[str] = Field(default=None, alias="password")
    ConnectionString: Optional[str] = Field(default=None, alias="connectionString")

class ApplicationConfig(BaseModel):
    """Global application configuration."""
    model_config = ConfigDict(extra='ignore', populate_by_name=True)
    Logging: LoggingConfig = Field(default_factory=LoggingConfig, alias='logging')
    Security: SecurityConfig = Field(default_factory=SecurityConfig, alias='security')
    MongoDB: MongoDBConfig = Field(default_factory=MongoDBConfig, alias='mongodb')

class Config:
    """The Config class, contain the static configuration of the application."""
    CONFIG_FILE_PATH = os.path.join('data', 'configs', 'general.json')
    """The path of the global config file."""
    
    __model: Optional[ApplicationConfig] = None
    
    @staticmethod
    def Initialize() -> bool:
        """Initialize the Config class by loading from a config file."""
        try:
            with open(Config.CONFIG_FILE_PATH, 'r', encoding='utf-8') as f:
                parsed = SaferJsonObjectParse(f.read())
                Config.__model = ApplicationConfig.model_validate(parsed)
            return True
        except Exception:
            return False
        
    @staticmethod
    def SaveConfig() -> bool:
        """Save the current Config to the config file. Will not save if not initialized."""
        if not Config.__model:
            return False
        try:
            with open(Config.CONFIG_FILE_PATH, 'w', encoding='utf-8') as f:
                f.write(Config.__model.model_dump_json(indent=4, by_alias=True))
            return True
        except Exception as e:
            Logger.LogException(e, "Config: Failed to save config")
            return False
    
    @staticmethod
    def Get() -> ApplicationConfig:
        """Return the strongly typed configuration model."""
        if not Config.__model:
            raise Exception("The Config didn't initialized!")
        return Config.__model

    @staticmethod
    def Reload(data: Optional[Dict[str, Any]] = None) -> bool:
        """Reload configuration from provided data or disk."""
        try:
            if data is None:
                with open(Config.CONFIG_FILE_PATH, 'r', encoding='utf-8') as f:
                    data = SaferJsonObjectParse(f.read())
            Config.__model = ApplicationConfig.model_validate(data)
            return True
        except Exception as e:
            Logger.LogException(e, "Config: Failed to reload config")
            return False