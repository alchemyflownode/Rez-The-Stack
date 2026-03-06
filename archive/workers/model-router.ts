// src/workers/model-router.ts
export class ModelRouter {
  private models: Map<string, any> = new Map();
  private usageStats: Map<string, { count: number, avgLatency: number }> = new Map();
  
  constructor() {
    this.initializeModels();
  }
  
  private initializeModels() {
    // Define your models with capabilities
    this.models.set('qwen2.5-coder:14b', {
      name: 'qwen2.5-coder:14b',
      capabilities: { coding: 10, reasoning: 8 }
    });
    
    this.models.set('gpt-oss:20b', {
      name: 'gpt-oss:20b',
      capabilities: { coding: 8, reasoning: 10 }
    });
    
    this.models.set('phi3.5:3.8b', {
      name: 'phi3.5:3.8b',
      capabilities: { coding: 6, reasoning: 6, fast: true }
    });
  }
  
  async recommendModel(task: string): Promise<string> {
    const taskLower = task.toLowerCase();
    
    // Simple logic - can be expanded
    if (taskLower.includes('code') || taskLower.includes('function') || 
        taskLower.includes('react') || taskLower.includes('component')) {
      return 'qwen2.5-coder:14b';
    }
    
    if (taskLower.includes('explain') || taskLower.includes('why') || 
        taskLower.includes('complex')) {
      return 'gpt-oss:20b';
    }
    
    // Default to fast model for simple queries
    if (task.length < 50) {
      return 'phi3.5:3.8b';
    }
    
    return 'phi3.5:3.8b';
  }
  
  recordUsage(model: string, latency: number, success: boolean) {
    const stats = this.usageStats.get(model) || { count: 0, avgLatency: 0 };
    stats.count++;
    stats.avgLatency = (stats.avgLatency * (stats.count - 1) + latency) / stats.count;
    this.usageStats.set(model, stats);
  }
  
  getStats() {
    const stats = [];
    for (const [name, model] of this.models) {
      const usage = this.usageStats.get(name) || { count: 0, avgLatency: 0 };
      stats.push({
        model: name,
        usageCount: usage.count,
        avgLatency: usage.avgLatency.toFixed(0) + 'ms',
        ...model
      });
    }
    return stats;
  }
}