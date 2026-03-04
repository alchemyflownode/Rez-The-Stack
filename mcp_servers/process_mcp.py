# process_mcp.py
import sys
import json
import psutil
import subprocess
import os

ALLOWED_APPS = {
    'notepad': 'notepad.exe',
    'calc': 'calc.exe',
    'paint': 'mspaint.exe',
    'chrome': 'chrome.exe',
    'code': 'code.exe',
    'explorer': 'explorer.exe'
}

PROTECTED = ['system', 'lsass.exe', 'winlogon.exe', 'services.exe']

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'launch_app':
        app = params.get('app', '').lower()
        if app in ALLOWED_APPS:
            try:
                subprocess.Popen(ALLOWED_APPS[app], shell=True)
                return {'success': True, 'message': f'Launched {app}'}
            except Exception as e:
                return {'error': str(e)}
        return {'error': f'App {app} not allowed'}
    
    elif method == 'kill_process':
        pid = params.get('pid')
        name = params.get('name', '').lower()
        
        if name in PROTECTED:
            return {'error': 'Cannot kill protected process'}
        
        try:
            if pid:
                proc = psutil.Process(pid)
                proc.terminate()
                return {'success': True, 'message': f'Terminated PID {pid}'}
            elif name:
                killed = []
                for proc in psutil.process_iter(['pid', 'name']):
                    if proc.info['name'] and proc.info['name'].lower() == name:
                        proc.terminate()
                        killed.append(proc.info['pid'])
                return {'success': True, 'message': f'Terminated {len(killed)} processes'}
        except Exception as e:
            return {'error': str(e)}
    
    elif method == 'list_apps':
        return {'apps': list(ALLOWED_APPS.keys())}
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("Process MCP Server Running\n")
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()
