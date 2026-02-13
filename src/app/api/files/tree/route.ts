import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

export async function POST(request: NextRequest) {
  try {
    const { path: targetPath = 'src' } = await request.json();
    const rootDir = process.cwd();
    const fullPath = path.join(rootDir, targetPath);

    async function scanDirectory(dirPath: string, relativePath: string): Promise<any[]> {
      const entries = await fs.readdir(dirPath, { withFileTypes: true });
      const children = [];

      // Directories first (sorted)
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

      // Files second (sorted)
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
    }

    const tree = await scanDirectory(fullPath, targetPath);
    
    return NextResponse.json({ 
      tree: [{
        name: targetPath,
        path: targetPath,
        type: 'directory',
        children: tree
      }],
      path: targetPath 
    });

  } catch (error) {
    console.error(`File tree error at path "${targetPath}":`, error);
    
    // Fallback: return mock tree for development
    return NextResponse.json({ 
      tree: [{
        name: '.',
        path: '.',
        type: 'directory',
        children: [
          {
            name: 'src',
            path: 'src',
            type: 'directory',
            children: [
              {
                name: 'app',
                path: 'src/app',
                type: 'directory',
                children: [
                  { name: 'page.tsx', path: 'src/app/page.tsx', type: 'file', extension: 'tsx' },
                  { name: 'layout.tsx', path: 'src/app/layout.tsx', type: 'file', extension: 'tsx' },
                  { name: 'globals.css', path: 'src/app/globals.css', type: 'file', extension: 'css' }
                ]
              },
              {
                name: 'components',
                path: 'src/components',
                type: 'directory',
                children: [
                  { name: 'FileTree.tsx', path: 'src/components/FileTree.tsx', type: 'file', extension: 'tsx' },
                  { name: 'JARVISTerminal.tsx', path: 'src/components/JARVISTerminal.tsx', type: 'file', extension: 'tsx' },
                  { name: 'ModelSelector.tsx', path: 'src/components/ModelSelector.tsx', type: 'file', extension: 'tsx' }
                ]
              },
              {
                name: 'lib',
                path: 'src/lib',
                type: 'directory',
                children: [
                  { name: 'sovereign-config.ts', path: 'src/lib/sovereign-config.ts', type: 'file', extension: 'ts' }
                ]
              }
            ]
          },
          { name: 'public', path: 'public', type: 'directory', children: [] },
          { name: 'package.json', path: 'package.json', type: 'file', extension: 'json' },
          { name: 'next.config.ts', path: 'next.config.ts', type: 'file', extension: 'ts' },
          { name: 'tsconfig.json', path: 'tsconfig.json', type: 'file', extension: 'json' },
          { name: 'tailwind.config.ts', path: 'tailwind.config.ts', type: 'file', extension: 'ts' },
          { name: 'README.md', path: 'README.md', type: 'file', extension: 'md' }
        ]
      }],
      path: '.',
      fallback: true
    });
  }
}

// Optional: GET endpoint for quick health check
export async function GET() {
  return NextResponse.json({
    service: 'File Tree API',
    status: 'ready',
    endpoints: ['POST /api/files/tree - Get directory structure']
  });
}