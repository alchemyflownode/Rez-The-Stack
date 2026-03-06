// src/app/sovereign/ZeroDriftDashboard.tsx
export const ZeroDriftDashboard = () => {
  const [metrics, setMetrics] = useState({
    driftScore: 0.02,
    constitutionalCompliance: 0.98,
    activeArticles: 9,
    lastAudit: "2026-03-04"
  });
  
  return (
    <div className="fixed bottom-4 left-4 w-80 bg-black/90 border border-cyan-500/30 rounded-xl p-4 z-50">
      <h3 className="text-cyan-400 font-medium mb-3">⚖️ Zero-Drift Monitor</h3>
      
      <div className="space-y-2">
        <MetricBar 
          label="Drift Score" 
          value={metrics.driftScore} 
          threshold={0.05}
          good="below"
        />
        <MetricBar 
          label="Constitutional" 
          value={metrics.constitutionalCompliance} 
          threshold={0.95}
          good="above"
        />
        <div className="text-xs text-white/40">
          Articles: {metrics.activeArticles}/9 active
        </div>
      </div>
    </div>
  );
};