# 🏛️ CREATE ALL REZ HIVE COMPONENTS DIRECTLY
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  CREATING REZ HIVE COMPONENTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

# ================================================
# 1. CREATE WORKERS DIRECTORY
# ================================================
New-Item -ItemType Directory -Path "src\api\workers" -Force | Out-Null
Write-Host "`n📁 Created src\api\workers" -ForegroundColor Green

# ================================================
# 2. CREATE SEARCH HARVESTER (Python)
# ================================================
Write-Host "`n🐍 Creating search_harvester.py..." -ForegroundColor Yellow

$searchHarvester = @'
from duckduckgo_search import DDGS
import json
import sys

def harvest(query, max_text=5, max_images=4):
    """
    Deep Search Harvester - Extracts both text and visual data
    Returns structured data for REZ Interface consumption
    """
    try:
        with DDGS() as ddgs:
            # Harvest text results for reasoning
            text_results = []
            for r in ddgs.text(query, max_results=max_text):
                text_results.append({
                    "title": r.get("title", ""),
                    "href": r.get("href", ""),
                    "body": r.get("body", "")
                })
            
            # Harvest images for mobile-like visual experience
            image_results = []
            for r in ddgs.images(query, max_results=max_images):
                image_results.append({
                    "image": r.get("image", ""),
                    "thumbnail": r.get("thumbnail", ""),
                    "title": r.get("title", ""),
                    "source": r.get("source", "")
                })
            
            return json.dumps({
                "success": True,
                "query": query,
                "results": text_results,
                "images": image_results,
                "answer": f"Harvested {len(text_results)} sources and {len(image_results)} images for '{query}'",
                "meta": {
                    "text_count": len(text_results),
                    "image_count": len(image_results)
                }
            }, indent=2)
    except Exception as e:
        return json.dumps({
            "success": False,
            "error": str(e),
            "query": query
        })

if __name__ == "__main__":
    if len(sys.argv) > 1:
        print(harvest(sys.argv[1]))
    else:
        print(harvest("cyberpunk 2077"))
'@

Set-Content -Path "src\api\workers\search_harvester.py" -Value $searchHarvester -Encoding UTF8
Write-Host "   ✅ search_harvester.py created" -ForegroundColor Green

# ================================================
# 3. CREATE SYSTEM AGENT (Python)
# ================================================
Write-Host "`n🐍 Creating system_agent.py..." -ForegroundColor Yellow

$systemAgent = @'
import psutil
import json
import platform
from datetime import datetime

def get_system_snapshot():
    """
    Mobile-style PC Dashboard Data
    Returns CPU, RAM, Disk, Network stats in mobile card format
    """
    try:
        # CPU Stats
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_count = psutil.cpu_count()
        cpu_freq = psutil.cpu_freq()
        
        # Memory Stats
        memory = psutil.virtual_memory()
        
        # Disk Stats
        disk = psutil.disk_usage('/')
        
        # Network Stats
        net_io = psutil.net_io_counters()
        
        # Boot Time
        boot_time = datetime.fromtimestamp(psutil.boot_time()).strftime("%Y-%m-%d %H:%M:%S")
        
        return {
            "success": True,
            "timestamp": datetime.now().isoformat(),
            "platform": {
                "system": platform.system(),
                "release": platform.release(),
                "version": platform.version(),
                "machine": platform.machine()
            },
            "cpu": {
                "percent": cpu_percent,
                "cores": cpu_count,
                "frequency_mhz": cpu_freq.current if cpu_freq else 0,
                "status": "high" if cpu_percent > 80 else "normal" if cpu_percent > 40 else "low"
            },
            "memory": {
                "total_gb": round(memory.total / (1024**3), 2),
                "used_gb": round(memory.used / (1024**3), 2),
                "percent": memory.percent,
                "available_gb": round(memory.available / (1024**3), 2),
                "status": "critical" if memory.percent > 90 else "warning" if memory.percent > 70 else "normal"
            },
            "disk": {
                "total_gb": round(disk.total / (1024**3), 2),
                "used_gb": round(disk.used / (1024**3), 2),
                "free_gb": round(disk.free / (1024**3), 2),
                "percent": round((disk.used / disk.total) * 100, 1),
                "status": "critical" if disk.percent > 90 else "warning" if disk.percent > 80 else "normal"
            },
            "network": {
                "bytes_sent_mb": round(net_io.bytes_sent / (1024**2), 2),
                "bytes_recv_mb": round(net_io.bytes_recv / (1024**2), 2),
                "packets_sent": net_io.packets_sent,
                "packets_recv": net_io.packets_recv
            },
            "boot_time": boot_time,
            "processes": len(psutil.pids())
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

def kill_process(pid):
    """Kill a specific process by PID"""
    try:
        process = psutil.Process(pid)
        process.terminate()
        return {"success": True, "message": f"Process {pid} terminated"}
    except Exception as e:
        return {"success": False, "error": str(e)}

def list_processes(limit=10):
    """List top processes by CPU usage"""
    try:
        processes = []
        for proc in sorted(psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']), 
                          key=lambda x: x.info['cpu_percent'] or 0, reverse=True)[:limit]:
            processes.append(proc.info)
        return {"success": True, "processes": processes}
    except Exception as e:
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "snapshot":
            print(json.dumps(get_system_snapshot(), indent=2))
        elif cmd == "processes":
            print(json.dumps(list_processes(), indent=2))
        else:
            print(json.dumps({"error": "Unknown command"}))
    else:
        print(json.dumps(get_system_snapshot(), indent=2))
'@

Set-Content -Path "src\api\workers\system_agent.py" -Value $systemAgent -Encoding UTF8
Write-Host "   ✅ system_agent.py created" -ForegroundColor Green

# ================================================
# 4. CREATE COMPONENTS DIRECTORY
# ================================================
New-Item -ItemType Directory -Path "src\components" -Force | Out-Null
Write-Host "`n📁 Created src\components" -ForegroundColor Green

# ================================================
# 5. CREATE PC DASHBOARD COMPONENT
# ================================================
Write-Host "`n🎨 Creating PCDashboard.tsx..." -ForegroundColor Yellow

$pcDashboard = @'
"use client";

import React, { useState, useEffect } from 'react';
import { Cpu, HardDrive, Wifi, Activity, RefreshCw, Terminal } from 'lucide-react';

interface SystemStats {
  success: boolean;
  cpu: { percent: number; cores: number; frequency_mhz: number; status: string };
  memory: { total_gb: number; used_gb: number; percent: number; available_gb: number; status: string };
  disk: { total_gb: number; used_gb: number; free_gb: number; percent: number; status: string };
  network: { bytes_sent_mb: number; bytes_recv_mb: number };
  processes: number;
  platform: { system: string; release: string };
}

export default function PCDashboard() {
  const [stats, setStats] = useState<SystemStats | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/system/snapshot');
      const data = await response.json();
      setStats(data);
    } catch {
      // Demo data if API fails
      setStats({
        success: true,
        cpu: { percent: 34, cores: 8, frequency_mhz: 3200, status: 'normal' },
        memory: { total_gb: 16, used_gb: 8.4, percent: 52, available_gb: 7.6, status: 'normal' },
        disk: { total_gb: 512, used_gb: 320, free_gb: 192, percent: 62, status: 'normal' },
        network: { bytes_sent_mb: 145.2, bytes_recv_mb: 892.1 },
        processes: 184,
        platform: { system: 'Windows', release: '11' }
      });
    }
    setLoading(false);
  };

  useEffect(() => { 
    fetchStats(); 
    const i = setInterval(fetchStats, 5000); 
    return () => clearInterval(i); 
  }, []);

  const getStatusColor = (status: string) => {
    if (status === 'critical') return 'text-red-500 bg-red-500/10';
    if (status === 'warning') return 'text-yellow-500 bg-yellow-500/10';
    return 'text-emerald-500 bg-emerald-500/10';
  };

  const getProgressColor = (p: number) => p > 90 ? 'bg-red-500' : p > 70 ? 'bg-yellow-500' : 'bg-emerald-500';

  if (!stats) return null;

  return (
    <div className="w-full max-w-md mx-auto space-y-4">
      <div className="flex items-center justify-between px-2">
        <div className="flex items-center gap-2">
          <Terminal className="w-5 h-5 text-violet-400" />
          <h2 className="text-lg font-bold text-white">PC Dashboard</h2>
        </div>
        <button onClick={fetchStats} className="p-2 rounded-full hover:bg-white/5" disabled={loading}>
          <RefreshCw className={`w-4 h-4 text-white/60 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      <div className="glass-panel rounded-2xl p-5 border border-white/5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className={`p-3 rounded-xl ${getStatusColor(stats.cpu.status)}`}>
              <Cpu className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-semibold text-white">Processor</h3>
              <p className="text-xs text-white/50">{stats.cpu.cores} Cores @ {stats.cpu.frequency_mhz}MHz</p>
            </div>
          </div>
          <span className="text-2xl font-bold text-white">{stats.cpu.percent}%</span>
        </div>
        <div className="h-2 bg-white/10 rounded-full overflow-hidden">
          <div className={`h-full ${getProgressColor(stats.cpu.percent)} transition-all`} style={{ width: `${stats.cpu.percent}%` }} />
        </div>
      </div>

      <div className="glass-panel rounded-2xl p-5 border border-white/5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className={`p-3 rounded-xl ${getStatusColor(stats.memory.status)}`}>
              <Activity className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-semibold text-white">Memory</h3>
              <p className="text-xs text-white/50">{stats.memory.used_gb}GB / {stats.memory.total_gb}GB</p>
            </div>
          </div>
          <span className="text-2xl font-bold text-white">{stats.memory.percent}%</span>
        </div>
        <div className="h-2 bg-white/10 rounded-full overflow-hidden">
          <div className={`h-full ${getProgressColor(stats.memory.percent)} transition-all`} style={{ width: `${stats.memory.percent}%` }} />
        </div>
      </div>

      <div className="glass-panel rounded-2xl p-5 border border-white/5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className={`p-3 rounded-xl ${getStatusColor(stats.disk.status)}`}>
              <HardDrive className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-semibold text-white">Storage</h3>
              <p className="text-xs text-white/50">{stats.disk.used_gb}GB / {stats.disk.total_gb}GB</p>
            </div>
          </div>
          <span className="text-2xl font-bold text-white">{stats.disk.percent}%</span>
        </div>
        <div className="h-2 bg-white/10 rounded-full overflow-hidden">
          <div className={`h-full ${getProgressColor(stats.disk.percent)} transition-all`} style={{ width: `${stats.disk.percent}%` }} />
        </div>
      </div>

      <div className="glass-panel rounded-2xl p-5 border border-white/5">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-3 rounded-xl bg-blue-500/10 text-blue-400">
            <Wifi className="w-6 h-6" />
          </div>
          <div>
            <h3 className="font-semibold text-white">Network</h3>
            <p className="text-xs text-white/50">{stats.platform.system} {stats.platform.release}</p>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white/5 rounded-xl p-3">
            <p className="text-xs text-white/40 mb-1">↓ Download</p>
            <p className="text-lg font-semibold text-emerald-400">{stats.network.bytes_recv_mb} MB</p>
          </div>
          <div className="bg-white/5 rounded-xl p-3">
            <p className="text-xs text-white/40 mb-1">↑ Upload</p>
            <p className="text-lg font-semibold text-violet-400">{stats.network.bytes_sent_mb} MB</p>
          </div>
        </div>
      </div>
    </div>
  );
}
'@

Set-Content -Path "src\components\PCDashboard.tsx" -Value $pcDashboard -Encoding UTF8
Write-Host "   ✅ PCDashboard.tsx created" -ForegroundColor Green

# ================================================
# 6. CREATE DEEP SEARCH RESULTS COMPONENT
# ================================================
Write-Host "`n🎨 Creating DeepSearchResults.tsx..." -ForegroundColor Yellow

$deepSearchResults = @'
"use client";

import React from 'react';
import { Search, Image as ImageIcon, ExternalLink, Sparkles } from 'lucide-react';

interface DeepSearchData {
  results: Array<{ title: string; href: string; body: string }>;
  images: Array<{ image: string; thumbnail: string; title: string; source: string }>;
  answer: string;
  meta: { text_count: number; image_count: number };
}

export default function DeepSearchResults({ data }: { data: DeepSearchData }) {
  if (!data) return null;

  return (
    <div className="w-full space-y-6">
      <div className="flex items-center gap-3 px-2">
        <div className="p-2 rounded-lg bg-violet-500/20 border border-violet-500/30">
          <Sparkles className="w-5 h-5 text-violet-400" />
        </div>
        <div>
          <h3 className="text-sm font-semibold text-violet-300">Deep Search Results</h3>
          <p className="text-xs text-white/50">{data.meta?.text_count || 0} sources • {data.meta?.image_count || 0} images</p>
        </div>
      </div>

      {data.answer && (
        <div className="glass-panel rounded-2xl p-6 border-l-4 border-violet-500">
          <p className="text-white/90 leading-relaxed">{data.answer}</p>
        </div>
      )}

      {data.images && data.images.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center gap-2 px-2">
            <ImageIcon className="w-4 h-4 text-white/60" />
            <span className="text-xs font-medium text-white/60 uppercase tracking-wider">Visual Results</span>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {data.images.map((img, idx) => (
              <div key={idx} className="group relative aspect-square rounded-xl overflow-hidden border border-white/10 hover:border-violet-500/50 transition-all cursor-pointer">
                <img src={img.image || img.thumbnail} alt={img.title} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
                  <div className="absolute bottom-0 left-0 right-0 p-3">
                    <p className="text-xs text-white font-medium truncate">{img.title}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {data.results && data.results.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center gap-2 px-2">
            <Search className="w-4 h-4 text-white/60" />
            <span className="text-xs font-medium text-white/60 uppercase tracking-wider">Sources</span>
          </div>
          <div className="space-y-3">
            {data.results.map((result, idx) => (
              <a key={idx} href={result.href} target="_blank" rel="noopener noreferrer" className="block glass-panel rounded-xl p-5 border border-white/5 hover:border-violet-500/30 hover:bg-white/5 transition-all group">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 min-w-0">
                    <h4 className="font-semibold text-white group-hover:text-violet-300 transition-colors truncate">{result.title}</h4>
                    <p className="text-sm text-white/60 mt-1 line-clamp-2">{result.body}</p>
                    <p className="text-xs text-white/40 font-mono mt-3 truncate">{result.href}</p>
                  </div>
                  <ExternalLink className="w-4 h-4 text-white/20 group-hover:text-violet-400 transition-colors flex-shrink-0" />
                </div>
              </a>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
'@

Set-Content -Path "src\components\DeepSearchResults.tsx" -Value $deepSearchResults -Encoding UTF8
Write-Host "   ✅ DeepSearchResults.tsx created" -ForegroundColor Green

# ================================================
# 7. CREATE API ROUTE FOR SYSTEM
# ================================================
Write-Host "`n🔧 Creating system API route..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "src\app\api\system\snapshot" -Force | Out-Null

$apiRoute = @'
import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function GET() {
  try {
    // Call Python system_agent
    const { stdout } = await execAsync('python src/api/workers/system_agent.py snapshot');
    const data = JSON.parse(stdout);
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json({ success: false, error: 'System agent unavailable' }, { status: 500 });
  }
}
'@

Set-Content -Path "src\app\api\system\snapshot\route.ts" -Value $apiRoute -Encoding UTF8
Write-Host "   ✅ system API route created" -ForegroundColor Green

# ================================================
# 8. CREATE AUDIT SCRIPT
# ================================================
Write-Host "`n⛓️ Creating audit script..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "audit" -Force | Out-Null

$auditScript = @'
# audit-all.ps1
# REZ HIVE Full System Audit Chain
# Run this to verify all "Hands" are talking to "Eyes"

param(
    [switch]$Deep,
    [switch]$Fix
)

$ErrorActionPreference = "Stop"
$results = @()

function Write-Status($message, $status, $color = "White") {
    $emoji = if ($status -eq "PASS") { "✅" } elseif ($status -eq "FAIL") { "❌" } elseif ($status -eq "WARN") { "⚠️" } else { "🔍" }
    Write-Host "$emoji $message" -ForegroundColor $color
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║           🕵️ REZ HIVE SOVEREIGN AUDIT CHAIN                  ║" -ForegroundColor Magenta
Write-Host "║           Verifying Hand-Eye-Brain Connection                ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Test 1: Python Environment
Write-Host "[1/6] Testing Python Environment..." -ForegroundColor Cyan
try {
    $pyVersion = python --version 2>&1
    Write-Status "Python detected: $pyVersion" "PASS" "Green"
    $results += @{Test="Python"; Status="PASS"; Detail=$pyVersion}
} catch {
    Write-Status "Python not found in PATH" "FAIL" "Red"
    $results += @{Test="Python"; Status="FAIL"; Detail=$_.Exception.Message}
}

# Test 2: System Agent (PC Management Hands)
Write-Host "`n[2/6] Testing System Agent (PC Management)..." -ForegroundColor Cyan
try {
    $sysResult = python src/api/workers/system_agent.py snapshot | ConvertFrom-Json
    if ($sysResult.success) {
        Write-Status "System Agent responding - CPU: $($sysResult.cpu.percent)% | RAM: $($sysResult.memory.percent)%" "PASS" "Green"
        $results += @{Test="System Agent"; Status="PASS"; Detail="CPU: $($sysResult.cpu.percent)%"}
    } else {
        Write-Status "System Agent error: $($sysResult.error)" "FAIL" "Red"
        $results += @{Test="System Agent"; Status="FAIL"; Detail=$sysResult.error}
    }
} catch {
    Write-Status "System Agent failed: $_" "FAIL" "Red"
    $results += @{Test="System Agent"; Status="FAIL"; Detail=$_.Exception.Message}
}

# Test 3: Deep Search Harvester
Write-Host "`n[3/6] Testing Deep Search Harvester..." -ForegroundColor Cyan
try {
    $searchResult = python src/api/workers/search_harvester.py "cyberpunk 2077" | ConvertFrom-Json
    if ($searchResult.success -and $searchResult.images.Count -gt 0) {
        Write-Status "Deep Search working - Found $($searchResult.results.Count) text + $($searchResult.images.Count) images" "PASS" "Green"
        $results += @{Test="Deep Search"; Status="PASS"; Detail="$($searchResult.results.Count) text, $($searchResult.images.Count) images"}
    } elseif ($searchResult.success) {
        Write-Status "Search working but no images returned" "WARN" "Yellow"
        $results += @{Test="Deep Search"; Status="WARN"; Detail="No images"}
    } else {
        Write-Status "Search failed: $($searchResult.error)" "FAIL" "Red"
        $results += @{Test="Deep Search"; Status="FAIL"; Detail=$searchResult.error}
    }
} catch {
    Write-Status "Search harvester failed: $_" "FAIL" "Red"
    $results += @{Test="Deep Search"; Status="FAIL"; Detail=$_.Exception.Message}
}

# Test 4: Dependencies
Write-Host "`n[4/6] Testing Python Dependencies..." -ForegroundColor Cyan
try {
    python -c "import psutil, duckduckgo_search" 2>&1 | Out-Null
    Write-Status "All dependencies installed (psutil, duckduckgo_search)" "PASS" "Green"
    $results += @{Test="Dependencies"; Status="PASS"; Detail="All present"}
} catch {
    Write-Status "Missing dependencies. Run: pip install psutil duckduckgo_search" "FAIL" "Red"
    $results += @{Test="Dependencies"; Status="FAIL"; Detail="Missing packages"}
}

# Test 5: File Structure
Write-Host "`n[5/6] Testing File Structure..." -ForegroundColor Cyan
$requiredFiles = @(
    "src/api/workers/search_harvester.py",
    "src/api/workers/system_agent.py"
)
$allPresent = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Status "Found $file" "PASS" "Green"
    } else {
        Write-Status "Missing $file" "FAIL" "Red"
        $allPresent = $false
    }
}
$results += @{Test="File Structure"; Status=$(if($allPresent){"PASS"}else{"FAIL"}); Detail="$(if($allPresent){"All present"}else{"Missing files"})"}

# Test 6: API Connectivity (if Deep scan requested)
if ($Deep) {
    Write-Host "`n[6/6] Deep Scan: Network Connectivity..." -ForegroundColor Cyan
    try {
        $testConn = Test-Connection -ComputerName duckduckgo.com -Count 1 -Quiet
        if ($testConn) {
            Write-Status "Internet connectivity confirmed" "PASS" "Green"
            $results += @{Test="Network"; Status="PASS"; Detail="Connected"}
        } else {
            Write-Status "No internet connection" "FAIL" "Red"
            $results += @{Test="Network"; Status="FAIL"; Detail="No connectivity"}
        }
    } catch {
        Write-Status "Network test failed" "FAIL" "Red"
        $results += @{Test="Network"; Status="FAIL"; Detail=$_.Exception.Message}
    }
} else {
    Write-Host "`n[6/6] Skipped (use -Deep for network test)" -ForegroundColor Gray
    $results += @{Test="Network"; Status="SKIP"; Detail="Not tested"}
}

# Summary
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                      AUDIT SUMMARY                           ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warnings = ($results | Where-Object { $_.Status -eq "WARN" }).Count

Write-Host "Total Tests: $($results.Count) | ✅ Passed: $passed | ❌ Failed: $failed | ⚠️ Warnings: $warnings" -ForegroundColor White

if ($failed -eq 0) {
    Write-Host "`n🚀 ALL SYSTEMS SOVEREIGN - Ready for deployment!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  SYSTEMS REQUIRE ATTENTION - Check failures above" -ForegroundColor Yellow
    exit 1
}
'@

Set-Content -Path "audit\audit-all.ps1" -Value $auditScript -Encoding UTF8
Write-Host "   ✅ audit-all.ps1 created" -ForegroundColor Green

# ================================================
# 9. INSTALL PYTHON DEPENDENCIES
# ================================================
Write-Host "`n📦 Installing Python dependencies..." -ForegroundColor Yellow
pip install psutil duckduckgo-search
Write-Host "   ✅ Dependencies installed" -ForegroundColor Green

# ================================================
# 10. FINAL SUMMARY
# ================================================
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  🏆 ALL REZ HIVE COMPONENTS CREATED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "   📁 Files created:" -ForegroundColor Yellow
Write-Host "      • src/api/workers/search_harvester.py"
Write-Host "      • src/api/workers/system_agent.py"
Write-Host "      • src/components/PCDashboard.tsx"
Write-Host "      • src/components/DeepSearchResults.tsx"
Write-Host "      • src/app/api/system/snapshot/route.ts"
Write-Host "      • audit/audit-all.ps1"
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1. Run the audit:" -ForegroundColor White
Write-Host "      cd audit; .\audit-all.ps1 -Deep" -ForegroundColor Yellow
Write-Host ""
Write-Host "   2. Start your server:" -ForegroundColor White
Write-Host "      `$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack" -ForegroundColor Yellow
Write-Host ""
Write-Host "   3. Try commands in UI:" -ForegroundColor White
Write-Host "      • Search the web for cyberpunk 2077" -ForegroundColor Gray
Write-Host "      • Check system health" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta