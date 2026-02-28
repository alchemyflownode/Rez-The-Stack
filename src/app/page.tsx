'use client';

import { useState } from 'react';
import { ModeToggle } from '@/components/ModeToggle';
import '@/styles/dual-theme.css';

const suggestions = [
  "Write a haiku about sovereignty",
  "Explain quantum computing simply",
  "Create a Python function for fibonacci",
  "What's the meaning of life?",
  "Tell me a story about AI"
];

export default function Home() {
  const [input, setInput] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);

  const ask = async () => {
    if (!input.trim()) return;
    
    setLoading(true);
    try {
      // ✅ FIXED: Using /api/kernel which exists (not /api/gpu-kernel)
      const res = await fetch('/api/kernel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: input })
      });
      const data = await res.json();
      setResponse(data.response || data.content || 'No response');
    } catch (e) {
      setResponse('Error: ' + e);
    }
    setLoading(false);
  };

  return (
    <div className="simple-layout">
      <ModeToggle />
      
      <div className="mode-badge">
        {typeof document !== 'undefined' && document.documentElement.dataset.theme === 'light' 
          ? '🌤 Flow Mode' 
          : '⚡ Builder Mode'}
      </div>
      
      <h1 className="hero-headline">
        {typeof document !== 'undefined' && document.documentElement.dataset.theme === 'light' 
          ? 'Create with clarity' 
          : 'Build with focus'}
      </h1>
      
      {/* Input Container */}
      <div className="input-container">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && ask()}
          placeholder="Ask Sovereign AI..."
          className="input-field"
        />
      </div>
      
      {/* Suggestion Chips */}
      <div className="suggestion-grid">
        {suggestions.map((suggestion, i) => (
          <button
            key={i}
            className="suggestion-chip"
            onClick={() => {
              setInput(suggestion);
              setTimeout(() => ask(), 100);
            }}
          >
            {suggestion}
          </button>
        ))}
      </div>
      
      {/* Response */}
      {response && (
        <div className="response-card">
          {response}
        </div>
      )}
      
      {/* Loading indicator */}
      {loading && (
        <div className="response-card" style={{ opacity: 0.7 }}>
          Thinking...
        </div>
      )}
    </div>
  );
}