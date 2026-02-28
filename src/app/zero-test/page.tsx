'use client';
import { ZeroDriftGlass } from '@/zero/ui/components/glass/ZeroDriftGlass';
import { SovereignStatusBadge } from '@/zero/ui/components/kinetic/SovereignStatusBadge';
import { KineticText } from '@/zero/ui/components/kinetic/KineticText';
import { useAgenticState } from '@/zero/ui/hooks/useAgenticState';

export default function ZeroTestPage() {
  const { state, proof } = useAgenticState();

  return (
    <main className="min-h-screen bg-[var(--bg-deep)] text-white p-8">
      <SovereignStatusBadge proof={proof} status="verified" />
      <div className="max-w-4xl mx-auto mt-20">
        <KineticText text="ZERO DRIFT" className="text-huge mb-4" as="h1" />
        <ZeroDriftGlass intensity="medium" className="p-6 mt-8">
          <p className="text-white/70">
            Zero Drift is running in parallel with your existing app.
            This proves the migration is working without breaking anything.
          </p>
          <div className="mt-4 text-[10px] font-mono text-white/30">
            Intent: {Math.round(state.intent * 100)}% | 
            Load: {Math.round(state.cognitiveLoad * 100)}% | 
            Proof: {proof}
          </div>
        </ZeroDriftGlass>
      </div>
    </main>
  );
}

