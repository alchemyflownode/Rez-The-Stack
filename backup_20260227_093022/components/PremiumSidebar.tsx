'use client';

import { cn } from '@/lib/utils';
import { Shield, Clock, Cpu, HardDrive, Activity, CheckCircle, Zap, Brain } from 'lucide-react';
import { GlassCard } from './ui/GlassCard';
import { motion } from 'framer-motion';

interface PremiumSidebarProps {
  constitution?: string[];
  history?: any[];
  metrics?: {
    cpu: number;
    ram: number;
    gpu: number;
  };
  className?: string;
}

export function PremiumSidebar({ constitution, history, metrics, className }: PremiumSidebarProps) {
  const defaultMetrics = {
    cpu: 23,
    ram: 38,
    gpu: 12
  };

  const data = {
    metrics: metrics || defaultMetrics,
    constitution: constitution || [
      "Preserve user privacy",
      "Verify before code execution",
      "No unauthorized deletion",
      "System watches continuously"
    ],
    history: history || [
      { task: "Check system health", time: "2m ago", status: "success" },
      { task: "Open Chrome", time: "5m ago", status: "success" },
      { task: "Deep search: AI news", time: "10m ago", status: "processing" }
    ]
  };

  return (
    <div className={cn(
      'fixed left-6 top-6 bottom-6 w-80',
      'flex flex-col gap-4',
      className
    )}>
      {/* Header */}
      <GlassCard variant="thin" radius="lg" className="p-4">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center">
            <Brain className="w-4 h-4 text-white" />
          </div>
          <div>
            <h1 className="text-sm font-medium text-white/90">SOVEREIGN</h1>
            <p className="text-[10px] text-white/30 font-mono">v2026 • LOCAL AI</p>
          </div>
          <div className="ml-auto">
            <span className="flex items-center gap-1 text-[10px] text-secondary">
              <span className="w-1.5 h-1.5 bg-secondary rounded-full animate-pulse" />
              LIVE
            </span>
          </div>
        </div>
      </GlassCard>

      {/* Metrics */}
      <GlassCard variant="thin" radius="lg" className="p-4">
        <div className="grid grid-cols-3 gap-3">
          <div className="text-center">
            <div className="text-xs font-mono text-white/90">{data.metrics.cpu}%</div>
            <div className="text-[8px] text-white/30 uppercase tracking-wider mt-1">CPU</div>
          </div>
          <div className="text-center">
            <div className="text-xs font-mono text-white/90">{data.metrics.ram}%</div>
            <div className="text-[8px] text-white/30 uppercase tracking-wider mt-1">RAM</div>
          </div>
          <div className="text-center">
            <div className="text-xs font-mono text-white/90">{data.metrics.gpu}%</div>
            <div className="text-[8px] text-white/30 uppercase tracking-wider mt-1">GPU</div>
          </div>
        </div>
      </GlassCard>

      {/* Constitution */}
      <GlassCard variant="thin" radius="lg" className="p-4 flex-1 overflow-y-auto">
        <h2 className="text-[10px] font-mono text-white/30 uppercase tracking-wider mb-3 flex items-center gap-2">
          <Shield className="w-3 h-3" />
          CONSTITUTION
        </h2>
        <div className="space-y-2">
          {data.constitution.map((rule, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.1 }}
              className="flex items-start gap-2 text-[10px] text-white/60 hover:text-white/80 transition-colors cursor-default"
            >
              <span className="w-1 h-1 bg-primary/50 rounded-full mt-1.5" />
              <span>{rule}</span>
            </motion.div>
          ))}
        </div>

        {/* Badge chips */}
        <div className="mt-4 flex flex-wrap gap-1">
          <span className="px-2 py-1 bg-white/5 rounded-full text-[8px] text-white/40 font-mono">PRIVACY</span>
          <span className="px-2 py-1 bg-white/5 rounded-full text-[8px] text-white/40 font-mono">LOCAL</span>
          <span className="px-2 py-1 bg-white/5 rounded-full text-[8px] text-white/40 font-mono">SECURE</span>
        </div>
      </GlassCard>

      {/* History */}
      <GlassCard variant="thin" radius="lg" className="p-4">
        <h2 className="text-[10px] font-mono text-white/30 uppercase tracking-wider mb-3 flex items-center gap-2">
          <Clock className="w-3 h-3" />
          ACTIVITY
        </h2>
        <div className="space-y-2 max-h-32 overflow-y-auto">
          {data.history.map((entry, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.05 }}
              className="flex items-center justify-between text-[10px] py-1 border-b border-white/5 last:border-0"
            >
              <span className="text-white/50 truncate max-w-[140px]">{entry.task}</span>
              <div className="flex items-center gap-2">
                <span className="text-white/20 text-[8px]">{entry.time}</span>
                {entry.status === 'success' && (
                  <CheckCircle className="w-2.5 h-2.5 text-secondary/50" />
                )}
                {entry.status === 'processing' && (
                  <Zap className="w-2.5 h-2.5 text-primary/50 animate-pulse" />
                )}
              </div>
            </motion.div>
          ))}
        </div>
      </GlassCard>
    </div>
  );
}
