'use client';

import { ModelSelector } from './ModelSelector';
import { Shield, Network } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

interface StatusPanelProps {
  violationsFixed: number;
  compliancePercent: number;
  status: 'STABLE' | 'WARNING' | 'CRITICAL';
  nodesDiscovered: number;
  currentModel: string;
  onModelChange: (model: string) => void;
}

export function StatusPanel({
  violationsFixed,
  compliancePercent,
  status,
  nodesDiscovered,
  currentModel,
  onModelChange,
}: StatusPanelProps) {
  const statusColors = {
    STABLE: 'text-green-500',
    WARNING: 'text-yellow-500',
    CRITICAL: 'text-red-500',
  };

  return (
    <Card className="glass-card">
      <CardHeader className="pb-2">
        <CardTitle className="text-lg font-semibold flex items-center gap-2">
          <Shield className="w-5 h-5 text-primary" />
          RezStack Sovereign
          <Badge variant="outline" className="badge-cyan text-xs ml-2">
            Zero-Drift AI Code Architect
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Compliance Status */}
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <Shield className="w-4 h-4 text-primary" />
              <span className="text-sm font-medium">Compliance Status</span>
            </div>
            <div className="flex items-center gap-3">
              <span className={`text-2xl font-bold ${statusColors[status]}`}>
                {status}
              </span>
              <Badge variant="outline" className="badge-success">
                {violationsFixed} violations fixed
              </Badge>
            </div>
            <div className="w-full bg-muted rounded-full h-2 mt-2">
              <div
                className="bg-gradient-to-r from-purple-500 to-cyan-500 h-2 rounded-full transition-all duration-500"
                style={{ width: `${compliancePercent}%` }}
              />
            </div>
            <span className="text-xs text-muted-foreground">
              Compliance Progress: {compliancePercent}%
            </span>
          </div>

          {/* Neural Engine with Model Selector */}
          <div className="space-y-2">
            <ModelSelector
              currentModel={currentModel}
              onModelChange={onModelChange}
            />
            
            {/* Nodes Discovered */}
            <div className="flex items-center gap-2 mt-2">
              <Network className="w-4 h-4 text-cyan-400" />
              <span className="text-xs text-muted-foreground">
                Nodes Discovered
              </span>
              <Badge variant="outline" className="badge-cyan text-xs ml-auto">
                {nodesDiscovered}
              </Badge>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
