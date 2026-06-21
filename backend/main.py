from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from models import FeatureFlag
from FlagStore import FlagStore

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

flag_store=FlagStore()
flag_store.load_flags()

@app.get("/flags")
def get_flags():
    return list(flag_store.flags.values())

@app.post("/flags")
def create_flag(flag:FeatureFlag):
    if flag.name in flag_store.flags:
        raise HTTPException(status_code=409, detail= "flag already exists")
    
    flag_store.add_flag(flag)
    return flag 
    

