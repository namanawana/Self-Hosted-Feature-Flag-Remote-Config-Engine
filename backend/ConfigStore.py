import json
import os
from models import ConfigVar
CONFIG_FILE = "config.json"
class ConfigStore :
    def __init__(self) :
        self.config={}
        self.load_configs()
        return
    def load_configs(self):
        if not os.path.exists(CONFIG_FILE):
            self.configs = {}
            return
        with open(CONFIG_FILE, "r") as f:
            data=json.load(f)
        self.configs={
            item["key"]:ConfigVar(**item) for item in data
        }    
    def save_configs(self):
        data = [config.model_dump() for config in self.configs.values()]
        with open(CONFIG_FILE, "w") as f:
            json.dump(data, f, indent=2)            
    def add_config(self, config: ConfigVar):
        self.configs[config.key]= config
        self.save_configs()
    def update_config(self, key:str, value:str):  
        if key not in self.configs:
            return None
        self.configs[key].value=value
        self.save_configs()
        return self.configs[key]
    def delete_config(self, key:str):
        if key not in self.configs:
            return None
        deleted = self.configs.pop(key)
        self.save_configs()
        return deleted
    