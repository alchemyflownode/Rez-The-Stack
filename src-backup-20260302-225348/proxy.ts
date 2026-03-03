import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// MUST be named 'proxy' (not 'middleware') for Next.js 16.1.3
export function proxy(request: NextRequest) {
  // Sovereign logging
  console.log(`[PROXY] ${request.method} ${request.nextUrl.pathname}`)
  
  // Security headers
  const response = NextResponse.next()
  response.headers.set('X-Sovereign-Version', '5.0')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  
  return response
}

// Optional: Configure which paths run through the proxy
export const config = {
  matcher: '/api/:path*',
}
