// src/lib/hardware-context.ts
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);

export async function getHardwareContext() {
  try {
    // Try to get real hardware stats
    const scriptPath = path.join(process.cwd(), 'src/workers/vram_monitor.py');
    const { stdout } = await execAsync(`python "${scriptPath}" --json`);
    const data = JSON.parse(stdout);
    
    return {
      cpu: data.cpu_percent,
      ram: data.ram?.percent,
      gpu: data.gpu?.name || 'RTX 3060',
      vram: data.gpu?.vram_total_gb || 12,
      gpuLoad: data.gpu?.util_percent || 0,
      workers: [
        'system_monitor',
        'app_launcher', 
        'deepsearch',
        'mutation_worker',
        'executive_mcp',
        'vision_worker'
      ]
    };
  } catch (error) {
    // Fallback to defaults
    return {
      cpu: '?',
      ram: '?',
      gpu: 'RTX 3060',
      vram: 12,
      gpuLoad: '?',
      workers: [
        'system_monitor',
        'app_launcher',
        'deepsearch',
        'mutation_worker',
        'executive_mcp',
        'vision_worker'
      ]
    };
  }
}
