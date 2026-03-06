# 🎯 Phase 1 Implementation Guide - Complete Pattern Reference

This document shows **exact patterns** for production-grade implementation.

---

## 📐 Architecture Patterns Used

### **1. Layered Architecture**
```
├── routes/        (API endpoints)
├── services/      (Business logic)
├── models/        (Database schemas)
├── middleware/    (Auth, logging, etc)
├── utils/         (Helpers)
└── config/        (Settings & env)
```

**Why:** Separation of concerns, testable, scalable.

---

### **2. Dependency Injection Pattern**
```python
# ❌ BAD - Tight coupling
class UserService:
    def __init__(self):
        self.db = Database()  # Hard to test

# ✅ GOOD - Loose coupling
class UserService:
    def __init__(self, db: Database):
        self.db = db  # Can inject mock for testing
```

---

### **3. Configuration Management**
```python
# ❌ BAD - Hardcoded
DATABASE_URL = "postgresql://localhost/mydb"

# ✅ GOOD - Environment-based
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
    log_level: str = "INFO"
    
    class Config:
        env_file = ".env"

settings = Settings()
```

**Why:** Secure, flexible, different configs per environment.

---

### **4. Error Handling Pattern**
```python
# ❌ BAD - Generic exception
try:
    result = await worker.process(task)
except Exception as e:
    return {"error": str(e)}

# ✅ GOOD - Specific exceptions with context
class WorkerLoadError(Exception):
    """Raised when worker fails to load"""
    pass

class TaskTimeoutError(Exception):
    """Raised when task exceeds timeout"""
    pass

try:
    result = await asyncio.wait_for(worker.process(task), timeout=60)
except asyncio.TimeoutError:
    logger.error(f"Task timeout for task: {task}", exc_info=True)
    raise TaskTimeoutError(f"Worker {worker.name} timed out")
except WorkerLoadError as e:
    logger.error(f"Worker load error: {e}")
    return {"error": "Worker unavailable", "code": "WORKER_LOAD_ERROR"}
```

**Why:** Debugging, monitoring, better error messages.

---

### **5. Async/Await Pattern (Correct)**
```python
# ❌ BAD - Blocking code in async context
@app.get("/data")
async def get_data():
    time.sleep(5)  # WRONG! Blocks event loop
    return {"data": "..."}

# ✅ GOOD - Non-blocking async operations
@app.get("/data")
async def get_data():
    result = await asyncio.sleep(5)  # Non-blocking
    return {"data": result}

# ✅ GOOD - Database async
@app.get("/users")
async def list_users():
    users = await db.fetch("SELECT * FROM users")  # Non-blocking
    return users
```

**Why:** Maintains AsyncIO event loop, prevents slowdowns.

---

### **6. Logging Pattern**
```python
# ❌ BAD - Print statements
print(f"Worker started: {worker_name}")

# ✅ GOOD - Structured logging with context
import logging
from pythonjsonlogger import jsonlogger

logger = logging.getLogger(__name__)

# Log with context
logger.info(
    "Worker process initiated",
    extra={
        "worker_name": worker_name,
        "task_id": task_id,
        "user_id": session_id,
        "timestamp": datetime.now().isoformat(),
    }
)

# Log errors with traceback
try:
    await worker.process(task)
except Exception as e:
    logger.error(
        "Worker process failed",
        exc_info=True,  # Includes full traceback
        extra={"worker_name": worker_name, "error_type": type(e).__name__}
    )
```

**Why:** Searchable logs, structured data, debugging.

---

### **7. Type Hints Pattern (Critical)**
```python
# ❌ BAD - No type hints
def process_task(task, worker):
    return worker.process(task)

# ✅ GOOD - Full type hints
from typing import Optional, List, Dict, Any

async def process_task(
    task: str,
    worker: Worker,
    timeout: int = 60
) -> Dict[str, Any]:
    """
    Process a task with a worker.
    
    Args:
        task: Task description
        worker: Worker instance
        timeout: Max seconds to wait
        
    Returns:
        Task result dictionary
        
    Raises:
        TaskTimeoutError: If task exceeds timeout
        WorkerLoadError: If worker fails
    """
    result = await asyncio.wait_for(
        worker.process(task),
        timeout=timeout
    )
    return result
```

**Why:** IDE autocomplete, type checking, documentation.

---

### **8. Database Connection Pattern**
```python
# ❌ BAD - Create new connection per request
@app.get("/users")
async def list_users():
    db = Database(DATABASE_URL)  # New connection!
    users = await db.fetch("SELECT * FROM users")
    await db.close()
    return users

# ✅ GOOD - Connection pooling with lifespan
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.pool import QueuePool

engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    poolclass=QueuePool,
    pool_size=20,  # Max 20 connections
    max_overflow=10,  # Up to 10 more if needed
)

@app.on_event("startup")
async def startup():
    await engine.connect()
    logger.info("Database connection pool initialized")

@app.on_event("shutdown")
async def shutdown():
    await engine.dispose()
    logger.info("Database connections closed")

async def get_db() -> AsyncSession:
    async with SessionLocal() as session:
        yield session

@app.get("/users")
async def list_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute("SELECT * FROM users")
    return result.scalars().all()
```

**Why:** Efficient, reuses connections, handles concurrent requests.

---

### **9. Dependency Injection in FastAPI**
```python
# ✅ GOOD - Using Depends()
from fastapi import Depends

async def get_db() -> AsyncSession:
    async with SessionLocal() as session:
        yield session

async def verify_token(request: Request) -> Dict[str, str]:
    token = request.headers.get("Authorization")
    if not token:
        raise HTTPException(status_code=401)
    return jwt.decode(token, SECRET_KEY)

@app.post("/kernel/stream")
async def kernel_stream(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: Dict = Depends(verify_token),
):
    # db and user automatically injected
    data = await request.json()
    # ... rest of code
```

**Why:** Testable, reusable, clean code.

---

### **10. Testing Pattern**
```python
# ✅ GOOD - Unit test with mocking
import pytest
from unittest.mock import AsyncMock, patch

@pytest.fixture
async def mock_worker():
    worker = AsyncMock()
    worker.process.return_value = {"content": "test"}
    return worker

@pytest.mark.asyncio
async def test_kernel_stream(mock_worker):
    with patch('app.workers.get', return_value=mock_worker):
        response = await kernel_stream({"task": "test"})
        # Assert response format
        assert "status" in response
        assert mock_worker.process.called

# ✅ GOOD - Integration test with real DB
@pytest.fixture
async def test_db():
    db = await init_test_database()
    yield db
    await teardown_test_database(db)

@pytest.mark.asyncio
async def test_save_message(test_db):
    msg = ChatMessage(role="user", content="test")
    await test_db.add(msg)
    
    retrieved = await test_db.query(ChatMessage).first()
    assert retrieved.content == "test"
```

**Why:** Catches bugs early, enables refactoring safely.

---

## 📋 Code Organization Best Practices

### **File Structure**
```python
# backend/config.py
"""Application configuration and settings"""
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    db_url: str
    jwt_secret: str
    log_level: str
    
    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()

# ---

# backend/models.py
"""SQLAlchemy models for database tables"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True)
    session_id = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class ChatMessage(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True)
    session_id = Column(String, ForeignKey("users.session_id"))
    role = Column(String)
    content = Column(String)
    worker = Column(String)
    model = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

# ---

# backend/database.py
"""Database connection and session management"""
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from config import settings

engine = create_async_engine(
    settings.db_url,
    echo=settings.debug,
    pool_pre_ping=True,  # Test connection before using
)

SessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

async def get_db() -> AsyncSession:
    async with SessionLocal() as session:
        yield session

# ---

# backend/middleware.py
"""Custom middleware for logging, auth, error handling"""
import logging
from fastapi import Request
from datetime import datetime

logger = logging.getLogger(__name__)

class LoggingMiddleware:
    def __init__(self, app):
        self.app = app
        
    async def __call__(self, request: Request, call_next):
        start = datetime.now()
        response = await call_next(request)
        duration = (datetime.now() - start).total_seconds()
        
        logger.info(
            "HTTP request",
            extra={
                "method": request.method,
                "path": request.url.path,
                "status": response.status_code,
                "duration_seconds": duration,
            }
        )
        return response

# ---

# backend/services.py
"""Business logic and service layer"""
class ChatService:
    def __init__(self, db: AsyncSession):
        self.db = db
        
    async def save_message(self, session_id: str, role: str, content: str, worker: str):
        message = ChatMessage(
            session_id=session_id,
            role=role,
            content=content,
            worker=worker,
        )
        self.db.add(message)
        await self.db.commit()
        return message
        
    async def get_history(self, session_id: str) -> List[ChatMessage]:
        result = await self.db.execute(
            select(ChatMessage).where(ChatMessage.session_id == session_id)
        )
        return result.scalars().all()

# ---

# backend/routes.py
"""API route handlers"""
from fastapi import APIRouter, Depends, HTTPException
from database import get_db
from services import ChatService

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "healthy"}

@router.post("/chat/save")
async def save_message(
    session_id: str,
    role: str,
    content: str,
    db: AsyncSession = Depends(get_db),
):
    service = ChatService(db)
    await service.save_message(session_id, role, content, "worker")
    return {"success": True}
```

---

## 🔐 Security Checklist

```python
# ✅ JWT Token Pattern
import jwt
from datetime import datetime, timedelta

def create_token(session_id: str) -> str:
    payload = {
        "session_id": session_id,
        "exp": datetime.utcnow() + timedelta(days=7),
        "iat": datetime.utcnow(),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")

def verify_token(token: str) -> Dict[str, Any]:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# ✅ Rate Limiting Pattern
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/kernel/stream")
@limiter.limit("10/minute")
async def kernel_stream(request: Request):
    pass

# ✅ CORS Pattern
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Input Validation Pattern
from pydantic import BaseModel, Field

class TaskRequest(BaseModel):
    task: str = Field(..., min_length=1, max_length=5000)
    worker: str = Field(..., regex="^(brain|code|search|files)$")
    model: Optional[str] = None
```

---

## 🧪 Testing Patterns

```python
# tests/test_kernel.py
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as c:
        yield c

@pytest.mark.asyncio
async def test_health_check(client):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

@pytest.mark.asyncio
async def test_kernel_stream_missing_task(client):
    response = await client.post("/kernel/stream", json={"task": ""})
    assert response.status_code == 422  # Validation error

@pytest.mark.asyncio
async def test_kernel_stream_valid(client):
    response = await client.post(
        "/kernel/stream",
        json={"task": "hello world", "worker": "brain"}
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "text/event-stream"
```

---

## 📊 Monitoring & Metrics Pattern

```python
# backend/metrics.py
from prometheus_client import Counter, Histogram, start_http_server
import time

request_count = Counter(
    'kernel_requests_total',
    'Total requests',
    ['method', 'endpoint']
)

request_duration = Histogram(
    'kernel_request_duration_seconds',
    'Request duration',
    ['endpoint']
)

@app.middleware("http")
async def add_metrics(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    
    request_count.labels(
        method=request.method,
        endpoint=request.url.path
    ).inc()
    
    request_duration.labels(
        endpoint=request.url.path
    ).observe(time.time() - start)
    
    return response

# Start metrics server
# start_http_server(8002)  # Prometheus scrapes :8002/metrics
```

---

## 🚨 Error Handling Best Practices

```python
# ✅ Custom exception classes
class KernelException(Exception):
    """Base exception for kernel"""
    pass

class WorkerException(KernelException):
    """Worker-related error"""
    def __init__(self, worker_name: str, message: str):
        self.worker_name = worker_name
        self.message = message
        super().__init__(f"Worker {worker_name}: {message}")

class TimeoutException(KernelException):
    """Task timeout"""
    pass

# ✅ Exception handlers
@app.exception_handler(WorkerException)
async def worker_exception_handler(request: Request, exc: WorkerException):
    logger.error(f"Worker error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=503,
        content={
            "error": "Worker unavailable",
            "worker": exc.worker_name,
            "detail": exc.message,
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error"}
    )
```

---

## ✨ Key Principles Summary

| Principle | Why | Example |
|-----------|-----|---------|
| **Type Hints** | IDE support, static checking | `async def process(task: str) -> Dict[str, Any]` |
| **Dependency Injection** | Testable, loose coupling | `def __init__(self, db: Database)` |
| **Async/Await** | Non-blocking, responsive | `await db.execute(query)` |
| **Logging** | Debugging, monitoring | `logger.error("msg", exc_info=True)` |
| **Error Classes** | Specific handling | `class TaskTimeoutError(Exception)` |
| **Config Management** | Flexible, secure | `settings = Settings()` from `.env` |
| **Layered Architecture** | Maintainable, scalable | `routes → services → models → db` |
| **Validation** | Data integrity | `Field(min_length=1, max_length=5000)` |
| **Connection Pooling** | Performance, stability | `create_async_engine(..., pool_size=20)` |
| **Testing** | Reliability, refactoring | `pytest`, mock external services |

---

## 🎓 Learning Path

1. **Day 1:** Understand layered architecture, type hints, dependency injection
2. **Day 2:** Implement database models and migrations
3. **Day 3:** Add authentication and logging
4. **Day 4:** Write tests
5. **Day 5:** Add monitoring and error handling

Now you have the **patterns and principles** to build production-grade code! 🚀
