import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const { command } = await request.json();
    
    // Mock response - replace with Python backend proxy when ready
    return NextResponse.json({ 
      output: `[Mock] Command received: ${command}\n[Execute via Python backend for real execution]`, 
      status: 'ok',
      warning: 'Hands worker in mock mode - connect Python backend for execution'
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
}
