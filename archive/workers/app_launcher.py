import subprocess
import json
import sys
import os

ALLOWED_APPS = {
    "chrome": "start chrome",
    "notepad": "start notepad",
    "calc": "start calc",
    "code": "start code",
    "spotify": "start spotify",
    "discord": "start discord"
}

def launch(app_name):
    # PSALM 91:11 "He will command his angels..."
    # Only whitelisted apps are permitted to execute.
    app = app_name.lower().strip()
    
    if app in ALLOWED_APPS:
        try:
            cmd = ALLOWED_APPS[app]
            if os.name == 'nt':
                subprocess.Popen(cmd, shell=True, creationflags=0x08000000) # CREATE_NO_WINDOW
            return {"success": True, "message": f"Launched {app}"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    else:
        return {"success": False, "error": "App not in Whitelist (Guardian)"}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        print(json.dumps(launch(sys.argv[1])))
