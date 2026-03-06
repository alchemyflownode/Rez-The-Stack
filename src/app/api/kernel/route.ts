import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { logger } from '@/lib/logger';
import { validate, KernelTaskSchema, ValidationError } from '@/lib/api/validation';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || process.env.API_URL || 'http://localhost:8001';
const MAX_TIMEOUT_MS = 30000; // 30 second timeout

/**
 * Error response helper
 */
function errorResponse(message: string, status: number, code: string = 'UNKNOWN_ERROR') {
  return NextResponse.json(
    {
      status: 'error',
      error: message,
      code,
      timestamp: new Date().toISOString(),
    },
    { status }
  );
}

/**
 * REZ HIVE Kernel API Proxy
 * Streams responses from FastAPI backend to support real-time AI responses
 * 
 * POST /api/kernel
 * Body: { task: string, worker?: string, model?: string }
 */
export async function POST(request: NextRequest) {
  const requestId = crypto.randomUUID();
  const startTime = Date.now();

  try {
    // Parse request body
    let body: unknown;
    try {
      body = await request.json();
    } catch (e) {
      logger.warn('KernelAPI', `Invalid JSON in request ${requestId}`, { error: String(e) });
      return errorResponse('Invalid JSON in request body', 400, 'INVALID_JSON');
    }

    // Validate request schema
    let validatedTask;
    try {
      validatedTask = validate(KernelTaskSchema, body);
    } catch (e) {
      if (e instanceof ValidationError) {
        logger.warn('KernelAPI', `Validation failed for request ${requestId}`, {
          error: e.message,
          details: e.details.errors,
        });
        return errorResponse(`Invalid request: ${e.message}`, 400, 'VALIDATION_FAILED');
      }
      throw e;
    }

    logger.info('KernelAPI', `Processing task: ${validatedTask.task}`, {
      requestId,
      worker: validatedTask.worker,
      model: validatedTask.model,
    });

    // Check if backend is reachable
    if (!API_BASE_URL) {
      logger.error('KernelAPI', new Error('API_URL not configured'), {
        requestId,
      });
      return errorResponse('API_URL not configured', 500, 'CONFIGURATION_ERROR');
    }

    // Forward to Python FastAPI backend with timeout
    let backendResponse: Response;
    try {
      backendResponse = await Promise.race([
        fetch(`${API_BASE_URL}/api/kernel`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Request-ID': requestId,
            'User-Agent': 'REZ-HIVE-Frontend/1.0',
          },
          body: JSON.stringify(validatedTask),
        }),
        new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Backend timeout')), MAX_TIMEOUT_MS)
        ),
      ] as const);
    } catch (e) {
      const error = e as Error;
      logger.error('KernelAPI', error, {
        requestId,
        elapsed: Date.now() - startTime,
      });

      // Categorize error
      if (error.message.includes('timeout') || error.message.includes('ECONNREFUSED')) {
        return errorResponse(
          'Backend service is not responding. Is the kernel running?',
          503,
          'BACKEND_UNAVAILABLE'
        );
      }

      if (error.message.includes('ENOTFOUND') || error.message.includes('getaddrinfo')) {
        return errorResponse(
          `Cannot reach backend at ${API_BASE_URL}`,
          503,
          'BACKEND_UNREACHABLE'
        );
      }

      return errorResponse(`Backend error: ${error.message}`, 502, 'BACKEND_ERROR');
    }

    // Handle non-200 responses from backend
    if (!backendResponse.ok) {
      let errorDetail = '';
      try {
        errorDetail = await backendResponse.text();
      } catch {
        errorDetail = backendResponse.statusText;
      }

      logger.warn('KernelAPI', `Backend returned ${backendResponse.status}`, {
        requestId,
        status: backendResponse.status,
        error: errorDetail,
      });

      // Categorize backend errors
      if (backendResponse.status === 404) {
        return errorResponse('Endpoint not found on backend', 404, 'ENDPOINT_NOT_FOUND');
      }

      if (backendResponse.status === 429) {
        return errorResponse(
          'Too many requests. Please wait before trying again.',
          429,
          'RATE_LIMITED'
        );
      }

      if (backendResponse.status >= 500) {
        return errorResponse(
          'Backend service error. Please try again later.',
          502,
          'BACKEND_SERVER_ERROR'
        );
      }

      return errorResponse(
        `Backend error: ${errorDetail}`,
        backendResponse.status,
        'BACKEND_REQUEST_ERROR'
      );
    }

    // Stream the response back to client
    const reader = backendResponse.body?.getReader();

    if (!reader) {
      logger.error('KernelAPI', new Error('No response body from backend'), {
        requestId,
      });
      return errorResponse('No response from backend', 502, 'EMPTY_RESPONSE');
    }

    // Create streaming response
    const stream = new ReadableStream({
      async start(controller) {
        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            controller.enqueue(value);
          }

          logger.info('KernelAPI', 'Response streamed successfully', {
            requestId,
            elapsed: Date.now() - startTime,
          });
        } catch (error) {
          logger.error('KernelAPI', error as Error, {
            requestId,
            stage: 'streaming',
          });
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
        'X-Request-ID': requestId,
      },
    });
  } catch (error) {
    // Catch-all for unexpected errors
    logger.error('KernelAPI', error as Error, {
      requestId,
      stage: 'handler',
      elapsed: Date.now() - startTime,
    });

    return errorResponse(
      'An unexpected error occurred. Please try again.',
      500,
      'INTERNAL_SERVER_ERROR'
    );
  }
}

/**
 * GET /api/kernel/health
 * Health check endpoint
 */
export async function GET(request: NextRequest) {
  const requestId = crypto.randomUUID();

  try {
    if (!API_BASE_URL) {
      return NextResponse.json(
        {
          status: 'unhealthy',
          backend: 'unavailable',
          reason: 'API_URL not configured',
          requestId,
        },
        { status: 503 }
      );
    }

    const backendResponse = await Promise.race([
      fetch(`${API_BASE_URL}/api/health`, { method: 'GET' }),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('timeout')), 5000)
      ),
    ] as const);

    if (backendResponse.ok) {
      const data = await backendResponse.json();
      return NextResponse.json(
        {
          status: 'healthy',
          backend: 'connected',
          requestId,
          timestamp: new Date().toISOString(),
          ...data,
        },
        { status: 200 }
      );
    }

    return NextResponse.json(
      {
        status: 'degraded',
        backend: 'error',
        statusCode: backendResponse.status,
        requestId,
        timestamp: new Date().toISOString(),
      },
      { status: 503 }
    );
  } catch (error) {
    logger.warn('KernelAPI', `Health check failed: ${(error as Error).message}`, {
      requestId,
    });

    return NextResponse.json(
      {
        status: 'unhealthy',
        backend: 'disconnected',
        reason: (error as Error).message,
        requestId,
        timestamp: new Date().toISOString(),
      },
      { status: 503 }
    );
  }
}
