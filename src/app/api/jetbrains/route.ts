import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);

// Detect installed JetBrains IDEs
const getInstalledIDEs = () => {
  const commonPaths = [
    'C:\\Program Files\\JetBrains\\PyCharm Community Edition\\bin\\pycharm64.exe',
    'C:\\Program Files\\JetBrains\\PyCharm Professional\\bin\\pycharm64.exe',
    'C:\\Program Files\\JetBrains\\IntelliJ IDEA Community Edition\\bin\\idea64.exe',
    'C:\\Program Files\\JetBrains\\IntelliJ IDEA Ultimate\\bin\\idea64.exe',
    'C:\\Program Files\\JetBrains\\DataGrip\\bin\\datagrip64.exe',
    'C:\\Program Files\\JetBrains\\WebStorm\\bin\\webstorm64.exe',
    'C:\\Program Files\\JetBrains\\CLion\\bin\\clion64.exe',
  ];
  
  const installed = [];
  for (const idePath of commonPaths) {
    if (require('fs').existsSync(idePath)) {
      installed.push({
        name: path.basename(path.dirname(path.dirname(idePath))),
        path: idePath,
        type: idePath.includes('pycharm') ? 'pycharm' :
               idePath.includes('idea') ? 'intellij' :
               idePath.includes('datagrip') ? 'datagrip' :
               idePath.includes('webstorm') ? 'webstorm' : 'other'
      });
    }
  }
  return installed;
};

export async function POST(request: NextRequest) {
  try {
    const { action, file, line, project, command } = await request.json();
    
    const ides = getInstalledIDEs();
    if (ides.length === 0) {
      return NextResponse.json({
        success: false,
        error: 'No JetBrains IDE found',
        ides: []
      });
    }

    // Use the appropriate IDE (prefer PyCharm for Python, IntelliJ for general)
    const ide = ides.find(i => i.type === 'pycharm') || ides[0];
    
    let result;
    
    switch (action) {
      case 'open-file':
        // Open file at specific line
        result = await execAsync(`"${ide.path}" --line ${line || 1} "${file}"`);
        break;
        
      case 'open-project':
        // Open entire project
        result = await execAsync(`"${ide.path}" "${project || process.cwd()}"`);
        break;
        
      case 'inspect':
        // Run code inspections
        result = await execAsync(`"${ide.path}" inspect "${project || process.cwd()}"`);
        break;
        
      case 'refactor':
        // Perform refactoring (requires IDE running with specific command)
        result = await execAsync(`"${ide.path}" refactor "${command}"`);
        break;
        
      case 'format':
        // Format code
        result = await execAsync(`"${ide.path}" format "${file}"`);
        break;
        
      default:
        return NextResponse.json({ success: false, error: 'Unknown action' });
    }
    
    return NextResponse.json({
      success: true,
      action,
      ide: ide.name,
      output: result?.stdout || 'Command executed',
      ides: ides.map(i => i.name)
    });
    
  } catch (error: any) {
    console.error('JetBrains API error:', error);
    return NextResponse.json({
      success: false,
      error: error.message
    }, { status: 500 });
  }
}

export async function GET() {
  const ides = getInstalledIDEs();
  return NextResponse.json({
    success: true,
    ides: ides.map(i => ({ name: i.name, type: i.type })),
    count: ides.length
  });
}
