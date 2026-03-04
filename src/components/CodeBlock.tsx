'use client';

import React from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';

interface CodeBlockProps {
  language: string;
  code: string;
}

export function CodeBlock({ language, code }: CodeBlockProps) {
  return (
    <div className="my-2 rounded-lg overflow-hidden border border-white/10">
      <div className="bg-black/60 px-3 py-1 text-xs text-white/40 font-mono border-b border-white/10">
        {language}
      </div>
      <SyntaxHighlighter
        language={language}
        style={vscDarkPlus}
        customStyle={{
          margin: 0,
          padding: '1rem',
          background: 'rgba(0,0,0,0.3)',
          fontSize: '0.85rem',
        }}
      >
        {code}
      </SyntaxHighlighter>
    </div>
  );
}