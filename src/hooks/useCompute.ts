// src/hooks/useCompute.ts
import { useState, useEffect } from 'react';

interface HardwareState {
  vram_free: number;
  vram_used: number;
  gpu_load: number;
  ram_available: number;
  cpu_percent: number;
}

interface ModelSpec {
  name: string;
  vram_gb: number;
  tokens_per_sec: number;
}

interface ExecutionResult {
  response: string;
  model_used: string;
  model_specs: ModelSpec;
  hardware: HardwareState;
  classification: any;
  loaded_models: string[];
}

export function useCompute() {
  const [hardware, setHardware] = useState<HardwareState | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [lastResult, setLastResult] = useState<ExecutionResult | null>(null);

  // Poll hardware state every 2 seconds
  useEffect(() => {
    const fetchHardware = async () => {
      try {
        const res = await fetch('/api/compute/hardware');
        const data = await res.json();
        setHardware(data);
      } catch (error) {
        console.error('Failed to fetch hardware state:', error);
      }
    };

    fetchHardware();
    const interval = setInterval(fetchHardware, 2000);
    return () => clearInterval(interval);
  }, []);

  const execute = async (task: string): Promise<ExecutionResult> => {
    setIsProcessing(true);
    try {
      const res = await fetch('/api/compute/execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task })
      });
      const result = await res.json();
      setLastResult(result);
      return result;
    } finally {
      setIsProcessing(false);
    }
  };

  return {
    hardware,
    isProcessing,
    lastResult,
    execute,
    vramFree: hardware?.vram_free || 0,
    vramUsed: hardware?.vram_used || 0,
    gpuLoad: hardware?.gpu_load || 0
  };
}