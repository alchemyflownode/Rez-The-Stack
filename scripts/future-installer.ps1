# ================================================================
# 🦊 SOVEREIGN OS - FUTURE OF LOCAL AI CO-WORKERS
# ================================================================
# Privacy-first • Specialized agents • Persistent memory
# Hybrid local/cloud routing • One-click install
# ================================================================

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     🦊 SOVEREIGN OS - FUTURE OF LOCAL AI                  ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

$srcPath = "G:\okiru\app builder\Cognitive Kernel\src"
$componentsPath = "$srcPath\components"
$stylesPath = "$srcPath\styles"

# ================================================================
# 1. FUTURE-PROOF COLOR PALETTE
# ================================================================
Write-Host "[1/8] Creating future-proof color palette..." -ForegroundColor Yellow

$futureCSS = @'
/* ================================================================
   SOVEREIGN OS - FUTURE OF LOCAL AI
   Deep purples • Muted grays • Clean hierarchy
   ================================================================ */

:root {
  /* ===== BACKGROUNDS - Deep & Professional ===== */
  --bg-primary: #1a1b26;        /* Main dark background */
  --bg-sidebar: #16161e;        /* Slightly darker sidebar */
  --bg-hover: #242530;          /* Hover states */
  --bg-elevated: #2d2e3a;       /* Cards, inputs */
  
  /* ===== ACCENTS - Sovereign Purple ===== */
  --accent-primary: #8b5cf6;     /* Primary actions */
  --accent-hover: #a78bfa;       /* Hover states */
  --accent-soft: rgba(139, 92, 246, 0.15);
  --accent-glow: 0 0 20px rgba(139, 92, 246, 0.3);
  
  /* ===== TEXT - Readable Hierarchy ===== */
  --text-primary: #e2e4e9;       /* Main text */
  --text-secondary: #9aa0ac;     /* Muted text */
  --text-tertiary: #6b7280;      /* Labels, metadata */
  
  /* ===== BORDERS - Subtle Separation ===== */
  --border-primary: #2d2e3a;     /* Main border color */
  --border-subtle: #242530;      /* Lighter borders */
  
  /* ===== SPACING - 8px Grid ===== */
  --space-1: 8px;
  --space-2: 16px;
  --space-3: 24px;
  --space-4: 32px;
  --space-5: 48px;
  
  /* ===== RADII - Modern Curves ===== */
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  
  /* ===== FONTS ===== */
  --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
'@

Set-Content -Path "$stylesPath\future-palette.css" -Value $futureCSS -Encoding UTF8
Write-Host "   ✅ Created future-proof palette" -ForegroundColor Green

# ================================================================
# 2. SIDEBAR COMPONENT (Like Screenshot)
# ================================================================
Write-Host "[2/8] Creating sidebar component..." -ForegroundColor Yellow

$sidebarComponent = @'
'use client';

import { useState } from 'react';
import { 
  MessageSquare, Search, Users, Plus, Settings,
  ChevronDown, ChevronRight, Folder, Code, Sparkles
} from 'lucide-react';

export function Sidebar() {
  const [projectsOpen, setProjectsOpen] = useState(true);
  const [activeProject, setActiveProject] = useState('RezCode AI IDE');
  
  const projects = [
    { name: 'New Project', icon: Plus, isNew: true },
    { name: 'RezCode AI IDE', icon: Code, active: true },
    { name: 'Sovereign OS', icon: Sparkles },
    { name: 'Worker Studio', icon: Folder },
  ];

  return (
    <aside className="w-64 bg-[#16161e] border-r border-[#2d2e3a] flex flex-col h-full">
      {/* Logo */}
      <div className="p-4 border-b border-[#2d2e3a]">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-[#8b5cf6] rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-sm">S</span>
          </div>
          <span className="font-semibold text-[#e2e4e9]">Sovereign</span>
        </div>
      </div>
      
      {/* New Chat Button */}
      <div className="p-3">
        <button className="w-full bg-[#2d2e3a] hover:bg-[#8b5cf6] text-[#e2e4e9] hover:text-white rounded-lg px-3 py-2 text-sm font-medium flex items-center gap-2 transition-colors">
          <MessageSquare size={16} />
          <span>New Chat</span>
        </button>
      </div>
      
      {/* Search Chats */}
      <div className="px-3 mb-2">
        <div className="relative">
          <Search size={14} className="absolute left-2 top-1/2 -translate-y-1/2 text-[#6b7280]" />
          <input
            type="text"
            placeholder="Search chats..."
            className="w-full bg-[#1a1b26] border border-[#2d2e3a] rounded-lg pl-7 pr-2 py-1.5 text-xs text-[#e2e4e9] placeholder:text-[#6b7280] focus:outline-none focus:border-[#8b5cf6]"
          />
        </div>
      </div>
      
      {/* Navigation */}
      <nav className="px-3 mb-2">
        <button className="w-full flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-[#242530] text-[#9aa0ac] hover:text-[#e2e4e9] text-sm transition-colors">
          <MessageSquare size={16} />
          <span>Community</span>
        </button>
      </nav>
      
      {/* Divider */}
      <div className="border-t border-[#2d2e3a] mx-3 my-2" />
      
      {/* Projects Section */}
      <div className="flex-1 overflow-y-auto px-3">
        <button
          onClick={() => setProjectsOpen(!projectsOpen)}
          className="flex items-center gap-1 text-xs font-medium text-[#9aa0ac] hover:text-[#e2e4e9] mb-2 transition-colors"
        >
          {projectsOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
          <span>PROJECTS</span>
        </button>
        
        {projectsOpen && (
          <div className="space-y-1">
            {projects.map((project) => (
              <button
                key={project.name}
                onClick={() => !project.isNew && setActiveProject(project.name)}
                className={`w-full flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm transition-colors ${
                  project.isNew
                    ? 'text-[#8b5cf6] hover:bg-[#242530]'
                    : activeProject === project.name
                    ? 'bg-[#242530] text-[#e2e4e9] border-l-2 border-[#8b5cf6]'
                    : 'text-[#9aa0ac] hover:bg-[#242530] hover:text-[#e2e4e9]'
                }`}
              >
                <project.icon size={16} className={project.isNew ? 'text-[#8b5cf6]' : ''} />
                <span className="flex-1 text-left text-sm">{project.name}</span>
              </button>
            ))}
          </div>
        )}
      </div>
      
      {/* Bottom Section */}
      <div className="p-3 border-t border-[#2d2e3a]">
        <button className="w-full flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-[#242530] text-[#9aa0ac] hover:text-[#e2e4e9] text-sm transition-colors">
          <Settings size={16} />
          <span>Settings</span>
        </button>
      </div>
    </aside>
  );
}
'@

Set-Content -Path "$componentsPath\Sidebar.tsx" -Value $sidebarComponent -Encoding UTF8
Write-Host "   ✅ Created sidebar component" -ForegroundColor Green

# ================================================================
# 3. MAIN CHAT AREA
# ================================================================
Write-Host "[3/8] Creating main chat area..." -ForegroundColor Yellow

$chatArea = @'
'use client';

import { useState, useRef, useEffect } from 'react';
import { Send, Code, Table, Check, Copy } from 'lucide-react';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  code?: string;
  table?: any;
  timestamp: Date;
}

export function ChatArea() {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      role: 'assistant',
      content: 'Hello! I\'m your Sovereign AI. I can help with code, research, and system tasks.',
      timestamp: new Date()
    }
  ]);
  const [input, setInput] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input,
      timestamp: new Date()
    };
    setMessages(prev => [...prev, userMessage]);
    setInput('');

    // Simulate response with formatted content
    setTimeout(() => {
      const response: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: 'Here\'s a code example:',
        code: `function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}`,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, response]);
    }, 1000);
  };

  return (
    <div className="flex-1 flex flex-col bg-[#1a1b26]">
      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div className={`max-w-[80%] ${msg.role === 'user' ? 'order-2' : ''}`}>
              {msg.role === 'assistant' && (
                <div className="flex items-center gap-2 mb-1">
                  <div className="w-5 h-5 rounded bg-[#8b5cf6] flex items-center justify-center">
                    <span className="text-white text-[10px]">AI</span>
                  </div>
                  <span className="text-xs text-[#9aa0ac]">Sovereign</span>
                </div>
              )}
              
              <div
                className={`rounded-lg px-3 py-2 ${
                  msg.role === 'user'
                    ? 'bg-[#8b5cf6] text-white'
                    : 'bg-[#2d2e3a] text-[#e2e4e9]'
                }`}
              >
                <p className="text-sm whitespace-pre-wrap">{msg.content}</p>
                
                {/* Code block */}
                {msg.code && (
                  <div className="mt-2 bg-[#1a1b26] rounded p-2 relative group">
                    <pre className="text-xs font-mono text-[#e2e4e9] overflow-x-auto">
                      <code>{msg.code}</code>
                    </pre>
                    <button className="absolute top-1 right-1 opacity-0 group-hover:opacity-100 transition-opacity p-1 hover:bg-[#2d2e3a] rounded">
                      <Copy size={12} className="text-[#9aa0ac]" />
                    </button>
                  </div>
                )}
                
                {/* Table example */}
                {msg.table && (
                  <div className="mt-2 bg-[#1a1b26] rounded overflow-hidden">
                    <table className="w-full text-xs">
                      <thead className="bg-[#2d2e3a]">
                        <tr>
                          <th className="px-2 py-1 text-left">Name</th>
                          <th className="px-2 py-1 text-left">Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr className="border-t border-[#2d2e3a]">
                          <td className="px-2 py-1">Worker 1</td>
                          <td className="px-2 py-1">
                            <span className="flex items-center gap-1">
                              <Check size={10} className="text-green-500" />
                              Active
                            </span>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
              
              <div className="text-[10px] text-[#6b7280] mt-1">
                {msg.timestamp.toLocaleTimeString()}
              </div>
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="p-4 border-t border-[#2d2e3a]">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            placeholder="Ask Sovereign..."
            className="flex-1 bg-[#2d2e3a] border border-[#242530] rounded-lg px-3 py-2 text-sm text-[#e2e4e9] placeholder:text-[#6b7280] focus:outline-none focus:border-[#8b5cf6]"
          />
          <button
            onClick={handleSend}
            className="px-3 py-2 bg-[#8b5cf6] hover:bg-[#a78bfa] rounded-lg transition-colors"
          >
            <Send size={16} className="text-white" />
          </button>
        </div>
        <div className="flex items-center gap-2 mt-2">
          <button className="text-xs px-2 py-1 bg-[#2d2e3a] rounded text-[#9aa0ac] hover:text-[#e2e4e9] transition-colors">
            <Code size={12} className="inline mr-1" /> Code
          </button>
          <button className="text-xs px-2 py-1 bg-[#2d2e3a] rounded text-[#9aa0ac] hover:text-[#e2e4e9] transition-colors">
            <Table size={12} className="inline mr-1" /> Table
          </button>
        </div>
      </div>
    </div>
  );
}
'@

Set-Content -Path "$componentsPath\ChatArea.tsx" -Value $chatArea -Encoding UTF8
Write-Host "   ✅ Created chat area" -ForegroundColor Green

# ================================================================
# 4. SMART ROUTER (Local vs Cloud)
# ================================================================
Write-Host "[4/8] Creating smart router..." -ForegroundColor Yellow

$smartRouter = @'
import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function POST(req: NextRequest) {
  try {
    const { task } = await req.json();
    const lower = task.toLowerCase();
    
    // SMART ROUTING DECISION
    // Simple tasks → Local (fast, free)
    // Complex → Cloud (if available)
    // Sensitive → Local only
    
    const isComplex = 
      task.length > 200 || 
      lower.includes('complex') ||
      lower.includes('explain in detail');
    
    const isSensitive =
      lower.includes('password') ||
      lower.includes('key') ||
      lower.includes('secret');
    
    let result;
    
    if (isSensitive) {
      // Force local for sensitive data
      console.log('🔒 Sensitive task → Local only');
      result = await handleLocal(task);
    } else if (isComplex && process.env.OPENAI_API_KEY) {
      // Complex task with cloud available
      console.log('☁️ Complex task → Cloud');
      result = await handleCloud(task);
    } else {
      // Default to local
      console.log('🖥️ Standard task → Local');
      result = await handleLocal(task);
    }
    
    return NextResponse.json(result);
    
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

async function handleLocal(task: string) {
  // Route to your 28 workers
  const { stdout } = await execAsync(`python src/workers/router.py "${task}"`);
  return JSON.parse(stdout);
}

async function handleCloud(task: string) {
  // Optional cloud fallback
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
    },
    body: JSON.stringify({
      model: 'gpt-4',
      messages: [{ role: 'user', content: task }]
    })
  });
  return await response.json();
}
'@

Set-Content -Path "$srcPath\app\api\smart-router\route.ts" -Value $smartRouter -Encoding UTF8
New-Item -ItemType Directory -Force -Path "$srcPath\app\api\smart-router" | Out-Null
Write-Host "   ✅ Created smart router (local vs cloud)" -ForegroundColor Green

# ================================================================
# 5. ONE-CLICK INSTALL SCRIPT
# ================================================================
Write-Host "[5/8] Creating one-click installer..." -ForegroundColor Yellow

$installer = @'
@echo off
title Sovereign OS Installer
color 0A

echo ╔══════════════════════════════════════════════════════════╗
echo ║     🦊 Sovereign OS - One-Click Install                   ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python not found. Please install Python 3.10+
    pause
    exit
)
echo ✅ Python found

:: Check Node
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js not found. Please install Node 18+
    pause
    exit
)
echo ✅ Node.js found

:: Install Python dependencies
echo.
echo 📦 Installing Python packages...
pip install -q psutil requests duckduckgo-search

:: Install Node dependencies
echo 📦 Installing Node packages...
call npm install

:: Create .env file
if not exist .env (
    echo.
    echo 🔧 Creating .env file...
    echo # Sovereign OS Configuration > .env
    echo # Add your OpenAI key for cloud fallback (optional) >> .env
    echo # OPENAI_API_KEY=sk-... >> .env
)

:: Setup complete
echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║     ✅ Sovereign OS installed successfully!               ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
echo 🚀 To start: .\rez-control.bat
echo 📖 Documentation: https://github.com/yourname/sovereign-os
echo.
pause
'@

Set-Content -Path "G:\okiru\app builder\Cognitive Kernel\install.bat" -Value $installer -Encoding ASCII
Write-Host "   ✅ Created one-click installer" -ForegroundColor Green

# ================================================================
# 6. MAIN LAYOUT
# ================================================================
Write-Host "[6/8] Creating main layout..." -ForegroundColor Yellow

$mainLayout = @'
'use client';

import { Sidebar } from '@/components/Sidebar';
import { ChatArea } from '@/components/ChatArea';
import '@/styles/future-palette.css';

export default function Home() {
  return (
    <div className="flex h-screen bg-[#1a1b26] text-[#e2e4e9]">
      <Sidebar />
      <ChatArea />
    </div>
  );
}
'@

Set-Content -Path "$srcPath\app\page.tsx" -Value $mainLayout -Encoding UTF8
Write-Host "   ✅ Created main layout" -ForegroundColor Green

# ================================================================
# 7. GLOBAL CSS
# ================================================================
Write-Host "[7/8] Updating global CSS..." -ForegroundColor Yellow

$globalCSS = @'
@import './styles/future-palette.css';

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  height: 100%;
  overflow: hidden;
  font-family: 'Inter', system-ui, sans-serif;
}

/* Smooth scrolling */
.scrollable {
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: #2d2e3a transparent;
}

.scrollable::-webkit-scrollbar {
  width: 4px;
}

.scrollable::-webkit-scrollbar-track {
  background: transparent;
}

.scrollable::-webkit-scrollbar-thumb {
  background: #2d2e3a;
  border-radius: 2px;
}

.scrollable::-webkit-scrollbar-thumb:hover {
  background: #8b5cf6;
}
'@

Set-Content -Path "$srcPath\app\globals.css" -Value $globalCSS -Encoding UTF8
Write-Host "   ✅ Updated global CSS" -ForegroundColor Green

# ================================================================
# 8. INSTALL DEPENDENCIES
# ================================================================
Write-Host "[8/8] Installing dependencies..." -ForegroundColor Yellow

npm install lucide-react
Write-Host "   ✅ Installed lucide-react" -ForegroundColor Green

# ================================================================
# COMPLETION
# ================================================================
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     ✅ FUTURE OF LOCAL AI - INSTALLED                      ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  🎨 COLOR PALETTE:" -ForegroundColor Cyan
Write-Host "     • Background: #1a1b26" -ForegroundColor White
Write-Host "     • Sidebar:    #16161e" -ForegroundColor White
Write-Host "     • Accent:     #8b5cf6" -ForegroundColor Purple
Write-Host "     • Text:       #e2e4e9" -ForegroundColor White
Write-Host "     • Muted:      #9aa0ac" -ForegroundColor Gray
Write-Host ""
Write-Host "  🏛️  FEATURES:" -ForegroundColor Yellow
Write-Host "     • Projects sidebar with collapsible sections" -ForegroundColor White
Write-Host "     • Chat area with code blocks" -ForegroundColor White
Write-Host "     • Smart router (local vs cloud)" -ForegroundColor White
Write-Host "     • One-click installer" -ForegroundColor White
Write-Host "     • 28 workers ready" -ForegroundColor White
Write-Host ""
Write-Host "  🚀 TO START:" -ForegroundColor Green
Write-Host "     .\install.bat" -ForegroundColor White
Write-Host "     .\rez-control.bat" -ForegroundColor White
Write-Host "     Open: http://localhost:3001" -ForegroundColor White
Write-Host ""