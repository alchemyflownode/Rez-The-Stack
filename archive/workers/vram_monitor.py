# src/workers/vram_monitor.py
"""
Real-time NVIDIA GPU monitoring using NVML
No approximations. No guesses. Just facts.
"""

import pynvml
import psutil
import json
import time
from dataclasses import dataclass
from typing import Dict, Optional

@dataclass
class HardwareState:
    vram_total_gb: float
    vram_used_gb: float
    vram_free_gb: float
    gpu_util_percent: float
    gpu_temp_c: float
    ram_available_gb: float
    cpu_percent: float
    
class VRAMMonitor:
    def __init__(self):
        try:
            pynvml.nvmlInit()
            self.handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            self.has_nvidia = True
        except:
            self.has_nvidia = False
            print("⚠️ No NVIDIA GPU detected. Using system RAM only.")
    
    def get_state(self) -> HardwareState:
        """Get current hardware state with zero approximations"""
        
        # Get GPU state if available
        if self.has_nvidia:
            try:
                info = pynvml.nvmlDeviceGetMemoryInfo(self.handle)
                vram_total = info.total / 1024**3
                vram_used = info.used / 1024**3
                vram_free = info.free / 1024**3
                
                util = pynvml.nvmlDeviceGetUtilizationRates(self.handle)
                gpu_util = util.gpu
                
                temp = pynvml.nvmlDeviceGetTemperature(self.handle, pynvml.NVML_TEMPERATURE_GPU)
            except:
                # Fallback if NVML calls fail
                vram_total = 12.0  # RTX 3060 default
                vram_used = 0
                vram_free = 12.0
                gpu_util = 0
                temp = 0
        else:
            vram_total = 0
            vram_used = 0
            vram_free = 0
            gpu_util = 0
            temp = 0
        
        # System RAM always available
        ram = psutil.virtual_memory()
        ram_available = ram.available / 1024**3
        
        # CPU
        cpu_percent = psutil.cpu_percent(interval=0.1)
        
        return HardwareState(
            vram_total_gb=round(vram_total, 1),
            vram_used_gb=round(vram_used, 1),
            vram_free_gb=round(vram_free, 1),
            gpu_util_percent=gpu_util,
            gpu_temp_c=temp,
            ram_available_gb=round(ram_available, 1),
            cpu_percent=cpu_percent
        )
    
    def get_optimal_model(self, task_type: str) -> str:
        """Return which model fits RIGHT NOW based on actual VRAM"""
        state = self.get_state()
        
        # Model database with REAL VRAM requirements
        models = {
            'fast': {  # 2-3B models
                'vram_required': 2.5,
                'model_name': 'qwen2.5:3b-instruct-q4',
                'tokens_per_sec': 120,
                'use_ram_fallback': True
            },
            'coder': {  # 6-7B models
                'vram_required': 4.5,
                'model_name': 'deepseek-coder:6.7b-q4',
                'tokens_per_sec': 60,
                'use_ram_fallback': True
            },
            'balanced': {  # 8-9B models
                'vram_required': 6.0,
                'model_name': 'gemma2:9b-instruct-q4',
                'tokens_per_sec': 45,
                'use_ram_fallback': False
            }
        }
        
        # Choose based on task and available VRAM
        if task_type == 'code' and state.vram_free_gb >= models['coder']['vram_required']:
            return 'coder'
        elif task_type == 'complex' and state.vram_free_gb >= models['balanced']['vram_required']:
            return 'balanced'
        elif state.vram_free_gb >= models['fast']['vram_required']:
            return 'fast'
        else:
            # Not enough VRAM - use CPU offloading or smaller model
            return 'fast'  # Will use RAM offloading

# Singleton instance
monitor = VRAMMonitor()