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
  id: string;
  role: 'user' | 'ai' | 'system';
  content: string;
  timestamp: string;
  worker?: string;
  model?: string;
  metadata?: any;
}

interface SessionUsage {
  current: number;
  weekly: number;
  total: number;
}

interface ServiceStatus {
  kernel: boolean;
  chroma: boolean;
  nextjs: boolean;
}

interface WorkerInfo {
  id: string;
  name: string;
  icon: string;
  description: string;
  model?: string;
}

// ============================================================================
// Constants
// ============================================================================
const WELCOME_MESSAGE = `# Welcome to REZ HIVE! 👋

I'm your **sovereign AI coworker**.

### Quick Start:
- 💬 **Chat naturally** - Ask me anything
- 🧠 **Brain** - General reasoning and conversation
- 👁️ **Eyes** - Search and research
- ✋ **Hands** - Code generation
- 📁 **Memory** - File operations

Try asking: *"Write a Python function to calculate fibonacci numbers"*`;

const API_BASE = 'http://localhost:8002';
const API_URL = `${API_BASE}/kernel/stream`;
const MAX_SESSION_MESSAGES = 100;
const MAX_WEEKLY_MESSAGES = 500;

// ============================================================================
// Helper Functions
// ============================================================================
const generateId = () => Math.random().toString(36).substring(2, 15);
const getTime = () => new Date().toLocaleTimeString();

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
// Message Content Component with Full Markdown + Code Support
// ============================================================================
const MessageContent = ({ content }: { content: string }) => {
  const [copiedCode, setCopiedCode] = useState<string | null>(null);

  const handleCopy = useCallback(async (code: string) => {
    try {
      await navigator.clipboard.writeText(code);
      setCopiedCode(code);
      setTimeout(() => setCopiedCode(null), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  }, []);

  return (
    <div className="prose prose-invert max-w-none">
      <ReactMarkdown
        components={{
          // ===== CODE BLOCKS =====
          code({ node, inline, className, children, ...props }) {
            const match = /language-(\w+)/.exec(className || '');
            const language = match ? match[1] : 'text';
            const codeString = String(children).replace(/\n$/, '');
            const isCopied = copiedCode === codeString;

            if (!inline) {
              return (
                <div className="my-4 relative group">
                  {/* Header */}
                  <div className="flex items-center justify-between mb-2 px-1">
                    <span className="text-xs px-2.5 py-1 rounded-lg bg-gradient-to-r from-cyan-500/20 to-purple-500/20 text-cyan-400 font-mono border border-cyan-500/30">
                      {language}
                    </span>
                    <button
                      onClick={() => handleCopy(codeString)}
                      className={`text-xs px-3 py-1.5 rounded-lg transition-all border flex items-center gap-1.5 ${
                        isCopied
                          ? 'bg-green-500/20 border-green-500/50 text-green-400'
                          : 'bg-white/5 border-white/10 text-white/60 hover:bg-white/10 hover:text-white/80'
                      }`}
                    >
                      {isCopied ? '✓ Copied!' : '📋 Copy'}
                    </button>
                  </div>
                  {/* Code Block */}
                  <CodeBlock language={language} code={codeString} />
                </div>
              );
            }

            // Inline code
            return (
              <code
                className="bg-black/40 px-1.5 py-0.5 rounded text-cyan-300 font-mono text-sm border border-white/10"
                {...props}
              >
                {children}
              </code>
            );
          },

          // ===== HEADERS =====
          h1: ({ children }) => (
            <h1 className="text-2xl font-bold text-cyan-400 mt-6 mb-3 border-b border-cyan-500/30 pb-2">
              {children}
            </h1>
          ),
          h2: ({ children }) => (
            <h2 className="text-xl font-bold text-cyan-400 mt-5 mb-2">
              {children}
            </h2>
          ),
          h3: ({ children }) => (
            <h3 className="text-lg font-bold text-cyan-300 mt-4 mb-2">
              {children}
            </h3>
          ),
          h4: ({ children }) => (
            <h4 className="text-base font-bold text-cyan-200 mt-3 mb-1">
              {children}
            </h4>
          ),

          // ===== LISTS =====
          ul: ({ children }) => (
            <ul className="list-disc list-inside space-y-1.5 my-3 text-gray-300 pl-2">
              {children}
            </ul>
          ),
          ol: ({ children }) => (
            <ol className="list-decimal list-inside space-y-1.5 my-3 text-gray-300 pl-2">
              {children}
            </ol>
          ),
          li: ({ children }) => (
            <li className="text-gray-300 leading-relaxed">{children}</li>
          ),

          // ===== TEXT FORMATTING =====
          strong: ({ children }) => (
            <strong className="text-cyan-400 font-bold">{children}</strong>
          ),
          em: ({ children }) => (
            <em className="text-purple-300 italic">{children}</em>
          ),

          // ===== LINKS =====
          a: ({ href, children }) => (
            <a
              href={href}
              className="text-cyan-400 hover:text-cyan-300 underline decoration-cyan-500/30 hover:decoration-cyan-500 transition-colors"
              target="_blank"
              rel="noopener noreferrer"
            >
              {children}
            </a>
          ),

          // ===== BLOCKQUOTES =====
          blockquote: ({ children }) => (
            <blockquote className="border-l-4 border-cyan-500/30 pl-4 italic text-gray-400 my-3 bg-cyan-500/5 py-2 rounded-r">
              {children}
            </blockquote>
          ),

          // ===== PARAGRAPHS =====
          p: ({ children }) => (
            <p className="text-gray-300 leading-relaxed my-2">{children}</p>
          ),

          // ===== HORIZONTAL RULE =====
          hr: () => <hr className="border-t border-white/10 my-6" />,

          // ===== TABLES =====
          table: ({ children }) => (
            <div className="overflow-x-auto my-4">
              <table className="min-w-full border border-white/10 rounded-lg overflow-hidden">
                {children}
              </table>
            </div>
          ),
          thead: ({ children }) => (
            <thead className="bg-white/5">{children}</thead>
          ),
          tbody: ({ children }) => (
            <tbody className="divide-y divide-white/10">{children}</tbody>
          ),
          tr: ({ children }) => <tr className="hover:bg-white/5">{children}</tr>,
          th: ({ children }) => (
            <th className="px-4 py-2 text-left text-cyan-400 font-semibold">
              {children}
            </th>
          ),
          td: ({ children }) => (
            <td className="px-4 py-2 text-gray-300">{children}</td>
          ),

          // ===== IMAGES =====
          img: ({ src, alt }) => (
            <img
              src={src}
              alt={alt}
              className="rounded-lg border border-white/10 my-4 max-w-full"
            />
          ),
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
};

// ============================================================================
// Main Dashboard Component
// ============================================================================
export default function SovereignDashboard() {
  // ===== STATE =====
  const [chatLog, setChatLog] = useState<Message[]>([
    {
      id: generateId(),
      role: 'ai',
      content: WELCOME_MESSAGE,
      timestamp: getTime(),
      worker: 'brain',
    },
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [selectedWorker, setSelectedWorker] = useState('brain');
  const [selectedModel, setSelectedModel] = useState('llama3.2');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [services, setServices] = useState<ServiceStatus>({
    kernel: false,
    chroma: false,
    nextjs: true,
  });
  const [sessionUsage, setSessionUsage] = useState<SessionUsage>({
    current: 0,
    weekly: 0,
    total: 0,
  });
  const [timeUntilReset, setTimeUntilReset] = useState('');
  const [availableModels, setAvailableModels] = useState<string[]>([
    'llama3.2',
    'llama3.1',
    'qwen2.5-coder:14b',
    'mistral',
    'codellama:34b',
  ]);

  const chatEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Workers Configuration
  const workers: WorkerInfo[] = [
    { id: 'brain', name: 'Brain', icon: '🧠', description: 'General reasoning', model: 'llama3.2' },
    { id: 'search', name: 'Eyes', icon: '👁️', description: 'Web search' },
    { id: 'code', name: 'Hands', icon: '✋', description: 'Code generation', model: 'qwen2.5-coder:14b' },
    { id: 'files', name: 'Memory', icon: '📁', description: 'File operations' },
  ];

  // ===== EFFECTS =====

  // Initialize session
  useEffect(() => {
    const initSession = async () => {
      try {
        // Check for existing session
        const existingSession = localStorage.getItem('rez_session_id');
        if (existingSession) {
          setSessionId(existingSession);
          
          // Load chat history
          try {
            const response = await fetch(`${API_BASE}/chat/${existingSession}/history`);
            if (response.ok) {
              const data = await response.json();
              if (data.messages && data.messages.length > 0) {
                setChatLog(data.messages.map((msg: any) => ({
                  id: generateId(),
                  role: msg.role,
                  content: msg.content,
                  timestamp: msg.timestamp || getTime(),
                  worker: msg.worker,
                })));
              }
            }
          } catch (e) {
            console.log('Could not load chat history:', e);
          }
          
          return;
        }

        // Create new session
        const response = await fetch(`${API_BASE}/auth/session`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
        });
        
        if (response.ok) {
          const data = await response.json();
          setSessionId(data.session_id);
          localStorage.setItem('rez_session_id', data.session_id);
          if (data.token) {
            localStorage.setItem('rez_token', data.token);
          }
          console.log('[OK] Session created:', data.session_id);
        }
      } catch (error) {
        console.error('Failed to create session:', error);
        // Generate local session ID as fallback
        const fallbackId = `local-${generateId()}`;
        setSessionId(fallbackId);
        localStorage.setItem('rez_session_id', fallbackId);
      }
    };

    initSession();
  }, []);

  // Auto-scroll to bottom
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatLog]);

  // Update session usage
  useEffect(() => {
    const userMessages = chatLog.filter(m => m.role === 'user').length;
    setSessionUsage({
      current: Math.min((userMessages / MAX_SESSION_MESSAGES) * 100, 100),
      weekly: Math.min((userMessages / MAX_WEEKLY_MESSAGES) * 100, 100),
      total: userMessages,
    });
  }, [chatLog]);

  // Update time until reset
  useEffect(() => {
    setTimeUntilReset(getTimeUntilReset());
    const interval = setInterval(() => {
      setTimeUntilReset(getTimeUntilReset());
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // Check service status
  useEffect(() => {
    const checkServices = async () => {
      // Check kernel
      try {
        const kernel = await fetch(`${API_BASE}/health`, {
          method: 'GET',
          signal: AbortSignal.timeout(5000),
        });
        const kernelData = kernel.ok ? await kernel.json() : null;
        setServices(prev => ({
          ...prev,
          kernel: kernel.ok,
        }));
        
        // Update worker count if available
        if (kernelData?.workers) {
          console.log(`[OK] Kernel healthy: ${kernelData.workers} workers`);
        }
      } catch {
        setServices(prev => ({ ...prev, kernel: false }));
      }

      // Check Chroma
      try {
        const chroma = await fetch('http://localhost:8000/api/v1/heartbeat', {
          method: 'GET',
          signal: AbortSignal.timeout(3000),
        });
        setServices(prev => ({ ...prev, chroma: chroma.ok }));
      } catch {
        setServices(prev => ({ ...prev, chroma: false }));
      }
    };

    checkServices();
    const interval = setInterval(checkServices, 10000);
    return () => clearInterval(interval);
  }, []);

  // Fetch available workers from backend
  useEffect(() => {
    const fetchWorkers = async () => {
      try {
        const response = await fetch(`${API_BASE}/workers`);
        if (response.ok) {
          const data = await response.json();
          console.log('[OK] Workers loaded:', data.workers?.length || 0);
        }
      } catch (e) {
        console.log('Using default workers');
      }
    };
    
    fetchWorkers();
  }, []);

  // ===== HANDLERS =====

  // Send message with SSE streaming
  const sendMessage = useCallback(async () => {
    if (!input.trim() || isLoading) return;

    const userMessage: Message = {
      id: generateId(),
      role: 'user',
      content: input,
      timestamp: getTime(),
      worker: selectedWorker,
    };

    setChatLog(prev => [...prev, userMessage]);
    const currentInput = input;
    setInput('');
    setIsLoading(true);

    // Add temporary AI message for streaming
    const aiMessageId = generateId();
    setChatLog(prev => [
      ...prev,
      {
        id: aiMessageId,
        role: 'ai',
        content: '',
        timestamp: getTime(),
        worker: selectedWorker,
        model: selectedModel,
      },
    ]);

    try {
      const response = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId || 'anonymous',
        },
        body: JSON.stringify({
          task: currentInput,
          worker: selectedWorker,
          model: selectedModel,
          session_id: sessionId || 'anonymous',
        }),
      });

      if (!response.ok) {
        // Handle HTTP errors
        let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
        
        // Try to parse error response
        try {
          const errorData = await response.json();
          if (errorData.error) {
            errorMessage = errorData.error;
          }
          if (errorData.reason) {
            errorMessage += `\n\n*${errorData.reason}*`;
          }
          if (errorData.articles_failed) {
            errorMessage += `\n\n**Constitutional Articles Failed:** ${errorData.articles_failed.join(', ')}`;
          }
        } catch {
          // Use default error message
        }

        setChatLog(prev =>
          prev.map(msg =>
            msg.id === aiMessageId
              ? { ...msg, content: `⚠️ **Error**: ${errorMessage}`, role: 'system' }
              : msg
          )
        );
        setIsLoading(false);
        return;
      }

      const reader = response.body?.getReader();
      if (!reader) {
        throw new Error('No response body');
      }

      const decoder = new TextDecoder();
      let accumulated = '';
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n\n');
        buffer = lines.pop() || ''; // Keep incomplete chunk in buffer

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));

              // Handle errors from stream
              if (data.error) {
                setChatLog(prev =>
                  prev.map(msg =>
                    msg.id === aiMessageId
                      ? {
                          ...msg,
                          content: `⚠️ **Error**: ${data.error}`,
                          role: 'system',
                        }
                      : msg
                  )
                );
                setIsLoading(false);
                return;
              }

              // Handle content
              if (data.content) {
                accumulated += data.content;
                setChatLog(prev =>
                  prev.map(msg =>
                    msg.id === aiMessageId
                      ? { ...msg, content: accumulated }
                      : msg
                  )
                );
              }

              // Handle metadata
              if (data.metadata) {
                setChatLog(prev =>
                  prev.map(msg =>
                    msg.id === aiMessageId
                      ? { ...msg, metadata: data.metadata }
                      : msg
                  )
                );
              }

              // Handle status updates
              if (data.status === 'started') {
                console.log(`[STREAM] Worker ${data.worker} started`);
              }

              if (data.status === 'complete') {
                console.log('[STREAM] Complete');
              }

              if (data.status === 'failed') {
                console.error('[STREAM] Failed');
              }
            } catch (e) {
              console.error('Error parsing SSE:', e, 'Line:', line);
            }
          }
        }
      }
    } catch (error) {
      console.error('Error:', error);
      setChatLog(prev =>
        prev.map(msg =>
          msg.id === aiMessageId
            ? {
                ...msg,
                content: `⚠️ **Connection Error**: ${
                  error instanceof Error ? error.message : 'Failed to connect to kernel'
                }\n\nMake sure the kernel is running on port 8001.`,
                role: 'system',
              }
            : msg
        )
      );
    } finally {
      setIsLoading(false);
      inputRef.current?.focus();
    }
  }, [input, isLoading, selectedWorker, selectedModel, sessionId]);

  // Clear chat
  const clearChat = useCallback(async () => {
    // Clear on backend if we have a session
    if (sessionId) {
      try {
        await fetch(`${API_BASE}/chat/${sessionId}/clear`, {
          method: 'POST',
        });
      } catch (e) {
        console.log('Could not clear server chat:', e);
      }
    }

    // Reset local state
    setChatLog([
      {
        id: generateId(),
        role: 'ai',
        content: WELCOME_MESSAGE,
        timestamp: getTime(),
        worker: 'brain',
      },
    ]);
  }, [sessionId]);

  // Quick command
  const quickCommand = useCallback((command: string) => {
    setInput(command);
    inputRef.current?.focus();
  }, []);

  // New session
  const newSession = useCallback(async () => {
    localStorage.removeItem('rez_session_id');
    localStorage.removeItem('rez_token');
    
    try {
      const response = await fetch(`${API_BASE}/auth/session`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });
      
      if (response.ok) {
        const data = await response.json();
        setSessionId(data.session_id);
        localStorage.setItem('rez_session_id', data.session_id);
        if (data.token) {
          localStorage.setItem('rez_token', data.token);
        }
      }
    } catch (e) {
      const fallbackId = `local-${generateId()}`;
      setSessionId(fallbackId);
      localStorage.setItem('rez_session_id', fallbackId);
    }

    setChatLog([
      {
        id: generateId(),
        role: 'ai',
        content: WELCOME_MESSAGE,
        timestamp: getTime(),
        worker: 'brain',
      },
    ]);
  }, []);

  // ============================================================================
  // RENDER
  // ============================================================================
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#030405] via-[#0a0e14] to-[#030405] text-white font-sans selection:bg-cyan-500/30">
      {/* ===== TOP BAR ===== */}
      <header className="fixed top-0 left-0 right-0 h-14 bg-gradient-to-b from-black/80 to-black/40 backdrop-blur-xl border-b border-white/10 flex items-center px-4 md:px-6 z-30 shadow-lg">
        {/* Hamburger Menu */}
        <button
          onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
          className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          aria-label="Toggle sidebar"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d={sidebarCollapsed ? "M4 6h16M4 12h16M4 18h16" : "M6 18L18 6M6 6l12 12"}
            />
          </svg>
        </button>

        {/* Logo & Status */}
        <div className="flex items-center gap-4 md:gap-6 ml-3">
          <h1 className="text-lg md:text-xl font-bold bg-gradient-to-r from-cyan-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
            REZ HIVE
          </h1>

          {/* Status Indicators */}
          <div className="hidden md:flex items-center gap-3 text-xs">
            <div className="flex items-center gap-1.5">
              <div
                className={`w-2 h-2 rounded-full transition-colors ${
                  services.kernel
                    ? 'bg-green-400 animate-pulse shadow-lg shadow-green-500/50'
                    : 'bg-red-400'
                }`}
              />
              <span className="text-white/60">Kernel</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div
                className={`w-2 h-2 rounded-full ${
                  services.chroma ? 'bg-green-400' : 'bg-white/20'
                }`}
              />
              <span className="text-white/60">Memory</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-white/40">Worker:</span>
              <span className="text-cyan-400 font-medium">
                {workers.find(w => w.id === selectedWorker)?.icon}{' '}
                {workers.find(w => w.id === selectedWorker)?.name}
              </span>
            </div>
          </div>
        </div>

        {/* Right Controls */}
        <div className="ml-auto flex items-center gap-2 md:gap-3">
          {/* Session indicator */}
          <div className="hidden lg:flex items-center gap-2 text-xs text-white/40">
            <span className="w-2 h-2 rounded-full bg-cyan-400/50" />
            <span className="font-mono truncate max-w-[100px]">
              {sessionId?.slice(0, 8)}...
            </span>
          </div>

          {/* Model selector */}
          <select
            value={selectedModel}
            onChange={e => setSelectedModel(e.target.value)}
            className="bg-black/40 border border-white/10 rounded-lg px-2 md:px-3 py-1.5 text-xs md:text-sm focus:outline-none focus:border-cyan-500/50 hover:bg-black/60 transition-colors cursor-pointer"
          >
            {availableModels.map(model => (
              <option key={model} value={model}>
                {model}
              </option>
            ))}
          </select>
        </div>
      </header>

      {/* ===== SIDEBAR ===== */}
      <aside
        className={`fixed left-0 top-14 bottom-0 w-64 bg-gradient-to-b from-black/60 to-black/40 backdrop-blur-xl border-r border-white/10 transition-transform duration-300 z-20 overflow-hidden ${
          sidebarCollapsed ? '-translate-x-full' : ''
        }`}
      >
        <div className="p-4 space-y-6 h-full overflow-y-auto custom-scrollbar">
          {/* Worker Selection */}
          <div>
            <h3 className="text-xs font-semibold text-white/40 uppercase tracking-wider mb-3">
              Workers
            </h3>
            <div className="space-y-2">
              {workers.map(worker => (
                <button
                  key={worker.id}
                  onClick={() => {
                    setSelectedWorker(worker.id);
                    // Auto-select appropriate model for worker
                    if (worker.model) {
                      setSelectedModel(worker.model);
                    }
                  }}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all ${
                    selectedWorker === worker.id
                      ? 'bg-gradient-to-r from-cyan-500/20 to-purple-500/20 border border-cyan-500/30 shadow-lg shadow-cyan-500/10'
                      : 'hover:bg-white/5 border border-transparent'
                  }`}
                >
                  <span className="text-xl">{worker.icon}</span>
                  <div className="flex-1 text-left">
                    <div className="font-medium text-sm">{worker.name}</div>
                    <div className="text-xs text-white/40">
                      {worker.description}
                    </div>
                  </div>
                  {selectedWorker === worker.id && (
                    <div className="w-2 h-2 rounded-full bg-cyan-400 animate-pulse" />
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Quick Commands */}
          <div>
            <h3 className="text-xs font-semibold text-white/40 uppercase tracking-wider mb-3">
              Quick Commands
            </h3>
            <div className="space-y-1">
              <button
                onClick={clearChat}
                className="w-full text-left px-3 py-2 text-sm hover:bg-white/5 rounded-lg transition-colors flex items-center gap-2 text-white/70 hover:text-white"
              >
                🗑️ Clear chat
              </button>
              <button
                onClick={newSession}
                className="w-full text-left px-3 py-2 text-sm hover:bg-white/5 rounded-lg transition-colors flex items-center gap-2 text-white/70 hover:text-white"
              >
                🆕 New session
              </button>
              <hr className="border-white/10 my-2" />
              <button
                onClick={() => quickCommand('Check system CPU and memory usage')}
                className="w-full text-left px-3 py-2 text-sm hover:bg-white/5 rounded-lg transition-colors flex items-center gap-2 text-white/70 hover:text-white"
              >
                💻 Check system
              </button>
              <button
                onClick={() => quickCommand('List files in current directory')}
                className="w-full text-left px-3 py-2 text-sm hover:bg-white/5 rounded-lg transition-colors flex items-center gap-2 text-white/70 hover:text-white"
              >
                📁 List files
              </button>
              <button
                onClick={() => quickCommand('Search for the latest AI news')}
                className="w-full text-left px-3 py-2 text-sm hover:bg-white/5 rounded-lg transition-colors flex items-center gap-2 text-white/70 hover:text-white"
              >
                🔍 Search web
              </button>
              <button
                onClick={() => quickCommand('Write a Python function to calculate fibonacci numbers with memoization')}
                className="w-full text-left px-3 py-2 text-sm hover:bg-white/5 rounded-lg transition-colors flex items-center gap-2 text-white/70 hover:text-white"
              >
                ⚡ Code example
              </button>
            </div>
          </div>

          {/* Session Stats */}
          <div className="pt-4 border-t border-white/10">
            <h3 className="text-xs font-semibold text-white/40 uppercase tracking-wider mb-3">
              Session Stats
            </h3>
            <div className="space-y-3">
              {/* Progress bar */}
              <div>
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-white/60">Usage</span>
                  <span className={sessionUsage.current > 80 ? 'text-red-400' : 'text-cyan-400'}>
                    {sessionUsage.current.toFixed(0)}%
                  </span>
                </div>
                <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${
                      sessionUsage.current > 80
                        ? 'bg-gradient-to-r from-red-500 to-orange-500'
                        : 'bg-gradient-to-r from-cyan-500 to-purple-500'
                    }`}
                    style={{ width: `${sessionUsage.current}%` }}
                  />
                </div>
              </div>

              <div className="space-y-2 text-xs">
                <div className="flex justify-between items-center">
                  <span className="text-white/60">Messages</span>
                  <span className="text-cyan-400 font-mono">
                    {sessionUsage.total} / {MAX_SESSION_MESSAGES}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-white/60">Model</span>
                  <span className="text-purple-400 font-mono text-xs truncate max-w-[100px]">
                    {selectedModel}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-white/60">Reset in</span>
                  <span className="text-green-400 font-mono">
                    {timeUntilReset}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </aside>

      {/* ===== MAIN CHAT AREA ===== */}
      <main
        className={`pt-14 pb-36 transition-all duration-300 ${
          sidebarCollapsed ? 'ml-0' : 'ml-0 md:ml-64'
        }`}
      >
        <div className="max-w-4xl mx-auto px-4 py-6 md:py-8">
          {/* Chat Messages */}
          <div className="space-y-4">
            <AnimatePresence mode="popLayout">
              {chatLog.map((message, index) => (
                <motion.div
                  key={message.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ delay: Math.min(index * 0.02, 0.2) }}
                  className={`p-4 rounded-xl transition-colors ${
                    message.role === 'user'
                      ? 'bg-gradient-to-r from-cyan-500/10 to-purple-500/10 border border-cyan-500/20 ml-4 md:ml-12'
                      : message.role === 'system'
                      ? 'bg-gradient-to-r from-yellow-500/10 to-orange-500/10 border border-yellow-500/20'
                      : 'bg-white/5 border border-white/10 mr-4 md:mr-12'
                  }`}
                >
                  {/* Message Header */}
                  <div className="flex items-center gap-2 mb-3 text-xs text-white/40">
                    <span className="text-base">
                      {message.role === 'user'
                        ? '👤'
                        : message.role === 'system'
                        ? '⚠️'
                        : workers.find(w => w.id === message.worker)?.icon || '🤖'}
                    </span>
                    <span className="font-medium">
                      {message.role === 'user'
                        ? 'You'
                        : message.role === 'system'
                        ? 'System'
                        : workers.find(w => w.id === message.worker)?.name || 'AI'}
                    </span>
                    <span className="text-white/20">•</span>
                    <span>{message.timestamp}</span>
                    {message.model && (
                      <>
                        <span className="text-white/20">•</span>
                        <span className="text-purple-400/60">{message.model}</span>
                      </>
                    )}
                  </div>

                  {/* Message Content */}
                  {message.content ? (
                    <MessageContent content={message.content} />
                  ) : (
                    <div className="flex items-center gap-2 text-white/40">
                      <LoadingIndicator />
                      <span className="text-sm">Thinking...</span>
                    </div>
                  )}

                  {/* Metadata */}
                  {message.metadata && (
                    <details className="mt-3 text-xs">
                      <summary className="cursor-pointer text-white/40 hover:text-white/60 transition-colors">
                        📊 Metadata
                      </summary>
                      <pre className="mt-2 p-3 bg-black/40 rounded-lg border border-white/10 overflow-x-auto text-white/60 font-mono text-xs">
                        {JSON.stringify(message.metadata, null, 2)}
                      </pre>
                    </details>
                  )}
                </motion.div>
              ))}
            </AnimatePresence>

            {/* Loading Indicator */}
            {isLoading && chatLog[chatLog.length - 1]?.content && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="flex items-center gap-3 text-sm text-white/40 mr-12 px-4"
              >
                <LoadingIndicator />
                <span>
                  {workers.find(w => w.id === selectedWorker)?.icon}{' '}
                  {workers.find(w => w.id === selectedWorker)?.name} is processing...
                </span>
              </motion.div>
            )}

            {/* Auto-scroll anchor */}
            <div ref={chatEndRef} />
          </div>
        </div>
      </main>

      {/* ===== INPUT AREA ===== */}
      <div className="fixed bottom-0 left-0 right-0 bg-gradient-to-t from-black via-black/95 to-transparent pt-8 pb-4 px-4 z-20">
        <div
          className={`max-w-4xl mx-auto transition-all duration-300 ${
            sidebarCollapsed ? 'ml-0' : 'ml-0 md:ml-64'
          }`}
        >
          {/* Input Row */}
          <div className="flex gap-2">
            {/* Worker Quick Select (Mobile) */}
            <div className="md:hidden">
              <select
                value={selectedWorker}
                onChange={e => setSelectedWorker(e.target.value)}
                className="h-full bg-white/5 border border-white/10 rounded-xl px-3 text-lg focus:outline-none focus:border-cyan-500/50"
              >
                {workers.map(w => (
                  <option key={w.id} value={w.id}>
                    {w.icon}
                  </option>
                ))}
              </select>
            </div>

            {/* Input Field */}
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  sendMessage();
                }
              }}
              placeholder={`Message ${workers.find(w => w.id === selectedWorker)?.name}...`}
              className="flex-1 bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-cyan-500/50 focus:bg-white/10 transition-all placeholder:text-white/30"
              disabled={isLoading}
            />

            {/* Send Button */}
            <button
              onClick={sendMessage}
              disabled={isLoading || !input.trim()}
              className="px-5 md:px-6 py-3 bg-gradient-to-r from-cyan-500 to-purple-500 rounded-xl text-sm font-medium hover:opacity-90 transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-cyan-500/20 flex items-center gap-2"
            >
              {isLoading ? (
                <LoadingIndicator />
              ) : (
                <>
                  <span className="hidden md:inline">Send</span>
                  <span>→</span>
                </>
              )}
            </button>
          </div>

          {/* Session Info Bar */}
          <div className="flex justify-between items-center mt-3 text-xs text-white/30">
            <div className="flex items-center gap-3">
              <span className="hidden md:inline">Session</span>
              <span
                className={`font-mono ${
                  sessionUsage.current > 80 ? 'text-red-400' : 'text-cyan-400'
                }`}
              >
                {sessionUsage.current.toFixed(0)}%
              </span>
              <span className="text-white/20 hidden sm:inline">•</span>
              <span className="hidden sm:inline">
                {services.kernel ? (
                  <span className="text-green-400">● Online</span>
                ) : (
                  <span className="text-red-400">● Offline</span>
                )}
              </span>
            </div>
            <div className="hidden md:block">Resets in {timeUntilReset}</div>
            <div className="font-mono">
              {sessionUsage.total} / {MAX_SESSION_MESSAGES}
            </div>
          </div>
        </div>
      </div>

      {/* ===== PS1-STYLE CONTROLLER ===== */}
      <RezHiveController />

      {/* ===== CUSTOM SCROLLBAR STYLES ===== */}
      <style jsx global>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 6px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: transparent;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 3px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: rgba(255, 255, 255, 0.2);
        }
      `}</style>
    </div>
  );
}