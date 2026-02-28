'use client';

import { useState, useEffect } from 'react';
import { cn } from '@/lib/utils';
import { 
  Shield, Clock, Cpu, HardDrive, Zap, 
  Activity, AlertCircle, CheckCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface MetricRingProps {
  value: number;
  max: number;
  label: string;
  color?: string;
  size?: 'sm' | 'md';
}

function MetricRing({ value, max, label, color = '#8B5CF6', size = 'md' }: MetricRingProps) {
  const percentage = (value / max) * 100;
  const radius = size === 'md' ? 30 : 20;
  const strokeWidth = size === 'md' ? 4 : 3;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (percentage / 100) * circumference;

  return (
    <div className="flex flex-col items-center">
      <div className="relative">
        <svg width={radius * 2 + 10} height={radius * 2 + 10} className="transform -rotate-90">
          {/* Background circle */}
          <circle
            cx={radius + 5}
            cy={radius + 5}
            r={radius}
            fill="none"
            stroke="rgba(255,255,255,0.1)"
            strokeWidth={strokeWidth}
          />
          {/* Progress circle */}
          <circle
            cx={radius + 5}
            cy={radius + 5}
            r={radius}
            fill="none"
            stroke={color}
            strokeWidth={strokeWidth}
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            className="transition-all duration-500"
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <span className={cn(
            'font-mono',
            size === 'md' ? 'text-sm' : 'text-xs'
          )}>{value}%</span>
        </div>
      </div>
      <span className={cn(
        'text-white/50',
        size === 'md' ? 'text-[10px] mt-1' : 'text-[8px] mt-0.5'
      )}>{label}</span>
    </div>
  );
}

interface SovereignSidebarProps {
  constitution?: string[];
  history?: any[];
  className?: string;
}

export function SovereignSidebar({ constitution, history, className }: SovereignSidebarProps) {
  const [metrics, setMetrics] = useState({
    cpu: 23,
    gpu: 12,
    npu: 8,
    ram: 38
  });

  const [activeAlerts, setActiveAlerts] = useState<string[]>([]);

  // Simulate metric updates
  useEffect(() => {
    const interval = setInterval(() => {
      setMetrics({
        cpu: Math.floor(Math.random() * 30) + 10,
        gpu: Math.floor(Math.random() * 20) + 5,
        npu: Math.floor(Math.random() * 15) + 5,
        ram: Math.floor(Math.random() * 40) + 30
      });
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  const defaultConstitution = [
    "Preserve user privacy",
    "Verify before code execution",
    "No unauthorized file deletion",
    "System watches continuously"
  ];

  const defaultHistory = [
    { task: "Check system health", time: "2m ago", status: "success" },
    { task: "Open Chrome", time: "5m ago", status: "success" },
    { task: "Deep search: AI news", time: "10m ago", status: "processing" }
  ];

  return (
    <div className={cn(
      'fixed left-0 top-0 bottom-0 w-80',
      'bg-black/20 backdrop-blur-[40px]',
      'border-r border-white/10',
      'p-6 flex flex-col gap-6',
      'font-mono text-[10px]',
      className
    )}>
      {/* Header */}
      <div className="flex items-center gap-2 pb-4 border-b border-white/10">
        <Shield className="w-4 h-4 text-purple-400" />
        <span className="text-sm font-bold text-white/90 tracking-wider">SOVEREIGN</span>
        <span className="text-[8px] text-green-400 ml-auto flex items-center gap-1">
          <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
          LIVE
        </span>
      </div>

      {/* Metrics Rings */}
      <div className="grid grid-cols-2 gap-4">
        <MetricRing value={metrics.cpu} max={100} label="CPU" color="#8B5CF6" />
        <MetricRing value={metrics.gpu} max={100} label="GPU" color="#10B981" />
        <MetricRing value={metrics.npu} max={100} label="NPU" color="#3B82F6" size="sm" />
        <MetricRing value={metrics.ram} max={100} label="RAM" color="#F59E0B" size="sm" />
      </div>

      {/* Active Alerts */}
      <div className="space-y-2">
        <h4 className="text-white/40 text-[8px] tracking-wider">ACTIVE GOVERNANCE</h4>
        <div className="space-y-1">
          <div className="flex items-center gap-2 text-[8px] text-green-400">
            <Shield className="w-2.5 h-2.5" />
            <span>Privacy Lock Active</span>
          </div>
          <div className="flex items-center gap-2 text-[8px] text-amber-400">
            <Activity className="w-2.5 h-2.5" />
            <span>Resource Monitor</span>
          </div>
        </div>
      </div>

      {/* Constitution */}
      <div className="space-y-2 flex-1">
        <h4 className="text-white/40 text-[8px] tracking-wider">CONSTITUTION</h4>
        <ul className="space-y-1.5">
          {(constitution || defaultConstitution).map((rule, i) => (
            <motion.li
              key={i}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.1 }}
              className="flex items-start gap-2 text-[8px] text-white/60"
            >
              <span className="w-1 h-1 bg-purple-500 rounded-full mt-1" />
              <span>{rule}</span>
            </motion.li>
          ))}
        </ul>
      </div>

      {/* Recent History */}
      <div className="space-y-2">
        <h4 className="text-white/40 text-[8px] tracking-wider">KERNEL LOG</h4>
        <div className="space-y-1 max-h-32 overflow-y-auto">
          {(history || defaultHistory).map((entry, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.05 }}
              className="flex items-center justify-between text-[8px] py-0.5 border-b border-white/5 last:border-0"
            >
              <span className="text-white/40 truncate max-w-[120px]">{entry.task}</span>
              <div className="flex items-center gap-1">
                <span className="text-white/20">{entry.time}</span>
                {entry.status === 'success' && (
                  <CheckCircle className="w-2.5 h-2.5 text-green-500/50" />
                )}
                {entry.status === 'processing' && (
                  <Zap className="w-2.5 h-2.5 text-purple-500/50 animate-pulse" />
                )}
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* System Version */}
      <div className="pt-4 border-t border-white/10 text-[6px] text-white/20 text-center">
        SOVEREIGN OS v2026 • LOCAL AI • PRIVATE BY DESIGN
      </div>
    </div>
  );
}
