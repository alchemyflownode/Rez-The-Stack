# ============================================
# REZ HIVE - COMPLETE INTEGRATION SETUP
# ============================================
# This script sets up:
# 1. All Python dependencies
# 2. MCP Servers (Executive, System, Process, Research)
# 3. RAG Pipeline with ChromaDB
# 4. FastAPI with all endpoints
# 5. Next.js proxy configuration
# ============================================

param(
    [switch]$Setup,
    [switch]$Start,
    [switch]$Status,
    [switch]$Stop
)

$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
$PYTHON_PATH = "C:\Users\Zphoenix\AppData\Local\Programs\Python\Python310\python.exe"
$MCP_PATH = "$PROJECT_PATH\mcp_servers"

# ============================================
# ASCII HEADER
# ============================================
function Show-Header {
    Clear-Host
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "     REZ HIVE - COMPLETE INTEGRATION                    " -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================
# SETUP MODE - Install Everything
# ============================================
if ($Setup) {
    Show-Header
    Write-Host "[1/8] Installing Python Dependencies..." -ForegroundColor Yellow
    
    $deps = @(
        "fastapi", "uvicorn", "python-multipart", "pydantic",
        "ollama", "chromadb-client", "requests", "psutil",
        "sentence-transformers", "torch", "transformers",
        "langchain", "langchain-chroma", "tiktoken",
        "pypdf", "python-docx", "markdown"
    )
    
    foreach ($dep in $deps) {
        Write-Host "   Installing $dep..." -ForegroundColor Gray
        & $PYTHON_PATH -m pip install $dep --quiet
    }
    Write-Host "   ✅ Dependencies installed" -ForegroundColor Green
    
    # ============================================
    # Create MCP Servers Directory
    # ============================================
    Write-Host "[2/8] Creating MCP Servers..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $MCP_PATH -Force | Out-Null
    New-Item -ItemType Directory -Path "$PROJECT_PATH\chroma_data" -Force | Out-Null
    New-Item -ItemType Directory -Path "$PROJECT_PATH\documents" -Force | Out-Null
    
    # ============================================
    # 1. EXECUTIVE MCP SERVER (Notes & Tasks)
    # ============================================
    $executiveMCP = @'
# executive_mcp.py
import sys
import json
import os
import sqlite3
from datetime import datetime
from pathlib import Path

MEMORY_DIR = Path.home() / "rezstack_brain"
MEMORY_DIR.mkdir(exist_ok=True)
NOTES_FILE = MEMORY_DIR / "memory.md"
DB_FILE = MEMORY_DIR / "tasks.db"

# Initialize SQLite
conn = sqlite3.connect(str(DB_FILE))
conn.execute('''
    CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT DEFAULT 'medium',
        status TEXT DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
''')
conn.commit()
conn.close()

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'take_note':
        content = params.get('content', '')
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(NOTES_FILE, 'a', encoding='utf-8') as f:
            f.write(f"\n## {timestamp}\n{content}\n---\n")
        return {'success': True, 'message': 'Note saved', 'file': str(NOTES_FILE)}
    
    elif method == 'search_notes':
        query = params.get('query', '').lower()
        results = []
        if NOTES_FILE.exists():
            with open(NOTES_FILE, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                for i, line in enumerate(lines):
                    if query in line.lower():
                        results.append({
                            'line': i + 1,
                            'context': line.strip()
                        })
        return {'success': True, 'results': results[:10]}
    
    elif method == 'create_task':
        conn = sqlite3.connect(str(DB_FILE))
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO tasks (title, description, priority) VALUES (?, ?, ?)",
            (params.get('title', ''), params.get('description', ''), params.get('priority', 'medium'))
        )
        task_id = cursor.lastrowid
        conn.commit()
        conn.close()
        return {'success': True, 'task_id': task_id}
    
    elif method == 'list_tasks':
        conn = sqlite3.connect(str(DB_FILE))
        cursor = conn.cursor()
        cursor.execute("SELECT id, title, priority FROM tasks WHERE status = 'pending'")
        tasks = [{'id': r[0], 'title': r[1], 'priority': r[2]} for r in cursor.fetchall()]
        conn.close()
        return {'success': True, 'tasks': tasks}
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("Executive MCP Server Running\n")
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()
'@
    Set-Content -Path "$MCP_PATH\executive_mcp.py" -Value $executiveMCP -Encoding UTF8
    Write-Host "   ✅ Executive MCP Server created" -ForegroundColor Green
    
    # ============================================
    # 2. SYSTEM MCP SERVER (Vitals & Monitoring)
    # ============================================
    $systemMCP = @'
# system_mcp.py
import sys
import json
import psutil
import platform
import datetime

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'get_vitals':
        return {
            'cpu': psutil.cpu_percent(interval=1),
            'memory': psutil.virtual_memory().percent,
            'disk': psutil.disk_usage('/').percent,
            'swap': psutil.swap_memory().percent,
            'boot_time': datetime.datetime.fromtimestamp(psutil.boot_time()).isoformat()
        }
    
    elif method == 'get_processes':
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                processes.append(proc.info)
            except:
                pass
        processes.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
        return {'processes': processes[:20]}
    
    elif method == 'get_system_info':
        return {
            'platform': platform.system(),
            'release': platform.release(),
            'processor': platform.processor(),
            'hostname': platform.node(),
            'python': platform.python_version()
        }
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("System MCP Server Running\n")
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()
'@
    Set-Content -Path "$MCP_PATH\system_mcp.py" -Value $systemMCP -Encoding UTF8
    Write-Host "   ✅ System MCP Server created" -ForegroundColor Green
    
    # ============================================
    # 3. PROCESS MCP SERVER (App Control)
    # ============================================
    $processMCP = @'
# process_mcp.py
import sys
import json
import psutil
import subprocess
import os

ALLOWED_APPS = {
    'notepad': 'notepad.exe',
    'calc': 'calc.exe',
    'paint': 'mspaint.exe',
    'chrome': 'chrome.exe',
    'code': 'code.exe',
    'explorer': 'explorer.exe'
}

PROTECTED = ['system', 'lsass.exe', 'winlogon.exe', 'services.exe']

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'launch_app':
        app = params.get('app', '').lower()
        if app in ALLOWED_APPS:
            try:
                subprocess.Popen(ALLOWED_APPS[app], shell=True)
                return {'success': True, 'message': f'Launched {app}'}
            except Exception as e:
                return {'error': str(e)}
        return {'error': f'App {app} not allowed'}
    
    elif method == 'kill_process':
        pid = params.get('pid')
        name = params.get('name', '').lower()
        
        if name in PROTECTED:
            return {'error': 'Cannot kill protected process'}
        
        try:
            if pid:
                proc = psutil.Process(pid)
                proc.terminate()
                return {'success': True, 'message': f'Terminated PID {pid}'}
            elif name:
                killed = []
                for proc in psutil.process_iter(['pid', 'name']):
                    if proc.info['name'] and proc.info['name'].lower() == name:
                        proc.terminate()
                        killed.append(proc.info['pid'])
                return {'success': True, 'message': f'Terminated {len(killed)} processes'}
        except Exception as e:
            return {'error': str(e)}
    
    elif method == 'list_apps':
        return {'apps': list(ALLOWED_APPS.keys())}
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("Process MCP Server Running\n")
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()
'@
    Set-Content -Path "$MCP_PATH\process_mcp.py" -Value $processMCP -Encoding UTF8
    Write-Host "   ✅ Process MCP Server created" -ForegroundColor Green
    
    # ============================================
    # 4. RESEARCH MCP SERVER (Web Search with SearXNG)
    # ============================================
    $researchMCP = @'
# research_mcp.py
import sys
import json
import requests
import time

SEARXNG_URL = "http://localhost:8080"

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'search_web':
        query = params.get('query', '')
        max_results = params.get('max_results', 5)
        
        try:
            response = requests.get(
                f"{SEARXNG_URL}/search",
                params={"q": query, "format": "json"},
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                results = []
                for r in data.get("results", [])[:max_results]:
                    results.append({
                        "title": r.get("title", ""),
                        "url": r.get("url", ""),
                        "content": r.get("content", "")[:200]
                    })
                return {"success": True, "results": results}
            return {"success": False, "error": f"HTTP {response.status_code}"}
        except requests.exceptions.ConnectionError:
            return {"success": False, "error": "SearXNG not running"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("Research MCP Server Running\n")
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()
'@
    Set-Content -Path "$MCP_PATH\research_mcp.py" -Value $researchMCP -Encoding UTF8
    Write-Host "   ✅ Research MCP Server created" -ForegroundColor Green
    
    # ============================================
    # 5. RAG PIPELINE (Document Q&A)
    # ============================================
    $ragPipeline = @'
# rag_pipeline.py
import sys
import json
import os
from pathlib import Path
from typing import List, Dict, Any
import chromadb
from sentence_transformers import SentenceTransformer
import pypdf
import docx
import markdown

class RAGPipeline:
    def __init__(self):
        self.chroma_client = chromadb.PersistentClient(path="./chroma_data")
        self.embedder = SentenceTransformer('all-MiniLM-L6-v2')
        self.collection = self.chroma_client.get_or_create_collection(
            name="documents",
            metadata={"hnsw:space": "cosine"}
        )
        self.doc_path = Path("./documents")
        self.doc_path.mkdir(exist_ok=True)
    
    def extract_text(self, file_path: Path) -> str:
        if file_path.suffix.lower() == '.pdf':
            reader = pypdf.PdfReader(file_path)
            return '\n'.join([page.extract_text() for page in reader.pages])
        elif file_path.suffix.lower() == '.docx':
            doc = docx.Document(file_path)
            return '\n'.join([para.text for para in doc.paragraphs])
        elif file_path.suffix.lower() == '.md':
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        else:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
    
    def index_document(self, file_path: str, chunk_size: int = 500):
        path = Path(file_path)
        if not path.exists():
            return {"error": "File not found"}
        
        text = self.extract_text(path)
        chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
        
        ids = []
        embeddings = []
        documents = []
        metadatas = []
        
        for i, chunk in enumerate(chunks):
            chunk_id = f"{path.stem}_{i}"
            ids.append(chunk_id)
            documents.append(chunk)
            metadatas.append({
                "source": path.name,
                "chunk": i,
                "total_chunks": len(chunks)
            })
            embeddings.append(self.embedder.encode(chunk).tolist())
        
        self.collection.add(
            ids=ids,
            embeddings=embeddings,
            documents=documents,
            metadatas=metadatas
        )
        
        return {
            "success": True,
            "chunks": len(chunks),
            "file": path.name
        }
    
    def query(self, question: str, n_results: int = 3) -> Dict[str, Any]:
        query_embedding = self.embedder.encode(question).tolist()
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results
        )
        
        contexts = []
        if results['documents']:
            for doc in results['documents'][0]:
                contexts.append(doc[:500])
        
        return {
            "success": True,
            "contexts": contexts,
            "count": len(contexts)
        }
    
    def list_documents(self) -> List[str]:
        return [str(f) for f in self.doc_path.iterdir() if f.is_file()]

rag = RAGPipeline()

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'index_document':
        return rag.index_document(params.get('file_path', ''))
    elif method == 'query':
        return rag.query(params.get('question', ''), params.get('n_results', 3))
    elif method == 'list_documents':
        return {'documents': rag.list_documents()}
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("RAG Pipeline Server Running\n")
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()
'@
    Set-Content -Path "$MCP_PATH\rag_pipeline.py" -Value $ragPipeline -Encoding UTF8
    Write-Host "   ✅ RAG Pipeline created" -ForegroundColor Green
    
    # ============================================
    # 6. UPDATED KERNEL.PY WITH ALL ENDPOINTS
    # ============================================
    Write-Host "[3/8] Creating Enhanced Kernel with All Endpoints..." -ForegroundColor Yellow
    
    $kernelPath = "$PROJECT_PATH\backend\kernel.py"
    $kernelContent = @'
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

try:
    import chromadb
    chroma_client = chromadb.HttpClient(host='localhost', port=8000)
    memory_collection = chroma_client.get_or_create_collection(name="hive_memory")
except Exception as e:
    print(f"Chroma Init Error: {e}")
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
# STREAMING GENERATOR
# ============================================================================
async def generate_stream(task: str):
    """Stream LLM responses token by token"""
    
    # 1. Check for MCP commands
    if "note" in task.lower() or "remember" in task.lower():
        result = mcp_manager.call('executive', 'take_note', {'content': task})
        msg = result.get('message', result.get('error', 'Done'))
        yield f"data: {json.dumps({'content': f'📝 Note saved: {msg}'})}\n\n"
        return
    
    if "vitals" in task.lower() or "system status" in task.lower():
        result = mcp_manager.call('system', 'get_vitals', {})
        msg = f"CPU: {result.get('cpu', '?')}% | RAM: {result.get('memory', '?')}% | Disk: {result.get('disk', '?')}%"
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
            msg = "🌐 Search Results:\n\n" + "\n".join([f"• {r['title']}" for r in results])
            yield f"data: {json.dumps({'content': msg})}\n\n"
        else:
            yield f"data: {json.dumps({'content': f'Search failed: {result.get("error")}'})}\n\n"
        return
    
    # 2. Memory Retrieval for Brain
    context = ""
    if memory_collection:
        try:
            results = memory_collection.query(query_texts=[task], n_results=3)
            if results['documents']:
                context = "\n".join(results['documents'][0])
        except:
            pass
    
    # 3. Ollama Streaming
    if not ollama:
        yield f"data: {json.dumps({'content': 'Error: Ollama offline.'})}\n\n"
        return
    
    try:
        system_prompt = f"You are REZ HIVE, a sovereign AI assistant. Use this context: {context}"
        
        stream = ollama.chat(
            model='llama3.2',
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
            except:
                pass
    
    except Exception as e:
        yield f"data: {json.dumps({'content': f'Error: {str(e)}'})}\n\n"

# ============================================================================
# API ENDPOINTS
# ============================================================================

# Main Kernel Endpoint
@app.post("/api/kernel")
async def kernel_endpoint(req: TaskRequest):
    return StreamingResponse(generate_stream(req.task), media_type="text/event-stream")

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
'@
    Set-Content -Path $kernelPath -Value $kernelContent -Encoding UTF8
    Write-Host "   ✅ Enhanced Kernel created with all endpoints" -ForegroundColor Green
    
    # ============================================
    # 7. UPDATE NEXT.CONFIG.JS
    # ============================================
    Write-Host "[4/8] Updating Next.js proxy configuration..." -ForegroundColor Yellow
    
    $nextConfig = @'
/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return [
      // Kernel endpoints
      { source: '/api/kernel', destination: 'http://localhost:8001/api/kernel' },
      { source: '/api/status', destination: 'http://localhost:8001/api/status' },
      { source: '/api/health', destination: 'http://localhost:8001/api/health' },
      
      // Executive MCP
      { source: '/api/notes/:path*', destination: 'http://localhost:8001/api/notes/:path*' },
      { source: '/api/tasks/:path*', destination: 'http://localhost:8001/api/tasks/:path*' },
      
      // System MCP
      { source: '/api/system/:path*', destination: 'http://localhost:8001/api/system/:path*' },
      
      // Process MCP
      { source: '/api/apps/:path*', destination: 'http://localhost:8001/api/apps/:path*' },
      { source: '/api/processes/:path*', destination: 'http://localhost:8001/api/processes/:path*' },
      
      // Research MCP
      { source: '/api/search/:path*', destination: 'http://localhost:8001/api/search/:path*' },
      
      // RAG Pipeline
      { source: '/api/rag/:path*', destination: 'http://localhost:8001/api/rag/:path*' },
      
      // Catch all
      { source: '/api/:path*', destination: 'http://localhost:8001/api/:path*' },
    ]
  },
}

module.exports = nextConfig
'@
    Set-Content -Path "$PROJECT_PATH\next.config.js" -Value $nextConfig -Encoding UTF8
    Write-Host "   ✅ Next.js proxy configured" -ForegroundColor Green
    
    # ============================================
    # 8. CREATE DOCKER COMPOSE FOR SEARXNG
    # ============================================
    Write-Host "[5/8] Creating Docker Compose for SearXNG..." -ForegroundColor Yellow
    
    $dockerCompose = @'
version: '3.8'

services:
  searxng:
    image: searxng/searxng:latest
    container_name: rez-searxng
    ports:
      - "8080:8080"
    volumes:
      - ./searxng-settings.yml:/etc/searxng/settings.yml:ro
    restart: unless-stopped
    networks:
      - rez-network

networks:
  rez-network:
    driver: bridge
'@
    Set-Content -Path "$PROJECT_PATH\docker-compose.yml" -Value $dockerCompose -Encoding UTF8
    
    $searxngSettings = @'
# SearXNG settings
use_default_settings: true
server:
  secret_key: "rezstack_secret_key_change_me"
  limiter: false
  public_instance: false
  port: 8080
  bind_address: "0.0.0.0"
search:
  safe_search: 0
  formats:
    - html
    - json
engines:
  - name: google
    use_mobile_ui: false
    timeout: 3.0
    disabled: false
  - name: duckduckgo
    timeout: 3.0
    disabled: false
  - name: bing
    timeout: 3.0
    disabled: false
'@
    Set-Content -Path "$PROJECT_PATH\searxng-settings.yml" -Value $searxngSettings -Encoding UTF8
    Write-Host "   ✅ Docker Compose created for SearXNG" -ForegroundColor Green
    
    # ============================================
    # 9. CREATE LAUNCH SCRIPTS
    # ============================================
    Write-Host "[6/8] Creating launch scripts..." -ForegroundColor Yellow
    
    $launchAll = @'
# launch-all.ps1
Write-Host "Launching REZ HIVE Full Stack..." -ForegroundColor Cyan

# Start Docker SearXNG
Write-Host "[1/5] Starting SearXNG..." -ForegroundColor Yellow
docker-compose up -d
Start-Sleep -Seconds 3

# Start ChromaDB
Write-Host "[2/5] Starting ChromaDB..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "python chroma_server.py"

# Start FastAPI
Write-Host "[3/5] Starting FastAPI Kernel..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "python backend/kernel.py"

# Start Next.js
Write-Host "[4/5] Starting Next.js Frontend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev"

Write-Host "[5/5] Services launching..." -ForegroundColor Yellow
Write-Host ""
Write-Host "All services starting!" -ForegroundColor Green
Write-Host "Frontend: http://localhost:3000"
Write-Host "Backend:  http://localhost:8001"
Write-Host "SearXNG:  http://localhost:8080"
'@
    Set-Content -Path "$PROJECT_PATH\launch-all.ps1" -Value $launchAll -Encoding UTF8
    
    $testEndpoints = @'
# test-endpoints.ps1
Write-Host "Testing REZ HIVE Endpoints..." -ForegroundColor Cyan

$endpoints = @(
    @{Method="GET"; Url="http://localhost:3000/api/status"},
    @{Method="GET"; Url="http://localhost:3000/api/health"},
    @{Method="GET"; Url="http://localhost:3000/api/system/vitals"},
    @{Method="GET"; Url="http://localhost:3000/api/system/info"},
    @{Method="GET"; Url="http://localhost:3000/api/apps/list"},
    @{Method="GET"; Url="http://localhost:3000/api/rag/documents"},
    @{Method="POST"; Url="http://localhost:3000/api/notes"; Body=@{"content"="Test note from endpoint tester"}},
    @{Method="POST"; Url="http://localhost:3000/api/tasks"; Body=@{"title"="Test Task"}}
)

foreach ($ep in $endpoints) {
    try {
        if ($ep.Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $ep.Url -Method Get
            Write-Host "✅ $($ep.Method) $($ep.Url)" -ForegroundColor Green
        } else {
            $json = $ep.Body | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $ep.Url -Method Post -Body $json -ContentType "application/json"
            Write-Host "✅ $($ep.Method) $($ep.Url)" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ $($ep.Method) $($ep.Url)" -ForegroundColor Red
    }
}
'@
    Set-Content -Path "$PROJECT_PATH\test-endpoints.ps1" -Value $testEndpoints -Encoding UTF8
    
    Write-Host "   ✅ Launch scripts created" -ForegroundColor Green
    
    # ============================================
    # 10. CREATE REQUIREMENTS.TXT
    # ============================================
    Write-Host "[7/8] Creating requirements.txt..." -ForegroundColor Yellow
    
    $requirements = @'
# Core
fastapi
uvicorn
python-multipart
pydantic

# AI
ollama
chromadb-client
sentence-transformers
torch
transformers

# RAG
langchain
langchain-chroma
tiktoken
pypdf
python-docx
markdown

# MCP Servers
psutil
requests

# Utils
python-dotenv
'@
    Set-Content -Path "$PROJECT_PATH\requirements.txt" -Value $requirements -Encoding UTF8
    Write-Host "   ✅ requirements.txt created" -ForegroundColor Green
    
    # ============================================
    # 11. CREATE CHROMA SERVER
    # ============================================
    Write-Host "[8/8] Creating ChromaDB server script..." -ForegroundColor Yellow
    
    $chromaServer = @'
# chroma_server.py
import chromadb
import time
import sys

print("="*50)
print("REZ HIVE Memory Server")
print("="*50)

try:
    client = chromadb.PersistentClient(path="./chroma_data")
    print(f"ChromaDB version: {chromadb.__version__}")
    
    collections = client.list_collections()
    print(f"\nFound {len(collections)} collections:")
    if len(collections) == 0:
        print("  No collections yet")
    else:
        for col in collections:
            print(f"  • {col.name}: {col.count()} vectors")
    
    collection = client.get_or_create_collection("rez_hive_memory")
    print(f"\nMemory collection ready: {collection.count()} vectors")
    
    print("\n" + "="*50)
    print("Server running. Press Ctrl+C to stop")
    print("="*50)
    
    while True:
        time.sleep(1)
        
except KeyboardInterrupt:
    print("\nShutting down...")
    sys.exit(0)
except Exception as e:
    print(f"\nError: {e}")
    sys.exit(1)
'@
    Set-Content -Path "$PROJECT_PATH\chroma_server.py" -Value $chromaServer -Encoding UTF8
    Write-Host "   ✅ ChromaDB server script created" -ForegroundColor Green
    
    # ============================================
    # COMPLETE
    # ============================================
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "     REZ HIVE COMPLETE INTEGRATION SETUP!               " -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "WHAT WAS INSTALLED:" -ForegroundColor Cyan
    Write-Host "   • Python Dependencies (fastapi, torch, transformers, etc.)" -ForegroundColor White
    Write-Host "   • 5 MCP Servers (Executive, System, Process, Research, RAG)" -ForegroundColor White
    Write-Host "   • Enhanced Kernel with all endpoints" -ForegroundColor White
    Write-Host "   • Next.js proxy configuration" -ForegroundColor White
    Write-Host "   • Docker Compose for SearXNG" -ForegroundColor White
    Write-Host "   • Launch scripts" -ForegroundColor White
    Write-Host ""
    Write-Host "TO START EVERYTHING:" -ForegroundColor Yellow
    Write-Host "   .\launch-all.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "TO TEST ENDPOINTS:" -ForegroundColor Yellow
    Write-Host "   .\test-endpoints.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "REZ HIVE IS NOW A COMPLETE SOVEREIGN AI SYSTEM!" -ForegroundColor Green
    
    return
}

# ============================================================================
# START MODE
# ============================================================================
if ($Start) {
    Show-Header
    Write-Host "Starting REZ HIVE Full Stack..." -ForegroundColor Cyan
    
    # Start Docker SearXNG
    Write-Host "[1/5] Starting SearXNG..." -ForegroundColor Yellow
    docker-compose up -d
    Start-Sleep -Seconds 3
    
    # Start ChromaDB
    Write-Host "[2/5] Starting ChromaDB..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PROJECT_PATH'; python chroma_server.py"
    Start-Sleep -Seconds 3
    
    # Start FastAPI
    Write-Host "[3/5] Starting FastAPI Kernel..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PROJECT_PATH'; python backend/kernel.py"
    Start-Sleep -Seconds 3
    
    # Start Next.js
    Write-Host "[4/5] Starting Next.js Frontend..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PROJECT_PATH'; npm run dev"
    
    Write-Host "[5/5] Services launching..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "All services starting!" -ForegroundColor Green
    Write-Host "Frontend: http://localhost:3000"
    Write-Host "Backend:  http://localhost:8001"
    Write-Host "SearXNG:  http://localhost:8080"
    
    return
}

# ============================================================================
# STATUS MODE
# ============================================================================
if ($Status) {
    Show-Header
    Write-Host "Checking REZ HIVE Status..." -ForegroundColor Cyan
    
    # Check Docker
    $docker = docker ps --filter "name=rez-searxng" --format "{{.Status}}" 2>$null
    if ($docker) {
        Write-Host "✅ SearXNG: $docker" -ForegroundColor Green
    } else {
        Write-Host "❌ SearXNG: Not running" -ForegroundColor Red
    }
    
    # Check ChromaDB
    try {
        $chroma = curl.exe -s http://localhost:8000/api/v1/heartbeat
        Write-Host "✅ ChromaDB: Running on port 8000" -ForegroundColor Green
    } catch {
        Write-Host "❌ ChromaDB: Not running" -ForegroundColor Red
    }
    
    # Check FastAPI
    try {
        $fastapi = curl.exe -s http://localhost:8001/api/status
        Write-Host "✅ FastAPI: Running on port 8001 - $fastapi" -ForegroundColor Green
    } catch {
        Write-Host "❌ FastAPI: Not running" -ForegroundColor Red
    }
    
    # Check Next.js
    try {
        $nextjs = curl.exe -s http://localhost:3000
        Write-Host "✅ Next.js: Running on port 3000" -ForegroundColor Green
    } catch {
        Write-Host "❌ Next.js: Not running" -ForegroundColor Red
    }
    
    return
}

# ============================================================================
# STOP MODE
# ============================================================================
if ($Stop) {
    Show-Header
    Write-Host "Stopping REZ HIVE Services..." -ForegroundColor Cyan
    
    # Stop Docker
    docker-compose down
    
    # Kill Python processes
    taskkill /F /IM python.exe 2>$null
    taskkill /F /IM python3.exe 2>$null
    
    # Kill Node processes
    taskkill /F /IM node.exe 2>$null
    
    Write-Host "All services stopped" -ForegroundColor Green
    return
}

# ============================================================================
# SHOW MENU IF NO PARAMETERS
# ============================================================================
Show-Header
Write-Host "USAGE: .\setup-rez-hive-complete.ps1 [OPTION]" -ForegroundColor Yellow
Write-Host ""
Write-Host "OPTIONS:" -ForegroundColor White
Write-Host "  -Setup    : Install everything (dependencies, MCP servers, configs)" -ForegroundColor Cyan
Write-Host "  -Start    : Launch all services (Docker, ChromaDB, FastAPI, Next.js)" -ForegroundColor Cyan
Write-Host "  -Status   : Check status of all services" -ForegroundColor Cyan
Write-Host "  -Stop     : Stop all services" -ForegroundColor Cyan
Write-Host ""
Write-Host "EXAMPLES:" -ForegroundColor White
Write-Host "  .\setup-rez-hive-complete.ps1 -Setup" -ForegroundColor Gray
Write-Host "  .\setup-rez-hive-complete.ps1 -Start" -ForegroundColor Gray
Write-Host "  .\setup-rez-hive-complete.ps1 -Status" -ForegroundColor Gray
Write-Host ""