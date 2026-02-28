// src/lib/kernel/worker-middleware.ts
// ================================================================
// Automatically emits events from all API workers
// ================================================================

import { NextRequest, NextResponse } from 'next/server';
import { neuralBus, WorkerType } from './event-bus';

export interface WorkerContext {
  worker: WorkerType;
  startTime: number;
}

export function withWorkerTracking(
  handler: (req: NextRequest, context: WorkerContext) => Promise<NextResponse>,
  workerType: WorkerType
) {
  return async (req: NextRequest) => {
    const context: WorkerContext = {
      worker: workerType,
      startTime: Date.now()
    };

    try {
      // Emit start event
      neuralBus.emit({
        worker: workerType,
        type: 'start',
        priority: 'medium',
        data: { url: req.url, method: req.method }
      });

      // Execute handler
      const response = await handler(req, context);

      // Emit complete event
      neuralBus.emit({
        worker: workerType,
        type: 'complete',
        priority: 'low',
        duration: Date.now() - context.startTime,
        data: { 
          status: response.status,
          statusText: response.statusText
        }
      });

      return response;

    } catch (error: any) {
      // Emit error event
      neuralBus.emit({
        worker: workerType,
        type: 'error',
        priority: 'high',
        duration: Date.now() - context.startTime,
        data: { 
          error: error.message,
          stack: error.stack
        }
      });

      throw error;
    }
  };
}

// Progress tracking helper
export function emitProgress(
  worker: WorkerType,
  progress: number,
  message: string,
  metadata?: any
) {
  neuralBus.emit({
    worker,
    type: 'progress',
    priority: 'medium',
    data: {
      progress,
      message,
      ...metadata
    }
  });
}
