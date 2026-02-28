// src/lib/timestamp.ts
// Hydration-safe timestamp utilities

export function getClientTime(date?: Date) {
  if (typeof window === 'undefined') {
    return ''; // Return empty during SSR
  }
  
  const d = date || new Date();
  return d.toLocaleTimeString([], { 
    hour: '2-digit', 
    minute: '2-digit',
    second: '2-digit'
  });
}

export function useClientTime() {
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);
  
  const formatTime = (date: Date) => {
    if (!mounted) return '';
    return date.toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    });
  };
  
  return { mounted, formatTime };
}
