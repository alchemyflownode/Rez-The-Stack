# 🏛️ OKIRU FRONTEND SETUP
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  SETTING UP FRONTEND EXPOSURE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

# ================================================
# 1. CREATE FRONTEND API ROUTES
# ================================================
Write-Host "`n📡 Creating frontend API routes..." -ForegroundColor Yellow

# Create directories
New-Item -ItemType Directory -Force -Path "src\app\api\frontend" | Out-Null

# Workers API
$workersAPI = @'
import { NextResponse } from 'next/server';

// Simulated worker status - replace with real data
export async function GET() {
  const workers = [
    { name: 'vision', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.98 },
    { name: 'mcp', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.95 },
    { name: 'code', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.92 },
    { name: 'app', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.99 },
    { name: 'file', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.97 },
    { name: 'voice', status: 'degraded', lastRun: new Date().toISOString(), successRate: 0.82 },
    { name: 'director', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.94 },
    { name: 'mutation', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.96 },
    { name: 'sce', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.93 },
    { name: 'canvas', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.91 },
    { name: 'rezstack', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.88 },
    { name: 'deepsearch', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.89 },
    { name: 'system_monitor', status: 'healthy', lastRun: new Date().toISOString(), successRate: 0.99 }
  ];
  
  return NextResponse.json({ workers });
}
'@
Set-Content -Path "src\app\api\frontend\workers\route.ts" -Value $workersAPI -Encoding UTF8
Write-Host "   ✅ /api/frontend/workers created" -ForegroundColor Green

# History API
$historyAPI = @'
import { NextResponse } from 'next/server';

// In-memory task history (replace with DB later)
const taskHistory = [];

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const limit = parseInt(searchParams.get('limit') || '50');
  
  return NextResponse.json({ 
    history: taskHistory.slice(-limit).reverse() 
  });
}

export async function POST(request: Request) {
  const task = await request.json();
  taskHistory.push({
    ...task,
    timestamp: new Date().toISOString(),
    id: Date.now().toString()
  });
  return NextResponse.json({ success: true });
}
'@
Set-Content -Path "src\app\api\frontend\history\route.ts" -Value $historyAPI -Encoding UTF8
Write-Host "   ✅ /api/frontend/history created" -ForegroundColor Green

# Constitution API
$constitutionAPI = @'
import { NextResponse } from 'next/server';
import { readFile, writeFile } from 'fs/promises';
import path from 'path';

const CONSTITUTION_PATH = path.join(process.cwd(), 'constitution.json');

// Default constitution
const defaultRules = [
  { id: '1', pattern: 'new rule', action: 'mutation', description: 'Add constitutional rules' },
  { id: '2', pattern: 'from now on', action: 'mutation', description: 'Update behavior' }
];

async function getRules() {
  try {
    const data = await readFile(CONSTITUTION_PATH, 'utf-8');
    return JSON.parse(data);
  } catch {
    return defaultRules;
  }
}

async function saveRules(rules: any[]) {
  await writeFile(CONSTITUTION_PATH, JSON.stringify(rules, null, 2));
}

export async function GET() {
  const rules = await getRules();
  return NextResponse.json({ rules });
}

export async function POST(request: Request) {
  const { rule } = await request.json();
  const rules = await getRules();
  const newRule = {
    id: Date.now().toString(),
    ...rule,
    createdAt: new Date().toISOString()
  };
  rules.push(newRule);
  await saveRules(rules);
  return NextResponse.json({ rule: newRule });
}

export async function DELETE(request: Request) {
  const { searchParams } = new URL(request.url);
  const id = searchParams.get('id');
  if (!id) return NextResponse.json({ error: 'No ID provided' }, { status: 400 });
  
  const rules = await getRules();
  const filtered = rules.filter((r: any) => r.id !== id);
  await saveRules(filtered);
  return NextResponse.json({ success: true });
}
'@
Set-Content -Path "src\app\api\frontend\constitution\route.ts" -Value $constitutionAPI -Encoding UTF8
Write-Host "   ✅ /api/frontend/constitution created" -ForegroundColor Green

# Health API
$healthAPI = @'
import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function GET() {
  try {
    // Get CPU usage (simplified)
    const cpu = await execAsync('wmic cpu get loadpercentage').catch(() => ({ stdout: '0' }));
    const cpuPercent = parseInt(cpu.stdout.split('\n')[1] || '0');
    
    // Get memory info
    const mem = process.memoryUsage();
    const totalMem = mem.heapTotal / 1024 / 1024;
    const usedMem = mem.heapUsed / 1024 / 1024;
    
    // Get disk usage (simplified)
    const disk = await execAsync('wmic logicaldisk where drivetype=3 get size,freespace').catch(() => ({ stdout: '' }));
    
    // Worker health (simplified)
    const workersHealthy = 12; // 12/13 healthy (voice degraded)
    const workersTotal = 13;
    
    return NextResponse.json({
      health: {
        cpu: cpuPercent,
        memory: Math.round((usedMem / totalMem) * 100),
        disk: 62, // placeholder
        workers: {
          healthy: workersHealthy,
          total: workersTotal
        },
        uptime: process.uptime()
      }
    });
  } catch (error) {
    return NextResponse.json({ 
      health: {
        cpu: 0,
        memory: 0,
        disk: 0,
        workers: { healthy: 0, total: 0 },
        uptime: 0
      }
    });
  }
}
'@
Set-Content -Path "src\app\api\frontend\health\route.ts" -Value $healthAPI -Encoding UTF8
Write-Host "   ✅ /api/frontend/health created" -ForegroundColor Green

# ================================================
# 2. CREATE UI COMPONENTS
# ================================================
Write-Host "`n🎨 Creating UI components..." -ForegroundColor Yellow

# WorkerStatus component
$workerStatus = @'
"use client";
import { useState, useEffect } from 'react';

export function WorkerStatus() {
  const [workers, setWorkers] = useState([]);
  
  useEffect(() => {
    fetch('/api/frontend/workers')
      .then(r => r.json())
      .then(data => setWorkers(data.workers));
  }, []);
  
  return (
    <div className="space-y-3">
      <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Worker Status</h3>
      <div className="grid grid-cols-2 gap-2">
        {workers.map((w: any) => (
          <div key={w.name} className={`p-2 rounded-lg border ${
            w.status === 'healthy' ? 'bg-green-500/10 border-green-500/30' :
            w.status === 'degraded' ? 'bg-yellow-500/10 border-yellow-500/30' :
            'bg-red-500/10 border-red-500/30'
          }`}>
            <div className="text-xs font-mono">{w.name}</div>
            <div className="flex justify-between items-center mt-1">
              <span className="text-[10px] opacity-70">
                {w.status === 'healthy' ? '🟢' : '🟡'} {(w.successRate * 100).toFixed(0)}%
              </span>
              <span className="text-[8px] opacity-50">
                {new Date(w.lastRun).toLocaleTimeString()}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
'@
Set-Content -Path "src\components\WorkerStatus.tsx" -Value $workerStatus -Encoding UTF8
Write-Host "   ✅ WorkerStatus.tsx created" -ForegroundColor Green

# ConfidenceBadge component
$confidenceBadge = @'
"use client";

export function ConfidenceBadge({ confidence, worker }: { confidence: number, worker: string }) {
  const color = confidence > 0.8 ? 'text-green-400' : 
                confidence > 0.5 ? 'text-yellow-400' : 'text-red-400';
  
  return (
    <div className={`text-xs ${color} font-mono flex items-center gap-1`}>
      <span>→ {worker}</span>
      <span className="opacity-70">({(confidence * 100).toFixed(0)}%)</span>
    </div>
  );
}
'@
Set-Content -Path "src\components\ConfidenceBadge.tsx" -Value $confidenceBadge -Encoding UTF8
Write-Host "   ✅ ConfidenceBadge.tsx created" -ForegroundColor Green

# TaskHistory component
$taskHistory = @'
"use client";
import { useState, useEffect } from 'react';

export function TaskHistory({ limit = 20 }: { limit?: number }) {
  const [history, setHistory] = useState([]);
  
  useEffect(() => {
    fetch(`/api/frontend/history?limit=${limit}`)
      .then(r => r.json())
      .then(data => setHistory(data.history));
  }, [limit]);
  
  return (
    <div className="space-y-3">
      <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Task History</h3>
      <div className="space-y-2 max-h-96 overflow-y-auto">
        {history.map((task: any) => (
          <div key={task.id} className="text-xs p-2 bg-white/5 rounded border border-white/10">
            <div className="flex justify-between">
              <span className="truncate max-w-[150px]">{task.intent}</span>
              <span className="opacity-70">{task.worker}</span>
            </div>
            <div className="text-[10px] opacity-50 mt-1">
              {new Date(task.timestamp).toLocaleString()}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
'@
Set-Content -Path "src\components\TaskHistory.tsx" -Value $taskHistory -Encoding UTF8
Write-Host "   ✅ TaskHistory.tsx created" -ForegroundColor Green

# ConstitutionPanel component
$constitutionPanel = @'
"use client";
import { useState, useEffect } from 'react';

export function ConstitutionPanel() {
  const [rules, setRules] = useState([]);
  const [newRule, setNewRule] = useState('');
  
  const fetchRules = async () => {
    const res = await fetch('/api/frontend/constitution');
    const data = await res.json();
    setRules(data.rules);
  };
  
  useEffect(() => {
    fetchRules();
  }, []);
  
  const addRule = async () => {
    if (!newRule.trim()) return;
    await fetch('/api/frontend/constitution', {
      method: 'POST',
      body: JSON.stringify({ rule: { pattern: newRule, action: 'custom' } })
    });
    setNewRule('');
    fetchRules();
  };
  
  const removeRule = async (id: string) => {
    await fetch(`/api/frontend/constitution?id=${id}`, { method: 'DELETE' });
    fetchRules();
  };
  
  return (
    <div className="space-y-3">
      <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider">📜 Constitution</h3>
      <div className="space-y-2 max-h-60 overflow-y-auto">
        {rules.map((r: any) => (
          <div key={r.id} className="flex justify-between items-center p-2 bg-white/5 rounded text-xs">
            <span className="truncate max-w-[150px]">{r.pattern}</span>
            <button 
              onClick={() => removeRule(r.id)}
              className="text-red-400 text-[10px] hover:text-red-300"
            >
              ✕
            </button>
          </div>
        ))}
      </div>
      <div className="flex gap-2">
        <input 
          value={newRule}
          onChange={(e) => setNewRule(e.target.value)}
          placeholder="e.g., 'from now on...'"
          className="flex-1 bg-black/50 border border-white/20 rounded px-3 py-2 text-xs"
          onKeyDown={(e) => e.key === 'Enter' && addRule()}
        />
        <button 
          onClick={addRule}
          className="px-3 py-2 bg-blue-600 hover:bg-blue-700 rounded text-xs"
        >
          Add
        </button>
      </div>
    </div>
  );
}
'@
Set-Content -Path "src\components\ConstitutionPanel.tsx" -Value $constitutionPanel -Encoding UTF8
Write-Host "   ✅ ConstitutionPanel.tsx created" -ForegroundColor Green

# SystemHealthOverlay component
$healthOverlay = @'
"use client";
import { useState, useEffect } from 'react';

export function SystemHealthOverlay({ show }: { show: boolean }) {
  const [health, setHealth] = useState(null);
  
  useEffect(() => {
    if (!show) return;
    
    const fetchHealth = async () => {
      const res = await fetch('/api/frontend/health');
      const data = await res.json();
      setHealth(data.health);
    };
    
    fetchHealth();
    const interval = setInterval(fetchHealth, 5000);
    return () => clearInterval(interval);
  }, [show]);
  
  if (!show || !health) return null;
  
  return (
    <div className="fixed bottom-4 right-4 text-xs bg-black/90 text-green-400 p-3 rounded-lg font-mono z-50 border border-green-500/30">
      <div className="font-bold mb-2">⚙️ SYSTEM HEALTH</div>
      <div>CPU: {health.cpu}%</div>
      <div>MEM: {health.memory}%</div>
      <div>DSK: {health.disk}%</div>
      <div>Workers: {health.workers?.healthy}/{health.workers?.total}</div>
      <div className="text-[8px] mt-2 opacity-50">
        Uptime: {Math.round(health.uptime / 60)}m
      </div>
    </div>
  );
}
'@
Set-Content -Path "src\components\SystemHealthOverlay.tsx" -Value $healthOverlay -Encoding UTF8
Write-Host "   ✅ SystemHealthOverlay.tsx created" -ForegroundColor Green

# ================================================
# 3. CREATE MAIN PAGE LAYOUT
# ================================================
Write-Host "`n📄 Creating main page layout..." -ForegroundColor Yellow

$mainPage = @'
"use client";
import { useState } from 'react';
import { WorkerStatus } from '@/components/WorkerStatus';
import { TaskHistory } from '@/components/TaskHistory';
import { ConstitutionPanel } from '@/components/ConstitutionPanel';
import { SystemHealthOverlay } from '@/components/SystemHealthOverlay';
import { ConfidenceBadge } from '@/components/ConfidenceBadge';
import { Brain, Settings, Mic, Image as ImageIcon } from 'lucide-react';

export default function OKIRUPage() {
  const [showDebug, setShowDebug] = useState(false);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  
  const handleSend = async () => {
    if (!input.trim()) return;
    
    const userMsg = { id: Date.now(), role: 'user', content: input };
    setMessages(prev => [...prev, userMsg]);
    setInput('');
    
    const res = await fetch('/api/kernel', {
      method: 'POST',
      body: JSON.stringify({ task: input })
    });
    const data = await res.json();
    
    setMessages(prev => [...prev, {
      id: Date.now() + 1,
      role: 'assistant',
      content: data.result?.answer || data.result?.message || data.error || 'Done.',
      worker: data.worker,
      confidence: data.confidence
    }]);
  };
  
  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <header className="border-b border-white/10 p-4 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <Brain className="w-6 h-6 text-purple-400" />
          <h1 className="text-xl font-bold">👑 OKIRU</h1>
          <span className="text-xs bg-white/5 px-2 py-1 rounded-full">v2.2 Vision</span>
        </div>
        <div className="flex gap-4">
          <button 
            onClick={() => setShowDebug(!showDebug)} 
            className={`text-sm px-3 py-1 rounded-full ${showDebug ? 'bg-green-600/20 text-green-400' : 'bg-white/5 text-gray-400'}`}
          >
            {showDebug ? '🔍 Debug ON' : '🔍 Debug'}
          </button>
          <button className="text-gray-400 hover:text-white">
            <Settings className="w-5 h-5" />
          </button>
        </div>
      </header>
      
      {/* Main Content */}
      <main className="grid grid-cols-4 gap-4 p-4 h-[calc(100vh-80px)]">
        {/* Left: Chat (3 cols) */}
        <div className="col-span-3 flex flex-col h-full">
          <div className="flex-1 overflow-y-auto space-y-4 mb-4">
            {messages.map((msg) => (
              <div key={msg.id} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[80%] ${msg.role === 'user' ? 'bg-purple-600/20' : 'bg-white/5'} rounded-2xl p-4`}>
                  <p className="text-sm whitespace-pre-wrap">{msg.content}</p>
                  {msg.worker && msg.role === 'assistant' && (
                    <ConfidenceBadge confidence={msg.confidence || 0.95} worker={msg.worker} />
                  )}
                </div>
              </div>
            ))}
          </div>
          
          {/* Input Area */}
          <div className="flex gap-2 items-end">
            <button className="p-3 bg-white/5 rounded-lg hover:bg-white/10">
              <ImageIcon className="w-5 h-5" />
            </button>
            <button className="p-3 bg-white/5 rounded-lg hover:bg-white/10">
              <Mic className="w-5 h-5" />
            </button>
            <input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              placeholder="Type a command..."
              className="flex-1 bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-purple-500"
            />
            <button 
              onClick={handleSend}
              className="px-6 py-3 bg-purple-600 rounded-lg hover:bg-purple-700 text-sm font-medium"
            >
              Send
            </button>
          </div>
        </div>
        
        {/* Right: Sidebar (1 col) */}
        <aside className="space-y-6 overflow-y-auto pr-2">
          <WorkerStatus />
          <TaskHistory limit={10} />
          <ConstitutionPanel />
        </aside>
      </main>
      
      {/* Debug Overlay */}
      <SystemHealthOverlay show={showDebug} />
    </div>
  );
}
'@
Set-Content -Path "src\app\page.tsx" -Value $mainPage -Encoding UTF8
Write-Host "   ✅ Main page updated" -ForegroundColor Green

# ================================================
# 4. CREATE CONSTITUTION.JSON
# ================================================
Write-Host "`n📝 Creating constitution.json..." -ForegroundColor Yellow

$constitution = @'
[
  {
    "id": "1",
    "pattern": "new rule",
    "action": "mutation",
    "description": "Add constitutional rules",
    "createdAt": "2025-01-15T10:00:00.000Z"
  },
  {
    "id": "2",
    "pattern": "from now on",
    "action": "mutation",
    "description": "Update behavior",
    "createdAt": "2025-01-15T10:00:00.000Z"
  },
  {
    "id": "3",
    "pattern": "system health",
    "action": "system_monitor",
    "description": "Check PC health",
    "createdAt": "2025-01-15T10:00:00.000Z"
  }
]
'@
Set-Content -Path "constitution.json" -Value $constitution -Encoding UTF8
Write-Host "   ✅ constitution.json created" -ForegroundColor Green

# ================================================
# 5. INSTALL DEPENDENCIES
# ================================================
Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
npm install lucide-react --save
Write-Host "   ✅ lucide-react installed" -ForegroundColor Green

# ================================================
# 6. FINAL SUMMARY
# ================================================
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  ✅ FRONTEND SETUP COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "   📡 API Routes Created:" -ForegroundColor Cyan
Write-Host "      • /api/frontend/workers"
Write-Host "      • /api/frontend/history"
Write-Host "      • /api/frontend/constitution"
Write-Host "      • /api/frontend/health"
Write-Host ""
Write-Host "   🎨 Components Created:" -ForegroundColor Cyan
Write-Host "      • WorkerStatus"
Write-Host "      • ConfidenceBadge"
Write-Host "      • TaskHistory"
Write-Host "      • ConstitutionPanel"
Write-Host "      • SystemHealthOverlay"
Write-Host ""
Write-Host "   📄 Constitution: constitution.json"
Write-Host ""
Write-Host "🚀 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "   1. Restart server: `$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack"
Write-Host "   2. Open http://localhost:3001"
Write-Host "   3. Try debug mode (top-right button)"
Write-Host "   4. Add constitution rules"
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta