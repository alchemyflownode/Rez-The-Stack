# Refactoring Plan: src\components\SovereignControlSurface.tsx

## Current State
- **File**: src\components\SovereignControlSurface.tsx
- **Nesting Depth**: 36
- **Total Lines**: 131

## Recommended Splits

### Sub-components to Extract
1. **HeaderSection** - Extract from render function
2. **MetricsDisplay** - Extract stats display logic
3. **WorkerGrid** - Extract worker visualization
4. **FooterSection** - Extract footer elements

## Benefits
- Reduces depth from 36 to <10
- Improves maintainability
- Enables code reuse

## Implementation Steps
1. Create new components in src/components/ui/
2. Import them into main component
3. Replace inline JSX with component calls
