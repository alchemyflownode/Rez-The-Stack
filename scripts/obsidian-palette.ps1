# ================================================================
# 🦊 SOVEREIGN OS - OBSIDIAN PALETTE + UI/UX GOODNESS
# ================================================================
# Deep blacks • Vibrant cyan • Pulse indicators • Split panes
# ================================================================

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     🦊 SOVEREIGN OS - OBSIDIAN PALETTE                    ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

$srcPath = "G:\okiru\app builder\Cognitive Kernel\src"
$stylesPath = "$srcPath\styles"

# ================================================================
# 1. OBSIDIAN CSS VARIABLES
# ================================================================
Write-Host "[1/6] Creating Obsidian palette CSS..." -ForegroundColor Yellow

$obsidianCSS = @'
/* ================================================================
   SOVEREIGN OS - OBSIDIAN PALETTE
   Deep blacks • Vibrant cyan • Pulse indicators
   ================================================================ */

:root {
  /* ===== OBSIDIAN DEEP - True dark mode ===== */
  --obsidian-root: #030405;
  --obsidian-surface: #0B0C0E;
  --obsidian-panel: #0F1113;
  --obsidian-elevated: #151719;
  
  /* ===== SOVEREIGN CYAN - Primary action ===== */
  --cyan-primary: #2DD4BF;
  --cyan-hover: #5EEAD4;
  --cyan-soft: rgba(45, 212, 191, 0.15);
  --cyan-glow: 0 0 20px rgba(45, 212, 191, 0.3);
  
  /* ===== CYBER GREEN - Success states ===== */
  --green-success: #22C55E;
  --green-soft: rgba(34, 197, 94, 0.1);
  --green-glow: 0 0 15px rgba(34, 197, 94, 0.3);
  
  /* ===== BORDERS & TEXT ===== */
  --border-subtle: #1E293B;
  --border-soft: #334155;
  --border-medium: #475569;
  
  --text-primary: #F8FAFC;
  --text-secondary: #CBD5E1;
  --text-muted: #94A3B8;
  --text-tertiary: #64748B;
  
  /* ===== PANEL SIZES ===== */
  --sidebar-width: 72px;
  --panel-radius: 8px;
  --card-radius: 6px;
}

/* ===== BASE STYLES ===== */
body {
  background-color: var(--obsidian-root);
  color: var(--text-primary);
  font-family: 'Inter', system-ui, sans-serif;
}

/* ===== PANELS & SURFACES ===== */
.panel-obsidian {
  background: var(--obsidian-panel);
  border: 1px solid var(--border-subtle);
  border-radius: var(--panel-radius);
}

.panel-surface {
  background: var(--obsidian-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--panel-radius);
}

.panel-elevated {
  background: var(--obsidian-elevated);
  border: 1px solid var(--border-soft);
  border-radius: var(--panel-radius);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.4);
}

/* ===== CYAN ACCENTS ===== */
.cyan-text { color: var(--cyan-primary); }
.cyan-border { border-color: var(--cyan-primary); }
.cyan-bg { background: var(--cyan-primary); }
.cyan-glow { box-shadow: var(--cyan-glow); }

/* ===== PULSE INDICATOR ===== */
.pulse-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--cyan-primary);
  box-shadow: var(--cyan-glow);
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.6; transform: scale(1.2); }
}

/* ===== STATUS INDICATORS ===== */
.status-online {
  color: var(--green-success);
  display: flex;
  align-items: center;
  gap: 4px;
}

.status-online::before {
  content: '';
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--green-success);
  box-shadow: var(--green-glow);
  animation: pulse 2s ease-in-out infinite;
}

/* ===== WORKER GRID ===== */
.worker-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(64px, 1fr));
  gap: 4px;
}

.worker-item {
  background: var(--obsidian-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--card-radius);
  padding: 8px 4px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.worker-item:hover {
  border-color: var(--cyan-primary);
  background: var(--cyan-soft);
}

.worker-item.active {
  border-color: var(--cyan-primary);
  background: var(--cyan-soft);
  box-shadow: var(--cyan-glow);
}

.worker-icon {
  width: 20px;
  height: 20px;
  margin: 0 auto 4px;
  color: var(--text-muted);
}

.worker-item.active .worker-icon {
  color: var(--cyan-primary);
}

.worker-name {
  font-size: 9px;
  color: var(--text-tertiary);
}

/* ===== SIDEBAR ===== */
.sidebar-obsidian {
  width: var(--sidebar-width);
  background: var(--obsidian-panel);
  border-right: 1px solid var(--border-subtle);
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 12px 0;
}

.sidebar-icon {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  color: var(--text-muted);
  margin: 4px 0;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
}

.sidebar-icon:hover {
  background: var(--cyan-soft);
  color: var(--cyan-primary);
}

.sidebar-icon.active {
  background: var(--cyan-soft);
  color: var(--cyan-primary);
}

.sidebar-icon.active::after {
  content: '';
  position: absolute;
  left: 0;
  top: 25%;
  height: 50%;
  width: 2px;
  background: var(--cyan-primary);
  box-shadow: var(--cyan-glow);
}

/* ===== SPLITTERS ===== */
[data-panel-resize-handle] {
  background: transparent;
  transition: background 0.2s ease, box-shadow 0.2s ease;
}

[data-panel-resize-handle]:hover {
  background: var(--cyan-primary);
  box-shadow: var(--cyan-glow);
}

[data-panel-group-direction="horizontal"] > [data-panel-resize-handle] {
  width: 2px;
}

[data-panel-group-direction="vertical"] > [data-panel-resize-handle] {
  height: 2px;
}

/* ===== SCROLLBARS ===== */
::-webkit-scrollbar {
  width: 4px;
  height: 4px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: var(--border-subtle);
  border-radius: 2px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--cyan-primary);
}
'@

Set-Content -Path "$stylesPath\obsidian-palette.css" -Value $obsidianCSS -Encoding UTF8
Write-Host "   ✅ Created Obsidian palette CSS" -ForegroundColor Green

# ================================================================
# 2. TAILWIND CONFIGURATION
# ================================================================
Write-Host "[2/6] Creating Tailwind config with Obsidian palette..." -ForegroundColor Yellow

$tailwindConfig = @'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        obsidian: {
          root: '#030405',
          surface: '#0B0C0E',
          panel: '#0F1113',
          elevated: '#151719',
        },
        cyan: {
          primary: '#2DD4BF',
          hover: '#5EEAD4',
          soft: 'rgba(45, 212, 191, 0.15)',
        },
        green: {
          success: '#22C55E',
          soft: 'rgba(34, 197, 94, 0.1)',
        },
        border: {
          subtle: '#1E293B',
          soft: '#334155',
          medium: '#475569',
        },
        text: {
          primary: '#F8FAFC',
          secondary: '#CBD5E1',
          muted: '#94A3B8',
          tertiary: '#64748B',
        },
      },
      animation: {
        'pulse-cyan': 'pulse 2s ease-in-out infinite',
      },
      keyframes: {
        pulse: {
          '0%, 100%': { opacity: '1', transform: 'scale(1)' },
          '50%': { opacity: '0.6', transform: 'scale(1.2)' },
        }
      },
    },
  },
  plugins: [],
}
'@

Set-Content -Path "G:\okiru\app builder\Cognitive Kernel\tailwind.config.js" -Value $tailwindConfig -Encoding UTF8
Write-Host "   ✅ Updated Tailwind config" -ForegroundColor Green

# ================================================================
# 3. PULSE INDICATOR COMPONENT
# ================================================================
Write-Host "[3/6] Creating PulseIndicator component..." -ForegroundColor Yellow

$pulseComponent = @'
'use client';

interface PulseIndicatorProps {
  status?: 'online' | 'processing' | 'idle';
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
}

export function PulseIndicator({ 
  status = 'online', 
  size = 'md',
  showLabel = false 
}: PulseIndicatorProps) {
  
  const sizeMap = {
    sm: 'w-1.5 h-1.5',
    md: 'w-2 h-2',
    lg: 'w-2.5 h-2.5'
  };
  
  const statusMap = {
    online: 'bg-green-success shadow-[0_0_10px_rgba(34,197,94,0.5)]',
    processing: 'bg-cyan-primary shadow-[0_0_10px_rgba(45,212,191,0.5)] animate-pulse-cyan',
    idle: 'bg-text-tertiary'
  };
  
  const labelMap = {
    online: 'Online',
    processing: 'Processing',
    idle: 'Idle'
  };
  
  return (
    <div className="flex items-center gap-2">
      <div className={`${sizeMap[size]} rounded-full ${statusMap[status]}`} />
      {showLabel && (
        <span className="text-xs text-text-muted">{labelMap[status]}</span>
      )}
    </div>
  );
}
'@

Set-Content -Path "$srcPath\components\PulseIndicator.tsx" -Value $pulseComponent -Encoding UTF8
Write-Host "   ✅ Created PulseIndicator component" -ForegroundColor Green

# ================================================================
# 4. WORKER ACTIVITY COMPONENT
# ================================================================
Write-Host "[4/6] Creating WorkerActivity component..." -ForegroundColor Yellow

$workerActivity = @'
'use client';

import { PulseIndicator } from './PulseIndicator';

interface WorkerActivityProps {
  name: string;
  active: boolean;
  lastActive?: string;
}

export function WorkerActivity({ name, active, lastActive }: WorkerActivityProps) {
  return (
    <div className="flex items-center justify-between p-2 bg-obsidian-surface rounded border border-border-subtle hover:border-cyan-primary transition-colors">
      <div className="flex items-center gap-2">
        <PulseIndicator status={active ? 'processing' : 'idle'} size="sm" />
        <span className="text-sm text-text-secondary">{name}</span>
      </div>
      {lastActive && (
        <span className="text-xs text-text-tertiary">{lastActive}</span>
      )}
    </div>
  );
}
'@

Set-Content -Path "$srcPath\components\WorkerActivity.tsx" -Value $workerActivity -Encoding UTF8
Write-Host "   ✅ Created WorkerActivity component" -ForegroundColor Green

# ================================================================
# 5. UPDATE GLOBAL CSS
# ================================================================
Write-Host "[5/6] Updating global CSS..." -ForegroundColor Yellow

$globalCSS = @'
@import './styles/obsidian-palette.css';

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  height: 100%;
  overflow: hidden;
}
'@

Set-Content -Path "$srcPath\app\globals.css" -Value $globalCSS -Encoding UTF8
Write-Host "   ✅ Updated global CSS" -ForegroundColor Green

# ================================================================
# 6. CREATE DEMO PAGE
# ================================================================
Write-Host "[6/6] Creating palette demo page..." -ForegroundColor Yellow

$demoPage = @'
'use client';

import { PulseIndicator } from '@/components/PulseIndicator';
import { WorkerActivity } from '@/components/WorkerActivity';
import '@/styles/obsidian-palette.css';

export default function PaletteDemo() {
  const workers = [
    'system_monitor', 'deepsearch', 'code_worker', 'vision',
    'app_launcher', 'mutation', 'voice', 'canvas'
  ];

  return (
    <div className="min-h-screen bg-obsidian-root text-text-primary p-8">
      <h1 className="text-2xl font-bold mb-2">Obsidian Palette Demo</h1>
      <p className="text-text-muted mb-8">#030405 • #0B0C0E • #2DD4BF • #22C55E</p>
      
      <div className="grid grid-cols-3 gap-6">
        {/* Color Swatches */}
        <div className="panel-obsidian p-4">
          <h2 className="text-lg mb-4">Colors</h2>
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-obsidian-root rounded border border-border-subtle" />
              <span className="text-sm">Root #030405</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-obsidian-surface rounded border border-border-subtle" />
              <span className="text-sm">Surface #0B0C0E</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-cyan-primary rounded" />
              <span className="text-sm">Cyan #2DD4BF</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-green-success rounded" />
              <span className="text-sm">Green #22C55E</span>
            </div>
          </div>
        </div>
        
        {/* Indicators */}
        <div className="panel-obsidian p-4">
          <h2 className="text-lg mb-4">Indicators</h2>
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <PulseIndicator status="online" showLabel />
              <span className="text-sm">Online</span>
            </div>
            <div className="flex items-center gap-4">
              <PulseIndicator status="processing" showLabel />
              <span className="text-sm">Processing</span>
            </div>
            <div className="flex items-center gap-4">
              <PulseIndicator status="idle" showLabel />
              <span className="text-sm">Idle</span>
            </div>
          </div>
        </div>
        
        {/* Workers */}
        <div className="panel-obsidian p-4">
          <h2 className="text-lg mb-4">Active Workers</h2>
          <div className="space-y-2">
            {workers.slice(0, 4).map((w, i) => (
              <WorkerActivity 
                key={w}
                name={w}
                active={i % 2 === 0}
                lastActive={i % 2 === 0 ? 'now' : '5m ago'}
              />
            ))}
          </div>
        </div>
      </div>
      
      {/* Worker Grid Preview */}
      <div className="mt-6 panel-obsidian p-4">
        <h2 className="text-lg mb-4">Worker Grid</h2>
        <div className="worker-grid">
          {workers.map((w, i) => (
            <div key={w} className={`worker-item ${i === 0 ? 'active' : ''}`}>
              <div className="worker-icon">⚙️</div>
              <div className="worker-name">{w.slice(0, 3)}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
'@

New-Item -ItemType Directory -Force -Path "$srcPath\app\palette-demo" | Out-Null
Set-Content -Path "$srcPath\app\palette-demo\page.tsx" -Value $demoPage -Encoding UTF8
Write-Host "   ✅ Created palette demo page" -ForegroundColor Green

# ================================================================
# COMPLETION
# ================================================================
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     ✅ OBSIDIAN PALETTE INSTALLED                         ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  🎨 COLOR PALETTE:" -ForegroundColor Cyan
Write-Host "     • Root:       #030405" -ForegroundColor White
Write-Host "     • Surface:    #0B0C0E" -ForegroundColor White
Write-Host "     • Cyan:       #2DD4BF" -ForegroundColor Cyan
Write-Host "     • Green:      #22C55E" -ForegroundColor Green
Write-Host "     • Border:     #1E293B" -ForegroundColor Blue
Write-Host "     • Text Muted: #94A3B8" -ForegroundColor Gray
Write-Host ""
Write-Host "  ✨ UI GOODNESS:" -ForegroundColor Yellow
Write-Host "     • Pulse indicators for worker states" -ForegroundColor White
Write-Host "     • Cyan accent for active elements" -ForegroundColor White
Write-Host "     • Subtle borders (#1E293B)" -ForegroundColor White
Write-Host "     • Hover effects with cyan glow" -ForegroundColor White
Write-Host "     • Splitter handles with cyan hover" -ForegroundColor White
Write-Host ""
Write-Host "  🚀 TO TEST:" -ForegroundColor Green
Write-Host "     1. Restart server: .\rez-control.bat" -ForegroundColor White
Write-Host "     2. Visit: http://localhost:3001/palette-demo" -ForegroundColor White
Write-Host ""