// src/components/RezHiveController.tsx
"use client";

import { useState, useRef, useEffect } from "react";
import { 
  X, Play, RotateCw, Activity, Zap, Shield, Terminal, 
  RefreshCw, Trash2, BookOpen, Cpu, HardDrive, Network, 
  AlertTriangle, GitMerge, CheckCircle, Globe, Code,
  Eye, Brain, Database, Command, Settings, Bell
} from "lucide-react";

interface OutputLine {
  id: string;
  text: string;
  timestamp: string;
  type: "command" | "success" | "error" | "info" | "heal" | "warning" | "constitution" | "search" | "code";
}

interface ServiceStatus {
  kernel: boolean;
  chroma: boolean;
  nextjs: boolean;
  ollama: boolean;
  ledger: boolean;
  duckduckgo: boolean;
}

interface WorkerStatus {
  orchestrator: boolean;
  brain: boolean;
  search: boolean;  // CHANGE: 'eyes' → 'search'
  code: boolean;     // CHANGE: 'hands' → 'code'
  files: boolean;    // CHANGE: 'memory' → 'files'
  system: boolean;
}

interface SystemMetrics {
  cpu: number;
  memory: number;
  gpu: number;
  uptime: number;
  tokens: number;
  maxTokens: number;
}

const API_BASE = "http://localhost:8001";

export function RezHiveController() {
  const [isOpen, setIsOpen] = useState(false);
  const[output, setOutput] = useState<OutputLine[]>([]);
  const [loading, setLoading] = useState<Record<number, boolean>>({});
  const [services, setServices] = useState<ServiceStatus>({
    kernel: false,
    chroma: false,
    nextjs: true,
    ollama: false,
    ledger: false,
    duckduckgo: false
  });
  const [workers, setWorkers] = useState<WorkerStatus>({
    orchestrator: false,
    brain: false,
    search: false,
    code: false,
    files: false,
    system: false
  });
  const [metrics, setMetrics] = useState<SystemMetrics>({
    cpu: 0,
    memory: 0,
    gpu: 0,
    uptime: 0,
    tokens: 0,
    maxTokens: 8192
  });
  const[healingActive, setHealingActive] = useState(false);
  const [autoHeal, setAutoHeal] = useState(false);
  const [healCount, setHealCount] = useState(0);
  const[showLedger, setShowLedger] = useState(false);
  const [precedents, setPrecedents] = useState<any[]>([]);
  const [searchMode, setSearchMode] = useState<"duckduckgo" | "brave" | "google">("duckduckgo");
  
  const outputRef = useRef<HTMLDivElement>(null);
  const healthInterval = useRef<NodeJS.Timeout>();
  const metricsInterval = useRef<NodeJS.Timeout>();
  const failureCount = useRef<Record<string, number>>({});
  const immunityTimer = useRef<NodeJS.Timeout>();

  const getTime = () => {
    const d = new Date();
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}:${d.getSeconds().toString().padStart(2, '0')}`;
  };

  const addOutput = (text: string, type: OutputLine["type"] = "info") => {
    setOutput((prev) =>[
      ...prev,
      {
        id: Math.random().toString(36).substring(2, 9),
        text,
        timestamp: getTime(),
        type,
      },
    ]);
  };

  useEffect(() => {
    outputRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [output]);

  useEffect(() => {
    return () => {
      if (immunityTimer.current) clearTimeout(immunityTimer.current);
      if (healthInterval.current) clearInterval(healthInterval.current);
      if (metricsInterval.current) clearInterval(metricsInterval.current);
    };
  },[]);

  const fetchWithTimeout = async (url: string, options?: RequestInit, timeoutMs = 5000) => {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetch(url, { ...options, signal: controller.signal });
      clearTimeout(timeoutId);
      return response;
    } catch (e) {
      clearTimeout(timeoutId);
      throw e;
    }
  };

  // =================================================================
  // SYSTEM METRICS
  // =================================================================
  const updateMetrics = async () => {
    try {
      // Get system metrics from kernel
      const response = await fetch(`${API_BASE}/health`);
      if (response.ok) {
        const data = await response.json();
        setMetrics(prev => ({
          ...prev,
          cpu: data.cpu || prev.cpu,
          memory: data.memory || prev.memory,
          uptime: data.uptime || prev.uptime + 1
        }));
      }
      
      // Update token count from chat
      const chatResponse = await fetch(`${API_BASE}/chat/${localStorage.getItem('rez_session_id')}/history`);
      if (chatResponse.ok) {
        const data = await chatResponse.json();
        // Rough token estimate (4 chars ≈ 1 token)
        const totalChars = data.messages.reduce((acc: number, msg: any) => acc + msg.content.length, 0);
        setMetrics(prev => ({ ...prev, tokens: Math.ceil(totalChars / 4) }));
      }
    } catch (e) {
      // Silent fail
    }
  };

  // =================================================================
  // SERVICE CHECKS
  // =================================================================
  const checkDuckDuckGo = async (): Promise<boolean> => {
    try {
      const response = await fetchWithTimeout('https://api.duckduckgo.com/?q=test&format=json', {}, 3000);
      return response.ok;
    } catch {
      return false;
    }
  };

  const checkWorkers = async (): Promise<WorkerStatus> => {
    try {
      const response = await fetch(`${API_BASE}/workers`);
      if (response.ok) {
        const data = await response.json();
        const workerStatus: WorkerStatus = {
          orchestrator: data.workers.some((w: any) => w.name === 'orchestrator' || w.name === 'router'),
          brain: data.workers.some((w: any) => w.name === 'brain'),
          search: data.workers.some((w: any) => w.name === 'search'),  // CHANGED
          code: data.workers.some((w: any) => w.name === 'code'),      // CHANGED
          files: data.workers.some((w: any) => w.name === 'files'),    // CHANGED
          system: data.workers.some((w: any) => w.name === 'system')
        };
        setWorkers(workerStatus);
        return workerStatus;
      }
    } catch {}
    return workers;
  };

  // =================================================================
  // LEDGER COMMANDS
  // =================================================================
  const checkLedger = async (silent = false): Promise<boolean> => {
    try {
      const response = await fetch(`${API_BASE}/api/v1/ps1/ledger-status`);
      if (!response.ok) return false;
      const data = await response.json();
      setServices(prev => ({ ...prev, ledger: true }));
      if (!silent) {
        addOutput(`📚 Ledger: ${data.total_precedents} precedents stored`, "info");
      }
      return true;
    } catch {
      setServices(prev => ({ ...prev, ledger: false }));
      return false;
    }
  };

  const viewPrecedents = async (): Promise<string> => {
    addOutput("📖 Fetching constitutional precedents...", "command");
    try {
      const response = await fetch(`${API_BASE}/api/v1/ps1/ledger-precedents`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      
      const data = await response.json();
      setPrecedents(data.precedents ||[]);
      
      if (data.precedents?.length === 0) {
        addOutput("📭 No precedents stored - ledger is empty", "info");
        return "Ledger empty";
      }
      
      addOutput(`📚 Found ${data.precedents.length} constitutional precedents:`, "constitution");
      data.precedents.slice(0, 5).forEach((p: any) => {
        addOutput(`  📜 ${p.input_hash?.slice(0,8)}... → ${p.preview}`, "constitution");
      });
      
      setShowLedger(true);
      return `Displaying ${Math.min(5, data.precedents.length)} of ${data.precedents.length} precedents`;
    } catch (e: any) {
      throw new Error(`Ledger query failed: ${e.message}`);
    }
  };

  // =================================================================
  // SEARCH MODE CONTROL
  // =================================================================
  const setSearchEngine = async (engine: "duckduckgo" | "brave" | "google"): Promise<string> => {
    setSearchMode(engine);
    addOutput(`🔍 Search engine set to: ${engine.toUpperCase()}`, "success");
    return `Search mode: ${engine}`;
  };

  const testSearch = async (query: string = "latest AI news"): Promise<string> => {
    addOutput(`🔍 Testing ${searchMode.toUpperCase()} search: "${query}"...`, "command");
    try {
      const response = await fetch(`${API_BASE}/kernel/stream`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: query, worker: "search" })
      });
      
      if (response.ok) {
        addOutput(`✅ Search test initiated`, "success");
        return "Check chat for results";
      }
      throw new Error(`HTTP ${response.status}`);
    } catch (e: any) {
      throw new Error(`Search test failed: ${e.message}`);
    }
  };

  // =================================================================
  // WORKER CONTROL
  // =================================================================
  const testWorker = async (worker: string, task: string): Promise<string> => {
    addOutput(`🧪 Testing ${worker} worker: "${task}"...`, "command");
    try {
      const response = await fetch(`${API_BASE}/kernel/stream`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task, worker })
      });
      
      if (response.ok) {
        addOutput(`✅ ${worker} worker test initiated`, "success");
        return "Check chat for results";
      }
      throw new Error(`HTTP ${response.status}`);
    } catch (e: any) {
      throw new Error(`Worker test failed: ${e.message}`);
    }
  };

  // =================================================================
  // KILL PORT
  // =================================================================
  const killPort = async (port: number): Promise<string> => {
    addOutput(`🔪 Killing processes on port ${port}...`, "command");
    try {
      const response = await fetch(`${API_BASE}/admin/kill-port?port=${port}`, {
        method: "POST",
      }).catch(() => null);

      if (response?.ok) {
        addOutput(`✅ Port ${port} freed successfully`, "success");
        return `Port ${port} is now available`;
      }
      return `Port kill attempted - verify manually`;
    } catch (e: any) {
      throw new Error(e.message);
    }
  };

  // =================================================================
  // CHECK STATUS
  // =================================================================
  const checkStatus = async (silent = false): Promise<string> => {
    const startTime = Date.now();
    
    try {
      const kernel = await fetchWithTimeout(`${API_BASE}/health`, {}, 3000)
        .then(r => r.ok).catch(() => false);
      
      let chroma = false;
      try {
        const chromaRes = await fetchWithTimeout('http://localhost:8000/api/v1/heartbeat', {}, 2000);
        chroma = chromaRes.ok;
      } catch {}
      
      const nextjs = await fetchWithTimeout('http://localhost:3001', {}, 2000)
        .then(r => r.ok).catch(() => false);
      
      const ollama = await fetchWithTimeout('http://localhost:11434/api/version', {}, 2000)
        .then(r => r.ok).catch(() => false);
      
      const ledger = await checkLedger(true);
      const duckduckgo = await checkDuckDuckGo();
      const workerStatus = await checkWorkers();

      const responseTime = Date.now() - startTime;
      setServices({ kernel, chroma, nextjs, ollama, ledger, duckduckgo });

      if (!kernel) failureCount.current.kernel = (failureCount.current.kernel || 0) + 1;
      else failureCount.current.kernel = 0;
      
      if (!ollama) failureCount.current.ollama = (failureCount.current.ollama || 0) + 1;
      else failureCount.current.ollama = 0;

      if (autoHeal && !healingActive) {
        if (failureCount.current.kernel > 2) {
          setHealingActive(true);
          addOutput("🩺 Auto-heal: Kernel critical - initiating recovery...", "heal");
          killPort(8001).then(() => {
            addOutput("⏳ Port freed. Waiting for resurrection...", "info");
            setHealCount(c => c + 1);
            immunityTimer.current = setTimeout(() => setHealingActive(false), 15000);
          }).catch(() => setHealingActive(false));
        }
        else if (failureCount.current.ollama > 2 && failureCount.current.kernel === 0) {
          setHealingActive(true);
          addOutput("🩺 Auto-heal: Ollama down - attempting restart...", "heal");
          setHealCount(c => c + 1);
          immunityTimer.current = setTimeout(() => setHealingActive(false), 15000);
        }
      }
      
      const workerStatusText = `Orch: ${workerStatus.orchestrator ? "✅" : "❌"} | Brain: ${workerStatus.brain ? "✅" : "❌"} | Search: ${workerStatus.search ? "✅" : "❌"} | Code: ${workerStatus.code ? "✅" : "❌"} | Files: ${workerStatus.files ? "✅" : "❌"} | Sys: ${workerStatus.system ? "✅" : "❌"}`;
      const statusMessage = `Kernel: ${kernel ? "✅" : "❌"} | Chroma: ${chroma ? "✅" : "❌"} | Next.js: ${nextjs ? "✅" : "❌"} | Ollama: ${ollama ? "✅" : "❌"} | DDG: ${duckduckgo ? "✅" : "❌"} (${responseTime}ms)`;
      
      if (!silent) {
        addOutput(statusMessage, "success");
        addOutput(workerStatusText, "info");
      }
      
      return statusMessage;
    } catch (e: any) {
      if (!silent) addOutput(`Health check error: ${e.message}`, "error");
      throw e;
    }
  };

  // =================================================================
  // DRIFT REPORT
  // =================================================================
  const getDriftReport = async (): Promise<string> => {
    addOutput("📊 Fetching zero-drift report...", "command");
    try {
      const response = await fetch(`${API_BASE}/api/v1/ps1/drift-report`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      addOutput(`📈 Total drift events: ${data.total_drift_events}`, data.total_drift_events === 0 ? 'success' : 'warning');
      addOutput(`🛡️ Unhealed drift: ${data.unhealed_drift}`, data.unhealed_drift === 0 ? 'success' : 'warning');
      return "Drift report complete";
    } catch (e: any) {
      throw new Error(`Drift report failed: ${e.message}`);
    }
  };

  // =================================================================
  // HEAL SYSTEM
  // =================================================================
  const healSystem = async (): Promise<string> => {
    addOutput("🩺 Initiating zero-drift healing sequence...", "heal");
    setHealingActive(true);
    try {
      const response = await fetch(`${API_BASE}/api/v1/ps1/heal-system`, { method: 'POST' });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      addOutput("✅ Healing sequence complete", "success");
      setHealCount(c => c + 1);
      await new Promise(resolve => setTimeout(resolve, 2000));
      await checkStatus(false);
      return "Healing complete";
    } catch (e: any) {
      throw new Error(`Healing failed: ${e.message}`);
    } finally {
      setHealingActive(false);
    }
  };

  // =================================================================
  // CLEAR OUTPUT
  // =================================================================
  const clearOutput = () => {
    setOutput([]);
    addOutput("🔄 Output cleared", "info");
  };

  // =================================================================
  // EXECUTE COMMAND
  // =================================================================
  const executeCommand = async (cmd: any) => {
    setLoading((prev) => ({ ...prev, [cmd.id]: true }));
    addOutput(`\n> [${cmd.id}] ${cmd.name}`, "command");
    try {
      const result = await cmd.action();
      addOutput(`✅ ${result}`, "success");
    } catch (error: any) {
      addOutput(`❌ ${error.message}`, "error");
    } finally {
      setLoading((prev) => ({ ...prev, [cmd.id]: false }));
    }
  };

  // =================================================================
  // PERIODIC UPDATES
  // =================================================================
  useEffect(() => {
    if (!isOpen) return;
    checkStatus(true);
    updateMetrics();
    healthInterval.current = setInterval(() => checkStatus(true), 10000);
    metricsInterval.current = setInterval(() => updateMetrics(), 5000);
    return () => {
      if (healthInterval.current) clearInterval(healthInterval.current);
      if (metricsInterval.current) clearInterval(metricsInterval.current);
      if (immunityTimer.current) clearTimeout(immunityTimer.current);
    };
  }, [isOpen, autoHeal]);

  // =================================================================
  // COMMANDS
  // =================================================================
  const commands =[
    // SYSTEM COMMANDS (1-10)
    { id: 1, name: "CHECK STATUS", description: "Check all service health", action: () => checkStatus(false), icon: Activity },
    { id: 2, name: autoHeal ? "AUTO-HEAL: ON" : "AUTO-HEAL: OFF", description: "Toggle automatic healing", action: async () => { setAutoHeal(!autoHeal); return `Auto-healing ${!autoHeal ? 'activated' : 'deactivated'}`; }, icon: Shield },
    { id: 3, name: "VIEW LEDGER", description: "Show constitutional precedents", action: viewPrecedents, icon: BookOpen },
    { id: 4, name: "DRIFT REPORT", description: "View zero-drift status", action: getDriftReport, icon: RefreshCw },
    { id: 5, name: "HEAL SYSTEM", description: "Run full healing sequence", action: healSystem, icon: RotateCw },
    { id: 6, name: "LEDGER STATUS", description: "Check ledger health", action: async () => { const ok = await checkLedger(false); return ok ? "Ledger operational" : "Ledger offline"; }, icon: Database },
    
    // SEARCH COMMANDS (11-15)
    { id: 11, name: "DDG SEARCH", description: "Test DuckDuckGo search", action: () => testSearch("latest AI news"), icon: Globe },
    { id: 12, name: "SET DDG", description: "Set search to DuckDuckGo", action: () => setSearchEngine("duckduckgo"), icon: Globe },
    
    // WORKER TESTS (21-30)
    { id: 21, name: "TEST BRAIN", description: "Test Brain worker", action: () => testWorker("brain", "What is the capital of France?"), icon: Brain },
    { id: 22, name: "TEST SEARCH", description: "Test Search worker", action: () => testWorker("search", "latest AI news"), icon: Eye },
    { id: 23, name: "TEST CODE", description: "Test Code worker", action: () => testWorker("code", "Create a Python function to calculate fibonacci"), icon: Code },
    { id: 24, name: "TEST FILES", description: "Test Files worker", action: () => testWorker("files", "list drives"), icon: Database },
    { id: 25, name: "TEST SYSTEM", description: "Test System worker", action: () => testWorker("system", "/check_system"), icon: Terminal },
    
    // PORT COMMANDS (16-20)
    { id: 16, name: "KILL PORT 8001", description: "Free kernel port", action: () => killPort(8001), icon: Terminal, danger: true },
    { id: 17, name: "KILL PORT 3001", description: "Free Next.js port", action: () => killPort(3001), icon: Terminal, danger: true },
    { id: 18, name: "KILL PORT 8000", description: "Free Chroma port", action: () => killPort(8000), icon: Terminal, danger: true },
    
    // UTILITY COMMANDS (31-35)
    { id: 31, name: "CLEAR OUTPUT", description: "Clear terminal", action: clearOutput, icon: Trash2 },
    { id: 32, name: "SYSTEM METRICS", description: "Show current metrics", action: async () => { return `CPU: ${metrics.cpu}% | RAM: ${metrics.memory}% | Tokens: ${metrics.tokens}/${metrics.maxTokens}`; }, icon: Cpu },
  ];

  const getStatusColor = (isOnline: boolean) => {
    if (!isOnline && autoHeal && failureCount.current.kernel > 2) return "bg-yellow-500 animate-pulse";
    return isOnline ? "bg-green-500" : "bg-red-500";
  };

  const tokenPercentage = (metrics.tokens / metrics.maxTokens) * 100;

  return (
    <>
      {/* Floating Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`fixed bottom-6 right-6 w-14 h-14 rounded-full flex items-center justify-center transition-all z-40 shadow-2xl ${
          isOpen ? "bg-red-500/20 border border-red-500/50 text-red-400 rotate-45" :
          healingActive ? "bg-yellow-500/30 border border-yellow-500/50 text-yellow-400 animate-pulse" :
          autoHeal ? "bg-green-500/30 border border-green-500/50 text-green-400" :
          "bg-gradient-to-br from-cyan-500/30 to-purple-500/30 border border-cyan-500/50 text-cyan-400"
        }`}
        title="REZ HIVE PS1 Controller"
      >
        {healingActive ? <RotateCw size={20} className="animate-spin" /> : <Shield size={20} />}
      </button>

      {/* Controller Panel */}
      {isOpen && (
        <div className="fixed bottom-24 right-6 w-96 bg-[#0E1015] border-2 border-cyan-500/40 rounded-xl shadow-2xl shadow-cyan-500/10 overflow-hidden z-40 flex flex-col max-h-[600px] backdrop-blur-xl">
          
          {/* Header with Metrics */}
          <div className="bg-gradient-to-r from-cyan-500/20 to-purple-500/20 border-b border-cyan-500/30 px-4 py-2">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Terminal size={16} className="text-cyan-400" />
                <span className="font-mono text-sm font-bold text-cyan-400">PS1 v2.0</span>
              </div>
              <div className="flex items-center gap-2">
                {/* Service Status Dots */}
                <div className="flex items-center gap-1">
                  <div className={`w-2 h-2 rounded-full ${getStatusColor(services.kernel)} ${services.kernel ? 'animate-pulse' : ''}`} title="Kernel" />
                  <div className={`w-2 h-2 rounded-full ${services.chroma ? 'bg-green-500' : 'bg-red-500'}`} title="Chroma" />
                  <div className={`w-2 h-2 rounded-full ${services.ollama ? 'bg-green-500' : 'bg-red-500'}`} title="Ollama" />
                  <div className={`w-2 h-2 rounded-full ${services.duckduckgo ? 'bg-blue-500' : 'bg-gray-500'}`} title="DuckDuckGo" />
                  <div className={`w-2 h-2 rounded-full ${services.ledger ? 'bg-purple-500' : 'bg-gray-500'}`} title="Ledger" />
                </div>
                <span className="text-xs text-white/40 ml-2">heals:{healCount}</span>
                <button onClick={() => setIsOpen(false)} className="p-1 hover:bg-white/10 rounded transition-colors text-white/60"><X size={16} /></button>
              </div>
            </div>
            
            {/* Token Usage Bar */}
            <div className="mt-2">
              <div className="flex justify-between text-[8px] text-white/30 mb-0.5">
                <span>CONTEXT</span>
                <span>{metrics.tokens} / {metrics.maxTokens} tokens</span>
              </div>
              <div className="h-1 bg-black/40 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-gradient-to-r from-cyan-500 to-purple-500"
                  style={{ width: `${tokenPercentage}%` }}
                />
              </div>
            </div>
          </div>

          {/* Worker Status Row */}
          <div className="border-b border-cyan-500/20 px-3 py-1.5 flex justify-between text-[8px] font-mono text-white/40">
            <span className={workers.orchestrator ? "text-cyan-400" : ""}>ORCH:{workers.orchestrator ? "✅" : "❌"}</span>
            <span className={workers.brain ? "text-green-400" : ""}>🧠:{workers.brain ? "✅" : "❌"}</span>
            <span className={workers.search ? "text-blue-400" : ""}>👁️:{workers.search ? "✅" : "❌"}</span>
            <span className={workers.code ? "text-yellow-400" : ""}>✋:{workers.code ? "✅" : "❌"}</span>
            <span className={workers.files ? "text-purple-400" : ""}>📁:{workers.files ? "✅" : "❌"}</span>
            <span className={workers.system ? "text-orange-400" : ""}>⚙️:{workers.system ? "✅" : "❌"}</span>
          </div>

          {/* Commands Grid - Scrollable */}
          <div className="border-b border-cyan-500/20 px-3 py-3 grid grid-cols-3 gap-1.5 max-h-[200px] overflow-y-auto custom-scrollbar">
            {commands.map((cmd) => (
              <button 
                key={cmd.id} 
                onClick={() => executeCommand(cmd)} 
                disabled={loading[cmd.id]}
                className={`text-left px-2 py-2 bg-white/5 hover:bg-cyan-500/10 disabled:opacity-50 rounded-lg border border-white/10 hover:border-cyan-500/30 transition-all text-[10px] ${cmd.danger ? 'hover:border-red-500/30 hover:bg-red-500/10' : ''}`}
              >
                <div className="flex items-center gap-1 mb-0.5">
                  {cmd.icon && <cmd.icon size={10} className="text-cyan-400" />}
                  <span className="text-cyan-400 font-mono text-[8px] font-bold">[{cmd.id}]</span>
                </div>
                <div className="text-white/80 text-[9px] font-medium truncate">{cmd.name}</div>
              </button>
            ))}
          </div>

          {/* Ledger Panel (Conditional) */}
          {showLedger && precedents.length > 0 && (
            <div className="border-b border-cyan-500/20 px-3 py-2 bg-purple-500/5 max-h-[80px] overflow-y-auto">
              <div className="flex items-center justify-between mb-1">
                <span className="text-purple-400 font-mono text-[8px] font-bold">📚 RECENT PRECEDENTS</span>
                <button onClick={() => setShowLedger(false)} className="text-white/30 hover:text-white/60">✕</button>
              </div>
              {precedents.slice(0, 2).map((p, i) => (
                <div key={i} className="text-[7px] font-mono text-white/40 truncate border-l border-purple-500/30 pl-2 my-1">
                  {p.input_hash?.slice(0,6)}... → {p.preview?.slice(0,30)}...
                </div>
              ))}
            </div>
          )}

          {/* Output Terminal */}
          <div className="flex-1 bg-black/60 font-mono text-[9px] overflow-y-auto custom-scrollbar p-2 space-y-1 min-h-[150px]">
            {output.length === 0 ? (
              <div className="text-white/20 italic">$ Sovereign controller ready. 6 workers active.</div>
            ) : (
              output.map((line) => (
                <div key={line.id} className={`flex gap-1 ${
                  line.type === "command" ? "text-cyan-400" :
                  line.type === "success" ? "text-green-400" :
                  line.type === "error" ? "text-red-400" :
                  line.type === "heal" ? "text-yellow-400" :
                  line.type === "constitution" ? "text-purple-400" :
                  line.type === "search" ? "text-blue-400" :
                  "text-white/60"
                }`}>
                  <span className="text-white/20 flex-shrink-0">[{line.timestamp}]</span>
                  <span className="flex-1">{line.text}</span>
                </div>
              ))
            )}
            <div ref={outputRef} />
          </div>

          {/* Footer */}
          <div className="bg-black/60 border-t border-cyan-500/20 px-3 py-1.5 flex justify-between items-center text-[7px]">
            <div className="flex items-center gap-2">
              <button onClick={() => checkStatus()} className="px-1.5 py-0.5 bg-cyan-500/10 hover:bg-cyan-500/20 rounded text-cyan-400 border border-cyan-500/30 flex items-center gap-1">
                <RefreshCw size={8} /> Refresh
              </button>
              <button onClick={clearOutput} className="px-1.5 py-0.5 bg-white/5 hover:bg-white/10 rounded text-white/60 border border-white/10">Clear</button>
            </div>
            <div className="flex items-center gap-1">
              <span className="text-white/20">v2.0</span>
              <Bell size={8} className="text-white/20" />
            </div>
          </div>
        </div>
      )}

      {/* Custom Scrollbar */}
      <style jsx>{`
        .custom-scrollbar::-webkit-scrollbar { width: 3px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(0, 229, 255, 0.2); border-radius: 3px; }
      `}</style>
    </>
  );
}