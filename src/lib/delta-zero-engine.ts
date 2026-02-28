// src/lib/delta-zero-engine.ts

export type Domain = "text" | "code" | "action" | "image";

export interface Rule<T> {
  name: string;
  verify: (output: T) => boolean;
  correct?: (output: T) => T;
}

export class DeltaZeroEngine {
  private rules: Map<Domain, Rule<any>[]> = new Map();
  public enabled: boolean = true;

  constructor() {
    this.rules.set("text", []);
    this.rules.set("code", []);
    this.rules.set("action", []);
    this.rules.set("image", []);
  }

  addRule<T>(domain: Domain, rule: Rule<T>) {
    const domainRules = this.rules.get(domain) || [];
    domainRules.push(rule);
    this.rules.set(domain, domainRules);
  }

  enforce<T>(output: T, domain: Domain): T {
    if (!this.enabled) return output;
    const domainRules = this.rules.get(domain) || [];
    let currentOutput = output;

    for (const rule of domainRules) {
      const isValid = rule.verify(currentOutput);
      if (!isValid) {
        console.warn(`[Delta_Zero] Rule "${rule.name}" FAILED.`);
        if (rule.correct) {
          console.log(`[Delta_Zero] Applying correction...`);
          currentOutput = rule.correct(currentOutput);
        }
      }
    }
    return currentOutput;
  }
}

export const Governor = new DeltaZeroEngine();
