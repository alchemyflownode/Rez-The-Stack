import React from 'react';

interface Props {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'secondary' | 'ghost';
  className?: string;
}

export function SovereignButton({ children, onClick, variant = 'secondary', className = '' }: Props) {
  const styles = {
    primary: "bg-gradient-to-r from-purple-600 to-violet-600 text-white shadow-[0_0_10px_rgba(139,92,246,0.3)] hover:shadow-[0_0_15px_rgba(139,92,246,0.5)]",
    secondary: "bg-white/5 border border-white/10 text-white/70 hover:bg-white/10 hover:text-white hover:border-purple-500/30",
    ghost: "bg-transparent text-white/50 hover:bg-white/5"
  };
  return (
    <button onClick={onClick} className={`px-3 py-2 rounded-lg text-xs font-medium transition-all flex items-center gap-1 ${styles[variant]} ${className}`}>
      {children}
    </button>
  );
}
