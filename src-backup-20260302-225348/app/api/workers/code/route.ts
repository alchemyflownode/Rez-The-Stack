import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { task, code, file } = await request.json();
    
    // If we have a file path, use JetBrains for intelligent operations
    if (file) {
      // Open in IDE for human review
      await fetch('http://localhost:3001/api/jetbrains', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'open-file',
          file,
          line: 1
        })
      });
      
      return NextResponse.json({
        success: true,
        worker: 'code-worker',
        message: `File opened in JetBrains IDE: ${file}`,
        action: 'ide_opened'
      });
    }
    
    // Otherwise use AI for generation
    const ollamaRes = await fetch('http://localhost:11434/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'deepseek-coder:6.7b',
        prompt: task || 'Generate code',
        stream: false
      })
    });
    
    const data = await ollamaRes.json();
    
    return NextResponse.json({
      success: true,
      worker: 'code-worker',
      code: data.response,
      language: 'auto'
    });
    
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
