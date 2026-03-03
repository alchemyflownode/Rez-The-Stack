// src/hooks/useApps.ts
import { useState, useEffect } from 'react';

export interface AppButton {
  id: string;
  name: string;
  icon: string;
  command: string;
}

const DEFAULT_APPS: AppButton[] = [
  { id: '1', name: 'Chrome', icon: 'Chrome', command: 'Open Chrome' },
  { id: '2', name: 'Notepad', icon: 'FileEdit', command: 'Open Notepad' },
  { id: '3', name: 'Calc', icon: 'Calculator', command: 'Open Calc' },
  { id: '4', name: 'Code', icon: 'Code', command: 'Open Code' },
  { id: '5', name: 'Spotify', icon: 'Music', command: 'Open Spotify' },
  { id: '6', name: 'Discord', icon: 'MessageCircle', command: 'Open Discord' }
];

export function useApps() {
  const [apps, setApps] = useState<AppButton[]>([]);

  useEffect(() => {
    const saved = localStorage.getItem('sovereign_apps');
    setApps(saved ? JSON.parse(saved) : DEFAULT_APPS);
  }, []);

  const removeApp = (id: string) => {
    const updated = apps.filter(a => a.id !== id);
    setApps(updated);
    localStorage.setItem('sovereign_apps', JSON.stringify(updated));
  };

  return { apps, removeApp };
}
