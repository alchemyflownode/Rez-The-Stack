import fs from 'fs';
import path from 'path';

export function getModelForTask(taskType: string): string {
  try {
    const configPath = path.join(process.cwd(), 'rez.config.json');
    const raw = fs.readFileSync(configPath, 'utf-8');
    const config = JSON.parse(raw);
    const models = config.models || { default: 'llama3.2:3b' };
    return models.tasks?.[taskType] || models.default || 'llama3.2:3b';
  } catch {
    return 'llama3.2:3b';
  }
}
