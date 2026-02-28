// Cognitive Kernel - The Root-Seeker Brain
// Epistemic prompts + Reflection + Chaining + Pattern Memory

export const EPISTEMIC_KERNEL = {
  // THE CONSTITUTION - Core principles baked into every thought
  CONSTITUTION: `
You are a ROOT-SEEKER cognitive kernel. Your purpose is to find the fundamental truth beneath any task.

EPISTEMIC FRAMEWORK:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LAYER 1 - SURFACE: What is immediately visible? (Features, symptoms, lists)
LAYER 2 - MIDDLE: What patterns are operating? (Use cases, relationships)
LAYER 3 - ROOT: What is the irreducible truth? (Principles, structures, flows)

OPERATING RULES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. NEVER stay at the surface
2. Features are not answers - they are clues to the root
3. If you're listing options, you haven't found the root yet
4. The root is TRANSFERABLE - if it only works here, it's not the root
5. Descend until you can't reduce further

SELF-CHECK PROTOCOL:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before EVERY output, ask yourself:
• Am I describing WHAT or explaining WHY?
• Did I find the structure or just list elements?
• Can this be applied to other domains?

If FAILED: Descend deeper.
If PASSED: You may have found the root.
`,

  // REFLECTION PROMPT - Self-evaluation after each thought
  REFLECTION: `
REFLECTION PROTOCOL - Evaluate your previous output:

QUESTIONS:
1. Was this output at SURFACE, MIDDLE, or ROOT level?
2. Did I just list features/options, or find underlying structure?
3. Is the task actually DONE, or did I just produce an output?

COMPLETION CRITERIA:
• Task is DONE when: The root truth is found AND actionable next steps exist
• Task is NOT done when: Still at surface, still exploring, no clear structure

OUTPUT FORMAT (JSON):
{
  "layer": "surface|middle|root",
  "isComplete": true|false,
  "confidence": 0.0-1.0,
  "nextStep": "what to do next if not complete",
  "foundRoot": "the root truth if found, null otherwise"
}
`,

  // CHAINING TRIGGER - Determines if more loops needed
  CHAIN_TRIGGER: `
CHAINING DECISION:

Based on your reflection, determine:
• Should the thinking continue?
• What specifically should happen next?

RULES:
• If layer = "surface" → MUST continue, descend deeper
• If layer = "middle" → Continue if confidence < 0.8
• If layer = "root" AND confidence >= 0.8 AND actionable → STOP
• If isComplete = false → Continue with nextStep

OUTPUT FORMAT (JSON):
{
  "continueChaining": true|false,
  "reason": "why continuing or stopping",
  "nextPrompt": "the exact prompt for the next iteration, null if stopping"
}
`,

  // PATTERN EXTRACTION - Learn from this interaction
  PATTERN_EXTRACTION: `
PATTERN EXTRACTION:

From this reasoning chain, extract transferable patterns:

1. What pattern did you discover?
2. What domain is this from?
3. What other domains could this apply to?
4. What's the abstract structure (domain-agnostic)?

OUTPUT FORMAT (JSON):
{
  "patternName": "descriptive name",
  "sourceDomain": "where this came from",
  "abstractStructure": "the domain-agnostic form",
  "potentialDomains": ["domain1", "domain2"],
  "confidence": 0.0-1.0
}
`
};

// Chain State - Track the reasoning journey
export interface ChainState {
  iteration: number;
  task: string;
  history: ThoughtStep[];
  currentLayer: 'surface' | 'middle' | 'root';
  isComplete: boolean;
  confidence: number;
  rootFound: string | null;
  patternsExtracted: Pattern[];
  maxIterations: number;
}

export interface ThoughtStep {
  iteration: number;
  thought: string;
  layer: 'surface' | 'middle' | 'root';
  reflection: {
    layer: string;
    isComplete: boolean;
    confidence: number;
    nextStep: string;
    foundRoot: string | null;
  };
  chainDecision: {
    continueChaining: boolean;
    reason: string;
    nextPrompt: string | null;
  };
  timestamp: Date;
}

export interface Pattern {
  id: string;
  name: string;
  sourceDomain: string;
  abstractStructure: string;
  potentialDomains: string[];
  confidence: number;
  createdAt: Date;
}

// Completion checkers
export const COMPLETION_RULES = {
  // Must be at root layer
  isAtRoot: (state: ChainState) => state.currentLayer === 'root',
  
  // Confidence must be high enough
  hasHighConfidence: (state: ChainState) => state.confidence >= 0.8,
  
  // Must have found a root truth
  hasRootFound: (state: ChainState) => state.rootFound !== null,
  
  // Must not exceed max iterations
  withinLimits: (state: ChainState) => state.iteration < state.maxIterations,
  
  // All conditions for completion
  isComplete: (state: ChainState) => 
    state.isAtRoot(state) && 
    state.hasHighConfidence(state) && 
    state.hasRootFound(state),
  
  // Should continue
  shouldContinue: (state: ChainState) => 
    state.withinLimits(state) && !state.isComplete(state)
};

// Type Definitions - Added by fix script
export type ThoughtStep = {
  iteration: number;
  thought: string;
  reflection: string;
  confidence: number;
};

export type Pattern = {
  id: string;
  content: string;
  source: string;
  timestamp: Date;
};

export type ChainState = {
  task: string;
  maxIterations: number;
  currentIteration: number;
  thoughts: ThoughtStep[];
  patterns: Pattern[];
  finalAnswer?: string;
};
