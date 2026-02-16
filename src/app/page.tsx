'use client';

import { useState, useEffect, useRef } from 'react';
import { FileTree } from '@/components/FileTree';
import { AgentInspector } from '@/components/AgentInspector';
import JARVISTerminal from '@/components/JARVISTerminal';
import { ModelSelector } from '@/components/ModelSelector';
import Link from 'next/link';
import { 
  LayoutDashboard, 
  FolderOpen, 
  ChevronDown, 
  Terminal as TerminalIcon, 
  Activity, 
  Settings2,
  Search
} from 'lucide-react';

export default function Home() {
  const [workspace, setWorkspace] = useState('.');
  const [currentModel, setCurrentModel] = useState('llama3.2:latest');
  const [leftWidth, setLeftWidth] = useState(20);
  const [rightWidth, setRightWidth] = useState(32);
  const [isDraggingLeft, setIsDraggingLeft] = useState(false);
  const [isDraggingRight, setIsDraggingRight] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!containerRef.current) return;
      const rect = containerRef.current.getBoundingClientRect();
      if (isDraggingLeft) {
        const val = ((e.clientX - rect.left) / rect.width) * 100;
        if (val > 12 && val < 35) setLeftWidth(val);
      }
      if (isDraggingRight) {
        const val = ((rect.right - e.clientX) / rect.width) * 100;
        if (val > 20 && val < 45) setRightWidth(val);
      }
    };
    const handleMouseUp = () => {
      setIsDraggingLeft(false);
      setIsDraggingRight(false);
      document.body.style.cursor = 'default';
    };
    if (isDraggingLeft || isDraggingRight) {
      document.body.style.cursor = 'col-resize';
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
    }
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDraggingLeft, isDraggingRight]);

  const middleWidth = 100 - leftWidth - rightWidth;

  return (
    <div className="h-screen flex flex-col bg-[#0b0b0b] text-[#cccccc] font-sans overflow-hidden select-none">
      {/* Global Navigation */}
      <nav className="h-11 flex items-center justify-between px-3 border-b border-[#252525] bg-[#181818] z-50 flex-shrink-0">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 bg-purple-600 rounded flex items-center justify-center">
              <span className="text-white text-[10px] font-bold">R</span>
            </div>
            <span className="text-xs font-semibold text-[#e1e1e1]">RezStack</span>
          </div>
          
          <button
            onClick={() => {}}
            className="flex items-center gap-1 px-2 py-1 hover:bg-[#2a2d2e] rounded transition-colors"
          >
            <FolderOpen className="w-3.5 h-3.5 text-[#858585]" />
            <span className="text-[11px] text-[#cccccc]">{workspace}</span>
            <ChevronDown className="w-3 h-3 text-[#858585]" />
          </button>
        </div>

        {/* Command Palette */}
        <div className="hidden md:flex items-center px-3 py-1 bg-[#202020] border border-[#303030] rounded-md w-1/3 justify-between group cursor-pointer hover:border-[#404040]">
          <div className="flex items-center gap-2">
            <Search className="w-3 h-3 text-[#858585]" />
            <span className="text-[11px] text-[#858585]">Search or run command...</span>
          </div>
          <span className="text-[9px] bg-[#2a2d2e] px-1.5 py-0.5 rounded text-[#858585]">⌘P</span>
        </div>

        <div className="flex items-center gap-3">
          <Link href="/rez-dashboard" className="p-1.5 hover:bg-[#2a2d2e] rounded transition-colors text-[#858585] hover:text-white">
            <LayoutDashboard className="w-4 h-4" />
          </Link>
          <div className="w-px h-4 bg-[#333333]" />
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-green-500/80 shadow-[0_0_8px_rgba(34,197,94,0.4)]" />
            <span className="text-[10px] font-medium text-green-500/80">Local</span>
          </div>
        </div>
      </nav>

      {/* Primary Workspace */}
      <main ref={containerRef} className="flex-1 flex min-h-0 bg-[#0b0b0b]">
        {/* File Explorer */}
        <aside style={{ width: `${leftWidth}%` }} className="flex flex-col bg-[#181818] border-r border-[#252525] flex-shrink-0">
          <div className="h-9 flex items-center px-4 text-[11px] font-bold uppercase tracking-wider text-[#858585] flex-shrink-0">
            EXPLORER
          </div>
          <div className="flex-1 overflow-y-auto custom-scrollbar">
            <FileTree workspace={workspace} />
          </div>
        </aside>

        {/* Splitter */}
        <div 
          onMouseDown={() => setIsDraggingLeft(true)}
          className="w-[2px] hover:w-[4px] bg-transparent hover:bg-purple-500/30 active:bg-purple-500/50 cursor-col-resize transition-all z-10 flex-shrink-0"
        />

        {/* Main Terminal */}
        <section style={{ width: `${middleWidth}%` }} className="flex flex-col bg-[#1e1e1e] flex-shrink-0">
          <div className="h-9 flex items-center px-4 border-b border-[#252525] bg-[#181818] gap-4 flex-shrink-0">
            <div className="flex items-center gap-2 border-b border-purple-500 h-full px-2">
              <TerminalIcon className="w-3.5 h-3.5 text-purple-400" />
              <span className="text-[11px] font-medium text-[#e1e1e1]">JARVIS</span>
            </div>
          </div>
          <div className="flex-1 relative overflow-hidden">
            <JARVISTerminal />
          </div>
        </section>

        {/* Splitter */}
        <div 
          onMouseDown={() => setIsDraggingRight(true)}
          className="w-[2px] hover:w-[4px] bg-transparent hover:bg-purple-500/30 active:bg-purple-500/50 cursor-col-resize transition-all z-10 flex-shrink-0"
        />

        {/* Inspector */}
        <aside style={{ width: `${rightWidth}%` }} className="flex flex-col bg-[#181818] border-l border-[#252525] flex-shrink-0">
          <div className="p-4 border-b border-[#252525] flex-shrink-0">
            <ModelSelector currentModel={currentModel} onModelChange={setCurrentModel} />
          </div>
          <div className="flex-1 overflow-y-auto custom-scrollbar">
            <div className="px-4 py-2 flex items-center gap-2 text-[10px] text-[#858585] uppercase tracking-widest font-bold">
              <Activity className="w-3 h-3" />
              INSPECTOR
            </div>
            <AgentInspector />
          </div>
        </aside>
      </main>

      {/* Status Bar */}
      <footer className="h-6 flex items-center justify-between px-3 bg-[#007acc] text-white text-[11px] flex-shrink-0">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-1 hover:bg-white/10 px-2 h-full cursor-pointer">
            <Settings2 className="w-3 h-3" />
            <span>Ready</span>
          </div>
          <span>UTF-8</span>
        </div>
        <div className="flex items-center gap-4 px-2">
          <span>{currentModel}</span>
          <span className="font-mono opacity-80">localhost:11434</span>
        </div>
      </footer>
    </div>
  );
}
