# research_mcp.py
import sys
import json
import requests
import time

SEARXNG_URL = "http://localhost:8080"

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'search_web':
        query = params.get('query', '')
        max_results = params.get('max_results', 5)
        
        try:
            response = requests.get(
                f"{SEARXNG_URL}/search",
                params={"q": query, "format": "json"},
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                results = []
                for r in data.get("results", [])[:max_results]:
                    results.append({
                        "title": r.get("title", ""),
                        "url": r.get("url", ""),
                        "content": r.get("content", "")[:200]
                    })
                return {"success": True, "results": results}
            return {"success": False, "error": f"HTTP {response.status_code}"}
        except requests.exceptions.ConnectionError:
            return {"success": False, "error": "SearXNG not running"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("Research MCP Server Running\n")
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()
