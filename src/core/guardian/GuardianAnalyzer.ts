// 🦊 GUARDIAN ANALYZER — SOVEREIGN CONSTITUTIONAL ENFORCEMENT
// Zero mocks. Zero illusions. Bitwise-verifiable AST analysis.
// Articles enforced: I (Sovereignty), II (Determinism), III (Shallow Copies), IV (Explicit Contracts)

import * as parser from '@babel/parser';
import traverse from '@babel/traverse';
import * as t from '@babel/types';

export interface Violation {
  id: string;
  type: 'any-type' | 'clone-deep' | 'console-log' | 'cloud-telemetry' | 'probabilistic-api';
  severity: 'error' | 'warning' | 'info';
  message: string;
  file: string;
  line: number;
  column: number;
  fix?: string;
}

export class GuardianAnalyzer {
  analyze(code: string, filename: string): Violation[] {
    const violations: Violation[] = [];
    
    try {
      const ast = parser.parse(code, {
        sourceType: 'module',
        plugins: ['typescript', 'jsx'],
        locations: true // CRITICAL: Enables line/column tracking
      });

      traverse(ast, {
        // ARTICLE IV: NO `any` TYPES (Explicit contracts required)
        TSTypeAnnotation(path) {
          if (t.isTSAnyKeyword(path.node.typeAnnotation)) {
            violations.push({
              id: `any-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
              type: 'any-type',
              severity: 'error',
              message: 'Constitutional violation: `any` type detected. Sovereignty requires explicit contracts.',
              file: filename,
              line: path.node.loc?.start.line ?? 0,
              column: path.node.loc?.start.column ?? 0,
              fix: 'Replace with `unknown` or domain-specific interface'
            });
          }
        },

        // ARTICLE I (Telemetry) + ARTICLE III (Clone-Deep) in Imports
        ImportDeclaration(path) {
          const source = path.node.source.value;
          if (typeof source !== 'string') return;

          // Cloud telemetry ban (Article I)
          if (/@sentry\/|dd-trace|newrelic|applicationinsights|logrocket|rollbar/.test(source)) {
            violations.push({
              id: `telemetry-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
              type: 'cloud-telemetry',
              severity: 'error',
              message: 'Constitutional violation: Cloud telemetry detected. Code must remain sovereign and offline.',
              file: filename,
              line: path.node.loc?.start.line ?? 0,
              column: path.node.loc?.start.column ?? 0,
              fix: 'Remove dependency. Use local audit logs only.'
            });
          }

          // Deep clone ban (Article III)
          if (/clone-deep|lodash\.clonedeep|lodash\/cloneDeep/.test(source)) {
            violations.push({
              id: `clone-deep-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
              type: 'clone-deep',
              severity: 'warning',
              message: 'Constitutional violation: Deep clone detected. Sovereignty requires explicit shallow copies only.',
              file: filename,
              line: path.node.loc?.start.line ?? 0,
              column: path.node.loc?.start.column ?? 0,
              fix: 'Use `{...obj}` or `Object.assign()` for shallow copies'
            });
          }
        },

        // ARTICLE II: PROBABILISTIC APIs + CONSOLE LOGS
        CallExpression(path) {
          if (!t.isMemberExpression(path.node.callee)) return;
          
          const obj = path.node.callee.object;
          const prop = path.node.callee.property;
          
          // Math.random() ban (Article II)
          if (t.isIdentifier(obj, { name: 'Math' }) && 
              t.isIdentifier(prop, { name: 'random' })) {
            violations.push({
              id: `prng-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
              type: 'probabilistic-api',
              severity: 'warning',
              message: 'Constitutional consideration: Math.random() creates non-deterministic behavior. Use seedable RNG.',
              file: filename,
              line: path.node.loc?.start.line ?? 0,
              column: path.node.loc?.start.column ?? 0,
              fix: 'import seedrandom from "seedrandom"; const rng = seedrandom("sovereign-42");'
            });
          }
          
          // Console logs (Production hygiene)
          if (t.isIdentifier(obj, { name: 'console' }) && 
              t.isIdentifier(prop) && 
              ['log', 'warn', 'error', 'info', 'debug'].includes(prop.name)) {
            violations.push({
              id: `console-${prop.name}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
              type: 'console-log',
              severity: 'info',
              message: `Constitutional consideration: console.${prop.name}() detected. Remove for production sovereignty.`,
              file: filename,
              line: path.node.loc?.start.line ?? 0,
              column: path.node.loc?.start.column ?? 0,
              fix: 'Remove or wrap in DEBUG flag'
            });
          }
        }
      });
    } catch (parseError) {
      violations.push({
        id: `parse-fail-${Date.now()}`,
        type: 'any-type',
        severity: 'error',
        message: `AST parse failed: ${(parseError as Error).message}. File may contain syntax errors.`,
        file: filename,
        line: 0,
        column: 0
      });
    }

    return violations;
  }
}