'use client';

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Zap, Lightbulb, TrendingUp } from 'lucide-react';

interface VibeJourneyPanelProps {
  level: number;
  xp: number;
  xpToNextLevel: number;
}

export function VibeJourneyPanel({ level, xp, xpToNextLevel }: VibeJourneyPanelProps) {
  const progressPercent = (xp / xpToNextLevel) * 100;
  
  const journeyStages = ['Beginner', 'Apprentice', 'Architect', 'Sovereign'];
  const currentStageIndex = Math.min(Math.floor(level / 3), 3);

  return (
    <Card className="glass-card">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg font-semibold text-foreground flex items-center gap-2">
          <TrendingUp className="w-5 h-5 text-primary" />
          User Vibe Journey
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Level & XP */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Zap className="w-5 h-5 text-yellow-500" />
            <span className="font-semibold text-foreground">
              Level {level}
            </span>
          </div>
          <Badge className="badge-purple text-sm">
            {xp.toLocaleString()} XP
          </Badge>
        </div>

        {/* Progress Bar */}
        <div className="space-y-2">
          <div className="flex justify-between text-xs text-muted-foreground">
            <span>Progress to Level {level + 1}</span>
            <span>{xp} / {xpToNextLevel} XP</span>
          </div>
          <Progress value={progressPercent} className="h-2 bg-primary/20 [&>div]:progress-purple" />
        </div>

        {/* Journey Stages */}
        <div className="space-y-2">
          <p className="text-xs text-muted-foreground mb-2">Your Journey</p>
          <div className="flex items-center justify-between">
            {journeyStages.map((stage, index) => (
              <React.Fragment key={stage}>
                <div
                  className={`flex flex-col items-center ${
                    index <= currentStageIndex ? 'text-primary' : 'text-muted-foreground'
                  }`}
                >
                  <div
                    className={`w-3 h-3 rounded-full mb-1 ${
                      index <= currentStageIndex
                        ? 'bg-primary glow-purple'
                        : 'bg-muted-foreground/30'
                    }`}
                  />
                  <span className="text-xs font-medium">{stage}</span>
                </div>
                {index < journeyStages.length - 1 && (
                  <div
                    className={`flex-1 h-0.5 mx-2 ${
                      index < currentStageIndex ? 'bg-primary' : 'bg-muted-foreground/30'
                    }`}
                  />
                )}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Daily Vibe Tip */}
        <div className="p-4 rounded-lg bg-primary/10 border border-primary/20 mt-4">
          <div className="flex items-start gap-3">
            <Lightbulb className="w-5 h-5 text-yellow-500 shrink-0 mt-0.5" />
            <div>
              <p className="text-xs font-semibold text-primary mb-1">Daily Vibe Tip</p>
              <p className="text-sm text-muted-foreground">
                Use <code className="text-cyan-400 bg-cyan-400/10 px-1 rounded">scan --critical</code> to focus on high-risk vulnerabilities first!
              </p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

