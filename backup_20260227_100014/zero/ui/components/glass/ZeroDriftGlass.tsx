'use client';
import { cn } from '@/lib/utils';
import { forwardRef, HTMLAttributes } from 'react';

interface ZeroDriftGlassProps extends HTMLAttributes<HTMLDivElement> {
  intensity?: 'ultra-thin' | 'thin' | 'medium' | 'heavy';
  border?: boolean;
  glow?: 'cyan' | 'amber' | 'none';
  radius?: 'none' | 'sm' | 'md' | 'lg' | 'xl' | 'full';
  hover?: boolean;
}

export const ZeroDriftGlass = forwardRef<HTMLDivElement, ZeroDriftGlassProps>(
  ({ className, intensity = 'medium', border = true, glow = 'none', radius = 'md', hover = true, children, ...props }, ref) => {
    const intensityMap = {
      'ultra-thin': 'bg-[rgba(18,18,20,0.3)] backdrop-blur-sm',
      'thin': 'bg-[rgba(18,18,20,0.5)] backdrop-blur-md',
      'medium': 'bg-[rgba(18,18,20,0.7)] backdrop-blur-lg',
      'heavy': 'bg-[rgba(18,18,20,0.9)] backdrop-blur-xl'
    };

    const glowMap = {
      'cyan': 'shadow-[0_0_30px_rgba(0,255,194,0.2)]',
      'amber': 'shadow-[0_0_30px_rgba(255,184,0,0.15)]',
      'none': ''
    };

    const radiusMap = {
      'none': 'rounded-none',
      'sm': 'rounded-[2px]',
      'md': 'rounded-[4px]',
      'lg': 'rounded-[8px]',
      'xl': 'rounded-[12px]',
      'full': 'rounded-[9999px]'
    };

    return (
      <div
        ref={ref}
        className={cn(
          'relative overflow-hidden transition-all duration-400',
          intensityMap[intensity],
          border && 'border border-white/5',
          radiusMap[radius],
          glowMap[glow],
          hover && 'hover:bg-white/5 hover:-translate-y-0.5',
          className
        )}
        {...props}
      >
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-white/20 to-transparent pointer-events-none" />
        <div className="absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-white/5 to-transparent pointer-events-none" />
        <div className="absolute top-0 left-0 w-4 h-4 border-l border-t border-white/10 pointer-events-none" />
        <div className="absolute top-0 right-0 w-4 h-4 border-r border-t border-white/10 pointer-events-none" />
        {children}
      </div>
    );
  }
);

ZeroDriftGlass.displayName = 'ZeroDriftGlass';
