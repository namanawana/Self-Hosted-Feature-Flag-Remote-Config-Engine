from models import FeatureFlag
from backend.FlagStore import FlagStore

store = FlagStore()
store.load_flags()

# Add a flag
store.add_flag(FeatureFlag(name="dark_mode", enabled=False, rule_type="beta_only",environment="Development"))

# Toggle it
store.toggle_flag("dark_mode")
print(store.flags)