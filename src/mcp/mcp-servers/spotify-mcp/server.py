import sys
import json

def handle(req):
    method = req.get('method')
    if method == 'play':
        return {'success': True, 'message': 'Playing (mock)'}
    elif method == 'pause':
        return {'success': True, 'message': 'Paused (mock)'}
    elif method == 'current':
        return {'success': True, 'track': 'Mock Song', 'artist': 'Mock Artist'}
    return {'error': 'unknown'}

if __name__ == '__main__':
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            resp = handle(json.loads(line))
            sys.stdout.write(json.dumps(resp) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()

