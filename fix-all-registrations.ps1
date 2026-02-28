# 🏛️ REZ HIVE - FIX ALL REGISTRATIONS
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  FIXING ALL WORKER REGISTRATIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

# 1. Update Router
Write-Host "`n🔧 Updating Router..." -ForegroundColor Yellow
$routerPath = "src\lib\okiru-engine.ts"
$completeRouter = @'
export async function runOKIRULoop(task: string) {
  const t = task.toLowerCase();
  let worker = 'mcp';
  
  if (t.includes('new rule') || t.includes('from now on')) worker = 'mutation';
  else if (t.includes('deep search') || t.includes('research')) worker = 'deepsearch';
  else if (t.includes('search') || t.includes('web')) worker = 'mcp';
  else if (t.includes('look') || t.includes('see') || t.includes('screenshot')) worker = 'vision';
  else if (t.includes('listen') || t.includes('hear') || t.includes('audio')) worker = 'voice';
  else if (t.includes('launch') || t.includes('open')) worker = 'app';
  else if (t.includes('file') || t.includes('list') || t.includes('read')) worker = 'file';
  else if (t.includes('write code') || t.includes('python')) worker = 'code';
  else if (t.includes('director') || t.includes('scene')) worker = 'director';
  else if (t.includes('working-storage')) worker = 'sce';
  else if (t.includes('generate image') || t.includes('draw')) worker = 'canvas';
  else if (t.includes('rezstack') || t.includes('stack')) worker = 'rezstack';

  console.log(`[ROUTER] ${task} -> ${worker}`);
  return { worker, intent: task };
}
'@
Set-Content -Path $routerPath -Value $completeRouter -Encoding UTF8
Write-Host "   ✅ Router updated" -ForegroundColor Green

# 2. Update Kernel Registry
Write-Host "`n👑 Updating Kernel Registry..." -ForegroundColor Yellow
$kernelPath = "src\app\api\kernel\route.ts"
$kernelContent = Get-Content $kernelPath -Raw
$allWorkers = @'
const workers = {
  code: 'http://localhost:3001/api/workers/code',
  app: 'http://localhost:3001/api/workers/app',
  file: 'http://localhost:3001/api/workers/file',
  rezstack: 'http://localhost:3001/api/workers/rezstack',
  mcp: 'http://localhost:3001/api/workers/mcp',
  vision: 'http://localhost:3001/api/workers/vision',
  mutation: 'http://localhost:3001/api/workers/mutation',
  director: 'http://localhost:3001/api/workers/director',
  sce: 'http://localhost:3001/api/workers/sce',
  voice: 'http://localhost:3001/api/workers/voice',
  canvas: 'http://localhost:3001/api/workers/canvas',
};
'@
$newContent = $kernelContent -replace 'const workers\s*=\s*\{[^}]*\};?', $allWorkers
Set-Content -Path $kernelPath -Value $newContent -Encoding UTF8
Write-Host "   ✅ Kernel registry updated" -ForegroundColor Green

# 3. Fix UI Imports
Write-Host "`n🎨 Fixing UI Imports..." -ForegroundColor Yellow
$uiPath = "src\app\page.tsx"
$uiContent = Get-Content $uiPath -Raw
$fixedImport = @'
import { 
  Brain, Send, Loader2, Terminal, Cpu, Wifi, CheckCircle, 
  Image as ImageIcon, X, Search, Code, Zap, Sparkles 
} from 'lucide-react';
'@
$uiContent = $uiContent -replace 'import \{.*?\} from .lucide-react.;', $fixedImport
Set-Content -Path $uiPath -Value $uiContent -Encoding UTF8
Write-Host "   ✅ UI imports fixed" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  ✅ ALL FIXES APPLIED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "   📋 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Kill existing server (Ctrl+C)"
Write-Host "   2. Restart: `$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack"
Write-Host "   3. Run scan again: .\scan-api.ps1"
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta