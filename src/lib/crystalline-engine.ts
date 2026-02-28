// src/lib/crystalline-engine.ts
import { getAgentSystemPrompt, enhancePromptWithContext } from './sovereign-agent-protocol';
import { getHardwareContext } from './hardware-context';

export async function crystallizeDeduction(task: string): Promise<string> {
  try {
    // Get real hardware context
    const context = await getHardwareContext();
    
    // Return enhanced prompt with context
    return enhancePromptWithContext(task, context);
  } catch (error) {
    // Fallback to basic prompt if context fetch fails
    console.warn('Failed to get hardware context, using basic prompt:', error);
    return getAgentSystemPrompt() + `\n\n# USER TASK\n"${task}"\n\n# YOUR RESPONSE\n`;
  }
}

export async function analyzeIntent(task: string): Promise<{
  type: 'simple' | 'complex' | 'tool_required';
  suggested_worker?: string;
  confidence: number;
}> {
  const taskLower = task.toLowerCase();
  
  // Quick pattern matching for intent analysis
  if (taskLower.includes('open ') || taskLower.includes('launch ')) {
    return {
      type: 'tool_required',
      suggested_worker: 'app_launcher',
      confidence: 0.95
    };
  }
  
  if (taskLower.includes('cpu') || taskLower.includes('memory') || 
      taskLower.includes('gpu') || taskLower.includes('health')) {
    return {
      type: 'tool_required',
      suggested_worker: 'system_monitor',
      confidence: 0.9
    };
  }
  
  if (taskLower.includes('search') || taskLower.includes('find') || 
      taskLower.includes('research')) {
    return {
      type: 'tool_required',
      suggested_worker: 'deepsearch',
      confidence: 0.85
    };
  }
  
  if (taskLower.includes('code') || taskLower.includes('function') || 
      taskLower.includes('bug') || taskLower.includes('fix')) {
    return {
      type: 'tool_required',
      suggested_worker: 'mutation_worker',
      confidence: 0.8
    };
  }
  
  if (taskLower.includes('note') || taskLower.includes('remember') || 
      taskLower.includes('task') || taskLower.includes('remind')) {
    return {
      type: 'tool_required',
      suggested_worker: 'executive_mcp',
      confidence: 0.9
    };
  }
  
  if (taskLower.includes('screen') || taskLower.includes('see') || 
      taskLower.includes('what\'s on')) {
    return {
      type: 'tool_required',
      suggested_worker: 'vision_worker',
      confidence: 0.85
    };
  }
  
  // Default to simple chat
  return {
    type: 'simple',
    confidence: 0.7
  };
}
