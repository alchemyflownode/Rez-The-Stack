'use client';

import { useEffect, useState } from 'react';

export default function TestPage() {
  const [cursorPos, setCursorPos] = useState({ x: 50, y: 50 });

  useEffect(() => {
    const updateCursor = (e: MouseEvent) => {
      setCursorPos({
        x: (e.clientX / window.innerWidth) * 100,
        y: (e.clientY / window.innerHeight) * 100
      });
    };
    window.addEventListener('mousemove', updateCursor);
    return () => window.removeEventListener('mousemove', updateCursor);
  }, []);

  return (
    <main className="min-h-screen bg-deep text-white flex items-center justify-center p-4">
      {/* Background glow that follows cursor */}
      <div 
        className="fixed inset-0 pointer-events-none transition-opacity duration-300"
        style={{
          background: `radial-gradient(circle at ${cursorPos.x}% ${cursorPos.y}%, rgba(0,255,194,0.05) 0%, transparent 50%)`
        }}
      />
      
      <div className="zd-glass p-8 max-w-2xl w-full rounded-xl rim-light relative z-10">
        {/* Scanline effect */}
        <div className="rez-border mb-6 p-4 rounded-lg">
          <h1 className="kinetic-text text-3xl text-cyan mb-2">✅ SOVEREIGN RECOVERY SUCCESS</h1>
          <p className="text-secondary text-sm">
            Zero Drift architecture successfully merged with GitHub scaffold.
          </p>
        </div>

        {/* Metrics Grid */}
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="metric-container">
            <span className="metric-label">CPU</span>
            <span className="metric-value">23%</span>
          </div>
          <div className="metric-container">
            <span className="metric-label">RAM</span>
            <span className="metric-value">45%</span>
          </div>
          <div className="metric-container">
            <span className="metric-label">GPU</span>
            <span className="metric-value">12%</span>
          </div>
          <div className="metric-container">
            <span className="metric-label">NPU</span>
            <span className="metric-value">8%</span>
          </div>
        </div>

        {/* Status Indicators */}
        <div className="flex gap-4 mb-6">
          <div className="flex items-center gap-2">
            <span className="status-dot online" />
            <span className="text-xs text-tertiary">ONLINE</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="status-dot verifying" />
            <span className="text-xs text-tertiary">VERIFYING</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="status-dot offline" />
            <span className="text-xs text-tertiary">OFFLINE</span>
          </div>
        </div>

        {/* Proof Hash */}
        <div className="flex items-center justify-between pt-4 border-t border-rim">
          <span className="text-xs text-tertiary">REZONIC PROOF</span>
          <span className="proof-hash">0x7A3F4B2C_REZNIC</span>
        </div>

        {/* System Version */}
        <div className="mt-4 text-center">
          <span className="text-[8px] text-dim tracking-widest">
            ZERO DRIFT v2026 • SOVEREIGN OS
          </span>
        </div>
      </div>
    </main>
  );
}
