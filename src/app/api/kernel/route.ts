import { NextResponse } from 'next/server';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const API_BASE_URL = process.env.API_URL || 'http://localhost:8001';

/**
 * REZ HIVE Kernel API Proxy
 * Streams responses from FastAPI backend to support real-time AI responses
 */
export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    // Forward to Python FastAPI backend
    const response = await fetch(`${API_BASE_URL}/api/kernel`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Backend error: ${response.status} - ${errorText}`);
    }

    // Stream the response back to client
    const reader = response.body?.getReader();
    
    if (!reader) {
      throw new Error('No response body from backend');
    }

    const stream = new ReadableStream({
      async start(controller) {
        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            controller.enqueue(value);
          }
        } catch (error) {
          controller.error(error);
        } finally {
          controller.close();
          reader.releaseLock();
        }
      },
    });

    return new Response(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });

  } catch (error: any) {
    console.error('[Kernel API Error]:', error);
    
    return NextResponse.json(
      { 
        content: `⚠️ System Error: ${error.message}. Is the backend running?`,
        status: 'error',
        error: error.message 
      },
      { status: 500 }
    );
  }
}

// Health check endpoint
export async function GET() {
  try {
    const response = await fetch(`${API_BASE_URL}/api/health`, {
      method: 'GET',
    });
    
    if (response.ok) {
      const data = await response.json();
      return NextResponse.json({ 
        status: 'online',
        backend: 'connected',
        ...data
      });
    }
    
    throw new Error('Backend not responding');
  } catch (error) {
    return NextResponse.json({ 
      status: 'degraded',
      backend: 'disconnected',
      message: 'FastAPI backend is not running'
    }, { status: 503 });
  }
}
