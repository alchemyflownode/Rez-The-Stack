'use client';

import React from 'react';
import { Input } from '@/components/ui/input';
import { Search, LayoutDashboard } from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

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
  const pathname = usePathname();

  return (
    <header className="flex flex-col gap-4 p-4 glass-panel rounded-xl">
      <div className="flex items-center gap-4 flex-wrap">
        {/* Dashboard Link */}
        <Link
  href="/rez-dashboard"
  className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-all font-medium ${
    pathname === '/rez-dashboard'
      ? 'bg-purple-600 text-white shadow-lg shadow-purple-600/30'
      : 'bg-purple-500/20 text-purple-400 border border-purple-500/30 hover:bg-purple-500/30 hover:shadow-md hover:shadow-purple-500/20'
  }`}
>
  <LayoutDashboard className="w-4 h-4" />
  <span>Dashboard</span>
</Link>

        {/* Search */}
        <div className="flex-1 min-w-[200px] relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            type="text"
            placeholder="Search commands..."
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            className="pl-9 bg-black/40 border-purple-500/30 focus:ring-purple-500/50"
          />
        </div>

        {/* Category Filters */}
        <div className="flex gap-1">
          {categories.map((category) => (
            <button
              key={category}
              onClick={() => onCategoryChange(category)}
              className={`px-3 py-1.5 text-sm rounded-lg transition-all ${
                categoryFilter === category
                  ? 'bg-purple-500/20 text-purple-400 border border-purple-500/30'
                  : 'text-muted-foreground hover:text-foreground hover:bg-white/5'
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

