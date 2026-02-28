import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);

export async function POST(request: NextRequest) {
  try {
    const { task, query: directQuery } = await request.json();
    
    // Extract query from task or use direct query
    let query = directQuery || task || '';
    
    // Clean up the query
    if (task) {
      query = task
        .replace(/search for/gi, '')
        .replace(/search/gi, '')
        .replace(/find/gi, '')
        .replace(/look up/gi, '')
        .replace(/research/gi, '')
        .replace(/deep search/gi, '')
        .trim();
    }
    
    if (!query) {
      query = "latest technology news";
    }
    
    console.log(`🔍 DeepSearch query: "${query}"`);
    
    // Call Python search worker
    const scriptPath = path.join(process.cwd(), 'src/workers/search_worker.py');
    const { stdout, stderr } = await execAsync(`python "${scriptPath}" "${query}" --synthesis`, { 
      timeout: 15000,
      maxBuffer: 1024 * 1024
    });
    
    if (stderr) {
      console.warn('Search worker stderr:', stderr);
    }
    
    const result = JSON.parse(stdout);
    
    if (!result.success) {
      return NextResponse.json({
        status: 'error',
        error: result.error || 'Search failed',
        worker: 'deepsearch'
      }, { status: 500 });
    }
    
    // Format response for chat
    let responseText = '';
    if (result.results && result.results.length > 0) {
      responseText = `🔍 Found ${result.count} results for "${result.query}":\n\n`;
      result.results.slice(0, 3).forEach((r: any, i: number) => {
        responseText += `${i+1}. **${r.title}**\n${r.snippet}\n[Source](${r.url})\n\n`;
      });
      if (result.count > 3) {
        responseText += `*... and ${result.count - 3} more results*`;
      }
    } else {
      responseText = `No results found for "${result.query}"`;
    }
    
    return NextResponse.json({
      status: 'success',
      worker: 'deepsearch',
      content: responseText,
      answer: responseText,
      results: result.results || [],
      images: result.images || [],
      count: result.count || 0,
      time_ms: result.time_ms,
      raw: result
    });
    
  } catch (error: any) {
    console.error('Search API error:', error);
    
    // Fallback to mock if Python worker fails
    return NextResponse.json({
      status: 'success',
      worker: 'deepsearch',
      content: `🔍 Search results for "${task}":\n\n1. **Sample Result 1**\nThis is a fallback result. Install duckduckgo-search for real results.\n\n2. **Sample Result 2**\nThe search worker encountered an error. Please check Python dependencies.`,
      results: [
        { title: 'Sample Result 1', url: '#', snippet: 'Fallback result' },
        { title: 'Sample Result 2', url: '#', snippet: 'Install duckduckgo-search' }
      ],
      count: 2,
      note: 'Using fallback - Python worker error'
    });
  }
}

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get('q');
  
  if (!query) {
    return NextResponse.json({ error: 'No query provided' }, { status: 400 });
  }
  
  // Reuse POST logic
  return POST(request);
}
