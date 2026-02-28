# src/workers/mcp_client.py
import subprocess
import json
import sys

def call_mcp_tool(tool_name: str, args: dict):
    """Calls the Executive MCP server via stdin/stdout"""
    # In a real setup, we'd use the MCP client library.
    # Here we simulate the call for direct integration.
    
    if tool_name == "take_note":
        # Direct call to logic for speed
        from executive_mcp_server import take_note
        return take_note(args.get("content"), args.get("filename", "inbox.md"))
    elif tool_name == "create_task":
        from executive_mcp_server import create_task
        return create_task(args.get("title"), args.get("priority", "medium"))
    elif tool_name == "list_tasks":
        from executive_mcp_server import list_tasks
        return list_tasks()
    elif tool_name == "create_reminder":
        from executive_mcp_server import create_reminder
        return create_reminder(args.get("title"), args.get("minutes", 60))
    else:
        return json.dumps({"error": "Unknown tool"})

if __name__ == "__main__":
    cmd = sys.argv[1]
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    result = call_mcp_tool(cmd, args)
    print(json.dumps({"status": "success", "result": result}))
