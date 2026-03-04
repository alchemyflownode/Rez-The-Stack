# executive_mcp.py
import sys
import json
import os
import sqlite3
from datetime import datetime
from pathlib import Path

MEMORY_DIR = Path.home() / "rezstack_brain"
MEMORY_DIR.mkdir(exist_ok=True)
NOTES_FILE = MEMORY_DIR / "memory.md"
DB_FILE = MEMORY_DIR / "tasks.db"

# Initialize SQLite
conn = sqlite3.connect(str(DB_FILE))
conn.execute('''
    CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT DEFAULT 'medium',
        status TEXT DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
''')
conn.commit()
conn.close()

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'take_note':
        content = params.get('content', '')
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(NOTES_FILE, 'a', encoding='utf-8') as f:
            f.write(f"\n## {timestamp}\n{content}\n---\n")
        return {'success': True, 'message': 'Note saved', 'file': str(NOTES_FILE)}
    
    elif method == 'search_notes':
        query = params.get('query', '').lower()
        results = []
        if NOTES_FILE.exists():
            with open(NOTES_FILE, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                for i, line in enumerate(lines):
                    if query in line.lower():
                        results.append({
                            'line': i + 1,
                            'context': line.strip()
                        })
        return {'success': True, 'results': results[:10]}
    
    elif method == 'create_task':
        conn = sqlite3.connect(str(DB_FILE))
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO tasks (title, description, priority) VALUES (?, ?, ?)",
            (params.get('title', ''), params.get('description', ''), params.get('priority', 'medium'))
        )
        task_id = cursor.lastrowid
        conn.commit()
        conn.close()
        return {'success': True, 'task_id': task_id}
    
    elif method == 'list_tasks':
        conn = sqlite3.connect(str(DB_FILE))
        cursor = conn.cursor()
        cursor.execute("SELECT id, title, priority FROM tasks WHERE status = 'pending'")
        tasks = [{'id': r[0], 'title': r[1], 'priority': r[2]} for r in cursor.fetchall()]
        conn.close()
        return {'success': True, 'tasks': tasks}
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("Executive MCP Server Running\n")
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
