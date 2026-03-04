# backend/startup_check.py
import requests

def verify_models():
    """Ensure required models are pulled in Ollama"""
    required = [
        "sovereign-constitutional:latest",
        "llama3.2-vision:11b",  # For Eyes worker
        "phi3.5:3.8b",          # For Hands worker
    ]
    
    try:
        available = requests.get("http://localhost:11434/api/tags").json()
        installed = [m["name"] for m in available.get("models", [])]
        
        missing = [m for m in required if m not in installed]
        if missing:
            print(f"⚠️  Missing models: {missing}")
            print("   Run: " + " ".join([f"ollama pull {m}" for m in missing]))
            return False
        return True
    except Exception as e:
        print(f"✗  Could not verify models: {e}")
        return False