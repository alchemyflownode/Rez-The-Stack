import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function GET() {
  try {
    const { stdout } = await execAsync('ollama list');
    const lines = stdout.trim().split('\n').slice(1);
    const models = lines.map(line => {
      const parts = line.split(/\s+/);
      return parts[0];
    }).filter(Boolean);
    
    return NextResponse.json({ models });
  } catch (error) {
    return NextResponse.json({ 
      models: ['llama3.2:latest', 'phi3.5:3.8b', 'qwen2.5-coder:14b'],
      default: 'llama3.2:latest'
    });
  }
}

export async function POST(request: Request) {
  try {
    const { model } = await request.json();
    return NextResponse.json({ selected: model });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to set model' }, { status: 500 });
  }
}
