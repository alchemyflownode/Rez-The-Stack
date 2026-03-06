"""
Hands Worker - Code generation with qwen2.5-coder
"""

import ollama
import logging

logger = logging.getLogger(__name__)

class HandsWorker:
    def __init__(self):
        self.name = "hands"
        self.description = "Code generation"
        self.model = "qwen2.5-coder:14b"
    
    async def process(self, task: str, model: str = None) -> dict:
        """Generate code"""
        model_to_use = model or self.model
        response = ollama.chat(
            model=model_to_use,
            messages=[{"role": "user", "content": task}],
            stream=False,
        )
        return {"code": response["message"]["content"]}
