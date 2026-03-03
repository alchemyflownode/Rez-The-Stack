// src/types/index.ts

export interface HardwareState {
  cpu_percent: number;
  ram: {
    total_gb: number;
    available_gb: number;
    percent: number;
  };
  gpu?: {
    name: string;
    vram_total_gb: number;
    vram_used_gb: number;
    vram_free_gb: number;
    util_percent: number;
    temp_c: number;
  };
}

export interface ComputeResult {
  success: boolean;
  response?: string;
  error?: string;
  model_used?: string;
  hardware?: HardwareState;
}
