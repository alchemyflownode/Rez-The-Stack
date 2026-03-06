import psutil
import json
import sys
from datetime import datetime

try:
    import GPUtil
    HAS_GPU = True
except:
    HAS_GPU = False

def get_snapshot():
    try:
        # FIX: Use interval=None for INSTANT non-blocking read
        # Returns 0.0 on first call, but instant thereafter
        cpu = psutil.cpu_percent(interval=None)
        mem = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        gpu_data = {"available": False}
        if HAS_GPU:
            try:
                gpus = GPUtil.getGPUs()
                if gpus:
                    gpu = gpus[0]
                    gpu_data = {
                        "available": True,
                        "name": gpu.name,
                        "load": round(gpu.load * 100, 1),
                        "temp": gpu.temperature,
                        "vram_used_gb": round(gpu.memoryUsed / 1024, 1)
                    }
            except: pass

        return {
            "success": True,
            "timestamp": datetime.now().isoformat(),
            "cpu": {"percent": cpu},
            "memory": {"percent": mem.percent},
            "disk": {"percent": round((disk.used / disk.total) * 100, 1)},
            "gpu": gpu_data
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    print(json.dumps(get_snapshot()))
