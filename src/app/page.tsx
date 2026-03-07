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
interface ServiceStatus { kernel: boolean; chroma: boolean; nextjs: boolean; mcp: boolean; }
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
  Brain: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z"/><path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z"/></svg>,
  Eye: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>,
  Hand: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M18 11V6a2 2 0 0 0-4 0v4"/><path d="M14 10V4a2 2 0 0 0-4 0v6"/><path d="M10 10.5V2.5a2 2 0 0 0-4 0v11.5"/><path d="M6 14v-1a2 2 0 0 0-4 0v5a7 7 0 0 0 7 7h3a7 7 0 0 0 7-7v-5a2 2 0 0 0-4 0v1"/></svg>,
  Database: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M3 5V19A9 3 0 0 0 21 19V5"/><path d="M3 12A9 3 0 0 0 21 12"/></svg>,
  Command: () => <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>,
  Zap: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>,
  Activity: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>,
  Cpu: () => <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="4" y="4" width="16" height="16" rx="2" ry="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>,
  HardDrive: () => <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="22" y1="12" x2="2" y2="12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/><line x1="6" y1="16" x2="6.01" y2="16"/><line x1="10" y1="16" x2="10.01" y2="16"/></svg>,
  Terminal: () => <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>,
  Shield: () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>,
  Cloud: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>,
  Apps: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="2" y="2" width="8" height="8"/><rect x="14" y="2" width="8" height="8"/><rect x="2" y="14" width="8" height="8"/><rect x="14" y="14" width="8" height="8"/></svg>,
  Video: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="m22 8-6 4 6 4V8Z"/><rect x="2" y="6" width="14" height="12" rx="2" ry="2"/></svg>,
  Mic: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>,
  Network: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="16" y="16" width="6" height="6" rx="1"/><rect x="2" y="16" width="6" height="6" rx="1"/><rect x="9" y="2" width="6" height="6" rx="1"/><path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"/><path d="M12 12V8"/></svg>,
  Paperclip: () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/></svg>
};

// Base UI Workers
const BASE_WORKERS: WorkerInfo[] =[
  { id: 'auto', name: 'Orchestrator', icon: <Icons.Command />, description: 'Auto-Routing Intent Detection', model: 'llama3.2:latest' },
  { id: 'brain', name: 'Brain Worker', icon: <Icons.Brain />, description: 'Cognitive Reasoning', model: 'llama3.2:latest' },
  { id: 'search', name: 'Eyes Worker', icon: <Icons.Eye />, description: 'Network Analysis', model: 'llama3.2:latest' },
  { id: 'code', name: 'Hands Worker', icon: <Icons.Hand />, description: 'Syntax Generation', model: 'qwen2.5-coder:14b' },
  { id: 'files', name: 'Memory Worker', icon: <Icons.Database />, description: 'Context Retrieval', model: 'llama3.2:latest' },
  { id: 'vision', name: 'Vision Worker', icon: <Icons.Video />, description: 'Screen Analysis', model: 'llava:7b' },
  { id: 'voice', name: 'Voice Worker', icon: <Icons.Mic />, description: 'Speech Recognition', model: 'whisper' },
  { id: 'cloud', name: 'Cloud Worker', icon: <Icons.Cloud />, description: 'Gemini Overdrive', model: 'gemini-1.5-pro' },
  { id: 'apps', name: 'Apps Worker', icon: <Icons.Apps />, description: 'Gemini App Integration', model: 'gemini-1.5-pro' },
];

const MessageContent = ({ content }: { content: string }) => {
  return (
    <div className="prose prose-invert max-w-none 
      prose-p:text-[#D1D5DB] prose-p:leading-relaxed prose-p:mb-4 
      prose-headings:text-white prose-headings:font-semibold prose-headings:mb-4 prose-headings:mt-6
      prose-a:text-[#00E5FF] prose-a:no-underline hover:prose-a:underline
      prose-ul:list-disc prose-ul:pl-5 prose-ul:mb-5 prose-ul:space-y-1.5
      prose-ol:list-decimal prose-ol:pl-5 prose-ol:mb-5 prose-ol:space-y-1.5
      prose-li:text-[#D1D5DB] prose-li:leading-relaxed
      prose-strong:text-white prose-strong:font-semibold
      prose-td:border prose-td:border-[#2A2E38] prose-td:p-2 prose-th:border prose-th:border-[#2A2E38] prose-th:p-2
      marker:text-[#4B5563]">
      <ReactMarkdown
        components={{
          code({ node, inline, className, children, ...props }) {
            const match = /language-(\w+)/.exec(className || '');
            const language = match ? match[1] : 'text';
            const codeString = String(children).replace(/\n$/, '');
            if (!inline) return <CodeBlock language={language} code={codeString} />;
            return <code className="bg-[#2A2E38]/50 text-[#00E5FF] px-1.5 py-0.5 rounded text-[13px] font-mono border border-[#2A2E38]/50 shadow-sm" {...props}>{children}</code>;
          },
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
};

export default function SovereignDashboard() {
  const [uiMode, setUiMode] = useState<'developer' | 'business' | 'focus'>('business');
  const[chatLog, setChatLog] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [workers, setWorkers] = useState<WorkerInfo[]>(BASE_WORKERS);
  const [selectedWorker, setSelectedWorker] = useState('auto');
  const [selectedModel, setSelectedModel] = useState('llama3.2:latest');
  const[sessionId, setSessionId] = useState<string | null>(null);
  const [services, setServices] = useState<ServiceStatus>({ kernel: false, chroma: false, nextjs: true, mcp: true });
  
  const[tokenStats, setTokenStats] = useState({ current: 0, max: 8192 });
  const[stats, setStats] = useState<SystemStats>({ cpu: 0, ram: 0, gpuTemp: 45, networkUp: 0.0, networkDown: 0.0 });
  const[uptime, setUptime] = useState(0);
  const [gpuBars, setGpuBars] = useState<number[]>(Array(22).fill(20));
  const[uploadedFiles, setUploadedFiles] = useState<string[]>([]);
  
  const chatEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Sync Workers
  useEffect(() => {
    const fetchWorkers = async () => {
      try {
        const res = await fetch(`${API_BASE}/workers`);
        if (res.ok) {
          const data = await res.json();
          const syncedWorkers = BASE_WORKERS.map(bw => {
            const backendWorker = data.workers.find((w: any) => w.name === bw.id);
            if (backendWorker && backendWorker.model !== "unknown") return { ...bw, model: backendWorker.model };
            return bw;
          });
          setWorkers(syncedWorkers);
        }
      } catch (e) { console.warn("Could not sync workers. Using defaults."); }
    };
    fetchWorkers();
  },[]);

  // Telemetry & Uptime
  useEffect(() => {
    const eventSource = new EventSource(`${API_BASE}/kernel/telemetry`);
    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        setStats({ cpu: data.cpu, ram: data.ram, gpuTemp: data.gpuTemp, networkDown: data.networkDown, networkUp: data.networkUp });
      } catch (e) { console.error("Telemetry error", e); }
    };
    const timer = setInterval(() => setUptime(prev => prev + 1), 1000);
    return () => { eventSource.close(); clearInterval(timer); };
  },[]);

  // GPU Animation Loop
  useEffect(() => {
    const animationLoop = setInterval(() => {
      setGpuBars(prev => prev.map(() => {
        const baseHeight = Math.max(20, stats.cpu);
        const variance = Math.random() * 40;
        return Math.min(100, baseHeight + variance);
      }));
    }, 800);
    return () => clearInterval(animationLoop);
  },[stats.cpu]);

  // Session
  useEffect(() => {
    const initSession = async () => {
      try {
        const response = await fetch(`${API_BASE}/auth/session`, { method: 'POST', headers: { 'Content-Type': 'application/json' } });
        if (response.ok) {
          const data = await response.json();
          setSessionId(data.session_id);
        } else setSessionId(`local-${generateId()}`);
      } catch (error) { setSessionId(`local-${generateId()}`); }
    };
    initSession();
  },[]);

  // Token Calculator
  useEffect(() => {
    try {
      const enc = getEncoding("cl100k_base");
      let total = 0;
      chatLog.forEach(m => { total += enc.encode(m.content).length; });
      setTokenStats(prev => ({ ...prev, current: total }));
    } catch (e) {
      setTokenStats(prev => ({ ...prev, current: Math.floor(chatLog.reduce((acc, m) => acc + m.content.length, 0) / 4) }));
    }
  },[chatLog]);

  useEffect(() => { chatEndRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [chatLog]);

  // Health Check
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

  // Handle File Upload
  const handleFileUpload = async (file: File) => {
    // Show immediate feedback
    setChatLog(prev =>[...prev, {
      id: generateId(),
      role: 'system',
      content: `📤 **Uploading** \`${file.name}\`...`,
      timestamp: getTime()
    }]);
  
    const formData = new FormData();
    formData.append('file', file);
    
    try {
      const response = await fetch(`${API_BASE}/kernel/upload`, {
        method: 'POST',
        body: formData,
        headers: {
          'Accept': 'application/json',
        },
      });
      
      if (!response.ok) {
        const error = await response.text();
        throw new Error(error);
      }
      
      const data = await response.json();
      
      // Update UI state to show active file
      setUploadedFiles(prev => Array.from(new Set([...prev, data.filename])));
      
      // Show success message with file info
      setChatLog(prev =>[...prev, {
        id: generateId(),
        role: 'system',
        content: `📎 **File Ready for Analysis**: \`${data.filename}\`\n` +
                 `- Size: ${(data.size / 1024).toFixed(2)} KB\n` +
                 `- Rows: ${data.rows?.toLocaleString() || 'Unknown'}\n` +
                 `- Type: ${data.type}\n\n` +
                 `**Try asking:**\n` +
                 `• "Analyze ${data.filename}"\n` +
                 `• "Show me trends in ${data.filename}"\n` +
                 `• "Forecast next quarter from ${data.filename}"\n` +
                 `• "Compare segments in ${data.filename}"`,
        timestamp: getTime()
      }]);
      
    } catch (error: any) {
      setChatLog(prev =>[...prev, {
        id: generateId(),
        role: 'system',
        content: `❌ **Upload Failed**: ${error.message}\n\nSupported files: Excel (.xlsx, .xls) and CSV`,
        timestamp: getTime()
      }]);
    }
  };

  // Send Message
  const sendMessage = useCallback(async () => {
    const currentInput = input.trim();
    if (!currentInput || isLoading) return;
  
    // Handle clear chat command
    if (currentInput === '/clear_chat') {
      setInput('');
      if (sessionId && !sessionId.startsWith('local-')) { 
        await fetch(`${API_BASE}/chat/${sessionId}/clear`, { method: 'POST' }); 
      }
      setChatLog([]);
      return;
    }
  
    // DETECT FILE ANALYSIS COMMANDS
    const fileAnalysisMatch = currentInput.match(/(analyze|show|trends?|forecast|predict|compare|vs|summarize|find|query).*?([\w\-\.]+\.(xlsx|xls|csv))/i);
    
    if (fileAnalysisMatch) {
      const action = fileAnalysisMatch[1].toLowerCase();
      const filename = fileAnalysisMatch[2];
      
      // Determine analysis type based on user intent
      let analysisType = 'summary';
      if (action.includes('trend')) analysisType = 'trends';
      else if (action.includes('forecast') || action.includes('predict')) analysisType = 'forecast';
      else if (action.includes('compar') || action.includes('vs')) analysisType = 'comparison';
      else if (action.includes('quer') || action.includes('find')) analysisType = 'query';
      
      // Create user message
      const userMessage: Message = { 
        id: generateId(), 
        role: 'user', 
        content: currentInput, 
        timestamp: getTime(), 
        worker: selectedWorker 
      };
      setChatLog(prev =>[...prev, userMessage]);
      setInput('');
      setIsLoading(true);
  
      // Create AI message placeholder
      const aiMessageId = generateId();
      setChatLog(prev =>[...prev, { 
        id: aiMessageId, 
        role: 'ai', 
        content: '', 
        timestamp: getTime(), 
        worker: 'files', 
        model: selectedModel 
      }]);
  
      try {
        // Call the analyze endpoint
        const response = await fetch(`${API_BASE}/kernel/analyze`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            filename: filename,
            analysis_type: analysisType,
            query: currentInput // Pass full query for context
          })
        });
  
        const data = await response.json();
        
        if (data.error) {
          setChatLog(prev => prev.map(msg => 
            msg.id === aiMessageId ? { 
              ...msg, 
              content: `❌ **Analysis Failed**: ${data.error}\n\nPlease upload the file first using the 📎 button.`, 
              role: 'system' 
            } : msg
          ));
        } else {
          // Stream the content word by word for effect
          const words = data.content.split(' ');
          let accumulated = '';
          
          for (const word of words) {
            accumulated += word + ' ';
            setChatLog(prev => prev.map(msg => 
              msg.id === aiMessageId ? { ...msg, content: accumulated } : msg
            ));
            await new Promise(r => setTimeout(r, 30)); // Typing effect
          }
        }
      } catch (error) {
        setChatLog(prev => prev.map(msg => 
          msg.id === aiMessageId ? { 
            ...msg, 
            content: `❌ **Connection Error**: Could not reach analysis engine.\n\nMake sure the backend is running on port 8001.`, 
            role: 'system' 
          } : msg
        ));
      } finally {
        setIsLoading(false);
        setTimeout(() => inputRef.current?.focus(), 50);
      }
      return;
    }
  
    // --- STANDARD CHAT FLOW ---
    const userMessage: Message = { id: generateId(), role: 'user', content: currentInput, timestamp: getTime(), worker: selectedWorker };
    setChatLog(prev =>[...prev, userMessage]);
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
            } catch (e) {}
          }
        }
      }
    } catch (error) {
      setChatLog(prev => prev.map(msg => msg.id === aiMessageId ? { ...msg, content: `**CONNECTION OFFLINE**: Kernel unreachable.`, role: 'system' } : msg));
    } finally {
      setIsLoading(false);
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  },[input, isLoading, selectedWorker, selectedModel, sessionId]);

  const activeWorkerInfo = workers.find(w => w.id === selectedWorker) || workers[0];
  const tokenPercent = Math.min((tokenStats.current / tokenStats.max) * 100, 100);

  return (
    <div className="h-screen w-screen bg-[#050505] text-[#D1D5DB] flex overflow-hidden font-sans selection:bg-[#00E5FF]/30 relative">
      
      {/* GLOBAL BACKGROUND GLOW */}
      <div className="absolute inset-0 pointer-events-none bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-[#00E5FF]/[0.02] via-[#050505] to-[#050505] z-0" />

      {/* LEFT SIDEBAR (Hidden in Focus Mode) */}
      {uiMode !== 'focus' && (
        <aside className="w-[260px] flex flex-col bg-[#050505]/90 backdrop-blur-xl border-r border-[#1F222A] z-20 flex-shrink-0 relative">
          <div className="h-16 flex items-center px-6 gap-3 border-b border-[#1F222A]">
            <div className="w-8 h-8 rounded bg-[#00E5FF] flex items-center justify-center text-black shadow-[0_0_15px_rgba(0,229,255,0.4)]">
              <Icons.Zap />
            </div>
            <h1 className="text-xl font-bold text-white tracking-wider">REZ HIVE</h1>
          </div>

          <div className="flex-1 py-4 px-3 space-y-8 overflow-y-auto custom-scrollbar">
            <div>
              <h2 className="text-[10px] font-mono text-[#8A8F9B] uppercase tracking-[0.2em] mb-3 px-3">
                {uiMode === 'business' ? 'Capabilities' : 'Active Protocols'}
              </h2>
              <div className="space-y-1.5">
                {workers.map(worker => {
                  const isActive = selectedWorker === worker.id;
                  let displayName = worker.name;
                  let displayDesc = worker.description;
                  if (uiMode === 'business') {
                    if (worker.id === 'files') { displayName = 'Company Knowledge'; displayDesc = 'Search internal files'; }
                    if (worker.id === 'search') { displayName = 'Web Research'; displayDesc = 'Live data analysis'; }
                    if (worker.id === 'code') { displayName = 'Automation Tools'; displayDesc = 'Execute workflows'; }
                  }

                  return (
                    <button
                      key={worker.id}
                      onClick={() => { setSelectedWorker(worker.id); if (worker.model) setSelectedModel(worker.model); }}
                      className={`w-full flex items-center gap-3 px-3 py-3 rounded-lg transition-all duration-300 relative group overflow-hidden ${
                        isActive ? 'bg-[#12141A] border border-[#2A2E38] shadow-[0_4px_20px_rgba(0,0,0,0.5)]' : 'border border-transparent hover:bg-[#0E1015]'
                      }`}
                    >
                      {isActive && <div className="absolute inset-0 bg-gradient-to-r from-[#00E5FF]/5 to-transparent pointer-events-none" />}
                      <div className={`${isActive ? 'text-[#00E5FF] drop-shadow-[0_0_8px_rgba(0,229,255,0.8)]' : 'text-[#8A8F9B] group-hover:text-white transition-colors'}`}>
                        {worker.icon}
                      </div>
                      <div className="text-left flex-1 z-10">
                        <div className={`font-medium text-sm tracking-wide ${isActive ? 'text-white' : 'text-[#8A8F9B] group-hover:text-white'}`}>{displayName}</div>
                        <div className="text-[10px] opacity-60 font-mono mt-0.5">{displayDesc}</div>
                      </div>
                      {isActive && <motion.div layoutId="active-pill" className="absolute right-2 w-1.5 h-1.5 bg-[#00E5FF] rounded-full shadow-[0_0_10px_#00E5FF]" />}
                    </button>
                  );
                })}
              </div>
            </div>
            
            {uiMode === 'developer' && (
              <div>
                <h2 className="text-[10px] font-mono text-[#8A8F9B] uppercase tracking-[0.2em] mb-3 px-3">System Directives</h2>
                <div className="space-y-1">
                  {['/check_system', '/list_files', '/clear_chat'].map(cmd => (
                    <button 
                      key={cmd} 
                      onClick={() => { setInput(cmd); inputRef.current?.focus(); }}
                      className="w-full text-left px-3 py-2.5 rounded-lg text-[11px] font-mono text-[#8A8F9B] hover:text-[#00E5FF] hover:bg-[#12141A] transition-colors flex items-center gap-2.5 border border-transparent hover:border-[#1F222A]"
                    >
                      <Icons.Command /> {cmd}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
          <div className="p-4 mt-auto border-t border-[#1F222A] bg-[#050505]">
            <div className="bg-[#0E1015] border border-[#1F222A] rounded-xl p-3 flex items-center gap-3 relative overflow-hidden group">
              <div className="absolute inset-0 bg-gradient-to-r from-[#00E5FF]/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="w-8 h-8 rounded bg-[#1A1D24] text-[#00E5FF] flex items-center justify-center border border-[#2A2E38]">
                <Icons.Shield />
              </div>
              <div className="z-10">
                <div className="text-[9px] text-[#8A8F9B] uppercase font-bold tracking-[0.15em]">Governor</div>
                <div className="text-xs text-[#00E5FF] font-medium tracking-wide drop-shadow-[0_0_5px_rgba(0,229,255,0.3)]">CONSTITUTIONAL</div>
              </div>
            </div>
          </div>
        </aside>
      )}

      {/* MAIN CENTER AREA */}
      <main className="flex-1 flex flex-col min-w-0 bg-[#0A0C10] relative z-10">
        
        {/* TOP HEADER HUD */}
        <header className="h-16 border-b border-[#1F222A] flex items-center justify-between px-6 bg-[#0A0C10]/80 backdrop-blur-md sticky top-0 z-30 flex-shrink-0">
          <div className="flex items-center gap-8">
            <div className="flex items-center gap-2 text-[#8A8F9B] text-xs font-bold tracking-[0.15em] uppercase">
              <Icons.Activity /> {uiMode === 'developer' ? 'System Health' : 'AI Workspace'}
            </div>
            
            {uiMode === 'developer' && (
              <div className="flex gap-6 text-[13px]">
                <div className="flex items-center gap-2">
                  <div className="w-5 h-5 rounded bg-[#12141A] border border-[#1F222A] text-[#00E5FF] flex items-center justify-center"><Icons.Cpu /></div> 
                  <span className={`font-mono transition-colors duration-300 w-8 ${stats.cpu > 80 ? 'text-[#FF4500] drop-shadow-[0_0_5px_#FF4500]' : 'text-white'}`}>{stats.cpu}%</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-5 h-5 rounded bg-[#12141A] border border-[#1F222A] text-[#B388FF] flex items-center justify-center"><Icons.HardDrive /></div> 
                  <span className={`font-mono transition-colors duration-300 w-8 ${stats.ram > 85 ? 'text-[#FF4500]' : 'text-white'}`}>{stats.ram}%</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-5 h-5 rounded bg-[#12141A] border border-[#1F222A] text-[#FF9800] flex items-center justify-center"><Icons.Zap /></div> 
                  <span className="font-mono text-white transition-colors duration-300 w-10">{stats.gpuTemp}°C</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-5 h-5 rounded bg-[#12141A] border border-[#1F222A] text-[#00E676] flex items-center justify-center"><Icons.Terminal /></div> 
                  <span className="font-mono text-white text-xs transition-colors duration-300 w-16">{stats.networkDown} MB/s</span>
                </div>
              </div>
            )}

            {uiMode !== 'developer' && (
              <div className="flex gap-6 text-[13px] text-[#8A8F9B]">
                Sovereign Assistant Mode Active
              </div>
            )}
          </div>

          <div className="flex items-center gap-6">
            
            {/* PERSONA TOGGLE */}
            <div className="flex items-center gap-1 bg-[#1A1D24] rounded-lg p-0.5 border border-[#2A2E38] mr-2">
              <button 
                onClick={() => setUiMode('developer')}
                className={`px-3 py-1.5 rounded text-[10px] font-mono transition-all font-bold tracking-wider ${
                  uiMode === 'developer' 
                    ? 'bg-[#00E5FF]/20 text-[#00E5FF] border border-[#00E5FF]/30 shadow-[0_0_8px_rgba(0,229,255,0.2)]' 
                    : 'text-white/40 hover:text-white/60'
                }`}
              >
                DEV
              </button>
              <button 
                onClick={() => setUiMode('business')}
                className={`px-3 py-1.5 rounded text-[10px] font-mono transition-all font-bold tracking-wider ${
                  uiMode === 'business' 
                    ? 'bg-[#10b981]/20 text-[#10b981] border border-[#10b981]/30 shadow-[0_0_8px_rgba(16,185,129,0.2)]' 
                    : 'text-white/40 hover:text-white/60'
                }`}
              >
                BIZ
              </button>
              <button 
                onClick={() => setUiMode('focus')}
                className={`px-3 py-1.5 rounded text-[10px] font-mono transition-all font-bold tracking-wider ${
                  uiMode === 'focus' 
                    ? 'bg-[#a855f7]/20 text-[#a855f7] border border-[#a855f7]/30 shadow-[0_0_8px_rgba(168,85,247,0.2)]' 
                    : 'text-white/40 hover:text-white/60'
                }`}
              >
                FOCUS
              </button>
            </div>

            <div className="flex flex-col items-end">
              <span className="text-[9px] text-[#8A8F9B] uppercase font-bold tracking-[0.15em]">Kernel Uptime</span>
              <span className="text-xs font-mono text-[#00E5FF]" suppressHydrationWarning>{uptime}s</span>
            </div>
          </div>
        </header>

        {/* CHAT INTERFACE */}
        <div className="flex-1 flex flex-col p-4 md:p-6 gap-4 overflow-hidden relative">
          
          <div className="absolute inset-0 z-0 pointer-events-none bg-[linear-gradient(to_right,#1F222A_1px,transparent_1px),linear-gradient(to_bottom,#1F222A_1px,transparent_1px)] bg-[size:24px_24px][mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)] opacity-20" />

          <div className="flex-1 bg-[#0E1015]/90 backdrop-blur-sm border border-[#1F222A] rounded-xl flex flex-col overflow-hidden relative shadow-[0_8px_30px_rgba(0,0,0,0.5)] z-10">
            
            <div className="h-12 border-b border-[#1F222A] flex items-center justify-between px-4 bg-[#0A0C10] flex-shrink-0">
              <div className="flex items-center gap-2 text-[#00E5FF] uppercase font-bold text-[11px] tracking-[0.15em] drop-shadow-[0_0_8px_rgba(0,229,255,0.3)]">
                {activeWorkerInfo.icon} {uiMode === 'business' ? (activeWorkerInfo.id === 'files' ? 'Company Knowledge' : activeWorkerInfo.name) : activeWorkerInfo.name}
              </div>
              <div className="flex items-center gap-4">
                <div className="px-3 py-1 rounded bg-[#12141A] border border-[#1F222A] text-[9px] font-mono text-white/60 uppercase tracking-wider">
                  Engine: <span className="text-[#B388FF]">{selectedModel}</span>
                </div>
                {services.kernel ? (
                  <div className="flex items-center gap-2 text-[9px] font-bold tracking-widest uppercase text-[#00E676]">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#00E676] animate-pulse shadow-[0_0_8px_#00E676]" /> KERNEL ONLINE
                  </div>
                ) : (
                   <div className="flex items-center gap-2 text-[9px] font-bold tracking-widest uppercase text-red-500">
                    <div className="w-1.5 h-1.5 rounded-full bg-red-500 shadow-[0_0_8px_#ef4444]" /> KERNEL OFFLINE
                  </div>
                )}
              </div>
            </div>

            {/* Chat Area */}
            <div className="flex-1 overflow-y-auto custom-scrollbar p-6 relative">
              
              {/* UPLOADED FILES DISPLAY (Always visible at top of chat if files exist) */}
              {uploadedFiles.length > 0 && (
                <div className="mb-8 p-4 bg-[#12141A]/90 border border-[#2A2E38] rounded-xl shadow-sm z-10 relative">
                  <div className="flex items-center gap-2 text-[10px] font-mono uppercase tracking-widest text-[#8A8F9B] mb-3">
                    <Icons.Database /> Active Memory Matrix
                  </div>
                  <div className="flex flex-wrap gap-2.5">
                    {uploadedFiles.map(file => (
                      <div key={file} className="px-3 py-2 bg-[#0A0C10] border border-[#00E5FF]/30 hover:border-[#00E5FF] transition-colors rounded-lg text-xs font-mono text-[#00E5FF] flex items-center gap-2 group">
                        <Icons.Paperclip /> {file}
                        <button 
                          onClick={() => { setInput(`Analyze ${file}`); inputRef.current?.focus(); }}
                          className="ml-2 px-1.5 py-0.5 rounded bg-[#00E5FF]/10 text-[#00E5FF] hover:bg-[#00E5FF] hover:text-black transition-colors"
                          title="Analyze this file"
                        >
                          Analyze
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {chatLog.length === 0 ? (
                
                uiMode === 'business' ? (
                  <motion.div 
                    initial={{ opacity: 0, y: 20 }} 
                    animate={{ opacity: 1, y: 0 }} 
                    transition={{ duration: 0.5, ease: "easeOut" }}
                    className="h-full flex flex-col items-center justify-center pt-8 pb-12"
                  >
                    <div className="mb-10 text-center">
                      <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#10b981]/20 to-[#00E5FF]/20 border border-[#10b981]/30 text-[#10b981] flex items-center justify-center shadow-[0_0_30px_rgba(16,185,129,0.15)] mx-auto mb-6">
                        <Icons.Brain />
                      </div>
                      <h2 className="text-3xl font-semibold text-white mb-3 tracking-tight">What can Rez Hive do for you today?</h2>
                      <p className="text-[#8A8F9B] text-sm">Select a capability, attach data, or type your request below.</p>
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4 max-w-2xl w-full">
                      {[
                        { icon: "📊", title: "Analyze Spreadsheet", desc: "Extract insights from financial data", prompt: "Analyze the uploaded data.xlsx" },
                        { icon: "📈", title: "Predict Trends", desc: "Forecast future performance", prompt: "Forecast next quarter from data.xlsx" },
                        { icon: "📝", title: "Draft Content", desc: "Generate professional correspondence", prompt: "Draft an email regarding the analysis." },
                        { icon: "🔎", title: "Query Matrix", desc: "Extract exact anomalies", prompt: "Find anomalies in data.xlsx" }
                      ].map((card, i) => (
                        <button 
                          key={i} 
                          onClick={() => { setInput(card.prompt); inputRef.current?.focus(); }} 
                          className="p-5 bg-[#12141A]/80 border border-[#2A2E38] rounded-xl hover:border-[#10b981]/50 hover:bg-[#10b981]/5 transition-all duration-300 text-left group shadow-sm hover:shadow-[0_0_15px_rgba(16,185,129,0.1)]"
                        >
                          <span className="text-2xl mb-3 block group-hover:scale-110 transition-transform origin-bottom-left">{card.icon}</span>
                          <h4 className="text-white text-sm font-medium mb-1.5">{card.title}</h4>
                          <p className="text-[#8A8F9B] text-xs leading-relaxed">{card.desc}</p>
                        </button>
                      ))}
                    </div>
                  </motion.div>
                ) : (
                  <motion.div 
                    initial={{ opacity: 0, scale: 0.95 }} 
                    animate={{ opacity: 1, scale: 1 }} 
                    transition={{ duration: 0.5, ease: "easeOut" }}
                    className="h-full flex flex-col items-center justify-center text-[#4B5563] font-mono"
                  >
                    <div className="relative mb-6">
                      <div className="absolute inset-0 bg-[#00E5FF] blur-2xl opacity-10 rounded-full" />
                      <div className="w-16 h-16 rounded-2xl bg-[#12141A] border border-[#2A2E38] text-[#00E5FF] flex items-center justify-center shadow-[0_0_30px_rgba(0,229,255,0.15)] relative z-10">
                        <Icons.Command />
                      </div>
                    </div>
                    <h3 className="text-white text-lg mb-2 tracking-widest uppercase font-sans font-bold">System Initialized</h3>
                    <div className="text-xs space-y-2 text-center text-[#8A8F9B] tracking-wide">
                      <p>Sovereign OS v2.0 Cognitive Engine Online.</p>
                      <p className="flex items-center justify-center gap-2">
                        Waiting for input via <span className="text-[#00E5FF] border border-[#00E5FF]/20 bg-[#00E5FF]/5 px-2 py-0.5 rounded">{activeWorkerInfo.name}</span>
                      </p>
                    </div>
                  </motion.div>
                )

              ) : (
                <div className="space-y-8 max-w-4xl mx-auto pb-4">
                  <AnimatePresence mode="popLayout">
                    {chatLog.map((message) => {
                       const msgWorker = workers.find(w => w.id === message.worker) || activeWorkerInfo;
                       return (
                        <motion.div
                          layout
                          key={message.id}
                          initial={{ opacity: 0, y: 20, scale: 0.98 }}
                          animate={{ opacity: 1, y: 0, scale: 1 }}
                          transition={{ type: "spring", stiffness: 200, damping: 20 }}
                          className={`flex flex-col gap-2 ${message.role === 'user' ? 'items-end' : 'items-start'}`}
                        >
                          <div className={`flex items-center gap-2 text-[9px] font-mono uppercase tracking-[0.15em] px-1 ${message.role === 'user' ? 'flex-row-reverse' : ''}`}>
                            {message.role === 'user' ? (
                              <>
                                <span className="px-2 py-0.5 rounded border border-[#2A2E38] bg-[#12141A] text-white shadow-sm">Admin</span> 
                                <span className="text-[#4B5563]" suppressHydrationWarning>{message.timestamp}</span>
                              </>
                            ) : (
                              <>
                                <span className={`flex items-center gap-1.5 px-2 py-0.5 rounded border shadow-sm ${
                                  message.role === 'system' 
                                    ? 'border-[#FF9800]/30 bg-[#FF9800]/10 text-[#FF9800] shadow-[0_0_10px_rgba(255,152,0,0.15)]' 
                                    : 'border-[#00E5FF]/30 bg-[#00E5FF]/10 text-[#00E5FF] shadow-[0_0_10px_rgba(0,229,255,0.15)]'
                                }`}>
                                  {message.role === 'system' ? <Icons.Shield /> : msgWorker.icon}
                                  {message.role === 'system' ? 'SYSTEM OVERRIDE' : msgWorker.name}
                                </span>
                                <span className="text-[#4B5563]" suppressHydrationWarning>{message.timestamp}</span>
                              </>
                            )}
                          </div>

                          <div className={`w-full max-w-[88%] relative ${
                            message.role === 'user' 
                              ? 'bg-[#1A1D24] border border-[#2A2E38] rounded-2xl rounded-tr-sm p-5 text-white shadow-md' 
                              : message.role === 'system'
                              ? 'border-l-2 border-[#FF9800] bg-gradient-to-r from-[#FF9800]/10 via-[#0A0C10] to-transparent p-5 text-[#FF9800] rounded-r-2xl shadow-sm'
                              : 'border-l-2 border-[#00E5FF] bg-gradient-to-r from-[#00E5FF]/5 via-[#0A0C10] to-transparent p-5 text-white rounded-r-2xl shadow-[inset_20px_0_40px_-20px_rgba(0,229,255,0.03)]'
                          }`}>
                            {message.content ? (
                              <MessageContent content={message.content} />
                            ) : (
                              <div className="flex items-center gap-3 text-[#00E5FF] font-mono text-xs tracking-wider">
                                <LoadingIndicator /> PROCESSING INTENT...
                              </div>
                            )}
                          </div>
                        </motion.div>
                      );
                    })}
                  </AnimatePresence>
                  <div ref={chatEndRef} className="h-4" />
                </div>
              )}
            </div>

            {/* Input Console */}
            <div className="p-5 bg-[#0A0C10] border-t border-[#1F222A] flex-shrink-0 relative">
              <div className="max-w-4xl mx-auto">
                <div className={`relative group rounded-xl bg-[#0E1015] border transition-all duration-300 flex flex-col p-2 shadow-lg ${
                  isLoading ? 'border-[#2A2E38]' : 'border-[#2A2E38] focus-within:border-[#00E5FF]/60 focus-within:shadow-[0_0_25px_rgba(0,229,255,0.1)]'
                }`}>
                  <textarea
                    ref={inputRef}
                    value={input}
                    onChange={e => setInput(e.target.value)}
                    onKeyDown={e => {
                      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
                    }}
                    placeholder={uiMode === 'business' ? "Ask Rez Hive anything..." : `Transmit command to ${activeWorkerInfo.name}...`}
                    className="w-full bg-transparent border-none outline-none text-white placeholder:text-[#4B5563] text-sm px-3 py-3 resize-none max-h-32 min-h-[48px] custom-scrollbar font-mono leading-relaxed"
                    rows={1}
                    disabled={isLoading}
                  />
                  <div className="flex items-center justify-between px-3 pt-2 border-t border-[#1F222A] mt-1">
                    <div className="flex items-center gap-4">
                      {/* FILE UPLOAD BUTTON */}
                      <input
                        ref={fileInputRef}
                        type="file"
                        className="hidden"
                        accept=".csv,.xlsx,.xls"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) handleFileUpload(file);
                          if (e.target) e.target.value = ''; // reset so same file can be uploaded
                        }}
                      />
                      <button
                        onClick={() => fileInputRef.current?.click()}
                        disabled={isLoading}
                        className="flex items-center gap-1.5 text-[#8A8F9B] hover:text-[#00E5FF] transition-colors group/attach"
                        title="Attach Spreadsheet Data"
                      >
                        <Icons.Paperclip />
                        <span className="text-[9px] font-mono uppercase tracking-[0.1em] mt-0.5 group-hover/attach:text-[#00E5FF]">Attach Data</span>
                      </button>
                      <div className="w-px h-3 bg-[#1F222A]" />
                      <span className="text-[9px] font-mono text-[#4B5563] uppercase tracking-[0.1em]">Shift + Enter for newline</span>
                    </div>
                    <button
                      onClick={sendMessage}
                      disabled={isLoading || !input.trim()}
                      className={`px-6 py-2 rounded md text-[10px] font-bold font-mono tracking-[0.2em] uppercase transition-all duration-300 border ${
                        isLoading || !input.trim() 
                          ? 'bg-[#12141A] text-[#4B5563] border-[#1F222A]' 
                          : 'bg-[#00E5FF]/10 text-[#00E5FF] border-[#00E5FF]/30 hover:bg-[#00E5FF] hover:text-black hover:shadow-[0_0_15px_rgba(0,229,255,0.4)]'
                      }`}
                    >
                      {isLoading ? 'Executing' : 'Transmit'}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* RIGHT STATS PANELS (Hidden in Focus Mode) */}
      {uiMode !== 'focus' && (
        <aside className="hidden xl:flex w-[320px] flex-col gap-6 p-6 pl-0 relative z-20 flex-shrink-0">
          
          {/* LIVE NETWORK PANEL (Always Visible unless in Focus Mode) */}
          <div className="bg-[#0E1015]/90 backdrop-blur-md border border-[#1F222A] rounded-xl p-5 shadow-[0_8px_30px_rgba(0,0,0,0.5)] relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-[#00E676]/5 rounded-full blur-3xl" />
            <div className="flex items-center justify-between mb-6 relative z-10">
              <div className="flex items-center gap-2 text-xs font-bold tracking-[0.15em] uppercase text-white">
                <div className="text-[#00E676] drop-shadow-[0_0_5px_#00E676]"><Icons.Terminal /></div> Network
              </div>
              <span className="text-[9px] px-2 py-0.5 rounded bg-[#00E676]/10 text-[#00E676] font-mono uppercase border border-[#00E676]/20">ACTIVE</span>
            </div>
            <div className="space-y-5 relative z-10">
              <div>
                <div className="flex justify-between text-[10px] text-[#8A8F9B] mb-2 uppercase font-bold tracking-wider">
                  <span>Download</span> <span className="font-mono text-white transition-all">{stats.networkDown} MB/s</span>
                </div>
                <div className="h-1.5 bg-[#12141A] rounded-full overflow-hidden relative border border-[#1F222A]">
                  <div 
                    className="h-full bg-[#00E676] rounded-full transition-all duration-300 shadow-[0_0_10px_#00E676]" 
                    style={{ width: `${Math.min((stats.networkDown / 50) * 100, 100)}%` }} 
                  />
                </div>
              </div>
              <div>
                <div className="flex justify-between text-[10px] text-[#8A8F9B] mb-2 uppercase font-bold tracking-wider">
                  <span>Upload</span> <span className="font-mono text-white transition-all">{stats.networkUp} MB/s</span>
                </div>
                <div className="h-1.5 bg-[#12141A] rounded-full overflow-hidden relative border border-[#1F222A]">
                  <div 
                    className="h-full bg-[#00E5FF] rounded-full transition-all duration-300 shadow-[0_0_10px_#00E5FF]" 
                    style={{ width: `${Math.min((stats.networkUp / 20) * 100, 100)}%` }} 
                  />
                </div>
              </div>
            </div>
          </div>

          {/* DEVELOPER MODE PANELS */}
          {uiMode === 'developer' && (
            <>
              {/* MEMORY CONTEXT VISUALIZER */}
              <div className="bg-[#0E1015]/90 backdrop-blur-md border border-[#1F222A] rounded-xl p-5 shadow-[0_8px_30px_rgba(0,0,0,0.5)] flex flex-col relative overflow-hidden">
                <div className="absolute bottom-0 right-0 w-40 h-40 bg-[#B388FF]/5 rounded-full blur-3xl pointer-events-none" />
                <div className="flex items-center justify-between mb-5 relative z-10">
                  <div className="flex items-center gap-2 text-xs font-bold tracking-[0.15em] uppercase text-white">
                    <div className="text-[#B388FF] drop-shadow-[0_0_5px_#B388FF]"><Icons.Database /></div> Context
                  </div>
                </div>
                <div className="flex-1 rounded-xl border border-[#1F222A] bg-[#0A0C10] p-5 flex flex-col justify-center gap-6 relative overflow-hidden z-10">
                  <div className="text-center">
                    <div className="text-4xl font-bold text-white mb-1 font-mono tracking-tighter drop-shadow-md">
                      {tokenStats.current.toLocaleString()} 
                    </div>
                    <div className="text-[9px] text-[#8A8F9B] font-mono uppercase tracking-[0.2em] mt-2">
                      / {tokenStats.max.toLocaleString()} TOKENS
                    </div>
                  </div>
                  <div>
                      <div className="flex justify-between text-[10px] text-[#8A8F9B] mb-2 font-mono tracking-wider">
                          <span>CAPACITY</span>
                          <span className={tokenPercent > 90 ? 'text-[#FF4500] drop-shadow-[0_0_5px_#FF4500]' : 'text-[#B388FF]'}>{tokenPercent.toFixed(1)}%</span>
                      </div>
                      <div className="h-2 bg-[#12141A] rounded-full overflow-hidden w-full relative border border-[#1F222A]">
                        <div 
                            className={`h-full absolute left-0 top-0 transition-all duration-500 rounded-full ${tokenPercent > 90 ? 'bg-[#FF4500] shadow-[0_0_15px_#FF4500]' : 'bg-gradient-to-r from-[#00E5FF] to-[#B388FF] shadow-[0_0_10px_#B388FF]'}`}
                            style={{ width: `${tokenPercent}%` }}
                        />
                      </div>
                  </div>
                </div>
              </div>

              {/* LIVE GPU ENGINE LOAD VISUALIZER */}
              <div className="h-48 bg-[#0E1015]/90 backdrop-blur-md border border-[#1F222A] rounded-xl p-5 shadow-[0_8px_30px_rgba(0,0,0,0.5)] flex flex-col relative overflow-hidden">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-32 h-32 bg-[#FF9800]/5 rounded-full blur-3xl pointer-events-none" />
                <div className="flex items-center justify-between mb-4 relative z-10">
                  <div className="flex items-center gap-2 text-xs font-bold tracking-[0.15em] uppercase text-white">
                    <div className="text-[#FF9800] drop-shadow-[0_0_5px_#FF9800]"><Icons.Zap /></div> GPU Engine
                  </div>
                  <span className="text-xs text-[#FF9800] font-mono font-bold transition-all drop-shadow-[0_0_5px_rgba(255,152,0,0.5)]">{stats.gpuTemp}°C</span>
                </div>
                <div className="flex-1 flex items-end justify-between gap-1.5 pt-4 relative z-10">
                  {gpuBars.map((height, i) => (
                    <motion.div 
                      key={i}
                      className="w-full rounded-t-sm border-t border-[#FF9800]/20"
                      animate={{ 
                        height: `${height}%`,
                        backgroundColor: height > 80 ? "#FF9800" : height > 50 ? "rgba(255, 152, 0, 0.6)" : "rgba(255, 152, 0, 0.15)"
                      }}
                      transition={{ duration: 0.8, ease: "easeInOut" }}
                      style={{
                        boxShadow: height > 80 ? "0 0 10px rgba(255, 152, 0, 0.5)" : "none"
                      }}
                    />
                  ))}
                </div>
              </div>
            </>
          )}

          {/* BUSINESS MODE PANELS */}
          {uiMode === 'business' && (
            <>
              {/* PRODUCTIVITY DASHBOARD */}
              <div className="bg-[#0E1015]/90 backdrop-blur-md border border-[#1F222A] rounded-xl p-5 shadow-[0_8px_30px_rgba(0,0,0,0.5)] relative overflow-hidden">
                <div className="absolute bottom-0 right-0 w-32 h-32 bg-[#10b981]/5 rounded-full blur-3xl pointer-events-none" />
                <div className="flex items-center justify-between mb-6 relative z-10">
                  <div className="flex items-center gap-2 text-xs font-bold tracking-[0.15em] uppercase text-white">
                    <div className="text-[#10b981] drop-shadow-[0_0_5px_#10b981]"><Icons.Activity /></div> Impact
                  </div>
                  <span className="text-[9px] px-2 py-0.5 rounded bg-[#10b981]/10 text-[#10b981] font-mono uppercase border border-[#10b981]/20">TODAY</span>
                </div>
                <div className="space-y-4 relative z-10">
                  <div className="flex justify-between items-center">
                    <span className="text-[#8A8F9B] text-[10px] uppercase tracking-wider font-bold">Tasks Completed</span>
                    <span className="text-white font-mono text-lg">{Math.max(12, chatLog.length * 2)}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-[#8A8F9B] text-[10px] uppercase tracking-wider font-bold">Files Analyzed</span>
                    <span className="text-white font-mono text-lg">{48 + uploadedFiles.length}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-[#8A8F9B] text-[10px] uppercase tracking-wider font-bold">Time Saved</span>
                    <span className="text-[#10b981] font-mono text-lg drop-shadow-[0_0_5px_rgba(16,185,129,0.4)]">{(2.3 + chatLog.length * 0.1).toFixed(1)}h</span>
                  </div>
                  <div className="h-1 bg-[#1A1D24] rounded-full overflow-hidden mt-4 border border-[#2A2E38]">
                    <div className="h-full w-[65%] bg-gradient-to-r from-[#10b981] to-[#00E5FF] rounded-full shadow-[0_0_10px_#10b981]" />
                  </div>
                </div>
              </div>

              {/* CONNECTED TOOLS (Friendly MCP) */}
              <div className="bg-[#0E1015]/90 backdrop-blur-md border border-[#1F222A] rounded-xl p-5 shadow-[0_8px_30px_rgba(0,0,0,0.5)] relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/5 rounded-full blur-3xl pointer-events-none" />
                <div className="flex items-center justify-between mb-5 relative z-10">
                  <div className="flex items-center gap-2 text-xs font-bold tracking-[0.15em] uppercase text-white">
                    <div className="text-blue-400 drop-shadow-[0_0_5px_#60a5fa]"><Icons.Apps /></div> Integrations
                  </div>
                  <span className="text-[9px] px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 font-mono uppercase border border-blue-500/20">5 ACTIVE</span>
                </div>
                <div className="grid grid-cols-2 gap-2.5 relative z-10">
                  <div className="flex items-center gap-2.5 p-2.5 bg-[#12141A] border border-[#2A2E38] rounded-lg hover:border-[#60a5fa]/50 transition-colors cursor-default">
                    <span className="text-blue-400 text-lg">📁</span>
                    <span className="text-white/80 text-[11px] font-medium tracking-wide">Files</span>
                  </div>
                  <div className="flex items-center gap-2.5 p-2.5 bg-[#12141A] border border-[#2A2E38] rounded-lg hover:border-[#60a5fa]/50 transition-colors cursor-default">
                    <span className="text-purple-400 text-lg">🐙</span>
                    <span className="text-white/80 text-[11px] font-medium tracking-wide">GitHub</span>
                  </div>
                  <div className="flex items-center gap-2.5 p-2.5 bg-[#12141A] border border-[#2A2E38] rounded-lg hover:border-[#60a5fa]/50 transition-colors cursor-default">
                    <span className="text-pink-400 text-lg">💬</span>
                    <span className="text-white/80 text-[11px] font-medium tracking-wide">Slack</span>
                  </div>
                  <div className="flex items-center gap-2.5 p-2.5 bg-[#12141A] border border-[#2A2E38] rounded-lg hover:border-[#60a5fa]/50 transition-colors cursor-default">
                    <span className="text-yellow-400 text-lg">📅</span>
                    <span className="text-white/80 text-[11px] font-medium tracking-wide">Calendar</span>
                  </div>
                </div>
              </div>
            </>
          )}

          {/* STANDARD MCP STATUS PANEL (Visible in Developer mode) */}
          {uiMode === 'developer' && (
            <div className="bg-[#0E1015]/90 backdrop-blur-md border border-[#1F222A] rounded-xl p-5 shadow-[0_8px_30px_rgba(0,0,0,0.5)] relative overflow-hidden">
              <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/5 rounded-full blur-3xl" />
              <div className="flex items-center justify-between mb-4 relative z-10">
                <div className="flex items-center gap-2 text-xs font-bold tracking-[0.15em] uppercase text-white">
                  <div className="text-emerald-400 drop-shadow-[0_0_5px_#10b981]"><Icons.Network /></div> MCP Bridge
                </div>
                <span className="text-[9px] px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 font-mono uppercase border border-emerald-500/20">
                  {services.mcp ? 'ACTIVE' : 'OFFLINE'}
                </span>
              </div>
              <div className="space-y-3 relative z-10">
                <div className="flex justify-between text-[10px] text-[#8A8F9B]">
                  <span>Connected Tools</span>
                  <span className="font-mono text-white">5 active</span>
                </div>
                <div className="flex flex-wrap gap-1.5">
                  <span className="text-[8px] px-2 py-1 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">filesystem</span>
                  <span className="text-[8px] px-2 py-1 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">github</span>
                  <span className="text-[8px] px-2 py-1 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">slack</span>
                  <span className="text-[8px] px-2 py-1 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">calendar</span>
                  <span className="text-[8px] px-2 py-1 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">search</span>
                </div>
              </div>
            </div>
          )}
        </aside>
      )}

      <RezHiveController />

      <style jsx global>{`
        /* Ultra-Sleek Scrollbar for Production */
        .custom-scrollbar::-webkit-scrollbar { width: 4px; height: 4px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: #1F222A; border-radius: 4px; transition: all 0.3s ease; }
        .custom-scrollbar:hover::-webkit-scrollbar-thumb { background: #4B5563; }
        
        /* Smooth selection color */
        ::selection { background: rgba(0, 229, 255, 0.2); color: #fff; }
      `}</style>
    </div>
  );
}