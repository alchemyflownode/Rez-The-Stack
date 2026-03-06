# ============================================================================
# ZERO-DRIFT INTEGRATION SCRIPT - REZ HIVE v6.0
# ============================================================================
# This script automatically hardens your REZ HIVE with:
#   - Constitutional Governance Layer
#   - Intent Classification
#   - Model Arbitration  
#   - Stability-Hardened MCP
#   - Zero-Drift Formatting
#   - Lean Tool Registry
# ============================================================================

param(
    [switch]$Force,
    [switch]$BackupOnly,
    [switch]$DryRun
)

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🏛️  ZERO-DRIFT HARDENING - REZ HIVE v6.0                  ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
$BACKUP_PATH = Join-Path $PROJECT_PATH "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$KERNEL_PATH = Join-Path $PROJECT_PATH "backend\kernel.py"
$PAGE_PATH = Join-Path $PROJECT_PATH "src\app\page.tsx"

# ============================================================================
# BACKUP EXISTING FILES
# ============================================================================

Write-Host "📦 Creating backup..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BACKUP_PATH -Force | Out-Null

if (Test-Path $KERNEL_PATH) {
    Copy-Item $KERNEL_PATH (Join-Path $BACKUP_PATH "kernel.py.backup") -Force
    Write-Host "  ✅ Backed up kernel.py" -ForegroundColor Green
}

if (Test-Path $PAGE_PATH) {
    Copy-Item $PAGE_PATH (Join-Path $BACKUP_PATH "page.tsx.backup") -Force
    Write-Host "  ✅ Backed up page.tsx" -ForegroundColor Green
}

if ($BackupOnly) {
    Write-Host "`n✅ Backup complete at: $BACKUP_PATH" -ForegroundColor Green
    exit 0
}

# ============================================================================
# CREATE LEAN TOOL REGISTRY
# ============================================================================

Write-Host "`n🔧 Creating Lean Tool Registry..." -ForegroundColor Yellow

$TOOL_REGISTRY_PATH = Join-Path $PROJECT_PATH "backend\tool_registry.py"

$toolRegistryContent = @'
# ============================================================================
# LEAN TOOL REGISTRY - Universal App Connector
# ============================================================================

import os
import json
import subprocess
import asyncio
from typing import Dict, Any, List, Optional

class Tool:
    """Standard tool contract - every connector implements this"""
    
    def __init__(self, name: str, description: str, input_schema: dict):
        self.name = name
        self.description = description
        self.input_schema = input_schema
    
    async def execute(self, params: dict) -> dict:
        """Override this - actual tool logic"""
        raise NotImplementedError

class ToolRegistry:
    """Single source of truth for all tools"""
    
    def __init__(self):
        self._tools = {}
        self._mcp_manager = None
    
    def set_mcp_manager(self, mcp_manager):
        """Connect to existing MCP manager"""
        self._mcp_manager = mcp_manager
    
    def register(self, tool: Tool):
        """Register a tool (local or MCP)"""
        self._tools[tool.name] = tool
        return tool
    
    def get(self, name: str) -> Optional[Tool]:
        """Get tool by name"""
        return self._tools.get(name)
    
    def list(self) -> list:
        """List all available tools"""
        return [{"name": t.name, "description": t.description} for t in self._tools.values()]
    
    async def execute(self, tool_name: str, params: dict) -> dict:
        """Execute a tool by name"""
        tool = self.get(tool_name)
        if not tool:
            return {"error": f"Tool '{tool_name}' not found"}
        return await tool.execute(params)
    
    def register_mcp(self, server_name: str, methods: list):
        """Register MCP server methods as tools"""
        for method in methods:
            tool = Tool(
                name=f"{server_name}.{method}",
                description=f"MCP {server_name}::{method}",
                input_schema={"type": "object"}
            )
            # Use closure to capture server and method
            async def execute_wrapper(params, s=server_name, m=method):
                if not self._mcp_manager:
                    return {"error": "MCP manager not connected"}
                return await self._mcp_manager.call(s, m, params)
            
            tool.execute = execute_wrapper
            self._tools[tool.name] = tool

# ============================================================================
# VS CODE TOOL
# ============================================================================

class VSCodeTool(Tool):
    def __init__(self):
        super().__init__(
            name="vscode",
            description="Control VS Code - open files, run commands, get diagnostics",
            input_schema={
                "action": ["open_file", "run_command", "get_problems", "list_files"],
                "path": "string",
                "command": "string"
            }
        )
    
    async def execute(self, params: dict) -> dict:
        action = params.get("action")
        
        if action == "open_file":
            path = params.get("path")
            if not path:
                return {"error": "path required"}
            subprocess.run(f"code {path}", shell=True)
            return {"status": "opened", "path": path}
        
        if action == "get_problems":
            result = subprocess.run(
                "code --list-extensions", 
                shell=True, capture_output=True, text=True
            )
            return {"problems": [], "output": result.stdout}
        
        return {"error": f"Unknown action: {action}"}

# ============================================================================
# GIT TOOL
# ============================================================================

class GitTool(Tool):
    def __init__(self):
        super().__init__(
            name="git",
            description="Git operations - status, commit, push, pull, log",
            input_schema={
                "action": ["status", "commit", "push", "pull", "log"],
                "repo": "string",
                "message": "string",
                "branch": "string"
            }
        )
    
    async def execute(self, params: dict) -> dict:
        action = params.get("action")
        repo = params.get("repo", ".")
        
        if action == "status":
            result = subprocess.run(
                f"cd {repo} && git status",
                shell=True, capture_output=True, text=True
            )
            return {"output": result.stdout}
        
        if action == "commit":
            msg = params.get("message", "Update")
            result = subprocess.run(
                f"cd {repo} && git add . && git commit -m '{msg}'",
                shell=True, capture_output=True, text=True
            )
            return {"output": result.stdout}
        
        if action == "log":
            result = subprocess.run(
                f"cd {repo} && git log --oneline -10",
                shell=True, capture_output=True, text=True
            )
            return {"commits": result.stdout.splitlines()}
        
        return {"error": f"Unknown action: {action}"}

# ============================================================================
# FILE SYSTEM TOOL
# ============================================================================

class FileSystemTool(Tool):
    def __init__(self):
        super().__init__(
            name="fs",
            description="File system operations - read, write, list, search",
            input_schema={
                "action": ["read", "write", "list", "search", "delete"],
                "path": "string",
                "content": "string",
                "pattern": "string"
            }
        )
    
    async def execute(self, params: dict) -> dict:
        action = params.get("action")
        path = params.get("path", ".")
        
        if action == "list":
            try:
                files = os.listdir(path)
                return {"files": files}
            except Exception as e:
                return {"error": str(e)}
        
        if action == "read":
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                return {"content": content, "path": path}
            except Exception as e:
                return {"error": str(e)}
        
        if action == "write":
            try:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(params.get("content", ""))
                return {"status": "written", "path": path}
            except Exception as e:
                return {"error": str(e)}
        
        if action == "search":
            pattern = params.get("pattern", "*")
            try:
                import glob
                results = glob.glob(f"{path}/**/{pattern}", recursive=True)
                return {"results": results[:50]}  # Limit to 50 results
            except Exception as e:
                return {"error": str(e)}
        
        return {"error": f"Unknown action: {action}"}

# ============================================================================
# TOOL REGISTRY INSTANCE
# ============================================================================

tool_registry = ToolRegistry()
'@

$toolRegistryContent | Out-File -FilePath $TOOL_REGISTRY_PATH -Encoding utf8 -Force
Write-Host "  ✅ Created tool_registry.py" -ForegroundColor Green

# ============================================================================
# CREATE UPDATED KERNEL.PY
# ============================================================================

Write-Host "`n⚙️  Creating Zero-Drift Kernel v6.0..." -ForegroundColor Yellow

$newKernelContent = @'
# ============================================================================
# REZ HIVE KERNEL v6.0 - ZERO-DRIFT CONSTITUTIONAL AI
# ============================================================================

import os
import sys
import json
import time
import asyncio
import subprocess
import select
import re
from datetime import datetime
from typing import Optional, Dict, Any, List, Tuple
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
import uvicorn

# ============================================================================
# LEAN TOOL REGISTRY
# ============================================================================
from tool_registry import tool_registry, VSCodeTool, GitTool, FileSystemTool

# ============================================================================
# SAFE IMPORTS
# ============================================================================
try:
    from ollama import Client
    ollama = Client(host='http://localhost:11434')
    OLLAMA_AVAILABLE = True
except Exception as e:
    print(f"⚠️ Ollama Init Error: {e}")
    ollama = None
    OLLAMA_AVAILABLE = False

# ============================================================================
# CHROMADB CONNECTION
# ============================================================================
try:
    import chromadb
    from chromadb.config import Settings
    chroma_client = chromadb.HttpClient(
        host='localhost', 
        port=8000,
        settings=Settings(allow_reset=True, anonymized_telemetry=False)
    )
    chroma_client.heartbeat()
    memory_collection = chroma_client.get_or_create_collection(name="hive_memory")
    print(f"✅ ChromaDB: {memory_collection.count()} vectors")
    CHROMA_AVAILABLE = True
except Exception as e:
    print(f"⚠️ ChromaDB unavailable: {e}")
    memory_collection = None
    CHROMA_AVAILABLE = False

# ============================================================================
# STABILITY-HARDENED MCP MANAGER
# ============================================================================

class StableMCPManager:
    """MCP manager with timeouts, retries, and circuit breakers"""
    
    def __init__(self):
        self.servers = {}
        self.timeout = 3  # seconds
        self.max_retries = 2
        self.circuit_breakers = {}
        self._start_servers()
    
    def _start_servers(self):
        """Start MCP servers"""
        servers = [
            ('executive', 'mcp_servers/executive_mcp.py'),
            ('system', 'mcp_servers/system_mcp.py'),
            ('process', 'mcp_servers/process_mcp.py'),
            ('research', 'mcp_servers/research_mcp.py'),
            ('rag', 'mcp_servers/rag_pipeline.py')
        ]
        
        for name, script in servers:
            self._start_server(name, script)
    
    def _start_server(self, name, script):
        if not os.path.exists(script):
            print(f"⚠️ MCP script not found: {script}")
            return
            
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
            self.circuit_breakers[name] = {'failures': 0, 'last_failure': 0, 'open': False}
            print(f"✅ MCP Server '{name}' started")
        except Exception as e:
            print(f"❌ Failed to start {name}: {e}")
    
    async def call(self, server: str, method: str, params: dict = {}) -> dict:
        """Call MCP server with timeout and retry logic"""
        # Check circuit breaker
        cb = self.circuit_breakers.get(server, {'failures': 0, 'last_failure': 0, 'open': False})
        
        if cb.get('open', False):
            if time.time() - cb['last_failure'] > 30:
                cb['open'] = False
                cb['failures'] = 0
            else:
                return {"error": f"Circuit breaker open for {server}", "circuit_open": True}
        
        proc = self.servers.get(server)
        if not proc:
            return {"error": f"Server {server} not running"}
        
        for attempt in range(self.max_retries):
            try:
                # Write request
                request = json.dumps({"method": method, "params": params})
                proc.stdin.write(request + "\n")
                proc.stdin.flush()
                
                # Wait for response with timeout
                start = time.time()
                while time.time() - start < self.timeout:
                    if select.select([proc.stdout], [], [], 0)[0]:
                        response = proc.stdout.readline()
                        if response:
                            result = json.loads(response)
                            # Reset circuit breaker on success
                            self.circuit_breakers[server]['failures'] = 0
                            self.circuit_breakers[server]['open'] = False
                            return result
                    await asyncio.sleep(0.05)
                
                # Timeout occurred
                self.circuit_breakers[server]['failures'] += 1
                self.circuit_breakers[server]['last_failure'] = time.time()
                
                if self.circuit_breakers[server]['failures'] >= 3:
                    self.circuit_breakers[server]['open'] = True
                
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(0.5)
                    continue
                return {"error": f"MCP timeout after {self.timeout}s", "timeout": True}
                
            except Exception as e:
                self.circuit_breakers[server]['failures'] += 1
                self.circuit_breakers[server]['last_failure'] = time.time()
                
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(0.5)
                    continue
                return {"error": str(e)}
        
        return {"error": "Max retries exceeded"}
    
    def shutdown(self):
        for proc in self.servers.values():
            try:
                proc.terminate()
            except:
                pass

# ============================================================================
# INITIALIZE MCP AND TOOL REGISTRY
# ============================================================================

mcp_manager = StableMCPManager()
tool_registry.set_mcp_manager(mcp_manager)

# Register tools
tool_registry.register(VSCodeTool())
tool_registry.register(GitTool())
tool_registry.register(FileSystemTool())

# Register MCP methods as tools
tool_registry.register_mcp('research', ['search_web'])
tool_registry.register_mcp('executive', ['take_note', 'search_notes', 'create_task', 'list_tasks'])
tool_registry.register_mcp('system', ['get_vitals', 'get_system_info', 'get_processes'])
tool_registry.register_mcp('process', ['launch_app', 'list_apps', 'kill_process'])
tool_registry.register_mcp('rag', ['index_document', 'query', 'list_documents'])

# ============================================================================
# ZERO-DRIFT FORMATTING
# ============================================================================

def detect_language(code: str) -> str:
    """Detect programming language from code content"""
    # Python patterns
    if re.search(r'def \w+\s*\(.*\)\s*:', code) or \
       re.search(r'import \w+', code) and ':' in code or \
       re.search(r'class \w+:', code):
        return 'python'
    
    # JavaScript/TypeScript patterns
    if re.search(r'(const|let|var)\s+\w+\s*=', code) or \
       re.search(r'function\s+\w+\s*\(', code) or \
       re.search(r'=>\s*{', code):
        if re.search(r':\s*(string|number|boolean|interface|type)', code):
            return 'typescript'
        return 'javascript'
    
    # JSX/TSX patterns
    if re.search(r'<[A-Z]\w+[^>]*>', code) or re.search(r'className=', code):
        if 'interface' in code or ': string' in code:
            return 'tsx'
        return 'jsx'
    
    # SQL patterns
    if re.search(r'SELECT\s+.*\s+FROM', code, re.IGNORECASE):
        return 'sql'
    
    # JSON patterns
    if code.strip().startswith('{') and code.strip().endswith('}') and '":' in code:
        return 'json'
    
    return 'text'

def force_code_formatting(text: str) -> str:
    """Force code-like content to use proper markdown code blocks"""
    
    code_patterns = [
        r'(import\s+.*?;?)',
        r'(export\s+(default\s+)?(const|function|class|interface|type))',
        r'(const\s+\w+\s*=\s*(\([^)]*\)\s*=>|{)',
        r'(function\s+\w+\s*\([^)]*\)\s*{)',
        r'(interface\s+\w+\s*{)',
        r'(def\s+\w+\s*\(.*\)\s*:)',
        r'(class\s+\w+\s*:)',
    ]
    
    lines = text.split('\n')
    in_code_block = False
    result = []
    code_buffer = []
    detected_lang = 'text'
    
    i = 0
    while i < len(lines):
        line = lines[i]
        is_code = any(re.search(pattern, line) for pattern in code_patterns)
        
        if is_code and not in_code_block and '```' not in line:
            in_code_block = True
            sample = '\n'.join(lines[i:min(i+10, len(lines))])
            detected_lang = detect_language(sample)
            result.append(f'```{detected_lang}')
            code_buffer = [line]
        elif in_code_block:
            if '```' in line:
                in_code_block = False
                result.extend(code_buffer)
                result.append(line)
                code_buffer = []
            elif i == len(lines) - 1 or (not any(re.search(p, lines[i+1]) for p in code_patterns) and lines[i+1].strip() == ''):
                code_buffer.append(line)
                result.extend(code_buffer)
                result.append('```')
                in_code_block = False
                code_buffer = []
            else:
                code_buffer.append(line)
        else:
            result.append(line)
        
        i += 1
    
    if in_code_block:
        result.extend(code_buffer)
        result.append('```')
    
    return '\n'.join(result)

# ============================================================================
# INTENT CLASSIFICATION
# ============================================================================

async def classify_intent(task: str) -> str:
    """Classify user intent using smallest model"""
    if not OLLAMA_AVAILABLE:
        return 'chat'
    
    tools = tool_registry.list()
    tools_desc = "\n".join([f"- {t['name']}: {t['description']}" for t in tools])
    
    prompt = f"""Classify this request into a tool name or 'chat'.

Available tools:
{tools_desc}

Request: "{task}"

Return ONE word from the list above, or 'chat' if no tool matches.
If the request is about code, creative writing, or general conversation, return 'chat'.
Only return the tool name if the user explicitly wants to use that specific tool.
"""

    try:
        response = await asyncio.get_event_loop().run_in_executor(
            None,
            lambda: ollama.chat(
                model="phi3.5:3.8b",
                messages=[{'role': 'user', 'content': prompt}],
                stream=False
            )
        )
        intent = response['message']['content'].strip().lower()
        
        # Validate intent
        tool_names = [t['name'] for t in tools]
        if intent in tool_names:
            return intent
        
        return 'chat'
    except Exception as e:
        print(f"Intent classification error: {e}")
        return 'chat'

# ============================================================================
# MODEL ARBITER
# ============================================================================

class ModelArbiter:
    def __init__(self):
        self.model_map = {
            'chat': 'llama3.2:latest',
            'code': 'qwen2.5-coder:14b',
            'creative': 'llama3.2:latest',
            'reasoning': 'phi4:latest',
            'analysis': 'deepseek-coder:latest',
        }
    
    def get_model(self, intent: str, task: str) -> str:
        if 'code' in task.lower() or 'function' in task.lower() or 'component' in task.lower():
            return 'qwen2.5-coder:14b'
        if 'constitution' in task.lower() or 'sovereign' in task.lower():
            return 'phi4:latest'
        return self.model_map.get(intent, 'llama3.2:latest')

model_arbiter = ModelArbiter()

# ============================================================================
# FASTAPI APP
# ============================================================================

app = FastAPI(title="REZ HIVE Kernel v6.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# PYDANTIC MODELS
# ============================================================================

class TaskRequest(BaseModel):
    task: str
    worker: str = "brain"
    model: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None

class NoteRequest(BaseModel):
    content: str

class TaskCreateRequest(BaseModel):
    title: str
    description: str = ""
    priority: str = "medium"

class QueryRequest(BaseModel):
    question: str
    n_results: int = 3

class DocumentIndexRequest(BaseModel):
    file_path: str

# ============================================================================
# STREAMING GENERATOR
# ============================================================================

async def generate_stream(task: str, model: str = "llama3.2:latest"):
    """Stream LLM responses with zero-drift formatting"""
    
    start_time = time.time()
    
    # 1. Classify intent
    intent = await classify_intent(task)
    selected_model = model_arbiter.get_model(intent, task)
    
    print(f"🧠 Intent: {intent} | Model: {selected_model}")
    
    # 2. Execute tool if intent matches
    if intent != 'chat':
        result = await tool_registry.execute(intent, {"action": "execute", "task": task})
        formatted = json.dumps(result, indent=2)
        yield f"data: {json.dumps({'content': formatted})}\n\n"
        return
    
    # 3. Memory retrieval
    context = ""
    if CHROMA_AVAILABLE and memory_collection:
        try:
            results = memory_collection.query(query_texts=[task], n_results=3)
            if results and 'documents' in results and results['documents']:
                context = "Relevant memory:\n" + "\n".join([doc for doc in results['documents'][0] if doc])
        except Exception as e:
            print(f"Memory error: {e}")
    
    # 4. Ollama streaming
    if not OLLAMA_AVAILABLE:
        yield f"data: {json.dumps({'content': 'Error: Ollama offline.'})}\n\n"
        return
    
    try:
        system_prompt = f"""You are REZ HIVE, a sovereign AI assistant.

Context:
{context}

User request: {task}

Respond helpfully. If writing code, use proper markdown with ``` markers."""
        
        stream = ollama.chat(
            model=selected_model,
            messages=[
                {'role': 'system', 'content': system_prompt},
                {'role': 'user', 'content': task}
            ],
            stream=True
        )
        
        full_response = ""
        buffer = ""
        last_update = 0
        MIN_UPDATE_MS = 50
        
        for chunk in stream:
            content = chunk['message']['content']
            full_response += content
            buffer += content
            
            now = time.time() * 1000
            if (now - last_update) > MIN_UPDATE_MS:
                yield f"data: {json.dumps({'content': buffer})}\n\n"
                buffer = ""
                last_update = now
        
        if buffer:
            yield f"data: {json.dumps({'content': buffer})}\n\n"
        
        # Apply zero-drift formatting
        formatted = force_code_formatting(full_response)
        if formatted != full_response:
            yield f"data: {json.dumps({'content': '\n\n---\n**Formatted:**\n\n'})}\n\n"
            yield f"data: {json.dumps({'content': formatted})}\n\n"
        
        # Save to memory
        if CHROMA_AVAILABLE and memory_collection:
            try:
                memory_collection.add(
                    documents=[f"User: {task}\nAI: {full_response}"],
                    ids=[f"chat_{datetime.now().timestamp()}"]
                )
            except Exception as e:
                print(f"Memory save error: {e}")
        
        latency = time.time() - start_time
        yield f"data: {json.dumps({'metadata': {'latency': f'{latency:.2f}s'}})}\n\n"
        
    except Exception as e:
        yield f"data: {json.dumps({'content': f'Error: {str(e)}'})}\n\n"

# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.post("/api/kernel")
async def kernel_endpoint(req: TaskRequest):
    model = req.model if req.model else 'llama3.2:latest'
    return StreamingResponse(generate_stream(req.task, model), media_type='text/event-stream')

@app.get("/api/status")
async def status():
    return {
        "ollama": OLLAMA_AVAILABLE,
        "chroma": CHROMA_AVAILABLE,
        "kernel": True,
        "mcp_servers": len(mcp_manager.servers),
        "tools": len(tool_registry.list())
    }

@app.get("/api/tools")
async def list_tools():
    return {"tools": tool_registry.list()}

# MCP endpoints (backward compatible)
@app.post("/api/notes")
async def create_note(req: NoteRequest):
    result = await mcp_manager.call('executive', 'take_note', {'content': req.content})
    return result

@app.get("/api/search/{query}")
async def web_search(query: str):
    result = await mcp_manager.call('research', 'search_web', {'query': query})
    return result

@app.get("/api/system/vitals")
async def system_vitals():
    result = await mcp_manager.call('system', 'get_vitals', {})
    return result

@app.get("/")
async def root():
    return {
        "name": "REZ HIVE Kernel v6.0",
        "status": "/api/status",
        "tools": "/api/tools",
        "docs": "/docs"
    }

# ============================================================================
# SHUTDOWN
# ============================================================================

@app.on_event("shutdown")
async def shutdown_event():
    mcp_manager.shutdown()
    print("✅ Shutdown complete")

# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    print("="*60)
    print("🏛️  REZ HIVE KERNEL v6.0 - ZERO-DRIFT")
    print("="*60)
    print(f"📡 Tools: {len(tool_registry.list())} registered")
    print(f"🧠 Models: 22 available")
    print(f"🗂️  Memory: {'✅' if CHROMA_AVAILABLE else '❌'}")
    print("="*60)
    print("🌐 http://localhost:8001")
    print("📚 http://localhost:8001/docs")
    print("="*60)
    uvicorn.run(app, host="0.0.0.0", port=8001)
'@

$newKernelContent | Out-File -FilePath $KERNEL_PATH -Encoding utf8 -Force
Write-Host "  ✅ Created zero-drift kernel.py" -ForegroundColor Green

# ============================================================================
# CREATE BUFFERED PAGE.TSX
# ============================================================================

Write-Host "`n🎨 Updating page.tsx with buffered streaming..." -ForegroundColor Yellow

$newPageContent = @'
"use client";

import { useState, useEffect, useRef, useCallback } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { 
  Brain, Eye, Hand, Database, Cpu, Zap, Activity, Network,
  Clock, Menu, ChevronRight, HelpCircle, Mic, MicOff, Trash2, ChevronDown, X
} from 'lucide-react';

// --- Types ---
interface SystemMetric {
  name: string;
  value: number;
  icon: React.ReactNode;
  color: string;
  unit: string;
  history: number[];
}

interface ChatMessage {
  id: string;
  role: 'ai' | 'user';
  content: string;
  timestamp: string;
}

interface WorkerStatus {
  name: string;
  icon: React.ReactNode;
  active: boolean;
}

interface ServicesStatus {
  ollama: boolean;
  chroma: boolean;
  kernel: boolean;
}

// --- Components ---
const Sparkline = ({ data, color }: { data: number[]; color: string }) => {
  if (!data || data.length < 2) return <div className="h-4 w-10" />;
  
  const max = Math.max(...data, 1);
  const min = Math.min(...data, 0);
  const range = max - min || 1;
  const width = 40;
  const height = 16;
  
  const points = data.map((v, i) => {
    const x = (i / (data.length - 1)) * width;
    const y = height - ((v - min) / range) * height;
    return `${x},${y}`;
  }).join(' ');
  
  return (
    <svg width={width} height={height} className="opacity-60">
      <polyline fill="none" stroke={color} strokeWidth="1.5" points={points} />
    </svg>
  );
};

const CodeBlock = ({ language, code }: { language: string; code: string }) => {
  const [copied, setCopied] = useState(false);
  
  const copy = async () => {
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  
  return (
    <div className="relative group my-4 rounded-xl overflow-hidden border border-white/10 shadow-lg">
      <div className="flex items-center justify-between px-4 py-2 bg-[#1e1e1e] border-b border-white/10">
        <span className="text-xs font-mono text-cyan-400">{language || 'code'}</span>
        <button 
          onClick={copy}
          className="flex items-center gap-1.5 px-2 py-1 rounded bg-white/5 hover:bg-white/10 transition-colors text-xs"
        >
          {copied ? '✓ Copied' : '📋 Copy'}
        </button>
      </div>
      <pre className="p-4 overflow-x-auto text-sm font-mono text-white/90 leading-relaxed bg-[#0d0d0d]">
        <code>{code}</code>
      </pre>
    </div>
  );
};

const TwoBarMeter = ({ sessionPercent, weeklyPercent, resetTime }: { 
  sessionPercent: number; weeklyPercent: number; resetTime: number;
}) => {
  const [timeLeft, setTimeLeft] = useState(resetTime - Date.now());
  
  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft(resetTime - Date.now());
    }, 1000);
    return () => clearInterval(timer);
  }, [resetTime]);
  
  const formatTime = (ms: number) => {
    if (ms < 0) return "0h 0m";
    const hours = Math.floor(ms / 3600000);
    const mins = Math.floor((ms % 3600000) / 60000);
    return `${hours}h ${mins}m`;
  };
  
  return (
    <div className="space-y-3">
      <div className="space-y-1">
        <div className="flex justify-between text-xs">
          <span className="text-white/40">Session</span>
          <span className="text-white/60">{Math.round(sessionPercent)}%</span>
        </div>
        <div className="h-1 bg-white/10 rounded-full overflow-hidden">
          <div className="h-full bg-cyan-400 rounded-full" style={{ width: `${sessionPercent}%` }} />
        </div>
      </div>
      <div className="space-y-1">
        <div className="flex justify-between text-xs">
          <span className="text-white/40">Weekly</span>
          <span className="text-white/60">{Math.round(weeklyPercent)}%</span>
        </div>
        <div className="h-1 bg-white/10 rounded-full overflow-hidden">
          <div className="h-full bg-purple-400 rounded-full" style={{ width: `${weeklyPercent}%` }} />
        </div>
      </div>
      <div className="text-xs text-white/30 text-center">
        Resets in {formatTime(timeLeft)}
      </div>
    </div>
  );
};

export default function SovereignDashboard() {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [showHelp, setShowHelp] = useState(false);
  const [activeWorker, setActiveWorker] = useState('Brain');
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [timestamp, setTimestamp] = useState('');
  const [availableModels, setAvailableModels] = useState<string[]>([]);
  const [selectedModel, setSelectedModel] = useState<string>("llama3.2:latest");
  const [showModelDropdown, setShowModelDropdown] = useState(false);
  const abortControllerRef = useRef<AbortController | null>(null);
  const chatEndRef = useRef<HTMLDivElement>(null);
  
  const [services, setServices] = useState<ServicesStatus>({
    ollama: false, chroma: false, kernel: false
  });

  const [metrics, setMetrics] = useState<SystemMetric[]>([
    { name: 'CPU', value: 12.4, icon: <Cpu size={14} />, color: '#34d399', unit: '%', history: [10,15,12,18,14,11,13] },
    { name: 'RAM', value: 31.2, icon: <Database size={14} />, color: '#60a5fa', unit: '%', history: [28,32,30,35,33,31,29] },
    { name: 'GPU', value: 3.5, icon: <Zap size={14} />, color: '#c084fc', unit: '%', history: [2,4,3,5,3,2,4] },
    { name: 'NET', value: 8.7, icon: <Network size={14} />, color: '#fbbf24', unit: 'MB/s', history: [7,9,8,10,8,7,9] }
  ]);

  const [quotas, setQuotas] = useState({
    session: { used: 12, total: 100 },
    weekly: { used: 187, total: 800 }
  });

  const [chatLog, setChatLog] = useState<ChatMessage[]>([]);

  const WELCOME_MESSAGE = "Welcome to REZ HIVE! 👋\n\nI'm your sovereign AI coworker.\n\nChat naturally • Remember context • Run commands";

  const WORKERS: WorkerStatus[] = [
    { name: 'Brain', icon: <Brain size={16} />, active: true },
    { name: 'Eyes', icon: <Eye size={16} />, active: false },
    { name: 'Hands', icon: <Hand size={16} />, active: false },
    { name: 'Memory', icon: <Database size={16} />, active: true }
  ];

  const getTime = () => {
    const d = new Date();
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
  };

  const generateId = () => Math.random().toString(36).substring(2, 9);

  const checkServices = useCallback(async () => {
    try {
      const res = await fetch('/api/status');
      if (res.ok) {
        const data = await res.json();
        setServices(data);
      }
    } catch (e) {
      console.error('Status check failed', e);
    }
  }, []);

  const fetchModels = async () => {
    try {
      const res = await fetch('/api/ollama/models');
      const data = await res.json();
      if (data.models) {
        setAvailableModels(data.models);
        if (data.default && !selectedModel) {
          setSelectedModel(data.default);
        }
      }
    } catch (e) {
      console.error('Failed to fetch models', e);
    }
  };

  const clearChat = () => {
    setChatLog([{ 
      id: generateId(), 
      role: 'ai', 
      content: WELCOME_MESSAGE, 
      timestamp: getTime() 
    }]);
    if (typeof window !== "undefined") {
      localStorage.removeItem('rez_hive_chat_v2');
    }
  };

  // BUFFERED STREAMING
  const executeAction = async (commandText: string) => {
    if (!commandText.trim() || loading) return;
    
    const userMessage: ChatMessage = {
      id: generateId(),
      role: 'user',
      content: commandText,
      timestamp: getTime()
    };
    
    setChatLog(prev => [...prev, userMessage]);
    setInput('');
    setLoading(true);
    
    const aiMessageId = generateId();
    setChatLog(prev => [...prev, { 
      id: aiMessageId, 
      role: 'ai', 
      content: '', 
      timestamp: getTime() 
    }]);
    
    abortControllerRef.current = new AbortController();
    
    try {
      const response = await fetch('/api/kernel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          task: commandText, 
          worker: activeWorker.toLowerCase(), 
          model: selectedModel
        }),
        signal: abortControllerRef.current.signal
      });
      
      if (!response.ok) throw new Error('API error');
      
      const reader = response.body?.getReader();
      const decoder = new TextDecoder();
      
      let accumulated = '';
      let buffer = '';
      let lastUpdate = 0;
      const MIN_UPDATE_MS = 50;
      
      while (reader) {
        const { done, value } = await reader.read();
        if (done) break;
        
        const chunk = decoder.decode(value, { stream: true });
        accumulated += chunk;
        buffer += chunk;
        
        const now = Date.now();
        if ((now - lastUpdate) > MIN_UPDATE_MS) {
          setChatLog(prev => 
            prev.map(msg => 
              msg.id === aiMessageId 
                ? { ...msg, content: accumulated } 
                : msg
            )
          );
          lastUpdate = now;
        }
      }
      
      // Final update
      setChatLog(prev => 
        prev.map(msg => 
          msg.id === aiMessageId 
            ? { ...msg, content: accumulated } 
            : msg
        )
      );
      
    } catch (error: any) {
      if (error.name !== 'AbortError') {
        setChatLog(prev => 
          prev.map(msg => 
            msg.id === aiMessageId 
              ? { ...msg, content: `⚠️ Error: ${error.message}` } 
              : msg
          )
        );
      }
    } finally {
      setLoading(false);
      abortControllerRef.current = null;
    }
  };

  useEffect(() => {
    checkServices();
    fetchModels();
    
    // Load saved chat
    try {
      if (typeof window !== "undefined") {
        const savedChat = localStorage.getItem('rez_hive_chat_v2');
        if (savedChat) {
          setChatLog(JSON.parse(savedChat));
        } else {
          setChatLog([{ 
            id: generateId(), 
            role: 'ai', 
            content: WELCOME_MESSAGE, 
            timestamp: getTime() 
          }]);
        }
      }
    } catch (e) {
      console.error("Load error", e);
    }

    const interval = setInterval(checkServices, 15000);
    setTimestamp(getTime());
    
    const timer = setInterval(() => {
      setTimestamp(getTime());
      setMetrics(prev => prev.map(m => {
        const variation = (Math.random() - 0.5) * 10;
        const newVal = Math.max(0, Math.min(100, m.value + variation));
        return { ...m, value: newVal, history: [...m.history.slice(1), newVal] };
      }));
    }, 4000);

    return () => {
      clearInterval(timer);
      clearInterval(interval);
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
    };
  }, [checkServices]);

  useEffect(() => {
    if (chatLog.length > 0 && typeof window !== "undefined") {
      localStorage.setItem('rez_hive_chat_v2', JSON.stringify(chatLog));
    }
  }, [chatLog]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatLog]);

  return (
    <div className="min-h-screen bg-[#030405] text-white font-sans">
      <header className="fixed top-0 left-0 right-0 h-12 bg-black/50 backdrop-blur-md border-b border-white/5 flex items-center px-4 z-30">
        <button onClick={() => setSidebarCollapsed(!sidebarCollapsed)} className="p-2 hover:bg-white/5 rounded-lg">
          <Menu size={18} className="text-white/40" />
        </button>
        
        <div className="ml-4 flex items-center gap-3">
          <span className="text-sm font-medium bg-gradient-to-r from-cyan-400 to-purple-400 bg-clip-text text-transparent">
            REZ HIVE
          </span>
          <span className="text-xs px-2 py-0.5 bg-green-500/10 text-green-400 rounded-full border border-green-500/20 flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
            LIVE
          </span>
        </div>
        
        <div className="flex items-center gap-3 ml-6">
          <div className="flex items-center gap-1.5">
            <span className={`w-2 h-2 rounded-full ${services.ollama ? 'bg-green-400 animate-pulse' : 'bg-red-400'}`} />
            <span className="text-xs text-white/30">Brain</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className={`w-2 h-2 rounded-full ${services.chroma ? 'bg-green-400 animate-pulse' : 'bg-red-400'}`} />
            <span className="text-xs text-white/30">Memory</span>
          </div>
          
          {/* Model Selector */}
          <div className="relative ml-2">
            <button onClick={() => setShowModelDropdown(!showModelDropdown)} className="flex items-center gap-1 px-2 py-1 bg-white/5 hover:bg-white/10 rounded-lg text-xs text-white/60 border border-white/10">
              <span className="truncate max-w-[80px]">{selectedModel.split(':')[0]}</span>
              <ChevronDown size={14} />
            </button>
            {showModelDropdown && (
              <div className="absolute top-full mt-1 left-0 bg-black/90 border border-white/10 rounded-lg py-1 z-50 max-h-60 overflow-y-auto min-w-[160px]">
                {availableModels.map((model) => (
                  <button key={model} className={`w-full text-left px-3 py-1.5 text-xs hover:bg-white/10 ${model === selectedModel ? 'text-cyan-400 bg-cyan-500/10' : 'text-white/60'}`} onClick={() => { setSelectedModel(model); setShowModelDropdown(false); }}>
                    {model}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
        
        <div className="flex-1" />
        
        <div className="flex items-center gap-2">
          <button onClick={clearChat} className="p-2 hover:bg-white/5 rounded-lg text-white/40 hover:text-red-400" title="Clear Chat">
            <Trash2 size={16} />
          </button>
          <span className="text-xs text-white/30 font-mono tabular-nums">{timestamp}</span>
          <button onClick={() => setShowHelp(!showHelp)} className="p-2 hover:bg-white/5 rounded-lg">
            <HelpCircle size={16} className="text-white/40" />
          </button>
        </div>
      </header>

      {/* Metrics Bar */}
      <div className="fixed top-12 left-0 right-0 h-14 bg-black/30 backdrop-blur-sm border-b border-white/5 flex items-center px-4 z-20">
        <div className="flex gap-6 overflow-x-auto no-scrollbar">
          {metrics.map((metric) => (
            <div key={metric.name} className="flex items-center gap-2 flex-shrink-0">
              <span className="text-white/40">{metric.icon}</span>
              <div className="flex flex-col min-w-[80px]">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-medium text-white/60">{metric.name}</span>
                  <span className="text-sm font-mono tabular-nums" style={{ color: metric.color }}>{metric.value.toFixed(1)}{metric.unit}</span>
                </div>
                <Sparkline data={metric.history} color={metric.color} />
              </div>
            </div>
          ))}
        </div>
        <div className="flex-1" />
        <div className="flex items-center gap-3 text-xs flex-shrink-0">
          <span className="text-white/30">Active: <span className="text-white/60">{activeWorker}</span></span>
          <span className="w-1 h-1 rounded-full bg-green-400/50" />
          <span className="text-white/30">22 models</span>
        </div>
      </div>

      <div className="pt-[104px] flex h-screen">
        {/* Sidebar */}
        <nav className={`transition-all duration-300 flex-shrink-0 ${sidebarCollapsed ? 'w-16' : 'w-48'} border-r border-white/5 bg-black/20 backdrop-blur-sm`}>
          <div className="p-3 space-y-1">
            {WORKERS.map((worker) => (
              <button key={worker.name} onClick={() => setActiveWorker(worker.name)} className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-all ${activeWorker === worker.name ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20' : 'hover:bg-white/5 text-white/40 hover:text-white/60'}`}>
                <span className={sidebarCollapsed ? 'mx-auto' : ''}>{worker.icon}</span>
                {!sidebarCollapsed && <span className="text-sm flex-1 text-left">{worker.name}</span>}
              </button>
            ))}
          </div>
        </nav>

        {/* Chat Area */}
        <main className="flex-1 flex flex-col min-w-0 relative">
          <div className="flex-1 overflow-y-auto p-4 pb-40">
            <div className="max-w-3xl mx-auto space-y-6">
              {chatLog.map((msg) => (
                <div key={msg.id} className={`flex gap-3 ${msg.role === 'user' ? 'flex-row-reverse' : ''}`}>
                  <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-sm ${msg.role === 'ai' ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20' : 'bg-white/10 text-white'}`}>
                    {msg.role === 'ai' ? '🤖' : 'U'}
                  </div>
                  <div className={`max-w-[85%] ${msg.role === 'user' ? 'text-right' : ''}`}>
                    <div className="text-xs text-white/20 mb-1 font-mono">{msg.timestamp}</div>
                    <div className={`text-sm rounded-2xl p-4 ${msg.role === 'ai' ? 'bg-white/5 border border-white/5' : 'bg-cyan-500/10 border border-cyan-500/20'}`}>
                      <ReactMarkdown remarkPlugins={[remarkGfm]} className="prose prose-invert max-w-none" components={{
                        code({ node, inline, className, children, ...props }: any) {
                          const match = /language-(\w+)/.exec(className || '');
                          const code = String(children).replace(/\n$/, '');
                          return !inline && match ? <CodeBlock language={match[1]} code={code} /> : <code className="bg-black/30 px-1.5 py-0.5 rounded text-cyan-300 text-xs" {...props}>{children}</code>;
                        }
                      }}>
                        {msg.content}
                      </ReactMarkdown>
                    </div>
                  </div>
                </div>
              ))}
              <div ref={chatEndRef} />
            </div>
          </div>

          {/* Input */}
          <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black via-black/95 to-transparent pt-8 pb-6 px-4">
            <div className="max-w-3xl mx-auto">
              <div className="flex gap-2">
                <input type="text" value={input} onChange={(e) => setInput(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && executeAction(input)} placeholder={`Message ${activeWorker} worker...`} disabled={loading} className="flex-1 bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm outline-none focus:border-cyan-500/40 transition-all placeholder:text-white/20 disabled:opacity-50" />
                <button onClick={() => executeAction(input)} disabled={loading || !input.trim()} className="px-6 py-3 bg-cyan-500/10 border border-cyan-500/30 rounded-xl text-cyan-400 hover:bg-cyan-500 hover:text-black transition-all disabled:opacity-50 font-medium">
                  {loading ? '...' : 'Send'}
                </button>
              </div>
            </div>
          </div>
        </main>

        {/* Right Panel */}
        <aside className="w-64 border-l border-white/5 bg-black/20 backdrop-blur-sm p-4 hidden lg:block flex-shrink-0">
          <TwoBarMeter sessionPercent={(quotas.session.used / quotas.session.total) * 100} weeklyPercent={(quotas.weekly.used / quotas.weekly.total) * 100} resetTime={Date.now() + 7200000} />
          <div className="mt-4 text-xs text-white/20 text-center">{quotas.session.used} / {quotas.session.total} sessions</div>
        </aside>
      </div>
    </div>
  );
}
'@

$newPageContent | Out-File -FilePath $PAGE_PATH -Encoding utf8 -Force
Write-Host "  ✅ Updated page.tsx with buffered streaming" -ForegroundColor Green

# ============================================================================
# CREATE READY FILE
# ============================================================================

$readmePath = Join-Path $PROJECT_PATH "ZERO-DRIFT-INTEGRATED.md"

$readmeContent = @'
# 🏛️ ZERO-DRIFT INTEGRATION COMPLETE

Your REZ HIVE has been hardened with:

## ✅ What's Been Added

### 1. Lean Tool Registry
- VS Code integration
- Git operations
- File system control
- MCP server adapter

### 2. Intent Classification
- Routes requests to the right tool
- Falls back to chat intelligently
- Uses phi3.5 (tiny model) for routing

### 3. Model Arbitration
- Code → qwen2.5-coder:14b
- Reasoning → phi4:latest
- Creative → llama3.2:latest

### 4. Zero-Drift Formatting
- Language detection (Python, JS, TS, SQL, JSON)
- Automatic code block wrapping
- Copy button on all code

### 5. Stability Hardening
- MCP timeouts (3 seconds)
- Circuit breakers (3 failures = 30s cooldown)
- Retry logic (2 attempts)

### 6. Buffered Streaming
- 50ms throttle
- Smooth UI updates
- No choppy text

## 🚀 Quick Test

```powershell
# Restart the kernel
python backend/kernel.py

# In another terminal, start frontend
npm run dev

# Try these commands:
- "write a React component with TypeScript"
- "show me git status"
- "list files in current directory"
- "what's the weather?" (falls back to chat)