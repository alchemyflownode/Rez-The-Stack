import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// Expanded whitelist with all apps
const ALLOWED_APPS = ['notepad', 'calc', 'mspaint', 'explorer', 'cmd', 'chrome', 'code', 'vscode', 'spotify', 'discord'];

export async function POST(request: NextRequest) {
  try {
    const { task } = await request.json();
    
    // Better app name extraction
    let appName = task.toLowerCase()
      .replace('open ', '')
      .replace('launch ', '')
      .replace('start ', '')
      .replace('run ', '')
      .trim();
    
    // Handle multi-word app names
    if (appName.includes('vscode') || appName.includes('visual studio')) {
      appName = 'code';
    } else if (appName.includes('chrome')) {
      appName = 'chrome';
    } else if (appName.includes('spotify')) {
      appName = 'spotify';
    } else if (appName.includes('discord')) {
      appName = 'discord';
    }
    
    if (!ALLOWED_APPS.includes(appName)) {
      return NextResponse.json({ 
        status: 'error', 
        error: `App '${appName}' not in whitelist. Allowed: ${ALLOWED_APPS.join(', ')}` 
      }, { status: 403 });
    }
    
    // Launch the app
    const cmd = process.platform === 'win32' ? `start ${appName}` : appName;
    await execAsync(cmd, { timeout: 5000 });
    
    return NextResponse.json({ 
      status: 'success', 
      worker: 'app', 
      launched: appName 
    });
    
  } catch (error: any) {
    return NextResponse.json({ 
      status: 'error', 
      error: error.message 
    }, { status: 500 });
  }
}
