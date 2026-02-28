// src/lib/workers/workerRegistry.ts
// Complete registry of all 28 workers

export interface Worker {
  id: string;
  name: string;
  category: 'python' | 'api' | 'system' | 'ai';
  description: string;
  endpoint: string;
  icon?: string;
  status: 'active' | 'idle' | 'error';
  lastUsed?: Date;
  usageCount?: number;
}

export const workerRegistry: Worker[] = [
  // Python Workers (15)
  { id: 'system-monitor', name: 'System Monitor', category: 'python', 
    description: 'Monitor CPU, RAM, GPU, disk usage', endpoint: '/api/workers/system_monitor', status: 'active' },
  { id: 'deep-search', name: 'Deep Search', category: 'python', 
    description: 'Web search and synthesis', endpoint: '/api/workers/deepsearch', status: 'active' },
  { id: 'mutation', name: 'Code Mutation', category: 'python', 
    description: 'Code analysis and improvement', endpoint: '/api/workers/mutation', status: 'active' },
  { id: 'vision', name: 'Vision Analysis', category: 'python', 
    description: 'Image and screen analysis', endpoint: '/api/workers/vision', status: 'active' },
  { id: 'app-launcher', name: 'App Launcher', category: 'python', 
    description: 'Launch applications', endpoint: '/api/workers/app', status: 'active' },
  { id: 'code-worker', name: 'Code Worker', category: 'python', 
    description: 'Code generation and execution', endpoint: '/api/workers/code', status: 'active' },
  { id: 'voice', name: 'Voice Processing', category: 'python', 
    description: 'Speech recognition and synthesis', endpoint: '/api/workers/voice', status: 'active' },
  { id: 'canvas', name: 'Canvas Generator', category: 'python', 
    description: 'Image generation', endpoint: '/api/workers/canvas', status: 'active' },
  { id: 'file-worker', name: 'File Operations', category: 'python', 
    description: 'File system operations', endpoint: '/api/workers/file', status: 'active' },
  { id: 'rezstack', name: 'RezStack', category: 'python', 
    description: 'Stack operations', endpoint: '/api/workers/rezstack', status: 'active' },
  { id: 'mcp', name: 'MCP Server', category: 'python', 
    description: 'Model Context Protocol', endpoint: '/api/workers/mcp', status: 'active' },
  { id: 'director', name: 'Director', category: 'python', 
    description: 'SCE compilation', endpoint: '/api/workers/director', status: 'active' },
  { id: 'sce', name: 'SCE Engine', category: 'python', 
    description: 'Sovereign Component Exchange', endpoint: '/api/workers/sce', status: 'active' },
  { id: 'harvester', name: 'Harvester', category: 'python', 
    description: 'Data harvesting', endpoint: '/api/workers/harvester', status: 'active' },
  { id: 'guardian', name: 'Guardian', category: 'python', 
    description: 'System protection', endpoint: '/api/workers/guardian', status: 'active' },

  // API Workers (13)
  { id: 'architect', name: 'Architect', category: 'api', 
    description: 'Framework architecture', endpoint: '/api/architect', status: 'active' },
  { id: 'discover', name: 'Discovery', category: 'api', 
    description: 'Root discovery', endpoint: '/api/discover', status: 'active' },
  { id: 'domains', name: 'Domains', category: 'api', 
    description: 'Domain management', endpoint: '/api/domains', status: 'active' },
  { id: 'generate', name: 'Generate', category: 'api', 
    description: 'Code generation', endpoint: '/api/generate', status: 'active' },
  { id: 'heal', name: 'Heal', category: 'api', 
    description: 'Self-healing', endpoint: '/api/heal', status: 'active' },
  { id: 'learn', name: 'Learn', category: 'api', 
    description: 'Pattern learning', endpoint: '/api/learn', status: 'active' },
  { id: 'autonomous', name: 'Autonomous', category: 'api', 
    description: 'Autonomous execution', endpoint: '/api/autonomous', status: 'active' },
  { id: 'heartbeat', name: 'Heartbeat', category: 'api', 
    description: 'System monitoring', endpoint: '/api/heartbeat', status: 'active' },
  { id: 'governor', name: 'Governor', category: 'api', 
    description: 'Constitutional checks', endpoint: '/api/governor-test', status: 'active' },
  { id: 'compute-hw', name: 'Compute Hardware', category: 'api', 
    description: 'Hardware monitoring', endpoint: '/api/compute/hardware', status: 'active' },
  { id: 'compute-exec', name: 'Compute Execute', category: 'api', 
    description: 'Compute execution', endpoint: '/api/compute/execute', status: 'active' },
  { id: 'frontend-workers', name: 'Frontend Workers', category: 'api', 
    description: 'Worker listing', endpoint: '/api/frontend/workers', status: 'active' },
  { id: 'system-snapshot', name: 'System Snapshot', category: 'api', 
    description: 'System state', endpoint: '/api/system/snapshot', status: 'active' },
];

export const getWorker = (id: string) => workerRegistry.find(w => w.id === id);
export const getWorkersByCategory = (category: string) => workerRegistry.filter(w => w.category === category);
