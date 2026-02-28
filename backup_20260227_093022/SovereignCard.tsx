'use client';

import { cn } from '@/lib/utils';
import { forwardRef, HTMLAttributes } from 'react';

interface SovereignCardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'glass' | 'ultra-thin' | 'neural';
  glowColor?: 'purple' | 'green' | 'amber' | 'blue';
  animate?: boolean;
}

export const SovereignCard = forwardRef<HTMLDivElement, SovereignCardProps>(
  ({ className, variant = 'glass', glowColor = 'purple', animate = true, children, ...props }, ref) => {
    const glowColors = {
      purple: 'rgba(139, 92, 246, 0.3)',
      green: 'rgba(16, 185, 129, 0.3)',
      amber: 'rgba(245, 158, 11, 0.3)',
      blue: 'rgba(59, 130, 246, 0.3)'
    };

    return (
      <div
        ref={ref}
        className={cn(
          'relative overflow-hidden rounded-[2rem] transition-all duration-300',
          'border border-white/10 shadow-2xl',
          
          // Variants
          variant === 'glass' && 'bg-black/40 backdrop-blur-xl',
          variant === 'ultra-thin' && 'bg-black/20 backdrop-blur-[40px]',
          variant === 'neural' && 'bg-gradient-to-br from-purple-500/10 via-transparent to-blue-500/10 backdrop-blur-2xl',
          
          // Animations
          animate && 'hover:scale-[1.02] hover:border-purple-500/30',
          
          className
        )}
        style={{
          boxShadow: animate ? `0 20px 50px rgba(0,0,0,0.5), 0 0 30px ${glowColors[glowColor]}` : undefined
        }}
        {...props}
      >
        {/* Top Edge Highlight - The "Premium" Detail */}
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-white/20 to-transparent" />
        
        {/* Bottom Edge Glow */}
        <div className="absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-white/10 to-transparent" />
        
        {/* Corner Accents */}
        <div className="absolute top-0 left-0 w-8 h-8 border-l-2 border-t-2 border-white/5 rounded-tl-[2rem]" />
        <div className="absolute top-0 right-0 w-8 h-8 border-r-2 border-t-2 border-white/5 rounded-tr-[2rem]" />
        
        {children}
      </div>
    );
  }
);

SovereignCard.displayName = 'SovereignCard';
