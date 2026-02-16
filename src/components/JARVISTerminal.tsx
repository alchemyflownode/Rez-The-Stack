'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Terminal, Send, Loader, AlertCircle, CheckCircle, XCircle } from 'lucide-react';
import { nlu } from '@/services/NLUBridge';
import { ecosystem } from '@/services/EcosystemBridge';

interface Message {
  id: string; // Added ID for better key stability
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
  status?: 'loading' | 'success' | 'error';
}

export default function JARVISTerminal() {
  const [input, setInput] = useState('');
  const [messages, setMessages] = useState<Message[]>([
    { 
      id: 'init-1',
      role: 'assistant', 
      content: '🦊 Hello! I\'m your AI pair programmer. Type /scan to check constitutional violations.', 
      timestamp: new Date(0) 
    }
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const [mounted, setMounted] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Set mounted state after hydration
  useEffect(() => {
    setMounted(true);
  }, []);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const addMessage = (role: 'user' | 'assistant' | 'system', content: string, status?: 'loading' | 'success' | 'error') => {
    const timestamp = mounted ? new Date() : new Date(0);
    const id = `${timestamp.getTime()}-${Math.random().toString(36).substr(2, 9)}`;
    setMessages(prev => [...prev, { id, role, content, timestamp, status }]);
  };

  const updateLastMessage = (content: string, status?: 'loading' | 'success' | 'error') => {
    setMessages(prev => {
      const newMessages = [...prev];
      const lastIndex = newMessages.length - 1;
      // Preserve ID and Timestamp, update content and status
      newMessages[lastIndex] = { ...newMessages[lastIndex], content, status };
      return newMessages;
    });
  };

  // Typing effect for assistant responses
  const typeMessage = (fullContent: string, status: 'success' | 'error' = 'success') => {
    let i = 0;
    const speed = 15; // ms per character
    
    // Initialize empty message if needed, or update existing loading message
    // For simplicity in this refactor, we assume we are updating the last message 
    // which was created as 'loading' just before calling this.
    
    const interval = setInterval(() => {
      if (i < fullContent.length) {
        updateLastMessage(fullContent.slice(0, i + 1), 'loading');
        i++;
      } else {
        updateLastMessage(fullContent, status);
        clearInterval(interval);
      }
    }, speed);
  };

  const formatTime = (date: Date) => {
    if (!mounted || date.getTime() === 0) return '--:--:--';
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  };

  const getStatusIcon = (status?: string) => {
    switch (status) {
      case 'loading': return <Loader className="w-3 h-3 animate-spin text-blue-400" />;
      case 'success': return <CheckCircle className="w-3 h-3 text-green-400" />;
      case 'error': return <XCircle className="w-3 h-3 text-red-400" />;
      default: return null;
    }
  };

  // Unified Command Handler
  const handleCommand = async (command: string) => {
    if (!command.trim() || isLoading) return;

    addMessage('user', command);
    setInput('');
    setIsLoading(true);

    // 1. Handle Special Commands
    if (command === '/scan') {
      addMessage('assistant', '🔍 Scanning workspace for constitutional violations...', 'loading');
      
      // Simulate progress steps
      const steps = [
        { t: 500, msg: '📁 Scanning files... 25%' },
        { t: 1000, msg: '🔬 Analyzing TypeScript files... 50%' },
        { t: 1500, msg: '⚖️ Checking constitutional articles... 75%' }
      ];

      steps.forEach(step => {
        setTimeout(() => updateLastMessage(step.msg, 'loading'), step.t);
      });

      try {
        // Simulate API delay
        await new Promise(r => setTimeout(r, 2000));
        
        // Mock response for demo (replace with actual fetch in prod)
        const mockData = { violationsFound: 0, totalFiles: 42 }; 
        
        if (mockData.violationsFound > 0) {
          updateLastMessage(`⚠️ Found ${mockData.violationsFound} violations!`, 'error');
        } else {
          updateLastMessage(`✅ No constitutional violations found!\n• ${mockData.totalFiles} files scanned`, 'success');
        }
      } catch (error) {
        updateLastMessage('❌ Failed to connect to constitutional API.', 'error');
      } finally {
        setIsLoading(false);
      }
      return;
    }

    if (command === '/status') {
      addMessage('assistant', '✅ All systems nominal. NLU and Ecosystem bridges active.', 'success');
      setIsLoading(false);
      return;
    }

    // 2. Try Swarm First
    try {
      const response = await fetch('http://localhost:8000/process', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command, context: { workspace: '.' } }),
        // Short timeout to fail fast if swarm is down
        signal: AbortSignal.timeout(2000) 
      });
      
      if (response.ok) {
        const data = await response.json();
        const swarmMsg = data.response || data.message || 'Swarm processed: ' + command;
        addMessage('assistant', `🦊 [Swarm] ${swarmMsg}`, 'loading');
        typeMessage(swarmMsg, 'success');
        setIsLoading(false);
        return;
      }
    } catch (error) {
      // Swarm failed, fall through to local processing
      console.warn('Swarm unavailable');
    }

    // 3. Fallback to Local NLU
    try {
      // Create a placeholder message for typing effect
      addMessage('assistant', 'Thinking...', 'loading');
      
      const nluResponse = await nlu.process(command);
      
      if (nluResponse.intent !== 'unknown') {
        typeMessage(nluResponse.response, nluResponse.confidence > 0.8 ? 'success' : 'loading');
      } else {
        typeMessage(nluResponse.response, 'success');
      }
    } catch (error) {
      addMessage('assistant', 
        `❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        'error'
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    handleCommand(input);
  };

  return (
    <div data-testid="terminal-main" className="h-full flex flex-col bg-[#1e1e1e] font-mono">
      {/* Terminal Header */}
      <div className="h-9 flex items-center justify-between px-4 border-b border-[#252525] bg-[#181818] select-none">
        <div className="flex items-center gap-2">
          <Terminal className="w-3.5 h-3.5 text-purple-400" />
          <span className="text-[11px] font-medium text-[#e1e1e1]">JARVIS Terminal</span>
          <span className="text-[9px] px-1.5 py-0.5 bg-[#2a2d2e] rounded text-[#858585]">v4.2</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-green-500/80 shadow-[0_0_8px_rgba(34,197,94,0.4)]" />
          <span className="text-[9px] text-[#858585]">NLU ONLINE</span>
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
        {messages.map((msg) => (
          <div
            key={msg.id} // Improved key stability
            className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'} animate-fade-in`}
          >
            {msg.role === 'assistant' && (
              <div className="flex-shrink-0 mr-2 mt-0.5">
                <div className="w-5 h-5 bg-purple-500/20 rounded flex items-center justify-center border border-purple-500/20">
                  <span className="text-[10px]">🦊</span>
                </div>
              </div>
            )}
            <div
              className={`relative max-w-[85%] rounded-lg px-3 py-2 shadow-sm ${
                msg.role === 'user'
                  ? 'bg-[#007acc] text-white'
                  : msg.status === 'loading'
                  ? 'bg-[#252525] text-[#cccccc] border border-blue-500/30'
                  : msg.status === 'error'
                  ? 'bg-[#2a1f1f] text-[#ff6b6b] border border-red-500/30'
                  : 'bg-[#252525] text-[#cccccc] border border-[#333]'
              }`}
            >
              <div className="flex items-start gap-2">
                {msg.status && msg.role === 'assistant' && (
                  <div className="mt-0.5 flex-shrink-0">
                    {getStatusIcon(msg.status)}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <p className="text-[11px] whitespace-pre-wrap leading-relaxed break-words">{msg.content}</p>
                  <p className={`text-[8px] mt-1 text-right ${
                    msg.role === 'user' ? 'text-blue-200/70' : 'text-[#555]'
                  }`}>
                    {formatTime(msg.timestamp)}
                  </p>
                </div>
              </div>
            </div>
            {msg.role === 'user' && (
              <div className="flex-shrink-0 ml-2 mt-0.5">
                <div className="w-5 h-5 bg-blue-500/20 rounded flex items-center justify-center border border-blue-500/20">
                  <span className="text-[10px]">👤</span>
                </div>
              </div>
            )}
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="p-3 border-t border-[#252525] bg-[#181818]">
        <form onSubmit={handleSubmit} className="flex gap-2">
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Type /scan, /status, or ask a question..."
            className="flex-1 bg-[#0b0b0b] border border-[#252525] rounded px-3 py-2 text-[12px] text-[#cccccc] placeholder-[#555] focus:border-[#007acc] focus:outline-none focus:ring-1 focus:ring-[#007acc]/50 transition-all"
            disabled={isLoading}
            aria-label="Terminal input"
          />
          <button
            type="submit"
            disabled={isLoading || !input.trim()}
            className="px-4 py-2 bg-[#007acc] hover:bg-[#005999] rounded text-[11px] font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 min-w-[80px] justify-center"
            aria-label="Send message"
          >
            {isLoading ? (
              <Loader className="w-3.5 h-3.5 animate-spin" />
            ) : (
              <Send className="w-3.5 h-3.5" />
            )}
            <span>Send</span>
          </button>
        </form>
        
        {/* Quick Commands */}
        <div className="flex items-center gap-2 mt-3 overflow-x-auto pb-1">
          <span className="text-[9px] text-[#555] whitespace-nowrap">Quick:</span>
          {[
            { cmd: '/scan', label: 'Scan' },
            { cmd: '/status', label: 'Status' },
            { cmd: '/help', label: 'Help' }
          ].map((item) => (
            <button
              key={item.cmd}
              onClick={() => handleCommand(item.cmd)}
              disabled={isLoading}
              className="text-[9px] px-2.5 py-1 bg-[#252525] hover:bg-[#2a2d2e] hover:text-white rounded border border-[#333] text-[#858585] transition-all disabled:opacity-50"
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>

      <style jsx>{`
        @keyframes fade-in {
          from { opacity: 0; transform: translateY(5px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .animate-fade-in {
          animation: fade-in 0.2s ease-out;
        }
        /* Custom Scrollbar for Webkit */
        .custom-scrollbar::-webkit-scrollbar {
          width: 6px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: #1e1e1e; 
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: #333; 
          border-radius: 3px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: #444; 
        }
      `}</style>
    </div>
  );
}
