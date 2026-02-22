'use client';

import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import {
  Brain, Zap, RefreshCw, CheckCircle, AlertTriangle,
  Layers, Play, Square, Settings,
  Database, Terminal, Cpu, HardDrive, Wifi
} from 'lucide-react';

interface ChainProgress {
  type: 'progress' | 'complete' | 'error';
  iteration?: number;
  layer?: string;
  confidence?: number;
  isComplete?: boolean;
  latestThought?: string;
  result?: any;
  error?: string;
}

function CognitiveKernel() {
  const [task, setTask] = useState('');
  const [maxIterations, setMaxIterations] = useState(10);
  const [isRunning, setIsRunning] = useState(false);
  const [progress, setProgress] = useState<ChainProgress | null>(null);
  const [result, setResult] = useState<any>(null);
  const [patterns, setPatterns] = useState<any[]>([]);
  const [ollamaStatus, setOllamaStatus] = useState<'checking' | 'connected' | 'disconnected'>('checking');
  const [ollamaUrl] = useState('http://localhost:11434');
  const [systemStats, setSystemStats] = useState({
    cpu: '12%',
    memory: '4.2/16GB',
    uptime: '2h 14m'
  });
  const [powershellCommand, setPowershellCommand] = useState('');
  const [powershellOutput, setPowershellOutput] = useState('');
  const [powershellLoading, setPowershellLoading] = useState(false);

  // Check Ollama status
  const checkOllama = useCallback(async () => {
    setOllamaStatus('checking');
    try {
      const res = await fetch('/api/kernel', { method: 'GET' });
      if (res.ok) {
        setOllamaStatus('connected');
      } else {
        setOllamaStatus('disconnected');
      }
    } catch {
      setOllamaStatus('disconnected');
    }
  }, []);

  // Fetch patterns
  const fetchPatterns = useCallback(async () => {
    try {
      const res = await fetch('/api/kernel');
      const text = await res.text();
      if (!text) return;
      const data = JSON.parse(text);
      if (data.success && Array.isArray(data.patterns)) {
        setPatterns(data.patterns);
      }
    } catch (error) {
      console.error('Failed to fetch patterns:', error);
    }
  }, []);

  useEffect(() => {
    checkOllama();
    fetchPatterns();
    
    const interval = setInterval(() => {
      setSystemStats({
        cpu: Math.floor(Math.random() * 30 + 5) + '%',
        memory: (Math.random() * 2 + 3.5).toFixed(1) + '/16GB',
        uptime: '2h ' + Math.floor(Math.random() * 60) + 'm'
      });
    }, 5000);
    
    return () => clearInterval(interval);
  }, [checkOllama, fetchPatterns]);

  // Run PowerShell command
  const runPowerShell = async () => {
    if (!powershellCommand.trim() || powershellLoading) return;
    
    setPowershellLoading(true);
    setPowershellOutput('');
    
    try {
      const res = await fetch('/api/powershell', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command: powershellCommand })
      });
      const data = await res.json();
      setPowershellOutput(data.output || data.error || 'No output');
    } catch (error: any) {
      setPowershellOutput('Error: ' + error.message);
    } finally {
      setPowershellLoading(false);
    }
  };

  // Run chain
  const runChain = async () => {
    if (!task.trim() || isRunning) return;

    setIsRunning(true);
    setResult(null);
    setProgress(null);

    try {
      const res = await fetch('/api/kernel', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task, maxIterations })
      });

      const reader = res.body?.getReader();
      const decoder = new TextDecoder();

      if (!reader) return;

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));
              setProgress(data);
              if (data.type === 'complete') {
                setResult(data.result);
                fetchPatterns();
              }
            } catch (e) {}
          }
        }
      }
    } catch (error) {
      setProgress({ type: 'error', error: String(error) });
    }
    setIsRunning(false);
  };

  const layerColors: Record<string, string> = {
    surface: 'bg-yellow-500/20 text-yellow-400 border-yellow-500',
    middle: 'bg-blue-500/20 text-blue-400 border-blue-500',
    root: 'bg-emerald-500/20 text-emerald-400 border-emerald-500'
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-950 via-gray-900 to-gray-950 text-gray-100 font-sans">
      {/* Windows-style title bar */}
      <div className="bg-gray-800 border-b border-gray-700 px-4 py-2 flex items-center justify-between text-sm select-none">
        <div className="flex items-center gap-2">
          <Brain className="w-4 h-4 text-purple-400" />
          <span className="font-semibold">Cognitive Kernel v1.0</span>
          <span className="text-gray-500">â€¢</span>
          <span className="text-gray-400">DESKTOP-REZHIVE</span>
        </div>
        <div className="flex items-center gap-3">
          <Badge variant="outline" className={`border-0 ${
            ollamaStatus === 'connected' ? 'text-emerald-400' : 'text-red-400'
          }`}>
            <Wifi className="w-3 h-3 mr-1" />
            Ollama
          </Badge>
          <Badge variant="outline" className="border-0 text-blue-400">
            <Database className="w-3 h-3 mr-1" />
            {patterns.length} patterns
          </Badge>
          <div className="w-6 h-6 rounded-full bg-gray-700 flex items-center justify-center text-xs">
            <Cpu className="w-3 h-3" />
          </div>
        </div>
      </div>

      {/* Main layout */}
      <div className="flex h-[calc(100vh-41px)]">
        {/* Left sidebar */}
        <div className="w-72 bg-gray-900 border-r border-gray-800 p-4 flex flex-col gap-4 overflow-y-auto">
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="p-3">
              <CardTitle className="text-xs font-medium text-gray-400 flex items-center gap-1">
                <HardDrive className="w-3 h-3" />
                SYSTEM
              </CardTitle>
            </CardHeader>
            <CardContent className="p-3 pt-0 space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-gray-500">CPU</span>
                <span>{systemStats.cpu}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Memory</span>
                <span>{systemStats.memory}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Uptime</span>
                <span>{systemStats.uptime}</span>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gray-800 border-gray-700 flex-1">
            <CardHeader className="p-3">
              <CardTitle className="text-xs font-medium text-gray-400 flex items-center gap-1">
                <Database className="w-3 h-3" />
                PATTERN MEMORY
              </CardTitle>
            </CardHeader>
            <CardContent className="p-3 pt-0">
              <ScrollArea className="h-[300px]">
                {patterns.length > 0 ? (
                  <div className="space-y-2">
                    {patterns.map((p, i) => (
                      <div key={i} className="p-2 bg-gray-700/30 rounded text-xs">
                        <div className="font-mono text-purple-400">{p.name}</div>
                        <div className="text-gray-500 mt-1 line-clamp-2">{p.description}</div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-gray-600 text-xs text-center py-4">
                    No patterns yet
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>

          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="p-3">
              <CardTitle className="text-xs font-medium text-gray-400 flex items-center gap-1">
                <Terminal className="w-3 h-3" />
                POWERSHELL
              </CardTitle>
            </CardHeader>
            <CardContent className="p-3 pt-0">
              <Input
                value={powershellCommand}
                onChange={(e) => setPowershellCommand(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && runPowerShell()}
                placeholder="Get-Process | Select-Object -First 5"
                className="bg-gray-900 border-gray-700 text-xs font-mono h-8"
              />
              <Button 
                onClick={runPowerShell}
                disabled={powershellLoading || !powershellCommand.trim()}
                size="sm"
                className="w-full mt-2 h-7 text-xs"
              >
                {powershellLoading ? 'Running...' : 'Execute'}
              </Button>
              {powershellOutput && (
                <div className="mt-2 p-2 bg-gray-900 rounded border border-gray-700 max-h-32 overflow-auto">
                  <pre className="text-xs text-green-400 font-mono whitespace-pre-wrap break-all">
                    {powershellOutput}
                  </pre>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Main content */}
        <div className="flex-1 flex flex-col p-4 gap-4 overflow-y-auto">
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="p-4">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <Terminal className="w-4 h-4 text-purple-400" />
                TASK INPUT
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4 pt-0">
              <Textarea
                placeholder="What root do you seek? (e.g., 'What is the root of creative flow?')"
                value={task}
                onChange={(e) => setTask(e.target.value)}
                className="bg-gray-900 border-gray-700 text-sm font-mono h-24"
                disabled={isRunning}
              />
              <div className="flex items-center justify-between mt-4">
                <div className="flex items-center gap-4">
                  <label className="text-xs text-gray-500">Iterations:</label>
                  <Input
                    type="number"
                    value={maxIterations}
                    onChange={(e) => setMaxIterations(Number(e.target.value))}
                    className="w-20 bg-gray-900 border-gray-700 text-sm h-8"
                    min={1}
                    max={50}
                    disabled={isRunning}
                  />
                </div>
                {isRunning ? (
                  <Button onClick={() => setIsRunning(false)} variant="destructive" size="sm">
                    <Square className="w-4 h-4 mr-2" />
                    STOP
                  </Button>
                ) : (
                  <Button onClick={runChain} disabled={!task.trim()} size="sm">
                    <Play className="w-4 h-4 mr-2" />
                    RUN CHAIN
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gray-800 border-gray-700 flex-1">
            <CardHeader className="p-4">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                {isRunning ? (
                  <RefreshCw className="w-4 h-4 text-purple-400 animate-spin" />
                ) : result?.isComplete ? (
                  <CheckCircle className="w-4 h-4 text-emerald-400" />
                ) : (
                  <Layers className="w-4 h-4 text-gray-400" />
                )}
                {isRunning ? 'THINKING...' : result?.isComplete ? 'COMPLETE' : 'CHAIN PROGRESS'}
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4 pt-0">
              {progress || result ? (
                <div className="space-y-4">
                  {progress?.type === 'progress' && (
                    <>
                      <div className="flex justify-between text-xs">
                        <span className="text-gray-500">Iteration {progress.iteration}/{maxIterations}</span>
                        <span className="text-gray-500">Confidence {((progress.confidence || 0) * 100).toFixed(0)}%</span>
                      </div>
                      <Progress value={((progress.iteration || 0) / maxIterations) * 100} className="h-1" />
                      <Badge className={layerColors[progress.layer || 'surface']}>
                        {progress.layer}
                      </Badge>
                    </>
                  )}

                  {progress?.latestThought && (
                    <div className="p-3 bg-gray-900 rounded border border-gray-700">
                      <div className="text-xs font-mono text-gray-300 whitespace-pre-wrap break-all">
                        {progress.latestThought}
                      </div>
                    </div>
                  )}

                  {result && (
                    <div className="space-y-3">
                      <div className="grid grid-cols-3 gap-3">
                        <div className="p-3 bg-gray-900 rounded">
                          <div className="text-xs text-gray-500">Iterations</div>
                          <div className="text-xl font-mono text-purple-400">{result.iterations}</div>
                        </div>
                        <div className="p-3 bg-gray-900 rounded">
                          <div className="text-xs text-gray-500">Confidence</div>
                          <div className="text-xl font-mono text-emerald-400">{(result.confidence * 100).toFixed(0)}%</div>
                        </div>
                        <div className="p-3 bg-gray-900 rounded">
                          <div className="text-xs text-gray-500">Layer</div>
                          <Badge className={layerColors[result.finalLayer]}>{result.finalLayer}</Badge>
                        </div>
                      </div>

                      {result.rootFound && (
                        <div className="p-3 bg-purple-950/30 border border-purple-800 rounded">
                          <div className="text-xs text-purple-400 mb-1">ROOT DISCOVERED</div>
                          <div className="text-sm font-mono">{result.rootFound}</div>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              ) : (
                <div className="h-32 flex items-center justify-center text-gray-700 text-sm">
                  Ready. Enter a task.
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

export default CognitiveKernel;

