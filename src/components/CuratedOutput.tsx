'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CodeOutput, Copy, Trash2, Play, FileCode, Check, Clock, Brain } from 'lucide-react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';

interface OutputMetadata {
  lines: number;
  compliance: number;
  generatedAt: string;
  model: string;
}

interface CuratedOutputProps {
  code: string;
  metadata: OutputMetadata;
  onClear: () => void;
  onRun: () => void;
}

export function CuratedOutput({
  code,
  metadata,
  onClear,
  onRun,
}: CuratedOutputProps) {
  const [copied, setCopied] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <Card className="glass-card">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg font-semibold text-foreground flex items-center gap-2">
            <FileCode className="w-5 h-5 text-primary" />
            CURATED OUTPUT
          </CardTitle>
          <Badge className="badge-success text-xs gap-1">
            <Check className="w-3 h-3" />
            Zero-Drift Compliant
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Action Buttons */}
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleCopy}
            className="border-border hover:bg-primary/20 hover:text-primary"
          >
            {copied ? (
              <>
                <Check className="w-4 h-4 mr-1" />
                Copied
              </>
            ) : (
              <>
                <Copy className="w-4 h-4 mr-1" />
                Copy
              </>
            )}
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={onClear}
            className="border-border hover:bg-orange-500/20 hover:text-orange-400"
          >
            <Trash2 className="w-4 h-4 mr-1" />
            Clear
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={onRun}
            className="border-border hover:bg-cyan-500/20 hover:text-cyan-400"
          >
            <Play className="w-4 h-4 mr-1" />
            Run
          </Button>
        </div>

        {/* Code Block */}
        <div className="code-block overflow-hidden rounded-lg">
          <div className="max-h-96 overflow-y-auto">
            <SyntaxHighlighter
              language="typescript"
              style={vscDarkPlus}
              customStyle={{
                margin: 0,
                padding: '1rem',
                background: 'rgba(0, 0, 0, 0.4)',
                fontSize: '0.875rem',
                lineHeight: '1.5',
              }}
              showLineNumbers
            >
              {code}
            </SyntaxHighlighter>
          </div>
        </div>

        {/* Metadata Footer - Fixed Hydration Mismatch */}
        <div className="flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
          <div className="flex items-center gap-1.5">
            <FileCode className="w-3.5 h-3.5" />
            <span>Lines: {metadata.lines}</span>
          </div>
          <div className="flex items-center gap-1.5">
            <Check className="w-3.5 h-3.5 text-green-500" />
            <span>Compliance: {metadata.compliance}%</span>
          </div>
          <div className="flex items-center gap-1.5">
            <Clock className="w-3.5 h-3.5" />
            {/* Fix: Only render timestamp on client with suppressHydrationWarning */}
            <span suppressHydrationWarning>
              {mounted ? `Generated ${metadata.generatedAt}` : 'Generating...'}
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <Brain className="w-3.5 h-3.5 text-primary" />
            <span>Model: {metadata.model}</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
