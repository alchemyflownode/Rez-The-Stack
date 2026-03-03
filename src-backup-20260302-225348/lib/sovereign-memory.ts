// src/lib/sovereign-memory.ts

export interface MemoryEntry {
  id: string;
  timestamp: number;
  role: 'user' | 'assistant';
  content: string;
}

class SovereignMemoryCore {
  private STORAGE_KEY = 'rez-hive-memory-v1';
  private entries: MemoryEntry[] = [];

  constructor() {
    // SAFE CHECK: Only load if window exists
    if (typeof window !== 'undefined') {
      this.load();
    }
  }

  private load() {
    try {
      const data = localStorage.getItem(this.STORAGE_KEY);
      if (data) this.entries = JSON.parse(data);
    } catch (e) {
      console.error("Memory load failed", e);
    }
  }

  private save() {
    if (typeof window === 'undefined') return;
    try {
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(this.entries));
    } catch (e) {
      console.error("Memory save failed", e);
    }
  }

  add(content: string, role: 'user' | 'assistant') {
    const entry: MemoryEntry = {
      id: Date.now().toString(),
      timestamp: Date.now(),
      role,
      content
    };
    this.entries.unshift(entry);
    if (this.entries.length > 50) this.entries.pop();
    this.save();
    return entry;
  }

  getRecent(count: number = 10) {
    return this.entries.slice(0, count);
  }
}

// Export Singleton
export const SovereignMemory = new SovereignMemoryCore();
