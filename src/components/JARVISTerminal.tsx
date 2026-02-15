'use client';

import React, { useState, useRef, useEffect, useCallback } from 'react';
import { Terminal, Loader } from 'lucide-react';

type StepStatus = 'pending' | 'running' | 'success' | 'error';

interface JARVISTerminalProps {
  workspace?: string;
  currentPath?: string;
  onPlanStart?: (steps: string[]) => void;
  onStepUpdate?: (index: number, status: StepStatus) => void;
  onShardCreate?: (shard: { id: string; type: string; tags: string[] }) => void;
}

export default function JARVISTerminal({
  workspace = '',
  currentPath = '.',
  onPlanStart = () => {},
  onStepUpdate = () => {},
  onShardCreate = () => {},
}: JARVISTerminalProps) {
  const [command, setCommand] = useState('');
  const [output, setOutput] = useState<string[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const outputRef = useRef<HTMLDivElement>(null);

  const workspaceDisplay = 'JARVIS';

  // Auto scroll
  useEffect(() => {
    outputRef.current?.scrollTo({
      top: outputRef.current.scrollHeight,
      behavior: 'smooth',
    });
  }, [output]);

  const appendOutput = useCallback((lines: string | string[]) => {
    setOutput((prev) => [...prev, ...(Array.isArray(lines) ? lines : [lines])]);
  }, []);

  const handleExecute = async () => {
    if (!command.trim() || isProcessing) return;

    const fullCmd = command.trim();
    setCommand('');
    setIsProcessing(true);

    appendOutput(
      `🦊 ${workspaceDisplay}@${currentPath === '.' ? '~' : currentPath}$ ${fullCmd}`
    );

    try {
      if (isAgentCommand(fullCmd)) {
        await handleAgent(fullCmd);
      } else if (isStandardCommand(fullCmd)) {
        await handleTerminal(fullCmd);
      } else {
        await handleNLU(fullCmd);
      }
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : 'Unknown execution error';

      appendOutput([
        '❌ Execution Error',
        `→ ${message}`,
        '💡 Ensure backend services are running.',
        '',
      ]);
    } finally {
      setIsProcessing(false);
    }
  };

  // ========================
  // ROUTERS
  // ========================

  const isAgentCommand = (cmd: string) =>
    cmd.startsWith('/build') || cmd.startsWith('build ');

  const isStandardCommand = (cmd: string) => {
    const standard = [
      'ls',
      'cd',
      'cat',
      'scan',
      'fix',
      'status',
      'help',
      '/architect',
      '/debug',
      '/learn',
    ];
    return standard.some((c) => cmd.startsWith(c));
  };

  const handleAgent = async (cmd: string) => {
    appendOutput('⚡ Generating Agent Plan...');

    const prompt = cmd.replace(/^\/?build\s*/, '');

    const res = await fetch('/api/agent', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt }),
    });

    if (!res.ok) throw new Error(`Agent API ${res.status}`);

    const data = await res.json();

    if (!data.success || !data.results) {
      appendOutput(`❌ Agent Error: ${data.error ?? 'Unknown error'}`);
      return;
    }

    const steps = data.results.map((r: any) => r.step);
    onPlanStart(steps);

    steps.forEach((_, i) => {
      setTimeout(() => onStepUpdate(i, 'running'), i * 250);
      setTimeout(() => onStepUpdate(i, 'success'), i * 250 + 600);
    });

    appendOutput([
      '✅ Plan Executed',
      JSON.stringify(data.results, null, 2),
      '',
    ]);

    if (data.shardId) {
      onShardCreate({
        id: data.shardId,
        type: 'skill',
        tags: ['agent'],
      });
    }
  };

  const handleNLU = async (cmd: string) => {
    appendOutput('🧠 Thinking...');

    const res = await fetch('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: cmd, workspace }),
    });

    if (!res.ok) throw new Error(`Chat API ${res.status}`);

    const data = await res.json();

    appendOutput([
      `[Intent: ${data.intent ?? 'unknown'} | Model: ${
        data.model ?? 'unknown'
      }]`,
      data.response ?? 'No response',
      '',
    ]);
  };

  const handleTerminal = async (cmd: string) => {
    const res = await fetch('/api/terminal', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ command: cmd, workspace }),
    });

    if (!res.ok) throw new Error(`Terminal API ${res.status}`);

    const data = await res.json();

    if (data.output === 'CLEAR') {
      setOutput([]);
      return;
    }

    appendOutput([...data.output.split('\n'), '']);
  };

  // ========================
  // UI
  // ========================

  return (
    <div className="h-full flex flex-col bg-gray-950">
      {/* HEADER */}
      <div className="flex items-center justify-between px-4 py-2 bg-gradient-to-r from-purple-900/40 via-gray-900 to-cyan-900/20 border-b border-purple-500/30">
        <div className="flex items-center gap-3">
          <Terminal className="w-5 h-5 text-purple-400" />
          <span className="text-xs font-mono text-purple-300 font-bold">
            JARVIS TERMINAL
          </span>
        </div>
        <span className="flex items-center gap-1.5 bg-emerald-500/10 px-2 py-1 rounded-full">
          <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
          <span className="text-[10px] text-emerald-400 font-medium">
            NLU ONLINE
          </span>
        </span>
      </div>

      {/* OUTPUT */}
      <div
        ref={outputRef}
        className="flex-1 overflow-y-auto p-4 font-mono text-xs bg-gradient-to-b from-gray-950 to-gray-900"
      >
        {output.map((line, i) => (
          <div key={i} className="text-gray-300 whitespace-pre-wrap">
            {line}
          </div>
        ))}

        {isProcessing && (
          <div className="flex items-center gap-2 text-purple-400 mt-2">
            <Loader className="w-3 h-3 animate-spin" />
            <span>Processing...</span>
          </div>
        )}
      </div>

      {/* INPUT */}
      <div className="flex items-center px-4 py-3 bg-gray-900/90 border-t border-purple-500/30">
        <span className="text-purple-400 mr-2 text-xs font-bold">🦊</span>

        <input
          type="text"
          value={command}
          onChange={(e) => setCommand(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleExecute()}
          placeholder="Try: what is this app?  or  /build SaaS landing page"
          className="flex-1 bg-transparent border-none outline-none text-xs text-gray-200 placeholder-gray-600 font-mono"
          disabled={isProcessing}
          autoFocus
        />

        <button
          onClick={handleExecute}
          disabled={isProcessing || !command.trim()}
          className="ml-2 px-4 py-1.5 bg-gradient-to-r from-purple-600 to-cyan-600 hover:from-purple-700 hover:to-cyan-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg text-xs font-medium transition-all duration-200 shadow-lg shadow-purple-500/20"
        >
          RUN
        </button>
      </div>
    </div>
  );
}
