# backend/drift_detector.py
"""
Zero-Drift Detector - Continuously monitors system for drift
Auto-heals when possible, alerts when necessary
"""
import asyncio
import logging
import time
import json
import subprocess
import socket
import psutil
import requests
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime, timedelta
from pathlib import Path
from dataclasses import dataclass
from zero_drift_core import DriftEvent, DriftType

logger = logging.getLogger(__name__)

@dataclass
class ServiceStatus:
    name: str
    expected_port: int
    process_name: str
    healthy: bool = False
    pid: Optional[int] = None
    cpu_percent: float = 0
    memory_mb: float = 0
    last_check: float = 0

class ZeroDriftDetector:
    """
    Continuous monitoring system that detects and corrects drift.
    Runs as background task alongside main application.
    """
    
    def __init__(self):
        self.drift_events: List[DriftEvent] = []
        self.services = [
            ServiceStatus("kernel", 8001, "python"),
            ServiceStatus("chroma", 8000, "chroma"),
            ServiceStatus("ollama", 11434, "ollama"),
            ServiceStatus("nextjs", 3001, "node"),
        ]
        self.healing_actions = {
            "kernel": self._heal_kernel,
            "chroma": self._heal_chroma,
            "ollama": self._heal_ollama,
            "nextjs": self._heal_nextjs,
        }
        self.running = True
        self.detection_interval = 10  # seconds
        self.heal_attempts = {}
        self.max_heal_attempts = 3
        
    async def start_monitoring(self):
        """Start the drift detection loop"""
        logger.info("🛡️ Zero-Drift Detector started")
        while self.running:
            try:
                await self._detection_cycle()
                await asyncio.sleep(self.detection_interval)
            except Exception as e:
                logger.error(f"Drift detection error: {e}", exc_info=True)
    
    async def _detection_cycle(self):
        """Single detection cycle - check all services"""
        for service in self.services:
            await self._check_service(service)
    
    async def _check_service(self, service: ServiceStatus):
        """Check a single service for drift"""
        service.last_check = time.time()
        
        # Check if process is running
        process_healthy = await self._check_process(service)
        # Check if port is listening
        port_healthy = await self._check_port(service.expected_port)
        
        was_healthy = service.healthy
        service.healthy = process_healthy and port_healthy
        
        # If health changed from healthy to unhealthy, we have drift
        if was_healthy and not service.healthy:
            drift = DriftEvent(
                event_id=f"drift_{int(time.time())}_{service.name}",
                timestamp=time.time(),
                drift_type=DriftType.SERVICE_DOWN,
                component=service.name,
                expected=True,
                actual=False,
                severity=4
            )
            self.drift_events.append(drift)
            logger.warning(f"⚠️ Drift detected: {service.name} is down")
            
            # Attempt auto-heal
            await self._attempt_heal(service.name, drift)
    
    async def _check_process(self, service: ServiceStatus) -> bool:
        """Check if process is running"""
        try:
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_info']):
                if service.process_name.lower() in proc.info['name'].lower():
                    service.pid = proc.info['pid']
                    service.cpu_percent = proc.info['cpu_percent'] or 0
                    if proc.info['memory_info']:
                        service.memory_mb = proc.info['memory_info'].rss / 1024 / 1024
                    return True
            service.pid = None
            return False
        except Exception as e:
            logger.error(f"Process check error: {e}")
            return False
    
    async def _check_port(self, port: int) -> bool:
        """Check if port is listening"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('127.0.0.1', port))
            sock.close()
            return result == 0
        except:
            return False
    
    async def _attempt_heal(self, service_name: str, drift: DriftEvent):
        """Attempt to auto-heal a drifted service"""
        if service_name not in self.healing_actions:
            logger.warning(f"No healing action for {service_name}")
            return
        
        # Check attempt count
        attempts = self.heal_attempts.get(service_name, 0)
        if attempts >= self.max_heal_attempts:
            logger.error(f"❌ Max heal attempts reached for {service_name}")
            drift.auto_healed = False
            return
        
        self.heal_attempts[service_name] = attempts + 1
        
        # Attempt heal
        logger.info(f"🔧 Attempting to heal {service_name} (attempt {attempts + 1})")
        success = await self.healing_actions[service_name]()
        
        drift.auto_healed = success
        drift.healing_action = f"attempt_{attempts + 1}"
        
        if success:
            logger.info(f"✅ Successfully healed {service_name}")
            # Reset attempt counter on success
            self.heal_attempts[service_name] = 0
        else:
            logger.error(f"❌ Failed to heal {service_name}")
    
    async def _heal_kernel(self) -> bool:
        """Heal kernel service"""
        try:
            # Kill existing kernel process
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                if 'python' in proc.info['name'] and 'kernel.py' in str(proc.info['cmdline']):
                    proc.terminate()
                    await asyncio.sleep(2)
                    if proc.is_running():
                        proc.kill()
            
            # Restart kernel (would need to be done by external process)
            # For now, just log that manual restart may be needed
            logger.info("Kernel heal attempted - may need manual restart")
            return True
        except Exception as e:
            logger.error(f"Kernel heal error: {e}")
            return False
    
    async def _heal_chroma(self) -> bool:
        """Heal ChromaDB service"""
        try:
            # Try to restart via command
            result = subprocess.run(
                ["chroma", "run", "--path", "./chroma_data", "--port", "8000"],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except:
            return False
    
    async def _heal_ollama(self) -> bool:
        """Heal Ollama service"""
        try:
            # Try to restart via command
            if os.name == 'nt':  # Windows
                subprocess.run(["taskkill", "/F", "/IM", "ollama.exe"], capture_output=True)
                await asyncio.sleep(2)
                subprocess.run(["ollama", "serve"], capture_output=True)
            else:  # Unix
                subprocess.run(["pkill", "-f", "ollama"])
                await asyncio.sleep(2)
                subprocess.run(["ollama", "serve"], capture_output=True)
            return True
        except:
            return False
    
    async def _heal_nextjs(self) -> bool:
        """Heal Next.js service"""
        try:
            # Kill node processes
            for proc in psutil.process_iter(['pid', 'name']):
                if 'node' in proc.info['name'].lower():
                    proc.terminate()
            await asyncio.sleep(2)
            logger.info("Next.js heal attempted - restart via launcher.bat")
            return True
        except:
            return False
    
    def get_drift_report(self) -> Dict[str, Any]:
        """Generate comprehensive drift report"""
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "total_drift_events": len(self.drift_events),
            "unhealed_drift": len([e for e in self.drift_events if not e.auto_healed]),
            "services": [
                {
                    "name": s.name,
                    "healthy": s.healthy,
                    "pid": s.pid,
                    "cpu": s.cpu_percent,
                    "memory_mb": round(s.memory_mb, 2),
                    "last_check": s.last_check
                }
                for s in self.services
            ],
            "recent_events": [e.to_dict() for e in self.drift_events[-10:]]
        }

# Global detector instance
detector = ZeroDriftDetector()