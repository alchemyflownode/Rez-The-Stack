import sys
import json
import sqlite3
import os
from datetime import datetime, timedelta

class SimpleMCPServer:
    def __init__(self):
        self.brain_path = "G:/okiru/brain"
        self.notes_path = os.path.join(self.brain_path, "daily_notes")
        self.tasks_db = os.path.join(self.brain_path, "tasks.db")
        self.reminders_db = os.path.join(self.brain_path, "reminders.db")
        os.makedirs(self.notes_path, exist_ok=True)
        self._init_db()

    def _init_db(self):
        for db, schema in [
            (self.tasks_db, "CREATE TABLE IF NOT EXISTS tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, status TEXT DEFAULT 'pending', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"),
            (self.reminders_db, "CREATE TABLE IF NOT EXISTS reminders (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, trigger_time TIMESTAMP, status TEXT DEFAULT 'active')")
        ]:
            conn = sqlite3.connect(db)
            conn.execute(schema)
            conn.commit()
            conn.close()

    def handle(self, req):
        method = req.get('method')
        params = req.get('params', {})
        if method == 'take_note':
            path = os.path.join(self.notes_path, "inbox.md")
            with open(path, 'a', encoding='utf-8') as f:
                f.write(f"\n## {datetime.now()}\n{params.get('content')}\n---\n")
            return {'success': True, 'message': 'Note saved'}
        elif method == 'create_task':
            conn = sqlite3.connect(self.tasks_db)
            cur = conn.cursor()
            cur.execute("INSERT INTO tasks (title) VALUES (?)", (params.get('title'),))
            conn.commit()
            conn.close()
            return {'success': True, 'message': 'Task created'}
        elif method == 'list_tasks':
            conn = sqlite3.connect(self.tasks_db)
            cur = conn.cursor()
            cur.execute("SELECT id, title FROM tasks WHERE status='pending'")
            tasks = [{'id': r[0], 'title': r[1]} for r in cur.fetchall()]
            conn.close()
            return {'success': True, 'tasks': tasks}
        elif method == 'complete_task':
            conn = sqlite3.connect(self.tasks_db)
            cur = conn.cursor()
            cur.execute("UPDATE tasks SET status='completed' WHERE id=?", (params.get('task_id'),))
            conn.commit()
            conn.close()
            return {'success': True}
        return {'error': 'unknown method'}

if __name__ == '__main__':
    server = SimpleMCPServer()
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            resp = server.handle(json.loads(line))
            sys.stdout.write(json.dumps(resp) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()

