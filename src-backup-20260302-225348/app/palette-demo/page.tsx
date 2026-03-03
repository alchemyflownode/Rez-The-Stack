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
