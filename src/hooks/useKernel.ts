import { useState, useCallback } from 'react';
import { KernelService } from '@/services/kernel.service';

// Zero Drift State Interface
export interface ZeroDriftState {
  intent: number;
  clarity: number;
  load: number;
  entropy: number;
}

export function useKernel() {
  const [isProcessing, setIsProcessing] = useState(false);
  const [lastResponse, setLastResponse] = useState<any>(null);
  const [driftState, setDriftState] = useState<ZeroDriftState>({
    intent: 0.8,
    clarity: 0.9,
    load: 0.1,
    entropy: 0.05
  });

  // Calculate Zero Drift State from Real Stats
  const updateDrift = (cpu: number, ram: number) => {
    const load = (cpu + ram) / 200; // Average of CPU/RAM
    const entropy = Math.abs(cpu - ram) / 100; // Variance is Entropy
    const clarity = 1 - entropy;
    const intent = isProcessing ? 1.0 : 0.8; // High intent if processing
    
    setDriftState({ intent, clarity, load, entropy });
  };

  const execute = useCallback(async (task: string) => {
    setIsProcessing(true);
    const result = await KernelService.getInstance().execute(task);
    setLastResponse(result);
    setIsProcessing(false);
    return result;
  }, []);

  return { 
    execute, 
    isProcessing, 
    lastResponse,
    driftState,
    updateDrift // Expose updater to UI
  };
}
