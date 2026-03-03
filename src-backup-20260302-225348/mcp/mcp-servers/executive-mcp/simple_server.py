# executive_simple.py – Simple MCP server without fastmcp

import sys
import json
import sqlite3
import os
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional

# Simple MCP protocol implementation
class SimpleMCPServer:
    def __init__(self):
        self.brain_path = "G:/okiru/brain"
        self.notes_path = os.path.join(self.brain_path, "daily_notes")
        self.tasks_db = os.path.join(self.brain_path, "tasks.db")
        self.reminders_db = os.path.join(self.brain_path, "reminders.db")
        
        # Create directories if needed
        os.makedirs(self.notes_path, exist_ok=True)
        self._init_database()
    
    def _init_database(self):
        """Initialize SQLite databases"""
        # Tasks DB
        conn = sqlite3.connect(self.tasks_db)
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
        
        # Reminders DB
        conn = sqlite3.connect(self.reminders_db)
        conn.execute('''
            CREATE TABLE IF NOT EXISTS reminders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                trigger_time TIMESTAMP NOT NULL,
                status TEXT DEFAULT 'active'
            )
        ''')
        conn.commit()
        conn.close()
    
    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle incoming MCP request"""
        method = request.get('method', '')
        params = request.get('params', {})
        
        if method == 'take_note':
            return self._take_note(params.get('content', ''))
        elif method == 'create_task':
            return self._create_task(params.get('title', ''))
        elif method == 'list_tasks':
            return self._list_tasks()
        elif method == 'create_reminder':
            return self._create_reminder(
                params.get('title', ''),
                params.get('minutes', 5)
            )
        else:
            return {'error': f'Unknown method: {method}'}
    
    def _take_note(self, content: str) -> Dict[str, Any]:
        path = os.path.join(self.notes_path, "inbox.md")
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(path, "a", encoding="utf-8") as f:
            f.write(f"\n## {timestamp}\n{content}\n---\n")
        return {
            'success': True,
            'message': f'Note saved to your brain'
        }
    
    def _create_task(self, title: str) -> Dict[str, Any]:
        conn = sqlite3.connect(self.tasks_db)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO tasks (title) VALUES (?)",
            (title,)
        )
        task_id = cursor.lastrowid
        conn.commit()
        conn.close()
        return {
            'success': True,
            'message': f'Task created: {title} (ID: {task_id})'
        }
    
    def _list_tasks(self) -> Dict[str, Any]:
        conn = sqlite3.connect(self.tasks_db)
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, title, priority FROM tasks WHERE status = 'pending'"
        )
        tasks = [{'id': row[0], 'title': row[1], 'priority': row[2]} 
                for row in cursor.fetchall()]
        conn.close()
        return {'success': True, 'tasks': tasks}
    
    def _create_reminder(self, title: str, minutes: int) -> Dict[str, Any]:
        trigger = datetime.now() + timedelta(minutes=minutes)
        conn = sqlite3.connect(self.reminders_db)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO reminders (title, trigger_time) VALUES (?, ?)",
            (title, trigger.isoformat())
        )
        reminder_id = cursor.lastrowid
        conn.commit()
        conn.close()
        return {
            'success': True,
            'message': f'Reminder set for {minutes} minutes: {title}'
        }

# Main loop
if __name__ == "__main__":
    server = SimpleMCPServer()
    print("📋 Simple Executive MCP running (stdio)...")
    
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            request = json.loads(line)
            response = server.handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            error_response = {'error': str(e)}
            sys.stdout.write(json.dumps(error_response) + '\n')
            sys.stdout.flush()
