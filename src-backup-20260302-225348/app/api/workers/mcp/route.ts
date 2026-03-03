import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);
const HARVESTER_PATH = path.join(process.cwd(), 'src/workers/harvester.py');

export async function POST(request: NextRequest) {
  try {
    const { task } = await request.json();
    
    let query = task.toLowerCase()
      .replace('search the web for', '')
      .replace('search for', '')
      .replace('search', '')
      .trim();
    
    if (!query) query = 'cyberpunk';

    console.log(`[MCP] Lite Harvester searching: ${query}`);

    const { stdout, stderr } = await execAsync(`python "${HARVESTER_PATH}" "${query}"`, { timeout: 15000 });
    
    if(stderr) console.error(`[MCP] stderr:`, stderr);
    
    const data = JSON.parse(stdout);
    
    return NextResponse.json({ 
      status: 'success',
      worker: 'mcp',
      results: data.results || [],
      source: 'DuckDuckGo (lite)'
    });

  } catch (error: any) {
    console.error('[MCP] CRASH:', error);
    return NextResponse.json({ 
      status: 'error', 
      message: error.message 
    }, { status: 500 });
  }
}
