'use client';

import { Code, BarChart3, Eye, Terminal } from 'lucide-react';

export function WorkerGrid() {
  const workers = [
    { icon: Code, name: 'Developer', color: 'text-blue-400', bg: 'bg-blue-400/10' },
    { icon: BarChart3, name: 'Analyst', color: 'text-orange-400', bg: 'bg-orange-400/10' },
    { icon: Eye, name: 'Visionary', color: 'text-purple-400', bg: 'bg-purple-400/10' },
    { icon: Terminal, name: 'Execution Engine', color: 'text-rose-400', bg: 'bg-rose-400/10' },
  ];

  return (
    <div className="grid grid-cols-2 gap-3 mb-4">
      {workers.map((worker, i) => (
        <div key={i} className={`glass-card p-3 ${worker.bg} border-${worker.color.replace('text-', '')}/20`}>
          <div className="flex items-center gap-2">
            <worker.icon size={16} className={worker.color} />
            <span className="text-xs font-medium">{worker.name}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
