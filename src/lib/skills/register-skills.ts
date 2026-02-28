// src/lib/skills/register-skills.ts
import { skillRegistry } from './SkillRegistry';

// System Monitor
skillRegistry.register({
  id: 'system-monitor',
  name: 'System Monitor',
  description: 'Monitor CPU, RAM, GPU, disk usage',
  keywords: ['cpu', 'ram', 'gpu', 'memory', 'disk', 'health', 'vitals'],
  load: async () => '# System Monitor Skill\nReal-time hardware monitoring',
  execute: async (input) => {
    try {
      const res = await fetch('/api/system/snapshot');
      return await res.json();
    } catch (error) {
      return { error: 'Failed to get system stats' };
    }
  }
});

// Deep Search
skillRegistry.register({
  id: 'deep-search',
  name: 'Deep Research',
  description: 'Search web and synthesize information',
  keywords: ['search', 'research', 'find', 'lookup', 'web'],
  load: async () => '# Deep Research Skill\nWeb search with synthesis',
  execute: async (input) => {
    try {
      const res = await fetch('/api/workers/deepsearch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: input })
      });
      return await res.json();
    } catch (error) {
      return { error: 'Deep search failed' };
    }
  }
});

// Code Mutation
skillRegistry.register({
  id: 'code-mutation',
  name: 'Code Mutation',
  description: 'Analyze and improve code',
  keywords: ['code', 'fix', 'bug', 'refactor', 'clean'],
  load: async () => '# Code Mutation Skill\nSafe code analysis and improvement',
  execute: async (input) => {
    try {
      const res = await fetch('/api/workers/mutation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: input })
      });
      return await res.json();
    } catch (error) {
      return { error: 'Code mutation failed' };
    }
  }
});

// App Launcher
skillRegistry.register({
  id: 'app-launcher',
  name: 'App Launcher',
  description: 'Launch applications',
  keywords: ['open', 'launch', 'start', 'run'],
  load: async () => '# App Launcher Skill\nLaunch applications safely',
  execute: async (input) => {
    try {
      const res = await fetch('/api/workers/app', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: input })
      });
      return await res.json();
    } catch (error) {
      return { error: 'Failed to launch app' };
    }
  }
});

// Vision
skillRegistry.register({
  id: 'vision',
  name: 'Vision Analysis',
  description: 'Analyze images and screen',
  keywords: ['see', 'look', 'image', 'screen', 'vision'],
  load: async () => '# Vision Skill\nImage and screen analysis',
  execute: async (input) => {
    try {
      const res = await fetch('/api/workers/vision', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: input })
      });
      return await res.json();
    } catch (error) {
      return { error: 'Vision analysis failed' };
    }
  }
});

// System Health
skillRegistry.register({
  id: 'system-health',
  name: 'System Health',
  description: 'Check overall system health',
  keywords: ['health', 'status', 'check', 'dashboard'],
  load: async () => '# System Health Skill\nComprehensive system check',
  execute: async (input) => {
    try {
      const res = await fetch('/api/frontend/health');
      return await res.json();
    } catch (error) {
      return { error: 'Health check failed' };
    }
  }
});

console.log(`✅ Registered ${skillRegistry.list().length} skills`);
