'use client';

import { PrimordialUI } from '../components/PrimordialUI';
import { TwoBarMeter } from '../components/TwoBarMeter';

import { useState, useEffect, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { 
  Brain, 
  Eye, 
  Hand, 
  Database, 
  Cpu, 
  Zap, 
  HardDrive, 
  Activity, 
  Network,
  Gauge,
  Terminal,
  Code,
  Search,
  Music,
  FolderDown,
  AlertCircle,
  CheckCircle,
  Clock,
  CpuIcon,
  Thermometer,
  HardDriveIcon,
  Wifi,
  Download,
  Upload
} from 'lucide-react';

// --- TYPES ---
interface SystemMetric {
  name: string;
  value: number;
  icon: React.ReactNode;
  color: string;
  unit: string;
  subtext?: string;
}

interface CommandItem {
  cmd: string;
  icon: string;
  desc: string;
  value: string;
  payload?: any;
}

type CommandCategories = {
  [key in 'system' | 'apps' | 'search' | 'code' | 'memory' | 'files']: CommandItem[];
};

interface ChatMessage {
  id: number;
  role: 'ai' | 'user';
  content: string;
  timestamp: string;
}

interface WorkerStatus {
  name: string;
  icon: React.ReactNode;
  active: boolean;
  model?: string;
}

// --- CONFIGURATION ---
const SOVEREIGN_COMMANDS: CommandCategories = {
  system: [
    { cmd: "Check CPU usage", icon: "⚡", desc: "Real-time query", value: "fetch", payload: { query: 'cpu_usage' } },
    { cmd: "Analyze RAM", icon: "🧠", desc: "Memory breakdown", value: "analyze", payload: { query: 'ram_usage' } },
    { cmd: "GPU temperature", icon: "🌡️", desc: "RTX 3060 stats", value: "48°C", payload: { query: 'gpu_temp' } },
    { cmd: "System health", icon: "🩺", desc: "Full diagnostic", value: "Run", payload: { action: 'health_check' } },
  ],
  apps: [
    { cmd: "Launch VS Code", icon: "💻", desc: "Dev editor", value: "Launch", payload: { app: 'vscode' } },
    { cmd: "Spotify Control", icon: "🎵", desc: "Music player", value: "Open", payload: { app: 'spotify' } },
    { cmd: "Terminal", icon: "⌨️", desc: "Cli access", value: "Ready", payload: { app: 'terminal' } },
  ],
  search: [
    { cmd: "AI news", icon: "🔍", desc: "Latest updates", value: "12 new", payload: { search: 'ai news' } },
    { cmd: "Quantum trends", icon: "🔬", desc: "Research", value: "3 papers", payload: { search: 'quantum computing' } },
  ],
  code: [
    { cmd: "Clean my code", icon: "🧹", desc: "Run linter", value: "Scan", payload: { action: 'lint' } },
    { cmd: "Explain error", icon: "❓", desc: "Debug assistant", value: "Active", payload: { action: 'debug' } },
  ],
  memory: [
    { cmd: "Remember this", icon: "💾", desc: "Save context", value: "Store", payload: { action: 'remember' } },
    { cmd: "Recall last chat", icon: "🔄", desc: "Previous session", value: "Load", payload: { action: 'recall' } },
  ],
  files: [
    { cmd: "Downloads folder", icon: "⬇️", desc: "Access files", value: "1.2GB", payload: { path: '~/Downloads' } },
    { cmd: "Analyze large files", icon: "📦", desc: "Storage usage", value: "Scan", payload: { action: 'analyze' } },
  ]
};

const WORKERS: WorkerStatus[] = [
  { name: "Brain Worker", icon: <Brain size={18} />, active: true, model: "Llama 3.2 3B" },
  { name: "Eyes Worker", icon: <Eye size={18} />, active: false },
  { name: "Hands Worker", icon: <Hand size={18} />, active: false },
  { name: "Memory Worker", icon: <Database size={18} />, active: false },
];

const STATIC_METRICS: SystemMetric[] = [
  { 
    name: "CPU", 
    value: 29.0, 
    icon: <Cpu size={20} />, 
    color: "#5a9eff", 
    unit: "%",
    subtext: "8-core"
  },
  { 
    name: "RAM", 
    value: 46.0, 
    icon: <Zap size={20} />, 
    color: "#9f7aff", 
    unit: "%",
    subtext: "32GB"
  },
  { 
    name: "GPU", 
    value: 19.0, 
    icon: <Activity size={20} />, 
    color: "#5aff9e", 
    unit: "%",
    subtext: "RTX 3060"
  },
  { 
    name: "NET", 
    value: 16.88, 
    icon: <Network size={20} />, 
    color: "#ff7a5a", 
    unit: "MB/s",
    subtext: ""
  }
];

const DOC_ITEMS = [
  { icon: "📄", name: "page.tsx" },
  { icon: "📄", name: "route.ts" },
  { icon: "🤖", name: "Sovereign AI" },
  { icon: "⚡", name: "REZ HIVE" },
  { icon: "🧠", name: "Cognitive" },
  { icon: "🖥️", name: "next-server" }
];

export default function SovereignDashboard() {
  const [input, setInput] = useState('');
  const [chatLog, setChatLog] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [activeCategory, setActiveCategory] = useState<keyof CommandCategories>('system');
  const [recentCommands, setRecentCommands] = useState<string[]>([]);
  const [metrics, setMetrics] = useState<SystemMetric[]>(STATIC_METRICS);
  const [timestamp, setTimestamp] = useState('');
  const [temperature, setTemperature] = useState(47);
  const [isMounted, setIsMounted] = useState(false);
  const [uptime, setUptime] = useState(3851);
  const [activeWorkers, setActiveWorkers] = useState(23);
  const [networkDown, setNetworkDown] = useState(16.08);
  const [networkUp, setNetworkUp] = useState(3.48);
  const [quotas, setQuotas] = useState({ 
    session: { used: 45, total: 100 }, 
    weekly: { used: 320, total: 1000 } 
  });
  const [activeWorker, setActiveWorker] = useState('Brain Worker');
  
  const chatEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setIsMounted(true);
    
    const now = new Date();
    const timeString = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    setTimestamp(timeString);
    
    setChatLog([{
      id: Date.now(),
      role: 'ai',
      content: 'Brain Worker (Llama 3.2 3B) is awaiting cognitive tasks.',
      timestamp: timeString,
    }]);

    // Load recent commands from localStorage
    try {
      const saved = localStorage.getItem('sovereign_recent');
      if (saved) {
        setRecentCommands(JSON.parse(saved));
      }
    } catch (e) {
      console.error('Failed to load recent commands:', e);
    }

    // Simulate live updates
    const timer = setInterval(() => {
      const liveNow = new Date();
      setTimestamp(liveNow.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
      
      setMetrics(prev => prev.map(m => ({
        ...m,
        value: m.name === "CPU" ? 25 + Math.random() * 15 :
               m.name === "RAM" ? 40 + Math.random() * 10 :
               m.name === "GPU" ? 15 + Math.random() * 15 :
               15 + Math.random() * 10
      })));
      
      setTemperature(45 + Math.floor(Math.random() * 8));
      setUptime(prev => prev + 4);
      setActiveWorkers(20 + Math.floor(Math.random() * 10));
      setNetworkDown(15 + Math.random() * 5);
      setNetworkUp(3 + Math.random() * 2);
      
      setQuotas({
        session: { used: Math.floor(Math.random() * 80), total: 100 },
        weekly: { used: Math.floor(Math.random() * 500), total: 1000 }
      });
    }, 4000);

    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    if (chatEndRef.current) {
      chatEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [chatLog]);

  const executeAction = async (commandText: string, payload?: any) => {
    if (!commandText.trim()) return;
    
    const now = new Date();
    const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    // Add user message
    const userMsg: ChatMessage = {
      id: Date.now(),
      role: 'user',
      content: commandText,
      timestamp: timeStr,
    };
    setChatLog(prev => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    // Update recent commands
    const updatedRecents = [commandText, ...recentCommands.filter(c => c !== commandText)].slice(0, 6);
    setRecentCommands(updatedRecents);
    
    try {
      localStorage.setItem('sovereign_recent', JSON.stringify(updatedRecents));
    } catch (e) {
      console.error('Failed to save recent commands:', e);
    }
    
    try {
      // Call the kernel API
      const res = await fetch('/api/kernel', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
          task: commandText, 
          worker: activeWorker.toLowerCase().replace(' worker', ''),
          ...payload 
        }),
      });
      
      if (!res.ok) {
        throw new Error(`Kernel Error: ${res.statusText}`);
      }

      const data = await res.json();
      const aiResponseContent = data.content || data.response || data.answer || `Executed: ${commandText}`;

      // Add AI response
      setChatLog(prev => [...prev, {
        id: Date.now() + 1,
        role: 'ai',
        content: aiResponseContent,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      }]);

    } catch (error) {
      console.error('API Error:', error);
      
      // Fallback response for development
      setChatLog(prev => [...prev, {
        id: Date.now() + 1,
        role: 'ai',
        content: `**⚡ Command Received**\n\nExecuted: \`${commandText}\`\n\n\`\`\`json\n${JSON.stringify(payload || {}, null, 2)}\n\`\`\``,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      }]);
    } finally {
      setLoading(false);
    }
  };

  const handleWorkerClick = (workerName: string) => {
    setActiveWorker(workerName);
    executeAction(`Switch to ${workerName}`);
  };

  return (
    <div className="min-h-screen bg-[#030405] text-white font-sans relative overflow-hidden"><div className="noise-overlay"></div>
      {/* Background gradients */}
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute top-20 left-20 w-96 h-96 bg-cyan-500/5 rounded-full blur-3xl" />
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-purple-500/5 rounded-full blur-3xl" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-orange-500/3 rounded-full blur-3xl" />
      </div>

      {/* ========== LEFT SIDEBAR - WORKERS ========== */}
      <div className="fixed left-0 top-0 bottom-0 w-64 premium-glass z-40 flex flex-col">
        {/* <span class="gradient-text-accent">REZ HIVE</span> Logo */}
        <div className="p-6 border-b border-white/10">
          <h1 className="text-xl font-bold bg-gradient-to-r from-cyan-400 via-purple-400 to-orange-400 bg-clip-text text-transparent">
            <span class="gradient-text-accent">REZ HIVE</span>
          </h1>
          <div className="text-xs text-white/30 mt-1 font-mono">Sovereign OS v5.0</div>
        </div>

        {/* Worker Navigation */}
        <div className="flex-1 p-4 space-y-1">
          <div className="text-xs text-white/30 uppercase tracking-wider mb-3 px-3 font-mono">
            Workers
          </div>
          
          {WORKERS.map((worker) => (
            <button
              key={worker.name}
              onClick={() => handleWorkerClick(worker.name)}
              className={`worker-item w-full flex items-center gap-3 px-3 py-3 rounded-xl transition-all ${
                activeWorker === worker.name
                  ? 'chat-message-user text-cyan-400' 
                  : 'hover:bg-white/5 text-white/60 hover:text-white/80'
              }`}
            >
              <span className={activeWorker === worker.name ? 'text-cyan-400' : 'text-white/40'}>
                {worker.icon}
              </span>
              <span className="text-sm font-medium flex-1 text-left">{worker.name}</span>
              {worker.active && (
                <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
              )}
            </button>
          ))}
        </div>

        {/* System Stats */}
        <div className="p-4 border-t border-white/10 space-y-3">
          <div className="flex justify-between text-xs">
            <span className="text-white/40 font-mono">UPTIME</span>
            <span className="text-cyan-400 font-mono">{uptime}s</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-white/40 font-mono">ACTIVE</span>
            <span className="text-green-400 font-mono">{activeWorkers}</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-white/40 font-mono">DOWNLOAD</span>
            <span className="text-purple-400 font-mono">{networkDown.toFixed(2)} MB/s</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-white/40 font-mono">UPLOAD</span>
            <span className="text-orange-400 font-mono">{networkUp.toFixed(2)} MB/s</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-white/40 font-mono">TEMP</span>
            <span className={temperature > 65 ? "text-red-400 font-mono" : "text-orange-400 font-mono"}>
              {temperature}°C
            </span>
          </div>
        </div>

        {/* Memory Context Link */}
        <div className="p-4 border-t border-white/10">
          <button className="w-full flex items-center justify-between text-xs text-white/40 hover:text-white/60 transition-colors font-mono" class="has-tooltip">
            <span>MEMORY CONTEXT</span>
            <span className="text-cyan-400">→</span>
          </button>
        </div>
      </div>

      {/* BUILD MODE PILL - Top Center */}
      <div className="fixed top-6 left-1/2 -translate-x-1/2 z-50">
        <div className="bg-black/80 backdrop-blur-xl border border-yellow-500/30 rounded-full px-5 py-2 flex items-center gap-3 shadow-[0_10px_30px_rgba(0,0,0,0.5)]">
          <span className="text-yellow-500 text-lg">⧉</span>
          <span className="text-white/80 text-sm font-medium">BUILD MODE</span>
          <span className="bg-yellow-500/10 text-yellow-500 px-2 py-0.5 rounded-full text-xs relative pl-5 border border-yellow-500/20">
            <span className="absolute left-2 top-1/2 -translate-y-1/2 w-2 h-2 bg-yellow-500 rounded-full animate-pulse" />
            LIVE
          </span>
          <span className="text-white/40 text-sm font-mono">{timestamp}</span>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="pl-64 pr-80 pt-24 pb-8 min-h-screen">
        {/* Metrics Grid */}
        <div className="grid grid-cols-4 gap-5 mb-8">
          {metrics.map((metric, idx) => (
            <div
              key={metric.name}
              className="premium-card metric-card-premium transition-all group"
            >
              <div className="flex justify-between items-start mb-4">
                <span className="text-white/40 text-sm font-medium font-mono">{metric.name}</span>
                <span className="text-white/60 group-hover:text-cyan-400 transition-colors">{metric.icon}</span>
              </div>
              <div className="text-4xl font-bold mb-2 font-mono">
                {metric.value.toFixed(1)}
                <span className="text-sm font-normal text-white/40 ml-1 font-mono">{metric.unit}</span>
              </div>
              <div className="h-1.5 bg-white/10 rounded-full overflow-hidden mb-3">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{ width: `${metric.value}%`, backgroundColor: metric.color }}
                />
              </div>
              {metric.subtext && (
                <div className="text-xs text-white/30 font-mono">{metric.subtext}</div>
              )}
            </div>
          ))}
        </div>

        {/* READY Status */}
        <div className="mb-4">
          <span className="text-xs font-mono text-green-400 bg-green-500/10 px-3 py-1.5 rounded-full border border-green-500/20 inline-flex items-center gap-2">
            <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
            SYSTEM READY
          </span>
        </div>

        {/* Brain Worker Status */}
        <div className="mb-4 text-sm text-white/60 bg-white/5 px-4 py-2 rounded-lg border border-white/5 inline-block">
          <Brain size={14} className="inline mr-2 text-cyan-400" />
          Brain Worker (Llama 3.2 3B) is awaiting cognitive tasks.
        </div>

        {/* Chat Input */}
        <div className="mb-6">
          <div className="flex gap-3">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && executeAction(input)}
              placeholder="Query Brain Worker..."
              className="flex-1 chat-message-ai rounded-xl px-4 py-3 text-white text-sm outline-none focus:border-cyan-500/40 transition-all font-mono placeholder:text-white/20"
            />
            <button
              onClick={() => executeAction(input)}
              disabled={loading}
              className="px-6 py-3 bg-cyan-500/10 border border-cyan-500/30 rounded-xl text-cyan-400 hover:bg-cyan-400 hover:text-black transition-all font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? '...' : 'Send'}
            </button>
          </div>
        </div>

        {/* Chat Log */}
        <div className="bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl mb-6 overflow-hidden">
          <div className="h-[30vh] overflow-y-auto p-4 space-y-3">
            {chatLog.map((msg) => (
              <div key={msg.id} className={`flex gap-3 ${msg.role === 'user' ? 'flex-row-reverse' : ''}`}>
                <div className={`w-6 h-6 rounded-lg flex items-center justify-center flex-shrink-0 text-xs ${
                  msg.role === 'ai' 
                    ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20' 
                    : 'bg-white/10 text-white border border-white/20'
                }`}>
                  {msg.role === 'ai' ? '🤖' : 'U'}
                </div>
                <div className={`max-w-[80%] ${msg.role === 'user' ? 'text-right' : ''}`}>
                  <div className="text-xs text-white/30 mb-1 font-mono">{msg.timestamp}</div>
                  <div className={`text-sm rounded-xl p-3 ${
                    msg.role === 'ai' 
                      ? 'chat-message-ai' 
                      : 'chat-message-user'
                  }`}>
                    <ReactMarkdown 
                      remarkPlugins={[remarkGfm]} 
                      className="prose prose-invert max-w-none"
                      components={{
                        code({node, inline, className, children, ...props}) {
                          return (
                            <code className={className + ' bg-black/30 px-1 py-0.5 rounded text-cyan-300'} {...props}>
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
            {loading && (
              <div className="flex gap-3">
                <div className="w-6 h-6 rounded-lg chat-message-user flex items-center justify-center text-cyan-400">
                  🤖
                </div>
                <div className="flex gap-1 text-cyan-400 text-xl">
                  <span className="animate-bounce">.</span>
                  <span className="animate-bounce delay-100">.</span>
                  <span className="animate-bounce delay-200">.</span>
                </div>
              </div>
            )}
            <div ref={chatEndRef} />
          </div>
        </div>

        {/* Category Tabs */}
        <div className="flex gap-2 mb-4 overflow-x-auto pb-2 no-scrollbar">
          {Object.keys(SOVEREIGN_COMMANDS).map((category) => (
            <button
              key={category}
              onClick={() => setActiveCategory(category as keyof CommandCategories)}
              className={`px-4 py-2 rounded-lg text-xs font-medium transition-all font-mono whitespace-nowrap ${
                activeCategory === category
                  ? 'bg-cyan-500/10 border border-cyan-500/30 text-cyan-400'
                  : 'bg-transparent border border-white/10 text-white/40 hover:bg-white/5 hover:text-white/60'
              }`}
            >
              {category.toUpperCase()}
            </button>
          ))}
        </div>

        {/* Action Cards Grid */}
        <div className="grid grid-cols-4 gap-4 mb-8">
          {SOVEREIGN_COMMANDS[activeCategory].slice(0, 4).map((cmd, idx) => (
            <button
              key={idx}
              onClick={() => executeAction(cmd.cmd, cmd.payload)}
              className="chat-message-ai rounded-xl p-4 text-left hover:bg-white/10 hover:border-white/20 transition-all group"
            >
              <div className="flex items-center gap-3 mb-2">
                <span className="text-2xl group-hover:scale-110 transition-transform">{cmd.icon}</span>
                <div>
                  <div className="text-sm font-medium text-white/90">{cmd.cmd}</div>
                  <div className="text-xs text-white/40 font-mono">{cmd.desc}</div>
                </div>
              </div>
              <div className="text-xs text-cyan-400 bg-cyan-500/10 px-2 py-1 rounded inline-block font-mono">
                {cmd.value}
              </div>
            </button>
          ))}
        </div>

        {/* GPU ENGINE Section */}
        <div className="mb-6">
          <div className="text-xs text-white/30 uppercase tracking-wider mb-2 font-mono flex items-center gap-2">
            <Thermometer size={14} className="text-orange-400" />
            GPU ENGINE
          </div>
          <div className="bg-white/5 backdrop-blur-xl border border-white/10 rounded-xl p-4">
            <div className="flex justify-between items-center">
              <span className="text-sm text-white/60 font-mono">NVIDIA RTX 3060</span>
              <span className="text-2xl font-bold text-purple-400 font-mono">{temperature}°C</span>
            </div>
            <div className="h-1.5 bg-white/10 rounded-full mt-3 overflow-hidden">
              <div 
                className="h-full bg-gradient-to-r from-cyan-400 to-purple-400 rounded-full transition-all duration-500"
                style={{ width: `${(temperature - 40) * 5}%` }}
              />
            </div>
          </div>
        </div>

        {/* Recent Commands */}
        {recentCommands.length > 0 && (
          <div className="mb-6">
            <h3 className="text-xs font-bold text-white/40 uppercase tracking-wider mb-3 font-mono flex items-center gap-2">
              <Clock size={14} />
              RECENT COMMANDS
            </h3>
            <div className="flex flex-wrap gap-2">
              {recentCommands.map((cmd, i) => (
                <button
                  key={i}
                  onClick={() => executeAction(cmd)}
                  className="px-3 py-1.5 chat-message-ai rounded-lg text-xs text-white/60 hover:text-white/80 hover:bg-white/10 transition-all font-mono"
                >
                  {cmd.length > 20 ? cmd.substring(0, 20) + '...' : cmd}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Status Footer */}
        <div className="flex justify-between items-center text-xs text-white/30 border-t border-white/10 pt-6">
          <div className="flex gap-4 flex-wrap">
            {DOC_ITEMS.map((item, idx) => (
              <span key={idx} className="flex items-center gap-1 hover:text-white/60 cursor-pointer transition-colors font-mono">
                <span>{item.icon}</span>
                <span>{item.name}</span>
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* Right Sidebar - TwoBarMeter */}
      <div className="fixed right-6 top-24 w-80 z-40">
        <div className="bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl p-4">
          <TwoBarMeter
            sessionPercent={(quotas.session.used / quotas.session.total) * 100}
            weeklyPercent={(quotas.weekly.used / quotas.weekly.total) * 100}
            resetTime={Date.now() + 7200000}
          />
        </div>
      </div>

      {/* PrimordialUI */}
      <PrimordialUI />

      {/* Global styles */}
      <style jsx global>{`
        .prose {
          max-width: none;
          font-size: 0.85rem;
        }
        .prose p {
          margin: 0 0 0.5rem 0;
        }
        .prose p:last-child {
          margin-bottom: 0;
        }
        .prose code {
          color: #82b1ff;
          background: rgba(130, 177, 255, 0.1);
          padding: 2px 4px;
          border-radius: 4px;
          font-family: 'JetBrains Mono', monospace;
        }
        .prose pre {
          background: rgba(0, 0, 0, 0.3);
          border: 1px solid rgba(255, 255, 255, 0.1);
          border-radius: 8px;
          padding: 0.75rem;
          font-family: 'JetBrains Mono', monospace;
        }
        .no-scrollbar::-webkit-scrollbar {
          display: none;
        }
        .no-scrollbar {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </div>
  );
}



