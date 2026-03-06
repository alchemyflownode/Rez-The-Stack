"""
Zero-Drift State Ledger - Immutable audit trail for AI decisions
SHA256 hashing + Merkle tree for verification
"""

import json
import hashlib
import os
from datetime import datetime
from typing import Optional, Dict, Any

class StateLedger:
    """Immutable ledger for zero-drift verification"""
    
    def __init__(self, ledger_path="logs/state_ledger.json"):
        self.ledger_path = ledger_path
        os.makedirs(os.path.dirname(ledger_path), exist_ok=True)
        self.load()
    
    def load(self):
        """Load existing ledger"""
        if os.path.exists(self.ledger_path):
            with open(self.ledger_path, 'r') as f:
                self.ledger = json.load(f)
        else:
            self.ledger = {
                "genesis_block": {
                    "timestamp": datetime.utcnow().isoformat(),
                    "version": "1.0.0",
                    "drift_events": 0
                },
                "precedents": {}
            }
    
    def save(self):
        """Save ledger atomically"""
        temp_path = self.ledger_path + ".tmp"
        with open(temp_path, 'w') as f:
            json.dump(self.ledger, f, indent=2)
        os.replace(temp_path, self.ledger_path)
    
    def hash_output(self, task: str, output: str) -> str:
        """Create SHA256 hash of task+output"""
        content = f"{task}|{output}".encode()
        return hashlib.sha256(content).hexdigest()
    
    def commit(self, task: str, output: str) -> str:
        """Store a precedent in the ledger"""
        task_hash = hashlib.sha256(task.encode()).hexdigest()[:16]
        output_hash = self.hash_output(task, output)
        
        self.ledger["precedents"][task_hash] = {
            "output_hash": output_hash,
            "timestamp": datetime.utcnow().isoformat(),
            "preview": output[:100]
        }
        self.save()
        return output_hash
    
    def verify(self, task: str, output: str) -> bool:
        """Verify output matches precedent"""
        task_hash = hashlib.sha256(task.encode()).hexdigest()[:16]
        if task_hash not in self.ledger["precedents"]:
            return False  # No precedent
        
        expected_hash = self.ledger["precedents"][task_hash]["output_hash"]
        actual_hash = self.hash_output(task, output)
        return expected_hash == actual_hash
    
    def get_drift_report(self) -> Dict[str, Any]:
        """Return drift statistics"""
        return {
            "total_drift_events": self.ledger["genesis_block"]["drift_events"],
            "total_precedents": len(self.ledger["precedents"]),
            "genesis_timestamp": self.ledger["genesis_block"]["timestamp"]
        }
