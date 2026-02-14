'use client';

import React, { useState } from 'react';
import { Terminal, Loader } from 'lucide-react';

export default function JARVISTerminal({ 
  workspace = '', 
  currentPath = '.', 
  onPlanStart = () => {}, 
  onStepUpdate = () => {}, 
  onShardCreate = () => {} 
}) {
  const [command, setCommand] = useState('');
  const [output, setOutput] = useState<string[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [workspaceDisplay] = useState('JARVIS');

  const handleExecute = async () => {
    if (!command.trim()) return;
    
    const fullCmd = command.trim();
    
    setOutput(prev => [...prev, 
      `?? JARVIS@${workspaceDisplay}:${currentPath === '.' ? '~' : currentPath}$ ${fullCmd}`
    ]);
    setCommand('');
    setIsProcessing(true);

    try {
      // 1. Check for Agentic Build Commands
      const isAgentTask = fullCmd.startsWith('/build') || fullCmd.startsWith('build ');
      if (isAgentTask) {
        setOutput(prev => [...prev, '?? Generating Plan... (Agent Mode)']);
        
        const response = await fetch('/api/agent', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ prompt: fullCmd.replace('/build ', '').replace('build ', '') })
        });
        const data = await response.json();

        if (data.success && data.results) {
           const planSteps = data.results.map((r: unknown) => r.step);
           onPlanStart(planSteps);
           
           data.results.forEach((res: unknown, i: number) => {
              setTimeout(() => onStepUpdate(i, 'running'), i * 200);
              setTimeout(() => onStepUpdate(i, 'success'), i * 200 + 500);
           });

           setOutput(prev => [...prev, '? Plan Executed:', JSON.stringify(data.results, null, 2)]);

           if(data.shardId) {
             onShardCreate({ id: data.shardId, type: 'skill', tags: ['agent'] });
           }
        } else {
           setOutput(prev => [...prev, `? Agent Error: ${data.error}`]);
        }
        return;
      }

      // 2. Check for Standard Commands
      const standardCommands = ['ls', 'cd', 'cat', 'scan', 'fix', 'status', 'help', '/architect', '/debug', '/learn'];
      const isStandard = standardCommands.some(cmd => fullCmd.startsWith(cmd));

      // 3. Route everything else to NLU Chat
      const isNaturalLanguage = !isStandard && fullCmd.split(' ').length > 1;

      if (isNaturalLanguage && !isStandard) {
        setOutput(prev => [...prev, '?? Thinking... (NLU Mode)']);
        
        const response = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message: fullCmd, workspace })
        });
        
        const data = await response.json();
        
        setOutput(prev => [...prev, 
          `[Intent: ${data.intent} | Model: ${data.model}]`,
          data.response,
          ''
        ]);
      } else {
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
      setOutput(prev => [...prev, `? Error: ${error instanceof Error ? error.message : 'Unknown error'}`, '']);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="h-full flex flex-col bg-gray-950">
      <div className="flex items-center justify-between px-4 py-2 bg-gradient-to-r from-purple-900/40 via-gray-900 to-cyan-900/20 border-b border-purple-500/30">
        <div className="flex items-center gap-3">
          <div className="relative">
            <Terminal className="w-5 h-5 text-purple-400" aria-hidden="true" />
            <div className="absolute -top-1 -right-1 w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
          </div>
          <span className="text-xs font-mono text-purple-300 font-bold">JARVIS TERMINAL</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-1.5 bg-emerald-500/10 px-2 py-1 rounded-full">
            <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
            <span className="text-[10px] text-emerald-400 font-medium">NLU ONLINE</span>
          </span>
        </div>
      </div>
      
      <div className="flex-1 overflow-y-auto p-4 font-mono text-xs bg-gradient-to-b from-gray-950 to-gray-900">
        {output.map((line, i) => (
          <div key={i} className="text-gray-300 whitespace-pre-wrap">{line}</div>
        ))}
        {isProcessing && (
          <div className="flex items-center gap-2 text-purple-400 mt-2" role="status">
            <Loader className="w-3 h-3 animate-spin" />
            <span>Processing...</span>
          </div>
        )}
      </div>
      
      <div className="flex items-center px-4 py-3 bg-gray-900/90 border-t border-purple-500/30">
        <span className="text-purple-400 mr-2 text-xs font-bold" aria-hidden="true">??</span>
        <label htmlFor="jarvis-input" className="sr-only">Command Input</label>
        <input
          id="jarvis-input"
          type="text"
          value={command}
          onChange={(e) => setCommand(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleExecute()}
          placeholder="Try: 'what is this app?' or /build ..."
          className="flex-1 bg-transparent border-none outline-none text-xs text-gray-200 placeholder-gray-600 font-mono"
          autoFocus
          disabled={isProcessing}
          aria-label="Command input"
        />
        <button 
          onClick={handleExecute} 
          disabled={isProcessing || !command.trim()}
          className="ml-2 px-4 py-1.5 bg-gradient-to-r from-purple-600 to-cyan-600 hover:from-purple-700 hover:to-cyan-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg text-xs font-medium transition-all duration-200 shadow-lg shadow-purple-500/20"
          aria-label="Run command"
        >
          RUN
        </button>
      </div>
    </div>
  );
}



