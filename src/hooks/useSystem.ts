// src/hooks/useSystem.ts
import { useState, useEffect } from 'react';

export interface SystemStats {
  cpu?: { percent: number };
  memory?: { percent: number };
  disk?: { percent: number };
  gpu?: { load: number; name?: string; temp?: number };
}

export function useSystem(intervalMs = 2000) {
  const [stats, setStats] = useState<SystemStats>({});
  const [isLive, setIsLive] = useState(false);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const res = await fetch('/api/system/snapshot');
        if (!res.ok) throw new Error('Failed to fetch');
        const data = await res.json();
        
        if (data.success) {
          setStats({
            cpu: { percent: data.cpu?.percent || 0 },
            memory: { percent: data.memory?.percent || 0 },
            disk: { percent: data.disk?.percent || 0 },
            gpu: data.gpu ? {
              load: data.gpu.load || 0,
              name: data.gpu.name,
              temp: data.gpu.temp
            } : { load: 0 }
          });
          setIsLive(true);
        }
      } catch (error) {
        console.error('System stats fetch failed:', error);
        setIsLive(false);
      }
    };

    fetchStats();
    const interval = setInterval(fetchStats, intervalMs);
    return () => clearInterval(interval);
  }, [intervalMs]);

  return { stats, isLive };
}
