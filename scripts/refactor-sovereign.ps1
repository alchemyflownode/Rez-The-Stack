# ================================================================
# 🦊 SOVEREIGN REFACTOR - COMPONENT EXTRACTION
# ================================================================

Write-Host "Extracting components from SovereignControlSurface..." -ForegroundColor Cyan

# Create directory
New-Item -ItemType Directory -Force -Path "src\components\sovereign" | Out-Null

# ================================================================
# 1. SovereignHeader Component
# ================================================================
$headerComponent = @'
'use client';

import { Brain, Settings } from 'lucide-react';
import { SovereignBadge } from '@/components/ui/SovereignBadge';

interface SovereignHeaderProps {
  onSettingsClick: () => void;
  isEditing: boolean;
}

export function SovereignHeader({ onSettingsClick, isEditing }: SovereignHeaderProps) {
  return (
    <div className="p-3 border-b border-white/10 flex justify-between items-center">
      <div className="flex items-center gap-2">
        <Brain className="w-4 h-4 text-purple-400" />
        <span className="text-xs font-bold text-white/80">SOVEREIGN CONTROL</span>
      </div>
      <div className="flex items-center gap-2">
        <button
          onClick={onSettingsClick}
          className="p-1 hover:bg-white/10 rounded text-white/50 hover:text-white transition-colors"
          aria-label={isEditing ? "Exit edit mode" : "Enter edit mode"}
        >
          <Settings className="w-3 h-3" />
        </button>
        <SovereignBadge variant="online">ONLINE</SovereignBadge>
      </div>
    </div>
  );
}
'@
Set-Content -Path "src\components\sovereign\SovereignHeader.tsx" -Value $headerComponent -Encoding UTF8
Write-Host "   ✅ Created SovereignHeader" -ForegroundColor Green

# ================================================================
# 2. SovereignTabs Component
# ================================================================
$tabsComponent = @'
'use client';

import { Cpu, Rocket, Code, Search } from 'lucide-react';

interface Tab {
  id: string;
  label: string;
  icon: any;
}

interface SovereignTabsProps {
  tabs: Tab[];
  activeTab: string;
  onTabChange: (tabId: string) => void;
}

export function SovereignTabs({ tabs, activeTab, onTabChange }: SovereignTabsProps) {
  return (
    <div className="flex border-b border-white/10">
      {tabs.map(tab => {
        const Icon = tab.icon;
        return (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={`flex-1 p-2 text-[10px] flex flex-col items-center gap-1 transition-colors ${
              activeTab === tab.id
                ? 'bg-purple-600/20 text-purple-300 border-b-2 border-purple-500'
                : 'text-white/50 hover:bg-white/5'
            }`}
            aria-selected={activeTab === tab.id}
            role="tab"
          >
            <Icon className="w-3 h-3" />
            {tab.label}
          </button>
        );
      })}
    </div>
  );
}

export const SOVEREIGN_TABS = [
  { id: 'SYSTEM', label: 'System', icon: Cpu },
  { id: 'APPS', label: 'Apps', icon: Rocket },
  { id: 'CODE', label: 'Dev', icon: Code },
  { id: 'RESEARCH', label: 'Research', icon: Search }
];
'@
Set-Content -Path "src\components\sovereign\SovereignTabs.tsx" -Value $tabsComponent -Encoding UTF8
Write-Host "   ✅ Created SovereignTabs" -ForegroundColor Green

# ================================================================
# 3. SystemMetrics Component
# ================================================================
$metricsComponent = @'
'use client';

interface SystemMetricsProps {
  stats: {
    cpu?: { percent: number };
    memory?: { percent: number };
    disk?: { percent: number };
    gpu?: { load: number };
  };
}

export function SystemMetrics({ stats }: SystemMetricsProps) {
  return (
    <div className="grid grid-cols-2 gap-2 text-[10px]">
      <div className="bg-white/5 p-2 rounded flex justify-between">
        <span className="text-white/50">CPU</span>
        <span className="text-cyan-400 font-mono">{stats?.cpu?.percent || 0}%</span>
      </div>
      <div className="bg-white/5 p-2 rounded flex justify-between">
        <span className="text-white/50">RAM</span>
        <span className="text-purple-400 font-mono">{stats?.memory?.percent || 0}%</span>
      </div>
      <div className="bg-white/5 p-2 rounded flex justify-between">
        <span className="text-white/50">DISK</span>
        <span className="text-emerald-400 font-mono">{stats?.disk?.percent || 0}%</span>
      </div>
      <div className="bg-white/5 p-2 rounded flex justify-between">
        <span className="text-white/50">GPU</span>
        <span className="text-amber-400 font-mono">{stats?.gpu?.load || 0}%</span>
      </div>
    </div>
  );
}
'@
Set-Content -Path "src\components\sovereign\SystemMetrics.tsx" -Value $metricsComponent -Encoding UTF8
Write-Host "   ✅ Created SystemMetrics" -ForegroundColor Green

# ================================================================
# 4. AppGrid Component
# ================================================================
$appGridComponent = @'
'use client';

import { Terminal, X } from 'lucide-react';

interface App {
  id: string;
  name: string;
  icon: string;
  command: string;
}

interface AppGridProps {
  apps: App[];
  onAction: (command: string) => void;
  onRemove: (id: string) => void;
  editing: boolean;
  iconMap: Record<string, any>;
}

export function AppGrid({ apps, onAction, onRemove, editing, iconMap }: AppGridProps) {
  return (
    <div className="grid grid-cols-3 gap-2">
      {apps.map(app => {
        const IconComponent = iconMap[app.icon] || Terminal;
        return (
          <div key={app.id} className="relative group">
            <button
              onClick={() => onAction(app.command)}
              className="w-full p-3 bg-white/5 hover:bg-blue-500/20 border border-white/10 hover:border-blue-500/50 rounded-lg flex flex-col items-center gap-1 transition-all"
              aria-label={`Launch ${app.name}`}
            >
              <IconComponent className="w-4 h-4 text-blue-400" />
              <span className="text-[9px] text-white/80">{app.name}</span>
            </button>

            {editing && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onRemove(app.id);
                }}
                className="absolute -top-1 -right-1 bg-red-500 rounded-full p-0.5 opacity-0 group-hover:opacity-100 transition-opacity"
                aria-label={`Remove ${app.name}`}
              >
                <X className="w-2 h-2 text-white" />
              </button>
            )}
          </div>
        );
      })}
    </div>
  );
}
'@
Set-Content -Path "src\components\sovereign\AppGrid.tsx" -Value $appGridComponent -Encoding UTF8
Write-Host "   ✅ Created AppGrid" -ForegroundColor Green

# ================================================================
# 5. DevTools Component
# ================================================================
$devToolsComponent = @'
'use client';

interface DevToolsProps {
  onAction: (command: string) => void;
}

export function DevTools({ onAction }: DevToolsProps) {
  return (
    <div className="space-y-2">
      <div className="text-[10px] text-white/40 mb-1">Development Tools</div>
      <div className="grid grid-cols-2 gap-2">
        <button
          onClick={() => onAction('Clean code')}
          className="p-2 bg-red-500/10 hover:bg-red-500/20 border border-red-500/30 rounded text-[10px] text-red-300 flex items-center gap-1 justify-center"
          aria-label="Clean code"
        >
          Clean Code
        </button>
        <button
          onClick={() => onAction('Write a python hello world')}
          className="p-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded text-[10px] text-white/80 flex items-center gap-1 justify-center"
          aria-label="Generate script"
        >
          Gen Script
        </button>
      </div>
    </div>
  );
}
'@
Set-Content -Path "src\components\sovereign\DevTools.tsx" -Value $devToolsComponent -Encoding UTF8
Write-Host "   ✅ Created DevTools" -ForegroundColor Green

# ================================================================
# 6. ResearchTools Component
# ================================================================
$researchToolsComponent = @'
'use client';

import { Search } from 'lucide-react';

interface ResearchToolsProps {
  onAction: (command: string) => void;
}

export function ResearchTools({ onAction }: ResearchToolsProps) {
  return (
    <div className="space-y-2">
      <div className="grid grid-cols-2 gap-2">
        <button
          onClick={() => onAction('Deep search: Latest AI news')}
          className="p-2 bg-purple-500/10 hover:bg-purple-500/20 border border-purple-500/30 rounded text-[10px] text-purple-300 flex items-center gap-1 justify-center"
          aria-label="Search AI news"
        >
          <Search className="w-3 h-3" /> AI News
        </button>
        <button
          onClick={() => onAction('Deep search: Cyberpunk art')}
          className="p-2 bg-purple-500/10 hover:bg-purple-500/20 border border-purple-500/30 rounded text-[10px] text-purple-300 flex items-center gap-1 justify-center"
          aria-label="Search cyberpunk art"
        >
          <Search className="w-3 h-3" /> Art Ref
        </button>
      </div>
    </div>
  );
}
'@
Set-Content -Path "src\components\sovereign\ResearchTools.tsx" -Value $researchToolsComponent -Encoding UTF8
Write-Host "   ✅ Created ResearchTools" -ForegroundColor Green

# ================================================================
# 7. Barrel Export (index.ts)
# ================================================================
$indexExport = @'
export { SovereignHeader } from './SovereignHeader';
export { SovereignTabs, SOVEREIGN_TABS } from './SovereignTabs';
export { SystemMetrics } from './SystemMetrics';
export { AppGrid } from './AppGrid';
export { DevTools } from './DevTools';
export { ResearchTools } from './ResearchTools';
'@
Set-Content -Path "src\components\sovereign\index.ts" -Value $indexExport -Encoding UTF8
Write-Host "   ✅ Created barrel export" -ForegroundColor Green

# ================================================================
# 8. Refactored Main Component
# ================================================================
$refactoredMain = @'
"use client";
import { useState } from 'react';
import { SovereignCard } from '@/components/ui/SovereignCard';
import {
  SovereignHeader,
  SovereignTabs,
  SOVEREIGN_TABS,
  SystemMetrics,
  AppGrid,
  DevTools,
  ResearchTools
} from '@/components/sovereign';
import { useApps } from '@/hooks/useApps';
import { Chrome, FileEdit, Calculator, Code, Music, MessageCircle, Terminal } from 'lucide-react';

const IconMap: Record<string, any> = {
  Chrome, FileEdit, Calculator, Code, Music, MessageCircle, Terminal
};

interface ControlSurfaceProps {
  onAction: (cmd: string) => void;
  stats: any;
}

export default function SovereignControlSurface({ onAction, stats }: ControlSurfaceProps) {
  const [activeTab, setActiveTab] = useState('SYSTEM');
  const { apps, removeApp } = useApps();
  const [editing, setEditing] = useState(false);

  const handleSettingsClick = () => setEditing(!editing);

  const renderTabContent = () => {
    switch (activeTab) {
      case 'SYSTEM':
        return (
          <div className="space-y-2">
            <SystemMetrics stats={stats} />
            <div className="grid grid-cols-2 gap-2 pt-2 border-t border-white/5">
              <button
                onClick={() => onAction('Check system health')}
                className="p-2 bg-white/5 hover:bg-white/10 rounded text-[10px] text-white/80 flex items-center gap-1 justify-center"
              >
                Vitals
              </button>
              <button
                onClick={() => onAction('List top processes')}
                className="p-2 bg-white/5 hover:bg-white/10 rounded text-[10px] text-white/80 flex items-center gap-1 justify-center"
              >
                Processes
              </button>
            </div>
          </div>
        );

      case 'APPS':
        return (
          <AppGrid
            apps={apps}
            onAction={onAction}
            onRemove={removeApp}
            editing={editing}
            iconMap={IconMap}
          />
        );

      case 'CODE':
        return <DevTools onAction={onAction} />;

      case 'RESEARCH':
        return <ResearchTools onAction={onAction} />;

      default:
        return null;
    }
  };

  return (
    <SovereignCard variant="glass" className="overflow-hidden">
      <SovereignHeader onSettingsClick={handleSettingsClick} isEditing={editing} />
      <SovereignTabs
        tabs={SOVEREIGN_TABS}
        activeTab={activeTab}
        onTabChange={setActiveTab}
      />
      <div className="p-3 space-y-3 max-h-[400px] overflow-y-auto">
        {renderTabContent()}
      </div>
    </SovereignCard>
  );
}
'@
Set-Content -Path "src\components\SovereignControlSurface.tsx" -Value $refactoredMain -Encoding UTF8
Write-Host "   ✅ Refactored main component" -ForegroundColor Green

# ================================================================
# COMPLETION
# ================================================================
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     ✅ SOVEREIGN REFACTOR COMPLETE                         ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  📁 New Structure:" -ForegroundColor Cyan
Write-Host "     src/components/sovereign/"
Write-Host "     ├── SovereignHeader.tsx"
Write-Host "     ├── SovereignTabs.tsx"
Write-Host "     ├── SystemMetrics.tsx"
Write-Host "     ├── AppGrid.tsx"
Write-Host "     ├── DevTools.tsx"
Write-Host "     ├── ResearchTools.tsx"
Write-Host "     └── index.ts"
Write-Host ""
Write-Host "  📊 Improvements:" -ForegroundColor Yellow
Write-Host "     • Original depth: 36 → New depth: 5-8"
Write-Host "     • Original lines: 131 → New avg: 30-40 per component"
Write-Host "     • Maintainability: ✅ Dramatically improved"
Write-Host "     • Reusability: ✅ Components can be used elsewhere"
Write-Host ""
Write-Host "  🚀 To test:" -ForegroundColor Green
Write-Host "     .\rez-control.bat (option 3: RESTART)"
Write-Host ""