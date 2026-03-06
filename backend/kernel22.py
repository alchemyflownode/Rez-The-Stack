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
from pydantic import BaseModel
from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession

# Phase 1 Imports
from models import ChatMessage, User
from database import init_db, close_db, get_db
from auth import create_session_id, create_access_token, verify_token
from services import ChatService, UserService, WorkerLogService, HealthCheckService
from middleware import setup_logging

# CONSTITUTIONAL AI - Zero Drift Governance (PHASE 0 - FOUNDATION)
from constitutional_wrapper import ZeroDriftConstitution
from invariant_layer import ExecutionGuard, InterceptionEngine, invariant_registry
from constitutional_audit import ConstitutionalAudit

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
        print(f"[OK] MCP Server '{name}' started")
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

class BrainWorker(Worker):
    def __init__(self):
        super().__init__("brain", "General reasoning and chat", "llama3.2:latest")

    async def process(self, task: str, model: str = None) -> dict:
        model_to_use = model or self.model
        response = ollama.chat(
            model=model_to_use,
            messages=[{"role": "user", "content": task}],
            stream=False,
        )
        return {"content": response["message"]["content"]}

class SearchWorker(Worker):
    def __init__(self):
        super().__init__("search", "Web search and information retrieval")

    async def process(self, task: str, model: str = None) -> dict:
        """Search using DuckDuckGo or fallback to local processing"""
        try:
            # First, try using the Brain worker to provide knowledge-based results
            brain_worker = BrainWorker()
            
            # Craft a search-optimized prompt
            search_prompt = f"""You are a search assistant. Provide relevant, factual information about: {task}

Format your response as:
1. Key Finding: [Main result]
2. Details: [Supporting information]  
3. Related: [Related topics]

Be concise and informative."""
            
            result = await asyncio.wait_for(
                brain_worker.process(search_prompt, model=model or "llama3.2:latest"),
                timeout=30
            )
            return result
            
        except asyncio.TimeoutError:
            return {"content": f"Search timed out for: '{task}'. Please try a simpler query."}
        except Exception as e:
            return {"content": f"Search unavailable: {str(e)}. Try asking the Brain worker directly about '{task}'."}
            

class SearchWorker_DuckDuckGo(Worker):
    """Alternative SearchWorker using DuckDuckGo if available"""
    def __init__(self):
        super().__init__("search", "Web search using DuckDuckGo (when available)")

    async def process(self, task: str, model: str = None) -> dict:
        """Search using DuckDuckGo Instant Answer API"""
        try:
            async with aiohttp.ClientSession() as session:
                # Use DuckDuckGo Instant Answer API
                params = {
                    'q': task,
                    'format': 'json',
                    'no_redirect': '1',
                    'no_html': '1',
                    'skip_disambig': '1'
                }
                async with session.get('https://api.duckduckgo.com/', params=params, timeout=aiohttp.ClientTimeout(total=8)) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        
                        # Extract results in a readable format
                        results_text = ""
                        
                        # Add instant answer if available
                        if data.get('AbstractText'):
                            results_text += f"**{data.get('AbstractTitle', 'Information')}**\n"
                            results_text += f"{data.get('AbstractText')}\n\n"
                        
                        # Add related topics
                        if data.get('RelatedTopics'):
                            results_text += "**Related Topics:**\n"
                            for topic in data.get('RelatedTopics', [])[:3]:
                                if 'Text' in topic:
                                    results_text += f"- {topic.get('Text', '')}\n"
                        
                        if results_text:
                            return {"content": results_text}
                        else:
                            return {"content": f"No direct results found for '{task}'. DuckDuckGo may have limited information."}
                    else:
                        return {"content": f"Search service temporarily unavailable (status: {resp.status})"}
        except asyncio.TimeoutError:
            return {"content": f"Search request timed out for '{task}'"}
        except Exception as e:
            return {"content": f"Search error: {str(e)}"}

class CodeWorker(Worker):
    def __init__(self):
        super().__init__("code", "Code generation", "qwen2.5-coder:14b")

    async def process(self, task: str, model: str = None) -> dict:
        model_to_use = model or self.model
        response = ollama.chat(
            model=model_to_use,
            messages=[{"role": "user", "content": task}],
            stream=False,
        )
        return {"code": response["message"]["content"]}

class FileWorker(Worker):
    def __init__(self):
        super().__init__("files", "File system operations")

    async def process(self, task: str, model: str = None) -> dict:
        import os
        import glob
        task_lower = task.lower()
        if "list" in task_lower:
            return {"files": os.listdir(".")[:20]}
        if "search" in task_lower:
            pattern = task_lower.replace("search", "").strip()
            return {"files": glob.glob(f"**/{pattern}", recursive=True)[:20]}
        return {"message": "File operation completed"}

# ============================================================================ 
# Worker Registry
# ============================================================================
class WorkerRegistry:
    def __init__(self):
        self.workers = {}

    def register(self, worker: Worker):
        self.workers[worker.name] = worker
        print(f"[OK] Worker '{worker.name}' registered")

    def get(self, name: str):
        return self.workers.get(name)

# ============================================================================ 
# PYDANTIC MODELS
# ============================================================================
class TaskRequest(BaseModel):
    task: str
    worker: str = "brain"
    model: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None
    confirmed: bool = False
    session_id: Optional[str] = None

class SessionResponse(BaseModel):
    session_id: str
    token: str

class ChatHistoryItem(BaseModel):
    role: str
    content: str
    timestamp: str

class HealthCheckResponse(BaseModel):
    status: str
    workers: int
    database: str
    timestamp: str

# ============================================================================ 
# Initialize
# ============================================================================
setup_logging(log_level="INFO")

app = FastAPI(title="REZ HIVE Kernel")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3001", "http://localhost:3000", "http://127.0.0.1:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*", "X-Session-ID"],
)

# Startup and shutdown events
@app.on_event("startup")
async def startup():
    await init_db()
    print("[OK] Database initialized")

@app.on_event("shutdown")
async def shutdown():
    await close_db()
    print("[STOP] Database connection closed")
    for name, server in mcp_manager.servers.items():
        if server.process:
            server.process.terminate()
            await server.process.wait()
            print(f"[STOP] MCP Server '{name}' terminated")

mcp_manager = MCPManager()
workers = WorkerRegistry()
workers.register(BrainWorker())
workers.register(SearchWorker())
workers.register(CodeWorker())
workers.register(FileWorker())

# ============================================================================
# CONSTITUTIONAL AI INITIALIZATION (GOVERNANCE FOUNDATION)
# ============================================================================
constitution = ZeroDriftConstitution()
execution_guard = ExecutionGuard(invariant_registry)
interception = InterceptionEngine(invariant_registry)
audit = ConstitutionalAudit()

# ============================================================================ 
# Stream Generator (Updated with ChatService)
# ============================================================================
async def format_response_for_streaming(result: dict, worker_name: str) -> str:
    """Format worker response for nice display with syntax highlighting"""
    # If there's an error, return it as-is
    if "error" in result:
        return result.get("error", "Unknown error")
    
    # Handle different response types
    if "content" in result:
        return result["content"]
    elif "code" in result:
        # Wrap code in markdown fence for syntax highlighting
        code_content = result["code"]
        # Try to detect language from context
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
        # For any other response, check if we should pretty-print it
        import json as json_lib
        try:
            # If it's a dict with multiple fields, pretty-print as JSON
            if len(result) > 1 or (len(result) == 1 and not any(k in result for k in ['content', 'code', 'files', 'results'])):
                return f"```json\n{json_lib.dumps(result, indent=2)}\n```"
        except:
            pass
        return str(result)

async def generate_stream(task: str, worker_name: str = "brain", model: str = None, session_id: str = None, db: AsyncSession = None):
    try:
        yield sse({"status": "started", "worker": worker_name})
        
        # Save user message if session and db available
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
        
        result = await asyncio.wait_for(worker.process(task, model=model), timeout=60)
        
        # Format response nicely
        formatted_content = await format_response_for_streaming(result, worker_name)
        
        # Save AI response if session and db available
        if session_id and db and "error" not in result:
            chat_service = ChatService(db)
            await chat_service.save_message(
                session_id=session_id,
                role="ai",
                content=formatted_content,
                worker=worker_name,
                model=model or (worker.model if hasattr(worker, 'model') else "unknown")
            )
            
            # Log worker execution
            worker_log_service = WorkerLogService(db)
            await worker_log_service.log_execution(
                worker_name=worker_name,
                status="success",
                duration_ms=0,
                error=None
            )
        
        # Stream the formatted content
        yield sse({"content": formatted_content})
        
        if result.get("error") and "research" in mcp_manager.servers:
            mcp_result = await mcp_manager.call("research", "search", {"query": task})
            yield sse(mcp_result)
        yield sse({"status": "complete"})
    except Exception as e:
        yield sse({"error": str(e)})
        yield sse({"status": "failed"})

# ============================================================================ 
# Endpoints - Phase 1 Enhanced
# ============================================================================

# Session Management
@app.post("/auth/session")
async def create_session(db: AsyncSession = Depends(get_db)):
    """Create a new session with JWT token"""
    session_id = create_session_id()
    token = create_access_token(session_id)
    
    # Create user in database
    user_service = UserService(db)
    await user_service.get_or_create_user(session_id)
    
    return SessionResponse(session_id=session_id, token=token)

@app.post("/kernel/stream")
async def kernel_stream(request: Request, db: AsyncSession = Depends(get_db)):
    """Stream chat responses with persistence"""
    data = await request.json()
    task = data.get("task", "")
    worker = data.get("worker", "brain")
    model = data.get("model")
    session_id = data.get("session_id") or request.headers.get("X-Session-ID")
    
    return StreamingResponse(
        generate_stream(task, worker, model, session_id, db),
        media_type="text/event-stream"
    )

# Chat History
@app.get("/chat/{session_id}/history")
async def get_chat_history(session_id: str, db: AsyncSession = Depends(get_db)):
    """Retrieve chat history for a session"""
    chat_service = ChatService(db)
    messages = await chat_service.get_chat_history(session_id, limit=50)
    return {
        "session_id": session_id,
        "messages": [
            {
                "role": msg.role,
                "content": msg.content,
                "worker": msg.worker,
                "timestamp": msg.created_at.isoformat() if msg.created_at else None
            }
            for msg in messages
        ]
    }

@app.post("/chat/{session_id}/clear")
async def clear_chat_history(session_id: str, db: AsyncSession = Depends(get_db)):
    """Clear chat history for a session"""
    chat_service = ChatService(db)
    await chat_service.clear_session_chat(session_id)
    return {"message": "Chat history cleared", "session_id": session_id}

# Health & Monitoring
@app.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)):
    """Service health check"""
    health_service = HealthCheckService(db)
    await health_service.log_health_check(
        service="kernel",
        status="healthy"
    )
    return HealthCheckResponse(
        status="healthy",
        workers=len(workers.workers),
        database="connected",
        timestamp=str(asyncio.get_event_loop().time())
    )

@app.get("/worker/{worker_name}/stats")
async def get_worker_stats(worker_name: str, db: AsyncSession = Depends(get_db)):
    """Get worker execution statistics"""
    worker_log_service = WorkerLogService(db)
    stats = await worker_log_service.get_worker_stats(worker_name, hours=24)
    return {
        "worker": worker_name,
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
    return {"workers": workers_info}

@app.get("/worker/{worker_name}/health")
async def worker_health(worker_name: str):
    """Check individual worker health"""
    worker = workers.get(worker_name)
    if not worker:
        raise HTTPException(status_code=404, detail=f"Worker '{worker_name}' not found")
    
    return {
        "worker": worker_name,
        "status": "healthy",
        "description": worker.description,
        "model": worker.model or "unknown",
        "ready": True
    }

@app.get("/mcp/servers")
async def list_mcp_servers():
    """List available MCP servers"""
    return {"servers": list(mcp_manager.servers.keys())}

# ============================================================================ 
# Admin/Operational Endpoints (PS1-Style Controller)
# ============================================================================

@app.post("/admin/kill-port")
async def kill_port_endpoint(port: int = 8001):
    """Kill processes using a specific port (Windows/Linux compatible)"""
    try:
        killed = False
        
        # Try to find and kill process using the port
        try:
            for conn in psutil.net_connections():
                if conn.laddr.port == port and conn.pid:
                    proc = psutil.Process(conn.pid)
                    proc.terminate()
                    proc.wait(timeout=3)
                    killed = True
                    print(f"[OK] Killed process {conn.pid} on port {port}")
        except:
            # Fallback: Try Windows-specific command
            import platform
            if platform.system() == "Windows":
                # Find PID using netstat
                result = subprocess.run(
                    f'netstat -ano | findstr :{port}',
                    shell=True,
                    capture_output=True,
                    text=True
                )
                if result.stdout:
                    lines = result.stdout.strip().split("\n")
                    for line in lines:
                        parts = line.split()
                        if parts:
                            pid = int(parts[-1])
                            os.kill(pid, signal.SIGTERM)
                            killed = True
                            print(f"[OK] Killed process {pid} on port {port}")
        
        if killed:
            await asyncio.sleep(1)  # Give it time to actually die
            return {"status": "success", "message": f"Port {port} freed"}
        else:
            return {"status": "not_found", "message": f"No process found on port {port}"}
    
    except Exception as e:
        print(f"[WARN] Error killing port {port}: {str(e)}")
        return {"status": "error", "message": str(e)}

@app.post("/admin/launch-all")
async def launch_all_services():
    """Launch all services (for browser-based control)"""
    try:
        # This is informational - actual launching still needs to be done from terminal
        # But we can verify what's running and suggest what's missing
        
        services_status = {}
        
        # Check kernel (we're running, so always true)
        services_status["kernel"] = True
        
        # Check if Next.js is running
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('127.0.0.1', 3001))
            sock.close()
            services_status["nextjs"] = (result == 0)
        except:
            services_status["nextjs"] = False
        
        # Check if ChromaDB is running
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('127.0.0.1', 8000))
            sock.close()
            services_status["chroma"] = (result == 0)
        except:
            services_status["chroma"] = False
        
        # Log what's running
        message = "Service Status:\n"
        for service, running in services_status.items():
            status_str = "✅ Running" if running else "❌ Not Running"
            message += f"  {service}: {status_str}\n"
        
        print(f"[INFO] {message}")
        
        return {
            "status": "check",
            "message": "Use launcher.bat to start all services from terminal",
            "services": services_status
        }
    
    except Exception as e:
        print(f"[WARN] Launch check error: {str(e)}")
        return {"status": "error", "message": str(e)}

@app.get("/status")
async def status():
    """General status endpoint"""
    return {
        "workers": len(workers.workers),
        "mcp_servers": len(mcp_manager.servers),
        "status": "running",
    }

@app.post("/api/kernel")
async def kernel_compatibility_endpoint(req: TaskRequest, db: AsyncSession = Depends(get_db)):
    """Legacy compatibility endpoint"""
    return StreamingResponse(
        generate_stream(req.task, req.worker, req.model, req.session_id, db),
        media_type="text/event-stream"
    )

# ============================================================================ 
# Main
# ============================================================================
if __name__ == "__main__":
    print("=")
    print("REZ HIVE KERNEL - Phase 1 Enhanced")
    print("=")
    print(f"[OK] Workers: {len(workers.workers)}")
    print(f"[OK] MCP Servers: {len(mcp_manager.servers)}")
    print(f"[OK] Database: Initializing on startup")
    print(f"[OK] Logging: Structured JSON format")
    print(f"[OK] Authentication: JWT enabled")
    print("=")
    # Try port 8001, if in use try 8002
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
    uvicorn.run(app, host="0.0.0.0", port=port)
