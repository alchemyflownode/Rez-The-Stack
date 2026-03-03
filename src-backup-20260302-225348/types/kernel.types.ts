// src/types/kernel.types.ts

// The strict contract for all Sovereign responses
export type KernelResponseType = 
  | 'stats'      // System monitoring
  | 'search'     // Deep search results
  | 'code'       // Code generation/fixing
  | 'app'        // App launched
  | 'note'       // Note taken
  | 'task'       // Task created
  | 'error';     // Something failed

export interface KernelResponse {
  // Core
  id: string;
  type: KernelResponseType;
  status: 'success' | 'error' | 'pending';
  
  // Data payload
  data: any;
  
  // Execution context
  worker?: string;
  executionTimeMs: number;
  timestamp: string;
  
  // Governance (Ready for Constitution Layer)
  auditId?: string;
  permissionsUsed?: string[];
}

export interface SystemStats {
  cpu: { percent: number };
  memory: { percent: number };
  disk: { percent: number };
  gpu: { available: boolean; load?: number };
}
