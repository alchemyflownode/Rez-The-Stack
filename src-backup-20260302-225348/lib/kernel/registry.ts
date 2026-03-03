// src/lib/kernel/registry.ts
// AUTOFIXED: Removed ghost imports causing silent crashes
import type { NextRequest, NextResponse } from 'next/server';

export type WorkerHandler = (req: NextRequest) => Promise<NextResponse>;

// Safe, empty registry - workers self-register via API routes
export const workerRegistry: Record<string, WorkerHandler> = {};

export function registerWorker(name: string, handler: WorkerHandler) {
  workerRegistry[name] = handler;
}

export function getWorker(name: string): WorkerHandler | undefined {
  return workerRegistry[name];
}
