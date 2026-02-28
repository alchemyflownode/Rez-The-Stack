"use client";
import { useState } from 'react';
import { Activity, Cpu, HardDrive, Brain, Search, Code, Terminal, Rocket, List, Chrome, Calculator, FileEdit, Settings, X, Music, MessageCircle } from 'lucide-react';
import { useApps } from '@/hooks/useApps';
import { SovereignCard } from '@/components/ui/SovereignCard';
import { SovereignButton } from '@/components/ui/SovereignButton';
import { SovereignBadge } from '@/components/ui/SovereignBadge';

interface ControlSurfaceProps {
  onAction: (cmd: string) => void;
  stats: any;
}

const IconMap: Record<string, any> = {
  Chrome, FileEdit, Calculator, Code, Music, MessageCircle, Terminal
};

export default function SovereignControlSurface({ onAction, stats }: ControlSurfaceProps) {
  const [activeTab, setActiveTab] = useState('SYSTEM');
  const { apps, removeApp } = useApps(); 
  const [editing, setEditing] = useState(false);

  const tabs = [
    { id: 'SYSTEM', label: 'System', icon: Cpu },
    { id: 'APPS', label: 'Apps', icon: Rocket },
    { id: 'CODE', label: 'Dev', icon: Code },
    { id: 'RESEARCH', label: 'Research', icon: Search }
  ];

  return (
    <SovereignCard variant="glass" className="overflow-hidden">
      {/* Header */}
      <div className="p-3 border-b border-white/10 flex justify-between items-center">
        <div className="flex items-center gap-2">
            <Brain className="w-4 h-4 text-purple-400" />
            <span className="text-xs font-bold text-white/80">SOVEREIGN CONTROL</span>
        </div>
        <div className="flex items-center gap-2">
            <button onClick={() => setEditing(!editing)} className="p-1 hover:bg-white/10 rounded text-white/50 hover:text-white">
                <Settings className="w-3 h-3" />
            </button>
            <SovereignBadge variant="online">ONLINE</SovereignBadge>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-white/10">
        {tabs.map(tab => (
          <button 
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex-1 p-2 text-[10px] flex flex-col items-center gap-1 transition-colors ${
              activeTab === tab.id ? 'bg-purple-600/20 text-purple-300 border-b-2 border-purple-500' : 'text-white/50 hover:bg-white/5'
            }`}
          >
            <tab.icon className="w-3 h-3" />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="p-3 space-y-3 max-h-[400px] overflow-y-auto">
        
        {/* SYSTEM TAB */}
        {activeTab === 'SYSTEM' && (
          <div className="space-y-2">
            <div className="grid grid-cols-2 gap-2 text-[10px]">
              <div className="bg-white/5 p-2 rounded flex justify-between"><span className="text-white/50">CPU</span><span className="text-cyan-400 font-mono">{stats?.cpu?.percent || 0}%</span></div>
              <div className="bg-white/5 p-2 rounded flex justify-between"><span className="text-white/50">RAM</span><span className="text-purple-400 font-mono">{stats?.memory?.percent || 0}%</span></div>
              <div className="bg-white/5 p-2 rounded flex justify-between"><span className="text-white/50">DISK</span><span className="text-emerald-400 font-mono">{stats?.disk?.percent || 0}%</span></div>
              <div className="bg-white/5 p-2 rounded flex justify-between"><span className="text-white/50">GPU</span><span className="text-amber-400 font-mono">{stats?.gpu?.load || 0}%</span></div>
            </div>
            
            <div className="grid grid-cols-2 gap-2 pt-2 border-t border-white/5">
              <SovereignButton onClick={() => onAction('Check system health')}>
                <Activity className="w-3 h-3" /> Vitals
              </SovereignButton>
              <SovereignButton onClick={() => onAction('List top processes')}>
                <List className="w-3 h-3" /> Processes
              </SovereignButton>
            </div>
          </div>
        )}

        {/* APPS TAB */}
        {activeTab === 'APPS' && (
          <div className="grid grid-cols-3 gap-2">
            {apps.map(app => {
              const IconComponent = IconMap[app.icon] || Terminal;
              return (
                <div key={app.id} className="relative group">
                  <button 
                    onClick={() => onAction(app.command)} 
                    className="w-full p-3 bg-white/5 hover:bg-blue-500/20 border border-white/10 hover:border-blue-500/50 rounded-lg flex flex-col items-center gap-1 transition-all"
                  >
                    <IconComponent className="w-4 h-4 text-blue-400" />
                    <span className="text-[9px] text-white/80">{app.name}</span>
                  </button>
                  
                  {editing && (
                    <button 
                      onClick={(e) => { e.stopPropagation(); removeApp(app.id); }} 
                      className="absolute -top-1 -right-1 bg-red-500 rounded-full p-0.5 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <X className="w-2 h-2 text-white" />
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* CODE TAB */}
        {activeTab === 'CODE' && (
          <div className="space-y-2">
            <div className="text-[10px] text-white/40 mb-1">Development Tools</div>
            <div className="grid grid-cols-2 gap-2">
              <SovereignButton onClick={() => onAction('Clean code')} className="border-red-500/30 text-red-300">
                Clean Code
              </SovereignButton>
              <SovereignButton onClick={() => onAction('Write a python hello world')}>
                Gen Script
              </SovereignButton>
            </div>
          </div>
        )}

        {/* RESEARCH TAB */}
        {activeTab === 'RESEARCH' && (
          <div className="space-y-2">
            <div className="grid grid-cols-2 gap-2">
              <SovereignButton onClick={() => onAction('Deep search: Latest AI news')}>
                AI News
              </SovereignButton>
              <SovereignButton onClick={() => onAction('Deep search: Cyberpunk art')}>
                Art Ref
              </SovereignButton>
            </div>
          </div>
        )}

      </div>
    </SovereignCard>
  );
}
