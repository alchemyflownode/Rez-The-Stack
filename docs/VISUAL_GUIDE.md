# 📊 Phase 1 Learning Path - Visual Guide

## Your Learning Journey

```
START HERE
    ↓
QUICK_REFERENCE.md (5 min)
    ↓ Understand what you're getting
    ↓
.env.example (2 min)
    ↓ Setup configuration
    ↓
PHASE_1_COMPLETE.md (10 min)
    ↓ Understand features you'll get
    ↓
PHASE_1_IMPLEMENTATION_GUIDE.md (120 min implementation)
    ├─ Read entire guide first (20 min)
    ├─ Install dependencies (5 min)
    ├─ Follow sections 1-9
    │  ├─ Step 1: .env setup
    │  ├─ Step 2: Imports
    │  ├─ Step 3: Models
    │  ├─ Step 4-8: kernel.py updates
    │  └─ Step 9: Test
    ├─ Test 5 endpoints (10 min)
    └─ Verify checklist (5 min)
    ↓
DONE! Phase 1 complete ✅
    ↓
Reference files (as needed)
    ├─ IMPLEMENTATION_PATTERNS.md (for understanding design)
    └─ PRODUCTION_ROADMAP.md (for Phase 2+)
```

---

## Code Files by Purpose

### What You Get

```
PHASE 1 PACKAGE
│
├─ 📋 DOCUMENTATION (Read in order)
│  ├─ QUICK_REFERENCE.md              ← Start here
│  ├─ PHASE_1_COMPLETE.md             ← Overview
│  ├─ PHASE_1_IMPLEMENTATION_GUIDE.md  ← Follow this for implementation
│  ├─ IMPLEMENTATION_PATTERNS.md       ← Learn design patterns
│  └─ PRODUCTION_ROADMAP.md            ← See roadmap
│
├─ 🔧 BACKEND CODE (Copy to backend/)
│  ├─ models.py                        ✅ NEW
│  ├─ database.py                      ✅ NEW  
│  ├─ auth.py                          ✅ NEW
│  ├─ services.py                      ✅ NEW
│  ├─ middleware.py                    ✅ NEW
│  ├─ kernel.py                        🔧 UPDATE
│  └─ requirements-phase1.txt           ✅ NEW
│
└─ ⚙️ CONFIG
   └─ .env.example                     ← Copy & customize
```

---

## The 5 New Files Explained

```
📄 models.py
└─ Defines database tables
   ├─ User (sessions)
   ├─ ChatMessage (conversations)
   ├─ WorkerLog (monitoring)
   └─ HealthCheck (service health)

📄 database.py
└─ Manages database connections
   ├─ Connection pooling
   ├─ Session management
   └─ Async operations

📄 auth.py
└─ Handles authentication
   ├─ Session creation
   ├─ JWT tokens
   └─ Token verification

📄 services.py
└─ Business logic layer
   ├─ UserService
   ├─ ChatService
   ├─ WorkerLogService
   └─ HealthCheckService

📄 middleware.py
└─ Cross-cutting concerns
   ├─ JSON logging
   ├─ Request tracking
   └─ Error handling
```

---

## How It All Connects

```
┌─────────────┐
│  Frontend   │
│ (localhost  │
│   :3001)    │
└──────┬──────┘
       │ HTTP Request
       │ "save message"
       ↓
┌──────────────────────────────────┐
│  FastAPI (kernel.py)             │
│  ────────────────────────────────│
│  @app.post("/kernel/stream")     │
│  async def stream(               │
│    db = Depends(get_db)  ←─────┐ │
│  ):                          │ │ │
│    service = ChatService(db) │ │ │
│    await service.save_...   │ │ │
└──────┬───────────────────────┼──┘
       │                       │
       ↓                  services.py
┌──────────────────────────────────┐
│  middleware.py                   │
│  RequestLoggingMiddleware        │
│  (logs every request)            │
│                                  │
│  "POST /kernel/stream"           │
│  "Duration: 245ms"               │
│  "Status: 200"                   │
└──────┬───────────────────────────┘
       │
       ↓
   logs/kernel.log (JSON)
```

---

## Data Flow Example: Save Message

```
User Types: "Hello AI"
    ↓
Frontend sends POST /kernel/stream
    ↓
kernel.py receives request
    ↓
db_session = get_db()   ← database.py provides
    ↓
service = ChatService(db_session)
    ↓
service.save_message(
    session_id="abc123",
    role="user",
    content="Hello AI",
    worker="brain"
)
    ↓
services.py creates:
    ChatMessage(...)  ← models.py definition
    ↓
db.add(message)
db.commit()
    ↓
SQL INSERT into chat_messages
    ↓
Message saved to rez_hive.db
    ↓
middleware.py logs:
{
  "timestamp": "...",
  "method": "POST",
  "path": "/kernel/stream",
  "status": 200,
  "duration_ms": 245
}
    ↓
logs/kernel.log updated
```

---

## File Dependencies

```
kernel.py (main app)
  ├─ Imports: database.py
  ├─ Imports: auth.py
  ├─ Imports: services.py
  └─ Imports: middleware.py

database.py
  └─ Imports: models.py
             (to create tables)

services.py
  └─ Imports: models.py
             (to define queries)

middleware.py
  └─ Standalone
     (just logging)

models.py
  └─ Standalone
     (database schemas)
```

---

## Using Each File

### 1. models.py - WHEN TO USE
- Need new database table? → Add here first
- Querying data? → Use these classes
- Creating records? → Instantiate from here

```python
from models import ChatMessage
msg = ChatMessage(session_id="...", role="user", ...)
```

### 2. database.py - WHEN TO USE
- Need database session in endpoint? → Use `Depends(get_db)`
- Startup/shutdown tasks? → Hooks already set up
- Change connection settings? → Edit here

```python
async def endpoint(db: AsyncSession = Depends(get_db)):
    # db automatically injected
```

### 3. auth.py - WHEN TO USE
- Create user session? → Call `create_session_id()`
- Generate token? → Call `create_access_token()`
- Verify token? → Call `verify_token()`

```python
session_id = create_session_id()
token = create_access_token(session_id)
```

### 4. services.py - WHEN TO USE
- Save message? → ChatService.save_message()
- Get history? → ChatService.get_chat_history()
- Get user? → UserService.get_or_create_user()

```python
service = ChatService(db)
await service.save_message(session_id, role, content)
```

### 5. middleware.py - WHEN TO USE
- Just call `setup_logging()` in kernel.py
- Automatic request logging
- Easy debugging with JSON logs

```python
setup_logging(log_level="INFO")
```

---

## The 3 Configuration Levels

### Level 1: .env File (Secrets & Settings)
```env
DATABASE_URL=sqlite:///...
JWT_SECRET=your-secret
LOG_LEVEL=INFO
```

### Level 2: config.py (Optional - Not needed for Phase 1)
```python
class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
```

### Level 3: Code (Module level defaults)
```python
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_DAYS = 7
```

→ Use .env for Phase 1 (simplest)

---

## Testing Strategy

```
Endpoint Test
    ↓
Check logs (logs/kernel.log)
    ↓
Query database (rez_hive.db)
    ↓
Verify result
```

Example:
```bash
# 1. Send message
curl -X POST http://localhost:8001/kernel/stream \
  -H "X-Session-ID: test" \
  -d '{"task":"hello"}'

# 2. Check logs
tail logs/kernel.log
→ See JSON with request details

# 3. Check database
sqlite3 rez_hive.db "SELECT * FROM chat_messages"
→ See message saved

# 4. Get via API
curl http://localhost:8001/chat/test/history
→ See message returned
```

---

## Error Diagnosis

```
Problem → Check This → File to Look At

Messages not saving → Database errors → logs/kernel.log
                    → SQL queries → services.py
                    → Connection → database.py

Token invalid → JWT_SECRET → .env
              → Token creation → auth.py
              → Token verify → kernel.py

Request slow → logging overhead? → middleware.py
             → worker time? → kernel.py stream
             → database time? → services.py

Module import error → File missing → check backend/ dir
                    → Import typo → grep in kernel.py

Health check fails → Services down → logs/kernel.log
                   → DB connection → database.py
                   → Ollama running? → Check ollama service
```

---

## Architecture: Before vs After

### BEFORE (MVP)
```
Frontend → kernel.py → Ollama/SearXNG
┌──────────────────────────────────┐
│ No persistence                   │
│ No logging                       │
│ No authentication                │
│ Monolithic endpoints             │
└──────────────────────────────────┘
```

### AFTER (Phase 1)
```
Frontend → kernel.py
           ├─ auth.py (JWT tokens)
           ├─ middleware.py (logging)
           ├─ database.py (persistence)
           └─ services.py (business logic)
                ├─ models.py (ORM)
                └─ rez_hive.db (SQLite)

           ↓ Workers
           ├─ Ollama
           └─ SearXNG

┌──────────────────────────────────┐
│ ✅ Persistence (messages saved)  │
│ ✅ Logging (full audit trail)    │
│ ✅ Auth (session management)     │
│ ✅ Layered (services/models)     │
│ ✅ Async (non-blocking I/O)      │
│ ✅ Testable (DI pattern)         │
│ ✅ Monitorable (health checks)   │
└──────────────────────────────────┘
```

---

## That's Everything!

You have all the building blocks:
- ✅ Code files (modular, production-ready)
- ✅ Documentation (patterns + step-by-step)
- ✅ Configuration template (.env.example)
- ✅ Dependencies list (requirements-phase1.txt)
- ✅ Testing instructions
- ✅ Troubleshooting guide
- ✅ Roadmap for Phase 2-6

**Your next action:**
1. Read `QUICK_REFERENCE.md` (5 min)
2. Follow `PHASE_1_IMPLEMENTATION_GUIDE.md` (2-3 hours)
3. Verify all 5 endpoints work
4. Check database has messages
5. Done! ✅

---

**Good luck! You've got this. 🚀**
