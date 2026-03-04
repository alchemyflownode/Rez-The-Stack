# system_mcp.py
import sys
import json
import psutil
import platform
import datetime

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'get_vitals':
        return {
            'cpu': psutil.cpu_percent(interval=1),
            'memory': psutil.virtual_memory().percent,
            'disk': psutil.disk_usage('/').percent,
            'swap': psutil.swap_memory().percent,
            'boot_time': datetime.datetime.fromtimestamp(psutil.boot_time()).isoformat()
        }
    
    elif method == 'get_processes':
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                processes.append(proc.info)
            except:
                pass
        processes.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
        return {'processes': processes[:20]}
    
    elif method == 'get_system_info':
        return {
            'platform': platform.system(),
            'release': platform.release(),
            'processor': platform.processor(),
            'hostname': platform.node(),
            'python': platform.python_version()
        }
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("System MCP Server Running\n")
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
