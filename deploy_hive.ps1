# 🏛️ REZ HIVE DEPLOYMENT SCRIPT (PowerShell)
# This script generates the complete architectural structure for the Cognitive Kernel Hive.
# Run this in your project root: 'G:\okiru\app builder\Cognitive Kernel'

Write-Host "🦊 Initializing Rez Hive Architecture..." -ForegroundColor Cyan

# --- 1. Directory Structure ---
Write-Host "📂 Creating Hive Directory Structure..." -ForegroundColor Yellow]
 $dirs = @(
    "src\lib\types",
    "src\app\api\kernel",
    "src\app\api\workers\code",
    "src\app\api\workers\app",
    "src\app\api\workers\file",
    "src\temp_workspace"
)
foreach ($dir in $dirs) {
    $path = Join-Path -Path $pwd -ChildPath $dir
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "   Created: $dir" -ForegroundColor DarkGray
    }
}

# --- 2. Type Definitions (The Constitution) ---
Write-Host "📜 Writing Hive Protocol Types..." -ForegroundColor Yellow
 $typesPath = "src\lib\types\worker.ts"
 $typesContent = @'
// 🏛️ The Hive Constitution: Standard Communication Protocol

export interface SwarmMessage {
  from: string;           // 'queen' | 'code-worker' | 'app-worker' | 'file-worker'
  to: string;             // target agent
  task: string;           // what needs doing
  context: any;           // relevant data
  priority: 'low' | 'medium' | 'high';
  replyTo?: string;       // for chaining
}

export interface WorkerCapability {
  name: string;
  actions: string[];      // ['write-file', 'execute-code', 'launch-app']
  endpoint: string;       // API endpoint
  status: 'idle' | 'busy' | 'offline';
}

export interface WorkerResponse {
  status: 'success' | 'error';
  action: string;
  output?: any;
  error?: string;
  worker: string;
}
'@
Set-Content -Path $typesPath -Value $typesContent -Encoding UTF8

# --- 3. Code Worker (The Hands) ---
Write-Host "🐝 Deploying Code Worker..." -ForegroundColor Yellow
 $codeWorkerPath = "src\app\api\workers\code\route.ts"
 $codeWorkerContent = @'
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
    // === Mode A: Code Generation ===
    if (task && !code) {
      console.log(`[Code Worker] Generating ${language} code for: ${task}`);
      
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
      const generatedCode = data.response;
      
      return NextResponse.json({ 
        status: 'success',
        action: 'code_generated',
        code: generatedCode,
        language,
        worker: 'code-worker'
      });
    }
    
    // === Mode B: Code Execution ===
    if (code) {
      console.log(`[Code Worker] Executing ${language} code...`);
      const tempDir = join(process.cwd(), 'src/temp_workspace');
      const extension = language === 'python' ? 'py' : 'js';
      const tempFile = join(tempDir, `temp_${Date.now()}.${extension}`);
      
      await mkdir(tempDir, { recursive: true });
      await writeFile(tempFile, code);
      
      const command = language === 'python' 
        ? `python "${tempFile}"` 
        : `node "${tempFile}"`;
      
      const { stdout, stderr } = await execAsync(command, { timeout: 10000 });
      
      await unlink(tempFile).catch(() => {});
      
      return NextResponse.json({ 
        status: 'success',
        action: 'code_executed',
        output: stdout,
        error: stderr,
        worker: 'code-worker'
      });
    }
    
    return NextResponse.json({ status: 'error', message: 'No task or code provided' }, { status: 400 });
    
  } catch (error: any) {
    console.error('[Code Worker] Error:', error);
    return NextResponse.json({ 
      status: 'error', 
      message: error.message,
      worker: 'code-worker'
    }, { status: 500 });
  }
}
'@
Set-Content -Path $codeWorkerPath -Value $codeWorkerContent -Encoding UTF8

# --- 4. App Worker (The Controller) ---
Write-Host "🐝 Deploying App Worker..." -ForegroundColor Yellow
 $appWorkerPath = "src\app\api\workers\app\route.ts"
 $appWorkerContent = @'
import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function POST(request: NextRequest) {
  const { action, app, windowTitle } = await request.json();
  
  try {
    switch(action) {
      case 'launch':
        // Windows specific launch command
        await execAsync(`start ${app}`);
        return NextResponse.json({ status: 'success', action: 'launched', app });
        
      case 'close':
        await execAsync(`taskkill /IM ${app}.exe /F`);
        return NextResponse.json({ status: 'success', action: 'closed', app });
        
      case 'list':
        const { stdout } = await execAsync('tasklist');
        // Parse the output for better JSON format if needed
        return NextResponse.json({ status: 'success', action: 'listed', processes: stdout });
        
      default:
        return NextResponse.json({ status: 'error', message: 'Unknown action' }, { status: 400 });
    }
  } catch (error: any) {
    return NextResponse.json({ status: 'error', message: error.message }, { status: 500 });
  }
}
'@
Set-Content -Path $appWorkerPath -Value $appWorkerContent -Encoding UTF8

# --- 5. File Worker (The Librarian) ---
Write-Host "🐝 Deploying File Worker..." -ForegroundColor Yellow
 $fileWorkerPath = "src\app\api\workers\file\route.ts"
 $fileWorkerContent = @'
import { NextRequest, NextResponse } from 'next/server';
import { readFile, writeFile, readdir, mkdir, stat } from 'fs/promises';
import { join } from 'path';

const WORKSPACE = join(process.cwd(), 'src/temp_workspace');

export async function POST(request: NextRequest) {
  const { action, path, content } = await request.json();
  // Sanitize path to prevent traversal attacks
  const safePath = path ? path.replace(/\.\./g, '') : '';
  const fullPath = join(WORKSPACE, safePath);
  
  try {
    switch(action) {
      case 'read':
        const data = await readFile(fullPath, 'utf-8');
        return NextResponse.json({ status: 'success', content: data });
        
      case 'write':
        await mkdir(join(fullPath, '..'), { recursive: true });
        await writeFile(fullPath, content);
        return NextResponse.json({ status: 'success', action: 'wrote', path: safePath });
        
      case 'list':
        const files = await readdir(fullPath || WORKSPACE);
        return NextResponse.json({ status: 'success', files });
        
      default:
        return NextResponse.json({ status: 'error', message: 'Unknown action' }, { status: 400 });
    }
  } catch (error: any) {
    return NextResponse.json({ status: 'error', message: error.message }, { status: 500 });
  }
}
'@
Set-Content -Path $fileWorkerPath -Value $fileWorkerContent -Encoding UTF8

# --- 6. Queen Kernel (The Orchestrator) ---
Write-Host "👑 Upgrading Queen Kernel..." -ForegroundColor Yellow
 $kernelPath = "src\app\api\kernel\route.ts"
# Note: This assumes an existing file or creates a new one. 
# For safety in this demo, we create a standalone orchestrator function.
 $kernelContent = @'
import { NextRequest, NextResponse } from 'next/server';

// Worker Registry
const workers = {
  code: 'http://localhost:3000/api/workers/code',
  app: 'http://localhost:3000/api/workers/app',
  file: 'http://localhost:3000/api/workers/file'
};

async function callOllama(prompt: string) {
  const response = await fetch('http://localhost:11434/api/generate', {
    method: 'POST',
    body: JSON.stringify({
      model: 'llama3', // Queen's brain
      prompt: prompt,
      stream: false
    })
  });
  const data = await response.json();
  return data.response;
}

async function queenDecide(task: string) {
  const prompt = `
Task: "${task}"

Which worker should handle this?
- code: for programming, scripts, algorithms
- app: for launching/closing applications
- file: for reading/writing files

Return JSON: { "worker": "code|app|file", "reason": "why" }
  `;
  const decisionText = await callOllama(prompt);
  try {
    // Extract JSON from potential markdown/text wrapper
    const jsonMatch = decisionText.match(/\{[\s\S]*\}/);
    return jsonMatch ? JSON.parse(jsonMatch[0]) : { worker: 'code', reason: 'default' };
  } catch {
    return { worker: 'code', reason: 'parse error' };
  }
}

export async function POST(request: NextRequest) {
  const { task } = await request.json();
  
  // 1. Decide
  const decision = await queenDecide(task);
  const workerUrl = workers[decision.worker as keyof typeof workers];
  
  if (!workerUrl) {
    return NextResponse.json({ error: 'Invalid worker selection' }, { status: 400 });
  }

  // 2. Delegate
  const workerResponse = await fetch(workerUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ task })
  });
  const result = await workerResponse.json();

  // 3. Reflect (Optional: Save this pattern to a database/memory)
  const reflection = `Delegated ${task} to ${decision.worker}. Success: ${result.status}`;
  
  return NextResponse.json({
    queenDecision: decision,
    workerResult: result,
    reflection: reflection
  });
}
'@
Set-Content -Path $kernelPath -Value $kernelContent -Encoding UTF8

Write-Host "✅ Rez Hive Architecture Deployed Successfully!" -ForegroundColor Green
Write-Host "Run 'npm run dev' to start the Queen and her Workers." -ForegroundColor Cyan