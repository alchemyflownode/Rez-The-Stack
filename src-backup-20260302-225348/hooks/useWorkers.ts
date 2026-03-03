// src/hooks/useWorkers.ts
import { useState, useEffect, useCallback } from 'react';
import { workerRegistry, Worker, getWorkersByCategory } from '@/lib/workers/workerRegistry';

export function useWorkers() {
  const [workers, setWorkers] = useState<Worker[]>([]);
  const [selectedWorker, setSelectedWorker] = useState<Worker | null>(null);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [workerStats, setWorkerStats] = useState<Record<string, { lastUsed: Date; usageCount: number }>>({});

  useEffect(() => {
    // Load workers from registry
    setWorkers(workerRegistry);
    
    // Load usage stats from localStorage
    const stats = localStorage.getItem('worker-stats');
    if (stats) {
      setWorkerStats(JSON.parse(stats));
    }
  }, []);

  const updateWorkerStats = useCallback((workerId: string) => {
    setWorkerStats(prev => {
      const newStats = {
        ...prev,
        [workerId]: {
          lastUsed: new Date(),
          usageCount: (prev[workerId]?.usageCount || 0) + 1
        }
      };
      localStorage.setItem('worker-stats', JSON.stringify(newStats));
      return newStats;
    });
  }, []);

  const executeWorker = useCallback(async (workerId: string, task: string) => {
    const worker = workerRegistry.find(w => w.id === workerId);
    if (!worker) throw new Error(`Worker ${workerId} not found`);

    setLoading(true);
    setSelectedWorker(worker);
    
    try {
      let response;
      
      if (worker.category === 'python') {
        // Python workers use POST
        response = await fetch(worker.endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ task })
        });
      } else {
        // API workers might use GET or POST
        response = await fetch(worker.endpoint);
      }
      
      const data = await response.json();
      setResult(data);
      updateWorkerStats(workerId);
      return data;
    } catch (error) {
      console.error(`Worker ${workerId} execution failed:`, error);
      setResult({ error: String(error) });
    } finally {
      setLoading(false);
    }
  }, [updateWorkerStats]);

  const getWorkersByType = useCallback((category: string) => {
    return workers.filter(w => w.category === category);
  }, [workers]);

  return {
    workers,
    selectedWorker,
    loading,
    result,
    workerStats,
    executeWorker,
    getWorkersByType,
    pythonWorkers: workers.filter(w => w.category === 'python'),
    apiWorkers: workers.filter(w => w.category === 'api'),
    systemWorkers: workers.filter(w => w.category === 'system'),
    aiWorkers: workers.filter(w => w.category === 'ai'),
  };
}
