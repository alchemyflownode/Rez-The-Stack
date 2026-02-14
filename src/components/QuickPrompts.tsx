'use client';

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  Code2, 
  Server, 
  Database, 
  TestTube, 
  AlertTriangle,
  FileCode,
  Layers
} from 'lucide-react';

export interface QuickPrompt {
  id: string;
  title: string;
  description: string;
  prompt: string;
  icon: React.ReactNode;
  category: string;
}

interface QuickPromptsProps {
  onPromptSelect: (prompt: QuickPrompt) => void;
}

const prompts: QuickPrompt[] = [
  {
    id: 'react-component',
    title: 'React Component',
    description: 'Create a TypeScript React component for a user profile card...',
    prompt: 'Create a TypeScript React component for a user profile card with avatar, name, bio, and social links. Include proper TypeScript interfaces and Tailwind CSS styling.',
    icon: <Code2 className="w-5 h-5" />,
    category: 'Frontend',
  },
  {
    id: 'api-endpoint',
    title: 'API Endpoint',
    description: 'Write a Node.js Express API endpoint for user authentication...',
    prompt: 'Write a Node.js Express API endpoint for user authentication with JWT tokens. Include input validation, error handling, and proper TypeScript types.',
    icon: <Server className="w-5 h-5" />,
    category: 'Backend',
  },
  {
    id: 'database-schema',
    title: 'Database Schema',
    description: 'Create a Prisma schema for a blog with Users, Posts...',
    prompt: 'Create a Prisma schema for a blog application with Users, Posts, Comments, and Categories. Include proper relations and indexes.',
    icon: <Database className="w-5 h-5" />,
    category: 'Database',
  },
  {
    id: 'test-suite',
    title: 'Test Suite',
    description: 'Write Jest unit tests for a React hook that manages form state...',
    prompt: 'Write Jest unit tests for a React hook that manages form state with validation and submission. Include edge cases and mock implementations.',
    icon: <TestTube className="w-5 h-5" />,
    category: 'Testing',
  },
  {
    id: 'zero-drift-test',
    title: 'Zero-Drift Test',
    description: 'Write a function that incorrectly uses lodash cloneDeep...',
    prompt: 'Write a function that incorrectly uses lodash cloneDeep for state management, creating a Zero-Drift violation. Then explain the issue and fix it.',
    icon: <AlertTriangle className="w-5 h-5" />,
    category: 'Analysis',
  },
];

export function QuickPrompts({ onPromptSelect }: QuickPromptsProps) {
  const getCategoryColor = (category: string) => {
    const colors: Record<string, string> = {
      Frontend: 'badge-purple',
      Backend: 'badge-cyan',
      Database: 'badge-success',
      Testing: 'badge-warning',
      Analysis: 'bg-red-500/20 text-red-400 border-red-500/30',
    };
    return colors[category] || 'badge-cyan';
  };

  return (
    <Card className="glass-card">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg font-semibold text-foreground flex items-center gap-2">
          <Layers className="w-5 h-5 text-primary" />
          Quick Prompts
        </CardTitle>
        <p className="text-xs text-muted-foreground">
          Click a card to populate the input area
        </p>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
          {prompts.map((prompt) => (
            <div
              key={prompt.id}
              onClick={() => onPromptSelect(prompt)}
              className="prompt-card glass-card p-4 rounded-lg border border-border group"
            >
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-lg bg-primary/10 text-primary group-hover:bg-primary/20 transition-smooth">
                  {prompt.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-1">
                    <h4 className="text-sm font-semibold text-foreground truncate">
                      {prompt.title}
                    </h4>
                    <Badge className={`${getCategoryColor(prompt.category)} text-xs ml-2 shrink-0`}>
                      {prompt.category}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted-foreground line-clamp-2">
                    {prompt.description}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

