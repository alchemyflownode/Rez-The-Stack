# executive_server_real.py
# Real Executive MCP Server – Stores notes to files

import os
import json
import sys
from datetime import datetime
from pathlib import Path

NOTES_DIR = Path.home() / "rezstack_brain"
NOTES_DIR.mkdir(exist_ok=True)

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'take_note':
        content = params.get('content', '')
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        filename = NOTES_DIR / "memory.md"
        
        with open(filename, 'a', encoding='utf-8') as f:
            f.write(f"\n## {timestamp}\n{content}\n---\n")
        
        return {
            'success': True,
            'message': f'Note saved to {filename}'
        }
    
    elif method == 'search_notes':
        query = params.get('query', '').lower()
        results = []
        filename = NOTES_DIR / "memory.md"
        
        if filename.exists():
            with open(filename, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                for i, line in enumerate(lines):
                    if query in line.lower():
                        results.append({
                            'filename': 'memory.md',
                            'line': i + 1,
                            'context': line.strip()
                        })
        
        return {'success': True, 'results': results[:5]}
    
    else:
        return {'success': True, 'message': 'Command processed'}

# MCP over stdio
if __name__ == "__main__":
    print("🧠 REAL Executive MCP running...", file=sys.stderr)
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            error = {'error': str(e)}
            sys.stdout.write(json.dumps(error) + '\n')
            sys.stdout.flush()
