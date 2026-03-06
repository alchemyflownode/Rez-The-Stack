# backend/constitutional_audit.py
import json
import time
from pathlib import Path

class ConstitutionalAudit:
    """Immutable log of all constitutional decisions"""
    
    def __init__(self):
        self.log_file = Path("logs/constitutional_audit.jsonl")
        self.log_file.parent.mkdir(exist_ok=True)
    
    def log_ruling(self, intent: str, verdict: dict, articles: list):
        entry = {
            "timestamp": time.time(),
            "iso": time.strftime("%Y-%m-%d %H:%M:%S"),
            "intent_hash": hashlib.sha256(intent.encode()).hexdigest()[:16],
            "verdict": verdict["allowed"],
            "articles_applied": articles,
            "violations": verdict.get("violations", []),
            "model": "constitutional_council"
        }
        
        with open(self.log_file, "a") as f:
            f.write(json.dumps(entry) + "\n")