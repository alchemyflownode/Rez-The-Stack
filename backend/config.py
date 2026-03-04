# backend/config.py
import os
from dotenv import load_dotenv

load_dotenv()

# Model configuration - defaults to your sovereign model
OLLAMA_BASE = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "sovereign-constitutional:latest")

# Worker model mapping
WORKER_MODELS = {
    "brain": os.getenv("BRAIN_MODEL", OLLAMA_MODEL),
    "eyes": os.getenv("EYES_MODEL", "llama3.2-vision:11b"),  # Vision model
    "hands": os.getenv("HANDS_MODEL", "phi3.5:3.8b"),        # Fast execution model
    "memory": os.getenv("MEMORY_MODEL", "smollm2:360m"),     # Lightweight embedding
}