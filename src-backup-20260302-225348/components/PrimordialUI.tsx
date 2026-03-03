'use client';

import { useState } from 'react';
import { Brain, Lightbulb } from 'lucide-react';

export function PrimordialUI() {
  const [agentMode] = useState('learning');
  const [suggestions] = useState([
    {
      id: '1',
      type: 'insight',
      message: 'I notice you check CPU often. Would you like a shortcut?',
    },
    {
      id: '2',
      type: 'tip',
      message: 'Your RAM usage suggests closing Chrome tabs might help',
    }
  ]);

  return (
    <>
      {/* Agent Status Badge */}
      <div className="fixed top-20 right-4 z-50">
        <div className="px-3 py-1.5 rounded-full bg-blue-500/20 border border-blue-500/30 text-blue-400 text-xs flex items-center gap-2 backdrop-blur-xl">
          <span className="w-2 h-2 rounded-full animate-pulse bg-blue-400" />
          <span>Agent: {agentMode}</span>
        </div>
      </div>

      {/* Agent Thought Bubble */}
      <div className="fixed top-28 right-4 w-72 z-40">
        <div className="glass-card p-4 border-l-4 border-blue-500">
          <Brain className="text-blue-400 absolute -left-3 -top-3" size={20} />
          <p className="text-sm text-white/80 italic">
            &ldquo;I'm learning your patterns. You seem most active at night.&rdquo;
          </p>
        </div>
      </div>

      {/* Suggestions Panel */}
      <div className="fixed bottom-24 right-4 w-80 space-y-2 z-40">
        <h3 className="text-xs font-bold text-white/40 uppercase tracking-wider mb-2 px-2">
          Agent Insights
        </h3>
        {suggestions.map(s => (
          <div key={s.id} className="glass-card p-4 border-l-4 border-blue-500">
            <div className="flex gap-3">
              <Lightbulb className="text-blue-400 shrink-0" size={18} />
              <p className="text-sm text-white/80">{s.message}</p>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
