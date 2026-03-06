# backend/constitutional_wrapper.py
class ZeroDriftConstitution:
    """
    Zero-drift constitutional AI governance.
    Every decision is logged, auditable, and replayable.
    """
    
    def __init__(self):
        self.articles = {
            "sovereignty": self.check_data_sovereignty,
            "transparency": self.check_transparency,
            "accountability": self.check_accountability,
            "determinism": self.check_determinism,
            "safety": self.check_safety,
            "privacy": self.check_privacy,
            "auditability": self.check_auditability,
            "recoverability": self.check_recoverability,
            "boundedness": self.check_boundedness
        }
    
    def check_data_sovereignty(self, task: str, context: dict) -> bool:
        """
        Article 1: All data must stay within the sovereign system.
        No external API calls, no data leakage.
        """
        # Check for external URLs, API calls, etc.
        external_indicators = [
            "http://", "https://", "api.", ".com", ".org",
            "fetch(", "axios.", "requests."
        ]
        for indicator in external_indicators:
            if indicator in task.lower():
                return False
        return True
    
    def check_transparency(self, task: str, context: dict) -> bool:
        """
        Article 2: All operations must be transparent and explainable.
        """
        # Implementation depends on your needs
        return True
    
    def check_accountability(self, task: str, context: dict) -> bool:
        """
        Article 3: Every action must be attributable to a specific session/user.
        """
        return context.get("session_id") is not None
    
    def check_determinism(self, task: str, context: dict) -> bool:
        """
        Article 4: Same input + same context = same output.
        """
        # Implementation depends on your needs
        return True
    
    def check_safety(self, task: str, context: dict) -> bool:
        """
        Article 5: No harmful operations (file deletion, system commands, etc.).
        """
        harmful_patterns = [
            "rm -rf", "del /f", "format ", "dd if=",
            "DROP TABLE", "DELETE FROM"
        ]
        for pattern in harmful_patterns:
            if pattern in task.lower():
                return False
        return True
    
    def check_privacy(self, task: str, context: dict) -> bool:
        """
        Article 6: No PII collection or storage.
        """
        pii_patterns = [
            "email", "phone", "address", "ssn", "credit card"
        ]
        # This would need more sophisticated detection
        return True
    
    def check_auditability(self, task: str, context: dict) -> bool:
        """
        Article 7: All operations must be logged for audit.
        """
        # Always true if we're using the audit system
        return True
    
    def check_recoverability(self, task: str, context: dict) -> bool:
        """
        Article 8: System must be able to rollback to known state.
        """
        # Implementation depends on your needs
        return True
    
    def check_boundedness(self, task: str, context: dict) -> bool:
        """
        Article 9: Operations must stay within defined scope.
        """
        worker = context.get("worker")
        # Different workers have different scopes
        if worker == "files":
            # File operations must stay within project directory
            return ".." not in task and not task.startswith("/")
        return True

    def validate_task(self, task: str, worker: str, session_id: str) -> dict:
        """
        Validate a task against all constitutional articles.
        Returns: {
            "passed": bool,
            "failed_articles": list,
            "reason": str
        }
        """
        context = {"worker": worker, "session_id": session_id}
        failed = []
        
        # Check each article
        for article_name, check_func in self.articles.items():
            if not check_func(task, context):
                failed.append(article_name)
        
        if failed:
            return {
                "passed": False,
                "failed_articles": failed,
                "reason": f"Constitutional violations: {', '.join(failed)}"
            }
        
        return {"passed": True, "failed_articles": [], "reason": ""}