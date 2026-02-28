import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);

export async function GET() {
  try {
    const scriptPath = path.join(process.cwd(), 'src/workers/system_agent.py');
    
    // Run quick snapshot (no interval delay for API calls)
    const { stdout } = await execAsync(`python "${scriptPath}" snapshot`);
    const stats = JSON.parse(stdout);
    
    // ANALYZE FOR ALERTS
    const alerts = [];
    if (stats.cpu?.percent > 80) alerts.push(`⚠️ CPU High: ${stats.cpu.percent}%`);
    if (stats.memory?.percent > 90) alerts.push(`⚠️ RAM Critical: ${stats.memory.percent}%`);
    if (stats.gpu?.available && stats.gpu?.temp > 85) alerts.push(`🔥 GPU Hot: ${stats.gpu.temp}°C`);

    return NextResponse.json({
      status: 'alive',
      timestamp: new Date().toISOString(),
      stats: stats,
      alerts: alerts
    });
    
  } catch (e: any) {
    return NextResponse.json({ status: 'dead', error: e.message });
  }
}
