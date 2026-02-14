'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Code2, Sparkles, Zap, Shield, CheckCircle } from 'lucide-react';
import type { QuickPrompt } from './QuickPrompts';

interface ArchitecturalInputProps {
  inputValue: string;
  onInputChange: (value: string) => void;
  onSubmit: () => void;
  isGenerating: boolean;
}

export function ArchitecturalInput({
  inputValue,
  onInputChange,
  onSubmit,
  isGenerating,
}: ArchitecturalInputProps) {
  const maxChars = 2000;
  const charCount = inputValue.length;

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
      e.preventDefault();
      onSubmit();
    }
  };

  return (
    <Card className="glass-card">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg font-semibold text-foreground flex items-center gap-2">
          <Code2 className="w-5 h-5 text-primary" />
          Architectural Directive
        </CardTitle>
        <p className="text-xs text-muted-foreground">
          Describe your code architecture requirement
        </p>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Textarea */}
        <div className="relative">
          <Textarea
            value={inputValue}
            onChange={(e) => onInputChange(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Describe your code architecture, component, or analysis request..."
            className="min-h-[120px] bg-input border-border input-glow transition-smooth resize-none font-mono text-sm"
            maxLength={maxChars}
          />
          <div className="absolute bottom-2 right-2 text-xs text-muted-foreground">
            {charCount}/{maxChars} chars
          </div>
        </div>

        {/* Status Badges */}
        <div className="flex flex-wrap gap-2">
          <Badge className="badge-cyan gap-1">
            <Shield className="w-3 h-3" />
            Zero-Drift
          </Badge>
          <Badge className="badge-success gap-1">
            <CheckCircle className="w-3 h-3" />
            Type-Safe
          </Badge>
          <Badge className="badge-purple gap-1">
            <Zap className="w-3 h-3" />
            Production
          </Badge>
        </div>

        {/* Submit Button */}
        <div className="flex items-center justify-between">
          <p className="text-xs text-muted-foreground">
            Press <kbd className="px-1.5 py-0.5 rounded bg-primary/20 text-primary text-xs">Ctrl+Enter</kbd> to generate
          </p>
          <Button
            onClick={onSubmit}
            disabled={isGenerating || !inputValue.trim()}
            className="btn-gradient text-white font-medium px-6"
          >
            {isGenerating ? (
              <>
                <Sparkles className="w-4 h-4 mr-2 animate-pulse" />
                Generating...
              </>
            ) : (
              <>
                <Code2 className="w-4 h-4 mr-2" />
                Architect Code
              </>
            )}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

