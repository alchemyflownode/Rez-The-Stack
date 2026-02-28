export interface AgenticState {
  intent: number;
  cognitiveLoad: number;
  engagement: number;
  emotionalTone: 'calm' | 'focused' | 'exploratory' | 'frustrated';
  driftRate?: number;
  entropy?: number;
}

export interface RezonicProof {
  hash: string;
  timestamp: string;
  assertion: 'ui_valid' | 'state_coherent' | 'audit_passed';
  strength: number;
}

export interface SovereignAudit {
  proofHashId: string;
  compatibilityThreshold: number;
  auditHooks: string[];
  lastVerified: string;
  preflightPassed: boolean;
}
