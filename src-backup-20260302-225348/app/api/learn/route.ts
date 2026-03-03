import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

const MEMORY_DIR = path.join(process.cwd(), 'brain', 'knowledge');

// Ensure memory directory exists
try {
  if (!fs.existsSync(MEMORY_DIR)) {
    fs.mkdirSync(MEMORY_DIR, { recursive: true });
  }
} catch (e) {
  console.error('Failed to create memory directory:', e);
}

export async function GET() {
  try {
    // Read memory files
    const files = fs.existsSync(MEMORY_DIR) ? fs.readdirSync(MEMORY_DIR) : [];
    
    const memories = files
      .filter(f => f.endsWith('.json'))
      .map(f => {
        try {
          const content = fs.readFileSync(path.join(MEMORY_DIR, f), 'utf-8');
          return {
            id: f.replace('.json', ''),
            ...JSON.parse(content)
          };
        } catch (e) {
          return null;
        }
      })
      .filter(Boolean);

    return NextResponse.json({
      success: true,
      memories,
      count: memories.length,
      message: 'Memory system online'
    });
  } catch (error) {
    return NextResponse.json({
      success: true,
      memories: [],
      count: 0,
      message: 'Memory system initializing'
    });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { sourceDomain, targetDomain, context, patterns } = body;
    
    const timestamp = Date.now();
    const memoryFile = path.join(MEMORY_DIR, `memory_${timestamp}.json`);
    
    const memoryEntry = {
      id: `mem_${timestamp}`,
      timestamp: new Date().toISOString(),
      sourceDomain: sourceDomain || 'unknown',
      targetDomain: targetDomain || 'unknown',
      context: context || '',
      patterns: patterns || [],
      applications: 1
    };
    
    fs.writeFileSync(memoryFile, JSON.stringify(memoryEntry, null, 2));
    
    return NextResponse.json({
      success: true,
      memory: memoryEntry,
      message: 'Memory stored successfully'
    });
  } catch (error) {
    console.error('Memory storage error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to store memory',
        details: String(error)
      },
      { status: 500 }
    );
  }
}
