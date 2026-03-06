import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  const { command } = await request.json();
  return NextResponse.json({ output: `Executed: ${command}`, status: 'ok' });
}
