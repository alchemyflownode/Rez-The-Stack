// src/app/page.tsx
'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CodeBlock } from '@/components/CodeBlock';
import { LoadingIndicator } from '@/components/LoadingIndicator';
import { RezHiveController } from '@/components/RezHiveController';
import ReactMarkdown from 'react-markdown';

// ============================================================================
// Types
// ============================================================================
interface Message {
  id: string; role: 'user' | 'ai' | 'system'; content: string; timestamp: string; worker?: string; model?: string; metadata?: any;
}
interface SessionUsage { current: number; weekly: number; total: number; }
interface ServiceStatus { kernel: boolean; chroma: boolean; nextjs: boolean; }
interface WorkerInfo { id: string; name: string; icon: any; description: string; model?: string; }

// ============================================================================
// Constants
// ============================================================================
const API_BASE = "http://localhost:8001";
const API_URL = `${API_BASE}/kernel/stream`;
const MAX_SESSION_MESSAGES = 100;
const MAX_WEEKLY_MESSAGES = 500;

const generateId = () => Math.random().toString(36).substring(2, 15);
const getTime = () => new Date().toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute:'2-digit', second:'2-digit' });
const getTimeUntilReset = () => {
  const now = new Date();
  const nextHour = new Date(now);
  nextHour.setHours(now.getHours() + 1, 0, 0, 0);
  const diff = nextHour.getTime() - now.getTime();
  const minutes = Math.floor(diff / 60000);
  const seconds = Math.floor((diff % 60000) / 1000);
  return `${minutes}m ${seconds}s`;
};

// ============================================================================
// Icons (Merged Set)
// ============================================================================
const Icons = {
  Brain: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z"/><path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z"/></svg>,
  Eye: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>,
  Hand: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M18 11V6a2 2 0 0 0-4 0v4"/><path d="M14 10V4a2 2 0 0 0-4 0v6"/><path d="M10 10.5V2.5a2 2 0 0 0-4 0v11.5"/><path d="M6 14v-1a2 2 0 0 0-4 0v5a7 7 0 0 0 7 7h3a7 7 0 0 0 7-7v-5a2 2 0 0 0-4 0v1"/></svg>,
  Database: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M3 5V19A9 3 0 0 0 21 19V5"/><path d="M3 12A9 3 0 0 0 21 12"/></svg>,
  Command: () => <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>,
  Zap: () => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>,
  Activity: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>,
  Cpu: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="4" width="16" height="16" rx="2" ry="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>,
  HardDrive: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="22" y1="12" x2="2" y2="12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/><line x1="6" y1="16" x2="6.01" y2="16"/><line x1="10" y1="16" x2="10.01" y2="16"/></svg>,
  Terminal: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>,
  Shield: () => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>,
  Settings: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
};

// ============================================================================
// Premium Markdown Renderer (from Neural UI)
// ============================================================================
const MessageContent = ({ content }: { content: string }) => {
  const [copiedCode, setCopiedCode] = useState<string | null>(null);

  const handleCopy = useCallback(async (code: string) => {
    try {
      await navigator.clipboard.writeText(code);
      setCopiedCode(code);
      setTimeout(() => setCopiedCode(null), 2000);
    } catch (err) {}
  },[]);

  return (
    <div className="prose prose-invert max-w-none prose-p:text-[#B4BBC5] prose-p:leading-relaxed prose-headings:text-[#00E5FF] prose-headings:font-medium prose-a:text-[#00E5FF] prose-li:text-[#B4BBC5]">
      <ReactMarkdown
        components={{
          code({ node, inline, className, children, ...props }) {
            const match = /language-(\w+)/.exec(className || '');
            const language = match ? match[1] : 'text';
            const codeString = String(children).replace(/\n$/, '');
            const isCopied = copiedCode === codeString;

            if (!inline) {
              return (
                <div className="my-5 relative group border border-[#2A2E38] rounded-xl overflow-hidden bg-[#0B0C10]">
                  <div className="flex items-center justify-between px-4 py-2 bg-[#1A1D24] border-b border-[#2A2E38]">
                    <span className="text-[10px] text-[#00E5FF] font-mono uppercase tracking-widest flex items-center gap-2">
                      <Icons.Command /> {language}
                    </span>
                    <button
                      onClick={() => handleCopy(codeString)}
                      className={`text-[10px] px-3 py-1 rounded-md transition-all font-mono uppercase tracking-wider ${
                        isCopied ? 'bg-[#00E676]/20 text-[#00E676] border border-[#00E676]/30' : 'bg-white/5 text-white/50 hover:text-white hover:bg-white/10 border border-transparent'
                      }`}
                    >
                      {isCopied ? 'COPIED' : 'COPY CODE'}
                    </button>
                  </div>
                  <div className="p-4 overflow-x-auto text-[13px] font-mono leading-relaxed custom-scrollbar">
                    <CodeBlock language={language} code={codeString} />
                  </div>
                </div>
              );
            }
            return (
              <code className="bg-[#1A1D24] text-[#00E5FF] px-1.5 py-0.5 rounded font-mono text-[13px] border border-[#2A2E38]" {...props}>
                {children}
              </code>
            );
          },
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
};

// ============================================================================
// Main Application (The Ultimate Merge)
// ============================================================================
export default function SovereignDashboard() {
  const [chatLog, setChatLog] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [selectedWorker, setSelectedWorker] = useState('brain');
  const[selectedModel, setSelectedModel] = useState('llama3.2');
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [services, setServices] = useState<ServiceStatus>({ kernel: false, chroma: false, nextjs: true });
  const [timeUntilReset, setTimeUntilReset] = useState('');
  
  const chatEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const workers: WorkerInfo[] =[
    { id: 'brain', name: 'Brain Worker', icon: <Icons.Brain />, description: 'Cognitive Reasoning', model: 'llama3.2' },
    { id: 'search', name: 'Eyes Worker', icon: <Icons.Eye />, description: 'Network Analysis' },
    { id: 'code', name: 'Hands Worker', icon: <Icons.Hand />, description: 'Syntax Generation', model: 'qwen2.5-coder:14b' },
    { id: 'files', name: 'Memory Worker', icon: <Icons.Database />, description: 'Context Retrieval' },
  ];

  // ===== EFFECTS =====
  useEffect(() => {
    const initSession = async () => {
      try {
        const existingSession = localStorage.getItem('rez_session_id');
        if (existingSession) {
          setSessionId(existingSession);
          try {
            const response = await fetch(`${API_BASE}/chat/${existingSession}/history`);
            if (response.ok) {
              const data = await response.json();
              if (data.messages && data.messages.length > 0) {
                setChatLog(data.messages.map((msg: any) => ({
                  id: generateId(), role: msg.role, content: msg.content, timestamp: msg.timestamp || getTime(), worker: msg.worker,
                })));
              }
            }
          } catch (e) {}
          return;
        }

        const response = await fetch(`${API_BASE}/auth/session`, { method: 'POST', headers: { 'Content-Type': 'application/json' } });
        if (response.ok) {
          const data = await response.json();
          setSessionId(data.session_id);
          localStorage.setItem('rez_session_id', data.session_id);
          if (data.token) localStorage.setItem('rez_token', data.token);
        }
      } catch (error) {
        const fallbackId = `local-${generateId()}`;
        setSessionId(fallbackId);
        localStorage.setItem('rez_session_id', fallbackId);
      }
    };
    initSession();
  },[]);

  useEffect(() => { chatEndRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [chatLog]);

  useEffect(() => {
    setTimeUntilReset(getTimeUntilReset());
    const interval = setInterval(() => setTimeUntilReset(getTimeUntilReset()), 1000);
    return () => clearInterval(interval);
  },[]);

  useEffect(() => {
    const checkServices = async () => {
      try {
        const kernel = await fetch(`${API_BASE}/health`, { method: 'GET', signal: AbortSignal.timeout(5000) });
        setServices(prev => ({ ...prev, kernel: kernel.ok }));
      } catch { setServices(prev => ({ ...prev, kernel: false })); }
      try {
        const chroma = await fetch('http://localhost:8000/api/v1/heartbeat', { method: 'GET', signal: AbortSignal.timeout(3000) });
        setServices(prev => ({ ...prev, chroma: chroma.ok }));
      } catch { setServices(prev => ({ ...prev, chroma: false })); }
    };
    checkServices();
    const interval = setInterval(checkServices, 10000);
    return () => clearInterval(interval);
  },[]);

  // ===== HANDLERS (Actual SSE Logic Restored) =====
  const sendMessage = useCallback(async () => {
    if (!input.trim() || isLoading) return;

    const userMessage: Message = { id: generateId(), role: 'user', content: input, timestamp: getTime(), worker: selectedWorker };
    setChatLog(prev =>[...prev, userMessage]);
    const currentInput = input;
    setInput('');
    setIsLoading(true);

    const aiMessageId = generateId();
    setChatLog(prev =>[...prev, { id: aiMessageId, role: 'ai', content: '', timestamp: getTime(), worker: selectedWorker, model: selectedModel }]);

    try {
      const response = await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Session-ID': sessionId || 'anonymous' },
        body: JSON.stringify({ task: currentInput, worker: selectedWorker, model: selectedModel, session_id: sessionId || 'anonymous' }),
      });

      if (!response.ok) {
        let errorMessage = `HTTP ${response.status}`;
        try {
          const errorData = await response.json();
          if (errorData.error) errorMessage = errorData.error;
        } catch {}
        setChatLog(prev => prev.map(msg => msg.id === aiMessageId ? { ...msg, content: `**SYSTEM ERROR**: ${errorMessage}`, role: 'system' } : msg));
        setIsLoading(false);
        return;
      }

      const reader = response.body?.getReader();
      if (!reader) throw new Error('No response body');

      const decoder = new TextDecoder();
      let accumulated = '';
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));
              if (data.error) {
                setChatLog(prev => prev.map(msg => msg.id === aiMessageId ? { ...msg, content: `**SYSTEM ERROR**: ${data.error}`, role: 'system' } : msg));
                setIsLoading(false);
                return;
              }
              if (data.content) {
                accumulated += data.content;
                setChatLog(prev => prev.map(msg => msg.id === aiMessageId ? { ...msg, content: accumulated } : msg));
              }
            } catch (e) { console.error('Error parsing SSE:', e); }
          }
        }
      }
    } catch (error) {
      setChatLog(prev => prev.map(msg => msg.id === aiMessageId ? { ...msg, content: `**CONNECTION OFFLINE**: Ensure kernel is running on port 8001.`, role: 'system' } : msg));
    } finally {
      setIsLoading(false);
      inputRef.current?.focus();
    }
  }, [input, isLoading, selectedWorker, selectedModel, sessionId]);

  const insertQuickCommand = (cmd: string) => {
    setInput(cmd);
    inputRef.current?.focus();
  };

  const activeWorkerInfo = workers.find(w => w.id === selectedWorker) || workers[0];

  return (
    <div className="h-screen w-screen bg-[#050505] text-[#D1D5DB] flex overflow-hidden font-sans selection:bg-[#00E5FF]/30">
      
      {/* ========================================== */}
      {/* LEFT SIDEBAR (Original + Directives)       */}
      {/* ========================================== */}
      <aside className="w-[260px] flex flex-col bg-[#050505] border-r border-[#1F222A] z-10 flex-shrink-0">
        <div className="h-16 flex items-center px-6 gap-3 border-b border-[#1F222A]">
          <div className="w-8 h-8 rounded bg-[#00E5FF] flex items-center justify-center text-black">
            <Icons.Zap />
          </div>
          <h1 className="text-xl font-bold text-white tracking-wide">REZ HIVE</h1>
        </div>

        <div className="flex-1 py-4 px-3 space-y-6 overflow-y-auto custom-scrollbar">
          {/* Active Protocols */}
          <div>
            <h2 className="text-[10px] font-mono text-[#8A8F9B] uppercase tracking-widest mb-3 px-3">Active Protocols</h2>
            <div className="space-y-1">
              {workers.map(worker => {
                const isActive = selectedWorker === worker.id;
                return (
                  <button
                    key={worker.id}
                    onClick={() => { setSelectedWorker(worker.id); if (worker.model) setSelectedModel(worker.model); }}
                    className={`w-full flex items-center gap-3 px-3 py-3 rounded-lg transition-all relative group ${
                      isActive ? 'bg-[#1A1D24] text-white' : 'text-[#8A8F9B] hover:bg-[#111318] hover:text-white'
                    }`}
                  >
                    <div className={`${isActive ? 'text-[#00E5FF]' : 'text-inherit group-hover:text-[#00E5FF]'}`}>{worker.icon}</div>
                    <div className="text-left flex-1">
                      <div className="font-medium text-sm">{worker.name}</div>
                      <div className="text-[10px] opacity-60 font-mono mt-0.5">{worker.description}</div>
                    </div>
                    {isActive && <div className="absolute right-3 w-1 h-4 bg-[#00E5FF] rounded-full shadow-[0_0_8px_#00E5FF]" />}
                  </button>
                );
              })}
            </div>
          </div>

          {/* System Directives (From Neural UI) */}
          <div>
            <h2 className="text-[10px] font-mono text-[#8A8F9B] uppercase tracking-widest mb-3 px-3">System Directives</h2>
            <div className="space-y-1">
              {['/check_system', '/list_files', '/clear_chat'].map(cmd => (
                <button 
                  key={cmd} 
                  onClick={() => insertQuickCommand(cmd)}
                  className="w-full text-left px-3 py-2 rounded-lg text-xs font-mono text-[#8A8F9B] hover:text-[#00E5FF] hover:bg-[#1A1D24] transition-colors flex items-center gap-2"
                >
                  <Icons.Command /> {cmd}
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className="p-4 mt-auto border-t border-[#1F222A]">
          <div className="bg-[#12141A] border border-[#1F222A] rounded-xl p-3 flex items-center gap-3">
            <div className="w-8 h-8 rounded bg-[#1A1D24] text-[#00E5FF] flex items-center justify-center">
              <Icons.Shield />
            </div>
            <div>
              <div className="text-[10px] text-[#8A8F9B] uppercase font-bold tracking-wider">Governor</div>
              <div className="text-xs text-[#00E5FF] font-medium tracking-wide">CONSTITUTIONAL</div>
            </div>
          </div>
        </div>
      </aside>

      {/* ========================================== */}
      {/* MAIN CENTER AREA                           */}
      {/* ========================================== */}
      <main className="flex-1 flex flex-col min-w-0 bg-[#0A0C10]">
        
        {/* Top Header Metrics (From Original Command Center) */}
        <header className="h-16 border-b border-[#1F222A] flex items-center justify-between px-6 bg-[#0E1015] flex-shrink-0">
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2 text-[#8A8F9B] text-xs font-bold tracking-widest uppercase">
              <Icons.Activity /> System Health
            </div>
            <div className="flex gap-6 text-sm">
              <div className="flex items-center gap-2"><div className="w-5 h-5 rounded bg-[#1A1D24] text-[#00E5FF] flex items-center justify-center"><Icons.Cpu /></div> <span className="font-mono text-white">18%</span></div>
              <div className="flex items-center gap-2"><div className="w-5 h-5 rounded bg-[#1A1D24] text-[#B388FF] flex items-center justify-center"><Icons.HardDrive /></div> <span className="font-mono text-white">58%</span></div>
              <div className="flex items-center gap-2"><div className="w-5 h-5 rounded bg-[#1A1D24] text-[#FF9800] flex items-center justify-center"><Icons.Zap /></div> <span className="font-mono text-white">16%</span></div>
              <div className="flex items-center gap-2"><div className="w-5 h-5 rounded bg-[#1A1D24] text-[#00E676] flex items-center justify-center"><Icons.Terminal /></div> <span className="font-mono text-white text-xs">14.69 MB/s</span></div>
            </div>
          </div>

          <div className="flex items-center gap-6">
            <div className="flex flex-col items-end">
              <span className="text-[10px] text-[#8A8F9B] uppercase font-bold tracking-wider">Uptime</span>
              <span className="text-xs font-mono text-white" suppressHydrationWarning>4947s</span>
            </div>
            <button className="text-[#8A8F9B] hover:text-white transition-colors"><Icons.Settings /></button>
          </div>
        </header>

        {/* Central Chat Interface */}
        <div className="flex-1 flex flex-col p-4 md:p-6 gap-4 overflow-hidden relative">
          <div className="flex-1 bg-[#0E1015] border border-[#1F222A] rounded-xl flex flex-col overflow-hidden relative shadow-2xl">
            
            {/* Window Header */}
            <div className="h-12 border-b border-[#1F222A] flex items-center justify-between px-4 bg-[#12141A] flex-shrink-0">
              <div className="flex items-center gap-2 text-[#00E5FF] uppercase font-bold text-xs tracking-wider">
                {activeWorkerInfo.icon} {activeWorkerInfo.name.toUpperCase()}
              </div>
              <div className="flex items-center gap-3">
                <div className="px-3 py-1 rounded bg-[#1A1D24] border border-[#2A2E38] text-[10px] font-mono text-white/60 uppercase">
                  Engine: <span className="text-[#B388FF]">{selectedModel}</span>
                </div>
                <div className="flex items-center gap-2 text-[10px] font-bold tracking-wider uppercase text-[#00E676]">
                  <div className="w-2 h-2 rounded-full bg-[#00E676] animate-pulse shadow-[0_0_8px_#00E676]" /> Ready
                </div>
              </div>
            </div>

            {/* Chat Area */}
            <div className="flex-1 overflow-y-auto custom-scrollbar p-6">
              {chatLog.length === 0 ? (
                /* Empty State (From Neural UI) */
                <div className="h-full flex flex-col items-center justify-center text-[#4B5563] font-mono">
                  <div className="w-16 h-16 rounded-xl bg-[#1A1D24] border border-[#2A2E38] text-[#00E5FF] flex items-center justify-center mb-6 shadow-[0_0_30px_rgba(0,229,255,0.1)]">
                    <Icons.Command />
                  </div>
                  <h3 className="text-white text-lg mb-2">SYSTEM INITIALIZED</h3>
                  <div className="text-sm space-y-2 text-center text-[#8A8F9B]">
                    <p>Sovereign OS v2.0 Cognitive Engine Online.</p>
                    <p>All subsystems optimal. Waiting for user input via {activeWorkerInfo.name}.</p>
                  </div>
                </div>
              ) : (
                <div className="space-y-6 max-w-4xl mx-auto pb-4">
                  <AnimatePresence mode="popLayout">
                    {chatLog.map((message) => (
                      <motion.div
                        key={message.id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className={`flex flex-col gap-1.5 ${message.role === 'user' ? 'items-end' : 'items-start'}`}
                      >
                        {/* Meta tag */}
                        <div className="flex items-center gap-2 text-[10px] font-mono uppercase tracking-widest text-[#8A8F9B] px-1">
                          {message.role === 'user' ? (
                            <><span suppressHydrationWarning>{message.timestamp}</span> <span className="text-[#4B5563]">•</span> <span className="text-white">Admin</span></>
                          ) : (
                            <><span className={message.role === 'system' ? 'text-[#FF9800]' : 'text-[#00E5FF]'}>{message.role === 'system' ? 'SYSTEM' : activeWorkerInfo.name}</span> <span className="text-[#4B5563]">•</span> <span suppressHydrationWarning>{message.timestamp}</span></>
                          )}
                        </div>

                        {/* Message Content (Neural UI style: Border-left, no bubbles) */}
                        <div className={`w-full max-w-[85%] relative ${
                          message.role === 'user' 
                            ? 'bg-[#12141A] border border-[#2A2E38] rounded-xl rounded-tr-sm p-4 text-white shadow-sm' 
                            : message.role === 'system'
                            ? 'border-l-2 border-[#FF9800] bg-gradient-to-r from-[#FF9800]/10 to-transparent p-4 text-[#FF9800] rounded-r-xl'
                            : 'border-l-2 border-[#00E5FF] bg-gradient-to-r from-[#00E5FF]/10 to-transparent p-4 text-white rounded-r-xl shadow-[inset_20px_0_40px_-20px_rgba(0,229,255,0.05)]'
                        }`}>
                          {message.content ? (
                            <MessageContent content={message.content} />
                          ) : (
                            <div className="flex items-center gap-3 text-[#00E5FF] font-mono text-xs">
                              <LoadingIndicator /> Computing response...
                            </div>
                          )}
                        </div>
                      </motion.div>
                    ))}
                  </AnimatePresence>
                  <div ref={chatEndRef} />
                </div>
              )}
            </div>

            {/* Input Console (From Neural UI) */}
            <div className="p-4 bg-[#0E1015] border-t border-[#1F222A] flex-shrink-0">
              <div className="max-w-4xl mx-auto">
                <div className="relative group rounded-xl bg-[#12141A] border border-[#2A2E38] focus-within:border-[#00E5FF]/50 focus-within:shadow-[0_0_20px_rgba(0,229,255,0.05)] transition-all flex flex-col p-1.5">
                  <textarea
                    ref={inputRef}
                    value={input}
                    onChange={e => setInput(e.target.value)}
                    onKeyDown={e => {
                      if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        sendMessage();
                      }
                    }}
                    placeholder={`Transmit command to ${activeWorkerInfo.name}...`}
                    className="w-full bg-transparent border-none outline-none text-white placeholder:text-[#4B5563] text-sm px-3 py-2.5 resize-none max-h-32 min-h-[44px] custom-scrollbar font-mono"
                    rows={1}
                    disabled={isLoading}
                  />
                  
                  <div className="flex items-center justify-between px-2 pt-1 border-t border-[#1F222A] mt-1">
                    <div className="flex items-center gap-3 text-[10px] font-mono text-[#4B5563] uppercase tracking-widest">
                      <span>Shift + Enter for newline</span>
                    </div>
                    
                    <button
                      onClick={sendMessage}
                      disabled={isLoading || !input.trim()}
                      className="px-5 py-1.5 rounded bg-[#1A1D24] text-[#00E5FF] text-[10px] font-bold font-mono tracking-widest uppercase transition-all disabled:opacity-30 hover:bg-[#00E5FF] hover:text-black border border-[#2A2E38] hover:border-[#00E5FF]"
                    >
                      {isLoading ? 'Executing...' : 'Transmit'}
                    </button>
                  </div>
                </div>
              </div>
            </div>

          </div>
        </div>
      </main>

      {/* ========================================== */}
      {/* RIGHT STATS PANELS (Original Command Center) */}
      {/* ========================================== */}
      <aside className="hidden xl:flex w-[320px] flex-col gap-6 p-6 pl-0 bg-[#0A0C10] overflow-y-auto custom-scrollbar flex-shrink-0">
        
        {/* Network Panel */}
        <div className="bg-[#0E1015] border border-[#1F222A] rounded-xl p-5 shadow-lg">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2 text-xs font-bold tracking-wider uppercase text-white">
              <div className="text-[#00E676]"><Icons.Terminal /></div> Network
            </div>
            <span className="text-[10px] text-[#00E676] font-mono uppercase">38 Active</span>
          </div>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-[10px] text-[#8A8F9B] mb-1.5 uppercase font-bold tracking-wider">
                <span>Download</span> <span className="font-mono text-white">14.69 MB/s</span>
              </div>
              <div className="h-1 bg-[#1A1D24] rounded-full overflow-hidden">
                <div className="h-full bg-[#00E676] w-[75%] shadow-[0_0_8px_#00E676]" />
              </div>
            </div>
            <div>
              <div className="flex justify-between text-[10px] text-[#8A8F9B] mb-1.5 uppercase font-bold tracking-wider">
                <span>Upload</span> <span className="font-mono text-white">0.38 MB/s</span>
              </div>
              <div className="h-1 bg-[#1A1D24] rounded-full overflow-hidden">
                <div className="h-full bg-[#00E5FF] w-[15%] shadow-[0_0_8px_#00E5FF]" />
              </div>
            </div>
          </div>
        </div>

        {/* Memory Context Panel */}
        <div className="flex-1 bg-[#0E1015] border border-[#1F222A] rounded-xl p-5 shadow-lg flex flex-col min-h-[200px]">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2 text-xs font-bold tracking-wider uppercase text-white">
              <div className="text-[#B388FF]"><Icons.Database /></div> Memory Context
            </div>
            <button className="text-[10px] text-[#B388FF] font-mono uppercase hover:text-white transition-colors">View All</button>
          </div>
          <div className="flex-1 rounded-lg border border-[#1F222A] bg-[#0A0C10] p-4 flex flex-col items-center justify-center text-center gap-2">
             <div className="text-[#2A2E38]"><Icons.Database /></div>
             <span className="text-[#4B5563] text-xs font-mono">Context window empty.<br/> Awaiting data injection.</span>
          </div>
        </div>

        {/* GPU Engine Panel */}
        <div className="h-48 bg-[#0E1015] border border-[#1F222A] rounded-xl p-5 shadow-lg flex flex-col">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2 text-xs font-bold tracking-wider uppercase text-white">
              <div className="text-[#FF9800]"><Icons.Zap /></div> GPU Engine
            </div>
            <span className="text-xs text-[#FF9800] font-mono">52°C</span>
          </div>
          <div className="flex-1 flex items-end justify-between gap-1 pt-4">
            {[30,40,70,80,45,40,30,60,85,30,20,55,90,40,35,70,60,30,80,65,40,20].map((h, i) => (
              <div key={i} className="w-full bg-[#FF9800] rounded-t-sm opacity-80" style={{ height: `${h}%` }} />
            ))}
          </div>
        </div>
      </aside>

      {/* Global PS1 Controller */}
      <RezHiveController />

      {/* Custom Scrollbar Global Styles */}
      <style jsx global>{`
        .custom-scrollbar::-webkit-scrollbar { width: 5px; height: 5px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: #2A2E38; border-radius: 5px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: #4B5563; }
      `}</style>
    </div>
  );
}
