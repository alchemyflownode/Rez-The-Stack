import { useEffect, useState } from 'react';

export function useSessionMemory() {
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    // Only runs in Browser
    const sessionId = crypto.randomUUID();
    console.log(`📚 Session started: ${sessionId}`);
    setLoaded(true);

    // Cleanup
    return () => {
      console.log(`📚 Session ended: ${sessionId}`);
    };
  }, []);

  return { loaded };
}
