/**
 * API Validation Schemas
 * Runtime validation of API responses to ensure type safety
 * Uses Zod for schema definition and validation
 */

import { z } from 'zod';

// ============================================
// Kernel API Schemas
// ============================================

export const KernelTaskSchema = z.object({
  task: z.string().min(1, 'Task cannot be empty'),
  worker: z.string().default('brain'),
  model: z.string().optional(),
  confirmed: z.boolean().default(false),
});

export type KernelTask = z.infer<typeof KernelTaskSchema>;

export const KernelResponseSchema = z.object({
  status: z.enum(['success', 'error', 'pending']),
  result: z.string().optional(),
  error: z.string().optional(),
  worker: z.string().optional(),
  timestamp: z.string().datetime().optional(),
});

export type KernelResponse = z.infer<typeof KernelResponseSchema>;

// ============================================
// Status API Schemas
// ============================================

export const ServiceStatusSchema = z.object({
  ollama: z.boolean().describe('LLM service status'),
  chroma: z.boolean().describe('Memory/embeddings status'),
  kernel: z.boolean().describe('Backend kernel status'),
});

export type ServiceStatus = z.infer<typeof ServiceStatusSchema>;

export const SystemMetricSchema = z.object({
  name: z.string(),
  value: z.number(),
  unit: z.string(),
  timestamp: z.string().datetime().optional(),
});

export type SystemMetric = z.infer<typeof SystemMetricSchema>;

export const SystemStatusSchema = z.object({
  status: z.enum(['healthy', 'degraded', 'unhealthy']),
  services: ServiceStatusSchema,
  metrics: z.array(SystemMetricSchema).optional(),
  memory: z.object({
    used: z.number(),
    total: z.number(),
    percent: z.number(),
  }).optional(),
  cpu: z.object({
    usage: z.number(),
    cores: z.number(),
  }).optional(),
});

export type SystemStatus = z.infer<typeof SystemStatusSchema>;

// ============================================
// Search API Schemas
// ============================================

export const SearchResultSchema = z.object({
  title: z.string(),
  url: z.string().url(),
  snippet: z.string(),
  source: z.string().optional(),
  relevance: z.number().min(0).max(1).optional(),
});

export type SearchResult = z.infer<typeof SearchResultSchema>;

export const SearchImageSchema = z.object({
  title: z.string(),
  url: z.string().url(),
  thumbnail: z.string().url(),
  source: z.string().optional(),
});

export type SearchImage = z.infer<typeof SearchImageSchema>;

export const SearchResponseSchema = z.object({
  query: z.string(),
  results: z.array(SearchResultSchema),
  images: z.array(SearchImageSchema).optional(),
  time_ms: z.number().optional(),
  result_count: z.number().optional(),
});

export type SearchResponse = z.infer<typeof SearchResponseSchema>;

// ============================================
// Error Response Schema
// ============================================

export const ErrorResponseSchema = z.object({
  status: z.literal('error'),
  error: z.string(),
  code: z.string().optional(),
  details: z.record(z.unknown()).optional(),
  timestamp: z.string().datetime().optional(),
});

export type ErrorResponse = z.infer<typeof ErrorResponseSchema>;

// ============================================
// Model API Schemas
// ============================================

export const ModelInfoSchema = z.object({
  name: z.string(),
  model: z.string(),
  size: z.number().optional(),
  digest: z.string().optional(),
  modified_at: z.string().datetime().optional(),
});

export type ModelInfo = z.infer<typeof ModelInfoSchema>;

export const ModelsListSchema = z.object({
  models: z.array(ModelInfoSchema),
  default: z.string().optional(),
});

export type ModelsList = z.infer<typeof ModelsListSchema>;

// ============================================
// Validation Helpers
// ============================================

export class ValidationError extends Error {
  constructor(
    public details: z.ZodError,
    message = 'Validation failed'
  ) {
    super(message);
    this.name = 'ValidationError';
  }
}

/**
 * Safely validate data against a schema
 * Throws ValidationError if invalid
 */
export function validate<T>(schema: z.ZodSchema<T>, data: unknown): T {
  try {
    return schema.parse(data);
  } catch (error) {
    if (error instanceof z.ZodError) {
      throw new ValidationError(error, `Invalid data: ${error.errors.map(e => e.message).join(', ')}`);
    }
    throw error;
  }
}

/**
 * Safely validate data, returning null if invalid
 * Better for non-critical validations
 */
export function safeValidate<T>(schema: z.ZodSchema<T>, data: unknown): T | null {
  try {
    return schema.parse(data);
  } catch {
    return null;
  }
}

/**
 * Get validation errors as plain object
 * Useful for displaying to users
 */
export function getValidationErrors(error: unknown): Record<string, string[]> {
  if (error instanceof z.ZodError) {
    const errors: Record<string, string[]> = {};
    error.errors.forEach((err) => {
      const path = err.path.join('.');
      if (!errors[path]) {
        errors[path] = [];
      }
      errors[path].push(err.message);
    });
    return errors;
  }
  return {};
}
