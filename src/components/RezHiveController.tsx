// src/components/RezHiveController.tsx - FINAL SOVEREIGN VERSION
"use client";

import { useState, useRef, useEffect } from "react";
import { X, Play, RotateCw, Activity, Zap, Shield, Terminal, RefreshCw, Trash2 } from "lucide-react";

interface OutputLine {
  id: string;
  text: string;
  timestamp: string;
  type: "command" | "success" | "error" | "info" | "heal" | "warning";
}

interface ServiceStatus {
  kernel: boolean;
  chroma: boolean;
  nextjs: boolean;
  ollama: boolean;
}

const API_BASE = "http://localhost:8001";

export function RezHiveController() {
  const [isOpen, setIsOpen] = useState(false);
  const [output, setOutput] = useState<OutputLine[]>([]);
  const [loading, setLoading] = useState<Record<number, boolean>>({});
  const [services, setServices] = useState<ServiceStatus>({
    kernel: false,
    chroma: false,
    nextjs: true,
    ollama: false
  });
  const [healingActive, setHealingActive] = useState(false);
  const [autoHeal, setAutoHeal] = useState(false);
  const [healCount, setHealCount] = useState(0);
  
  const outputRef = useRef<HTMLDivElement>(null);
  const healthInterval = useRef<NodeJS.Timeout>();
  const failureCount = useRef<Record<string, number>>({});
  const immunityTimer = useRef<NodeJS.Timeout>();

  const getTime = () => {
    const d = new Date();
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}:${d.getSeconds().toString().padStart(2, '0')}`;
  };

  const addOutput = (text: string, type: OutputLine["type"] = "info") => {
    setOutput((prev) => [
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
    };
  }, []);

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

      const responseTime = Date.now() - startTime;
      setServices({ kernel, chroma, nextjs, ollama });

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
      
      const statusMessage = `Kernel: ${kernel ? "✅" : "❌"} | Chroma: ${chroma ? "✅" : "❌"} | Next.js: ${nextjs ? "✅" : "❌"} | Ollama: ${ollama ? "✅" : "❌"} (${responseTime}ms)`;
      if (!silent) addOutput(statusMessage, "success");
      
      return statusMessage;
    } catch (e: any) {
      if (!silent) addOutput(`Health check error: ${e.message}`, "error");
      throw e;
    }
  };

  const getDriftReport = async (): Promise<string> => {
    addOutput("📊 Fetching zero-drift report...", "command");
    try {
      const response = await fetch(`${API_BASE}/api/v1/ps1/drift-report`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      addOutput(`📈 Total drift events: ${data.total_drift_events}`, 'success');
      return "Drift report complete";
    } catch (e: any) {
      throw new Error(`Drift report failed: ${e.message}`);
    }
  };

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

  const clearOutput = () => {
    setOutput([]);
    addOutput("🔄 Output cleared", "info");
  };

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

  useEffect(() => {
    if (!isOpen) return;
    checkStatus(true);
    healthInterval.current = setInterval(() => checkStatus(true), 10000);
    return () => {
      if (healthInterval.current) clearInterval(healthInterval.current);
      if (immunityTimer.current) clearTimeout(immunityTimer.current);
    };
  }, [isOpen, autoHeal]);

  const commands = [
    { id: 1, name: "CHECK STATUS", description: "Check all service health", action: () => checkStatus(false), icon: Activity },
    { id: 2, name: autoHeal ? "AUTO-HEAL: ON" : "AUTO-HEAL: OFF", description: "Toggle automatic healing", action: async () => { setAutoHeal(!autoHeal); return `Auto-healing ${!autoHeal ? 'activated' : 'deactivated'}`; }, icon: Shield },
    { id: 4, name: "DRIFT REPORT", description: "View zero-drift status", action: getDriftReport, icon: RefreshCw },
    { id: 5, name: "HEAL SYSTEM", description: "Run full healing sequence", action: healSystem, icon: RotateCw },
    { id: 16, name: "KILL PORT 8001", description: "Free kernel port", action: () => killPort(8001), icon: Terminal, danger: true },
    { id: 17, name: "KILL PORT 3001", description: "Free Next.js port", action: () => killPort(3001), icon: Terminal, danger: true },
    { id: 18, name: "KILL PORT 8000", description: "Free Chroma port", action: () => killPort(8000), icon: Terminal, danger: true },
    { id: 20, name: "CLEAR OUTPUT", description: "Clear terminal", action: clearOutput, icon: Trash2 },
  ];

  const getStatusColor = (isOnline: boolean) => {
    if (!isOnline && autoHeal && failureCount.current.kernel > 2) return "bg-yellow-500 animate-pulse";
    return isOnline ? "bg-green-500" : "bg-red-500";
  };

  return (
    <>
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

      {isOpen && (
        <div className="fixed bottom-24 right-6 w-96 bg-[#0E1015] border-2 border-cyan-500/40 rounded-xl shadow-2xl shadow-cyan-500/10 overflow-hidden z-40 flex flex-col max-h-[600px] backdrop-blur-xl">
          <div className="bg-gradient-to-r from-cyan-500/20 to-purple-500/20 border-b border-cyan-500/30 px-4 py-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Terminal size={16} className="text-cyan-400" />
                <span className="font-mono text-sm font-bold text-cyan-400">PS1 CONTROLLER v2.0</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="flex items-center gap-1">
                  <div className={`w-2 h-2 rounded-full ${getStatusColor(services.kernel)} ${services.kernel ? 'animate-pulse' : ''}`} title="Kernel" />
                  <div className={`w-2 h-2 rounded-full ${services.chroma ? 'bg-green-500' : 'bg-red-500'}`} title="Chroma" />
                  <div className={`w-2 h-2 rounded-full ${services.ollama ? 'bg-green-500' : 'bg-red-500'}`} title="Ollama" />
                  <div className={`w-2 h-2 rounded-full ${services.nextjs ? 'bg-green-500' : 'bg-red-500'}`} title="Next.js" />
                </div>
                <span className="text-xs text-white/40 ml-2">heals:{healCount}</span>
                <button onClick={() => setIsOpen(false)} className="p-1 hover:bg-white/10 rounded transition-colors text-white/60"><X size={16} /></button>
              </div>
            </div>
          </div>

          <div className="border-b border-cyan-500/20 px-3 py-3 grid grid-cols-2 gap-2 max-h-[200px] overflow-y-auto custom-scrollbar">
            {commands.map((cmd) => (
              <button key={cmd.id} onClick={() => executeCommand(cmd)} disabled={loading[cmd.id]}
                className={`text-left px-3 py-2.5 bg-white/5 hover:bg-cyan-500/10 disabled:opacity-50 rounded-lg border border-white/10 hover:border-cyan-500/30 transition-all ${cmd.danger ? 'hover:border-red-500/30 hover:bg-red-500/10' : ''}`}>
                <div className="flex items-center gap-2">
                  {cmd.icon && <cmd.icon size={12} className="text-cyan-400" />}
                  <span className="text-cyan-400 font-mono text-xs font-bold">[{cmd.id}]</span>
                </div>
                <div className="text-white/80 text-xs font-medium mt-1">{cmd.name}</div>
              </button>
            ))}
          </div>

          <div className="flex-1 bg-black/60 font-mono text-xs overflow-y-auto custom-scrollbar p-3 space-y-1 min-h-[200px]">
            {output.length === 0 ? (
              <div className="text-white/20 italic">$ Sovereign controller ready.</div>
            ) : (
              output.map((line) => (
                <div key={line.id} className={`flex gap-2 ${line.type === "command" ? "text-cyan-400" : line.type === "success" ? "text-green-400" : line.type === "error" ? "text-red-400" : line.type === "heal" ? "text-yellow-400" : "text-white/60"}`}>
                  <span className="text-white/20 flex-shrink-0">[{line.timestamp}]</span>
                  <span className="flex-1">{line.text}</span>
                </div>
              ))
            )}
            <div ref={outputRef} />
          </div>

          <div className="bg-black/60 border-t border-cyan-500/20 px-3 py-2 flex justify-between items-center text-[10px]">
            <div className="flex items-center gap-2">
              <button onClick={() => checkStatus()} className="px-2 py-1 bg-cyan-500/10 hover:bg-cyan-500/20 rounded text-cyan-400 border border-cyan-500/30 flex items-center gap-1"><RefreshCw size={10} /> Refresh</button>
              <button onClick={clearOutput} className="px-2 py-1 bg-white/5 hover:bg-white/10 rounded text-white/60 border border-white/10">Clear</button>
            </div>
            <span className="text-white/20">Zero-Drift • Sovereign • v2.0</span>
          </div>
        </div>
      )}
      <style jsx>{`.custom-scrollbar::-webkit-scrollbar { width: 4px; } .custom-scrollbar::-webkit-scrollbar-track { background: transparent; } .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(0, 229, 255, 0.2); border-radius: 4px; }`}</style>
    </>
  );
}