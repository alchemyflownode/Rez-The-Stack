import { NextRequest, NextResponse } from 'next/server';
import { readFile, writeFile, readdir, mkdir } from 'fs/promises';
import { join } from 'path';

const WORKSPACE = join(process.cwd(), 'src/temp_workspace');

export async function POST(request: NextRequest) {
  const { task, action, path: filePath, content } = await request.json();
  try {
    if (task && task.toLowerCase().includes('list')) {
      const files = await readdir(process.cwd());
      return NextResponse.json({ status: 'success', worker: 'file', files: files.slice(0, 20) });
    }
    return NextResponse.json({ status: 'error', message: 'No valid action' }, { status: 400 });
  } catch (error: any) {
    return NextResponse.json({ status: 'error', message: error.message }, { status: 500 });
  }
}
