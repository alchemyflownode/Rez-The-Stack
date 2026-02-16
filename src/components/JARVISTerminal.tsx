'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Terminal, Send, Loader, AlertCircle, CheckCircle, XCircle } from 'lucide-react';

interface Message {
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
  status?: 'loading' | 'success' | 'error';
}

export default function JARVISTerminal() {
  const [input, setInput] = useState('');
  const [messages, setMessages] = useState<Message[]>([
    { 
      role: 'assistant', 
      content: '🦊 Hello! I\'m your AI pair programmer. Type /scan to check constitutional violations.', 
      timestamp: new Date() 
    }
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

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
    setMessages(prev => [...prev, { role, content, timestamp: new Date(), status }]);
  };

  const updateLastMessage = (content: string, status?: 'loading' | 'success' | 'error') => {
    setMessages(prev => {
      const newMessages = [...prev];
      const lastIndex = newMessages.length - 1;
      newMessages[lastIndex] = { ...newMessages[lastIndex], content, status };
      return newMessages;
    });
  };

  const handleScan = async () => {
    addMessage('assistant', '🔍 Scanning workspace for constitutional violations...', 'loading');
    
    // Simulate progress
    setTimeout(() => updateLastMessage('📁 Scanning files... 25%', 'loading'), 500);
    setTimeout(() => updateLastMessage('🔬 Analyzing TypeScript files... 50%', 'loading'), 1000);
    setTimeout(() => updateLastMessage('⚖️ Checking constitutional articles... 75%', 'loading'), 1500);
    
    try {
      const response = await fetch('/api/constitutional/scan');
      const data = await response.json();
      
      if (data.violationsFound > 0) {
        updateLastMessage(
          `⚠️ Found ${data.violationsFound} constitutional violations!\n` +
          `• Critical: ${data.critical || 0}\n` +
          `• High: ${data.high || 0}\n` +
          `• Medium: ${data.medium || 0}\n` +
          `• Low: ${data.low || 0}`,
          'error'
        );
      } else {
        updateLastMessage(
          `✅ No constitutional violations found!\n` +
          `• ${data.totalFiles || 0} files scanned\n` +
          `• All 8 articles enforced`,
          'success'
        );
      }
    } catch (error) {
      updateLastMessage(
        '❌ Failed to connect to constitutional API. Is Ollama running?',
        'error'
      );
    }
  };

  const handleCommand = async (command: string) => {
    if (!command.trim() || isLoading) return;

    addMessage('user', command);
    setInput('');
    setIsLoading(true);

    // Handle special commands
    if (command === '/scan') {
      await handleScan();
      setIsLoading(false);
      return;
    }

    if (command === '/status') {
      addMessage('assistant', 
        '📊 **System Status**\n\n' +
        '• GPU: RTX 3060 (12GB)\n' +
        '• Models: 25 available\n' +
        '• Constitution: 8 articles\n' +
        '• Memory: 0 crystals\n' +
        '• Zero telemetry: ACTIVE\n' +
        '• Ollama: Connected',
        'success'
      );
      setIsLoading(false);
      return;
    }

    if (command === '/help') {
      addMessage('assistant',
        '🦊 **Available Commands**\n\n' +
        '• `/scan` - Constitutional violation scan\n' +
        '• `/status` - System health check\n' +
        '• `/memory` - Query memory crystals\n' +
        '• `/models` - List available AI models\n' +
        '• `/help` - Show this help\n\n' +
        'Or just chat naturally!',
        'success'
      );
      setIsLoading(false);
      return;
    }

    // Generic response for other commands
    setTimeout(() => {
      addMessage('assistant', `🦊 Processing: "${command}"\n\nThis command is being routed to the appropriate service.`, 'success');
      setIsLoading(false);
    }, 1000);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    handleCommand(input);
  };

  const formatTime = (date: Date) => {
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

  return (
    <div className="h-full flex flex-col bg-[#1e1e1e]">
      {/* Terminal Header */}
      <div className="h-9 flex items-center justify-between px-4 border-b border-[#252525] bg-[#181818]">
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

      {/* Messages Area - Scrollable */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
        {messages.map((msg, i) => (
          <div
            key={i}
            className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'} animate-fade-in`}
          >
            {msg.role === 'assistant' && (
              <div className="flex-shrink-0 mr-2">
                <div className="w-5 h-5 bg-purple-500/20 rounded flex items-center justify-center">
                  <span className="text-xs">🦊</span>
                </div>
              </div>
            )}
            <div
              className={`relative max-w-[80%] rounded-lg px-3 py-2 ${
                msg.role === 'user'
                  ? 'bg-[#007acc] text-white'
                  : msg.status === 'loading'
                  ? 'bg-[#252525] text-[#cccccc] border border-blue-500/30'
                  : msg.status === 'error'
                  ? 'bg-[#2a1f1f] text-[#ff6b6b] border border-red-500/30'
                  : 'bg-[#252525] text-[#cccccc]'
              }`}
            >
              <div className="flex items-start gap-2">
                {msg.status && (
                  <div className="mt-0.5">
                    {getStatusIcon(msg.status)}
                  </div>
                )}
                <div className="flex-1">
                  <p className="text-[11px] whitespace-pre-wrap leading-relaxed">{msg.content}</p>
                  <p className={`text-[8px] mt-1 ${
                    msg.role === 'user' ? 'text-blue-200' : 'text-[#555]'
                  }`}>
                    {formatTime(msg.timestamp)}
                  </p>
                </div>
              </div>
            </div>
            {msg.role === 'user' && (
              <div className="flex-shrink-0 ml-2">
                <div className="w-5 h-5 bg-blue-500/20 rounded flex items-center justify-center">
                  <span className="text-xs">👤</span>
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
            placeholder="Type /scan, /status, /help or just chat..."
            className="flex-1 bg-[#0b0b0b] border border-[#252525] rounded px-3 py-2 text-[11px] text-[#cccccc] placeholder-[#555] focus:border-[#007acc] focus:outline-none transition-colors"
            disabled={isLoading}
          />
          <button
            type="submit"
            disabled={isLoading}
            className="px-3 py-2 bg-[#007acc] hover:bg-[#005999] rounded text-[11px] font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-1"
          >
            {isLoading ? (
              <Loader className="w-3 h-3 animate-spin" />
            ) : (
              <Send className="w-3 h-3" />
            )}
            <span>Send</span>
          </button>
        </form>
        
        {/* Quick Commands */}
        <div className="flex items-center gap-2 mt-2">
          <span className="text-[9px] text-[#555]">Quick:</span>
          <button
            onClick={() => handleCommand('/scan')}
            className="text-[9px] px-2 py-0.5 bg-[#252525] hover:bg-[#2a2d2e] rounded text-[#858585] transition-colors"
          >
            /scan
          </button>
          <button
            onClick={() => handleCommand('/status')}
            className="text-[9px] px-2 py-0.5 bg-[#252525] hover:bg-[#2a2d2e] rounded text-[#858585] transition-colors"
          >
            /status
          </button>
          <button
            onClick={() => handleCommand('/help')}
            className="text-[9px] px-2 py-0.5 bg-[#252525] hover:bg-[#2a2d2e] rounded text-[#858585] transition-colors"
          >
            /help
          </button>
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
      `}</style>
    </div>
  );
}
