'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import { ChevronDown, Folder, Wrench, BookOpen } from 'lucide-react';

export interface Command {
  id: string;
  name: string;
  description: string;
  category: 'filesystem' | 'system' | 'learning';
  difficulty: 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED';
}

interface CommandCategory {
  id: string;
  name: string;
  icon: React.ReactNode;
  commands: Command[];
}

const commandCategories: CommandCategory[] = [
  {
    id: 'filesystem',
    name: 'Filesystem',
    icon: <Folder className="w-4 h-4" />,
    commands: [
      {
        id: 'scan',
        name: 'scan',
        description: 'Scan directory for code analysis and vulnerabilities',
        category: 'filesystem',
        difficulty: 'BEGINNER',
      },
    ],
  },
  {
    id: 'system',
    name: 'System',
    icon: <Wrench className="w-4 h-4" />,
    commands: [
      {
        id: 'analyze',
        name: 'analyze',
        description: 'Deep system analysis for Zero-Drift compliance',
        category: 'system',
        difficulty: 'INTERMEDIATE',
      },
    ],
  },
  {
    id: 'learning',
    name: 'Learning',
    icon: <BookOpen className="w-4 h-4" />,
    commands: [
      {
        id: 'tutorial',
        name: 'tutorial',
        description: 'Interactive tutorial for Sovereign commands',
        category: 'learning',
        difficulty: 'BEGINNER',
      },
    ],
  },
];

interface CommandSidebarProps {
  selectedCategory: string | null;
  onCategorySelect: (categoryId: string) => void;
  selectedDifficulty: 'ALL' | 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED';
}

export function CommandSidebar({
  selectedCategory,
  onCategorySelect,
  selectedDifficulty,
}: CommandSidebarProps) {
  const [expandedCategories, setExpandedCategories] = useState<string[]>(['filesystem', 'system', 'learning']);

  const toggleCategory = (categoryId: string) => {
    setExpandedCategories((prev) =>
      prev.includes(categoryId)
        ? prev.filter((id) => id !== categoryId)
        : [...prev, categoryId]
    );
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'BEGINNER':
        return 'badge-success';
      case 'INTERMEDIATE':
        return 'badge-warning';
      case 'ADVANCED':
        return 'badge-purple';
      default:
        return 'badge-cyan';
    }
  };

  return (
    <Card className="glass-card h-full">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg font-semibold text-foreground flex items-center gap-2">
          <Folder className="w-5 h-5 text-primary" />
          Command Categories
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-2">
        {commandCategories.map((category) => {
          const isExpanded = expandedCategories.includes(category.id);
          const filteredCommands = category.commands.filter(
            (cmd) => selectedDifficulty === 'ALL' || cmd.difficulty === selectedDifficulty
          );

          return (
            <Collapsible
              key={category.id}
              open={isExpanded}
              onOpenChange={() => toggleCategory(category.id)}
            >
              <CollapsibleTrigger asChild>
                <div className="expandable-header flex items-center justify-between p-3 rounded-lg cursor-pointer hover:bg-primary/10 transition-smooth">
                  <div className="flex items-center gap-3">
                    <span className="text-primary">{category.icon}</span>
                    <span className="font-medium text-foreground">{category.name}</span>
                    <Badge className="badge-cyan text-xs">
                      {filteredCommands.length}
                    </Badge>
                  </div>
                  <ChevronDown
                    className={`w-4 h-4 text-muted-foreground transition-transform ${
                      isExpanded ? 'rotate-180' : ''
                    }`}
                  />
                </div>
              </CollapsibleTrigger>
              <CollapsibleContent className="ml-8 mt-2 space-y-1">
                {filteredCommands.map((command) => (
                  <div
                    key={command.id}
                    onClick={() => onCategorySelect(category.id)}
                    className="p-2 rounded-lg cursor-pointer hover:bg-primary/10 transition-smooth group"
                  >
                    <div className="flex items-center justify-between mb-1">
                      <code className="text-sm text-cyan-400 font-mono">
                        {command.name}
                      </code>
                      <Badge className={`${getDifficultyColor(command.difficulty)} text-xs`}>
                        {command.difficulty}
                      </Badge>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {command.description}
                    </p>
                  </div>
                ))}
                {filteredCommands.length === 0 && (
                  <p className="text-xs text-muted-foreground italic p-2">
                    No commands match the selected filter
                  </p>
                )}
              </CollapsibleContent>
            </Collapsible>
          );
        })}
      </CardContent>
    </Card>
  );
}

