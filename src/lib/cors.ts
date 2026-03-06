/**
 * CORS Configuration & Middleware
 * Implements proper Cross-Origin Resource Sharing (CORS) headers
 * 
 * Usage in API routes:
 * import { applyCORS, withCORSHandler } from '@/lib/cors';
 * 
 * // Option 1: Manual
 * export async function POST(request: Request) {
 *   const response = NextResponse.json({...});
 *   return applyCORS(response, request);
 * }
 * 
 * // Option 2: With helper
 * export const POST = withCORSHandler(async (request, response) => {
 *   return response;
 * });
 */

import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

/**
 * CORS Configuration
 * Adjust based on your deployment environment
 */
const CORS_CONFIG = {
  // Allowed origins - configure for your environment
  allowedOrigins: process.env.NODE_ENV === 'production'
    ? [process.env.ALLOWED_ORIGINS || 'https://yourdomain.com'].filter(Boolean)
    : ['http://localhost:3000', 'http://localhost:5173', 'http://127.0.0.1:3000'], // Dev origins

  // Allowed HTTP methods
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD'],

  // Allowed headers
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Requested-With',
    'X-Request-ID',
    'Accept',
    'Origin',
  ],

  // Exposed headers
  exposedHeaders: [
    'Content-Length',
    'Content-Type',
    'X-Request-ID',
    'X-RateLimit-Limit',
    'X-RateLimit-Remaining',
    'X-RateLimit-Reset',
  ],

  // Allow credentials
  credentials: true,

  // Max age for preflight cache (24 hours)
  maxAge: 86400,
};

/**
 * Check if origin is allowed
 */
function isOriginAllowed(origin: string | null): boolean {
  if (!origin) return false;

  // In development, generally allow all localhost origins
  if (process.env.NODE_ENV === 'development') {
    return origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1');
  }

  // In production, only allow explicitly configured origins
  return CORS_CONFIG.allowedOrigins.includes(origin);
}

/**
 * Apply CORS headers to response
 */
export function applyCORS(response: NextResponse, request: NextRequest): NextResponse {
  const origin = request.headers.get('origin');

  // Only set CORS headers if origin is allowed
  if (isOriginAllowed(origin)) {
    response.headers.set('Access-Control-Allow-Origin', origin || '*');
    response.headers.set('Access-Control-Allow-Credentials', String(CORS_CONFIG.credentials));
    response.headers.set(
      'Access-Control-Allow-Methods',
      CORS_CONFIG.allowedMethods.join(', ')
    );
    response.headers.set(
      'Access-Control-Allow-Headers',
      CORS_CONFIG.allowedHeaders.join(', ')
    );
    response.headers.set(
      'Access-Control-Expose-Headers',
      CORS_CONFIG.exposedHeaders.join(', ')
    );
    response.headers.set('Access-Control-Max-Age', String(CORS_CONFIG.maxAge));
  }

  return response;
}

/**
 * Handle OPTIONS preflight requests
 */
export function handleCORSPreflight(request: NextRequest): NextResponse | null {
  if (request.method === 'OPTIONS') {
    const response = new NextResponse(null, { status: 200 });
    return applyCORS(response, request);
  }

  return null;
}

/**
 * Middleware wrapper for API handlers
 * Handles preflight and applies CORS automatically
 */
export function withCORSHandler(
  handler: (request: NextRequest) => Promise<NextResponse>
) {
  return async function corsHandler(request: NextRequest): Promise<NextResponse> {
    // Handle preflight
    const preflight = handleCORSPreflight(request);
    if (preflight) {
      return preflight;
    }

    // Call the actual handler
    let response = await handler(request);

    // Apply CORS headers
    response = applyCORS(response, request);

    return response;
  };
}

/**
 * Next.js Middleware for all routes
 * Place in src/middleware.ts
 * 
 * export { corsMiddleware as default } from '@/lib/cors';
 * 
 * export const config = {
 *   matcher: [
 *     '/((?!_next/static|_next/image|favicon.ico).*)',
 *   ],
 * };
 */
export async function corsMiddleware(request: NextRequest) {
  // Handle preflight requests
  if (request.method === 'OPTIONS') {
    return handleCORSPreflight(request);
  }

  // For regular requests, just continue
  // CORS headers will be added by individual route handlers
  return undefined;
}

/**
 * Rate limiting result interface
 */
export interface RateLimitResult {
  limited: boolean;
  remaining: number;
  resetAt: number;
}

/**
 * Simple in-memory rate limiter
 * NOTE: In production, use Redis or similar for distributed rate limiting
 */
class RateLimiter {
  private requests: Map<string, number[]> = new Map();
  private readonly windowMs: number;
  private readonly maxRequests: number;

  constructor(windowMs: number = 60000, maxRequests: number = 100) {
    this.windowMs = windowMs;
    this.maxRequests = maxRequests;
  }

  /**
   * Check if request is rate limited
   */
  check(identifier: string): RateLimitResult {
    const now = Date.now();
    const times = this.requests.get(identifier) || [];

    // Remove old requests outside the window
    const recentRequests = times.filter(t => now - t < this.windowMs);

    if (recentRequests.length >= this.maxRequests) {
      const oldestRequest = Math.min(...recentRequests);
      return {
        limited: true,
        remaining: 0,
        resetAt: oldestRequest + this.windowMs,
      };
    }

    // Record this request
    recentRequests.push(now);
    this.requests.set(identifier, recentRequests);

    return {
      limited: false,
      remaining: this.maxRequests - recentRequests.length,
      resetAt: now + this.windowMs,
    };
  }
}

export const rateLimiter = new RateLimiter(60000, 100); // 100 requests per minute

/**
 * Apply rate limiting headers to response
 */
export function applyRateLimitHeaders(response: NextResponse, result: RateLimitResult) {
  response.headers.set('X-RateLimit-Limit', '100');
  response.headers.set('X-RateLimit-Remaining', String(result.remaining));
  response.headers.set('X-RateLimit-Reset', String(result.resetAt));

  return response;
}
