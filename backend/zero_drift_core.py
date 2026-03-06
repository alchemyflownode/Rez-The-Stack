# backend/zero_drift_core.py
"""
Zero-Drift Constitutional Core - The immutable foundation
Every decision is logged, auditable, and replayable
"""
import hashlib
import json
import time
import logging
from datetime import datetime
from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path

logger = logging.getLogger(__name__)

# ============================================================================
# ENUMS & TYPES
# ============================================================================

class Verdict(Enum):
    ALLOWED = "allowed"
    DENIED = "denied"
    REQUIRES_CONFIRMATION = "requires_confirmation"

class DriftType(Enum):
    CONFIGURATION = "configuration_drift"
    DEPENDENCY = "dependency_drift"
    BEHAVIORAL = "behavioral_drift"
    SECURITY = "security_drift"
    PERFORMANCE = "performance_drift"

# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class ConstitutionalRuling:
    """Record of a constitutional decision"""
    ruling_id: str
    timestamp: float
    iso_time: str
    intent_hash: str
    intent_preview: str
    worker: str
    session_id: str
    verdict: Verdict
    articles_applied: List[str]
    violations: List[str] = field(default_factory=list)
    processing_time_ms: float = 0
    context: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "ruling_id": self.ruling_id,
            "timestamp": self.timestamp,
            "iso_time": self.iso_time,
            "intent_hash": self.intent_hash,
            "intent_preview": self.intent_preview,
            "worker": self.worker,
            "session_id": self.session_id,
            "verdict": self.verdict.value,
            "articles_applied": self.articles_applied,
            "violations": self.violations,
            "processing_time_ms": self.processing_time_ms
        }

@dataclass
class DriftEvent:
    """Record of detected drift"""
    event_id: str
    timestamp: float
    drift_type: DriftType
    component: str
    expected: Any
    actual: Any
    severity: int  # 1-5, 5 being critical
    auto_healed: bool = False
    healing_action: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "event_id": self.event_id,
            "timestamp": self.timestamp,
            "drift_type": self.drift_type.value,
            "component": self.component,
            "expected": str(self.expected),
            "actual": str(self.actual),
            "severity": self.severity,
            "auto_healed": self.auto_healed,
            "healing_action": self.healing_action
        }

# ============================================================================
# THE CONSTITUTION - 9 ARTICLES OF ZERO-DRIFT SOVEREIGNTY
# ============================================================================

class ZeroDriftConstitution:
    """
    The immutable constitution governing all AI operations.
    Every article is a function that returns (bool, reason, suggestions)
    """
    
    def __init__(self):
        self.articles = {
            # Article 1: Data Sovereignty - No external dependencies
            "sovereignty": self.article_1_sovereignty,
            
            # Article 2: Transparency - All operations explainable
            "transparency": self.article_2_transparency,
            
            # Article 3: Accountability - Every action attributable
            "accountability": self.article_3_accountability,
            
            # Article 4: Determinism - Same input = same output
            "determinism": self.article_4_determinism,
            
            # Article 5: Safety - No harmful operations
            "safety": self.article_5_safety,
            
            # Article 6: Privacy - No PII collection
            "privacy": self.article_6_privacy,
            
            # Article 7: Auditability - Full logging required
            "auditability": self.article_7_auditability,
            
            # Article 8: Recoverability - Can rollback to known state
            "recoverability": self.article_8_recoverability,
            
            # Article 9: Boundedness - Operations stay within scope
            "boundedness": self.article_9_boundedness
        }
        
        # Track rulings for replayability
        self.rulings: List[ConstitutionalRuling] = []
        self.ledger_path = Path("logs/constitutional_ledger.jsonl")
        self.ledger_path.parent.mkdir(exist_ok=True)
    
    # ========================================================================
    # ARTICLE 1: SOVEREIGNTY - No external dependencies
    # ========================================================================
    def article_1_sovereignty(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        All data must stay within the sovereign system.
        No external API calls, no data leakage to cloud services.
        """
        violations = []
        
        # Check for external URLs
        external_indicators = [
            "http://", "https://", "api.", ".com", ".org", ".io",
            "fetch(", "axios.", "requests.", "urllib", "aiohttp"
        ]
        
        for indicator in external_indicators:
            if indicator in task.lower():
                violations.append(f"External reference detected: {indicator}")
        
        # Check for cloud model names
        cloud_models = ["gpt-", "claude", "gemini-", "bedrock", "sagemaker"]
        for model in cloud_models:
            if model in task.lower():
                violations.append(f"Cloud model reference: {model}")
        
        if violations:
            return False, "Data sovereignty violation", violations
        return True, "Sovereignty maintained", []
    
    # ========================================================================
    # ARTICLE 2: TRANSPARENCY - All operations explainable
    # ========================================================================
    def article_2_transparency(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        All operations must be transparent and explainable.
        No black-box decisions without audit trail.
        """
        # Check if we have session tracking
        if not context.get("session_id"):
            return False, "No session ID for accountability", ["Missing session_id"]
        
        # Check if we're in a known worker context
        if not context.get("worker"):
            return False, "No worker context", ["Missing worker"]
        
        return True, "Operation is transparent", []
    
    # ========================================================================
    # ARTICLE 3: ACCOUNTABILITY - Every action attributable
    # ========================================================================
    def article_3_accountability(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        Every action must be attributable to a specific session/user.
        """
        if not context.get("session_id"):
            return False, "No session for accountability", ["Anonymous session"]
        
        # Session should exist in database (handled by service layer)
        return True, "Action attributable", []
    
    # ========================================================================
    # ARTICLE 4: DETERMINISM - Same input = same output
    # ========================================================================
    def article_4_determinism(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        Same input + same context must produce same output.
        Non-deterministic elements must be logged.
        """
        # Check for non-deterministic indicators
        non_deterministic = [
            "random", "randint", "shuffle", "time(", "datetime",
            "uuid", "nanoseconds", "timestamp"
        ]
        
        violations = []
        for item in non_deterministic:
            if item in task.lower():
                violations.append(f"Potential non-deterministic element: {item}")
        
        if violations:
            return False, "Non-deterministic elements detected", violations
        return True, "Deterministic operation", []
    
    # ========================================================================
    # ARTICLE 5: SAFETY - No harmful operations
    # ========================================================================
    def article_5_safety(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        No harmful operations that could damage system or data.
        """
        harmful_patterns = [
            # File system destruction
            "rm -rf", "del /f", "format ", "dd if=", "mkfs",
            "remove-recursive", "unlink --recursive",
            
            # Database destruction
            "DROP TABLE", "DROP DATABASE", "DELETE FROM", "TRUNCATE",
            
            # System commands
            "shutdown", "reboot", "halt", "poweroff",
            "taskkill /F", "kill -9", "pkill -f",
            
            # Privilege escalation
            "sudo", "su ", "chmod 777", "chown root"
        ]
        
        violations = []
        for pattern in harmful_patterns:
            if pattern in task.upper() or pattern in task.lower():
                violations.append(f"Harmful pattern detected: {pattern}")
        
        if violations:
            return False, "Safety violation", violations
        return True, "Operation is safe", []
    
    # ========================================================================
    # ARTICLE 6: PRIVACY - No PII collection
    # ========================================================================
    def article_6_privacy(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        No PII (Personally Identifiable Information) collection or storage.
        """
        pii_patterns = [
            "email", "phone", "address", "ssn", "credit card", "passport",
            "driver license", "bank account", "routing number", "dob",
            "birth date", "social security", "medicare"
        ]
        
        violations = []
        for pattern in pii_patterns:
            if pattern in task.lower():
                violations.append(f"Potential PII detected: {pattern}")
        
        if violations:
            return False, "Privacy violation - PII detected", violations
        return True, "No PII detected", []
    
    # ========================================================================
    # ARTICLE 7: AUDITABILITY - Full logging required
    # ========================================================================
    def article_7_auditability(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        All operations must be logged for audit.
        """
        # Always true if we're using this system
        return True, "Audit trail available", []
    
    # ========================================================================
    # ARTICLE 8: RECOVERABILITY - Can rollback to known state
    # ========================================================================
    def article_8_recoverability(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        System must be able to rollback to known state.
        Operations should be idempotent or have rollback plans.
        """
        worker = context.get("worker")
        
        # Different workers have different recoverability requirements
        if worker == "files":
            # File operations should be idempotent or have backups
            if "delete" in task.lower() and "backup" not in task.lower():
                return False, "File deletion without backup", ["Non-recoverable delete"]
        
        elif worker == "code":
            # Code generation should be revertible
            if "overwrite" in task.lower() and "backup" not in task.lower():
                return False, "Code overwrite without backup", ["Non-recoverable overwrite"]
        
        return True, "Operation is recoverable", []
    
    # ========================================================================
    # ARTICLE 9: BOUNDEDNESS - Operations stay within scope
    # ========================================================================
    def article_9_boundedness(self, task: str, context: Dict[str, Any]) -> tuple:
        """
        Operations must stay within defined scope/worker boundaries.
        """
        worker = context.get("worker")
        
        # Brain worker - general reasoning, should stay in its lane
        if worker == "brain":
            # Check if trying to do file operations
            file_ops = ["list files", "read file", "write file", "delete file"]
            for op in file_ops:
                if op in task.lower():
                    return False, "Brain worker attempting file operation", ["Use files worker instead"]
        
        # Files worker - must stay within project directory
        elif worker == "files":
            if ".." in task or task.startswith("/") or ":" in task:
                return False, "Files worker attempting to escape sandbox", ["Path traversal detected"]
        
        # Code worker - should only generate code, not execute it
        elif worker == "code":
            if "execute" in task.lower() or "run" in task.lower():
                return False, "Code worker attempting execution", ["Use hands worker for execution"]
        
        return True, "Operation within bounds", []
    
    # ========================================================================
    # MAIN VALIDATION FUNCTION
    # ========================================================================
    def validate_task(self, task: str, worker: str, session_id: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Validate a task against all constitutional articles.
        Returns detailed ruling with reasons and suggestions.
        """
        start_time = time.time()
        
        full_context = {
            "worker": worker,
            "session_id": session_id,
            "timestamp": time.time()
        }
        if context:
            full_context.update(context)
        
        results = {}
        violations = []
        articles_applied = []
        
        # Check each article
        for article_name, check_func in self.articles.items():
            passed, reason, article_violations = check_func(task, full_context)
            results[article_name] = {
                "passed": passed,
                "reason": reason,
                "violations": article_violations
            }
            
            articles_applied.append(article_name)
            if not passed:
                violations.extend(article_violations)
        
        # Determine verdict
        if not violations:
            verdict = Verdict.ALLOWED
            reason = "All constitutional articles satisfied"
        else:
            # Check severity - some violations are warnings, some are blockers
            critical_violations = [v for v in violations if "delete" in v or "DROP" in v or "rm" in v]
            if critical_violations:
                verdict = Verdict.DENIED
                reason = f"Critical constitutional violations: {', '.join(critical_violations[:3])}"
            else:
                verdict = Verdict.REQUIRES_CONFIRMATION
                reason = f"Non-critical violations detected: {', '.join(violations[:3])}"
        
        # Create ruling record
        ruling = ConstitutionalRuling(
            ruling_id=hashlib.sha256(f"{task}{time.time()}".encode()).hexdigest()[:16],
            timestamp=start_time,
            iso_time=datetime.utcnow().isoformat(),
            intent_hash=hashlib.sha256(task.encode()).hexdigest()[:16],
            intent_preview=task[:50] + "..." if len(task) > 50 else task,
            worker=worker,
            session_id=session_id,
            verdict=verdict,
            articles_applied=articles_applied,
            violations=violations,
            processing_time_ms=(time.time() - start_time) * 1000,
            context=full_context
        )
        
        # Store ruling
        self.rulings.append(ruling)
        self._append_to_ledger(ruling)
        
        return {
            "ruling_id": ruling.ruling_id,
            "verdict": verdict.value,
            "reason": reason,
            "violations": violations,
            "articles_applied": articles_applied,
            "processing_time_ms": ruling.processing_time_ms,
            "requires_confirmation": verdict == Verdict.REQUIRES_CONFIRMATION
        }
    
    def _append_to_ledger(self, ruling: ConstitutionalRuling):
        """Append ruling to immutable ledger"""
        try:
            with open(self.ledger_path, "a") as f:
                f.write(json.dumps(ruling.to_dict()) + "\n")
        except Exception as e:
            logger.error(f"Failed to write to ledger: {e}")
    
    def get_ruling_history(self, session_id: Optional[str] = None, limit: int = 100) -> List[Dict]:
        """Get ruling history, optionally filtered by session"""
        if session_id:
            filtered = [r for r in self.rulings if r.session_id == session_id][-limit:]
        else:
            filtered = self.rulings[-limit:]
        return [r.to_dict() for r in filtered]

# Global constitution instance
constitution = ZeroDriftConstitution()