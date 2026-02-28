#!/usr/bin/env python
import sys
import json
import requests

OLLAMA_URL = "http://host.docker.internal:11434/api/generate"

def analyze_image(task, image_base64):
    # Try vision models first
    vision_models = ['llava:7b', 'llava', 'llama3.2-vision:11b']
    
    for model in vision_models:
        try:
            response = requests.post(OLLAMA_URL, json={
                'model': model,
                'prompt': task or "Describe this image",
                'images': [image_base64],
                'stream': False
            }, timeout=30)
            
            if response.ok:
                return {'success': True, 'analysis': response.json()['response'], 'model': model}
        except Exception as e:
            continue
    
    # Fallback to text model
    try:
        response = requests.post(OLLAMA_URL, json={
            'model': 'llama3.2:3b',
            'prompt': "No image provided. Please provide an image to analyze.",
            'stream': False
        }, timeout=30)
        
        return {'success': True, 'analysis': response.json()['response'], 'fallback': True}
    except Exception as e:
        return {'error': str(e)}

if __name__ == '__main__':
    data = json.loads(sys.argv[1])
    result = analyze_image(data.get('task'), data.get('image', ''))
    print(json.dumps(result))
