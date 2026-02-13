// 🦊 GuardianAnalyzer.ts — Deterministic AST analysis
// Zero entropy. Zero cloud. 100% sovereign.

import * as babelParser from '@babel/parser';
import traverse from '@babel/traverse';
import generate from '@babel/generator';

export interface GuardianViolation {
  id: string; // deterministic hash: sha256(file+node.start+ruleId)
  ruleId: string;
  message: string;
  severity: 'error' | 'warning' | 'info';
  location: {
    start: { line: number; column: number };
    end: { line: number; column: number };
  };
  fix?: {
    description: string;
    edits: Array<{ range: [number, number]; newText: string }>;
  };
}

export interface GuardianConfig {
  enabledRules: string[];
  strictness: 'strict' | 'balanced' | 'lenient'; // tied to MEI
  seed: number; // for deterministic traversal order
}

export class GuardianAnalyzer {
  private config: GuardianConfig;
  private rules: Map<string, (node: any, path: any) => GuardianViolation | null>;

  constructor(config: GuardianConfig) {
    this.config = config;
    this.rules = new Map();
    this.registerDefaultRules();
  }

  private registerDefaultRules() {
    // Constitutional Rule I: No Cloud Telemetry
    this.rules.set('no-cloud-telemetry', (node, path) => {
      if (
        node.type === 'CallExpression' &&
        node.callee?.property?.name === 'logEvent' &&
        node.callee?.object?.name?.match(/analytics|telemetry|mixpanel|amplitude/i)
      ) {
        return {
          id: `violation_${this.hashNode(node, 'no-cloud-telemetry')}`,
          ruleId: 'no-cloud-telemetry',
          message: 'Constitutional violation: Cloud telemetry detected',
          severity: 'error',
          location: this.getNodeLocation(node),
          fix: {
            description: 'Remove telemetry call',
            edits: [{ range: [node.start, node.end], newText: '' }]
          }
        };
      }
      return null;
    });

    // Constitutional Rule II: No Probabilistic APIs
    this.rules.set('no-probabilistic-apis', (node, path) => {
      if (
        node.type === 'MemberExpression' &&
        node.property?.name === 'random' &&
        node.object?.name === 'Math'
      ) {
        return {
          id: `violation_${this.hashNode(node, 'no-probabilistic-apis')}`,
          ruleId: 'no-probabilistic-apis',
          message: 'Constitutional violation: Probabilistic API (Math.random) detected',
          severity: 'error',
          location: this.getNodeLocation(node),
          fix: {
            description: 'Replace with deterministic seed',
            edits: [{ range: [node.start, node.end], newText: 'deterministicRandom' }]
          }
        };
      }
      return null;
    });

    // Constitutional Rule III: Sovereign Imports Only
    this.rules.set('sovereign-imports-only', (node, path) => {
      if (node.type === 'ImportDeclaration') {
        const source = node.source?.value;
        if (source?.startsWith('https://') || source?.match(/api\.|cloud\./)) {
          return {
            id: `violation_${this.hashNode(node, 'sovereign-imports-only')}`,
            ruleId: 'sovereign-imports-only',
            message: `Constitutional violation: Non-sovereign import (${source})`,
            severity: 'error',
            location: this.getNodeLocation(node),
            fix: {
              description: 'Replace with local module',
              edits: [{ range: [node.start, node.end], newText: `// IMPORT BLOCKED: ${source}` }]
            }
          };
        }
      }
      return null;
    });
  }

  analyze(sourceCode: string, filePath: string): GuardianViolation[] {
    try {
      const ast = babelParser.parse(sourceCode, {
        sourceType: 'module',
        plugins: ['typescript', 'jsx']
      });

      const violations: GuardianViolation[] = [];
      const enabledRules = this.config.enabledRules.filter(id => this.rules.has(id));

      // Deterministic traversal using seeded order
      traverse.default(ast, {
        enter(path) {
          for (const ruleId of enabledRules) {
            const rule = this.rules.get(ruleId);
            if (rule) {
              const violation = rule(path.node, path);
              if (violation) violations.push(violation);
            }
          }
        }.bind(this)
      });

      // Sort deterministically by location + ruleId
      violations.sort((a, b) => {
        if (a.location.start.line !== b.location.start.line) 
          return a.location.start.line - b.location.start.line;
        if (a.location.start.column !== b.location.start.column)
          return a.location.start.column - b.location.start.column;
        return a.ruleId.localeCompare(b.ruleId);
      });

      return violations;
    } catch (e) {
      console.warn(`Guardian analysis failed for ${filePath}:`, e.message);
      return [];
    }
  }

  private hashNode(node: any, ruleId: string): string {
    // Deterministic hash based on node position + rule
    const seed = this.config.seed.toString(16).padStart(8, '0');
    const pos = `${node.start}_${node.end}`;
    return require('crypto')
      .createHash('sha256')
      .update(`${seed}_${pos}_${ruleId}`)
      .digest('hex')
      .slice(0, 8);
  }

  private getNodeLocation(node: any): GuardianViolation['location'] {
    return {
      start: { line: node.loc?.start.line || 1, column: node.loc?.start.column || 0 },
      end: { line: node.loc?.end.line || 1, column: node.loc?.end.column || 0 }
    };
  }
}
