'use client';

import { useState } from 'react';
import Link from 'next/link';
import { LayoutDashboard } from 'lucide-react';
import SovereignDashboard from '@/components/SovereignDashboard';

export default function Home() {
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<'ALL' | 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED'>('ALL');

  return (
    <main className="relative">
      {/* Floating Dashboard Button */}
      <Link
        href="/rez-dashboard"
        className="fixed top-20 right-6 z-50 flex items-center gap-2 px-4 py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-lg shadow-lg shadow-purple-600/30 transition-all hover:scale-105"
      >
        <LayoutDashboard className="w-5 h-5" />
        <span className="font-medium">Dashboard</span>
      </Link>

      <SovereignDashboard 
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        categoryFilter={categoryFilter}
        onCategoryChange={setCategoryFilter}
      />
    </main>
  );
}
