# REZ HIVE - Source Structure

## Frontend (src/app/)
- `page.tsx` - Main dashboard UI
- `layout.tsx` - Root layout
- `globals.css` - Global styles
- `api/kernel/route.ts` - Next.js API endpoint

## Components (src/components/)
- `PrimordialUI.tsx` - Agent insights panel
- `TwoBarMeter.tsx` - Memory usage meter
- `CodeBlock.tsx` - Syntax highlighting
- `SovereignTracker.tsx` - Progress tracker

## Workers (src/workers/)
- `memory-worker.ts` - ChromaDB memory integration
- `model-router.ts` - Smart model selection
- `embed.py` - Python embedding generator (copied to backend/)

## Kernel (src/kernel/)
- `psalm139/IntimacyFactory.ts` - Original memory factory

## Backend (backend/)
- `kernel.py` - FastAPI main kernel
- `kernel_v2.py` - Enhanced kernel with file tools
- `tools.py` - System tools
- `memory.py` - Context management
- `vision.py` - Vision worker
- `hands.py` - Hands worker
- `api_discovery.py` - API search
- `embed.py` - Embedding generator

## Architecture Note
The frontend (Next.js) communicates with the backend (FastAPI) 
via the proxy in next.config.js. All API calls to /api/* are 
forwarded to the Python backend.
