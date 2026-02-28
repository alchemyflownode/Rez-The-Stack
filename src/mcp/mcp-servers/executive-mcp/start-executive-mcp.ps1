# start-executive-mcp.ps1
# One-click launcher for Executive MCP server

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "📋 Starting Sovereign Executive MCP..." -ForegroundColor Cyan
python "$scriptDir\server.py"
