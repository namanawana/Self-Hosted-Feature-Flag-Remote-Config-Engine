from models import ConfigVar
from ConfigStore import ConfigStore

store = ConfigStore()
store.load_configs()

store.add_config(ConfigVar(key="welcome_message", value="Hello!", description="Shown on home screen"))
store.update_config("welcome_message", "Hey there!")
print(store.configs)