// src/lib/skills/SkillRegistry.ts
export interface Skill {
  id: string;
  name: string;
  description: string;
  keywords: string[];
  load: () => Promise<string>;
  execute: (input: string) => Promise<any>;
}

export class SkillRegistry {
  private skills: Map<string, Skill> = new Map();
  
  register(skill: Skill) {
    this.skills.set(skill.id, skill);
  }
  
  async discover(task: string): Promise<Skill[]> {
    const taskLower = task.toLowerCase();
    return Array.from(this.skills.values())
      .filter(s => s.keywords.some(k => taskLower.includes(k)));
  }
  
  async get(id: string): Promise<Skill | undefined> {
    return this.skills.get(id);
  }
  
  list(): Skill[] {
    return Array.from(this.skills.values());
  }
}

export const skillRegistry = new SkillRegistry();
