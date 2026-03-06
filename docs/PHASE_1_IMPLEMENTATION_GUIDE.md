# 🚀 Phase 1 Implementation - Step-by-Step Guide

**Status:** Ready to implement with provided code files

## ✅ What's Already Created

These files are ready in your backend directory:
- ✅ `models.py` - SQLAlchemy database models
- ✅ `database.py` - Database setup & connection pooling  
- ✅ `auth.py` - JWT token generation & verification
- ✅ `services.py` - Business logic layer
- ✅ `middleware.py` - Logging & error handling
- ✅ `IMPLEMENTATION_PATTERNS.md` - Reference guide

## 📦 Installation Requirements

```bash
# Install Phase 1 dependencies
pip install sqlalchemy aiosqlite python-dotenv pyjwt
pip install python-json-logger slowapi prometheus-client

# For PostgreSQL (optional, recommended for production)
pip install psycopg2-binary asyncpg
```

## 🔧 Integration Steps

### Step 1: Create .env file

Create `.env` in your project root:

```env
# Database
DATABASE_URL=sqlite+aiosqlite:///./rez_hive.db
# DATABASE_URL=postgresql+asyncpg://user:password@localhost/rez_hive  # For production

# Security
JWT_SECRET=your-super-secret-key-change-in-production
DEBUG=false
LOG_LEVEL=INFO
PORT=8001

# API
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
```

---

### Step 2: Update kernel.py

Replace the imports section at the top with:

```python
import json
import asyncio
import urllib.parse
import logging
import time
from datetime import datetime
from typing import Optional, Dict, Any, AsyncGenerator

import ollama
import aiohttp
from fastapi import FastAPI, Request, Depends
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
import uvicorn
from pydantic import BaseModel, Field

# Phase 1 Integration
from database import init_db, close_db, get_db
from auth import create_session_id, create_access_token, get_current_session
from services import ChatService, UserService, WorkerLogService, HealthCheckService
from middleware import setup_logging, RequestLoggingMiddleware

# Setup logging
setup_logging(log_level="INFO", log_file="logs/kernel.log")
logger = logging.getLogger(__name__)
```

---

### Step 3: Update Pydantic Models

Replace the TaskRequest model:

```python
class TaskRequest(BaseModel):
    """Request model with validation"""
    task: str = Field(..., min_length=1, max_length=5000)
    worker: str = Field(default="brain", regex="^(brain|code|search|files)$")
    model: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None
    confirmed: bool = False


class AuthResponse(BaseModel):
    session_id: str
    token: str
    expires_in_days: int = 7


class HealthResponse(BaseModel):
    status: str
    timestamp: str
    workers_ready: int
    services: Dict[str, str]
```

---

### Step 4: Update App Initialization

Replace the initialization section:

```python
app = FastAPI(
    title="REZ HIVE Kernel",
    description="Production-grade local AI with persistence",
    version="1.0.0"
)

# Add middleware
app.add_middleware(RequestLoggingMiddleware)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3001", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

mcp_manager = MCPManager()
workers = WorkerRegistry()
workers.register(BrainWorker())
workers.register(SearchWorker())
workers.register(CodeWorker())
workers.register(FileWorker())
```

---

### Step 5: Update Stream Generator

Replace `generate_stream()` with proper database integration:

```python
async def generate_stream(
    task: str,
    worker_name: str = "brain",
    model: str = None,
    session_id: str = None,
    db: AsyncSession = None
) -> AsyncGenerator[str, None]:
    """Generate streaming response with database persistence"""
    start_time = time.time()
    
    try:
        chat_service = ChatService(db) if db else None
        worker_log_service = WorkerLogService(db) if db else None
        
        yield sse({"status": "started", "worker": worker_name})
        
        worker = workers.get(worker_name)
        if not worker:
            logger.error(f"Worker not found: {worker_name}")
            yield sse({"error": f"Worker '{worker_name}' not found"})
            yield sse({"status": "failed"})
            return
        
        # Save user message
        if chat_service and session_id:
            await chat_service.save_message(
                session_id, "user", task, worker_name, model
            )
        
        # Execute worker
        result = await asyncio.wait_for(
            worker.process(task, model=model), timeout=60
        )
        
        yield sse(result)
        
        # Save AI response
        if chat_service and session_id:
            content = result.get("content") or result.get("code") or str(result)
            await chat_service.save_message(
                session_id, "ai", content, worker_name, model
            )
        
        # Log execution
        if worker_log_service:
            await worker_log_service.log_execution(
                worker=worker_name,
                status="success",
                processing_time_ms=(time.time() - start_time) * 1000,
                input_length=len(task),
                output_length=len(str(result)),
            )
        
        yield sse({"status": "complete"})
        
    except asyncio.TimeoutError:
        logger.error(f"Worker timeout: {worker_name}")
        yield sse({"error": f"Worker timed out"})
        yield sse({"status": "failed"})
    except Exception as e:
        logger.error(f"Worker error: {e}", exc_info=True)
        yield sse({"error": str(e)})
        yield sse({"status": "failed"})
```

---

### Step 6: Add New Endpoints

Add these endpoints before the existing ones:

```python
@app.post("/auth/session", response_model=AuthResponse)
async def create_session():
    """Create new user session with JWT token"""
    session_id = create_session_id()
    token = create_access_token(session_id)
    logger.info(f"New session: {session_id}")
    return AuthResponse(session_id=session_id, token=token)


@app.get("/health", response_model=HealthResponse)
async def health_check(db: AsyncSession = Depends(get_db)):
    """Health status of all services"""
    health_service = HealthCheckService(db)
    services = {}
    
    # Check Ollama
    try:
        ollama.list()
        services["ollama"] = "healthy"
    except Exception as e:
        services["ollama"] = "unhealthy"
        logger.warning(f"Ollama down: {e}")
    
    # Check Database
    try:
        await db.execute("SELECT 1")
        services["database"] = "healthy"
    except Exception as e:
        services["database"] = "unhealthy"
        logger.warning(f"Database down: {e}")
    
    return HealthResponse(
        status="healthy" if all(v == "healthy" for v in services.values()) else "degraded",
        timestamp=datetime.utcnow().isoformat(),
        workers_ready=len(workers.workers),
        services=services
    )


@app.get("/chat/{session_id}/history")
async def get_chat_history(
    session_id: str,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
):
    """Retrieve chat history from database"""
    try:
        chat_service = ChatService(db)
        messages = await chat_service.get_chat_history(session_id, limit)
        return {
            "session_id": session_id,
            "messages": [
                {
                    "id": msg.id,
                    "role": msg.role,
                    "content": msg.content,
                    "worker": msg.worker,
                    "created_at": msg.created_at.isoformat(),
                }
                for msg in messages
            ],
        }
    except Exception as e:
        logger.error(f"History error: {e}", exc_info=True)
        return {"error": str(e)}
```

---

### Step 7: Update Existing Endpoints

Change the `/kernel/stream` endpoint:

```python
@app.post("/kernel/stream")
async def kernel_stream(
    request: Request,
    db: AsyncSession = Depends(get_db),
    session_id: str = Depends(get_current_session),
):
    """Execute task with database persistence"""
    try:
        data = await request.json()
        task = data.get("task", "").strip()
        worker = data.get("worker", "brain")
        model = data.get("model")
        
        # Create/update user session
        user_service = UserService(db)
        await user_service.get_or_create_user(session_id)
        
        return StreamingResponse(
            generate_stream(task, worker, model, session_id, db),
            media_type="text/event-stream"
        )
    except Exception as e:
        logger.error(f"Stream error: {e}", exc_info=True)
        async def error_stream():
            yield sse({"error": str(e)})
        return StreamingResponse(error_stream(), media_type="text/event-stream")
```

---

### Step 8: Add Startup/Shutdown Events

Replace the shutdown event:

```python
@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    try:
        await init_db()
        logger.info("✅ Database initialized | Workers ready", extra={
            "workers": len(workers.workers),
            "mcp_servers": len(mcp_manager.servers),
        })
    except Exception as e:
        logger.error(f"Startup failed: {e}", exc_info=True)
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down...")
    
    # Terminate MCP servers
    for name, server in mcp_manager.servers.items():
        if server.process:
            try:
                server.process.terminate()
                await server.process.wait()
                logger.info(f"MCP server terminated: {name}")
            except Exception as e:
                logger.error(f"Error terminating {name}: {e}")
    
    # Close database
    try:
        await close_db()
    except Exception as e:
        logger.error(f"Database close error: {e}")
```

---

### Step 9: Update Main Entry Point

```python
if __name__ == "__main__":
    print("=" * 70)
    print("🏛️  REZ HIVE KERNEL - Production-Grade Local AI")
    print("=" * 70)
    print(f"✅ Workers: {len(workers.workers)}")
    print(f"✅ Database: SQLite")
    print(f"✅ Auth: JWT tokens")
    print(f"✅ Logging: Structured JSON")
    print(f"\n🌐 API: http://localhost:8001")
    print(f"📊 Docs: http://localhost:8001/docs")
    print("=" * 70 + "\n")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        log_config=None,  # Use our logging
    )
```

---

## ✅ Testing Phase 1

### 1. Create Session
```bash
curl -X POST http://localhost:8001/auth/session
```

Response:
```json
{
  "session_id": "uuid-...",
  "token": "eyJ0...",
  "expires_in_days": 7
}
```

### 2. Check Health
```bash
curl http://localhost:8001/health
```

### 3. Send Message (saves to DB)
```bash
curl -X POST http://localhost:8001/kernel/stream \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: your-session-id" \
  -d '{"task": "hello world", "worker": "brain"}'
```

### 4. Retrieve Chat History
```bash
curl http://localhost:8001/chat/your-session-id/history
```

---

## 📊 Verify Phase 1 Successfully

- [ ] Database file created: `rez_hive.db`
- [ ] Log file created: `logs/kernel.log`
- [ ] Chat messages saved to database
- [ ] Chat history retrievable via `/chat/{session_id}/history`
- [ ] Health check endpoint working
- [ ] Auth endpoint creating sessions
- [ ] Structured JSON logging in console and file

---

## 🎯 Next Steps After Phase 1

1. **Phase 2:** Add rate limiting & advanced auth
2. **Phase 3:** Implement task queue for long operations
3. **Phase 4:** Add monitoring & metrics
4. **Phase 5:** Horizontal scaling & load balancing

---

## 🆘 Troubleshooting

### `ModuleNotFoundError: No module named 'database'`
**Solution:** Make sure `database.py`, `auth.py`, `middleware.py`, `services.py`, and `models.py` are in the same directory as `kernel.py`

### `sqlite3.OperationalError: unable to open database file`
**Solution:** Create `logs/` directory: `mkdir logs`

### `ImportError: cannot import name 'AsyncSession'`
**Solution:** Run `pip install sqlalchemy`

### Messages not saving
**Solution:** Check logs: `cat logs/kernel.log` - look for database errors

---

## 📝 Code Patterns to Remember

### Using Services in Endpoints
```python
@app.get("/chat/{session_id}/history")
async def get_chat_history(session_id: str, db: AsyncSession = Depends(get_db)):
    chat_service = ChatService(db)
    messages = await chat_service.get_chat_history(session_id)
    return {"messages": messages}
```

### Logging with Context
```python
logger.info(
    "User action",
    extra={
        "user_id": session_id,
        "action": "sent_message",
        "worker": worker_name,
    }
)
```

### Error Handling
```python
try:
    result = await chat_service.save_message(...)
except Exception as e:
    logger.error(f"Database error: {e}", exc_info=True)
    raise
```

---

This is your complete Phase 1 implementation guide! 🚀
