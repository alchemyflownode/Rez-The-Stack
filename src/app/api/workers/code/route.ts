import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, unlink, mkdir } from 'fs/promises';
import { join } from 'path';

const execAsync = promisify(exec);
const CODE_MODEL = 'codellama:7b'; 
const OLLAMA_ENDPOINT = 'http://localhost:11434/api/generate';

export async function POST(request: NextRequest) {
  const { task, language = 'python', code } = await request.json();
  
  try {
    if (task && !code) {
      const response = await fetch(OLLAMA_ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: CODE_MODEL,
          prompt: `Write a ${language} script to: ${task}. Output only the code, no explanation.`,
          stream: false
        })
      });
      const data = await response.json();
      return NextResponse.json({ 
        status: 'success',
        action: 'code_generated',
        code: data.response,
        language,
        worker: 'code-worker'
      });
    }
    
    if (code) {
      const tempDir = join(process.cwd(), 'src/temp_workspace');
      const ext = language === 'python' ? 'py' : 'js';
      const tempFile = join(tempDir, `temp_${Date.now()}.${ext}`);
      
      await mkdir(tempDir, { recursive: true });
      await writeFile(tempFile, code);
      
      const cmd = language === 'python' ? `python "${tempFile}"` : `node "${tempFile}"`;
      const { stdout, stderr } = await execAsync(cmd, { timeout: 10000 });
      
      await unlink(tempFile).catch(() => {});
      
      return NextResponse.json({ 
        status: 'success',
        action: 'code_executed',
        output: stdout,
        error: stderr,
        worker: 'code-worker'
      });
    }
    
    return NextResponse.json({ status: 'error', message: 'No task or code' }, { status: 400 });
  } catch (error: any) {
    return NextResponse.json({ status: 'error', message: error.message, worker: 'code-worker' }, { status: 500 });
  }
}
