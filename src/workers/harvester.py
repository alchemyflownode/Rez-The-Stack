import sys
import json
import urllib.request
import urllib.parse
from html.parser import HTMLParser

# Mini HTML Parser
class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.in_link = False
        self.current_url = ""
        
    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            for attr in attrs:
                if attr[0] == 'href' and ('http' in attr[1] or 'https' in attr[1]):
                    self.in_link = True
                    self.current_url = attr[1]
                    
    def handle_data(self, data):
        if self.in_link and data.strip():
            self.links.append({
                'title': data.strip(), 
                'url': self.current_url, 
                'source': 'DuckDuckGo'
            })
            self.in_link = False

def search(query):
    try:
        url = f"https://html.duckduckgo.com/html/?q={urllib.parse.quote(query)}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req, timeout=10)
        html = response.read().decode('utf-8')
        
        parser = LinkParser()
        parser.feed(html)
        
        results = []
        seen = set()
        for link in parser.links[:5]:
            if link['url'] not in seen:
                seen.add(link['url'])
                results.append(link)
                
        return json.dumps({'status': 'success', 'results': results})
        
    except Exception as e:
        return json.dumps({'status': 'error', 'message': str(e)})

if __name__ == "__main__":
    query = sys.argv[1] if len(sys.argv) > 1 else "cyberpunk"
    print(search(query))
