from typing import List, Optional, Dict, Any, Literal
from dataclasses import dataclass, field

@dataclass
class FunctionParams:
	"""Minimal JSON Schema model used by  function calling.
	"""

	Type: str = "object"
	Properties: Dict[str, Any] = field(default_factory=dict)
	Required: List[str] = field(default_factory=list)
	Description: Optional[str] = None

@dataclass
class Function:
	""" function tool definition."""
 
	Name: str
	Description: Optional[str] = None
	Parameters: FunctionParams = field(default_factory=FunctionParams)
	Strict: Optional[bool] = None

@dataclass
class ToolDefinition:
	""" tool wrapper: `{type: 'function', function: {...}}`."""

	Function: Function
	Type: Literal["function"] = "function"