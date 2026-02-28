# src/workers/model_loader.py
"""
Hot-swappable model manager
Only keeps router + ONE specialist in VRAM at a time
"""

import subprocess
import time
from typing import Optional, Dict
from vram_monitor import monitor

class ModelLoader:
    def __init__(self):
        self.loaded_models: Dict[str, dict] = {}
        self.router_model = 'smollm2:360m-q4'
        self.router_vram = 0.4  # GB
        
        # Always load router first
        self._load_router()
    
    def _load_router(self):
        """Router stays loaded 24/7 - only 0.4GB VRAM"""
        if 'router' not in self.loaded_models:
            print("📡 Loading router model...")
            cmd = f"ollama run {self.router_model} --keep-alive -1"
            subprocess.Popen(cmd, shell=True)
            self.loaded_models['router'] = {
                'name': self.router_model,
                'loaded_at': time.time(),
                'vram': self.router_vram,
                'last_used': time.time()
            }
            time.sleep(2)  # Give it time to load
    
    def load_specialist(self, model_key: str, model_config: dict):
        """Load a specialist model, unloading others if needed"""
        
        # Check if already loaded
        if model_key in self.loaded_models:
            self.loaded_models[model_key]['last_used'] = time.time()
            return True
        
        # Check if we have enough VRAM
        state = monitor.get_state()
        required = model_config['vram_required']
        
        if state.vram_free_gb >= required + 1.0:  # 1GB buffer
            # Enough space, just load
            self._load_model(model_key, model_config)
            return True
        else:
            # Need to unload existing specialist
            return self._unload_and_load(model_key, model_config)
    
    def _load_model(self, model_key: str, model_config: dict):
        """Actually load the model"""
        print(f"🔄 Loading {model_key} model...")
        cmd = f"ollama run {model_config['model_name']} --keep-alive -1"
        subprocess.Popen(cmd, shell=True)
        
        # Unload any other specialist (keep only router + this one)
        for k in list(self.loaded_models.keys()):
            if k != 'router' and k != model_key:
                self._unload_model(k)
        
        self.loaded_models[model_key] = {
            'name': model_config['model_name'],
            'loaded_at': time.time(),
            'vram': model_config['vram_required'],
            'last_used': time.time()
        }
        time.sleep(3)  # Give it time to load
    
    def _unload_model(self, model_key: str):
        """Unload a model from VRAM"""
        if model_key in self.loaded_models:
            print(f"🔄 Unloading {model_key} to free VRAM...")
            model_name = self.loaded_models[model_key]['name']
            cmd = f"ollama stop {model_name}"
            subprocess.run(cmd, shell=True)
            del self.loaded_models[model_key]
    
    def _unload_and_load(self, model_key: str, model_config: dict) -> bool:
        """Unload existing specialist and load new one"""
        # Find oldest specialist (excluding router)
        oldest = None
        oldest_time = time.time()
        
        for k, v in self.loaded_models.items():
            if k != 'router' and v['last_used'] < oldest_time:
                oldest = k
                oldest_time = v['last_used']
        
        if oldest:
            self._unload_model(oldest)
            time.sleep(1)  # Give it time to unload
            self._load_model(model_key, model_config)
            return True
        
        return False
    
    def get_loaded_models(self) -> list:
        """Return list of currently loaded models"""
        return list(self.loaded_models.keys())
    
    def get_vram_used(self) -> float:
        """Calculate VRAM used by loaded models"""
        total = 0
        for v in self.loaded_models.values():
            total += v['vram']
        return total