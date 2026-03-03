import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);

export async function POST(req: NextRequest) {
  try {
    const { task } = await req.json();
    const lower = task.toLowerCase();
    console.log(`🧠 Processing: "${task}"`);

    let result;

    // ===== HIGHEST PRIORITY - MEMORY & DEDUCTION =====
    if (lower.includes('based on') || 
        lower.includes('remember') || 
        lower.includes('recall') || 
        lower.includes('previous') ||
        lower.includes('learn from') ||
        (lower.includes('memory') && !lower.includes('ram'))) {
      
      console.log('→ Routing to memory/deduction system');
      
      try {
        // Fetch memories from learn API
        const memRes = await fetch('http://localhost:3001/api/learn');
        const memories = await memRes.json();
        
        // Create context from memories
        const memoryContext = memories.memories?.map((m: any) => 
          `Previous: ${m.context} (${m.sourceDomain})`
        ).join('\n') || 'No previous memories';
        
        // Ask Ollama with memory context
        const ollamaRes = await fetch('http://localhost:11434/api/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: 'llama3.2:3b',
            prompt: `Context from previous conversations:\n${memoryContext}\n\nUser now asks: "${task}"\n\nProvide a response that references relevant past interactions.`,
            stream: false
          })
        });
        const data = await ollamaRes.json();
        result = { 
          success: true, 
          content: data.response,
          worker: 'memory_deduction',
          memories_used: memories.memories?.length || 0
        };
      } catch (memError) {
        console.error('Memory error, falling back:', memError);
        // Fallback to regular cortex
        const ollamaRes = await fetch('http://localhost:11434/api/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: 'llama3.2:3b',
            prompt: task,
            stream: false
          })
        });
        const data = await ollamaRes.json();
        result = { 
          success: true, 
          content: data.response,
          worker: 'cortex'
        };
      }
    }

    // ===== SEARCH (but not memory-related) =====
    else if ((lower.includes('search') || lower.includes('find') || lower.includes('research')) 
             && !lower.includes('memory')) {
      console.log('→ Routing to deepsearch');
      const scriptPath = path.join(process.cwd(), 'src/workers/search_worker.py');
      try {
        const { stdout } = await execAsync(`python "${scriptPath}" "${task}"`);
        result = JSON.parse(stdout);
        result.worker = 'deepsearch';
      } catch (searchError) {
        console.error('Search worker error:', searchError);
        const searchRes = await fetch('http://localhost:3001/api/workers/deepsearch', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ task })
        });
        result = await searchRes.json();
      }
    }

    // ===== APP LAUNCHING =====
    else if (lower.includes('open ') || lower.includes('launch ') || lower.includes('start ')) {
      console.log('→ Routing to app_launcher');
      const scriptPath = path.join(process.cwd(), 'src/workers/app_launcher.py');
      let app = lower.replace('open ', '').replace('launch ', '').replace('start ', '').trim();
      const { stdout } = await execAsync(`python "${scriptPath}" "${app}"`);
      result = JSON.parse(stdout);
      result.worker = 'app_launcher';
    }

    // ===== CODE/MUTATION =====
    else if (lower.includes('code') || lower.includes('function') || lower.includes('script')) {
      console.log('→ Routing to cortex for code');
      const ollamaRes = await fetch('http://localhost:11434/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'llama3.2:3b',
          prompt: task,
          stream: false
        })
      });
      const data = await ollamaRes.json();
      result = { 
        success: true, 
        content: data.response,
        worker: 'cortex'
      };
    }

    // ===== SYSTEM MONITORING (lowest priority - only pure hardware queries) =====
    else if ((lower.includes('cpu') || lower.includes('gpu') || lower.includes('temperature')) ||
             (lower.includes('ram') && !lower.includes('memory'))) {
      console.log('→ Routing to system_monitor');
      const scriptPath = path.join(process.cwd(), 'src/workers/system_agent.py');
      const { stdout } = await execAsync(`python "${scriptPath}" snapshot`);
      result = JSON.parse(stdout);
      result.worker = 'system_monitor';
    }

    // ===== DEFAULT =====
    else {
      console.log('→ Routing to cortex (default)');
      const ollamaRes = await fetch('http://localhost:11434/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'llama3.2:3b',
          prompt: task,
          stream: false
        })
      });
      const data = await ollamaRes.json();
      result = { 
        success: true, 
        content: data.response,
        worker: 'cortex'
      };
    }

    return NextResponse.json(result);

  } catch (error: any) {
    console.error('❌ Kernel error:', error);
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}

export async function GET() {
  return NextResponse.json({ status: 'sovereign', version: '2026' });
}
