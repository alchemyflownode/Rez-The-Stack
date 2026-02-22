import { NextRequest, NextResponse } from 'next/server';

// Worker Registry
const workers = {
  code: 'http://localhost:3000/api/workers/code',
  app: 'http://localhost:3000/api/workers/app',
  file: 'http://localhost:3000/api/workers/file'
};

// Deterministic Router (No AI needed for simple tasks)
function simpleRouter(task: string) {
  const t = task.toLowerCase();
  if (t.includes('launch') || t.includes('open') || t.includes('close')) return 'app';
  if (t.includes('write') || t.includes('script') || t.includes('python') || t.includes('code')) return 'code';
  if (t.includes('list') || t.includes('read') || t.includes('file')) return 'file';
  return 'code'; // Default to code worker
}

export async function POST(request: NextRequest) {
  try {
    const { task } = await request.json();
    if (!task) return NextResponse.json({ error: 'Task required' }, { status: 400 });

    const workerKey = simpleRouter(task);
    const workerUrl = workers[workerKey];

    // Delegate
    const response = await fetch(workerUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task })
    });

    const result = await response.json();
    return NextResponse.json({ 
      success: true,
      worker: workerKey,
      result 
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function GET() {
  return NextResponse.json({ status: 'online', patterns: [] });
}
