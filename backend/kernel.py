from contextlib import asynccontextmanager
import json
import asyncio  # ← Keep this one (line 3)
import urllib.parse
import ollama
import subprocess
import os
import signal
import psutil
import re
import time
from fastapi import FastAPI, Request, Depends, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
import logging

# ============================================================================
# ZERO-DRIFT & PHASE IMPORTS
# ============================================================================
from workers.brain_worker import BrainWorker
from workers.eyes_worker import EyesWorker
from workers.hands_worker import HandsWorker
from workers.memory_worker import MemoryWorker
from workers.system_worker import SystemWorker
from ps1_integration import router as ps1_router
from zero_drift_core import constitution, ZeroDriftConstitution
from drift_detector import detector, ZeroDriftDetector
from models import ChatMessage, User
from database import init_db, close_db, get_db
from auth import create_session_id, create_access_token, verify_token, get_current_session
from services import ChatService, UserService, WorkerLogService, HealthCheckService
from middleware import setup_logging, RequestLoggingMiddleware, ErrorHandlingMiddleware
from constitutional_wrapper import ZeroDriftConstitution as LegacyConstitution
from invariant_layer import ExecutionGuard, InterceptionEngine, invariant_registry
from constitutional_audit import ConstitutionalAudit

logger = logging.getLogger(__name__)

def sse(payload: dict) -> str:
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"

# ============================================================================ 
# MCP MANAGER
# ============================================================================
class MCPServer:
    def __init__(self, name: str, script_path: str):
        self.name = name
        self.script_path = script_path
        self.process = None

    async def start(self):
        self.process = await asyncio.create_subprocess_exec(
            "python", self.script_path,
            stdin=asyncio.subprocess.PIPE, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        )
        return self

    async def call(self, method: str, params: dict = None):
        if not self.process or not self.process.stdin: return {"error": f"MCP server {self.name} not running"}
        try:
            request_data = {"method": method, "params": params or {}}
            self.process.stdin.write((json.dumps(request_data) + "\n").encode())
            await self.process.stdin.drain()
            response = await asyncio.wait_for(self.process.stdout.readline(), timeout=15)
            if not response: return {"error": "No response from MCP server"}
            try: return json.loads(response.decode().strip())
            except json.JSONDecodeError: return {"error": "Invalid JSON from MCP server"}
        except Exception as e: return {"error": str(e)}

class MCPManager:
    def __init__(self): self.servers = {}
    async def register(self, name: str, script_path: str):
        server = MCPServer(name, script_path)
        await server.start()
        self.servers[name] = server
        logger.info(f"[OK] MCP Server '{name}' started")
        return server
    async def call(self, server_name: str, method: str, params: dict = None):
        server = self.servers.get(server_name)
        if not server: return {"error": f"MCP server '{server_name}' not found"}
        return await server.call(method, params)

# ============================================================================ 
# WORKER BASE & REGISTRY
# ============================================================================
class Worker:
    def __init__(self, name: str, description: str, model: str = None):
        self.name = name; self.description = description; self.model = model
    async def process(self, task: str, model: str = None) -> dict:
        return {"content": f"Worker {self.name} processed: {task}"}

class WorkerRegistry:
    def __init__(self): self.workers = {}
    def register(self, worker: Worker):
        self.workers[worker.name] = worker
        logger.info(f"[OK] Worker '{worker.name}' registered")
    def get(self, name: str): return self.workers.get(name)

# ============================================================================ 
# ORCHESTRATOR & VRAM MANAGER (UPDATED HYBRID ENGINE)
# ============================================================================
class IntelligentRouter:
    def __init__(self):
        self.model = "llama3.2:latest"
        self.patterns = {
            'code':[r'\bcode\b', r'\bscript\b', r'\bpython\b', r'\breact\b', r'\bpowershell\b', r'\bbash\b', r'\bdebug\b'],
            'search':[r'\bsearch net\b', r'\bgoogle\b', r'\blook up\b', r'\bnews\b', r'\bwho is\b', r'\bweb search\b', r'\bonline\b', r'\blatest\b', r'\bcurrent\b', r'\btoday\b', r'\bprice\b'],
            'files':[r'\bsearch pc\b', r'\bfind file\b', r'\bjpg\b', r'\bpng\b', r'\bpdf\b', r'\bdocument\b', r'\blocated\b']
        }

    async def route(self, task: str) -> str:
        task_lower = task.lower().strip()
        
        # 1. System Commands
        if task_lower.startswith('/'): 
            return 'system'
        
        # 2. Hard Overrides (Guarantees perfect routing for explicit commands)
        if any(kw in task_lower for kw in["search pc", "find file", "local drive", ".pdf", ".jpg", ".png"]):
            return 'files'
            
        # 🔥 FIX: Force any query with "online", "latest", or "web" directly to the Eyes/Search worker
        if any(kw in task_lower for kw in["search net", "web search", "google", "online", "internet", "latest", "news", "2026", "price"]):
            return 'search'

        # 3. Fast Regex Match
        for worker, patterns in self.patterns.items():
            if any(re.search(p, task_lower) for p in patterns): 
                return worker
            
        # 4. LLM Intent Detection (Fallback)
        try:
            prompt = """Analyze the user task and output ONLY ONE WORD (brain, code, search, files):
            - brain: general questions, math, logic, advice
            - code: programming, scripts, debugging, terminal
            - search: internet/web search, current events, online prices, news, anything requiring live data
            - files: local PC files, documents, drives
            Task: """ + task
            
            response = await asyncio.to_thread(
                ollama.chat, 
                model=self.model, 
                messages=[{"role": "user", "content": prompt}], 
                options={"temperature": 0.0, "num_predict": 5}
            )
            res_text = response['message']['content'].strip().lower()
            for w in ['brain', 'code', 'search', 'files']:
                if w in res_text: return w
        except Exception as e: 
            logger.error(f"Router LLM Error: {e}")
            
        return 'brain'

class GPUVRAMManager:
    def __init__(self):
        self.active_model = None
        # 🔥 TWEAK: Changed the search model to llama3.2 because llava is a Vision model 
        # and struggles heavily with text-based web search intent generation.
        self.models = { 'brain': 'llama3.2:latest', 'search': 'llama3.2:latest', 'code': 'qwen2.5-coder:14b' }

    async def optimize(self, target_worker: str, explicitly_requested_model: str = None):
        target_model = explicitly_requested_model or self.models.get(target_worker)
        if not target_model: return
        
        if self.active_model and self.active_model != target_model:
            logger.info(f"💾 VRAM: Offloading[{self.active_model}] from GPU...")
            try: 
                await asyncio.to_thread(ollama.generate, model=self.active_model, prompt='', keep_alive=0)
            except Exception: 
                pass
                
        self.active_model = target_model

smart_router = IntelligentRouter()
vram_manager = GPUVRAMManager()

# ============================================================================ 
# PYDANTIC MODELS
# ============================================================================
class TaskRequest(BaseModel):
    task: str = Field(..., min_length=1, max_length=10000)
    worker: str = Field(default="auto", pattern="^(auto|brain|code|search|files|system)$")
    model: Optional[str] = None
    session_id: Optional[str] = None

class SessionResponse(BaseModel):
    session_id: str
    token: str

# ============================================================================ 
# SYSTEM INITIALIZATION
# ============================================================================
setup_logging(log_level="INFO")
app = FastAPI(title="REZ HIVE Kernel")
app.add_middleware(RequestLoggingMiddleware)
app.add_middleware(ErrorHandlingMiddleware)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
app.include_router(ps1_router, prefix="/api/v1")

mcp_manager = MCPManager()
workers = WorkerRegistry()

# 🎯 FORCE EXPLICIT ID MAPPING
# This ensures the backend Python workers perfectly match the UI and Router IDs
brain = BrainWorker(); brain.name = 'brain'; workers.register(brain)
eyes = EyesWorker(); eyes.name = 'search'; workers.register(eyes)
hands = HandsWorker(); hands.name = 'code'; workers.register(hands)
memory = MemoryWorker(); memory.name = 'files'; workers.register(memory)
system = SystemWorker(); system.name = 'system'; workers.register(system)

zero_drift_constitution = constitution
legacy_constitution = LegacyConstitution()
execution_guard = ExecutionGuard(invariant_registry)
interception = InterceptionEngine(invariant_registry)
audit = ConstitutionalAudit()

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    asyncio.create_task(detector.start_monitoring())
    yield
    await close_db()
    for name, server in mcp_manager.servers.items():
        if server.process:
            try: server.process.terminate(); await asyncio.wait_for(server.process.wait(), timeout=5.0)
            except Exception: pass
    detector.running = False
app.router.lifespan_context = lifespan

# ============================================================================ 
# LIVE HARDWARE TELEMETRY STREAM (PHASE 5)
# ============================================================================
async def generate_telemetry():
    """Streams live hardware data to the frontend UI"""
    last_net_io = psutil.net_io_counters()
    last_time = time.time()
    
    while True:
        try:
            # Calculate CPU & RAM
            cpu_percent = psutil.cpu_percent(interval=0.1)
            ram = psutil.virtual_memory()
            ram_percent = ram.percent
            
            # Calculate Network Speeds
            current_net_io = psutil.net_io_counters()
            current_time = time.time()
            time_delta = current_time - last_time
            
            if time_delta > 0:
                down_speed = (current_net_io.bytes_recv - last_net_io.bytes_recv) / time_delta / (1024 * 1024) # MB/s
                up_speed = (current_net_io.bytes_sent - last_net_io.bytes_sent) / time_delta / (1024 * 1024) # MB/s
            else:
                down_speed, up_speed = 0.0, 0.0
                
            last_net_io = current_net_io
            last_time = current_time
            
            # Fake GPU Temp logic (since python needs pynvml for real GPU temp, simulating for aesthetic)
            gpu_temp = 45 + (cpu_percent * 0.3)
            
            payload = {
                "cpu": round(cpu_percent, 1),
                "ram": round(ram_percent, 1),
                "networkDown": round(down_speed, 2),
                "networkUp": round(up_speed, 2),
                "gpuTemp": round(gpu_temp, 1)
            }
            yield sse(payload)
            await asyncio.sleep(1.5) # Send update every 1.5 seconds
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Telemetry error: {e}")
            await asyncio.sleep(2)

@app.get("/kernel/telemetry")
async def kernel_telemetry(request: Request):
    return StreamingResponse(generate_telemetry(), media_type="text/event-stream")

# ============================================================================ 
# AI GENERATION STREAM
# ============================================================================
async def format_response_for_streaming(result: dict, worker_name: str) -> str:
    if "error" in result: return result.get("error", "Unknown error")
    if "content" in result: return result["content"]
    elif "code" in result: return f"```{'python' if worker_name == 'code' else 'text'}\n{result['code']}\n```"
    elif "files" in result: return "**Found files:**\n" + "\n".join(f"- {f}" for f in result["files"]) if isinstance(result["files"], list) else str(result["files"])
    elif "results" in result:
        if isinstance(result["results"], list):
            return "**Search Results:**\n" + "".join(f"{i}. {r.get('title', 'Result')} - {r.get('snippet', '')}\n" if isinstance(r, dict) else f"{i}. {str(r)}\n" for i, r in enumerate(result["results"][:5], 1))
        return str(result["results"])
    else: return str(result)

async def generate_stream(task: str, worker_name: str = "auto", model: str = None, session_id: str = None, db: AsyncSession = Depends(get_db)):
    try:
        if worker_name == "auto" or not worker_name:
            worker_name = await smart_router.route(task)
            logger.info(f"🤖 Auto-Router dynamically selected: [{worker_name.upper()}]")

        await vram_manager.optimize(worker_name, model)
        ruling = zero_drift_constitution.validate_task(task, worker_name, session_id or "anonymous")
        
        if ruling["verdict"] == "denied":
            yield sse({"error": f"⚠️ Constitutional violation: {ruling['reason']}", "constitutional": True})
            yield sse({"status": "failed"})
            return
        
        yield sse({"status": "started", "worker": worker_name, "constitutional": ruling["verdict"]})
        
        if session_id and db:
            chat_service = ChatService(db)
            await chat_service.save_message(session_id=session_id, role="user", content=task, worker=worker_name, model=model or "unknown")
        
        worker = workers.get(worker_name)
        if not worker:
            yield sse({"error": f"Worker '{worker_name}' not found", "status": "failed"})
            return
        
        try: result = await asyncio.wait_for(worker.process(task, model=model), timeout=60)
        except asyncio.TimeoutError:
            yield sse({"error": f"Worker '{worker_name}' timed out", "status": "failed"})
            return
        
        formatted_content = await format_response_for_streaming(result, worker_name)
        yield sse({"content": formatted_content, "status": "complete"})
        
    except Exception as e:
        logger.error(f"Stream error: {e}")
        yield sse({"error": f"Internal error: {str(e)}", "status": "failed"})

# ============================================================================ 
# STANDARD ENDPOINTS
# ============================================================================
@app.post("/auth/session", response_model=SessionResponse)
async def create_session(db: AsyncSession = Depends(get_db)):
    session_id = create_session_id()
    token = create_access_token(session_id)
    user_service = UserService(db)
    await user_service.get_or_create_user(session_id)
    return SessionResponse(session_id=session_id, token=token)

@app.post("/kernel/stream")
async def kernel_stream(request: Request, db: AsyncSession = Depends(get_db)):
    try: data = await request.json()
    except: raise HTTPException(status_code=400, detail="Invalid JSON")
    return StreamingResponse(generate_stream(data.get("task", ""), data.get("worker", "auto"), data.get("model"), data.get("session_id") or request.headers.get("X-Session-ID"), db), media_type="text/event-stream")

@app.get("/chat/{session_id}/history")
async def get_chat_history(session_id: str, limit: int = 50, db: AsyncSession = Depends(get_db)):
    chat_service = ChatService(db)
    messages = await chat_service.get_chat_history(session_id, limit=min(limit, 100))
    return {"session_id": session_id, "count": len(messages), "messages":[{"role": msg.role, "content": msg.content, "worker": msg.worker, "model": msg.model, "timestamp": msg.created_at.isoformat() if msg.created_at else None} for msg in messages]}

@app.post("/chat/{session_id}/clear")
async def clear_chat_history(session_id: str, db: AsyncSession = Depends(get_db)):
    chat_service = ChatService(db)
    await chat_service.clear_session_chat(session_id)
    return {"status": "cleared"}

@app.get("/health")
async def health_check(): return {"status": "healthy"}

# ----------------------------------------------------------------------------
# /workers endpoint - COMPLETE VERSION
# ----------------------------------------------------------------------------
@app.get("/workers")
async def list_workers():
    """List available workers"""
    workers_info = []
    for name, worker in workers.workers.items():
        workers_info.append({
            "name": name,
            "description": worker.description,
            "model": worker.model if hasattr(worker, 'model') else "unknown",
            "status": "available"
        })
    return {"workers": workers_info, "count": len(workers_info)}
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)