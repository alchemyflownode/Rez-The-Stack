'use client';

import React, { useState, useEffect } from 'react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Brain, Cpu, Sparkles, Zap, Shield } from 'lucide-react';
import { ecosystem } from '@/services/EcosystemBridge';

interface Model {
  name: string;
  size: string;
  modified: string;
  quantization?: string;
}

interface ModelSelectorProps {
  currentModel: string;
  onModelChange: (model: string) => void;
}

export function ModelSelector({ currentModel, onModelChange }: { currentModel: string; onModelChange: (model: string) => void }) {  // JARVIS API Integration
  useEffect(() => {
    const fetchJarvisModels = async () => {
      try {
        const response = await fetch('http://localhost:8002/issues');
        const data = await response.json();
        // Enhance model display with JARVIS data
        console.log(`🤖 JARVIS API: ${data.total} fixable issues detected`);
      } catch (error) {
        console.warn('JARVIS API not available');
      }
    };
    fetchJarvisModels();
  }, []);
  // Use props or fallback
  const [models, setModels] = useState<Model[]>([]);
  const [loading, setLoading] = useState(true);
  const [category, setCategory] = useState<'all' | 'sovereign' | 'coder' | 'small' | 'vision'>('all');

  // Fetch available models from Ollama
  useEffect(() => {
    const fetchModels = async () => {
  try {
    // Try to connect to Ollama
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3000); // 3 second timeout
    
    try {
      const response = await fetch('http://localhost:11434/api/tags', {
        signal: controller.signal
      });
      clearTimeout(timeoutId);
      
      if (response.ok) {
        const data = await response.json();
        setModels(data.models || []);
      } else {
        throw new Error(`Ollama returned ${response.status}`);
      }
    } catch (fetchError) {
      clearTimeout(timeoutId);
      throw fetchError;
    }
  } catch (error) {
    console.warn('🦊 Ollama not running - using fallback models');
    // Fallback to mock models for development
    setModels([
      { name: 'llama3.2:latest', size: '4.7 GB', modified: new Date().toISOString() },
      { name: 'phi4:latest', size: '9.1 GB', modified: new Date().toISOString() },
      { name: 'deepseek-coder:latest', size: '776 MB', modified: new Date().toISOString() },
      { name: 'qwen2.5-coder:7b', size: '4.7 GB', modified: new Date().toISOString() },
      { name: 'codellama:7b', size: '3.8 GB', modified: new Date().toISOString() },
      { name: 'llama3.2:1b', size: '1.3 GB', modified: new Date().toISOString() },
    ]);
  } finally {
    setLoading(false);
  }
};

    fetchModels();
    const interval = setInterval(fetchModels, 30000);
    return () => clearInterval(interval);
  }, []);

  // Categorize models
  const getModelCategory = (modelName: string) => {
    const name = modelName.toLowerCase();
    if (name.includes('sovereign') || name.includes('constitutional')) return 'sovereign';
    if (name.includes('coder') || name.includes('deepseek') || name.includes('codellama')) return 'coder';
    if (name.includes('vision') || name.includes('llava') || name.includes('moondream')) return 'vision';
    if (name.includes('1b') || name.includes('3b') || name.includes('phi')) return 'small';
    return 'all';
  };

  // Get model icon
  const getModelIcon = (modelName: string) => {
    const category = getModelCategory(modelName);
    switch (category) {
      case 'sovereign': return <Shield className="w-4 h-4 text-purple-400" />;
      case 'coder': return <Cpu className="w-4 h-4 text-cyan-400" />;
      case 'vision': return <Sparkles className="w-4 h-4 text-green-400" />;
      case 'small': return <Zap className="w-4 h-4 text-yellow-400" />;
      default: return <Brain className="w-4 h-4 text-primary" />;
    }
  };

  // Filter models by category
  const filteredModels = models.filter(model => 
    category === 'all' || getModelCategory(model.name) === category
  );

  // Group models by type
  const sovereignModels = models.filter(m => getModelCategory(m.name) === 'sovereign');
  const coderModels = models.filter(m => getModelCategory(m.name) === 'coder');
  const visionModels = models.filter(m => getModelCategory(m.name) === 'vision');
  const smallModels = models.filter(m => getModelCategory(m.name) === 'small');
  const otherModels = models.filter(m => getModelCategory(m.name) === 'all');

  return (
    <div data-testid="modelselector-main"  className="space-y-2">
      <div data-testid="modelselector-main"  className="flex items-center justify-between">
        <div data-testid="modelselector-main"  className="flex items-center gap-2">
          <Brain className="w-4 h-4 text-primary" />
          <span className="text-sm font-medium">Neural Engine</span>
        </div>
        {loading ? (
          <Badge variant="outline" className="badge-cyan text-xs">
            Loading...
          </Badge>
        ) : (
          <Badge variant="outline" className="badge-success text-xs">
            {models.length} Models
          </Badge>
        )}
      </div>

      {/* Category Pills */}
      <div data-testid="modelselector-main"  className="flex flex-wrap gap-1 pb-1">
        <button
          onClick={() => setCategory('all')}
          className={`px-2 py-1 text-xs rounded-full transition-all ${
            category === 'all'
              ? 'bg-primary/20 text-primary border border-primary/30'
              : 'bg-muted/50 text-muted-foreground hover:bg-muted'
          }`}
        >
          All ({models.length})
        </button>
        {sovereignModels.length > 0 && (
          <button
            onClick={() => setCategory('sovereign')}
            className={`px-2 py-1 text-xs rounded-full transition-all ${
              category === 'sovereign'
                ? 'bg-purple-500/20 text-purple-400 border border-purple-500/30'
                : 'bg-muted/50 text-muted-foreground hover:bg-muted'
            }`}
          >
            🏛️ Sovereign ({sovereignModels.length})
          </button>
        )}
        {coderModels.length > 0 && (
          <button
            onClick={() => setCategory('coder')}
            className={`px-2 py-1 text-xs rounded-full transition-all ${
              category === 'coder'
                ? 'bg-cyan-500/20 text-cyan-400 border border-cyan-500/30'
                : 'bg-muted/50 text-muted-foreground hover:bg-muted'
            }`}
          >
            🤖 Coder ({coderModels.length})
          </button>
        )}
        {visionModels.length > 0 && (
          <button
            onClick={() => setCategory('vision')}
            className={`px-2 py-1 text-xs rounded-full transition-all ${
              category === 'vision'
                ? 'bg-green-500/20 text-green-400 border border-green-500/30'
                : 'bg-muted/50 text-muted-foreground hover:bg-muted'
            }`}
          >
            👁️ Vision ({visionModels.length})
          </button>
        )}
        {smallModels.length > 0 && (
          <button
            onClick={() => setCategory('small')}
            className={`px-2 py-1 text-xs rounded-full transition-all ${
              category === 'small'
                ? 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/30'
                : 'bg-muted/50 text-muted-foreground hover:bg-muted'
            }`}
          >
            ⚡ Fast ({smallModels.length})
          </button>
        )}
      </div>

      {/* Model Selector */}
      <Select value={currentModel} onValueChange={onModelChange}>
        <SelectTrigger className="w-full bg-black/40 border-purple-500/30 focus:ring-purple-500/50">
          <SelectValue placeholder="Select a model" />
        </SelectTrigger>
        <SelectContent className="bg-gray-950 dark:bg-gray-950 border-purple-500/30 max-h-[300px]">
          {/* Sovereign Models */}
          {filteredModels.filter(m => getModelCategory(m.name) === 'sovereign').length > 0 && (
            <>
              <div data-testid="modelselector-main"  className="px-2 py-1.5 text-xs font-semibold text-purple-400 bg-purple-500/10">
                🏛️ SOVEREIGN COUNCIL
              </div>
              {filteredModels
                .filter(m => getModelCategory(m.name) === 'sovereign')
                .map(model => (
                  <SelectItem key={model.name} value={model.name} className="focus:bg-purple-500/20">
                    <div data-testid="modelselector-main"  className="flex items-center gap-2">
                      {getModelIcon(model.name)}
                      <span className="font-mono text-sm">{model.name}</span>
                      <span className="text-xs text-muted-foreground">
                        {model.size}
                      </span>
                    </div>
                  </SelectItem>
                ))
              }
            </>
          )}

          {/* Coder Models */}
          {filteredModels.filter(m => getModelCategory(m.name) === 'coder').length > 0 && (
            <>
              <div data-testid="modelselector-main"  className="px-2 py-1.5 text-xs font-semibold text-cyan-400 bg-cyan-500/10 mt-1">
                🤖 CODE ARCHITECTS
              </div>
              {filteredModels
                .filter(m => getModelCategory(m.name) === 'coder')
                .map(model => (
                  <SelectItem key={model.name} value={model.name} className="focus:bg-cyan-500/20">
                    <div data-testid="modelselector-main"  className="flex items-center gap-2">
                      {getModelIcon(model.name)}
                      <span className="font-mono text-sm">{model.name}</span>
                      <span className="text-xs text-muted-foreground">
                        {model.size}
                      </span>
                    </div>
                  </SelectItem>
                ))
              }
            </>
          )}

          {/* Vision Models */}
          {filteredModels.filter(m => getModelCategory(m.name) === 'vision').length > 0 && (
            <>
              <div data-testid="modelselector-main"  className="px-2 py-1.5 text-xs font-semibold text-green-400 bg-green-500/10 mt-1">
                👁️ VISION INTELLECT
              </div>
              {filteredModels
                .filter(m => getModelCategory(m.name) === 'vision')
                .map(model => (
                  <SelectItem key={model.name} value={model.name} className="focus:bg-green-500/20">
                    <div data-testid="modelselector-main"  className="flex items-center gap-2">
                      {getModelIcon(model.name)}
                      <span className="font-mono text-sm">{model.name}</span>
                      <span className="text-xs text-muted-foreground">
                        {model.size}
                      </span>
                    </div>
                  </SelectItem>
                ))
              }
            </>
          )}

          {/* Fast/Small Models */}
          {filteredModels.filter(m => getModelCategory(m.name) === 'small').length > 0 && (
            <>
              <div data-testid="modelselector-main"  className="px-2 py-1.5 text-xs font-semibold text-yellow-400 bg-yellow-500/10 mt-1">
                ⚡ LIGHTNING FAST
              </div>
              {filteredModels
                .filter(m => getModelCategory(m.name) === 'small')
                .map(model => (
                  <SelectItem key={model.name} value={model.name} className="focus:bg-yellow-500/20">
                    <div data-testid="modelselector-main"  className="flex items-center gap-2">
                      {getModelIcon(model.name)}
                      <span className="font-mono text-sm">{model.name}</span>
                      <span className="text-xs text-muted-foreground">
                        {model.size}
                      </span>
                    </div>
                  </SelectItem>
                ))
              }
            </>
          )}

          {/* Other Models */}
          {filteredModels.filter(m => getModelCategory(m.name) === 'all').length > 0 && (
            <>
              <div data-testid="modelselector-main"  className="px-2 py-1.5 text-xs font-semibold text-primary/70 bg-primary/10 mt-1">
                🧠 GENERAL INTELLIGENCE
              </div>
              {filteredModels
                .filter(m => getModelCategory(m.name) === 'all')
                .map(model => (
                  <SelectItem key={model.name} value={model.name} className="focus:bg-primary/20">
                    <div data-testid="modelselector-main"  className="flex items-center gap-2">
                      {getModelIcon(model.name)}
                      <span className="font-mono text-sm">{model.name}</span>
                      <span className="text-xs text-muted-foreground">
                        {model.size}
                      </span>
                    </div>
                  </SelectItem>
                ))
              }
            </>
          )}

          {filteredModels.length === 0 && !loading && (
            <div data-testid="modelselector-main"  className="px-2 py-4 text-center text-sm text-muted-foreground">
              No models found. Is Ollama running?
            </div>
          )}
        </SelectContent>
      </Select>

      {/* Current Model Badge */}
      {currentModel && (
        <div data-testid="modelselector-main"  className="flex items-center gap-1 pt-1">
          <Badge variant="outline" className="badge-purple text-[10px] px-1.5 py-0">
            {getModelIcon(currentModel)}
            <span className="ml-1">{currentModel}</span>
          </Badge>
        </div>
      )}
    </div>
  );
}





