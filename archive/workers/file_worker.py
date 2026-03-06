from lib.gpu_manager import sovereign_generate
import sys
from pathlib import Path
_project_root = Path(__file__).parent.parent.parent
if str(_project_root) not in sys.path: sys.path.insert(0, str(_project_root))
import os
import json
import sys
from pathlib import Path

def list_files(path="."):
    try:
        files = []
        for item in Path(path).iterdir():
            files.append({
                "name": item.name,
                "type": "directory" if item.is_dir() else "file",
                "size": item.stat().st_size if item.is_file() else 0,
                "modified": item.stat().st_mtime
            })
        return {"success": True, "files": files[:20], "path": os.path.abspath(path)}
    except Exception as e:
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if "list" in cmd.lower() or "files" in cmd.lower():
            result = list_files()
        else:
            result = {"success": False, "error": "Unknown command"}
    else:
        result = list_files()
    
    print(json.dumps(result))
