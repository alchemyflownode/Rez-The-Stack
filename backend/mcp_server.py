"""
MCP Server for REZ HIVE - Exposes your workers as MCP tools
"""

import asyncio
import logging
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
from mcp.types import Tool, TextContent, CallToolResult
import mcp.server.stdio

# Import your workers
from workers.memory_worker import MemoryWorker
from workers.eyes_worker import EyesWorker
from workers.hands_worker import HandsWorker

logger = logging.getLogger(__name__)

# Initialize MCP server
server = Server("rez-hive")

# Initialize workers (reuse existing instances)
memory_worker = MemoryWorker()
eyes_worker = EyesWorker()
hands_worker = HandsWorker()

@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    """List all available REZ HIVE tools via MCP"""
    return [
        Tool(
            name="search_pc",
            description="Search for files on the local PC",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Filename or pattern to search for",
                    },
                    "max_results": {
                        "type": "number",
                        "description": "Maximum number of results",
                        "default": 50
                    }
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="web_search",
            description="Search the web for information",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query",
                    }
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="generate_code",
            description="Generate Python code for a task",
            inputSchema={
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "Description of code to generate",
                    }
                },
                "required": ["task"]
            }
        ),
        Tool(
            name="remember",
            description="Store information in persistent memory",
            inputSchema={
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "Information to remember",
                    }
                },
                "required": ["content"]
            }
        ),
        Tool(
            name="recall",
            description="Retrieve information from memory",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "What to search for in memory",
                    }
                },
                "required": ["query"]
            }
        ),
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute REZ HIVE tools via MCP"""
    
    if name == "search_pc":
        query = arguments.get("query")
        max_results = arguments.get("max_results", 50)
        result = await memory_worker.search_entire_pc(query, max_results)
        return [TextContent(type="text", text=str(result))]
    
    elif name == "web_search":
        query = arguments.get("query")
        result = await eyes_worker.process(query)
        return [TextContent(type="text", text=result.get("content", ""))]
    
    elif name == "generate_code":
        task = arguments.get("task")
        result = await hands_worker.process(task)
        return [TextContent(type="text", text=result.get("code", ""))]
    
    elif name == "remember":
        content = arguments.get("content")
        # Use your existing memory worker
        doc_id = await memory_worker.store_memory(content)
        return [TextContent(type="text", text=f"Stored as {doc_id}")]
    
    elif name == "recall":
        query = arguments.get("query")
        results = await memory_worker.search_memory(query)
        return [TextContent(type="text", text=str(results))]
    
    else:
        return [TextContent(type="text", text=f"Unknown tool: {name}")]

async def main():
    """Run the MCP server"""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="rez-hive",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )

if __name__ == "__main__":
    asyncio.run(main())