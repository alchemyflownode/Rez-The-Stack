'use client';

import { useEffect } from "react";
import { initWebVitals } from "@/lib/web-vitals";
import { ErrorBoundary } from "@/components/ErrorBoundary";

export function LayoutClient({
  children,
  className,
}: {
  children: React.ReactNode;
  className: string;
}) {
  useEffect(() => {
    // Initialize Core Web Vitals monitoring
    if (typeof window !== 'undefined') {
      initWebVitals();
    }
  }, []);

  return (
    <body className={className}>
      <ErrorBoundary>
        {children}
      </ErrorBoundary>
    </body>
  );
}
