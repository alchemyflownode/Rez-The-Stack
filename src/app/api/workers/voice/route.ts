import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { task } = await request.json();
    
    return NextResponse.json({
      status: 'success',
      worker: 'voice',
      message: 'Voice processing would happen here with Whisper.cpp',
      note: 'Install Whisper.cpp and add audio handling',
      task: task
    });

  } catch (error: any) {
    return NextResponse.json({ 
      status: 'error', 
      message: error.message 
    }, { status: 500 });
  }
}

export async function GET() {
  return NextResponse.json({
    status: 'online',
    worker: 'voice',
    message: 'Voice worker ready'
  });
}
