/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return [
      // Kernel endpoints
      { source: '/api/kernel', destination: 'http://localhost:8001/api/kernel' },
      { source: '/api/status', destination: 'http://localhost:8001/api/status' },
      { source: '/api/health', destination: 'http://localhost:8001/api/health' },
      
      // Executive MCP
      { source: '/api/notes/:path*', destination: 'http://localhost:8001/api/notes/:path*' },
      { source: '/api/tasks/:path*', destination: 'http://localhost:8001/api/tasks/:path*' },
      
      // System MCP
      { source: '/api/system/:path*', destination: 'http://localhost:8001/api/system/:path*' },
      
      // Process MCP
      { source: '/api/apps/:path*', destination: 'http://localhost:8001/api/apps/:path*' },
      { source: '/api/processes/:path*', destination: 'http://localhost:8001/api/processes/:path*' },
      
      // Research MCP
      { source: '/api/search/:path*', destination: 'http://localhost:8001/api/search/:path*' },
      
      // RAG Pipeline
      { source: '/api/rag/:path*', destination: 'http://localhost:8001/api/rag/:path*' },
      
      // Catch all
      { source: '/api/:path*', destination: 'http://localhost:8001/api/:path*' },
    ]
  },
}

module.exports = nextConfig
