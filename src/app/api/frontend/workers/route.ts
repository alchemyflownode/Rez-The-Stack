import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    workers: [
      { name: 'system_monitor', status: 'active', type: 'python' },
      { name: 'deepsearch', status: 'active', type: 'python' },
      { name: 'cortex', status: 'active', type: 'local_llm' },
      { name: 'mutation', status: 'active', type: 'python' }
    ]
  });
}
