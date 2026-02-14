import React from 'react';
import { motion, PanInfo } from 'framer-motion';

interface SplitterProps {
  axis: 'horizontal' | 'vertical';
  onDrag: (delta: number) => void;
  onDragStart?: () => void;
  onDragEnd?: () => void;
  className?: string;
  size?: 'sm' | 'md' | 'lg';
  glowIntensity?: 'low' | 'medium' | 'high';
}

const Splitter: React.FC<SplitterProps> = ({ 
  axis, 
  onDrag, 
  onDragStart, 
  onDragEnd,
  className = '',
  size = 'md',
  glowIntensity = 'medium'
}) => {
  // Size mappings for padding
  const sizeMap = {
    sm: axis === 'vertical' ? 'px-1' : 'py-1',
    md: axis === 'vertical' ? 'px-2' : 'py-2',
    lg: axis === 'vertical' ? 'px-3' : 'py-3',
  };

  // Margin offset for visual alignment
  const marginMap = {
    sm: axis === 'vertical' ? '-mx-1' : '-my-1',
    md: axis === 'vertical' ? '-mx-2' : '-my-2',
    lg: axis === 'vertical' ? '-mx-3' : '-my-3',
  };

  // Glow intensity mapping
  const glowMap = {
    low: 'shadow-glow-purple-low',
    medium: 'shadow-glow-purple',
    high: 'shadow-glow-purple-intense'
  };

  return (
    <motion.div
      className={`
        splitter 
        ${axis} 
        ${sizeMap[size]} 
        ${marginMap[size]} 
        ${className}
        relative
        cursor-${axis === 'vertical' ? 'col-resize' : 'row-resize'}
        select-none
        group
        z-10
      `}
      drag={axis === 'vertical' ? 'x' : 'y'}
      dragConstraints={{ left: 0, right: 0, top: 0, bottom: 0 }}
      dragElastic={0.05}
      dragTransition={{ 
        power: 0.1, 
        timeConstant: 200,
        modifyTarget: target => Math.round(target)
      }}
      onDragStart={onDragStart}
      onDragEnd={onDragEnd}
      onDrag={(event, info: PanInfo) => 
        onDrag(axis === 'vertical' ? info.delta.x : info.delta.y)
      }
      whileDrag={{
        scale: axis === 'vertical' ? 1.02 : 1.02,
        transition: { duration: 0.1 }
      }}
    >
      <div 
        className={`
          splitter-handle 
          ${axis === 'vertical' ? 'w-1.5 h-full' : 'h-1.5 w-full'}
          bg-gradient-to-r from-purple-500/40 via-cyan-500/40 to-purple-500/40
          hover:from-purple-500/60 hover:via-cyan-500/60 hover:to-purple-500/60
          active:from-purple-500/80 active:via-cyan-500/80 active:to-purple-500/80
          rounded-full
          transition-all
          duration-200
          mx-auto
          ${glowMap[glowIntensity]}
          group-hover:scale-105
        `}
      />
      
      {/* Center indicator dot for better visibility */}
      <div className={`
        absolute 
        ${axis === 'vertical' ? 'top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2' : 'top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2'}
        w-1 h-1 
        bg-cyan-400 
        rounded-full 
        opacity-0 
        group-hover:opacity-100
        transition-opacity
        duration-200
        shadow-glow-cyan
      `} />
    </motion.div>
  );
};

export default React.memo(Splitter);

