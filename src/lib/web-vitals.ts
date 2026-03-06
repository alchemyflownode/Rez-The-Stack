/**
 * Web Vitals Monitoring
 * Tracks Core Web Vitals and sends to observability service
 * 
 * Core Web Vitals (Google):
 * - LCP (Largest Contentful Paint): < 2.5s
 * - FID (First Input Delay): < 100ms
 * - CLS (Cumulative Layout Shift): < 0.1
 */

import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

interface VitalMetric {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  delta: number;
  id: string;
  navigationType: 'navigate' | 'reload' | 'back-forward';
  timestamp: number;
}

// Thresholds for Core Web Vitals
const THRESHOLDS = {
  LCP: { good: 2500, poor: 4000 }, // ms
  FID: { good: 100, poor: 300 }, // ms
  CLS: { good: 0.1, poor: 0.25 }, // unitless
  FCP: { good: 1800, poor: 3000 }, // ms
  TTFB: { good: 600, poor: 1200 }, // ms
};

/**
 * Determine rating based on metric value and thresholds
 */
function getRating(
  name: string,
  value: number
): 'good' | 'needs-improvement' | 'poor' {
  const threshold = THRESHOLDS[name as keyof typeof THRESHOLDS];
  if (!threshold) return 'needs-improvement';

  if (value <= threshold.good) return 'good';
  if (value <= threshold.poor) return 'needs-improvement';
  return 'poor';
}

/**
 * Send metric to observability service
 */
async function sendMetric(metric: VitalMetric) {
  try {
    // Only send in production to reduce noise
    if (process.env.NODE_ENV !== 'production') {
      console.debug('[Vitals]', metric.name, `${metric.value}ms`, metric.rating);
      return;
    }

    // Send to your analytics endpoint
    if ('sendBeacon' in navigator) {
      navigator.sendBeacon(
        '/api/vitals',
        JSON.stringify(metric)
      );
    } else {
      await fetch('/api/vitals', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(metric),
        keepalive: true,
      });
    }
  } catch (e) {
    // Silently fail to avoid blocking user experience
    console.error('Failed to send vital metric:', e);
  }
}

/**
 * Initialize Web Vitals tracking
 * Call this in your root layout
 */
export function initWebVitals() {
  // Largest Contentful Paint
  getLCP((metric) => {
    const vital: VitalMetric = {
      name: 'LCP',
      value: Math.round(metric.value),
      rating: getRating('LCP', metric.value),
      delta: Math.round(metric.delta),
      id: metric.id,
      navigationType: metric.navigationType,
      timestamp: metric.startTime,
    };
    sendMetric(vital);
  });

  // First Input Delay
  getFID((metric) => {
    const vital: VitalMetric = {
      name: 'FID',
      value: Math.round(metric.value),
      rating: getRating('FID', metric.value),
      delta: Math.round(metric.delta),
      id: metric.id,
      navigationType: metric.navigationType,
      timestamp: metric.startTime,
    };
    sendMetric(vital);
  });

  // Cumulative Layout Shift
  getCLS((metric) => {
    const vital: VitalMetric = {
      name: 'CLS',
      value: Math.round(metric.value * 1000) / 1000, // Round to 3 decimals
      rating: getRating('CLS', metric.value),
      delta: Math.round(metric.delta * 1000) / 1000,
      id: metric.id,
      navigationType: metric.navigationType,
      timestamp: metric.startTime,
    };
    sendMetric(vital);
  });

  // First Contentful Paint
  getFCP((metric) => {
    const vital: VitalMetric = {
      name: 'FCP',
      value: Math.round(metric.value),
      rating: getRating('FCP', metric.value),
      delta: Math.round(metric.delta),
      id: metric.id,
      navigationType: metric.navigationType,
      timestamp: metric.startTime,
    };
    sendMetric(vital);
  });

  // Time to First Byte
  getTTFB((metric) => {
    const vital: VitalMetric = {
      name: 'TTFB',
      value: Math.round(metric.value),
      rating: getRating('TTFB', metric.value),
      delta: Math.round(metric.delta),
      id: metric.id,
      navigationType: metric.navigationType,
      timestamp: metric.startTime,
    };
    sendMetric(vital);
  });
}

/**
 * Helper to check if vitals are good
 */
export function areVitalsHealthy(vitals: VitalMetric[]): boolean {
  return vitals.every(v => v.rating === 'good' || v.rating === 'needs-improvement');
}
