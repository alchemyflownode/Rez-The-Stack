export async function runOKIRULoop(task: string) {
  const t = task.toLowerCase();
  let worker = 'mcp'; // DEFAULT IS SEARCH
  
  // PRIORITY 1: CONSTITUTIONAL AMENDMENT
  if (t.includes('new rule') || t.includes('from now on')) {
    worker = 'mutation';
  }
  // PRIORITY 2: DEEP SEARCH
  else if (t.includes('deep search') || t.includes('research') || t.includes('synthesize')) {
    worker = 'deepsearch';
  }
  // PRIORITY 2.5: MCP (Web Search)
  else if (t.includes('search') || t.includes('web') || t.includes('google') || t.includes('lookup')) {
    worker = 'mcp';
  }
  // PRIORITY 3: VISION
  else if (t.includes('look') || t.includes('see') || t.includes('screenshot')) {
    worker = 'vision';
  }
  // PRIORITY 3.5: VOICE
  else if (t.includes('listen') || t.includes('hear') || t.includes('transcribe') || t.includes('audio')) {
    worker = 'voice';
  }
  // PRIORITY 3.6: SYSTEM MONITOR (PC Dashboard)
  else if (t.includes('system health') || t.includes('pc stats') || t.includes('vitals') || t.includes('dashboard')) {
    worker = 'system_monitor';
  }
  // PRIORITY 4: APP CONTROL
  else if (t.includes('launch') || t.includes('open') || t.includes('start')) {
    worker = 'app';
  }
  // PRIORITY 4.5: FILE OPERATIONS
  else if (t.includes('file') || t.includes('list') || t.includes('read') || t.includes('write')) {
    worker = 'file';
  }
  // PRIORITY 5: CODE (Explicit)
  else if (t.includes('write code') || t.includes('python script') || t.includes('debug') || t.includes('function')) {
    worker = 'code';
  }
  // PRIORITY 5.5: DIRECTOR (SCE Compiler)
  else if (t.includes('director') || t.includes('scene') || t.includes('compile') || t.includes('sce')) {
    worker = 'director';
  }
  // PRIORITY 6: SCE ENGINE (COBOL-style)
  else if (t.includes('working-storage') || t.includes('procedure division')) {
    worker = 'sce';
  }
  // PRIORITY 6.5: CANVAS (Image Generation)
  else if (t.includes('generate image') || t.includes('create image') || t.includes('draw') || t.includes('comfy')) {
    worker = 'canvas';
  }
  // PRIORITY 7: REZSTACK
  else if (t.includes('rezstack') || t.includes('stack') || t.includes('crystal')) {
    worker = 'rezstack';
  }

  console.log(`[ROUTER] ${task} -> ${worker}`);
  return { worker, intent: task };
}
