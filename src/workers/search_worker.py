from lib.gpu_manager import sovereign_generate
import sys
from pathlib import Path
# Add project root to path so "lib.gpu_manager" works
_project_root = Path(__file__).parent.parent.parent
if str(_project_root) not in sys.path:
    sys.path.insert(0, str(_project_root))
#!/usr/bin/env python3
"""
Sovereign Search Worker - Clean implementation
No warnings. Graceful error handling. Rate limit protection.
"""

import sys
import json
import time
from datetime import datetime

# Import with fallback - no warnings
try:
    from ddgs import DDGS
except ImportError:
    try:
        from duckduckgo_search import DDGS
    except ImportError:
        print(json.dumps({
            "success": False,
            "error": "Please install: pip install ddgs"
        }))
        sys.exit(1)

def search_web(query: str, max_results: int = 5) -> dict:
    """
    Perform web search with rate limit protection
    """
    results = []
    images = []
    start_time = time.time()
    
    try:
        with DDGS() as ddgs:
            # Text search - primary
            for r in ddgs.text(query, max_results=max_results):
                results.append({
                    "title": r.get("title", "No title"),
                    "url": r.get("href", ""),
                    "snippet": r.get("body", "")[:200] + "..." if r.get("body") else "",
                })
            
            # Image search - with rate limit protection
            try:
                # Add delay to avoid rate limiting
                time.sleep(1)
                img_count = 0
                for img in ddgs.images(query, max_results=3):
                    images.append({
                        "title": img.get("title", ""),
                        "url": img.get("url", ""),
                        "thumbnail": img.get("thumbnail", "")
                    })
                    img_count += 1
                    if img_count >= 2:  # Limit to 2 images to avoid rate limits
                        break
            except Exception:
                # Silently fail images - not critical
                pass
                
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "query": query
        }
    
    elapsed = time.time() - start_time
    
    return {
        "success": True,
        "query": query,
        "results": results,
        "images": images,
        "count": len(results),
        "time_ms": round(elapsed * 1000, 2)
    }

if __name__ == "__main__":
    query = sys.argv[1] if len(sys.argv) > 1 else "test"
    result = search_web(query)
    print(json.dumps(result))
