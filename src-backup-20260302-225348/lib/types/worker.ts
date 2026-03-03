// 🏛️ The Hive Constitution
export interface SwarmMessage {
  from: string;
  to: string;
  task: string;
  context: any;
  priority: 'low' | 'medium' | 'high';
  replyTo?: string;
}

export interface WorkerCapability {
  name: string;
  actions: string[];
  endpoint: string;
  status: 'idle' | 'busy' | 'offline';
}

export interface WorkerResponse {
  status: 'success' | 'error';
  action: string;
  output?: any;
  error?: string;
  worker: string;
}
