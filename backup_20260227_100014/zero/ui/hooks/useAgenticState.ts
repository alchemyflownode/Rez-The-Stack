import { useState, useEffect } from 'react';
import { AgenticState } from '../../types/agentic';

export const generateProof = (state: AgenticState): string => {
  const rawValue = Math.abs(
    state.intent * 10000 + 
    state.cognitiveLoad * 1000 + 
    state.engagement * 100 +
    Date.now() % 1000
  );
  const hash = Math.floor(rawValue).toString(16).toUpperCase().slice(0, 8);
  return `0x${hash}_REZNIC`;
};

export const useAgenticState = () => {
  const [state, setState] = useState<AgenticState>({
    intent: 0.5,
    cognitiveLoad: 0.3,
    engagement: 0.7,
    emotionalTone: 'calm'
  });
  
  const [proof, setProof] = useState('0x7A3F_REZNIC');
  const [entropy, setEntropy] = useState(0.42);

  useEffect(() => {
    const fetchTelemetry = async () => {
      try {
        const res = await fetch('/api/system/snapshot');
        const data = await res.json();
        setState(prev => ({
          ...prev,
          cognitiveLoad: (data.cpu?.percent || 30) / 100,
          engagement: (data.gpu?.load || 50) / 100,
          emotionalTone: data.cpu?.percent > 70 ? 'focused' : 'calm'
        }));
        setEntropy(prev => prev + (Math.random() - 0.5) * 0.1);
      } catch (error) {
        console.error('Failed to fetch telemetry');
      }
    };

    fetchTelemetry();
    const interval = setInterval(fetchTelemetry, 2000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    setProof(generateProof(state));
  }, [state]);

  const updateState = (updates: Partial<AgenticState>) => {
    setState(prev => ({ ...prev, ...updates }));
  };

  return { state, proof, entropy, updateState };
};
