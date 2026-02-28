'use client';

import { useState, useEffect, useRef, Key } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import '@/styles/dual-theme.css'; // Assuming this contains global vars, but styles are defined in styled-jsx

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
  payload?: any; // For dynamic API calls
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

// --- CONFIGURATION / MOCK DATA ---
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

// --- PREMIUM COMPONENT ---
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
  
  const chatEndRef = useRef<HTMLDivElement>(null);

  // Client-side initialization
  useEffect(() => {
    setIsMounted(true);
    
    // 1. Load Recent Commands
    const saved = localStorage.getItem('sovereign_recent');
    if (saved) {
      setRecentCommands(JSON.parse(saved));
    }
    
    // 2. Initial Chat Message
    const now = new Date();
    setTimestamp(now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
    setChatLog([{
      id: Date.now(),
      role: 'ai',
      content: 'System initialized. Sovereign Kernel running optimally at 52°C. Waiting for input.',
      timestamp: now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      meta: { cpu: 24.5, temp: 48 }
    }]);
    
    // 3. Status Intervals (CPU/RAM Sim)
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
    }, 4000); // 4s interval for smoother perception
    
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

    // 1. Add User Message
    const userMsg: ChatMessage = {
      id: Date.now(),
      role: 'user',
      content: commandText,
      timestamp: timeStr,
    };
    setChatLog(prev => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    // 2. Update Recent Commands
    const updatedRecents = [commandText, ...recentCommands.filter(c => c !== commandText)].slice(0, 6);
    setRecentCommands(updatedRecents);
    localStorage.setItem('sovereign_recent', JSON.stringify(updatedRecents));
    
    // 3. API Call
    try {
      const res = await fetch('/api/kernel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: commandText, ...payload })
      });
      
      if (!res.ok) throw new Error(`Kernel Error: ${res.statusText}`);

      const data = await res.json();
      
      // 4. Handle AI Response (expecting markdown or structured text)
      const aiResponseContent = data.content || data.response || data.answer || "Command executed, but no response data returned.";

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

  // Adapter to render chat content professionally
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
        <span className="build-time">{isMounted ? timestamp : '--:--'}</span>
      </div>

      {/*SIDE BUTTONS - Removed tooltips for cleaner look, added hover animation */}
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

        {/* METRICS ROW - Premium Depth */}
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

        {/* CHAT LOG & INPUT - The AI Focus */}
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
        {isMounted && recentCommands.length > 0 && (
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

        {/*STATUS BAR - Refined */}
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
            🌡️ {isMounted ? temperature : '--'}°C
          </div>
        </div>
      </div>

      {/* --- PREMIUM STYLESHEET --- */}
      <style jsx global>{`
        /* Minimal Tailwind reset/prose override for Premium grade */
        .prose { max-width: none; font-size: 0.95rem; }
        .prose p { margin-top: 0; margin-bottom: 0.5rem; }
        .prose pre { background: rgba(0,0,0,0.4); border: 1px solid rgba(255,255,255,0.1); padding: 0.75rem; border-radius: 8px;}
        .prose code { color: #82b1ff; background: rgba(130,177,255,0.1); padding: 2px 4px; border-radius: 4px;}
        .prose strong { color: #fff; font-weight: 600;}
      `}</style>
      <style jsx>{`
        /* Color Palette & Vars */
        :react {
          --bg-dark: #020203;
          --panel-bg: rgba(10, 12, 16, 0.65);
          --card-bg: rgba(18, 21, 27, 0.6);
          --accent: #5a9eff;
          --border: rgba(255, 255, 255, 0.04);
          --border-bright: rgba(255, 255, 255, 0.08);
          --text-muted: rgba(255, 255, 255, 0.4);
          --shadow-premium: 0 20px 50px -12px rgba(0, 0, 0, 0.8);
        }

        .sovereign-root {
          background: #000; /* True black background */
          background-image: radial-gradient(at 50% 100%, #06080c 0%, #000 100%);
          min-height: 100vh;
          color: #fff;
          font-family: 'SF Pro Display', -apple-system, Inter, sans-serif;
          padding: 6vh 2vw; /* Use viewport units for padding */
          position: relative;
          overflow-x: hidden;
        }

        .fade-in { animation: fadeIn 0.8s ease-out; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

        .content-frame {
          max-width: 1300px;
          margin: 0 auto;
          background: var(--panel-bg);
          backdrop-filter: blur(40px) saturate(180%);
          border: 1px solid var(--border-bright);
          border-radius: 40px;
          padding: 40px;
          box-shadow: var(--shadow-premium);
        }

        .glass-morph {
          background: rgba(255, 255, 255, 0.01);
          border: 1px solid rgba(255, 255, 255, 0.03);
          box-shadow: inset 0 1px 1px rgba(255,255,255,0.01);
          transition: border-color 0.3s, box-shadow 0.3s;
        }

        /* Build mode updated with active pulsing dot */
        .build-pill {
          position: fixed;
          top: 24px;
          left: 50%;
          transform: translateX(-50%);
          background: rgba(8, 10, 13, 0.95);
          border: 1px solid rgba(255, 215, 100, 0.3);
          box-shadow: 0 10px 30px rgba(0,0,0,0.5);
          border-radius: 100px;
          padding: 10px 20px;
          display: flex;
          align-items: center;
          gap: 10px;
          z-index: 1000;
          font-size: 12px;
          font-weight: 500;
          letter-spacing: 0.5px;
        }

        .build-icon { color: #ffd764; font-size: 14px; }
        .build-status {
          background: rgba(255, 215, 100, 0.1);
          color: #ffd764;
          padding: 2px 8px;
          border-radius: 4px;
          position: relative;
          padding-left: 18px;
        }
        .build-status::before {
          content: '';
          position: absolute;
          left: 6px; top: 50%;
          transform: translateY(-50%);
          width: 6px; height: 6px;
          background: #ffd764;
          border-radius: 50%;
          animation: pulseGreen 2s infinite;
        }
        .build-time { color: var(--text-muted); }

        @keyframes pulseGreen { 0% { box-shadow: 0 0 0 0 rgba(255, 215, 100, 0.7); } 70% { box-shadow: 0 0 0 6px rgba(255, 215, 100, 0); } 100% { box-shadow: 0 0 0 0 rgba(255, 215, 100, 0); } }

        .side-nav {
          position: fixed;
          left: 30px;
          top: 50%;
          transform: translateY(-50%);
          display: flex;
          flex-direction: column;
          gap: 16px;
          z-index: 100;
        }

        .nav-btn {
          width: 48px;
          height: 48px;
          background: rgba(20, 24, 31, 0.8);
          border: 1px solid var(--border);
          border-radius: 16px;
          color: rgba(255,255,255,0.25);
          font-size: 20px;
          cursor: pointer;
          transition: 0.3s cubic-bezier(0.23, 1, 0.32, 1);
        }

        .nav-btn:hover {
          background: rgba(35, 41, 51, 0.95);
          border-color: var(--border-bright);
          color: var(--accent);
          transform: translateY(-2px) scale(1.05);
          box-shadow: 0 10px 20px rgba(0,0,0,0.3);
        }

        .title-bar {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 30px;
          color: rgba(255,255,255,0.3);
          font-size: 12px;
          letter-spacing: 0.5px;
          font-weight: 500;
        }

        .left-group { display: flex; gap: 16px; align-items: center; }
        .window-controls { display: flex; gap: 8px; }
        .dot { width: 12px; height: 12px; border-radius: 50%; background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.02); }

        .version-badge {
          background: rgba(255,255,255,0.03);
          border: 1px solid rgba(255,255,255,0.05);
          padding: 4px 12px;
          border-radius: 6px;
          color: rgba(255,255,255,0.5);
        }

        .metrics-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 20px;
          margin-bottom: 30px;
        }

        @keyframes metricEntry { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
        .metric-card {
          border-radius: 24px;
          padding: 24px;
          animation: metricEntry 0.5s ease-out both;
        }
        .metric-card:hover {
          border-color: rgba(255, 255, 255, 0.08);
          box-shadow: inset 0 1px 1px rgba(255,255,255,0.03), 0 10px 30px rgba(0,0,0,0.2);
        }

        .metric-header {
          display: flex;
          justify-content: space-between;
          margin-bottom: 16px;
          color: var(--text-muted);
          font-size: 12px;
          font-weight: 600;
          letter-spacing: 1px;
        }

        .metric-value-group {
          font-size: 42px;
          font-weight: 700;
          letter-spacing: -1px;
          margin-bottom: 12px;
          color: #fff;
        }

        .metric-unit { font-size: 16px; color: var(--text-muted); font-weight: 400; margin-left: 2px; }

        .progress-track {
          height: 6px;
          background: rgba(255,255,255,0.04);
          border-radius: 3px;
          overflow: hidden;
          box-shadow: inset 0 1px 2px rgba(0,0,0,0.3);
        }

        .progress-fill {
          height: 100%;
          border-radius: 3px;
          transition: width 0.5s cubic-bezier(0.23, 1, 0.32, 1);
        }

        .gpu-meta {
          font-size: 11px;
          color: rgba(255,255,255,0.3);
          margin-top: 10px;
          background: rgba(0,0,0,0.2);
          padding: 4px 8px;
          border-radius: 4px;
          display: inline-block;
        }

        /* Premium Chat Interface */
        .chat-interface {
          border-radius: 24px;
          margin-bottom: 24px;
          height: 40vh; /* Relative height */
          min-height: 350px;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }

        .chat-log {
          flex: 1;
          padding: 24px;
          overflow-y: auto;
          display: flex;
          flex-direction: column;
          gap: 20px;
          scroll-behavior: smooth;
        }

        /* Custom scrollbar for premium grade */
        .chat-log::-webkit-scrollbar { width: 6px; }
        .chat-log::-webkit-scrollbar-track { background: transparent; }
        .chat-log::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.05); border-radius: 3px; }
        .chat-log::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.1); }

        .chat-row {
          display: flex;
          gap: 16px;
          align-items: flex-start;
          max-width: 85%;
        }
        
        .chat-row.user {
          align-self: flex-end;
          flex-direction: row-reverse;
          text-align: right;
        }

        .chat-row.user .message-header { flex-direction: row-reverse; }

        .avatar {
          width: 36px;
          height: 36px;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 16px;
          flex-shrink: 0;
          margin-top: 2px;
        }
        
        .ai .avatar { background: rgba(90, 158, 255, 0.1); border: 1px solid rgba(90, 158, 255, 0.2); color: var(--accent); }
        .user .avatar { background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.1); color: #fff; }

        .message-content {
          background: var(--card-bg);
          border: 1px solid rgba(255,255,255,0.03);
          border-radius: 14px;
          padding: 12px 16px;
        }
        
        .ai .message-content { border-top-left-radius: 2px; }
        .user .message-content { border-top-right-radius: 2px; background: rgba(30, 40, 55, 0.5); }

        .message-header {
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 6px;
          font-size: 11px;
        }
        
        .sender { color: rgba(255,255,255,0.5); font-weight: 500; }
        .time { color: rgba(255,255,255,0.2); }

        /* Thinking animation */
        .thinking-dots {
          display: flex; gap: 4px; font-size: 1.5rem; color: var(--accent); line-height: 0; padding: 10px;
        }
        .thinking-dots span { animation: thinkDot 1.4s infinite; opacity: 0; }
        .thinking-dots span:nth-child(2) { animation-delay: 0.2s; }
        .thinking-dots span:nth-child(3) { animation-delay: 0.4s; }
        @keyframes thinkDot { 0%, 100% { opacity: 0; } 50% { opacity: 1; } }

        /* Input zone premium refinement */
        .input-zone {
          border-top: 1px solid rgba(255,255,255,0.03);
          padding: 16px 20px;
          display: flex;
          align-items: center;
          gap: 12px;
          background: rgba(0,0,0,0.1);
        }

        .sovereign-input {
          flex: 1;
          background: rgba(0,0,0,0.2);
          border: 1px solid var(--border);
          color: #fff;
          border-radius: 12px;
          padding: 12px 16px;
          font-size: 14px;
          outline: none;
          transition: border-color 0.3s;
        }
        
        .sovereign-input:focus { border-color: rgba(90, 158, 255, 0.4); background: rgba(0,0,0,0.3); }

        .send-btn {
          background: rgba(90, 158, 255, 0.1);
          color: var(--accent);
          border: 1px solid rgba(90, 158, 255, 0.3);
          width: 42px;
          height: 42px;
          border-radius: 12px;
          font-size: 18px;
          cursor: pointer;
          transition: 0.2s;
        }
        .send-btn:hover { background: var(--accent); color: #000; border-color: var(--accent); }

        /* Navigation pills updated for subtler, cleaner premium look */
        .pill-nav {
          display: flex;
          gap: 10px;
          margin-bottom: 20px;
          flex-wrap: wrap;
        }

        .pill {
          background: transparent;
          border: 1px solid var(--border);
          color: rgba(255,255,255,0.4);
          padding: 8px 18px;
          border-radius: 8px;
          font-size: 13px;
          cursor: pointer;
          text-transform: capitalize;
          transition: 0.2s;
          font-weight: 500;
        }

        .pill:hover { background: rgba(255,255,255,0.03); border-color: var(--border-bright); color: #fff; }
        .pill.active { background: rgba(90, 158, 255, 0.08); border-color: rgba(90, 158, 255, 0.3); color: var(--accent); }

        .action-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
          gap: 16px;
          margin-bottom: 30px;
        }

        /* Action card redesigned for Linear-style hierarchy */
        .action-card {
          background: var(--card-bg);
          border: 1px solid var(--border);
          border-radius: 16px;
          padding: 16px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          cursor: pointer;
          transition: 0.3s cubic-bezier(0.23, 1, 0.32, 1);
          text-align: left;
        }

        .action-card:hover {
          border-color: rgba(255,255,255,0.1);
          background: rgba(28, 33, 40, 0.8);
          transform: translateY(-2px);
          box-shadow: 0 10px 20px rgba(0,0,0,0.2);
        }

        .card-top { display: flex; align-items: center; gap: 14px; }
        .card-icon-frame {
          width: 40px; height: 40px;
          background: rgba(0,0,0,0.2);
          border-radius: 10px;
          display: flex; align-items: center; justify-content: center;
          font-size: 20px;
        }
        
        .action-card:hover .card-icon-frame { background: rgba(0,0,0,0.3); }

        .card-label { font-size: 14px; font-weight: 500; color: #fff; margin-bottom: 2px; }
        .card-desc { font-size: 11px; color: var(--text-muted); }
        .card-status { font-size: 11px; color: var(--accent); background: rgba(90, 158, 255, 0.08); padding: 3px 8px; border-radius: 4px; font-weight: 500; }

        .recent-container { margin-bottom: 30px; }
        .section-title { font-size: 11px; color: var(--text-muted); margin-bottom: 14px; letter-spacing: 1.5px; font-weight: 600; }
        .recent-list { display: flex; flex-wrap: wrap; gap: 8px; }
        
        .recent-pill {
          background: transparent;
          border: 1px solid var(--border);
          border-radius: 6px;
          padding: 6px 12px;
          font-size: 12px;
          color: rgba(255,255,255,0.6);
          cursor: pointer;
          transition: 0.2s;
        }
        .recent-pill:hover {
          border-color: var(--border-bright);
          color: #fff;
          background: rgba(255,255,255,0.02);
        }

        /* Status bar footer redesigned */
        .status-footer {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-top: 40px;
          padding-top: 24px;
          border-top: 1px solid var(--border);
          color: rgba(255,255,255,0.25);
          font-size: 12px;
        }

        .doc-tray { display: flex; gap: 20px; flex-wrap: wrap; }
        .doc-item { display: flex; align-items: center; gap: 8px; transition: color 0.2s; cursor: pointer;}
        .doc-item:hover { color: rgba(255,255,255,0.6); }
        .doc-type-icon { opacity: 0.4; font-size: 14px;}
        .doc-name { font-weight: 400; }

        .temp-badge {
          background: rgba(255,90,30,0.06);
          border: 1px solid rgba(255,90,30,0.15);
          border-radius: 100px;
          padding: 6px 16px;
          color: #ffaa7a;
          font-weight: 500;
          font-size: 11px;
          letter-spacing: 0.5px;
        }
        
        .temp-badge.high {
          background: rgba(255,30,30,0.1);
          border-color: rgba(255,30,30,0.3);
          color: #ff7a7a;
          animation: pulseRed 2s infinite;
        }
        
        @keyframes pulseRed { 0%, 100% { box-shadow: 0 0 0 0 rgba(255,122,122, 0.2); } 50% { box-shadow: 0 0 0 6px rgba(255,122,122, 0); } }
      `}</style>
    </div>
  );
}