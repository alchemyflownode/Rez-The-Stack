'use client';

import { useState, useEffect, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import '@/styles/dual-theme.css';
import { PrimordialUI } from '../components/PrimordialUI';
import { TwoBarMeter } from '../components/TwoBarMeter';
import { IntimacyFactory } from '../kernel/psalm139/IntimacyFactory';

// --- TYPES & INTERFACES ---
interface SystemMetric {
  name: string;
  value: number;
  icon: string;
  color: string;
  unit: string;
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
  meta?: {
    cpu?: number;
    temp?: number;
  };
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
    { cmd: "Launch VS Code", icon: "💻", desc: "Dev editor", value: "Launch" },
    { cmd: "Spotify Control", icon: "🎵", desc: "Music player", value: "Open" },
    { cmd: "Terminal", icon: "⌨️", desc: "Cli access", value: "Ready" },
  ],
  search: [
    { cmd: "AI news", icon: "🔍", desc: "Latest updates", value: "12 new" },
    { cmd: "Quantum trends", icon: "🔬", desc: "Research", value: "3 papers" },
  ],
  code: [
    { cmd: "Clean my code", icon: "🧹", desc: "Run linter", value: "Scan" },
    { cmd: "Explain error", icon: "❓", desc: "Debug assistant", value: "Active" },
  ],
  memory: [
    { cmd: "Remember this", icon: "💾", desc: "Save context", value: "Store" },
    { cmd: "Recall last chat", icon: "🔄", desc: "Previous session", value: "Load" },
  ],
  files: [
    { cmd: "Downloads folder", icon: "⬇️", desc: "Access files", value: "1.2GB" },
    { cmd: "Analyze large files", icon: "📦", desc: "Storage usage", value: "Scan" },
  ]
};

const STATIC_METRICS: SystemMetric[] = [
  { name: "CPU", value: 24.5, icon: "⚡", color: "#5a9eff", unit: "%" },
  { name: "RAM", value: 43.2, icon: "🧠", color: "#9f7aff", unit: "%" },
  { name: "DISK", value: 62.4, icon: "💾", color: "#ff7a5a", unit: "%" },
  { name: "GPU", value: 12.8, icon: "🎮", color: "#5aff9e", unit: "%" }
];

const DOC_ITEMS = [
  "📄 page.tsx", "📄 route.ts", "🤖 Sovereign AI",
  "⚡ REZ HIVE", "🧠 Cognitive", "🖥️ next-server"
];

export default function SovereignDashboard() {
  const [input, setInput] = useState('');
  const [chatLog, setChatLog] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [activeCategory, setActiveCategory] = useState<keyof CommandCategories>('system');
  const [recentCommands, setRecentCommands] = useState<string[]>([]);
  
  const [metrics, setMetrics] = useState<SystemMetric[]>(STATIC_METRICS);
  const [timestamp, setTimestamp] = useState('');
  const [temperature, setTemperature] = useState(48);
  const [isMounted, setIsMounted] = useState(false);
  const [sacredInsights, setSacredInsights] = useState<string[]>([]);
  const [quotas, setQuotas] = useState({ 
    session: { used: 45, total: 100 }, 
    weekly: { used: 320, total: 1000 } 
  });
  
  const chatEndRef = useRef<HTMLDivElement>(null);

  // Client-side initialization
  useEffect(() => {
    setIsMounted(true);
    
    // Load Recent Commands
    const saved = localStorage.getItem('sovereign_recent');
    if (saved) {
      setRecentCommands(JSON.parse(saved));
    }
    
    // Initial Chat Message
    const now = new Date();
    setTimestamp(now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
    setChatLog([{
      id: Date.now(),
      role: 'ai',
      content: 'System initialized. Sovereign Kernel running optimally at 52°C. Waiting for input.',
      timestamp: now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      meta: { cpu: 24.5, temp: 48 }
    }]);
    
    // Load sacred insights
    const loadInsights = async () => {
      try {
        const observer = await IntimacyFactory.getObserver();
        const insights = await observer.getInsights();
        setSacredInsights(insights);
      } catch (e) {
        console.log('Sacred insights not ready yet');
      }
    };
    loadInsights();
    
    // Status Intervals
    const timer = setInterval(() => {
      const liveNow = new Date();
      setTimestamp(liveNow.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
      
      setMetrics(prev => prev.map(m => ({
        ...m,
        value: m.name === "CPU" ? 20 + Math.random() * 15 :
               m.name === "RAM" ? 40 + Math.random() * 10 :
               m.name === "DISK" ? 62.4 :
               10 + Math.random() * 20
      })));
      
      setTemperature(Math.floor(45 + Math.random() * 10));
      
      // Update mock quotas
      setQuotas({
        session: { used: Math.floor(Math.random() * 80), total: 100 },
        weekly: { used: Math.floor(Math.random() * 500), total: 1000 }
      });
    }, 4000);
    
    return () => clearInterval(timer);
  }, []);

  // Auto-scroll chat
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatLog]);

  const executeAction = async (commandText: string, payload?: any) => {
    if (!commandText.trim()) return;
    
    const now = new Date();
    const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    const userMsg: ChatMessage = {
      id: Date.now(),
      role: 'user',
      content: commandText,
      timestamp: timeStr,
    };
    setChatLog(prev => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    const updatedRecents = [commandText, ...recentCommands.filter(c => c !== commandText)].slice(0, 6);
    setRecentCommands(updatedRecents);
    localStorage.setItem('sovereign_recent', JSON.stringify(updatedRecents));
    
    try {
      const res = await fetch('/api/kernel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: commandText, ...payload })
      });
      
      if (!res.ok) throw new Error(`Kernel Error: ${res.statusText}`);

      const data = await res.json();
      const aiResponseContent = data.content || data.response || data.answer || "Command executed.";

      setChatLog(prev => [...prev, {
        id: Date.now() + 1,
        role: 'ai',
        content: aiResponseContent,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      }]);

    } catch (error) {
      setChatLog(prev => [...prev, {
        id: Date.now() + 1,
        role: 'ai',
        content: `**⚠️ System Error**\n\nFailed to execute \`${commandText}\`. Error details: \n\n\`\`\`text\n${error}\n\`\`\``,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      }]);
    } finally {
      setLoading(false);
    }
  };

  const renderMessageContent = (content: string) => {
    return (
      <ReactMarkdown remarkPlugins={[remarkGfm]}>
        {content}
      </ReactMarkdown>
    );
  };

  return (
    <div className="sovereign-root">
      {/* BUILD MODE PILL */}
      <div className="build-pill">
        <span className="build-icon">⧉</span>
        <span className="build-text">BUILD MODE</span>
        <span className="build-status">LIVE</span>
        <span className="build-time">{timestamp || '--:--'}</span>
      </div>

      {/* SIDE BUTTONS */}
      <div className="side-nav">
        {['⌘', '⎇', '⌥', '⚙️'].map(icon => (
          <button key={icon} className="nav-btn">{icon}</button>
        ))}
      </div>

      <div className="content-frame fade-in">
        {/* TITLE BAR */}
        <div className="title-bar">
          <div className="left-group">
            <div className="window-controls">
              <div className="dot"></div>
              <div className="dot"></div>
              <div className="dot"></div>
            </div>
            <span className="title-text">AETHER · KERNEL COMMAND CENTER</span>
          </div>
          <div className="version-badge">v3.1.2 · Operational</div>
        </div>

        {/* METRICS ROW */}
        <div className="metrics-grid">
          {metrics.map((metric, i) => (
            <div key={metric.name} className="metric-card glass-morph" style={{ animationDelay: `${i * 100}ms` }}>
              <div className="metric-header">
                <span className="metric-name">{metric.name}</span>
                <span className="metric-icon">{metric.icon}</span>
              </div>
              <div className="metric-body">
                <div className="metric-value-group">
                  {metric.value.toFixed(1)}<span className="metric-unit">{metric.unit}</span>
                </div>
                <div className="progress-track">
                  <div 
                    className="progress-fill" 
                    style={{ width: `${metric.value}%`, background: metric.color }}
                  ></div>
                </div>
              </div>
              {metric.name === "GPU" && (
                <div className="gpu-meta">RTX 3060 · {temperature}°C</div>
              )}
            </div>
          ))}
        </div>

        {/* CHAT LOG & INPUT */}
        <div className="chat-interface glass-morph">
          <div className="chat-log">
            {chatLog.map((msg) => (
              <div key={msg.id} className={`chat-row ${msg.role}`}>
                <div className="avatar">{msg.role === 'ai' ? '🤖' : 'U'}</div>
                <div className="message-wrapper">
                  <div className="message-header">
                    <span className="sender">{msg.role === 'ai' ? 'Sovereign AI' : 'User'}</span>
                    <span className="time">{msg.timestamp}</span>
                  </div>
                  <div className="message-content prose prose-invert">
                    {renderMessageContent(msg.content)}
                  </div>
                </div>
              </div>
            ))}
            {loading && (
              <div className="chat-row ai thinking">
                <div className="avatar animate-pulse">🤖</div>
                <div className="message-wrapper">
                  <div className="thinking-dots"><span>.</span><span>.</span><span>.</span></div>
                </div>
              </div>
            )}
            <div ref={chatEndRef} />
          </div>
          
          <div className="input-zone">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && executeAction(input)}
              placeholder="Ask Sovereign or type command..."
              className="sovereign-input"
            />
            <button className="send-btn" onClick={() => executeAction(input)}>↵</button>
          </div>
        </div>

        {/* CATEGORY NAV */}
        <div className="pill-nav">
          {Object.keys(SOVEREIGN_COMMANDS).map((category) => (
            <button
              key={category}
              onClick={() => setActiveCategory(category as keyof CommandCategories)}
              className={`pill ${activeCategory === category ? 'active' : ''}`}
            >
              {category}
            </button>
          ))}
        </div>

        {/* COMMAND GRID */}
        <div className="action-grid">
          {SOVEREIGN_COMMANDS[activeCategory].map((cmd, i) => (
            <button
              key={i}
              onClick={() => executeAction(cmd.cmd, cmd.payload)}
              className="action-card"
            >
              <div className="card-top">
                <div className="card-icon-frame">{cmd.icon}</div>
                <div className="card-desc-group">
                  <div className="card-label">{cmd.cmd}</div>
                  <div className="card-desc">{cmd.desc}</div>
                </div>
              </div>
              <div className="card-status">{cmd.value}</div>
            </button>
          ))}
        </div>

        {/* RECENT COMMANDS */}
        {recentCommands.length > 0 && (
          <div className="recent-container">
            <h3 className="section-title">RECENT COMMANDS</h3>
            <div className="recent-list">
              {recentCommands.map((cmd, i) => (
                <button
                  key={i}
                  onClick={() => executeAction(cmd)}
                  className="recent-pill"
                >
                  {cmd.length > 30 ? cmd.substring(0, 30) + '...' : cmd}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* STATUS BAR */}
        <div className="status-footer">
          <div className="doc-tray">
            {DOC_ITEMS.map((item, i) => (
              <span key={i} className="doc-item">
                <span className="doc-type-icon">{item.split(' ')[0]}</span>
                <span className="doc-name">{item.split(' ').slice(1).join(' ')}</span>
              </span>
            ))}
          </div>
          <div className={`temp-badge ${temperature > 65 ? 'high' : ''}`}>
            🌡️ {temperature || '--'}°C
          </div>
        </div>
      </div>

      {/* ========== PRIMORDIAL LAYER ========== */}

      {/* Primordial UI with Agent Status, Thoughts, Suggestions */}
      <PrimordialUI />

      {/* Sacred Insights from Psalm 139 Memory */}
      {sacredInsights.length > 0 && (
        <div className="fixed top-40 right-4 w-72 z-40 mt-2">
          <div className="glass-card p-3 border-l-4 border-purple-500">
            <div className="flex items-center gap-2 mb-2">
              <span className="w-1.5 h-1.5 rounded-full bg-purple-400 animate-pulse" />
              <span className="text-xs font-mono text-purple-400">sacred insights</span>
            </div>
            {sacredInsights.map((insight, i) => (
              <p key={i} className="text-xs text-white/60 italic mb-1">✨ {insight}</p>
            ))}
          </div>
        </div>
      )}

      {/* CodexBar Two-Bar Meter */}
      <div className="fixed bottom-4 right-4 z-40">
        <div className="glass-card p-3 rounded-lg">
          <TwoBarMeter
            sessionPercent={(quotas.session.used / quotas.session.total) * 100}
            weeklyPercent={(quotas.weekly.used / quotas.weekly.total) * 100}
            resetTime={Date.now() + 7200000}
          />
          <div className="flex justify-between mt-1 text-[8px] text-white/20">
            <span>session</span>
            <span>weekly</span>
          </div>
        </div>
      </div>

      {/* --- STYLES --- */}
      <style jsx global>{`
        .prose { max-width: none; font-size: 0.95rem; }
        .prose p { margin-top: 0; margin-bottom: 0.5rem; }
        .prose pre { background: rgba(0,0,0,0.4); border: 1px solid rgba(255,255,255,0.1); padding: 0.75rem; border-radius: 8px;}
        .prose code { color: #82b1ff; background: rgba(130,177,255,0.1); padding: 2px 4px; border-radius: 4px;}
        .prose strong { color: #fff; font-weight: 600;}
      `}</style>
    </div>
  );
}