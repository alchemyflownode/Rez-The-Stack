'use client';
import { useState } from 'react';

export default function FastAI() {
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);

  const ask = async () => {
    setLoading(true);
    const res = await fetch('/api/gpu-kernel', {
      method: 'POST',
      body: JSON.stringify({ task: prompt })
    });
    const data = await res.json();
    setResponse(data.response);
    setLoading(false);
  };

  return (
    <div className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Fast AI (RTX 3060)</h1>
      <textarea 
        className="w-full p-2 border rounded mb-2"
        rows={3}
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        placeholder="Ask anything..."
      />
      <button 
        onClick={ask}
        disabled={loading}
        className="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
      >
        {loading ? 'Thinking...' : 'Ask'}
      </button>
      {response && (
        <div className="mt-4 p-4 bg-gray-100 rounded">
          <p className="whitespace-pre-wrap">{response}</p>
        </div>
      )}
    </div>
  );
}
