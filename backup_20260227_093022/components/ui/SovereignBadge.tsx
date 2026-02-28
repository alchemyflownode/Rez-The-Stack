import React from 'react';

interface Props {
  children: React.ReactNode;
  variant?: 'online' | 'offline';
}

export function SovereignBadge({ children, variant = 'online' }: Props) {
  const styles = {
    online: "bg-emerald-500/20 text-emerald-400 shadow-[0_0_8px_rgba(16,185,129,0.3)]",
    offline: "bg-red-500/20 text-red-400"
  };
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium ${styles[variant]}`}>
      {variant === 'online' && <span className="w-1.5 h-1.5 rounded-full bg-current animate-pulse" />}
      {children}
    </span>
  );
}
