import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';
import path from 'path';

const execAsync = promisify(exec);

// Load Registry
function loadRegistry() {
  try {
    const p = path.join(process.cwd(), 'config', 'skill_registry.json');
    return JSON.parse(fs.readFileSync(p, 'utf-8')).registry;
  } catch { return {}; }
}

export async function POST(req: NextRequest) {
  try {
    const { task } = await req.json();
    const registry = loadRegistry();

    // 1. MDS LAYER: Ask LLM to decompose task into Skills
    const planPrompt = `
You are a Task Decomposer. 
Available Skills: ${JSON.stringify(Object.keys(registry))}.
User Task: "${task}"
Output a JSON array of skill IDs to execute in order.
Example: ["check_hardware", "search_web"]
`;

    const ollama = await fetch('http://localhost:11434/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'llama3.2:3b', prompt: planPrompt, stream: false })
    });
    const planData = await ollama.json();
    
    // 2. PARSE PLAN
    // (Simple regex to find the list)
    const skillMatch = planData.response.match(/\[.*?\]/s);
    if (!skillMatch) return NextResponse.json({ status: 'error', message: 'Could not plan skills.' });
    
    const skills = JSON.parse(skillMatch[0]);
    const results = [];

    // 3. EXECUTION LOOP (The Chain)
    for (const skillId of skills) {
      const skill = registry[skillId];
      if (!skill) { results.push({ skill: skillId, error: 'Unknown skill' }); continue; }

      try {
        let cmd = '';
        if (skill.type === 'python') cmd = `python ${skill.command}`;
        if (skill.type === 'powershell') cmd = `powershell -Command "${skill.command}"`;
        
        const { stdout } = await execAsync(cmd, { timeout: 60000 });
        results.push({ skill: skillId, success: true, preview: stdout.substring(0,100) });
      } catch (e: any) {
        results.push({ skill: skillId, success: false, error: e.message });
        break; // Fail fast
      }
    }

    return NextResponse.json({ 
      status: 'orchestrated', 
      plan: skills, 
      execution_log: results 
    });

  } catch (e: any) {
    return NextResponse.json({ status: 'error', message: e.message }, { status: 500 });
  }
}
