import json
import os
import hashlib
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
    def delete_flag(self, name:str):
        if name not in self.flags:
            return None
        del self.flags[name]
        self.save_flags()
        return True
    def evaluate_flags(self, user_id: str):
        active_flags = []
        for flag in self.flags.values():
            if not flag.enabled:
                continue

            if flag.rule_type == "everyone":
                active_flags.append(flag.name)
            elif flag.rule_type == "beta_only":
                if isinstance(flag.rule_value, list) and user_id in flag.rule_value:
                    active_flags.append(flag.name)
            elif flag.rule_type == "percentage":
                if isinstance(flag.rule_value, int):
                    hash_val = int(hashlib.md5(user_id.encode()).hexdigest(), 16) % 100
                    if hash_val < flag.rule_value:
                        active_flags.append(flag.name)

        return active_flags
                