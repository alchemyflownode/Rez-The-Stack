#!/usr/bin/env python
import sys
import json
import subprocess
import tempfile
import os

def execute_code(code, language):
    with tempfile.NamedTemporaryFile(mode='w', suffix=f'.{language}', delete=False) as f:
        f.write(code)
        temp_file = f.name
    
    try:
        if language == 'python':
            result = subprocess.run(['python', temp_file], 
                                  capture_output=True, text=True, timeout=10)
        elif language == 'javascript':
            result = subprocess.run(['node', temp_file], 
                                  capture_output=True, text=True, timeout=10)
        else:
            return {'error': f'Unsupported language: {language}'}
        
        return {
            'stdout': result.stdout,
            'stderr': result.stderr,
            'returncode': result.returncode
        }
    except subprocess.TimeoutExpired:
        return {'error': 'Execution timeout (10s)'}
    finally:
        os.unlink(temp_file)

if __name__ == '__main__':
    data = json.loads(sys.argv[1])
    result = execute_code(data.get('code', ''), data.get('language', 'python'))
    print(json.dumps(result))
