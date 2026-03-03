import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);
const GUARDIAN_PATH = path.join(process.cwd(), 'src/workers/guardian.py');

export async function ensureDependencies() {
  console.log('[SOVEREIGN] Running Guardian Check...');
  try {
    // Try python3 first, fallback to python
    let pythonCmd = 'python3';
    try {
      await execAsync(`${pythonCmd} --version`);
    } catch {
      pythonCmd = 'python';
    }

    const { stdout, stderr } = await execAsync(`${pythonCmd} "${GUARDIAN_PATH}"`);
    console.log(stdout);
    if(stderr) console.error(stderr);
    return pythonCmd;
  } catch (error) {
    console.error('[SOVEREIGN] Guardian Check Failed.', error);
    return null;
  }
}
