# backend/ps1_integration.py
"""
PS1-Style Controller Backend Integration
Connects the floating UI to the zero-drift core
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any, List
import psutil
import os
import signal
import subprocess
import platform
from datetime import datetime

from database import get_db
from services import WorkerLogService, HealthCheckService
from zero_drift_core import constitution
from drift_detector import detector
from drift_detector import detector as drift_monitor

router = APIRouter(prefix="/ps1", tags=["ps1-controller"])

# ============================================================================
# STATUS ENDPOINTS
# ============================================================================

@router.get("/status")
async def get_system_status():
    """Get comprehensive system status for PS1 controller"""
    services = {}
    
    # Check kernel (this service)
    services["kernel"] = {
        "healthy": True,
        "port": 8001,
        "pid": os.getpid()
    }
    
    # Check ChromaDB
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        chroma_up = sock.connect_ex(('127.0.0.1', 8000)) == 0
        sock.close()
        services["chroma"] = {"healthy": chroma_up, "port": 8000}
    except:
        services["chroma"] = {"healthy": False, "port": 8000}
    
    # Check Next.js
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        nextjs_up = sock.connect_ex(('127.0.0.1', 3001)) == 0
        sock.close()
        services["nextjs"] = {"healthy": nextjs_up, "port": 3001}
    except:
        services["nextjs"] = {"healthy": False, "port": 3001}
    
    # Check Ollama
    try:
        import requests
        ollama_resp = requests.get("http://localhost:11434/api/version", timeout=2)
        services["ollama"] = {"healthy": ollama_resp.status_code == 200, "port": 11434}
    except:
        services["ollama"] = {"healthy": False, "port": 11434}
    
    # Get worker stats
    worker_stats = {}
    for worker in ["brain", "code", "search", "files"]:
        try:
            # This would come from database in real implementation
            worker_stats[worker] = {"active": True, "last_seen": datetime.now().isoformat()}
        except:
            worker_stats[worker] = {"active": False}
    
    return {
        "services": services,
        "workers": worker_stats,
        "timestamp": datetime.now().isoformat(),
        "drift_report": drift_monitor.get_drift_report()
    }

# ============================================================================
# CONTROL ENDPOINTS
# ============================================================================

@router.post("/kill-port/{port}")
async def kill_port(port: int):
    """Kill process using specified port"""
    killed = False
    pids = []
    
    try:
        if platform.system() == "Windows":
            # Windows: use netstat to find PID
            result = subprocess.run(
                f'netstat -ano | findstr :{port}',
                shell=True,
                capture_output=True,
                text=True
            )
            lines = result.stdout.strip().split('\n')
            for line in lines:
                if 'LISTENING' in line:
                    parts = line.split()
                    if parts:
                        pid = int(parts[-1])
                        pids.append(pid)
                        os.kill(pid, signal.SIGTERM)
                        killed = True
        else:
            # Unix: use lsof
            result = subprocess.run(
                ['lsof', '-ti', f':{port}'],
                capture_output=True,
                text=True
            )
            pids = [int(pid) for pid in result.stdout.strip().split('\n') if pid]
            for pid in pids:
                os.kill(pid, signal.SIGTERM)
                killed = True
        
        # Give processes time to die
        await asyncio.sleep(1)
        
        return {
            "success": killed,
            "message": f"Killed {len(pids)} process(es) on port {port}",
            "pids": pids
        }
    except Exception as e:
        return {
            "success": False,
            "message": str(e),
            "pids": []
        }

@router.post("/launch-all")
async def launch_all():
    """Launch all services (coordinated via launcher)"""
    # This endpoint tells the PS1 controller what to do
    # Actual launching happens via launcher.bat
    return {
        "message": "Use launcher.bat to start all services",
        "commands": [
            "cd backend && python kernel.py",
            "chroma run --path ./chroma_data --port 8000",
            "npm run dev"
        ],
        "status": "check_complete"
    }

@router.post("/heal-system")
async def heal_system():
    """Trigger zero-drift auto-healing"""
    # Run through all services and attempt heal
    results = {}
    
    # Check each service
    for service in drift_monitor.services:
        if not service.healthy:
            logger.info(f"Attempting to heal {service.name}")
            if service.name in drift_monitor.healing_actions:
                success = await drift_monitor.healing_actions[service.name]()
                results[service.name] = "healed" if success else "failed"
            else:
                results[service.name] = "no_healer"
        else:
            results[service.name] = "healthy"
    
    return {
        "success": all(r == "healthy" or r == "healed" for r in results.values()),
        "results": results,
        "timestamp": datetime.now().isoformat()
    }

# ============================================================================
# CONSTITUTIONAL ENDPOINTS
# ============================================================================

@router.post("/validate-task")
async def validate_constitutional_task(task: str, worker: str, session_id: str):
    """Validate a task against the constitution"""
    ruling = constitution.validate_task(task, worker, session_id)
    return ruling

@router.get("/ruling-history/{session_id}")
async def get_ruling_history(session_id: str, limit: int = 50):
    """Get constitutional ruling history for a session"""
    return {
        "session_id": session_id,
        "rulings": constitution.get_ruling_history(session_id, limit)
    }

@router.get("/constitution")
async def get_constitution():
    """Get the full constitution text"""
    return {
        "articles": [
            {
                "number": 1,
                "name": "Sovereignty",
                "description": "All data must stay within the sovereign system. No external API calls."
            },
            {
                "number": 2,
                "name": "Transparency",
                "description": "All operations must be transparent and explainable."
            },
            {
                "number": 3,
                "name": "Accountability",
                "description": "Every action must be attributable to a specific session."
            },
            {
                "number": 4,
                "name": "Determinism",
                "description": "Same input + same context = same output."
            },
            {
                "number": 5,
                "name": "Safety",
                "description": "No harmful operations that could damage system or data."
            },
            {
                "number": 6,
                "name": "Privacy",
                "description": "No PII collection or storage."
            },
            {
                "number": 7,
                "name": "Auditability",
                "description": "All operations must be logged for audit."
            },
            {
                "number": 8,
                "name": "Recoverability",
                "description": "System must be able to rollback to known state."
            },
            {
                "number": 9,
                "name": "Boundedness",
                "description": "Operations must stay within defined worker boundaries."
            }
        ],
        "preamble": "We the sovereign AI, in order to form a more perfect system..."
    }

# ============================================================================
# DRIFT REPORTING
# ============================================================================

@router.get("/drift-report")
async def get_drift_report():
    """Get comprehensive drift report"""
    return drift_monitor.get_drift_report()

@router.post("/reset-drift-counter")
async def reset_drift_counter():
    """Reset drift event counter (for testing)"""
    drift_monitor.drift_events = []
    return {"message": "Drift counter reset"}
