/**
 * Environment Configuration Validator
 * Validates that all required environment variables are set at startup
 * Prevents silent failures in production
 */

interface EnvConfig {
  apiUrl: string;
  ollamaBaseUrl: string;
  ollamaModel: string;
  searxngUrl: string;
  nodeEnv: 'development' | 'production' | 'test';
  isDevelopment: boolean;
  isProduction: boolean;
}

class EnvironmentValidator {
  private config: EnvConfig | null = null;
  private errors: string[] = [];

  /**
   * Validate and return configuration
   * Throws error if validation fails
   */
  public validate(): EnvConfig {
    if (this.config) {
      return this.config;
    }

    this.errors = [];

    // Get environment variables
    const nodeEnv = (process.env.NODE_ENV || 'development') as 'development' | 'production' | 'test';
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || process.env.API_URL;
    const ollamaBaseUrl = process.env.OLLAMA_BASE_URL;
    const ollamaModel = process.env.OLLAMA_MODEL;
    const searxngUrl = process.env.SEARXNG_URL;

    // Validate each variable
    this.validateApiUrl(apiUrl);
    this.validateOllamaUrl(ollamaBaseUrl);
    this.validateOllamaModel(ollamaModel);
    this.validateSearxngUrl(searxngUrl);

    // If in production, fail on any missing variables
    if (nodeEnv === 'production' && this.errors.length > 0) {
      const message = `❌ Production environment validation failed:\n${this.errors.map(e => `  - ${e}`).join('\n')}`;
      throw new Error(message);
    }

    // Log warnings in development
    if (this.errors.length > 0) {
      console.warn(
        '⚠️  Environment configuration warnings:\n' +
        this.errors.map(e => `  - ${e}`).join('\n')
      );
    }

    this.config = {
      apiUrl: apiUrl || 'http://localhost:8001',
      ollamaBaseUrl: ollamaBaseUrl || 'http://localhost:11434',
      ollamaModel: ollamaModel || 'llama3.2:latest',
      searxngUrl: searxngUrl || 'http://localhost:8080',
      nodeEnv,
      isDevelopment: nodeEnv === 'development',
      isProduction: nodeEnv === 'production',
    };

    return this.config;
  }

  /**
   * Get validated config (must call validate() first)
   */
  public getConfig(): EnvConfig {
    if (!this.config) {
      throw new Error('Configuration not validated. Call validate() first.');
    }
    return this.config;
  }

  public static getInstance(): EnvironmentValidator {
    if (!global.__envValidator) {
      global.__envValidator = new EnvironmentValidator();
    }
    return global.__envValidator;
  }

  private validateApiUrl(url?: string) {
    if (!url) {
      this.errors.push('NEXT_PUBLIC_API_URL or API_URL environment variable is not set');
      return;
    }

    try {
      new URL(url);
    } catch {
      this.errors.push(`API_URL is not a valid URL: ${url}`);
    }
  }

  private validateOllamaUrl(url?: string) {
    if (!url) {
      this.errors.push('OLLAMA_BASE_URL is not set');
      return;
    }

    try {
      new URL(url);
    } catch {
      this.errors.push(`OLLAMA_BASE_URL is not a valid URL: ${url}`);
    }
  }

  private validateOllamaModel(model?: string) {
    if (!model) {
      this.errors.push('OLLAMA_MODEL is not set');
    }
  }

  private validateSearxngUrl(url?: string) {
    if (!url) {
      this.errors.push('SEARXNG_URL is not set');
      return;
    }

    try {
      new URL(url);
    } catch {
      this.errors.push(`SEARXNG_URL is not a valid URL: ${url}`);
    }
  }
}

// Declare global type
declare global {
  var __envValidator: EnvironmentValidator | undefined;
}

/**
 * Get validated environment configuration
 * This is the main export for using environment variables
 */
export function getEnvConfig(): EnvConfig {
  const validator = EnvironmentValidator.getInstance();
  
  // Validate on first call
  if (!validator.getConfig) {
    validator.validate();
  }

  return validator.getConfig();
}

/**
 * Validate environment and throw on error
 * Call this at application startup
 */
export function validateEnvironment(): EnvConfig {
  const validator = EnvironmentValidator.getInstance();
  return validator.validate();
}

/**
 * Helper for checking if running in development
 */
export function isDev(): boolean {
  return getEnvConfig().isDevelopment;
}

/**
 * Helper for checking if running in production
 */
export function isProd(): boolean {
  return getEnvConfig().isProduction;
}
