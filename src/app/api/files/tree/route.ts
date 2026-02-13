import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

export async function POST(request: NextRequest) {
  try {
    const { path: targetPath = '.' } = await request.json();
    const rootDir = process.cwd();
    const fullPath = path.join(rootDir, targetPath);

    async function scanDirectory(dirPath: string, relativePath: string): Promise<any[]> {
      try {
        const entries = await fs.readdir(dirPath, { withFileTypes: true });
        const children = [];

        // Directories first
        const dirs = entries
          .filter(e => e.isDirectory() && !e.name.startsWith('.') && e.name !== 'node_modules' && e.name !== '.next')
          .sort((a, b) => a.name.localeCompare(b.name));

        for (const dir of dirs) {
          const dirRelativePath = path.join(relativePath, dir.name);
          const subChildren = await scanDirectory(path.join(dirPath, dir.name), dirRelativePath);
          children.push({
            name: dir.name,
            path: dirRelativePath.replace(/\\/g, '/'),
            type: 'directory',
            children: subChildren
          });
        }

        // Files second
        const files = entries
          .filter(e => e.isFile() && !e.name.startsWith('.'))
          .sort((a, b) => a.name.localeCompare(b.name));

        for (const file of files) {
          const ext = file.name.split('.').pop() || '';
          children.push({
            name: file.name,
            path: path.join(relativePath, file.name).replace(/\\/g, '/'),
            type: 'file',
            extension: ext
          });
        }

        return children;
      } catch (error) {
        return [];
      }
    }

    const tree = await scanDirectory(fullPath, targetPath);
    
    return NextResponse.json({ 
      tree: [{
        name: targetPath === '.' ? 'workspace' : targetPath.split('/').pop() || targetPath,
        path: targetPath,
        type: 'directory',
        children: tree
      }],
      path: targetPath 
    });

  } catch (error) {
    // Return empty tree instead of failing
    return NextResponse.json({ 
      tree: [{
        name: 'workspace',
        path: '.',
        type: 'directory',
        children: []
      }],
      path: '.',
      error: 'Could not read directory'
    });
  }
}

export async function GET() {
  return NextResponse.json({
    service: 'File Tree API',
    status: 'ready',
    version: '3.5'
  });
}