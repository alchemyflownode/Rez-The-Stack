// 🦊 useGuardian.ts — Real-time constitutional enforcement
// Integrates with Monaco Editor / textarea

import { useState, useEffect, useCallback, useRef } from 'react';
import type { GuardianViolation, GuardianConfig } from '@/guardian/GuardianAnalyzer';

export interface GuardianResult {
  violations: GuardianViolation[];
  isAnalyzing: boolean;
  lastAnalyzed: number;
}

export function useGuardian(config: GuardianConfig) {
  const [results, setResults] = useState<GuardianResult>({
    violations: [],
    isAnalyzing: false,
    lastAnalyzed: 0
  });

  const workerRef = useRef<Worker | null>(null);
  const debounceRef = useRef<NodeJS.Timeout | null>(null);

  // Initialize Web Worker
  useEffect(() => {
    if (!workerRef.current) {
      workerRef.current = new Worker(new URL('./guardian.worker.ts', import.meta.url), {
        type: 'module'
      });

      workerRef.current.onmessage = (event) => {
        if (event.data.type === 'analysis-complete') {
          setResults(prev => ({
            violations: event.data.violations,
            isAnalyzing: false,
            lastAnalyzed: event.data.timestamp
          }));
        }
      };
    }

    return () => {
      if (workerRef.current) {
        workerRef.current.terminate();
        workerRef.current = null;
      }
      if (debounceRef.current) {
        clearTimeout(debounceRef.current);
      }
    };
  }, []);

  // Analyze code with debounce
  const analyze = useCallback((sourceCode: string, filePath: string) => {
    if (!workerRef.current) return;

    setResults(prev => ({ ...prev, isAnalyzing: true }));

    if (debounceRef.current) {
      clearTimeout(debounceRef.current);
    }

    debounceRef.current = setTimeout(() => {
      workerRef.current?.postMessage({
        type: 'analyze',
        sourceCode,
        filePath,
        config
      });
    }, 300); // 300ms debounce for typing

  }, [config]);

  return {
    ...results,
    analyze,
    clear: useCallback(() => setResults({ violations: [], isAnalyzing: false, lastAnalyzed: 0 }), [])
  };
}
