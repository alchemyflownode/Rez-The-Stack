// Root-Seeker Core Types
// The universal framework for domain-agnostic root discovery

export interface RootQuestion {
  question: string;
  depth: number;
  isRoot: boolean;
}

export interface DomainInsight {
  surface: string[];      // What everyone sees
  middle: string[];       // Use cases and patterns
  root: string;           // The fundamental truth
}

export interface FrameworkStructure {
  name: string;
  principles: string[];
  components: FrameworkComponent[];
  flows: FlowDefinition[];
  metrics: MetricDefinition[];
}

export interface FrameworkComponent {
  name: string;
  purpose: string;
  connections: string[];
}

export interface FlowDefinition {
  name: string;
  steps: string[];
  triggers: string[];
}

export interface MetricDefinition {
  name: string;
  type: 'depth' | 'alignment' | 'truth' | 'momentum';
  description: string;
}

export interface HealingDiagnosis {
  issue: string;
  rootCause: string;
  intervention: string;
  confidence: number;
}

export interface PatternTransfer {
  sourceDomain: string;
  targetDomain: string;
  pattern: string;
  adaptation: string;
  confidence: number;
}

// Root-Seeking Prompts
export const ROOT_SEEKER_PROMPTS = {
  descend: `You are a Root-Seeker. Your job is to help discover the fundamental truth beneath any domain.

RULES:
1. Never accept surface-level answers
2. Always ask "why does this work?" not "what works?"
3. Look for the flow, not the features
4. Identify the irreducible structure

PROCESS:
- Layer 1 (Surface): What do people typically see?
- Layer 2 (Middle): What patterns emerge?
- Layer 3 (Root): What's the fundamental truth?

Output as JSON with keys: surface, middle, root`,

  architect: `You are a Framework Architect. Given a root truth, distill it into a buildable structure.

OUTPUT FORMAT:
{
  "name": "Framework Name",
  "principles": ["principle 1", "principle 2"],
  "components": [
    {"name": "Component", "purpose": "What it does", "connections": ["to other components"]}
  ],
  "flows": [
    {"name": "Flow Name", "steps": ["step 1", "step 2"], "triggers": ["when this happens"]}
  ],
  "metrics": [
    {"name": "Metric", "type": "depth|alignment|truth|momentum", "description": "What it measures"}
  ]
}`,

  heal: `You are a Self-Healing Diagnostic System. Detect when thinking is stuck at the surface level.

INDICATORS OF SURFACE-LEVEL THINKING:
- Circular reasoning
- Feature accumulation without purpose
- Losing sight of the root question
- Analysis paralysis
- Solution-first thinking (vs problem-first)

DIAGNOSIS FORMAT:
{
  "issue": "What's wrong",
  "rootCause": "Why it's happening",
  "intervention": "What to do",
  "confidence": 0.0-1.0
}`,

  learn: `You are a Deductive Learning Engine. Extract transferable patterns from domain insights.

When you see a pattern in one domain, identify:
1. The abstract structure (domain-agnostic)
2. The concrete application (domain-specific)
3. Potential applications to other domains

OUTPUT FORMAT:
{
  "pattern": "Pattern name",
  "abstractStructure": "The domain-agnostic form",
  "concreteApplications": ["example 1", "example 2"],
  "potentialDomains": ["domain where this could apply"],
  "confidence": 0.0-1.0
}`
};

// Domain-agnostic pattern templates
export const UNIVERSAL_PATTERNS = {
  evokerPattern: {
    name: "The EVOKER Pattern",
    description: "Transform any domain into a structured framework",
    structure: {
      stages: ["Perceive", "Analyze", "Synthesize", "Output"],
      coreQuestion: "What's the flow beneath what's happening?",
      metric: "Truth proximity, not feature accumulation"
    }
  },

  descentPattern: {
    name: "The Descent Pattern",
    description: "Go from surface to root in any domain",
    structure: {
      layers: ["Surface (what)", "Middle (how)", "Root (why)"],
      question: "What's true before any features exist?",
      stopping: "When the answer can't be reduced further"
    }
  },

  mirrorPattern: {
    name: "The Mirror Pattern",
    description: "Use AI as a pattern-recognition mirror",
    structure: {
      input: "Your understanding of a domain",
      process: "AI reflects back patterns you might miss",
      output: "Refined understanding, not generated content"
    }
  }
};
