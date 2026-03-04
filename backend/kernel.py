# backend/kernel.py - Enhanced with MCP & RAG
import os
import sys
import json
import time
import asyncio
import subprocess
from datetime import datetime
from typing import Optional, Dict, Any, List
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
import uvicorn

# ============================================================================
# SAFE IMPORTS
# ============================================================================
try:
    from ollama import Client
    ollama = Client(host='http://localhost:11434')
except Exception as e:
    print(f"Ollama Init Error: {e}")
    ollama = None

# ============================================================================
# FIXED: ChromaDB Connection with proper HTTP client
# ============================================================================
try:
    import chromadb
    from chromadb.config import Settings
    # Use HTTP client to connect to running ChromaDB server
    chroma_client = chromadb.HttpClient(
        host='localhost', 
        port=8000,
        settings=Settings(allow_reset=True, anonymized_telemetry=False)
    )
    # Test connection
    chroma_client.heartbeat()
    memory_collection = chroma_client.get_or_create_collection(name="hive_memory")
    print(f"✅ Connected to ChromaDB server with {memory_collection.count()} vectors")
except Exception as e:
    print(f"⚠️ ChromaDB server not available: {e}")
    memory_collection = None

# ============================================================================
# MCP MANAGER
# ============================================================================
class MCPManager:
    def __init__(self):
        self.servers = {}
        self.start_server('executive', 'mcp_servers/executive_mcp.py')
        self.start_server('system', 'mcp_servers/system_mcp.py')
        self.start_server('process', 'mcp_servers/process_mcp.py')
        self.start_server('research', 'mcp_servers/research_mcp.py')
        self.start_server('rag', 'mcp_servers/rag_pipeline.py')
    
    def start_server(self, name, script):
        try:
            proc = subprocess.Popen(
                [sys.executable, script],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1
            )
            self.servers[name] = proc
            print(f"✅ MCP Server '{name}' started")
        except Exception as e:
            print(f"❌ Failed to start {name}: {e}")
    
    def call(self, server, method, params={}):
        proc = self.servers.get(server)
        if not proc:
            return {"error": f"Server {server} not running"}
        
        try:
            request = json.dumps({"method": method, "params": params})
            proc.stdin.write(request + "\n")
            proc.stdin.flush()
            
            response = proc.stdout.readline()
            return json.loads(response)
        except Exception as e:
            return {"error": str(e)}
    
    def shutdown(self):
        for proc in self.servers.values():
            proc.terminate()

mcp_manager = MCPManager()

# ============================================================================
# FASTAPI APP
# ============================================================================
app = FastAPI(title="REZ HIVE Kernel")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# MODELS
# ============================================================================
class TaskRequest(BaseModel):
    task: str
    worker: str = "brain"
    payload: Optional[Dict[str, Any]] = None

class TaskResponse(BaseModel):
    content: str
    status: str = "success"
    model: Optional[str] = None
    latency: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class DocumentIndexRequest(BaseModel):
    file_path: str

class QueryRequest(BaseModel):
    question: str
    n_results: int = 3

class NoteRequest(BaseModel):
    content: str

class TaskCreateRequest(BaseModel):
    title: str
    description: str = ""
    priority: str = "medium"

# ============================================================================
# STREAMING GENERATOR - COMPLETELY FIXED
# ============================================================================
async def generate_stream(task: str, model: str = "llama3.2:latest"):
    """Stream LLM responses token by token"""
    
    # 1. Check for MCP commands
    if "note" in task.lower() or "remember" in task.lower():
        result = mcp_manager.call('executive', 'take_note', {'content': task})
        msg = result.get('message', result.get('error', 'Done'))
        yield f"data: {json.dumps({'content': f'Note saved: {msg}'})}\n\n"
        return
    
    if "vitals" in task.lower() or "system status" in task.lower():
        result = mcp_manager.call('system', 'get_vitals', {})
        cpu = result.get('cpu', '?')
        memory = result.get('memory', '?')
        disk = result.get('disk', '?')
        msg = f"CPU: {cpu}% | RAM: {memory}% | Disk: {disk}%"
        yield f"data: {json.dumps({'content': msg})}\n\n"
        return
    
    if "launch" in task.lower() or "open" in task.lower():
        app_name = task.lower().replace('launch', '').replace('open', '').strip()
        result = mcp_manager.call('process', 'launch_app', {'app': app_name})
        msg = result.get('message', result.get('error', 'Done'))
        yield f"data: {json.dumps({'content': msg})}\n\n"
        return
    
    if "search" in task.lower():
        query = task.lower().replace('search', '').strip()
        result = mcp_manager.call('research', 'search_web', {'query': query})
        if result.get('success'):
            results = result.get('results', [])
            if results:
                msg_lines = ["Search Results:"]
                for r in results:
                    msg_lines.append(f"• {r.get('title', 'Untitled')}")
                msg = "\n".join(msg_lines)
            else:
                msg = "No results found."
        else:
            error_msg = result.get('error', 'Unknown error')
            msg = f"Search failed: {error_msg}"
        
        yield f"data: {json.dumps({'content': msg})}\n\n"
        return
    
    # 2. Memory Retrieval for Brain
    context = ""
    if memory_collection:
        try:
            results = memory_collection.query(query_texts=[task], n_results=3)
            if results and 'documents' in results and results['documents']:
                context = "\n".join([doc for doc in results['documents'][0] if doc])
        except Exception as e:
            print(f"Memory query error: {e}")
    
    # 3. Ollama Streaming
    if not ollama:
        yield f"data: {json.dumps({'content': 'Error: Ollama offline.'})}\n\n"
        return
    
    try:
        system_prompt = f"You are REZ HIVE, a sovereign AI assistant. Use this context: {context}"
        
        stream = ollama.chat(
            model=model,
            messages=[
                {'role': 'system', 'content': system_prompt},
                {'role': 'user', 'content': task}
            ],
            stream=True
        )
        
        full_response = ""
        for chunk in stream:
            content = chunk['message']['content']
            full_response += content
            yield f"data: {json.dumps({'content': content})}\n\n"
        
        # Save to memory
        if memory_collection:
            try:
                memory_collection.add(
                    documents=[f"User: {task}\nAI: {full_response}"],
                    ids=[f"chat_{datetime.now().timestamp()}"]
                )
            except Exception as e:
                print(f"Memory save error: {e}")
    
    except Exception as e:
        yield f"data: {json.dumps({'content': f'Error: {str(e)}'})}\n\n"

# ============================================================================
# API ENDPOINTS
# ============================================================================

# Main Kernel Endpoint
@app.post("/api/kernel")
async def kernel_endpoint(req: TaskRequest):
    model = req.model if hasattr(req, 'model') else 'llama3.2:latest'
    return StreamingResponse(generate_stream(req.task, model), media_type='text/event-stream')

# Status Endpoint
@app.get("/api/status")
async def status():
    ollama_ok = False
    chroma_ok = False
    
    if ollama:
        try:
            ollama.list()
            ollama_ok = True
        except:
            pass
    
    if memory_collection:
        try:
            memory_collection.count()
            chroma_ok = True
        except:
            pass
    
    return {
        "ollama": ollama_ok,
        "chroma": chroma_ok,
        "kernel": True,
        "mcp_servers": len(mcp_manager.servers)
    }

# ============================================================================
# MCP EXECUTIVE ENDPOINTS
# ============================================================================
@app.post("/api/notes")
async def create_note(req: NoteRequest):
    result = mcp_manager.call('executive', 'take_note', {'content': req.content})
    return result

@app.get("/api/notes/search/{query}")
async def search_notes(query: str):
    result = mcp_manager.call('executive', 'search_notes', {'query': query})
    return result

@app.post("/api/tasks")
async def create_task(req: TaskCreateRequest):
    result = mcp_manager.call('executive', 'create_task', req.dict())
    return result

@app.get("/api/tasks")
async def list_tasks():
    result = mcp_manager.call('executive', 'list_tasks', {})
    return result

# ============================================================================
# MCP SYSTEM ENDPOINTS
# ============================================================================
@app.get("/api/system/vitals")
async def system_vitals():
    result = mcp_manager.call('system', 'get_vitals', {})
    return result

@app.get("/api/system/info")
async def system_info():
    result = mcp_manager.call('system', 'get_system_info', {})
    return result

@app.get("/api/system/processes")
async def system_processes():
    result = mcp_manager.call('system', 'get_processes', {})
    return result

# ============================================================================
# MCP PROCESS ENDPOINTS
# ============================================================================
@app.post("/api/apps/launch/{app_name}")
async def launch_app(app_name: str):
    result = mcp_manager.call('process', 'launch_app', {'app': app_name})
    return result

@app.get("/api/apps/list")
async def list_apps():
    result = mcp_manager.call('process', 'list_apps', {})
    return result

@app.post("/api/processes/kill")
async def kill_process(pid: Optional[int] = None, name: Optional[str] = None):
    result = mcp_manager.call('process', 'kill_process', {'pid': pid, 'name': name})
    return result

# ============================================================================
# MCP RESEARCH ENDPOINTS
# ============================================================================
@app.get("/api/search/{query}")
async def web_search(query: str, max_results: int = 5):
    result = mcp_manager.call('research', 'search_web', {'query': query, 'max_results': max_results})
    return result

# ============================================================================
# RAG ENDPOINTS
# ============================================================================
@app.post("/api/rag/index")
async def index_document(req: DocumentIndexRequest):
    result = mcp_manager.call('rag', 'index_document', {'file_path': req.file_path})
    return result

@app.post("/api/rag/query")
async def rag_query(req: QueryRequest):
    result = mcp_manager.call('rag', 'query', {'question': req.question, 'n_results': req.n_results})
    return result

@app.get("/api/rag/documents")
async def list_documents():
    result = mcp_manager.call('rag', 'list_documents', {})
    return result

# ============================================================================
# HEALTH CHECK
# ============================================================================
@app.get("/api/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/")
async def root():
    return {
        "name": "REZ HIVE Kernel",
        "version": "2.0",
        "endpoints": [
            "/api/kernel (streaming)",
            "/api/status",
            "/api/notes",
            "/api/tasks",
            "/api/system/vitals",
            "/api/system/processes",
            "/api/apps/launch/{app}",
            "/api/search/{query}",
            "/api/rag/index",
            "/api/rag/query"
        ]
    }

# ============================================================================
# SHUTDOWN HANDLER
# ============================================================================
@app.on_event("shutdown")
async def shutdown_event():
    mcp_manager.shutdown()

# ============================================================================
# MAIN
# ============================================================================
if __name__ == "__main__":
    print("="*60)
    print("REZ HIVE Kernel v2.0 - MCP + RAG Enabled")
    print("="*60)
    print("API: http://localhost:8001")
    print("Docs: http://localhost:8001/docs")
    print("="*60)
    uvicorn.run(app, host="0.0.0.0", port=8001)







