'use client';

import React, { useState } from 'react';
import { Terminal, Loader, Zap, Send } from 'lucide-react';

interface JARVISTerminalProps {
  workspace?: string;
  currentPath?: string;
  onPlanStart?: (plan: any[]) => void;
  onStepUpdate?: (index: number, status: string) => void;
  onShardCreate?: (shard: any) => void;
}

export default function JARVISTerminal({ 
  workspace = '', 
  currentPath = '.', 
  onPlanStart = () => {}, 
  onStepUpdate = () => {}, 
  onShardCreate = () => {} 
}: JARVISTerminalProps) {
  const [command, setCommand] = useState('');
  const [output, setOutput] = useState<string[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [workspaceDisplay] = useState('JARVIS');
  const [selectedModel, setSelectedModel] = useState('llama3.2:latest');
  const [activeTab, setActiveTab] = useState('results');

  const handleExecute = async () => {
    if (!command.trim()) return;
    
    const fullCmd = command.trim();
    
    setOutput(prev => [...prev, 
      `🦊 JARVIS@${workspaceDisplay}:${currentPath === '.' ? '~' : currentPath}$ ${fullCmd}`
    ]);
    setCommand('');
    setIsProcessing(true);

    try {
      const response = await fetch('/api/terminal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command: fullCmd, workspace })
      });
      
      const data = await response.json();
      
      if (data.output === 'CLEAR') {
        setOutput([]);
      } else {
        const lines = data.output.split('\n');
        setOutput(prev => [...prev, ...lines, '']);
      }
    } catch (error) {
      setOutput(prev => [...prev, `❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`, '']);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="h-full flex flex-col bg-gradient-to-b from-gray-900 to-gray-950">
      {/* Header */}
      <div className="flex items-center justify-between px-8 py-4 bg-gradient-to-r from-purple-900/30 via-gray-900 to-cyan-900/20 border-b border-purple-500/30">
        <div className="flex items-center gap-4">
          <div className="relative">
            <div className="absolute inset-0 bg-purple-500/30 blur-xl rounded-full" />
            <Terminal className="w-6 h-6 text-purple-400 relative z-10" />
          </div>
          <div>
            <span className="text-sm font-mono text-purple-300 font-bold tracking-wider">JARVIS TERMINAL</span>
            <span className="text-[10px] text-gray-500 block mt-0.5">Sovereign AI Interface</span>
          </div>
        </div>
        <div className="flex items-center gap-4">
          <div className="relative group">
            <select
              value={selectedModel}
              onChange={(e) => setSelectedModel(e.target.value)}
              className="appearance-none bg-purple-500/10 border border-purple-500/30 rounded-lg px-4 py-2 pr-8 text-xs text-purple-300 font-mono focus:outline-none focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 transition-all cursor-pointer hover:bg-purple-500/20"
            >
              <option value="llama3.2:latest">🦙 Llama 3.2</option>
              <option value="phi4:latest">🧠 Phi-4</option>
              <option value="deepseek-coder:latest">💻 DeepSeek Coder</option>
              <option value="qwen2.5-coder:7b">⚡ Qwen Coder</option>
              <option value="llama3.2:1b">🚀 Llama 1B (Fast)</option>
            </select>
            <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-purple-400/70">
              ▼
            </div>
          </div>
          <div className="flex items-center gap-2 bg-emerald-500/10 px-4 py-2 rounded-full border border-emerald-500/20">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            <span className="text-xs text-emerald-400 font-medium tracking-wide">ONLINE</span>
          </div>
        </div>
      </div>
      
      {/* Terminal Output with Scroll Tabs */}
      <div className="flex-1 flex flex-col overflow-hidden bg-gradient-to-b from-gray-900 via-gray-900 to-gray-950">
        {/* Tab Bar */}
        <div className="flex items-center gap-1 px-4 pt-2 border-b border-purple-500/30">
          <button 
            onClick={() => setActiveTab('results')}
            className={`px-3 py-1.5 text-xs font-mono transition-all rounded-t-lg border border-purple-500/30 border-b-0 ${
              activeTab === 'results' 
                ? 'text-purple-300 bg-purple-500/10' 
                : 'text-gray-500 hover:text-purple-300'
            }`}
          >
            📋 Results
          </button>
          <button 
            onClick={() => setActiveTab('console')}
            className={`px-3 py-1.5 text-xs font-mono transition-all rounded-t-lg border border-purple-500/30 border-b-0 ${
              activeTab === 'console' 
                ? 'text-purple-300 bg-purple-500/10' 
                : 'text-gray-500 hover:text-purple-300'
            }`}
          >
            📄 Console
          </button>
          <button 
            onClick={() => setActiveTab('metrics')}
            className={`px-3 py-1.5 text-xs font-mono transition-all rounded-t-lg border border-purple-500/30 border-b-0 ${
              activeTab === 'metrics' 
                ? 'text-purple-300 bg-purple-500/10' 
                : 'text-gray-500 hover:text-purple-300'
            }`}
          >
            📊 Metrics
          </button>
          <div className="flex-1" />
          <span className="text-[10px] text-gray-600 px-2">
            {output.length} lines
          </span>
        </div>
        
        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto p-4 font-mono text-sm space-y-1 bg-gradient-to-b from-gray-900 to-gray-950">
          {output.length === 0 ? (
            <div className="h-full flex items-center justify-center text-gray-700">
              <div className="text-center">
                <div className="text-6xl mb-4 opacity-20">🦊</div>
                <div className="text-sm">Ask me anything about your code</div>
                <div className="text-xs mt-2 text-gray-600">Try "scan --deep" or "what is this app?"</div>
              </div>
            </div>
          ) : (
            <>
              {/* Line counter - Sticky */}
              <div className="sticky top-0 bg-gray-900/95 backdrop-blur-sm p-2 mb-3 rounded border border-purple-500/20 text-[10px] text-gray-400 flex justify-between z-10">
                <span>📄 {activeTab} view • {output.length} lines</span>
                <span className="text-purple-400">▼ scroll for more</span>
              </div>
              
              {/* Scrollable lines */}
              <div className="space-y-1">
                {output.map((line, i) => {
                  let lineClass = "whitespace-pre-wrap break-words leading-relaxed py-0.5 px-2 rounded hover:bg-gray-800/30 transition-colors";
                  if (line.includes('🦊')) lineClass += " text-purple-400 border-l-2 border-purple-500/30 pl-2";
                  else if (line.includes('✅')) lineClass += " text-emerald-400";
                  else if (line.includes('❌')) lineClass += " text-red-400";
                  else if (line.includes('╔') || line.includes('║') || line.includes('╚')) lineClass += " text-purple-500 font-bold";
                  else if (line.includes('[PHASE')) lineClass += " text-cyan-400 font-bold mt-2";
                  return <div key={i} className={lineClass}>{line}</div>;
                })}
              </div>
            </>
          )}
          
          {/* Processing indicator */}
          {isProcessing && (
            <div className="sticky bottom-0 mt-4 p-3 bg-purple-500/10 rounded-lg border border-purple-500/30 backdrop-blur-sm">
              <div className="flex items-center gap-3 text-purple-400">
                <div className="animate-spin">⚡</div>
                <span className="text-sm">Processing...</span>
              </div>
            </div>
          )}
        </div>
      </div>
      
      {/* Input Area */}
      <div className="border-t border-purple-500/20 bg-gradient-to-t from-gray-950 to-gray-900 p-6">
        <div className="max-w-6xl mx-auto">
          <div className="flex items-center gap-3">
            <div className="flex-1 relative group">
              <input
                type="text"
                value={command}
                onChange={(e) => setCommand(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleExecute()}
                placeholder="Try: scan --deep • scan --zombies • help"
                className="w-full bg-gray-800/50 border border-purple-500/30 rounded-xl px-6 py-4 text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:border-purple-500 focus:ring-4 focus:ring-purple-500/20 transition-all"
                autoFocus
                disabled={isProcessing}
              />
            </div>
            <button 
              onClick={handleExecute} 
              disabled={isProcessing || !command.trim()}
              className="px-8 py-4 bg-gradient-to-r from-purple-600 to-cyan-600 hover:from-purple-700 hover:to-cyan-700 disabled:from-gray-700 disabled:to-gray-800 disabled:cursor-not-allowed rounded-xl text-sm font-medium text-white transition-all duration-200 shadow-lg shadow-purple-500/20 flex items-center gap-2 group"
            >
              <Send className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              <span>Send</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
