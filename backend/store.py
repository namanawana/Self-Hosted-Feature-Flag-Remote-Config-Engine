import json
import os
from models import FeatureFlag, ConfigVar
FLAGS_FILE = "flags.json"
CONFIG_FILE = "config.json"
class FlagStore:
    def __init__(self):
        self.flags={} 
        self.load_flags()
    def load_flags(self):
        if not os.path.exists(FLAGS_FILE):
            self.flags={}
            return
        with open(FLAGS_FILE , "r") as f:
            data= json.load(f)   

        self.flags = {
            item["name"]: FeatureFlag(**item) for item in data
        }

    def save_flags(self):
        data=[flag.model_dump() for flag in self.flags.values()]
        with open(FLAGS_FILE,"w")as f:
            json.dump(data,f,indent = 2)

    def add_flag(self, flag: FeatureFlag):
        self.flags[flag.name]=flag
        self.save_flags()
    def toggle_flag(self, name:str):
        if name not in self.flags:
            return None
        self.flags[name].enabled= not self.flags[name].enabled   
        self.save_flags()
        return self.flags[name]