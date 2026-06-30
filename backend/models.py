from pydantic import BaseModel
from typing import Optional, Union, List
class FeatureFlag(BaseModel):
    name: str 
    enabled : bool 
    environment :str 
    rule_type: str
    rule_value: Optional[Union[List[str], int]] = None
    archived: bool = False

class ConfigVar(BaseModel):
    key: str
    value: str
    description: Optional[str]=""

class ConfigUpdate(BaseModel):
    value: str

class Evaluate(BaseModel):
    user_id : str
    