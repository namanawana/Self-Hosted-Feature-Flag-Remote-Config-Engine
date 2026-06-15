from pydantic import BaseModel
from typing import Optional 
class FeatureFlag(BaseModel):
    name: str 
    enabled : bool 
    environment :str 
    rule_type: str
    rule_value: Optional[int]= None

class ConfigVar(BaseModel):
    key: str
    value: str
    description: Optional[str]=""

flag = FeatureFlag(name = "Dark mode", enabled=True, rule_type="beta_only ",environment="development")
print(flag)
print(flag.model_dump)