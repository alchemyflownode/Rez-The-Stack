import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);
const ALLOWED_APPS = ['notepad', 'calc', 'mspaint', 'chrome', 'code', 'explorer'];

export async function POST(request: NextRequest) {
  const { task, action, app } = await request.json();
  try {
    if (task && task.toLowerCase().includes('launch')) {
      const appName = task.toLowerCase().replace('launch', '').trim() || 'notepad';
      if (!ALLOWED_APPS.includes(appName)) return NextResponse.json({ status: 'error', message: 'App not allowed' }, { status: 403 });
      await execAsync(`start ${appName}`);
      return NextResponse.json({ status: 'success', worker: 'app', message: `Launched ${appName}` });
    }
    return NextResponse.json({ status: 'error', message: 'No valid action' }, { status: 400 });
  } catch (error: any) {
    return NextResponse.json({ status: 'error', message: error.message }, { status: 500 });
  }
}
