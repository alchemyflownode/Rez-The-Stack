# src/workers/compute_orchestrator.py
"""
The Sovereign Compute Orchestrator
Routes tasks based on HARDWARE STATE + TASK COMPLEXITY
"""

import json
import sys
import requests
from vram_monitor import monitor
from model_loader import ModelLoader

class ComputeOrchestrator:
    def __init__(self):
        self.model_loader = ModelLoader()
        
        # Model registry with REAL specs
        self.models = {
            'router': {
                'model': 'smollm2:360m-q4',
                'vram_gb': 0.4,
                'tok_s': 400,
                'purpose': 'intent_classification',
                'max_context': 8192
            },
            'fast': {
                'model': 'qwen2.5:3b-instruct-q4',
                'vram_gb': 2.2,
                'tok_s': 120,
                'purpose': 'general_chat',
                'max_context': 16384
            },
            'coder': {
                'model': 'deepseek-coder:6.7b-q4',
                'vram_gb': 4.2,
                'tok_s': 60,
                'purpose': 'code_generation',
                'max_context': 16384
            },
            'balanced': {
                'model': 'gemma2:9b-instruct-q4',
                'vram_gb': 5.8,
                'tok_s': 45,
                'purpose': 'complex_reasoning',
                'max_context': 8192
            },
            'planner': {
                'model': 'phi3.5:3.8b-mini-q4',
                'vram_gb': 2.4,
                'tok_s': 100,
                'purpose': 'task_planning',
                'max_context': 16384
            }
        }
    
    def classify_task(self, task: str) -> dict:
        """Use tiny router model to classify task (0.4GB VRAM)"""
        
        prompt = f"""Analyze this task and return JSON with:
1. type: one of [chat, code, research, system, executive]
2. complexity: float 0-1
3. context_needed: int (1-5 scale)
4. requires_reasoning: boolean

Task: {task}

Return ONLY valid JSON:"""
        
        # Call router model
        response = requests.post('http://localhost:11434/api/generate', json={
            'model': self.models['router']['model'],
            'prompt': prompt,
            'stream': False,
            'options': {
                'temperature': 0.1,
                'num_predict': 256
            }
        })
        
        try:
            result = response.json()
            text = result.get('response', '{}')
            # Extract JSON from response
            import re
            json_match = re.search(r'\{.*\}', text, re.DOTALL)
            if json_match:
                return json.loads(json_match.group())
        except:
            pass
        
        # Default fallback
        return {
            'type': 'chat',
            'complexity': 0.5,
            'context_needed': 3,
            'requires_reasoning': False
        }
    
    def select_model(self, task: str, classification: dict) -> str:
        """Choose optimal model based on hardware + task"""
        
        # Get current hardware state
        hw = monitor.get_state()
        
        print(f"📊 Hardware State: {hw.vram_free_gb:.1f}GB free, {hw.gpu_util_percent}% GPU load")
        
        # Task-based selection
        if classification['type'] == 'code':
            if hw.vram_free_gb >= self.models['coder']['vram_gb']:
                return 'coder'
        
        if classification['requires_reasoning'] or classification['complexity'] > 0.7:
            if hw.vram_free_gb >= self.models['balanced']['vram_gb']:
                return 'balanced'
        
        if classification['type'] in ['system', 'executive']:
            return 'planner'
        
        # Default to fast model (2.2GB)
        return 'fast'
    
    def execute(self, task: str) -> dict:
        """Main entry point - route and execute with hardware awareness"""
        
        # Step 1: Classify with router (always loaded)
        print("🔍 Classifying task...")
        classification = self.classify_task(task)
        
        # Step 2: Select optimal model based on hardware
        print("🎯 Selecting optimal model...")
        model_key = self.select_model(task, classification)
        model_config = self.models[model_key]
        
        # Step 3: Load model (hot-swap if needed)
        print(f"📡 Loading {model_key} model...")
        self.model_loader.load_specialist(model_key, {
            'vram_required': model_config['vram_gb'],
            'model_name': model_config['model']
        })
        
        # Step 4: Execute with chosen model
        print(f"🤖 Executing with {model_key} ({model_config['tok_s']} tok/s)")
        
        response = requests.post('http://localhost:11434/api/generate', json={
            'model': model_config['model'],
            'prompt': task,
            'stream': False,
            'options': {
                'temperature': 0.7,
                'num_ctx': model_config['max_context'],
                'num_predict': 1024 if classification['complexity'] > 0.7 else 512
            }
        })
        
        result = response.json()
        
        # Step 5: Return with telemetry
        hw = monitor.get_state()
        return {
            'task': task,
            'response': result.get('response', ''),
            'model_used': model_key,
            'model_specs': {
                'name': model_config['model'],
                'vram_gb': model_config['vram_gb'],
                'tokens_per_sec': model_config['tok_s']
            },
            'hardware': {
                'vram_free': hw.vram_free_gb,
                'vram_used': hw.vram_used_gb,
                'gpu_load': hw.gpu_util_percent,
                'ram_available': hw.ram_available_gb
            },
            'classification': classification,
            'loaded_models': self.model_loader.get_loaded_models()
        }

# CLI entry point
if __name__ == '__main__':
    orchestrator = ComputeOrchestrator()
    
    if len(sys.argv) > 1:
        task = ' '.join(sys.argv[1:])
        result = orchestrator.execute(task)
        print(json.dumps(result, indent=2))
    else:
        print("Usage: python compute_orchestrator.py <task>")