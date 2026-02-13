'use client';

import React, { useState } from 'react';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Search, FolderOpen } from 'lucide-react';
import { WorkspaceModal } from './WorkspaceModal';

export type CategoryFilter = 'ALL' | 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED';

interface SovereignHeaderProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  categoryFilter: CategoryFilter;
  onCategoryChange: (category: CategoryFilter) => void;
  workspace: string;
  onWorkspaceChange: (path: string) => void;
}

const categories: CategoryFilter[] = ['ALL', 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'];

export function SovereignHeader({
  searchQuery,
  onSearchChange,
  categoryFilter,
  onCategoryChange,
  workspace,
  onWorkspaceChange,
}: SovereignHeaderProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <>
      <header className="flex flex-col gap-4 p-4 glass-panel rounded-xl">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="badge-cyan text-xs gap-1">
              <span className="w-1.5 h-1.5 bg-cyan-400 rounded-full animate-pulse" />
              NEURAL ENGINE ACTIVE
            </Badge>
            <Badge variant="outline" className="badge-purple text-xs">
              v3.5
            </Badge>
          </div>
          
          {/* Current Workspace + Button - Just like your sample */}
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-800/50 
                          border border-purple-500/30 rounded-lg">
              <span className="text-xs font-mono text-purple-400/70 truncate max-w-[200px]">
                {workspace.split('\\').pop() || 'Select workspace...'}
              </span>
            </div>
            <button
              onClick={() => setIsModalOpen(true)}
              className="px-4 py-1.5 bg-gradient-to-r from-purple-600 to-cyan-600 
                       hover:from-purple-700 hover:to-cyan-700 rounded-lg
                       text-xs font-medium text-white flex items-center gap-2
                       transition-all duration-200 shadow-lg shadow-purple-500/20"
            >
              <FolderOpen className="w-3.5 h-3.5" />
              Select Workspace
            </button>
          </div>
        </div>

        <div className="flex items-center gap-4 flex-wrap">
          {/* Search */}
          <div className="flex-1 min-w-[200px] relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search commands..."
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              className="pl-10 bg-input border-border input-glow transition-smooth"
            />
          </div>

          {/* Category Pills */}
          <div className="flex gap-2 flex-wrap">
            {categories.map((category) => (
              <button
                key={category}
                onClick={() => onCategoryChange(category)}
                className={`category-pill px-4 py-2 rounded-lg border text-sm font-medium transition-smooth ${
                  categoryFilter === category
                    ? 'active border-primary bg-primary/20 text-primary'
                    : 'border-border text-muted-foreground hover:border-primary/50 hover:text-foreground'
                }`}
              >
                {category}
              </button>
            ))}
          </div>
        </div>
      </header>

      {/* Workspace Modal */}
      <WorkspaceModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSelect={onWorkspaceChange}
        currentPath={workspace}
      />
    </>
  );
}