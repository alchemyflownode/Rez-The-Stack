import { NextResponse } from 'next/server';
const taskHistory: any[] = [];
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const limit = parseInt(searchParams.get('limit') || '50');
  return NextResponse.json({ history: taskHistory.slice(-limit).reverse() });
}
export async function POST(request: Request) {
  const task = await request.json();
  taskHistory.push({ ...task, timestamp: new Date().toISOString(), id: Date.now().toString() });
  return NextResponse.json({ success: true });
}
