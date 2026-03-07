"""
Vision Worker - Screen analysis using LLaVA
Gives REZ HIVE the ability to see and understand your screen
"""

import asyncio
import ollama
import mss
import mss.tools
import base64
import io
from PIL import Image
import logging
import os
import tempfile
from datetime import datetime

logger = logging.getLogger(__name__)

class VisionWorker:
    def __init__(self):
        self.name = "vision"
        self.description = "Screen analysis and computer vision"
        self.model = "llava:7b"
        self.sct = mss.mss()
    
    def _capture_screen(self, monitor: int = 1) -> Image.Image:
        monitors = self.sct.monitors
        if monitor >= len(monitors):
            monitor = 1
        screenshot = self.sct.grab(monitors[monitor])
        img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
        return img
    
    def _capture_region(self, left: int, top: int, width: int, height: int) -> Image.Image:
        monitor = {"left": left, "top": top, "width": width, "height": height}
        screenshot = self.sct.grab(monitor)
        img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
        return img
    
    def _image_to_base64(self, img: Image.Image) -> str:
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        img_str = base64.b64encode(buffer.getvalue()).decode('utf-8')
        return img_str
    
    def _save_screenshot(self, img: Image.Image) -> str:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"screen_{timestamp}.png"
        filepath = os.path.join(tempfile.gettempdir(), filename)
        img.save(filepath)
        return filepath
    
    async def analyze_screen(self, prompt: str, monitor: int = 1) -> str:
        logger.info(f"👁️ Capturing screen for analysis: {prompt}")
        img = await asyncio.to_thread(self._capture_screen, monitor)
        filepath = self._save_screenshot(img)
        logger.info(f"📸 Screenshot saved: {filepath}")
        img_base64 = self._image_to_base64(img)
        
        messages = [{"role": "user", "content": prompt, "images": [img_base64]}]
        response = await asyncio.to_thread(
            ollama.chat,
            model=self.model,
            messages=messages,
            options={"temperature": 0.2}
        )
        return response['message']['content']
    
    async def process(self, task: str, model: str = None) -> dict:
        task_lower = task.lower().strip()
        
        if task_lower in ["describe screen", "what do you see", "look"]:
            description = await self.analyze_screen("Describe what you see on this screen in detail.")
            return {"content": f"👁️ **Screen Analysis:**\n\n{description}"}
        
        elif task_lower.startswith("find "):
            element = task[5:].strip()
            result = await self.analyze_screen(f"Look at this screen and tell me where I can find '{element}'. Describe its location.")
            return {"content": f"🔍 **Looking for '{element}':**\n\n{result}"}
        
        elif "read text" in task_lower or "ocr" in task_lower:
            text = await self.analyze_screen("Read all the text you can see on this screen. Just output the raw text.")
            return {"content": f"📝 **Text detected:**\n\n{text}"}
        
        elif task_lower.startswith("analyze:") or task_lower.startswith("vision:"):
            prompt = task.replace("analyze:", "").replace("vision:", "").strip()
            analysis = await self.analyze_screen(prompt)
            return {"content": f"👁️ **Analysis:**\n\n{analysis}"}
        
        elif task_lower == "screenshot" or task_lower == "capture":
            img = await asyncio.to_thread(self._capture_screen)
            filepath = self._save_screenshot(img)
            return {"content": f"📸 **Screenshot saved to:**\n`{filepath}`"}
        
        else:
            return {
                "content": """👁️ **Vision Worker Ready**

**Commands:**
• `describe screen` - Describe what's on your screen
• `find [element]` - Locate UI elements
• `read text` - OCR - read all text
• `analyze: [question]` - Ask custom questions
• `screenshot` - Just save a screenshot"""
            }
