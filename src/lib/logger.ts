/**
 * Production-grade logging system
 * Replaces console.log/error throughout the app
 */

type LogLevel = 'info' | 'warn' | 'error' | 'debug';

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  context: string;
  message: string;
  error?: unknown;
  metadata?: Record<string, any>;
}

class Logger {
  private isDevelopment = typeof window === 'undefined' 
    ? process.env.NODE_ENV === 'development'
    : false;

  private logToConsole(level: LogLevel, context: string, message: string, error?: unknown) {
    if (!this.isDevelopment) return;

    const timestamp = new Date().toISOString();
    const prefix = `[${timestamp}] [${context}] [${level.toUpperCase()}]`;

    switch (level) {
      case 'error':
        console.error(prefix, message, error);
        break;
      case 'warn':
        console.warn(prefix, message);
        break;
      case 'debug':
        console.debug(prefix, message);
        break;
      case 'info':
      default:
        console.log(prefix, message);
        break;
    }
  }

  private async sendToBackend(entry: LogEntry) {
    // In production, send logs to backend/observability service
    if (this.isDevelopment || typeof window === 'undefined') return;

    try {
      // Only queue logs, don't block execution
      if ('sendBeacon' in navigator) {
        navigator.sendBeacon(
          '/api/logs',
          JSON.stringify(entry)
        );
      }
    } catch (e) {
      // Silently fail to avoid recursive errors
    }
  }

  async info(context: string, message: string, metadata?: Record<string, any>) {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: 'info',
      context,
      message,
      metadata,
    };

    this.logToConsole('info', context, message);
    await this.sendToBackend(entry);
  }

  async warn(context: string, message: string, metadata?: Record<string, any>) {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: 'warn',
      context,
      message,
      metadata,
    };

    this.logToConsole('warn', context, message);
    await this.sendToBackend(entry);
  }

  async error(context: string, error: unknown, metadata?: Record<string, any>) {
    const message = error instanceof Error ? error.message : String(error);
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: 'error',
      context,
      message,
      error: error instanceof Error ? {
        message: error.message,
        stack: error.stack,
        name: error.name,
      } : error,
      metadata,
    };

    this.logToConsole('error', context, message, error);
    await this.sendToBackend(entry);
  }

  async debug(context: string, message: string, metadata?: Record<string, any>) {
    if (!this.isDevelopment) return;

    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: 'debug',
      context,
      message,
      metadata,
    };

    this.logToConsole('debug', context, message);
  }
}

// Singleton instance
export const logger = new Logger();

// Type-safe logging helper for components
export function useLogger(context: string) {
  return {
    info: (message: string, metadata?: Record<string, any>) => logger.info(context, message, metadata),
    warn: (message: string, metadata?: Record<string, any>) => logger.warn(context, message, metadata),
    error: (error: unknown, metadata?: Record<string, any>) => logger.error(context, error, metadata),
    debug: (message: string, metadata?: Record<string, any>) => logger.debug(context, message, metadata),
  };
}
