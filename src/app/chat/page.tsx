'use client';

import React from 'react';
import { SovereignHeader } from '@/components/SovereignHeader';
import { EnhancedResizableLayout } from '@/components/EnhancedResizableLayout';  // ✅ named import (with braces)
import { CommandSidebar } from '@/components/CommandSidebar';
import JARVISTerminal from '@/components/JARVISTerminal';  // ✅ default import (no braces)

export default function ChatPage() {
  const [workspace, setWorkspace] = React.useState('');
  const [currentPath, setCurrentPath] = React.useState('.');
  const terminalRef = React.useRef<{ executeCommand: (cmd: string) => void }>(null);

  const handleWorkspaceChange = (path: string) => {
    setWorkspace(path);
    setCurrentPath('.');
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new CustomEvent('workspace:changed', { detail: { path } }));
    }
  };

  return (
    <div className="h-screen flex flex-col overflow-hidden bg-background">
      <SovereignHeader
        searchQuery=""
        onSearchChange={() => {}}
        categoryFilter="ALL"
        onCategoryChange={() => {}}
        workspace={workspace}
        onWorkspaceChange={handleWorkspaceChange}
      />
      
      <div className="flex-1 overflow-hidden">
        <EnhancedResizableLayout
          left={
            <div className="p-4">
              <CommandSidebar
                selectedCategory={null}
                onCategorySelect={() => {}}
                selectedDifficulty="ALL"
              />
            </div>
          }
          right={
            <div className="h-full p-4">
              <h1 className="text-2xl font-bold text-purple-400 mb-4">Chat</h1>
              <JARVISTerminal
                ref={terminalRef}
                workspace={workspace}
                currentPath={currentPath}
                onPathChange={setCurrentPath}
              />
            </div>
          }
          leftConfig={{ id: 'chat-sidebar', defaultSize: 20, minSize: 15, maxSize: 30 }}
        />
      </div>
    </div>
  );
}