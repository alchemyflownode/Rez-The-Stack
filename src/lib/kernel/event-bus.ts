import { useState, useEffect } from 'react';
// src/lib/kernel/event-bus.ts
// ================================================================
// SOVEREIGN NEURAL EVENT BUS v2026
// Real-time communication layer between workers and UI
// ================================================================

export type WorkerType = 
  | 'vision' | 'deepsearch' | 'mutation' | 'code' | 'app' 
  | 'file' | 'voice' | 'system_monitor' | 'architect' | 'discover'
  | 'heal' | 'learn' | 'autonomous' | 'director' | 'sce' | 'canvas'
  | 'mcp' | 'rezstack' | 'governor' | 'heartbeat';

export type EventPriority = 'low' | 'medium' | 'high' | 'critical';

export interface WorkerEvent {
  id: string;
  worker: WorkerType;
  type: 'start' | 'progress' | 'complete' | 'error' | 'status';
  timestamp: number;
  data?: any;
  priority: EventPriority;
  duration?: number;
  metadata?: {
    workerName: string;
    cpuUsage?: number;
    memoryUsage?: number;
    vramUsage?: number;
  };
}

export interface EventSubscriber {
  id: string;
  filter?: (event: WorkerEvent) => boolean;
  callback: (event: WorkerEvent) => void;
}

class NeuralEventBus {
  private static instance: NeuralEventBus;
  private subscribers: Map<string, EventSubscriber> = new Map();
  private eventHistory: WorkerEvent[] = [];
  private maxHistorySize = 100;
  private workerStatus: Map<WorkerType, { lastEvent: WorkerEvent; active: boolean }> = new Map();

  private constructor() {
    // Start heartbeat monitor
    this.startHeartbeat();
  }

  static getInstance(): NeuralEventBus {
    if (!NeuralEventBus.instance) {
      NeuralEventBus.instance = new NeuralEventBus();
    }
    return NeuralEventBus.instance;
  }

  // Emit an event from any worker
  emit(event: Omit<WorkerEvent, 'id' | 'timestamp'>) {
    const fullEvent: WorkerEvent = {
      ...event,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
    };

    // Store in history
    this.eventHistory.unshift(fullEvent);
    if (this.eventHistory.length > this.maxHistorySize) {
      this.eventHistory.pop();
    }

    // Update worker status
    this.workerStatus.set(event.worker, {
      lastEvent: fullEvent,
      active: event.type !== 'error' && event.type !== 'complete'
    });

    // Notify subscribers
    this.subscribers.forEach((subscriber) => {
      if (!subscriber.filter || subscriber.filter(fullEvent)) {
        try {
          subscriber.callback(fullEvent);
        } catch (error) {
          console.error('Event subscriber error:', error);
        }
      }
    });

    // Log critical events
    if (event.priority === 'critical') {
      console.log(`?? CRITICAL: ${event.worker} - ${event.type}`, event.data);
    }

    return fullEvent;
  }

  // Subscribe to events
  subscribe(
    callback: (event: WorkerEvent) => void,
    filter?: (event: WorkerEvent) => boolean
  ): string {
    const id = crypto.randomUUID();
    this.subscribers.set(id, { id, callback, filter });
    return id;
  }

  // Unsubscribe
  unsubscribe(id: string) {
    this.subscribers.delete(id);
  }

  // Get event history
  getHistory(options?: { 
    worker?: WorkerType; 
    limit?: number;
    since?: number;
  }): WorkerEvent[] {
    let filtered = this.eventHistory;
    
    if (options?.worker) {
      filtered = filtered.filter(e => e.worker === options.worker);
    }
    
    if (options?.since) {
      filtered = filtered.filter(e => e.timestamp > options.since!);
    }
    
    return filtered.slice(0, options?.limit || 50);
  }

  // Get worker status
  getWorkerStatus(worker: WorkerType) {
    return this.workerStatus.get(worker) || { active: false };
  }

  // Get all active workers
  getActiveWorkers(): WorkerType[] {
    const active: WorkerType[] = [];
    this.workerStatus.forEach((status, worker) => {
      if (status.active) active.push(worker);
    });
    return active;
  }

  // Start heartbeat to monitor system health
  private heartbeatIntervalId: NodeJS.Timeout | null = null;`n`n  private startHeartbeat() {
    this.heartbeatIntervalId = setInterval(() => {
      this.emit({
        worker: 'heartbeat',
        type: 'status',
        priority: 'low',
        data: {
          activeWorkers: this.getActiveWorkers().length,
          eventQueue: this.subscribers.size,
          timestamp: Date.now()
        }
      });
    }, 5000);
  }

  // Clear old events
  clearHistory() {
    this.eventHistory = [];
  }
}

export const neuralBus = NeuralEventBus.getInstance();

// React hook for using the event bus
export function useNeuralBus() {
  const [events, setEvents] = useState<WorkerEvent[]>([]);
  const [activeWorkers, setActiveWorkers] = useState<WorkerType[]>([]);

  useEffect(() => {
    // Subscribe to all events
    const id = neuralBus.subscribe((event) => {
      setEvents(prev => [event, ...prev].slice(0, 50));
      setActiveWorkers(neuralBus.getActiveWorkers());
    });

    // Initial active workers
    setActiveWorkers(neuralBus.getActiveWorkers());

    return () => neuralBus.unsubscribe(id);
  }, []);

  return { events, activeWorkers };

  public stopHeartbeat() {
    if (this.heartbeatIntervalId) {
      clearInterval(this.heartbeatIntervalId);
      this.heartbeatIntervalId = null;
    }
  }}

