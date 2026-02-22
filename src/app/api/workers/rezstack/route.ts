import { NextRequest, NextResponse } from 'next/server';

const REZSTACK_URL = 'http://localhost:5173/api';

export async function POST(request: NextRequest) {
  try {
    const { task, endpoint, path: filePath, service, port } = await request.json();
    
    // Route to appropriate RezStack endpoint
    if (task?.includes('file tree') || endpoint === 'files/tree') {
      const response = await fetch(`${REZSTACK_URL}/files/tree`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path: filePath || '.' })
      });
      const data = await response.json();
      return NextResponse.json({ status: 'success', worker: 'rezstack', data });
    }
    
    else if (task?.includes('recover') || endpoint === 'recover') {
      const response = await fetch(`${REZSTACK_URL}/recover`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ service, port })
      });
      const data = await response.json();
      return NextResponse.json({ status: 'success', worker: 'rezstack', data });
    }
    
    else if (task?.includes('generate') || endpoint === 'generate') {
      return NextResponse.json({ 
        status: 'error', 
        message: 'Generate endpoint temporarily disabled in RezStack' 
      }, { status: 503 });
    }
    
    else {
      return NextResponse.json({ 
        status: 'error', 
        message: 'Unknown RezStack operation' 
      }, { status: 400 });
    }
    
  } catch (error: any) {
    return NextResponse.json({
      status: 'error',
      worker: 'rezstack',
      message: error.message
    }, { status: 500 });
  }
}
