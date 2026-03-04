import { NextResponse } from 'next/server';

export async function GET() {
  // Mock response - replace with ChromaDB proxy when ready
  return NextResponse.json({ 
    entries: [], 
    status: 'ok',
    message: 'Memory worker ready (ChromaDB integration pending)'
  });
}
