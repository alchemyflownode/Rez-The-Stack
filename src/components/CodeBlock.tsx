'use client';

import { useState, useEffect } from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { Check, Copy, Download, Maximize2 } from 'lucide-react';

interface CodeBlockProps {
  language: string;
  code: string;
}

export const CodeBlock = ({ language, code }: CodeBlockProps) => {
  const [copied, setCopied] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const lineCount = code.split('\n').length;

  // Escape key to close fullscreen
  useEffect(() => {
    if (!isExpanded) return;

    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setIsExpanded(false);
    };

    window.addEventListener('keydown', handleEscape);
    return () => window.removeEventListener('keydown', handleEscape);
  }, [isExpanded]);

  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  const downloadCode = () => {
    const extensions: Record<string, string> = {
      javascript: 'js',
      typescript: 'ts',
      python: 'py',
      bash: 'sh',
      powershell: 'ps1',
      json: 'json',
      yaml: 'yml',
      html: 'html',
      css: 'css',
      scss: 'scss',
      rust: 'rs',
      go: 'go',
      java: 'java',
      cpp: 'cpp',
      c: 'c',
      php: 'php',
      sql: 'sql',
      markdown: 'md',
    };

    const ext = extensions[normalizedLang] || language || 'txt';
    const filename = `code.${ext}`;

    const element = document.createElement('a');
    const file = new Blob([code], { type: 'text/plain' });
    element.href = URL.createObjectURL(file);
    element.download = filename;
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
    URL.revokeObjectURL(element.href);
  };

  // Map common language aliases
  const languageMap: Record<string, string> = {
    'js': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'jsx': 'javascript',
    'py': 'python',
    'rb': 'ruby',
    'sh': 'bash',
    'bash': 'bash',
    'ps1': 'powershell',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'html': 'html',
    'css': 'css',
    'scss': 'scss',
    'sql': 'sql',
    'go': 'go',
    'rs': 'rust',
    'rust': 'rust',
    'java': 'java',
    'c': 'c',
    'cpp': 'cpp',
    'c++': 'cpp',
    'php': 'php',
    'md': 'markdown',
    'markdown': 'markdown',
  };

  const normalizedLang = languageMap[language?.toLowerCase()] || language || 'text';

  const langColors: Record<string, string> = {
    javascript: 'from-yellow-500 to-yellow-600',
    typescript: 'from-blue-500 to-blue-600',
    python: 'from-blue-400 to-cyan-500',
    bash: 'from-green-500 to-green-600',
    powershell: 'from-purple-500 to-purple-600',
    json: 'from-orange-500 to-orange-600',
    html: 'from-red-500 to-red-600',
    css: 'from-pink-500 to-pink-600',
    rust: 'from-orange-600 to-red-600',
    go: 'from-cyan-400 to-blue-500',
    java: 'from-red-600 to-orange-500',
    sql: 'from-blue-600 to-indigo-600',
    markdown: 'from-gray-500 to-gray-600',
    scss: 'from-pink-600 to-purple-600',
    php: 'from-indigo-500 to-purple-500',
    c: 'from-blue-700 to-blue-800',
    cpp: 'from-blue-600 to-purple-600',
  };

  const bgGradient = langColors[normalizedLang] || 'from-cyan-500 to-blue-500';

  return (
    <>
      {/* Backdrop */}
      {isExpanded && (
        <div
          className="fixed inset-0 bg-black/80 backdrop-blur-sm z-40 animate-in fade-in duration-200"
          onClick={() => setIsExpanded(false)}
        />
      )}

      {/* Code Block */}
      <div
        className={`relative group my-4 rounded-xl overflow-hidden border border-white/10 shadow-2xl transition-all ${
          isExpanded ? 'fixed inset-4 z-50 max-h-[90vh] flex flex-col animate-in zoom-in-95 duration-200' : ''
        } backdrop-blur-sm bg-gradient-to-br from-black/80 to-zinc-900/80 hover:border-white/20`}
      >
        {/* Enhanced Header */}
        <div className="flex items-center justify-between px-4 py-3 bg-gradient-to-r from-slate-800/50 to-slate-900/50 border-b border-white/10 backdrop-blur-sm">
          <div className="flex items-center gap-3">
            <span
              className={`text-xs font-semibold uppercase tracking-wider px-3 py-1 rounded-lg bg-gradient-to-r ${bgGradient} text-white shadow-lg`}
            >
              {normalizedLang}
            </span>
            <span className="text-xs text-white/40 font-mono">
              {lineCount} {lineCount === 1 ? 'line' : 'lines'}
            </span>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-1.5">
            <button
              onClick={downloadCode}
              className="flex items-center gap-1.5 px-2 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 transition-all text-xs font-medium text-white/60 hover:text-white/80 border border-white/5 hover:border-white/10"
              title="Download code"
            >
              <Download size={13} />
            </button>

            {!isExpanded && (
              <button
                onClick={() => setIsExpanded(true)}
                className="flex items-center gap-1.5 px-2 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 transition-all text-xs font-medium text-white/60 hover:text-white/80 border border-white/5 hover:border-white/10"
                title="Expand fullscreen (Esc to close)"
              >
                <Maximize2 size={13} />
              </button>
            )}

            <button
              onClick={copyToClipboard}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg font-medium transition-all text-xs border ${
                copied
                  ? 'bg-green-500/20 border-green-500/50 text-green-400'
                  : 'bg-cyan-500/10 border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/20 hover:border-cyan-500/50'
              }`}
            >
              {copied ? (
                <>
                  <Check size={13} />
                  <span>Copied!</span>
                </>
              ) : (
                <>
                  <Copy size={13} />
                  <span>Copy</span>
                </>
              )}
            </button>

            {isExpanded && (
              <button
                onClick={() => setIsExpanded(false)}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 transition-all text-xs font-medium text-white/60 hover:text-white/80 border border-white/5 hover:border-white/10 ml-2"
                title="Close (Esc)"
              >
                <span>✕</span>
              </button>
            )}
          </div>
        </div>

        {/* Syntax Highlighter with Better Styling */}
        <div
          className={`flex-1 overflow-auto custom-scrollbar ${
            isExpanded ? '' : 'max-h-96'
          }`}
        >
          <SyntaxHighlighter
            language={normalizedLang}
            style={vscDarkPlus}
            customStyle={{
              margin: 0,
              padding: '1.5rem',
              background: 'transparent',
              fontSize: '0.9rem',
              lineHeight: '1.7',
              fontFamily: '"JetBrains Mono", "Fira Code", "Consolas", monospace',
            }}
            wrapLines={true}
            wrapLongLines={true}
            showLineNumbers={lineCount >= 3}
            lineNumberStyle={{
              color: '#6b7280',
              backgroundColor: 'transparent',
              paddingRight: '1rem',
              userSelect: 'none',
              minWidth: '3em',
            }}
          >
            {code}
          </SyntaxHighlighter>
        </div>

        {/* Bottom gradient fade - only if scrollable */}
        {!isExpanded && lineCount > 20 && (
          <div className="absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-black via-black/50 to-transparent pointer-events-none" />
        )}
      </div>
    </>
  );
};