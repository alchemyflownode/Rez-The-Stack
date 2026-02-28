// src/app/api/compute/execute/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function POST(req: NextRequest) {
  try {
    const { task } = await req.json();
    
    // Call compute orchestrator
    const { stdout } = await execAsync(`python src/workers/compute_orchestrator.py "${task}"`);
    const result = JSON.parse(stdout);
    
    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}