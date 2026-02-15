'use client';

import React from 'react';
import { Input } from '@/components/ui/input';
import { Search } from 'lucide-react';

export type CategoryFilter = 'ALL' | 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED';

interface SovereignHeaderProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  categoryFilter: CategoryFilter;
  onCategoryChange: (category: CategoryFilter) => void;
}

const categories: CategoryFilter[] = ['ALL', 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'];

export function SovereignHeader({
  searchQuery,
  onSearchChange,
  categoryFilter,
  onCategoryChange,
}: SovereignHeaderProps) {
  return (
    <header className="flex flex-col gap-4 p-4 glass-panel rounded-xl">
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
  );
}
