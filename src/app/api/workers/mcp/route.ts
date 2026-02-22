import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const { task } = await request.json();
  return NextResponse.json({ 
    status: 'success', 
    worker: 'mcp', 
    message: 'MCP worker mock initialized', 
    note: 'Install actual MCP client for web search capabilities' 
  });
}
