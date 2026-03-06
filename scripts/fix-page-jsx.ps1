# ============================================================================
# FIX PAGE.TSX - COMPLETE WORKING VERSION
# ============================================================================

$PAGE_PATH = "D:\okiru-os\The Reztack OS\src\app\page.tsx"
$BACKUP_PATH = "D:\okiru-os\The Reztack OS\page.tsx.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

Write-Host "📦 Backing up current page.tsx to $BACKUP_PATH" -ForegroundColor Yellow
Copy-Item $PAGE_PATH $BACKUP_PATH -Force

Write-Host "🔧 Creating fixed page.tsx..." -ForegroundColor Yellow

$fixedPage = @'
"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import {
  Brain,
  Eye,
  Hand,
  Database,
  Cpu,
  Zap,
  Network,
  Menu,
  ChevronDown,
  ChevronRight,
  HelpCircle,
  Mic,
  MicOff,
  Trash2,
  X,
} from "lucide-react";
import { CodeBlock } from "../components/CodeBlock";
import { motion, AnimatePresence } from "framer-motion";

// --- Types ---
interface SystemMetric {
  name: string;
  value: number;
  icon: React.ReactNode;
  color: string;
  unit: string;
  history: number[];
}

interface CommandItem {
  cmd: string;
  icon: string;
  desc: string;
  value: string;
  payload?: Record<string, any>;
}

type CommandCategory = "system" | "apps" | "search" | "code" | "memory" | "files";

interface ChatMessage {
  id: string;
  role: "ai" | "user";
  content: string;
  timestamp: string;
}

interface WorkerStatus {
  name: string;
  icon: React.ReactNode;
  active: boolean;
}

interface ServicesStatus {
  ollama: boolean;
  chroma: boolean;
  kernel: boolean;
}

// --- Utils ---
const getTime = () => {
  const d = new Date();
  return `${d.getHours().toString().padStart(2, "0")}:${d.getMinutes().toString().padStart(2, "0")}`;
};

const generateId = () => Math.random().toString(36).substring(2, 9);

const formatTime = (ms: number) => {
  if (ms < 0) return "0h 0m";
  const hours = Math.floor(ms / 3600000);
  const mins = Math.floor((ms % 3600000) / 60000);
  return `${hours}h ${mins}m`;
};

// --- Components ---
const Sparkline = ({ data, color }: { data: number[]; color: string }) => {
  if (!data || data.length < 2) return <div className="h-4 w-10" />;

  const max = Math.max(...data, 1);
  const min = Math.min(...data, 0);
  const range = max - min || 1;
  const width = 40;
  const height = 16;

  const points = data
    .map((v, i) => {
      const x = (i / (data.length - 1)) * width;
      const y = height - ((v - min) / range) * height;
      return `${x},${y}`;
    })
    .join(" ");

  return (
    <svg width={width} height={height} className="opacity-60">
      <polyline fill="none" stroke={color} strokeWidth="1.5" points={points} />
    </svg>
  );
};

const TwoBarMeter = ({
  sessionPercent,
  weeklyPercent,
  resetTime,
}: {
  sessionPercent: number;
  weeklyPercent: number;
  resetTime: number;
}) => {
  const [timeLeft, setTimeLeft] = useState(resetTime - Date.now());

  useEffect(() => {
    const timer = setInterval(() => setTimeLeft(resetTime - Date.now()), 1000);
    return () => clearInterval(timer);
  }, [resetTime]);

  return (
    <div className="space-y-3">
      <div className="space-y-1">
        <div className="flex justify-between text-xs">
          <span className="text-white/40">Session</span>
          <span className="text-white/60">{Math.round(sessionPercent)}%</span>
        </div>
        <div className="h-1 bg-white/10 rounded-full overflow-hidden">
          <motion.div
            className="h-full bg-cyan-400 rounded-full"
            style={{ width: `${sessionPercent}%` }}
            animate={{ width: `${sessionPercent}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>
      </div>

      <div className="space-y-1">
        <div className="flex justify-between text-xs">
          <span className="text-white/40">Weekly</span>
          <span className="text-white/60">{Math.round(weeklyPercent)}%</span>
        </div>
        <div className="h-1 bg-white/10 rounded-full overflow-hidden">
          <motion.div
            className="h-full bg-purple-400 rounded-full"
            style={{ width: `${weeklyPercent}%` }}
            animate={{ width: `${weeklyPercent}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>
      </div>

      <div className="text-xs text-white/30 text-center">
        Resets in {formatTime(timeLeft)}
      </div>
    </div>
  );
};

// --- Constants ---
const WELCOME_MESSAGE =
  "Welcome to REZ HIVE! 👋\n\nI'm your sovereign AI coworker.\n\nChat naturally • Remember context • Run commands\nTry: \"What can you help me with?\"";

const WORKERS: WorkerStatus[] = [
  { name: "Brain", icon: <Brain size={16} />, active: true },
  { name: "Eyes", icon: <Eye size={16} />, active: false },
  { name: "Hands", icon: <Hand size={16} />, active: false },
  { name: "Memory", icon: <Database size={16} />, active: true },
];

const SOVEREIGN_COMMANDS: Record<CommandCategory, CommandItem[]> = {
  system: [
    { cmd: "Check CPU", icon: "⚡", desc: "Check CPU usage", value: "cpu" },
    { cmd: "Health check", icon: "🩺", desc: "Run health check", value: "health" },
  ],
  apps: [{ cmd: "List apps", icon: "📱", desc: "List installed apps", value: "apps" }],
  search: [{ cmd: "Search web", icon: "🔍", desc: "Search the web", value: "search" }],
  code: [{ cmd: "Generate code", icon: "💻", desc: "Generate code", value: "code" }],
  memory: [{ cmd: "Recall", icon: "🧠", desc: "Recall context", value: "recall" }],
  files: [{ cmd: "List files", icon: "📁", desc: "List files", value: "files" }],
};

// --- Main Component ---
export default function SovereignDashboard() {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [showHelp, setShowHelp] = useState(false);
  const [activeWorker, setActiveWorker] = useState("Brain");
  const [activeCategory, setActiveCategory] = useState<CommandCategory>("system");
  const [showCommands, setShowCommands] = useState(true);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [timestamp, setTimestamp] = useState("");
  const [availableModels, setAvailableModels] = useState<string[]>([]);
  const [selectedModel, setSelectedModel] = useState<string>("llama3.2:latest");
  const [showModelDropdown, setShowModelDropdown] = useState(false);
  const abortControllerRef = useRef<AbortController | null>(null);
  const chatEndRef = useRef<HTMLDivElement>(null);

  const [services, setServices] = useState<ServicesStatus>({
    ollama: false,
    chroma: false,
    kernel: false,
  });

  const [metrics, setMetrics] = useState<SystemMetric[]>([
    { name: "CPU", value: 12.4, icon: <Cpu size={14} />, color: "#34d399", unit: "%", history: [10, 15, 12, 18, 14, 11, 13] },
    { name: "RAM", value: 31.2, icon: <Database size={14} />, color: "#60a5fa", unit: "%", history: [28, 32, 30, 35, 33, 31, 29] },
    { name: "GPU", value: 3.5, icon: <Zap size={14} />, color: "#c084fc", unit: "%", history: [2, 4, 3, 5, 3, 2, 4] },
    { name: "NET", value: 8.7, icon: <Network size={14} />, color: "#fbbf24", unit: "MB/s", history: [7, 9, 8, 10, 8, 7, 9] },
  ]);

  const [quotas, setQuotas] = useState({
    session: { used: 12, total: 100 },
    weekly: { used: 187, total: 800 },
  });

  const [chatLog, setChatLog] = useState<ChatMessage[]>([]);

  // --- Effects ---
  useEffect(() => {
    // Load chat
    try {
      const savedChat = typeof window !== "undefined" ? localStorage.getItem("rez_hive_chat_v2") : null;
      if (savedChat) setChatLog(JSON.parse(savedChat));
      else
        setChatLog([
          { id: generateId(), role: "ai", content: WELCOME_MESSAGE, timestamp: getTime() },
        ]);
    } catch (e) {
      console.error("Load error", e);
    }

    // Metrics and timestamp updater
    const interval = setInterval(() => setTimestamp(getTime()), 1000);
    const metricsTimer = setInterval(() => {
      setMetrics((prev) =>
        prev.map((m) => {
          const newVal = Math.max(0, Math.min(100, m.value + (Math.random() - 0.5) * 10));
          return { ...m, value: newVal, history: [...m.history.slice(1), newVal] };
        })
      );
    }, 4000);

    return () => {
      clearInterval(interval);
      clearInterval(metricsTimer);
      abortControllerRef.current?.abort();
    };
  }, []);

  // --- Debounced localStorage ---
  useEffect(() => {
    const handler = setTimeout(() => {
      if (typeof window !== "undefined") localStorage.setItem("rez_hive_chat_v2", JSON.stringify(chatLog));
    }, 500);
    return () => clearTimeout(handler);
  }, [chatLog]);

  // --- Scroll chat ---
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [chatLog]);

  // --- Services & Models ---
  const checkServices = useCallback(async () => {
    try {
      const res = await fetch("/api/status");
      if (res.ok) setServices(await res.json());
    } catch {}
  }, []);

  const fetchModels = useCallback(async () => {
    try {
      const res = await fetch("/api/ollama/models");
      const data = await res.json();
      setAvailableModels(data.models || ["llama3.2:latest", "phi3.5:3.8b"]);
      if (data.default) setSelectedModel(data.default);
    } catch {
      setAvailableModels(["llama3.2:latest", "phi3.5:3.8b"]);
    }
  }, []);

  useEffect(() => {
    checkServices();
    fetchModels();
    const interval = setInterval(checkServices, 15000);
    return () => clearInterval(interval);
  }, [checkServices, fetchModels]);

  // --- Action Handler ---
  const executeAction = async (commandText: string, payload?: Record<string, any>) => {
    if (!commandText.trim() || loading) return;
    const userMessage: ChatMessage = { id: generateId(), role: "user", content: commandText, timestamp: getTime() };
    const aiMessageId = generateId();

    setChatLog((prev) => [...prev, userMessage, { id: aiMessageId, role: "ai", content: "", timestamp: getTime() }]);
    setInput("");
    setLoading(true);
    abortControllerRef.current?.abort();
    abortControllerRef.current = new AbortController();

    try {
      const response = await fetch("/api/kernel", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ task: commandText, worker: activeWorker.toLowerCase(), model: selectedModel, confirmed: payload?.confirmed || false, ...payload }),
        signal: abortControllerRef.current.signal,
      });

      if (!response.ok) throw new Error("API error");
      const reader = response.body?.getReader();
      const decoder = new TextDecoder();
      let accumulated = "";
      let lastUpdate = 0;
      const MIN_UPDATE_MS = 50;

      while (reader) {
        const { done, value } = await reader.read();
        if (done) break;
        accumulated += decoder.decode(value, { stream: true });
        if (Date.now() - lastUpdate > MIN_UPDATE_MS) {
          setChatLog((prev) => prev.map((msg) => (msg.id === aiMessageId ? { ...msg, content: accumulated } : msg)));
          lastUpdate = Date.now();
        }
      }
      setChatLog((prev) => prev.map((msg) => (msg.id === aiMessageId ? { ...msg, content: accumulated } : msg)));
    } catch (e: any) {
      if (e.name !== "AbortError") setChatLog((prev) => prev.map((msg) => (msg.id === aiMessageId ? { ...msg, content: `⚠️ Error: ${e.message}` } : msg)));
    } finally {
      setLoading(false);
      abortControllerRef.current = null;
    }
  };

  const startListening = () => setIsListening(!isListening);
  const clearChat = () => setChatLog([{ id: generateId(), role: "ai", content: WELCOME_MESSAGE, timestamp: getTime() }]);

  return (
    <div className="min-h-screen bg-[#030405] text-white font-sans selection:bg-cyan-500/30">
      {/* Top Bar */}
      <header className="fixed top-0 left-0 right-0 h-12 bg-black/50 backdrop-blur-md border-b border-white/5 flex items-center px-4 z-30">
        <button 
          onClick={() => setSidebarCollapsed(!sidebarCollapsed)} 
          className="p-2 hover:bg-white/5 rounded-lg transition-colors"
        >
          <Menu size={18} className="text-white/40" />
        </button>
        
        <div className="ml-4 flex items-center gap-3">
          <span className="text-sm font-medium bg-gradient-to-r from-cyan-400 to-purple-400 bg-clip-text text-transparent">
            REZ HIVE
          </span>
          <span className="text-xs px-2 py-0.5 bg-green-500/10 text-green-400 rounded-full border border-green-500/20 flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
            LIVE
          </span>
        </div>
        
        <div className="flex items-center gap-3 ml-6">
          <div className="flex items-center gap-1.5">
            <span className={`w-2 h-2 rounded-full ${services.ollama ? 'bg-green-400 animate-pulse' : 'bg-red-400'}`} />
            <span className="text-xs text-white/30">Brain</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className={`w-2 h-2 rounded-full ${services.chroma ? 'bg-green-400 animate-pulse' : 'bg-red-400'}`} />
            <span className="text-xs text-white/30">Memory</span>
          </div>
          
          {/* Model Selector Dropdown */}
          <div className="relative ml-2">
            <button
              onClick={() => setShowModelDropdown(!showModelDropdown)}
              className="flex items-center gap-1 px-2 py-1 bg-white/5 hover:bg-white/10 rounded-lg text-xs text-white/60 border border-white/10"
            >
              <span className="truncate max-w-[80px]">{selectedModel.split(':')[0]}</span>
              <ChevronDown size={14} />
            </button>
            
            {showModelDropdown && (
              <div className="absolute top-full mt-1 left-0 bg-black/90 border border-white/10 rounded-lg py-1 z-50 max-h-60 overflow-y-auto min-w-[160px]">
                {availableModels.map((model) => (
                  <button
                    key={model}
                    className={`w-full text-left px-3 py-1.5 text-xs hover:bg-white/10 ${
                      model === selectedModel ? 'text-cyan-400 bg-cyan-500/10' : 'text-white/60'
                    }`}
                    onClick={() => {
                      setSelectedModel(model);
                      setShowModelDropdown(false);
                    }}
                  >
                    {model}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
        
        <div className="flex-1" />
        
        <div className="flex items-center gap-2">
          <button 
            onClick={clearChat} 
            className="p-2 hover:bg-white/5 rounded-lg text-white/40 hover:text-red-400 transition-colors" 
            title="Clear Chat"
          >
            <Trash2 size={16} />
          </button>
          <span className="text-xs text-white/30 font-mono tabular-nums">{timestamp}</span>
          <button 
            onClick={() => setShowHelp(!showHelp)} 
            className="p-2 hover:bg-white/5 rounded-lg transition-colors"
          >
            <HelpCircle size={16} className="text-white/40" />
          </button>
        </div>
      </header>

      {/* Metrics Bar */}
      <div className="fixed top-12 left-0 right-0 h-14 bg-black/30 backdrop-blur-sm border-b border-white/5 flex items-center px-4 z-20">
        <div className="flex gap-6 overflow-x-auto no-scrollbar">
          {metrics.map((metric) => (
            <div key={metric.name} className="flex items-center gap-2 flex-shrink-0">
              <span className="text-white/40">{metric.icon}</span>
              <div className="flex flex-col min-w-[80px]">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-medium text-white/60">{metric.name}</span>
                  <span className="text-sm font-mono tabular-nums" style={{ color: metric.color }}>
                    {metric.value.toFixed(1)}{metric.unit}
                  </span>
                </div>
                <Sparkline data={metric.history} color={metric.color} />
              </div>
            </div>
          ))}
        </div>
        
        <div className="flex-1" />
        
        <div className="flex items-center gap-3 text-xs flex-shrink-0">
          <span className="text-white/30">Active: <span className="text-white/60">{activeWorker}</span></span>
          <span className="w-1 h-1 rounded-full bg-green-400/50" />
          <span className="text-white/30">30+ models</span>
        </div>
      </div>

      <div className="pt-[104px] flex h-screen">
        {/* Sidebar */}
        <nav className={`transition-all duration-300 flex-shrink-0 ${sidebarCollapsed ? 'w-16' : 'w-48'} border-r border-white/5 bg-black/20 backdrop-blur-sm`}>
          <div className="p-3 space-y-1">
            {WORKERS.map((worker) => (
              <button
                key={worker.name}
                onClick={() => setActiveWorker(worker.name)}
                className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-all ${
                  activeWorker === worker.name 
                    ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20' 
                    : 'hover:bg-white/5 text-white/40 hover:text-white/60'
                }`}
              >
                <span className={sidebarCollapsed ? 'mx-auto' : ''}>{worker.icon}</span>
                {!sidebarCollapsed && (
                  <>
                    <span className="text-sm flex-1 text-left">{worker.name}</span>
                    {worker.active && <span className="w-1.5 h-1.5 bg-green-400 rounded-full" />}
                  </>
                )}
              </button>
            ))}
          </div>
        </nav>

        {/* Main Chat Area */}
        <main className="flex-1 flex flex-col min-w-0 relative">
          <div className="flex-1 overflow-y-auto p-4 pb-40">
            <div className="max-w-3xl mx-auto space-y-6">
              {chatLog.map((msg) => (
                <div 
                  key={msg.id} 
                  className={`flex gap-3 ${msg.role === 'user' ? 'flex-row-reverse' : ''}`}
                >
                  <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-sm ${
                    msg.role === 'ai' 
                      ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20' 
                      : 'bg-white/10 text-white'
                  }`}>
                    {msg.role === 'ai' ? '🤖' : 'U'}
                  </div>
                  
                  <div className={`max-w-[85%] ${msg.role === 'user' ? 'text-right' : ''}`}>
                    <div className="text-xs text-white/20 mb-1 font-mono">{msg.timestamp}</div>
                    
                    <div className={`text-sm rounded-2xl p-4 ${
                      msg.role === 'ai' 
                        ? 'bg-white/5 border border-white/5' 
                        : 'bg-cyan-500/10 border border-cyan-500/20'
                    }`}>
                      <ReactMarkdown 
                        remarkPlugins={[remarkGfm]} 
                        className="prose prose-invert max-w-none prose-p:leading-relaxed prose-pre:bg-transparent prose-pre:p-0"
                        components={{
                          code({ node, inline, className, children, ...props }) {
                            const match = /language-(\w+)/.exec(className || '');
                            const code = String(children).replace(/\n$/, '');
                            return !inline && match ? (
                              <CodeBlock language={match[1]} code={code} />
                            ) : (
                              <code className="bg-black/30 px-1.5 py-0.5 rounded text-cyan-300 text-xs" {...props}>
                                {children}
                              </code>
                            );
                          }
                        }}
                      >
                        {msg.content}
                      </ReactMarkdown>
                    </div>
                  </div>
                </div>
              ))}
              <div ref={chatEndRef} />
            </div>
          </div>

          {/* Input Area */}
          <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black via-black/95 to-transparent pt-8 pb-6 px-4">
            <div className="max-w-3xl mx-auto">
              {/* Category Tabs */}
              <div className="flex gap-1 mb-2 overflow-x-auto pb-1 scrollbar-hide">
                {(Object.keys(SOVEREIGN_COMMANDS) as CommandCategory[]).map((category) => (
                  <button
                    key={category}
                    onClick={() => setActiveCategory(category)}
                    className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all whitespace-nowrap capitalize ${
                      activeCategory === category 
                        ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/30' 
                        : 'text-white/30 hover:text-white/50 hover:bg-white/5'
                    }`}
                  >
                    {category}
                  </button>
                ))}
              </div>
              
              {/* Quick Commands */}
              {showCommands && (
                <div className="flex flex-wrap gap-2 mb-3">
                  {SOVEREIGN_COMMANDS[activeCategory].slice(0, 4).map((cmd, idx) => (
                    <button
                      key={`${activeCategory}-${idx}`}
                      onClick={() => executeAction(cmd.cmd, cmd.payload)}
                      disabled={loading}
                      className="px-3 py-1.5 bg-white/5 hover:bg-white/10 disabled:opacity-50 rounded-full text-xs flex items-center gap-2 transition-all border border-white/5 hover:border-white/10"
                    >
                      <span>{cmd.icon}</span>
                      <span>{cmd.cmd}</span>
                    </button>
                  ))}
                  <button 
                    onClick={() => setShowCommands(false)} 
                    className="px-2 py-1.5 text-white/20 hover:text-white/40 transition-colors"
                  >
                    <ChevronRight size={14} />
                  </button>
                </div>
              )}
              
              {/* Input Field */}
              <div className="flex gap-2">
                <button
                  onClick={startListening}
                  disabled={loading}
                  className={`p-3 rounded-xl transition-all disabled:opacity-50 ${
                    isListening 
                      ? 'bg-red-500/20 text-red-400 animate-pulse border border-red-500/50' 
                      : 'bg-white/5 text-white/40 hover:text-white/60 border border-white/5 hover:border-white/10'
                  }`}
                  title="Voice Input"
                >
                  {isListening ? <MicOff size={18} /> : <Mic size={18} />}
                </button>
                
                <input
                  type="text"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && executeAction(input)}
                  placeholder={isListening ? "Listening..." : `Message ${activeWorker} worker...`}
                  disabled={loading}
                  className="flex-1 bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm outline-none focus:border-cyan-500/40 transition-all placeholder:text-white/20 disabled:opacity-50"
                />
                
                <button
                  onClick={() => executeAction(input)}
                  disabled={loading || !input.trim()}
                  className="px-6 py-3 bg-cyan-500/10 border border-cyan-500/30 rounded-xl text-cyan-400 hover:bg-cyan-500 hover:text-black transition-all disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                >
                  {loading ? '...' : 'Send'}
                </button>
              </div>
            </div>
          </div>
        </main>

        {/* Right Panel */}
        <aside className="w-64 border-l border-white/5 bg-black/20 backdrop-blur-sm p-4 hidden lg:block flex-shrink-0">
          <TwoBarMeter 
            sessionPercent={(quotas.session.used / quotas.session.total) * 100} 
            weeklyPercent={(quotas.weekly.used / quotas.weekly.total) * 100} 
            resetTime={Date.now() + 7200000} 
          />
          <div className="mt-4 text-xs text-white/20 text-center">
            {quotas.session.used} / {quotas.session.total} sessions
          </div>
        </aside>
      </div>

      {/* Help Modal */}
      {showHelp && (
        <div 
          className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          onClick={(e) => e.target === e.currentTarget && setShowHelp(false)}
        >
          <div className="max-w-md w-full bg-[#0a0a0a] border border-white/10 rounded-2xl p-6 relative">
            <button 
              onClick={() => setShowHelp(false)}
              className="absolute top-4 right-4 p-1 hover:bg-white/5 rounded-lg text-white/40 hover:text-white/60"
            >
              <X size={18} />
            </button>
            
            <h2 className="text-lg font-medium mb-4 text-white">Welcome to REZ HIVE 👋</h2>
            
            <div className="space-y-3 text-sm text-white/70">
              <p className="flex items-start gap-2">
                <span className="text-cyan-400 font-medium">•</span>
                <span><span className="text-cyan-400">Streaming Chat</span> — Responses appear in real-time</span>
              </p>
              <p className="flex items-start gap-2">
                <span className="text-cyan-400 font-medium">•</span>
                <span><span className="text-cyan-400">Voice Input</span> — Click the microphone button</span>
              </p>
              <p className="flex items-start gap-2">
                <span className="text-cyan-400 font-medium">•</span>
                <span><span className="text-cyan-400">Persistent History</span> — Chat saved to localStorage</span>
              </p>
              <p className="flex items-start gap-2">
                <span className="text-cyan-400 font-medium">•</span>
                <span><span className="text-cyan-400">Workers</span> — Switch between AI modes in sidebar</span>
              </p>
            </div>
            
            <button 
              onClick={() => setShowHelp(false)} 
              className="mt-6 w-full px-4 py-2.5 bg-cyan-500/10 border border-cyan-500/30 rounded-lg text-cyan-400 hover:bg-cyan-500/20 transition-colors font-medium"
            >
              Got it
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
'@

$fixedPage | Out-File -FilePath $PAGE_PATH -Encoding utf8 -Force

Write-Host "✅ Fixed page.tsx created!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Kill any running processes: taskkill /F /IM python.exe ; taskkill /F /IM node.exe" -ForegroundColor White
Write-Host "2. Start kernel: python backend/kernel.py" -ForegroundColor White
Write-Host "3. Start frontend: npm run dev" -ForegroundColor White
Write-Host "4. Open http://localhost:3000" -ForegroundColor White