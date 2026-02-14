'use client';
import React, { useState, useRef, useEffect } from 'react';

interface ResizableLayoutProps {
  left: React.ReactNode;
  right: React.ReactNode;
  defaultLeftWidth?: number;
  minLeftWidth?: number;
  maxLeftWidth?: number;
}

export default function ResizableLayout({ 
  left, 
  right, 
  defaultLeftWidth = 25, 
  minLeftWidth = 15, 
  maxLeftWidth = 50 
}: ResizableLayoutProps) {
  const [leftWidth, setLeftWidth] = useState(defaultLeftWidth);
  const [isResizing, setIsResizing] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!isResizing || !containerRef.current) return;
      const containerRect = containerRef.current.getBoundingClientRect();
      const newWidth = ((e.clientX - containerRect.left) / containerRect.width) * 100;
      setLeftWidth(Math.min(Math.max(newWidth, minLeftWidth), maxLeftWidth));
    };
    
    const handleMouseUp = () => setIsResizing(false);
    
    if (isResizing) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);
    }
    
    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isResizing, minLeftWidth, maxLeftWidth]);

  return (
    <div ref={containerRef} className="flex h-full w-full">
      <div 
        className="h-full overflow-auto border-r border-purple-500/20" 
        style={{ width: leftWidth + '%' }}
      >
        {left}
      </div>
      
      <div 
        className="w-1 bg-purple-500/20 hover:bg-purple-500/40 cursor-col-resize transition-colors flex-shrink-0" 
        onMouseDown={() => setIsResizing(true)} 
      />
      
      <div className="flex-1 h-full overflow-auto">
        {right}
      </div>
    </div>
  );
}
