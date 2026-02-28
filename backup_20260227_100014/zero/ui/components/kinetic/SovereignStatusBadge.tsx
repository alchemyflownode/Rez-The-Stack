'use client';
import { cn } from '@/lib/utils';
import { Fingerprint } from 'lucide-react';

interface SovereignStatusBadgeProps {
  proof: string;
  status?: 'verified' | 'verifying' | 'active' | 'error';
  size?: 'sm' | 'md' | 'lg';
  showIcon?: boolean;
  pulse?: boolean;
  className?: string;
}

export const SovereignStatusBadge: React.FC<SovereignStatusBadgeProps> = ({
  proof,
  status = 'verified',
  size = 'md',
  showIcon = true,
  pulse = true,
  className
}) => {
  const statusConfig = {
    verified: { dot: 'bg-[#00FFC2]', text: 'text-[#00FFC2]', label: 'VERIFIED' },
    verifying: { dot: 'bg-[#FFB800] animate-pulse', text: 'text-[#FFB800]', label: 'VERIFYING' },
    active: { dot: 'bg-[#00FFC2] animate-pulse', text: 'text-[#00FFC2]', label: 'ACTIVE' },
    error: { dot: 'bg-white/30', text: 'text-white/50', label: 'ERROR' }
  };

  const sizeMap = {
    sm: 'px-3 py-1.5 text-[8px]',
    md: 'px-4 py-2 text-[10px]',
    lg: 'px-5 py-2.5 text-xs'
  };

  const config = statusConfig[status];

  return (
    <div className={cn(
      'bg-[rgba(18,18,20,0.7)] backdrop-blur-xl',
      'border border-white/5 rounded-[4px]',
      'flex items-center gap-3',
      sizeMap[size],
      className
    )}>
      {showIcon && <Fingerprint size={size === 'sm' ? 12 : 14} className={config.text} />}
      <div className="flex items-center gap-2">
        {pulse && <span className={cn('w-1.5 h-1.5 rounded-full', config.dot)} />}
        <span className="font-mono tracking-wider text-white/70">{config.label}</span>
      </div>
      <div className="w-px h-3 bg-white/10" />
      <span className={cn('font-mono tracking-wider', config.text)}>{proof}</span>
    </div>
  );
};
