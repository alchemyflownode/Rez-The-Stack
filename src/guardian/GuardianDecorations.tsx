// 🦊 GuardianDecorations.tsx — Visual violation feedback
// Red squiggles. Quick fixes. Sovereign UX.

import React from 'react';
import { useGuardian } from '@/guardian/useGuardian';
import { GuardianViolation } from '@/guardian/GuardianAnalyzer';
import { AlertCircle, Lightbulb, X } from 'lucide-react';

interface GuardianDecorationsProps {
  editorContent: string;
  filePath: string;
  onFixApplied?: (violationId: string, fixedCode: string) => void;
}

export const GuardianDecorations: React.FC<GuardianDecorationsProps> = ({
  editorContent,
  filePath,
  onFixApplied
}) => {
  const { violations, isAnalyzing, analyze } = useGuardian({
    enabledRules: ['no-cloud-telemetry', 'no-probabilistic-apis', 'sovereign-imports-only'],
    strictness: 'balanced',
    seed: 42
  });

  // Auto-analyze on content change
  useEffect(() => {
    if (editorContent.trim().length > 10) {
      analyze(editorContent, filePath);
    }
  }, [editorContent, filePath, analyze]);

  if (violations.length === 0 && !isAnalyzing) return null;

  return (
    <div className="absolute bottom-0 left-0 right-0 bg-gray-900/90 border-t border-amber-500/30 
                    p-3 rounded-t-lg backdrop-blur-sm z-50 animate-in fade-in slide-in-from-bottom-2">
      <div className="flex items-start gap-3">
        {isAnalyzing ? (
          <>
            <div className="w-4 h-4 border-2 border-amber-500 border-t-transparent rounded-full animate-spin mt-0.5" />
            <div className="text-sm text-amber-400/80">Guardian analyzing...</div>
          </>
        ) : (
          <>
            <AlertCircle className="w-4 h-4 text-amber-500 mt-0.5 flex-shrink-0" />
            <div className="flex-1">
              <div className="text-sm font-medium text-amber-400 mb-1">
                Constitutional Violations Detected ({violations.length})
              </div>
              <div className="space-y-2 max-h-48 overflow-y-auto pr-2">
                {violations.slice(0, 3).map((v) => (
                  <div 
                    key={v.id} 
                    className="text-xs bg-gray-800/50 p-2 rounded border-l-2 border-amber-500/50"
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <div className="text-amber-300">{v.message}</div>
                        <div className="text-[10px] text-gray-500 mt-0.5">
                          Line {v.location.start.line}, Column {v.location.start.column}
                        </div>
                      </div>
                      {v.fix && (
                        <button
                          onClick={() => onFixApplied?.(v.id, '')}
                          className="ml-2 p-1 hover:bg-amber-500/20 rounded transition-colors"
                          title={v.fix.description}
                        >
                          <Lightbulb className="w-3 h-3 text-amber-400" />
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
              {violations.length > 3 && (
                <div className="text-[10px] text-gray-600 mt-2">
                  +{violations.length - 3} more violations
                </div>
              )}
            </div>
            <button
              onClick={() => document.dispatchEvent(new Event('guardian-dismiss'))}
              className="p-1 hover:bg-gray-800 rounded transition-colors"
              title="Dismiss"
            >
              <X className="w-4 h-4 text-gray-500" />
            </button>
          </>
        )}
      </div>
    </div>
  );
};
