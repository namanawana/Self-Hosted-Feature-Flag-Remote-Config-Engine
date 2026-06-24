from fastapi import FastAPI, HTTPException,WebSocket,WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from models import FeatureFlag, ConfigVar, ConfigUpdate
from FlagStore import FlagStore
from ConfigStore import ConfigStore

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

config_store=ConfigStore()
config_store.load_configs()

class ConnectionManager:
    def __init__(self):
        self.active_connections:list[WebSocket]=[]
    async def connect(self, websocket:WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    def disconnect(self, websocket:WebSocket):
        self.active_connections.remove(websocket)
    async def broadcast(self, message:dict):
        for connection in self.active_connections:
            await connection.send_json(message)

manager=ConnectionManager()   
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)  
    try:
        while True:
            await websocket.receive_text()           
    except WebSocketDisconnect:
        manager.disconnect(websocket)
@app.get("/flags")
def get_flags():
    return list(flag_store.flags.values())

@app.post("/flags")
def create_flag(flag:FeatureFlag):
    if flag.name in flag_store.flags:
        raise HTTPException(status_code=409, detail= "flag already exists")
    
    flag_store.add_flag(flag)
    return flag 

@app.patch("/flags/{name}/toggle")
async def toggle_flag(name:str):
    if name not in flag_store.flags:
        raise HTTPException(status_code=404, detail="Flag not found")
    updated_flag = flag_store.toggle_flag(name)
    await manager.broadcast({
        "type":"flag updated",
        "flag":updated_flag.model_dump()
    })
    return updated_flag

@app.delete("/flags/{name}")
def delete_flag(name:str):
    if name not in flag_store.flags:
        raise HTTPException(status_code=404, detail="Flag not found")
    deleted_flag = flag_store.delete_flag(name)
    return{
        "message":f"Flag '{name}' deleted",
        "flag": deleted_flag
    }

@app.get("/config")
def get_configs():
    return list(config_store.configs.values())

@app.post("/config")
def create_config(config: ConfigVar):
    if config.key in config_store.configs:
        raise HTTPException(status_code=409 , detail="Config already exists")
    
    config_store.add_config(config)
    return config
@app.patch("/config/{key}")
def update_config(key: str, body: ConfigUpdate):
    if key not in config_store.configs:
        raise HTTPException(status_code=404, detail="Config not found")

    updated_config = config_store.update_config(key, body.value)
    return updated_config

@app.delete("/config/{key}")
def delete_config(key: str):
    if key not in config_store.configs:
        raise HTTPException(status_code=404, detail="Config not found")
    
    deleted = config_store.delete_config(key)
    return{
        "message":f"Config '{key}' deleted",
        "config": deleted
           }