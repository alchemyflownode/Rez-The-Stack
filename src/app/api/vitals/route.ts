/**
 * Web Vitals Endpoint
 * Receives Core Web Vitals metrics from frontend
 * POST /api/vitals
 */

import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { logger } from '@/lib/logger';

interface VitalMetric {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  delta: number;
  id: string;
  navigationType: string;
  timestamp: number;
}

/**
 * Store vitals in memory (in production, use database)
 * This is for demonstration - replace with real storage
 */
const vitalsStore: VitalMetric[] = [];

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const metric = (await request.json()) as unknown;

    // Validate metric structure
    if (
      typeof metric !== 'object' ||
      metric === null ||
      !('name' in metric) ||
      !('value' in metric)
    ) {
      return NextResponse.json(
        { error: 'Invalid metric format' },
        { status: 400 }
      );
    }

    const vital = metric as VitalMetric;

    // Log metric
    await logger.info('WebVitals', `${vital.name}: ${vital.value}ms (${vital.rating})`, {
      name: vital.name,
      value: vital.value,
      rating: vital.rating,
      navigationType: vital.navigationType,
    });

    // Store for monitoring
    vitalsStore.push(vital);

    // Alert on poor vitals
    if (vital.rating === 'poor') {
      await logger.warn('WebVitals', `Poor ${vital.name}: ${vital.value}`, {
        threshold: 'poor',
        navigationType: vital.navigationType,
      });
    }

    return NextResponse.json({ status: 'recorded' });
  } catch (error) {
    logger.error('VitalsEndpoint', error as Error);
    return NextResponse.json(
      { error: 'Failed to record metric' },
      { status: 500 }
    );
  }
}

/**
 * GET /api/vitals/summary
 * Returns aggregated vitals summary
 */
export async function GET(): Promise<NextResponse> {
  if (vitalsStore.length === 0) {
    return NextResponse.json({ vitals: [], count: 0 });
  }

  // Calculate averages by metric type
  const grouped: Record<string, number[]> = {};
  vitalsStore.forEach((v) => {
    if (!grouped[v.name]) grouped[v.name] = [];
    grouped[v.name].push(v.value);
  });

  const summary = Object.entries(grouped).reduce(
    (acc, [name, values]) => {
      const avg = values.reduce((a, b) => a + b, 0) / values.length;
      const poor = values.filter(
        (v) =>
          (name === 'LCP' && v > 4000) ||
          (name === 'FID' && v > 300) ||
          (name === 'CLS' && v > 0.25) ||
          (name === 'FCP' && v > 3000) ||
          (name === 'TTFB' && v > 1200)
      ).length;

      acc[name] = {
        avg: Math.round(avg),
        min: Math.min(...values),
        max: Math.max(...values),
        count: values.length,
        poorCount: poor,
      };
      return acc;
    },
    {} as Record<
      string,
      {
        avg: number;
        min: number;
        max: number;
        count: number;
        poorCount: number;
      }
    >
  );

  return NextResponse.json({
    summary,
    totalMetrics: vitalsStore.length,
    timestamp: new Date().toISOString(),
  });
}
