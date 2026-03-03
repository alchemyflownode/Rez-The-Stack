'use client';

import { useState } from 'react';
import { Mic, Search, Zap, Network } from 'lucide-react';

interface OnlineFeaturesProps {
  onVoiceClick?: () => void;
  onOptimize?: () => void;
  networkNodes?: number;
  downlink?: string;
}

export function OnlineFeatures({ 
  onVoiceClick, 
  onOptimize,
  networkNodes = 161,
  downlink = "43.48"
}: OnlineFeaturesProps) {
  const [searchQuery, setSearchQuery] = useState('');

  return (
    <>
      <button
        onClick={onVoiceClick}
        className="absolute right-16 top-1/2 -translate-y-1/2 p-2 rounded-lg hover:bg-white/5 transition-colors"
      >
        <Mic size={18} className="text-cyan-400" />
      </button>

      <div className="memory-vault glass-card p-4 mb-4">
        <div className="flex items-center gap-2 mb-3">
          <Search size={16} className="text-purple-400" />
          <h3 className="text-sm font-bold">Memory Vault</h3>
        </div>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search memories..."
          className="w-full bg-black/30 border border-white/10 rounded-lg px-3 py-2 text-sm"
        />
      </div>

      <button
        onClick={onOptimize}
        className="w-full py-3 rounded-lg bg-gradient-to-r from-yellow-500/20 to-orange-500/20 border border-yellow-500/30 text-yellow-400 text-sm font-medium hover:from-yellow-500/30 hover:to-orange-500/30 transition-all mb-4"
      >
        <Zap size={16} className="inline mr-2" />
        INITIATE SELF-OPTIMIZATION
      </button>

      <div className="network-stats glass-card p-4">
        <div className="flex items-center gap-2 mb-3">
          <Network size={16} className="text-emerald-400" />
          <h3 className="text-sm font-bold">NETWORK</h3>
          <span className="ml-auto text-xs text-emerald-400">{networkNodes} NODES</span>
        </div>
        <div className="space-y-2">
          <div className="flex justify-between text-xs">
            <span className="text-white/40">DOWNLINK</span>
            <span className="text-white font-mono">{downlink} MB/s</span>
          </div>
          <div className="w-full h-1 bg-white/5 rounded-full overflow-hidden">
            <div className="h-full bg-emerald-400" style={{ width: '65%' }} />
          </div>
        </div>
      </div>
    </>
  );
}
