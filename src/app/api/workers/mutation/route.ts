import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { task, file } = await request.json();
    
    // If we have a file, use JetBrains for safe refactoring
    if (file) {
      // First, let JetBrains analyze the code
      const analysis = await fetch('http://localhost:3001/api/jetbrains', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'inspect',
          file
        })
      });
      
      // Then open for manual refactoring if needed
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
        worker: 'mutation',
        message: `File opened for safe refactoring in JetBrains IDE`,
        analysis: await analysis.json()
      });
    }
    
    // Use Python mutation worker for automatic fixes
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);
    const path = require('path');
    
    const scriptPath = path.join(process.cwd(), 'src/workers/mutation_worker.py');
    const { stdout } = await execAsync(`python "${scriptPath}" .`);
    const result = JSON.parse(stdout);
    
    return NextResponse.json({
      success: true,
      worker: 'mutation',
      stats: result.stats
    });
    
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
