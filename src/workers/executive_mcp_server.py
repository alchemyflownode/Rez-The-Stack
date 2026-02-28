# src/workers/executive_mcp_server.py
import os
import json
import sqlite3
from datetime import datetime, timedelta
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("executive")

# Config
BRAIN_PATH = "G:/okiru/brain"
NOTES_PATH = os.path.join(BRAIN_PATH, "daily_notes")
TASKS_DB = os.path.join(BRAIN_PATH, "tasks.db")
REMINDERS_DB = os.path.join(BRAIN_PATH, "reminders.db")

os.makedirs(NOTES_PATH, exist_ok=True)

def init_db():
    # Tasks
    conn = sqlite3.connect(TASKS_DB)
    conn.execute('''CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY, title TEXT, description TEXT, 
        priority TEXT DEFAULT 'medium', status TEXT DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, due_date TIMESTAMP
    )''')
    conn.commit(); conn.close()
    
    # Reminders
    conn = sqlite3.connect(REMINDERS_DB)
    conn.execute('''CREATE TABLE IF NOT EXISTS reminders (
        id INTEGER PRIMARY KEY, title TEXT, message TEXT,
        trigger_time TIMESTAMP, status TEXT DEFAULT 'active'
    )''')
    conn.commit(); conn.close()

init_db()

@mcp.tool()
def take_note(content: str, filename: str = "inbox.md") -> str:
    path = os.path.join(NOTES_PATH, filename)
    ts = datetime.now().strftime("%Y-%m-%d %H:%M")
    with open(path, "a", encoding="utf-8") as f:
        f.write(f"\n## {ts}\n{content}\n---\n")
    return f"📝 Note saved to {filename}."

@mcp.tool()
def create_task(title: str, priority: str = "medium") -> str:
    conn = sqlite3.connect(TASKS_DB)
    conn.execute("INSERT INTO tasks (title, priority) VALUES (?, ?)", (title, priority))
    conn.commit(); conn.close()
    return f"✅ Task created: {title}"

@mcp.tool()
def list_tasks() -> list:
    conn = sqlite3.connect(TASKS_DB)
    cur = conn.cursor()
    cur.execute("SELECT id, title, status, priority FROM tasks WHERE status='pending'")
    return [{"id": r[0], "title": r[1], "status": r[2], "priority": r[3]} for r in cur.fetchall()]

@mcp.tool()
def create_reminder(title: str, minutes: int) -> str:
    trigger = (datetime.now() + timedelta(minutes=minutes)).isoformat()
    conn = sqlite3.connect(REMINDERS_DB)
    conn.execute("INSERT INTO reminders (title, trigger_time) VALUES (?, ?)", (title, trigger))
    conn.commit(); conn.close()
    return f"⏰ Reminder set: {title} in {minutes} mins."

if __name__ == "__main__":
    print("📋 Executive MCP Running...")
    mcp.run()
