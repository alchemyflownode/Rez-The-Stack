// 🦊 guardian.worker.ts — Runs analysis off-main-thread
// No UI jank. Zero cloud calls. Pure sovereignty.

import { GuardianAnalyzer, GuardianViolation, GuardianConfig } from './GuardianAnalyzer';

self.onmessage = async (event: MessageEvent<{ 
  type: 'analyze'; 
  sourceCode: string; 
  filePath: string; 
  config: GuardianConfig 
}>) => {
  if (event.data.type !== 'analyze') return;

  const { sourceCode, filePath, config } = event.data;
  
  try {
    const analyzer = new GuardianAnalyzer(config);
    const violations = analyzer.analyze(sourceCode, filePath);
    
    self.postMessage({
      type: 'analysis-complete',
      filePath,
      violations,
      timestamp: Date.now()
    });
  } catch (error) {
    self.postMessage({
      type: 'analysis-error',
      filePath,
      error: error.message,
      timestamp: Date.now()
    });
  }
};
