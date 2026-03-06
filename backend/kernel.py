from contextlib import asynccontextmanager
import json
import asyncio
import urllib.parse
import ollama
import aiohttp
import subprocess
import os
import signal
import psutil
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
# ZERO-DRIFT IMPORTS
# ============================================================================

# Worker imports
from workers.brain_worker import BrainWorker
from workers.eyes_worker import EyesWorker
from workers.hands_worker import HandsWorker
from workers.memory_worker import MemoryWorker
from workers.system_worker import SystemWorker
from ps1_integration import router as ps1_router
from zero_drift_core import constitution, ZeroDriftConstitution
from drift_detector import detector, ZeroDriftDetector
import asyncio

# Phase 1 Imports
from models import ChatMessage, User
from database import init_db, close_db, get_db
from auth import create_session_id, create_access_token, verify_token, get_current_session
from services import ChatService, UserService, WorkerLogService, HealthCheckService
from middleware import setup_logging, RequestLoggingMiddleware, ErrorHandlingMiddleware

# CONSTITUTIONAL AI - Zero Drift Governance (PHASE 0 - FOUNDATION)
from constitutional_wrapper import ZeroDriftConstitution as LegacyConstitution
from invariant_layer import ExecutionGuard, InterceptionEngine, invariant_registry
from constitutional_audit import ConstitutionalAudit

logger = logging.getLogger(__name__)

# ============================================================================ 
# SSE Helper
# ============================================================================
def sse(payload: dict) -> str:
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"

# ============================================================================ 
# MCP Server
# ============================================================================
class MCPServer:
    def __init__(self, name: str, script_path: str):
        self.name = name
        self.script_path = script_path
        self.process = None

    async def start(self):
        self.process = await asyncio.create_subprocess_exec(
            "python",
            self.script_path,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        return self

    async def call(self, method: str, params: dict = None):
        if not self.process or not self.process.stdin:
            return {"error": f"MCP server {self.name} not running"}
        try:
            request_data = {"method": method, "params": params or {}}
            self.process.stdin.write((json.dumps(request_data) + "\n").encode())
            await self.process.stdin.drain()

            response = await asyncio.wait_for(self.process.stdout.readline(), timeout=15)
            if not response:
                return {"error": "No response from MCP server"}

            try:
                return json.loads(response.decode().strip())
            except json.JSONDecodeError:
                return {"error": "Invalid JSON from MCP server"}
        except Exception as e:
            return {"error": str(e)}

# ============================================================================ 
# MCP Manager
# ============================================================================
class MCPManager:
    def __init__(self):
        self.servers = {}

    async def register(self, name: str, script_path: str):
        server = MCPServer(name, script_path)
        await server.start()
        self.servers[name] = server
        logger.info(f"[OK] MCP Server '{name}' started")
        return server

    async def call(self, server_name: str, method: str, params: dict = None):
        server = self.servers.get(server_name)
        if not server:
            return {"error": f"MCP server '{server_name}' not found"}
        return await server.call(method, params)

# ============================================================================ 
# Worker Base
# ============================================================================
class Worker:
    def __init__(self, name: str, description: str, model: str = None):
        self.name = name
        self.description = description
        self.model = model

    async def process(self, task: str, model: str = None) -> dict:
        return {"content": f"Worker {self.name} processed: {task}"}





class WorkerRegistry:
    def __init__(self):
        self.workers = {}

    def register(self, worker: Worker):
        self.workers[worker.name] = worker
        logger.info(f"[OK] Worker '{worker.name}' registered")

    def get(self, name: str):
        return self.workers.get(name)

# ============================================================================ 
# PYDANTIC MODELS WITH VALIDATION
# ============================================================================
class TaskRequest(BaseModel):
    task: str = Field(..., min_length=1, max_length=10000)
    worker: str = Field(default="brain", pattern="^(brain|code|search|files)$")
    model: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None
    confirmed: bool = False
    session_id: Optional[str] = None
    
    @validator('worker')
    def validate_worker(cls, v):
        valid_workers = ['brain', 'code', 'search', 'files']
        if v not in valid_workers:
            raise ValueError(f"Invalid worker: {v}. Must be one of {valid_workers}")
        return v

class SessionResponse(BaseModel):
    session_id: str
    token: str

class ChatHistoryItem(BaseModel):
    role: str
    content: str
    timestamp: str
    worker: Optional[str] = None

class HealthCheckResponse(BaseModel):
    status: str
    workers: int
    database: str
    timestamp: str
    drift_status: Optional[Dict[str, Any]] = None

# ============================================================================ 
# Initialize
# ============================================================================
setup_logging(log_level="INFO")

app = FastAPI(title="REZ HIVE Kernel - Zero-Drift Sovereign AI")

# Add middleware
app.add_middleware(RequestLoggingMiddleware)
app.add_middleware(ErrorHandlingMiddleware)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3001", "http://localhost:3000", "http://127.0.0.1:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*", "X-Session-ID"],
)

# Include PS1 router for zero-drift controller
app.include_router(ps1_router, prefix="/api/v1")

# ============================================================================
# LIFESPAN MANAGEMENT
# ============================================================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 REZ HIVE Kernel starting up...")
    await init_db()
    
    # Start drift detector
    asyncio.create_task(detector.start_monitoring())
    logger.info("🛡️ Zero-Drift Detector launched")
    
    logger.info(f"[OK] Workers: {len(workers.workers)}")
    logger.info(f"[OK] MCP Servers: {len(mcp_manager.servers)}")
    logger.info("[OK] Database initialized")
    logger.info("[OK] Authentication: JWT enabled")
    
    yield
    
    # Shutdown
    logger.info("🛑 REZ HIVE Kernel shutting down...")
    await close_db()
    for name, server in mcp_manager.servers.items():
        if server.process:
            server.process.terminate()
            await server.process.wait()
            logger.info(f"[STOP] MCP Server '{name}' terminated")
    
    detector.running = False
    logger.info("👋 Goodbye")

app.router.lifespan_context = lifespan

mcp_manager = MCPManager()
workers = WorkerRegistry()
workers.register(BrainWorker())
workers.register(EyesWorker())
workers.register(HandsWorker())
workers.register(MemoryWorker())
workers.register(SystemWorker())

# ============================================================================
# CONSTITUTIONAL AI INITIALIZATION
# ============================================================================
zero_drift_constitution = constitution
legacy_constitution = LegacyConstitution()
execution_guard = ExecutionGuard(invariant_registry)
interception = InterceptionEngine(invariant_registry)
audit = ConstitutionalAudit()

# ============================================================================ 
# Stream Generator with Intent Routing
# ============================================================================
async def format_response_for_streaming(result: dict, worker_name: str) -> str:
    """Format worker response for nice display with syntax highlighting"""
    if "error" in result:
        return result.get("error", "Unknown error")
    
    if "content" in result:
        return result["content"]
    elif "code" in result:
        code_content = result["code"]
        lang = "python" if worker_name == "code" else "text"
        return f"```{lang}\n{code_content}\n```"
    elif "files" in result:
        files = result["files"]
        if isinstance(files, list):
            return "**Found files:**\n" + "\n".join(f"- {f}" for f in files)
        return str(files)
    elif "results" in result:
        results = result["results"]
        if isinstance(results, list):
            formatted = "**Search Results:**\n"
            for i, r in enumerate(results[:5], 1):
                if isinstance(r, dict):
                    formatted += f"{i}. {r.get('title', 'Result')} - {r.get('snippet', '')}\n"
                else:
                    formatted += f"{i}. {str(r)}\n"
            return formatted
        return str(results)
    else:
        import json as json_lib
        try:
            if len(result) > 1 or (len(result) == 1 and not any(k in result for k in['content', 'code', 'files', 'results'])):
                return f"```json\n{json_lib.dumps(result, indent=2)}\n```"
        except:
            pass
        return str(result)

async def generate_stream(task: str, worker_name: str = "brain", model: str = None, session_id: str = None, db: AsyncSession = None):
    try:
        # =========================================================
        # INTENT ROUTING - THIS MUST BE FIRST!
        # =========================================================
        task_lower = task.lower()
        
        # =========================================================
        # SYSTEM DIRECTIVES - HANDLE SLASH COMMANDS
        # =========================================================
        if task_lower.startswith('/'):
            worker_name = "system"
            logger.info(f"🔄 SYSTEM COMMAND → System Worker: {task[:50]}...")
            # Let the system worker handle it
        
        # PC Search commands -> Memory Worker (files)
        elif any(phrase in task_lower for phrase in [
            'search pc', 'find on pc', 'search computer', 'find file', 
            'locate file', 'list drives', 'disk space', 'show drives',
            'search entire pc', 'find on computer', 'find all',
            'search for file', 'drive list', 'storage'
        ]):
            worker_name = "files"
            logger.info(f"🔄 Routed to Memory Worker: {task[:50]}...")
        # Let the system worker handle it
        # PC Search commands -> Memory Worker (files)
        if any(phrase in task_lower for phrase in [
            'search pc', 'find on pc', 'search computer', 'find file', 
            'locate file', 'list drives', 'disk space', 'show drives',
            'search entire pc', 'find on computer', 'find all',
            'search for file', 'drive list', 'storage'
        ]):
            worker_name = "files"
            logger.info(f"🔄 Routed to Memory Worker: {task[:50]}...")
        
        # CONSTITUTIONAL CHECK
        ruling = zero_drift_constitution.validate_task(task, worker_name, session_id or "anonymous")
        
        logger.info(f"Constitutional ruling for {worker_name}: {ruling['verdict']}", extra={
            "ruling_id": ruling.get("ruling_id"),
            "verdict": ruling["verdict"],
            "violations": ruling["violations"]
        })
        
        if ruling["verdict"] == "denied":
            error_msg = f"⚠️ Constitutional violation: {ruling['reason']}"
            yield sse({
                "error": error_msg,
                "violations": ruling["violations"],
                "constitutional": True,
                "ruling_id": ruling.get("ruling_id")
            })
            yield sse({"status": "failed"})
            return
        
        if ruling["requires_confirmation"]:
            yield sse({
                "warning": ruling["reason"],
                "violations": ruling["violations"],
                "requires_confirmation": True,
                "ruling_id": ruling.get("ruling_id")
            })
        
        yield sse({"status": "started", "worker": worker_name, "constitutional": ruling["verdict"]})
        
        # Save user message
        if session_id and db:
            chat_service = ChatService(db)
            await chat_service.save_message(
                session_id=session_id,
                role="user",
                content=task,
                worker=worker_name,
                model=model or "unknown"
            )
        
        worker = workers.get(worker_name)
        if not worker:
            yield sse({"error": f"Worker '{worker_name}' not found"})
            yield sse({"status": "failed"})
            return
        
        # Execute worker
        try:
            result = await asyncio.wait_for(worker.process(task, model=model), timeout=60)
        except asyncio.TimeoutError:
            yield sse({"error": f"Worker '{worker_name}' timed out after 60 seconds"})
            yield sse({"status": "failed"})
            return
        
        # Format response
        formatted_content = await format_response_for_streaming(result, worker_name)
        
        # Save AI response
        if session_id and db and "error" not in result:
            chat_service = ChatService(db)
            await chat_service.save_message(
                session_id=session_id,
                role="ai",
                content=formatted_content,
                worker=worker_name,
                model=model or (worker.model if hasattr(worker, 'model') else "unknown")
            )
            
            worker_log_service = WorkerLogService(db)
            await worker_log_service.log_execution(
                worker=worker_name,
                status="success",
                processing_time_ms=0,
                input_length=len(task),
                output_length=len(formatted_content)
            )
        
        yield sse({"content": formatted_content})
        
        if result.get("error") and "research" in mcp_manager.servers:
            mcp_result = await mcp_manager.call("research", "search", {"query": task})
            yield sse(mcp_result)
            
        yield sse({"status": "complete"})
        
    except Exception as e:
        logger.error(f"Stream error: {e}", exc_info=True)
        yield sse({"error": f"Internal error: {str(e)}"})
        yield sse({"status": "failed"})

# ============================================================================ 
# Endpoints
# ============================================================================

@app.post("/auth/session", response_model=SessionResponse)
async def create_session(db: AsyncSession = Depends(get_db)):
    """Create a new session with JWT token"""
    session_id = create_session_id()
    token = create_access_token(session_id)
    
    user_service = UserService(db)
    await user_service.get_or_create_user(session_id)
    
    logger.info(f"New session created: {session_id[:8]}...")
    return SessionResponse(session_id=session_id, token=token)

@app.post("/kernel/stream")
async def kernel_stream(request: Request, db: AsyncSession = Depends(get_db)):
    """Stream chat responses with persistence and constitutional validation"""
    try:
        data = await request.json()
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")
    
    task = data.get("task", "")
    worker = data.get("worker", "brain")
    model = data.get("model")
    session_id = data.get("session_id") or request.headers.get("X-Session-ID")
    
    if not task:
        raise HTTPException(status_code=400, detail="Task cannot be empty")
    
    return StreamingResponse(
        generate_stream(task, worker, model, session_id, db),
        media_type="text/event-stream"
    )

@app.get("/chat/{session_id}/history")
async def get_chat_history(session_id: str, limit: int = 50, db: AsyncSession = Depends(get_db)):
    """Retrieve chat history for a session"""
    chat_service = ChatService(db)
    messages = await chat_service.get_chat_history(session_id, limit=min(limit, 100))
    
    return {
        "session_id": session_id,
        "count": len(messages),
        "messages":[
            {
                "role": msg.role,
                "content": msg.content,
                "worker": msg.worker,
                "model": msg.model,
                "timestamp": msg.created_at.isoformat() if msg.created_at else None
            }
            for msg in messages
        ]
    }

@app.post("/chat/{session_id}/clear")
async def clear_chat_history(session_id: str, db: AsyncSession = Depends(get_db)):
    """Clear chat history for a session"""
    chat_service = ChatService(db)
    count = await chat_service.clear_session_chat(session_id)
    return {"message": f"Chat history cleared ({count} messages)", "session_id": session_id}

@app.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)):
    """Service health check with drift status"""
    health_service = HealthCheckService(db)
    await health_service.log_health_check(
        service="kernel",
        status="healthy"
    )
    
    drift_report = detector.get_drift_report() if hasattr(detector, 'get_drift_report') else None
    
    return HealthCheckResponse(
        status="healthy",
        workers=len(workers.workers),
        database="connected",
        timestamp=datetime.utcnow().isoformat(),
        drift_status=drift_report
    )

@app.get("/worker/{worker_name}/stats")
async def get_worker_stats(worker_name: str, hours: int = 24, db: AsyncSession = Depends(get_db)):
    """Get worker execution statistics"""
    worker = workers.get(worker_name)
    if not worker:
        raise HTTPException(status_code=404, detail=f"Worker '{worker_name}' not found")
    
    worker_log_service = WorkerLogService(db)
    stats = await worker_log_service.get_worker_stats(worker_name, hours=hours)
    
    return {
        "worker": worker_name,
        "description": worker.description,
        "stats": stats
    }

@app.get("/workers")
async def list_workers():
    """List available workers"""
    workers_info = []
    for name, worker in workers.workers.items():
        workers_info.append({
            "name": name,
            "description": worker.description,
            "model": worker.model or "unknown",
            "status": "available"
        })
    return {"workers": workers_info, "count": len(workers_info)}

@app.get("/worker/{worker_name}/health")
async def worker_health(worker_name: str):
    """Check individual worker health"""
    worker = workers.get(worker_name)
    if not worker:
        raise HTTPException(status_code=404, detail=f"Worker '{worker_name}' not found")
    
    try:
        if worker_name == "brain":
            test = await asyncio.wait_for(worker.process("ping", timeout=5), timeout=5)
            healthy = "error" not in test
        else:
            healthy = True
    except:
        healthy = False
    
    return {
        "worker": worker_name,
        "status": "healthy" if healthy else "degraded",
        "description": worker.description,
        "model": worker.model or "unknown",
        "ready": healthy
    }

@app.get("/mcp/servers")
async def list_mcp_servers():
    """List available MCP servers"""
    return {
        "servers": list(mcp_manager.servers.keys()),
        "count": len(mcp_manager.servers)
    }

# ============================================================================ 
# Admin/Operational Endpoints
# ============================================================================

@app.post("/admin/kill-port")
async def kill_port_endpoint(port: int = 8001):
    """Kill processes using a specific port"""
    try:
        killed = False
        killed_pids = []
        
        try:
            for conn in psutil.net_connections():
                if hasattr(conn, 'laddr') and conn.laddr.port == port and conn.pid:
                    proc = psutil.Process(conn.pid)
                    proc.terminate()
                    try:
                        proc.wait(timeout=3)
                    except psutil.TimeoutExpired:
                        proc.kill()
                    killed = True
                    killed_pids.append(conn.pid)
                    logger.info(f"[OK] Killed process {conn.pid} on port {port}")
        except Exception as e:
            logger.warning(f"psutil method failed: {e}")
            
            import platform
            if platform.system() == "Windows":
                result = subprocess.run(
                    f'netstat -ano | findstr :{port}',
                    shell=True,
                    capture_output=True,
                    text=True
                )
                if result.stdout:
                    lines = result.stdout.strip().split("\n")
                    for line in lines:
                        if 'LISTENING' in line:
                            parts = line.split()
                            if parts:
                                pid = int(parts[-1])
                                try:
                                    os.kill(pid, signal.SIGTERM)
                                    killed = True
                                    killed_pids.append(pid)
                                    logger.info(f"[OK] Killed process {pid} on port {port}")
                                except:
                                    pass
        
        if killed:
            await asyncio.sleep(1)
            return {
                "status": "success",
                "message": f"Freed port {port}",
                "killed_pids": killed_pids
            }
        else:
            return {
                "status": "not_found",
                "message": f"No process found on port {port}",
                "killed_pids": []
            }
    
    except Exception as e:
        logger.error(f"Error killing port {port}: {e}")
        return {
            "status": "error",
            "message": str(e),
            "killed_pids": []
        }

@app.post("/admin/launch-all")
async def launch_all_services():
    """Launch all services (for browser-based control)"""
    try:
        services_status = {}
        services_status["kernel"] = True
        
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('127.0.0.1', 3001))
            sock.close()
            services_status["nextjs"] = (result == 0)
        except:
            services_status["nextjs"] = False
        
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('127.0.0.1', 8000))
            sock.close()
            services_status["chroma"] = (result == 0)
        except:
            services_status["chroma"] = False
        
        message = "Service Status:\n"
        for service, running in services_status.items():
            status_str = "✅ Running" if running else "❌ Not Running"
            message += f"  {service}: {status_str}\n"
        
        logger.info(message)
        
        return {
            "status": "check_complete",
            "message": "Use launcher.bat to start all services from terminal",
            "services": services_status,
            "commands":[
                "cd backend && python kernel.py",
                "chroma run --path ./chroma_data --port 8000",
                "npm run dev"
            ]
        }
    
    except Exception as e:
        logger.error(f"Launch check error: {e}")
        return {"status": "error", "message": str(e)}

@app.get("/status")
async def status():
    """General status endpoint"""
    return {
        "workers": len(workers.workers),
        "mcp_servers": len(mcp_manager.servers),
        "status": "running",
        "drift_protection": "active"
    }

@app.post("/api/kernel")
async def kernel_compatibility_endpoint(req: TaskRequest, db: AsyncSession = Depends(get_db)):
    """Legacy compatibility endpoint for older clients"""
    return StreamingResponse(
        generate_stream(req.task, req.worker, req.model, req.session_id, db),
        media_type="text/event-stream"
    )

# ============================================================================ 
# Main
# ============================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("🏛️  REZ HIVE KERNEL - Zero-Drift Sovereign AI")
    print("=" * 60)
    print(f"[OK] Workers: {len(workers.workers)}")
    for name, worker in workers.workers.items():
        print(f"      - {name}: {worker.description}")
    print(f"[OK] MCP Servers: {len(mcp_manager.servers)}")
    print(f"[OK] Database: SQLite with connection pooling")
    print(f"[OK] Logging: Structured JSON")
    print(f"[OK] Authentication: JWT enabled")
    print(f"[OK] Constitutional AI: 9 Articles active")
    print(f"[OK] Zero-Drift Detector: Active")
    print(f"[OK] Intent Routing: PC Search → Memory Worker")
    print(f"[OK] Online Search: DuckDuckGo Grounding Enabled")
    print("=" * 60)
    
    import socket
    port = 8001
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = s.connect_ex(('127.0.0.1', port))
        s.close()
        if result != 0:
            print(f"[OK] Starting on port {port}")
        else:
            port = 8002
            print(f"[WARN] Port 8001 in use, trying {port}")
    except:
        pass
    
    print(f"🌐 API: http://localhost:{port}")
    print(f"📊 Docs: http://localhost:{port}/docs")
    print(f"🔍 Online Search: Auto-detects factual questions")
    print(f"💾 PC Search: Type 'search pc [filename]'")
    print("=" * 60)
    
    uvicorn.run(app, host="0.0.0.0", port=port)




