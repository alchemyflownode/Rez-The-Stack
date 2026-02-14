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
  const [activeTab, setActiveTab] = useState<'results' | 'console' | 'metrics'>('results');

  const handleExecute = async () => {
    if (!command.trim()) return;
    
    const fullCmd = command.trim();
    
    setOutput(prev => [...prev, 
      `🦊 JARVIS@${workspaceDisplay}:${currentPath === '.' ? '~' : currentPath}$ ${fullCmd}`
    ]);
    setCommand('');
    setIsProcessing(true);

    try {
      // Check for Agentic Build Commands
      const isAgentTask = fullCmd.startsWith('/build') || fullCmd.startsWith('build ');
      if (isAgentTask) {
        setOutput(prev => [...prev, '🧠 Generating Plan... (Agent Mode)']);
        
        const response = await fetch('/api/agent', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ prompt: fullCmd.replace('/build ', '').replace('build ', '') })
        });
        const data = await response.json();

        if (data.success && data.results) {
           const planSteps = data.results.map((r: any) => r.step);
           onPlanStart(planSteps);
           
           data.results.forEach((res: any, i: number) => {
              setTimeout(() => onStepUpdate(i, 'running'), i * 200);
              setTimeout(() => onStepUpdate(i, 'success'), i * 200 + 500);
           });

           setOutput(prev => [...prev, '✅ Plan Executed:', JSON.stringify(data.results, null, 2)]);

           if(data.shardId) {
             onShardCreate({ id: data.shardId, type: 'skill', tags: ['agent'] });
           }
        } else {
           setOutput(prev => [...prev, `❌ Agent Error: ${data.error}`]);
        }
        return;
      }

      // Standard commands
      const standardCommands = ['ls', 'cd', 'cat', 'scan', 'fix', 'status', 'help', '/architect', '/debug', '/learn'];
      const isStandard = standardCommands.some(cmd => fullCmd.startsWith(cmd));

      // Natural language detection
      const isNaturalLanguage = !isStandard && fullCmd.split(' ').length > 1;

      if (isNaturalLanguage && !isStandard) {
        setOutput(prev => [...prev, '🧠 Thinking... (NLU Mode)']);
        
        const response = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            message: fullCmd, 
            workspace,
            model: selectedModel
          })
        });
        
        const data = await response.json();
        
        setOutput(prev => [...prev, 
          `[Intent: ${data.intent} | Model: ${data.model}]`,
          data.response,
          ''
        ]);
      } else {
        // Standard Terminal Passthrough
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
              <option value="mixtral:latest">🌟 Mixtral</option>
              <option value="codellama:latest">📘 Code Llama</option>
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
            <span className="text-xs text-emerald-400 font-medium tracking-wide">NLU ONLINE</span>
          </div>
        </div>
      </div>
      
      {/* Scroll Tabs Section */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Tab Bar */}
        <div className="flex items-center gap-1 px-4 pt-2 border-b border-purple-500/30 bg-gray-900/50">
          <button 
            onClick={() => setActiveTab('results')}
            className={`px-4 py-2 text-xs font-mono transition-all rounded-t-lg border border-purple-500/30 border-b-0 ${
              activeTab === 'results' 
                ? 'text-purple-300 bg-purple-500/10 -mb-px' 
                : 'text-gray-500 hover:text-purple-300 bg-transparent'
            }`}
          >
            📋 Scan Results
          </button>
          <button 
            onClick={() => setActiveTab('console')}
            className={`px-4 py-2 text-xs font-mono transition-all rounded-t-lg border border-purple-500/30 border-b-0 ${
              activeTab === 'console' 
                ? 'text-purple-300 bg-purple-500/10 -mb-px' 
                : 'text-gray-500 hover:text-purple-300 bg-transparent'
            }`}
          >
            📄 Console
          </button>
          <button 
            onClick={() => setActiveTab('metrics')}
            className={`px-4 py-2 text-xs font-mono transition-all rounded-t-lg border border-purple-500/30 border-b-0 ${
              activeTab === 'metrics' 
                ? 'text-purple-300 bg-purple-500/10 -mb-px' 
                : 'text-gray-500 hover:text-purple-300 bg-transparent'
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
        <div className="flex-1 overflow-y-auto p-6 font-mono text-sm space-y-2 bg-gradient-to-b from-gray-900 to-gray-950">
          {output.length === 0 ? (
            <div className="h-full flex items-center justify-center text-gray-700">
              <div className="text-center">
                <div className="text-6xl mb-4 opacity-20">🦊</div>
                <div className="text-sm">Ask me anything about your code</div>
                <div className="text-xs mt-2 text-gray-600">Try "scan" or "what is this app?"</div>
              </div>
            </div>
          ) : (
            <>
              <div className="sticky top-0 bg-gray-900/95 backdrop-blur-sm p-2 mb-4 rounded border border-purple-500/20 text-[10px] text-gray-400 flex justify-between">
                <span>📄 {activeTab} view • {output.length} lines</span>
                <span className="text-purple-400">▼ scroll for more</span>
              </div>
              
              <div className="space-y-1.5">
                {output.map((line, i) => {
                  if (line.includes('🦊')) 
                    return <div key={i} className="text-purple-400 whitespace-pre-wrap leading-relaxed pl-2 border-l-2 border-purple-500/30 hover:bg-purple-500/5 transition-colors py-0.5">{line}</div>;
                  if (line.includes('✅')) 
                    return <div key={i} className="text-emerald-400 whitespace-pre-wrap leading-relaxed hover:bg-emerald-500/5 transition-colors py-0.5">✓ {line}</div>;
                  if (line.includes('❌')) 
                    return <div key={i} className="text-red-400 whitespace-pre-wrap leading-relaxed hover:bg-red-500/5 transition-colors py-0.5">✗ {line}</div>;
                  if (line.includes('╔') || line.includes('║') || line.includes('╚'))
                    return <div key={i} className="text-purple-500 whitespace-pre-wrap font-bold py-0.5">{line}</div>;
                  if (line.includes('[Intent:'))
                    return <div key={i} className="text-cyan-400/60 text-[11px] italic leading-relaxed pl-2 py-0.5">{line}</div>;
                  return <div key={i} className="text-gray-300 whitespace-pre-wrap leading-relaxed hover:bg-gray-800/30 transition-colors py-0.5 break-words">{line}</div>;
                })}
              </div>
            </>
          )}
          {isProcessing && (
            <div className="sticky bottom-0 mt-4 p-3 bg-purple-500/10 rounded-lg border border-purple-500/30 backdrop-blur-sm">
              <div className="flex items-center gap-3 text-purple-400">
                <div className="animate-spin">⚡</div>
                <span className="text-sm">Processing your request...</span>
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
              <div className="absolute inset-0 bg-gradient-to-r from-purple-500/10 to-cyan-500/10 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-xl" />
              <input
                type="text"
                value={command}
                onChange={(e) => setCommand(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleExecute()}
                placeholder="Ask anything: 'scan --deep' or 'what is this app?' ..."
                className="w-full bg-gray-800/50 border border-purple-500/30 rounded-xl px-6 py-4 text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:border-purple-500 focus:ring-4 focus:ring-purple-500/20 transition-all relative z-10"
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
          
          <div className="flex items-center gap-4 mt-4 text-[11px] text-gray-600">
            <span className="flex items-center gap-1 cursor-pointer hover:text-purple-400 transition-colors" onClick={() => setCommand('scan')}>
              <span className="w-1 h-1 bg-purple-500 rounded-full"></span> scan
            </span>
            <span className="flex items-center gap-1 cursor-pointer hover:text-emerald-400 transition-colors" onClick={() => setCommand('fix')}>
              <span className="w-1 h-1 bg-emerald-500 rounded-full"></span> fix
            </span>
            <span className="flex items-center gap-1 cursor-pointer hover:text-blue-400 transition-colors" onClick={() => setCommand('status')}>
              <span className="w-1 h-1 bg-blue-500 rounded-full"></span> status
            </span>
            <span className="flex items-center gap-1 cursor-pointer hover:text-amber-400 transition-colors" onClick={() => setCommand('vibe')}>
              <span className="w-1 h-1 bg-amber-500 rounded-full"></span> vibe
            </span>
            <span className="flex items-center gap-1 cursor-pointer hover:text-red-400 transition-colors" onClick={() => setCommand('scan --deep')}>
              <span className="w-1 h-1 bg-red-500 rounded-full"></span> scan --deep
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
