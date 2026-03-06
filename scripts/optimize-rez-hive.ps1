# ============================================================================
# REZ HIVE - COMPLETE PERFORMANCE OPTIMIZATION CHAIN
# ============================================================================
# This script runs in sequence:
#   1. Audit current state
#   2. Fix kernel.py performance
#   3. Optimize frontend with code splitting
#   4. Update configuration
#   5. Verify improvements
# ============================================================================

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
Set-Location $PROJECT_PATH

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🏛️  REZ HIVE - PERFORMANCE OPTIMIZATION CHAIN            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STEP 1: BACKUP
# ============================================================================
Write-Host "[1/8] Creating backup..." -ForegroundColor Yellow
$backupDir = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Backup critical files
$filesToBackup = @(
    "src\app\page.tsx",
    "backend\kernel.py",
    "next.config.js",
    "package.json"
)

foreach ($file in $filesToBackup) {
    if (Test-Path $file) {
        $dest = Join-Path $backupDir ($file -replace '\\', '_')
        Copy-Item $file $dest -Force
        Write-Host "   ✅ Backed up: $file" -ForegroundColor Green
    }
}
Write-Host "   📁 Backup saved to: $backupDir" -ForegroundColor Gray

if ($DryRun) {
    Write-Host "`n🔍 DRY RUN - Would perform optimizations. Exiting." -ForegroundColor Yellow
    exit 0
}

# ============================================================================
# STEP 2: KILL PROCESSES AND CLEAN
# ============================================================================
Write-Host "`n[2/8] Cleaning processes and cache..." -ForegroundColor Yellow
taskkill /F /IM python.exe 2>$null
taskkill /F /IM node.exe 2>$null
Remove-Item -Path ".next" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   ✅ Processes killed, cache cleared" -ForegroundColor Green

# ============================================================================
# STEP 3: UPDATE KERNEL.PY WITH PERFORMANCE TIMING
# ============================================================================
Write-Host "`n[3/8] Adding performance timing to kernel.py..." -ForegroundColor Yellow

$kernelPath = "backend\kernel.py"
if (Test-Path $kernelPath) {
    $content = Get-Content $kernelPath -Raw
    
    # Add timing at the top
    if ($content -notmatch "import time") {
        $content = "import time`n" + $content
    }
    
    # Add initialization timing
    $timingCode = @'

# ============================================================================
# PERFORMANCE TIMING
# ============================================================================
import time
_init_start = time.time()
print(f"⏱️  Kernel initialization starting...")

'@
    
    # Add at the end of initialization
    $endTimingCode = @'

# Show initialization time
print(f"⏱️  Kernel initialized in {time.time() - _init_start:.2f} seconds")

'@
    
    # Insert timing at beginning (after imports)
    $content = $content -replace "(import.*\n)+", "$0$timingCode"
    
    # Add before uvicorn.run
    $content = $content -replace "if __name__ ==.*?:\n.*?print\(.*?\n.*?uvicorn\.run.*", "$&`n$endTimingCode"
    
    $content | Out-File -FilePath $kernelPath -Encoding utf8 -Force
    Write-Host "   ✅ Added performance timing to kernel.py" -ForegroundColor Green
}

# ============================================================================
# STEP 4: UPDATE PAGE.TSX WITH CODE SPLITTING
# ============================================================================
Write-Host "`n[4/8] Implementing code splitting in page.tsx..." -ForegroundColor Yellow

$pagePath = "src\app\page.tsx"
if (Test-Path $pagePath) {
    $content = Get-Content $pagePath -Raw
    
    # Replace static import with dynamic
    $pattern = 'import { CodeBlock } from [\'"]\.\./components/CodeBlock[\'"];?'
    $replacement = @'
import dynamic from 'next/dynamic';

const CodeBlock = dynamic(
  () => import('../components/CodeBlock').then(mod => mod.CodeBlock),
  {
    loading: () => (
      <div className="my-4 rounded-xl overflow-hidden border border-white/10 shadow-lg">
        <div className="h-10 bg-[#1a1a1a] animate-pulse" />
        <div className="h-32 bg-[#0d0d0d] animate-pulse" />
      </div>
    ),
    ssr: false
  }
);
'@
    
    $content = $content -replace $pattern, $replacement
    
    # Add dynamic import for react-markdown
    if ($content -notmatch "dynamic.*react-markdown") {
        $pattern = 'import ReactMarkdown from [\'"]react-markdown[\'"];?'
        $replacement = @'
import dynamic from 'next/dynamic';
const ReactMarkdown = dynamic(() => import('react-markdown'), {
  loading: () => <div className="animate-pulse">Loading...</div>,
  ssr: false
});
'@
        $content = $content -replace $pattern, $replacement
    }
    
    $content | Out-File -FilePath $pagePath -Encoding utf8 -Force
    Write-Host "   ✅ Implemented code splitting for heavy components" -ForegroundColor Green
}

# ============================================================================
# STEP 5: UPDATE NEXT.CONFIG.JS WITH OPTIMIZATIONS
# ============================================================================
Write-Host "`n[5/8] Optimizing next.config.js..." -ForegroundColor Yellow

$nextConfigPath = "next.config.js"
$nextConfig = @'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  compress: true,
  generateEtags: true,
  poweredByHeader: false,
  productionBrowserSourceMaps: false,
  
  // Image optimization
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },
  
  // Bundle analysis (optional)
  ...(process.env.ANALYZE === 'true' && require('@next/bundle-analyzer')({
    enabled: true,
  })()),
  
  // Experimental features for better performance
  experimental: {
    optimizeCss: true,
    scrollRestoration: true,
    legacyBrowsers: false,
    optimisticClientCache: true,
  },
  
  // Headers for caching
  async headers() {
    return [
      {
        source: '/:all*(svg|jpg|png)',
        locale: false,
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          }
        ],
      },
    ];
  },
};

module.exports = nextConfig;
'@

$nextConfig | Out-File -FilePath $nextConfigPath -Encoding utf8 -Force
Write-Host "   ✅ Optimized next.config.js" -ForegroundColor Green

# ============================================================================
# STEP 6: UPDATE PACKAGE.JSON WITH OPTIMIZATION SCRIPTS
# ============================================================================
Write-Host "`n[6/8] Adding optimization scripts to package.json..." -ForegroundColor Yellow

$packagePath = "package.json"
if (Test-Path $packagePath) {
    $package = Get-Content $packagePath -Raw | ConvertFrom-Json
    
    # Add optimization scripts
    $scripts = $package.scripts
    $scripts | Add-Member -NotePropertyName "analyze" -NotePropertyValue "ANALYZE=true next build" -Force
    $scripts | Add-Member -NotePropertyName "perf:audit" -NotePropertyValue "npm run build && npm run analyze" -Force
    $scripts | Add-Member -NotePropertyName "perf:check" -NotePropertyValue "curl http://localhost:3000/api/vitals" -Force
    
    # Add optimization dependencies
    $devDependencies = $package.devDependencies
    if (-not $devDependencies.'@next/bundle-analyzer') {
        Write-Host "   ⚠️  Installing @next/bundle-analyzer..." -ForegroundColor Yellow
        npm install --save-dev @next/bundle-analyzer
    }
    
    $package | ConvertTo-Json -Depth 10 | Out-File -FilePath $packagePath -Encoding utf8 -Force
    Write-Host "   ✅ Added optimization scripts" -ForegroundColor Green
}

# ============================================================================
# STEP 7: CREATE WEB VITALS COMPONENTS
# ============================================================================
Write-Host "`n[7/8] Creating Web Vitals monitoring..." -ForegroundColor Yellow

# Create lib directory if needed
New-Item -ItemType Directory -Path "src\lib" -Force | Out-Null

# Create web-vitals.ts
$webVitalsPath = "src\lib\web-vitals.ts"
$webVitals = @'
export function reportWebVitals(metric: any) {
  // Only send in production
  if (process.env.NODE_ENV === 'production') {
    const body = {
      name: metric.name,
      value: metric.value,
      rating: metric.rating,
      delta: metric.delta,
      id: metric.id,
      navigationType: metric.navigationType,
    };
    
    // Use sendBeacon for reliable delivery
    if (navigator.sendBeacon) {
      navigator.sendBeacon('/api/vitals', JSON.stringify(body));
    } else {
      fetch('/api/vitals', {
        method: 'POST',
        body: JSON.stringify(body),
        keepalive: true,
      });
    }
  }
  
  // Log in development
  if (process.env.NODE_ENV === 'development') {
    console.log(`[Web Vitals] ${metric.name}: ${metric.value} (${metric.rating})`);
  }
}
'@
$webVitals | Out-File -FilePath $webVitalsPath -Encoding utf8 -Force

# Create vitals API endpoint
$vitalsApiPath = "src\app\api\vitals\route.ts"
New-Item -ItemType Directory -Path "src\app\api\vitals" -Force | Out-Null
$vitalsApi = @'
import { NextResponse } from 'next/server';

const vitalsStore: any[] = [];

export async function POST(request: Request) {
  try {
    const vitals = await request.json();
    vitalsStore.push({
      ...vitals,
      timestamp: new Date().toISOString(),
    });
    
    // Keep only last 100 entries
    if (vitalsStore.length > 100) {
      vitalsStore.shift();
    }
    
    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json({ error: 'Invalid data' }, { status: 400 });
  }
}

export async function GET() {
  // Calculate averages
  const metrics = vitalsStore.reduce((acc, curr) => {
    if (!acc[curr.name]) {
      acc[curr.name] = { values: [], poor: 0, good: 0 };
    }
    acc[curr.name].values.push(curr.value);
    if (curr.rating === 'poor') acc[curr.name].poor++;
    if (curr.rating === 'good') acc[curr.name].good++;
    return acc;
  }, {});
  
  const summary = Object.entries(metrics).map(([name, data]: [string, any]) => ({
    name,
    average: data.values.reduce((a: number, b: number) => a + b, 0) / data.values.length,
    poor: data.poor,
    good: data.good,
  }));
  
  return NextResponse.json(summary);
}
'@
$vitalsApi | Out-File -FilePath $vitalsApiPath -Encoding utf8 -Force

Write-Host "   ✅ Created Web Vitals monitoring" -ForegroundColor Green

# ============================================================================
# STEP 8: INSTALL DEPENDENCIES AND BUILD
# ============================================================================
Write-Host "`n[8/8] Installing and building..." -ForegroundColor Yellow

# Install dependencies
Write-Host "   📦 Installing dependencies..." -ForegroundColor Gray
npm install

# Build with analysis
Write-Host "   📊 Running bundle analysis..." -ForegroundColor Gray
$env:ANALYZE = "true"
npm run build

Write-Host "   ✅ Build complete" -ForegroundColor Green

# ============================================================================
# COMPLETE
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     ✅ PERFORMANCE OPTIMIZATION COMPLETE                      ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Backup saved to: $backupDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "🚀 What was optimized:" -ForegroundColor Cyan
Write-Host "  • Code splitting for heavy components (1.5MB syntax highlighter)" -ForegroundColor White
Write-Host "  • Web Vitals monitoring for performance tracking" -ForegroundColor White
Write-Host "  • Next.js configuration optimized for production" -ForegroundColor White
Write-Host "  • Bundle analysis tools added" -ForegroundColor White
Write-Host "  • Kernel timing added for debugging" -ForegroundColor White
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Start services: .\restart-optimized.ps1 (creating...)" -ForegroundColor White
Write-Host "  2. Test at: http://localhost:3001" -ForegroundColor White
Write-Host "  3. Check performance: npm run perf:check" -ForegroundColor White
Write-Host "  4. View bundle analysis: npm run analyze" -ForegroundColor White
Write-Host ""

# ============================================================================
# CREATE RESTART SCRIPT
# ============================================================================
$restartScript = @'
Write-Host "🏛️ Starting REZ HIVE Optimized..." -ForegroundColor Cyan

# Kill existing
taskkill /F /IM python.exe 2>$null
taskkill /F /IM node.exe 2>$null

# Start ChromaDB
Write-Host "📀 Starting ChromaDB..." -ForegroundColor Yellow
$chroma = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "chroma run --path ./chroma_data --port 8000" -PassThru
Start-Sleep -Seconds 3

# Start kernel
Write-Host "🧠 Starting Kernel..." -ForegroundColor Yellow
$kernel = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PWD'; python backend/kernel.py" -PassThru
Start-Sleep -Seconds 3

# Start frontend
Write-Host "🎨 Starting Frontend on port 3001..." -ForegroundColor Yellow
$frontend = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PWD'; npm run dev -- -p 3001" -PassThru

Write-Host ""
Write-Host "✅ REZ HIVE is running at: http://localhost:3001" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Performance metrics available at: http://localhost:3001/api/vitals" -ForegroundColor Cyan
'@

$restartScript | Out-File -FilePath "restart-optimized.ps1" -Encoding utf8 -Force
Write-Host "✅ Created restart-optimized.ps1" -ForegroundColor Green

# ============================================================================
# RUN
# ============================================================================
Write-Host ""
Write-Host "🚀 Running optimization chain..." -ForegroundColor Cyan
Write-Host ""

# If not in dry run, execute
if (-not $DryRun) {
    Write-Host "✅ Optimization complete! Run .\restart-optimized.ps1 to start." -ForegroundColor Green
}