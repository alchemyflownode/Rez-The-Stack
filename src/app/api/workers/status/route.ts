import { NextResponse } from 'next/server';
import { workerRegistry } from '@/lib/workers/workerRegistry';

export async function GET() {
  // In a real implementation, you'd check actual worker status
  // For now, return registry with active status
  
  return NextResponse.json({
    success: true,
    workers: workerRegistry,
    stats: {
      total: workerRegistry.length,
      python: workerRegistry.filter(w => w.category === 'python').length,
      api: workerRegistry.filter(w => w.category === 'api').length,
      system: workerRegistry.filter(w => w.category === 'system').length,
      ai: workerRegistry.filter(w => w.category === 'ai').length,
    }
  });
}
