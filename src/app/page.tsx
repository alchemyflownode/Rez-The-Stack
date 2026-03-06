'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CodeBlock } from '@/components/CodeBlock';
import { LoadingIndicator } from '@/components/LoadingIndicator';
import { RezHiveController } from '@/components/RezHiveController';
import ReactMarkdown from 'react-markdown';
import { getEncoding } from 'js-tiktoken'; 

// ============================================================================
// Types & Constants
// ============================================================================
interface Message { id: string; role: 'user' | 'ai' | 'system'; content: string; timestamp: string; worker?: string; model?: string; }
interface ServiceStatus { kernel: boolean; chroma: boolean; nextjs: boolean; }
interface WorkerInfo { id: string; name: string; icon: any; description: string; model?: string; }
interface SystemStats { cpu: number; ram: number; gpuTemp: number; networkUp: number; networkDown: number; }

const API_BASE = "http://localhost:8001";
const API_URL = `${API_BASE}/kernel/stream`;
const generateId = () => Math.random().toString(36).substring(2, 15);
const getTime = () => new Date().toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute:'2-digit', second:'2-digit' });

// ============================================================================
// Icons
// ============================================================================
const Icons = {
  Brain: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z"/><path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z"/></svg>,
  Eye: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>,
  Hand: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M18 11V6a2 2 0 0 0-4 0v4"/><path d="M14 10V4a2 2 0 0 0-4 0v6"/><path d="M10 10.5V2.5a2 2 0 0 0-4 0v11.5"/><path d="M6 14v-1a2 2 0 0 0-4 0v5a7 7 0 0 0 7 7h3a7 7 0 0 0 7-7v-5a2 2 0 0 0-4 0v1"/></svg>,
  Database: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M3 5V19A9 3 0 0 0 21 19V5"/><path d="M3 12A9 3 0 0 0 21 12"/></svg>,
  Command: () => <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>,
  Zap: () => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>,
  Activity: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>,
  Cpu: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="4" y="4" width="16" height="16" rx="2" ry="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>,
  HardDrive: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="22" y1="12" x2="2" y2="12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/><line x1="6" y1="16" x2="6.01" y2="16"/><line x1="10" y1="16" x2="10.01" y2="16"/></svg>,
  Terminal: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>,
  Shield: () => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>,
};

// Base UI Workers before backend sync
const BASE_WORKERS: WorkerInfo[] =[
  { id: 'auto', name: 'Orchestrator', icon: <Icons.Command />, description: 'Auto-Routing Intent Detection', model: 'llama3.2:latest' },
  { id: 'brain', name: 'Brain Worker', icon: <Icons.Brain />, description: 'Cognitive Reasoning', model: 'llama3.2:latest' },
  { id: 'search', name: 'Eyes Worker', icon: <Icons.Eye />, description: 'Network Analysis', model: 'llava:7b' },
  { id: 'code', name: 'Hands Worker', icon: <Icons.Hand />, description: 'Syntax Generation', model: 'qwen2.5-coder:14b' },
  { id: 'files', name: 'Memory Worker', icon: <Icons.Database />, description: 'Context Retrieval', model: 'llama3.2:latest' },
];

const MessageContent = ({ content }: { content: string }) => {
  return (
    <div className="prose prose-invert max-w-none 
      prose-p:text-[#D1D5DB] prose-p:leading-7 prose-p:mb-5 
      prose-headings:text-white prose-headings:font-semibold prose-headings:mb-4 prose-headings:mt-8
      prose-a:text-[#00E5FF] prose-a:no-underline hover:prose-a:underline
      prose-ul:list-disc prose-ul:pl-5 prose-ul:mb-6 prose-ul:space-y-2
      prose-ol:list-decimal prose-ol:pl-5 prose-ol:mb-6 prose-ol:space-y-2
      prose-li:text-[#D1D5DB] prose-li:leading-7
      prose-strong:text-white prose-strong:font-semibold
      marker:text-[#4B5563]">
      <ReactMarkdown
        components={{
          code({ node, inline, className, children, ...props }) {
            const match = /language-(\w+)/.exec(className || '');
            const language = match ? match[1] : 'text';
            const codeString = String(children).replace(/\n$/, '');
            if (!inline) return <CodeBlock language={language} code={codeString} />;
            return <code className="bg-[#2A2E38]/50 text-[#00E5FF] px-1.5 py-0.5 rounded-md font-mono text-[13px] border border-[#2A2E38]/50" {...props}>{children}</code>;
          },
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
};

export default function SovereignDashboard() {
  const[chatLog, setChatLog] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [workers, setWorkers] = useState<WorkerInfo[]>(BASE_WORKERS);
  const [selectedWorker, setSelectedWorker] = useState('auto');
  const [selectedModel, setSelectedModel] = useState('llama3.2:latest');
  const [sessionId, setSessionId] = useState<string | null>(null);
  const[services, setServices] = useState<ServiceStatus>({ kernel: false, chroma: false, nextjs: true });
  
  // PHASE 4 & 5: Tokenizer, Telemetry, and GPU Visualizer State
  const[tokenStats, setTokenStats] = useState({ current: 0, max: 8192 });
  const [stats, setStats] = useState<SystemStats>({ cpu: 0, ram: 0, gpuTemp: 45, networkUp: 0.0, networkDown: 0.0 });
  const [uptime, setUptime] = useState(0);
  const[gpuBars, setGpuBars] = useState<number[]>(Array(22).fill(20));
  
  const chatEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  // ===== SYNC WORKERS WITH BACKEND =====
  useEffect(() => {
    const fetchWorkers = async () => {
      try {
        const res = await fetch(`${API_BASE}/workers`);
        if (res.ok) {
          const data = await res.json();
          const syncedWorkers = BASE_WORKERS.map(bw => {
            const backendWorker = data.workers.find((w: any) => w.name === bw.id);
            if (backendWorker && backendWorker.model !== "unknown") {
              return { ...bw, model: backendWorker.model };
            }
            return bw;
          });
          setWorkers(syncedWorkers);
        }
      } catch (e) {
        console.warn("Could not sync workers from kernel. Using defaults.", e);
      }
    };
    fetchWorkers();
  },[]);

  // ===== HARDWARE TELEMETRY & UPTIME =====
  useEffect(() => {
    const eventSource = new EventSource(`${API_BASE}/kernel/telemetry`);
    
    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        setStats({
          cpu: data.cpu,
          ram: data.ram,
          gpuTemp: data.gpuTemp,
          networkDown: data.networkDown,
          networkUp: data.networkUp
        });
      } catch (e) {
        console.error("Telemetry parsing error", e);
      }
    };
    
    const timer = setInterval(() => setUptime(prev => prev + 1), 1000);

    return () => {
      eventSource.close();
      clearInterval(timer);
    };
  },[]);

  // ===== GPU ANIMATION LOOP (Prevents Hydration Errors) =====
  useEffect(() => {
    const animationLoop = setInterval(() => {
      setGpuBars(prev => prev.map(() => {
        const baseHeight = Math.max(20, stats.cpu);
        const variance = Math.random() * 40;
        return Math.min(100, baseHeight + variance);
      }));
    }, 1500);
    return () => clearInterval(animationLoop);
  }, [stats.cpu]);

  // ===== SESSION INITIALIZATION =====
  useEffect(() => {
    const initSession = async () => {
      try {
        const response = await fetch(`${API_BASE}/auth/session`, { method: 'POST', headers: { 'Content-Type': 'application/json' } });
        if (response.ok) {
          const data = await response.json();
          setSessionId(data.session_id);
        } else {
          setSessionId(`local-${generateId()}`);
        }
      } catch (error) { 
        setSessionId(`local-${generateId()}`); 
      }
    };
    initSession();
  },[]);

  // ===== TOKEN CALCULATOR =====
  useEffect(() => {
    try {
      const enc = getEncoding("cl100k_base");
      let total = 0;
      chatLog.forEach(m => { total += enc.encode(m.content).length; });
      setTokenStats(prev => ({ ...prev, current: total }));
    } catch (e) {
      setTokenStats(prev => ({ ...prev, current: Math.floor(chatLog.reduce((acc, m) => acc + m.content.length, 0) / 4) }));
    }
  }, [chatLog]);

  useEffect(() => { chatEndRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [chatLog]);

  // ===== HEALTH CHECK =====
  useEffect(() => {
    const checkServices = async () => {
      try {
        const kernel = await fetch(`${API_BASE}/health`, { method: 'GET', signal: AbortSignal.timeout(5000) });
        setServices(prev => ({ ...prev, kernel: kernel.ok }));
      } catch { setServices(prev => ({ ...prev, kernel: false })); }
    };
    checkServices();
    const interval = setInterval(checkServices, 10000);
    return () => clearInterval(interval);
  },[]);

  // ===== SUBMIT HANDLER =====
  const sendMessage = useCallback(async () => {
    const currentInput = input.trim();
    if (!currentInput || isLoading) return;

    if (currentInput === '/clear_chat') {
      setInput('');
      if (sessionId && !sessionId.startsWith('local-')) { 
        await fetch(`${API_BASE}/chat/${sessionId}/clear`, { method: 'POST' }); 
      }
      setChatLog([]);
      return;
    }

    const userMessage: Message = { id: generateId(), role: 'user', content: currentInput, timestamp: getTime(), worker: selectedWorker };
    setChatLog(prev => [...prev, userMessage]);
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
              if (data.status === 'started' && data.worker) {
                 setChatLog(prev => prev.map(msg => msg.id === aiMessageId ? { ...msg, worker: data.worker } : msg));
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
      setChatLog(prev => prev.map(msg => msg.id === aiMessageId ? { ...msg, content: `**CONNECTION OFFLINE**: Kernel unreachable.`, role: 'system' } : msg));
    } finally {
      setIsLoading(false);
      setTimeout(() => inputRef.current?.focus(), 50); // Ensure focus returns after render
    }
  },[input, isLoading, selectedWorker, selectedModel, sessionId]);

  const activeWorkerInfo = workers.find(w => w.id === selectedWorker) || workers[0];
  const tokenPercent = Math.min((tokenStats.current / tokenStats.max) * 100, 100);

  return (
    <div className="h-screen w-screen bg-[#050505] text-[#D1D5DB] flex overflow-hidden font-sans selection:bg-[#00E5FF]/30">
      
      {/* LEFT SIDEBAR */}
      <aside className="w-[260px] flex flex-col bg-[#050505] border-r border-[#1F222A] z-10 flex-shrink-0">
        <div className="h-16 flex items-center px-6 gap-3 border-b border-[#1F222A]">
          <div className="w-8 h-8 rounded bg-[#00E5FF] flex items-center justify-center text-black">
            <Icons.Zap />
          </div>
          <h1 className="text-xl font-bold text-white tracking-wide">REZ HIVE</h1>
        </div>

        <div className="flex-1 py-4 px-3 space-y-6 overflow-y-auto custom-scrollbar">
          <div>
            <h2 className="text-[10px] font-mono text-[#8A8F9B] uppercase tracking-widest mb-3 px-3">Active Protocols</h2>
            <div className="space-y-1">
              {workers.map(worker => {
                const isActive = selectedWorker === worker.id;
                return (
                  <button
                    key={worker.id}
                    onClick={() => { 
                      setSelectedWorker(worker.id); 
                      if (worker.model) setSelectedModel(worker.model); 
                    }}
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
          <div>
            <h2 className="text-[10px] font-mono text-[#8A8F9B] uppercase tracking-widest mb-3 px-3">System Directives</h2>
            <div className="space-y-1">
              {['/check_system', '/list_files', '/clear_chat'].map(cmd => (
                <button 
                  key={cmd} 
                  onClick={() => { setInput(cmd); inputRef.current?.focus(); }}
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

      {/* MAIN CENTER AREA */}
      <main className="flex-1 flex flex-col min-w-0 bg-[#0A0C10]">
        <header className="h-16 border-b border-[#1F222A] flex items-center justify-between px-6 bg-[#0E1015] flex-shrink-0">
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2 text-[#8A8F9B] text-xs font-bold tracking-widest uppercase"><Icons.Activity /> System Health</div>
            
            <div className="flex gap-6 text-sm">
              <div className="flex items-center gap-2"><div className="w-5 h-5 rounded bg-[#1A1D24] text-[#00E5FF] flex items-center justify-center"><Icons.Cpu /></div> <span className="font-mono text-white transition-all">{stats.cpu}%</span></div>
              <div className="flex items-center gap-2"><div className="w-5 h-5 rounded bg-[#1A1D24] text-[#B388FF] flex items-center justify-center"><Icons.HardDrive /></div> <span className="font-mono text-white transition-all">{stats.ram}%</span></div>
              <div className="flex items-center gap-2"><div className="w-5 h-5 rounded bg-[#1A1D24] text-[#FF9800] flex items-center justify-center"><Icons.Zap /></div> <span className="font-mono text-white transition-all">{stats.gpuTemp}°C</span></div>
              <div className="flex items-center gap-2"><div className="w-5 h-5 rounded bg-[#1A1D24] text-[#00E676] flex items-center justify-center"><Icons.Terminal /></div> <span className="font-mono text-white text-xs transition-all">{stats.networkDown} MB/s</span></div>
            </div>
          </div>
          <div className="flex items-center gap-6">
            <div className="flex flex-col items-end">
              <span className="text-[10px] text-[#8A8F9B] uppercase font-bold tracking-wider">Uptime</span>
              <span className="text-xs font-mono text-white" suppressHydrationWarning>{uptime}s</span>
            </div>
          </div>
        </header>

        <div className="flex-1 flex flex-col p-4 md:p-6 gap-4 overflow-hidden relative">
          <div className="flex-1 bg-[#0E1015] border border-[#1F222A] rounded-xl flex flex-col overflow-hidden relative shadow-2xl">
            <div className="h-12 border-b border-[#1F222A] flex items-center justify-between px-4 bg-[#12141A] flex-shrink-0">
              <div className="flex items-center gap-2 text-[#00E5FF] uppercase font-bold text-xs tracking-wider">
                {activeWorkerInfo.icon} {activeWorkerInfo.name.toUpperCase()}
              </div>
              <div className="flex items-center gap-3">
                <div className="px-3 py-1 rounded bg-[#1A1D24] border border-[#2A2E38] text-[10px] font-mono text-white/60 uppercase">
                  Engine: <span className="text-[#B388FF]">{selectedModel}</span>
                </div>
                {services.kernel ? (
                  <div className="flex items-center gap-2 text-[10px] font-bold tracking-wider uppercase text-[#00E676]">
                    <div className="w-2 h-2 rounded-full bg-[#00E676] animate-pulse shadow-[0_0_8px_#00E676]" /> Ready
                  </div>
                ) : (
                   <div className="flex items-center gap-2 text-[10px] font-bold tracking-wider uppercase text-red-500">
                    <div className="w-2 h-2 rounded-full bg-red-500 shadow-[0_0_8px_#ef4444]" /> Offline
                  </div>
                )}
              </div>
            </div>

            {/* Chat Area */}
            <div className="flex-1 overflow-y-auto custom-scrollbar p-6">
              {chatLog.length === 0 ? (
                <div className="h-full flex flex-col items-center justify-center text-[#4B5563] font-mono">
                  <div className="w-16 h-16 rounded-xl bg-[#1A1D24] border border-[#2A2E38] text-[#00E5FF] flex items-center justify-center mb-6 shadow-[0_0_30px_rgba(0,229,255,0.1)]">
                    <Icons.Command />
                  </div>
                  <h3 className="text-white text-lg mb-2">SYSTEM INITIALIZED</h3>
                  <div className="text-sm space-y-2 text-center text-[#8A8F9B]">
                    <p>Sovereign OS v2.0 Cognitive Engine Online.</p>
                    <p>Waiting for user input via {activeWorkerInfo.name}.</p>
                  </div>
                </div>
              ) : (
                <div className="space-y-6 max-w-4xl mx-auto pb-4">
                  <AnimatePresence mode="popLayout">
                    {chatLog.map((message) => {
                       const msgWorker = workers.find(w => w.id === message.worker) || activeWorkerInfo;
                       return (
                        <motion.div
                          key={message.id}
                          initial={{ opacity: 0, y: 10 }}
                          animate={{ opacity: 1, y: 0 }}
                          className={`flex flex-col gap-1.5 ${message.role === 'user' ? 'items-end' : 'items-start'}`}
                        >
                          <div className="flex items-center gap-2 text-[10px] font-mono uppercase tracking-widest text-[#8A8F9B] px-1">
                            {message.role === 'user' ? (
                              <><span suppressHydrationWarning>{message.timestamp}</span> <span className="text-[#4B5563]">•</span> <span className="text-white">Admin</span></>
                            ) : (
                              <><span className={message.role === 'system' ? 'text-[#FF9800]' : 'text-[#00E5FF]'}>{message.role === 'system' ? 'SYSTEM' : msgWorker.name}</span> <span className="text-[#4B5563]">•</span> <span suppressHydrationWarning>{message.timestamp}</span></>
                            )}
                          </div>

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
                      );
                    })}
                  </AnimatePresence>
                  <div ref={chatEndRef} />
                </div>
              )}
            </div>

            {/* Input Console */}
            <div className="p-4 bg-[#0E1015] border-t border-[#1F222A] flex-shrink-0">
              <div className="max-w-4xl mx-auto">
                <div className="relative group rounded-xl bg-[#12141A] border border-[#2A2E38] focus-within:border-[#00E5FF]/50 focus-within:shadow-[0_0_20px_rgba(0,229,255,0.05)] transition-all flex flex-col p-1.5">
                  <textarea
                    ref={inputRef}
                    value={input}
                    onChange={e => setInput(e.target.value)}
                    onKeyDown={e => {
                      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
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

      {/* RIGHT STATS PANELS */}
      <aside className="hidden xl:flex w-[320px] flex-col gap-6 p-6 pl-0 bg-[#0A0C10] overflow-y-auto custom-scrollbar flex-shrink-0">
        
        {/* LIVE NETWORK PANEL */}
        <div className="bg-[#0E1015] border border-[#1F222A] rounded-xl p-5 shadow-lg">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2 text-xs font-bold tracking-wider uppercase text-white">
              <div className="text-[#00E676]"><Icons.Terminal /></div> Network
            </div>
            <span className="text-[10px] text-[#00E676] font-mono uppercase">ACTIVE</span>
          </div>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-[10px] text-[#8A8F9B] mb-1.5 uppercase font-bold tracking-wider">
                <span>Download</span> <span className="font-mono text-white transition-all">{stats.networkDown} MB/s</span>
              </div>
              <div className="h-1 bg-[#1A1D24] rounded-full overflow-hidden relative">
                <div 
                  className="h-full bg-[#00E676] rounded-full transition-all duration-300 shadow-[0_0_8px_#00E676]" 
                  style={{ width: `${Math.min((stats.networkDown / 50) * 100, 100)}%` }} 
                />
              </div>
            </div>
            <div>
              <div className="flex justify-between text-[10px] text-[#8A8F9B] mb-1.5 uppercase font-bold tracking-wider">
                <span>Upload</span> <span className="font-mono text-white transition-all">{stats.networkUp} MB/s</span>
              </div>
              <div className="h-1 bg-[#1A1D24] rounded-full overflow-hidden relative">
                <div 
                  className="h-full bg-[#00E5FF] rounded-full transition-all duration-300 shadow-[0_0_8px_#00E5FF]" 
                  style={{ width: `${Math.min((stats.networkUp / 20) * 100, 100)}%` }} 
                />
              </div>
            </div>
          </div>
        </div>

        {/* MEMORY CONTEXT VISUALIZER */}
        <div className="flex-1 bg-[#0E1015] border border-[#1F222A] rounded-xl p-5 shadow-lg flex flex-col min-h-[200px]">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2 text-xs font-bold tracking-wider uppercase text-white">
              <div className="text-[#B388FF]"><Icons.Database /></div> Memory Context
            </div>
          </div>
          <div className="flex-1 rounded-lg border border-[#1F222A] bg-[#0A0C10] p-4 flex flex-col justify-center gap-4 relative overflow-hidden">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-24 h-24 bg-[#B388FF]/10 blur-2xl rounded-full pointer-events-none" />
            <div className="text-center z-10">
              <div className="text-3xl font-bold text-white mb-1 font-mono tracking-tight">
                {tokenStats.current.toLocaleString()} 
                <span className="block text-[10px] text-[#4B5563] font-normal uppercase tracking-widest mt-1">/ {tokenStats.max.toLocaleString()} TOKENS</span>
              </div>
            </div>
            <div className="z-10">
                <div className="flex justify-between text-[10px] text-[#8A8F9B] mb-1.5 font-mono">
                    <span>CAPACITY</span>
                    <span className={tokenPercent > 90 ? 'text-red-500' : 'text-[#B388FF]'}>{tokenPercent.toFixed(1)}%</span>
                </div>
                <div className="h-2 bg-[#1A1D24] rounded-full overflow-hidden w-full relative">
                <div 
                    className={`h-full absolute left-0 top-0 transition-all duration-500 ${tokenPercent > 90 ? 'bg-red-500 shadow-[0_0_10px_#ef4444]' : 'bg-gradient-to-r from-[#00E5FF] to-[#B388FF]'}`}
                    style={{ width: `${tokenPercent}%` }}
                />
                </div>
            </div>
          </div>
        </div>

        {/* LIVE GPU ENGINE LOAD VISUALIZER */}
        <div className="h-48 bg-[#0E1015] border border-[#1F222A] rounded-xl p-5 shadow-lg flex flex-col">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2 text-xs font-bold tracking-wider uppercase text-white">
              <div className="text-[#FF9800]"><Icons.Zap /></div> GPU Engine
            </div>
            <span className="text-xs text-[#FF9800] font-mono transition-all">{stats.gpuTemp}°C</span>
          </div>
          <div className="flex-1 flex items-end justify-between gap-1 pt-4">
            {gpuBars.map((height, i) => (
              <motion.div 
                key={i}
                className="w-full rounded-t-sm"
                animate={{ 
                  height: `${height}%`,
                  backgroundColor: height > 80 ? "#FF9800" : "rgba(255, 152, 0, 0.4)"
                }}
                transition={{ duration: 1.5, ease: "easeInOut" }}
              />
            ))}
          </div>
        </div>
      </aside>

      <RezHiveController />

      <style jsx global>{`
        .custom-scrollbar::-webkit-scrollbar { width: 5px; height: 5px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: #2A2E38; border-radius: 5px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: #4B5563; }
      `}</style>
    </div>
  );
}