from typing import List, Dict, Any
from pydantic import BaseModel


class AIKeywordRefineInput(BaseModel):
    content: Dict[str, Any]


class AIKeywordRefineOutput(BaseModel):
    keywords: List[str]
