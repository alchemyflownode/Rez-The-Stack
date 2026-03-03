# Create the TwoBarMeter component
$twoBarMeter = @'
'use client';

import { useState, useEffect } from 'react';

interface TwoBarMeterProps {
  sessionPercent: number;
  weeklyPercent: number;
  resetTime?: number;
  className?: string;
}

export function TwoBarMeter({ 
  sessionPercent, 
  weeklyPercent, 
  resetTime, 
  className = '' 
}: TwoBarMeterProps) {
  const [timeLeft, setTimeLeft] = useState<string>('');

  useEffect(() => {
    if (!resetTime) return;

    const timer = setInterval(() => {
      const diff = resetTime - Date.now();
      if (diff <= 0) {
        setTimeLeft('Resetting...');
        return;
      }

      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      setTimeLeft(`${hours}h ${minutes}m`);
    }, 60000);

    return () => clearInterval(timer);
  }, [resetTime]);

  return (
    <div className={`flex flex-col gap-1 ${className}`}>
      <div className="w-full bg-white/5 rounded-full overflow-hidden h-1.5">
        <div
          className="h-full transition-all duration-300 bg-cyan-400"
          style={{ width: `${Math.min(sessionPercent, 100)}%` }}
        />
      </div>
      
      <div className="w-full bg-white/5 rounded-full overflow-hidden h-1.5">
        <div
          className="h-full transition-all duration-300 bg-purple-400"
          style={{ width: `${Math.min(weeklyPercent, 100)}%` }}
        />
      </div>

      {timeLeft && (
        <div className="flex justify-end">
          <span className="text-[10px] font-mono text-white/30">
            reset {timeLeft}
          </span>
        </div>
      )}
    </div>
  );
}
'@

# Save the file
New-Item -ItemType Directory -Path "src\app\components" -Force | Out-Null
$twoBarMeter | Out-File "src\app\components\TwoBarMeter.tsx" -Encoding UTF8 -Force
Write-Host "✅ TwoBarMeter.tsx created" -ForegroundColor Green