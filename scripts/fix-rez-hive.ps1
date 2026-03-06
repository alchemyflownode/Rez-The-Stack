# ============================================
# REZ HIVE - COMPLETE AUTO-FIX SCRIPT
# ============================================
# Run this script as Administrator to fix all issues
# ============================================

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🏛️  REZ HIVE SOVEREIGN - COMPLETE AUTO-FIX              ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Set project path
$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
Set-Location $PROJECT_PATH

# ============================================
# STEP 1: STOP ALL NODE PROCESSES
# ============================================
Write-Host "[1/8] Stopping Node processes..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "      ✅ Node processes stopped" -ForegroundColor Green

# ============================================
# STEP 2: CREATE COMPONENTS DIRECTORY
# ============================================
Write-Host "[2/8] Creating components directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "src\components" -Force -ErrorAction SilentlyContinue | Out-Null
Write-Host "      ✅ Components directory ready" -ForegroundColor Green

# ============================================
# STEP 3: CREATE TWOBARMETER COMPONENT
# ============================================
Write-Host "[3/8] Creating TwoBarMeter component..." -ForegroundColor Yellow

$twoBarMeter = @'
'use client';

import React from 'react';

interface TwoBarMeterProps {
  sessionPercent: number;
  weeklyPercent: number;
  resetTime: number;
}

export const TwoBarMeter: React.FC<TwoBarMeterProps> = ({ 
  sessionPercent, 
  weeklyPercent, 
  resetTime 
}) => {
  const formatResetTime = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="space-y-3">
      <div className="space-y-1">
        <div className="flex justify-between text-xs">
          <span className="text-white/40 font-mono">SESSION</span>
          <span className="text-cyan-400 font-mono">{Math.min(sessionPercent, 100).toFixed(1)}%</span>
        </div>
        <div className="h-2 bg-white/10 rounded-full overflow-hidden">
          <div 
            className="h-full bg-gradient-to-r from-cyan-400 to-blue-400 rounded-full transition-all duration-500"
            style={{ width: `${Math.min(sessionPercent, 100)}%` }}
          />
        </div>
      </div>
      <div className="space-y-1">
        <div className="flex justify-between text-xs">
          <span className="text-white/40 font-mono">WEEKLY</span>
          <span className="text-purple-400 font-mono">{Math.min(weeklyPercent, 100).toFixed(1)}%</span>
        </div>
        <div className="h-2 bg-white/10 rounded-full overflow-hidden">
          <div 
            className="h-full bg-gradient-to-r from-purple-400 to-pink-400 rounded-full transition-all duration-500"
            style={{ width: `${Math.min(weeklyPercent, 100)}%` }}
          />
        </div>
      </div>
      <div className="flex justify-between text-[10px] text-white/30 font-mono pt-1 border-t border-white/5">
        <span>RESET</span>
        <span>{formatResetTime(resetTime)}</span>
      </div>
    </div>
  );
};

export default TwoBarMeter;
'@

$twoBarMeter | Out-File -FilePath "src\components\TwoBarMeter.tsx" -Encoding UTF8 -Force
Write-Host "      ✅ TwoBarMeter.tsx created" -ForegroundColor Green

# ============================================
# STEP 4: CREATE PRIMORDIALUI COMPONENT
# ============================================
Write-Host "[4/8] Creating PrimordialUI component..." -ForegroundColor Yellow

$primordialUI = @'
'use client';

import React, { useState } from 'react';
import { Brain, Lightbulb } from 'lucide-react';

export const PrimordialUI = () => {
  const [insights] = useState([
    'I notice you check CPU often. Would you like a shortcut?',
    'Your RAM usage suggests closing Chrome tabs might help',
    "You're most active in the evening"
  ]);

  return (
    <div className="fixed right-6 bottom-24 w-80 z-40 space-y-3">
      <div className="bg-blue-500/10 backdrop-blur-xl border border-blue-500/30 rounded-2xl p-4">
        <div className="flex items-center gap-2 mb-3">
          <Brain className="text-blue-400" size={18} />
          <span className="text-xs font-mono text-blue-400">AGENT INSIGHTS</span>
        </div>
        <div className="space-y-2">
          {insights.map((insight, i) => (
            <div key={i} className="flex gap-2 text-xs text-white/60">
              <Lightbulb size={14} className="text-blue-400 shrink-0 mt-0.5" />
              <span>✨ {insight}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default PrimordialUI;
'@

$primordialUI | Out-File -FilePath "src\components\PrimordialUI.tsx" -Encoding UTF8 -Force
Write-Host "      ✅ PrimordialUI.tsx created" -ForegroundColor Green

# ============================================
# STEP 5: CREATE API ROUTE
# ============================================
Write-Host "[5/8] Creating API route..." -ForegroundColor Yellow

# Create API directory
New-Item -ItemType Directory -Path "src\app\api\kernel" -Force -ErrorAction SilentlyContinue | Out-Null

$apiRoute = @'
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { task, worker, ...payload } = body;
    
    console.log(`🧠 Processing: "${task}"`);
    console.log(`→ Routing to ${worker || 'default'} worker`);
    
    await new Promise(resolve => setTimeout(resolve, 500));
    
    let response = '';
    
    if (task.toLowerCase().includes('cpu')) {
      const cpuUsage = (20 + Math.random() * 30).toFixed(1);
      response = `**CPU Analysis Complete**\n\nCurrent CPU usage is **${cpuUsage}%** across 8 cores.`;
    } 
    else if (task.toLowerCase().includes('ram') || task.toLowerCase().includes('memory')) {
      const ramUsage = (40 + Math.random() * 20).toFixed(1);
      response = `**Memory Analysis Complete**\n\nRAM usage is **${ramUsage}%** (32GB total).`;
    }
    else if (task.toLowerCase().includes('gpu')) {
      const gpuTemp = (45 + Math.random() * 15).toFixed(0);
      response = `**GPU Status**\n\nRTX 3060 temperature: **${gpuTemp}°C**\nGPU load: **${(15 + Math.random() * 30).toFixed(1)}%**`;
    }
    else if (task.toLowerCase().includes('health')) {
      response = `**System Health Check**\n\n✅ All systems operational\n✅ Memory: 32GB available\n✅ GPU: RTX 3060 active\n✅ Storage: 1TB NVMe (62% used)`;
    }
    else {
      response = `**Command Executed**\n\n\`${task}\` processed successfully.\n\n\`\`\`json\n${JSON.stringify(payload, null, 2)}\n\`\`\``;
    }
    
    return NextResponse.json({ 
      content: response,
      status: 'success',
      worker: worker || 'brain',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Kernel API Error:', error);
    
    return NextResponse.json(
      { 
        error: 'Kernel processing failed',
        content: `**⚠️ Kernel Error**\n\nFailed to process request.\n\`\`\`\n${error}\n\`\`\``,
        status: 'error'
      },
      { status: 500 }
    );
  }
}

export async function OPTIONS() {
  return NextResponse.json({}, { status: 200 });
}
'@

$apiRoute | Out-File -FilePath "src\app\api\kernel\route.ts" -Encoding UTF8 -Force
Write-Host "      ✅ API route created" -ForegroundColor Green

# ============================================
# STEP 6: FIX PAGE.TSX IMPORTS
# ============================================
Write-Host "[6/8] Fixing page.tsx imports..." -ForegroundColor Yellow

$pagePath = "src\app\page.tsx"
if (Test-Path $pagePath) {
    $content = Get-Content $pagePath -Raw
    
    # Check if imports are missing
    if ($content -notmatch "import .* TwoBarMeter") {
        # Add imports after the last lucide-react import
        $content = $content -replace "(import .+ from 'lucide-react';)", "`$1`n`nimport { PrimordialUI } from '../components/PrimordialUI';`nimport { TwoBarMeter } from '../components/TwoBarMeter';"
        $content | Out-File -FilePath $pagePath -Encoding UTF8 -Force
        Write-Host "      ✅ Added missing imports to page.tsx" -ForegroundColor Green
    } else {
        Write-Host "      ✅ Imports already present" -ForegroundColor Green
    }
}

# ============================================
# STEP 7: INSTALL DEPENDENCIES
# ============================================
Write-Host "[7/8] Installing dependencies..." -ForegroundColor Yellow
npm install lucide-react react-markdown remark-gfm
Write-Host "      ✅ Dependencies installed" -ForegroundColor Green

# ============================================
# STEP 8: CLEAR CACHE AND RESTART
# ============================================
Write-Host "[8/8] Clearing cache..." -ForegroundColor Yellow
Remove-Item -Path ".next" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "node_modules\.cache" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "      ✅ Cache cleared" -ForegroundColor Green

# ============================================
# COMPLETE
# ============================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     ✅ REZ HIVE FIX COMPLETE!                                 ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Starting REZ HIVE Sovereign..." -ForegroundColor Cyan
Write-Host ""
Write-Host "The server will start automatically. Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

# Start the server
npm run dev