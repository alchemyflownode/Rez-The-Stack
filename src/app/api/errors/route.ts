/**
 * Error Logging Endpoint
 * Receives error reports from frontend and logs them
 */

import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { logger } from '@/lib/logger';

interface ErrorReport {
  message: string;
  stack?: string;
  componentStack?: string;
  timestamp?: string;
}

/**
 * POST /api/errors
 * Logs client-side errors from error boundaries
 */
export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const report = (await request.json()) as unknown;

    // Basic validation
    if (typeof report !== 'object' || report === null) {
      return NextResponse.json(
        { error: 'Invalid error report format' },
        { status: 400 }
      );
    }

    const errorReport = report as ErrorReport;

    // Log the error
    await logger.error('ClientErrorBoundary', {
      message: errorReport.message,
      stack: errorReport.stack,
      componentStack: errorReport.componentStack,
      timestamp: errorReport.timestamp,
    } as any);

    // In production, could send to external service like Sentry
    // Example:
    // if (process.env.NODE_ENV === 'production') {
    //   await sendToSentry(errorReport);
    // }

    return NextResponse.json(
      {
        status: 'logged',
        message: 'Error has been recorded',
      },
      { status: 200 }
    );
  } catch (error) {
    logger.error('ErrorLoggingEndpoint', error as Error);

    return NextResponse.json(
      { error: 'Failed to log error' },
      { status: 500 }
    );
  }
}

/**
 * GET /api/errors/health
 * Check if error logging is working
 */
export async function GET(): Promise<NextResponse> {
  return NextResponse.json({
    status: 'ok',
    service: 'error-logging',
    timestamp: new Date().toISOString(),
  });
}
