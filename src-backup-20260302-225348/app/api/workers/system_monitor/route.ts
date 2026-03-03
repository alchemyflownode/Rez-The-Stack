import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);
const MONITOR_PATH = path.join(process.cwd(), 'src/api/workers/system_agent.py');

export async function POST(request: NextRequest) {
  try {
    const { stdout } = await execAsync(`python "${MONITOR_PATH}" snapshot`, { timeout: 5000 });
    const stats = JSON.parse(stdout);
    
    return NextResponse.json({
      status: 'success',
      worker: 'system_monitor',
      stats: stats
    });
  } catch (error: any) {
    return NextResponse.json({ 
      status: 'error', 
      message: error.message 
    }, { status: 500 });
  }
}

export async function GET() {
  return NextResponse.json({
    status: 'online',
    worker: 'system_monitor',
    message: 'System monitor ready'
  });
}
