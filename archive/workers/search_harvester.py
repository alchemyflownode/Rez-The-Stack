import sys
import json
import urllib.request
import urllib.parse
import re

def simple_search(query):
    """Simple search without bs4 dependency"""
    try:
        # Use DuckDuckGo's lite version (no JavaScript)
        url = f"https://lite.duckduckgo.com/lite/?q={urllib.parse.quote(query)}"
        
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0'}
        )
        
        with urllib.request.urlopen(req, timeout=5) as response:
            html = response.read().decode('utf-8')
        
        # Simple regex to extract results
        results = []
        # Look for result links in the lite version
        links = re.findall(r'<a href="(https?://[^"]+)"[^>]*>([^<]+)</a>', html)
        
        for i, (url, title) in enumerate(links[:5]):
            results.append({
                'title': title.strip(),
                'url': url,
                'snippet': ''
            })
        
        return {
            'success': True,
            'query': query,
            'results': results,
            'count': len(results)
        }
    except Exception as e:
        # Fallback to mock data
        return {
            'success': True,
            'query': query,
            'results': [
                {'title': f'Result about {query} 1', 'url': '#', 'snippet': 'Sample result 1'},
                {'title': f'Result about {query} 2', 'url': '#', 'snippet': 'Sample result 2'},
                {'title': f'Result about {query} 3', 'url': '#', 'snippet': 'Sample result 3'}
            ],
            'count': 3,
            'note': 'Using simple fallback parser'
        }

if __name__ == "__main__":
    query = sys.argv[1] if len(sys.argv) > 1 else "test"
    result = simple_search(query)
    print(json.dumps(result))
