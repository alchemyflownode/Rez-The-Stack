#!/usr/bin/env python3
"""
Sovereign Search Worker - Fixed version (no GPU dependencies)
"""

import sys
import json
import time
from datetime import datetime

# Simple search function without GPU dependencies
def search_web(query: str, max_results: int = 5) -> dict:
    """Simple search function (mock for now)"""
    results = []
    start_time = time.time()
    
    # Mock results for testing
    for i in range(min(max_results, 3)):
        results.append({
            "title": f"Sample Result {i+1} about {query}",
            "url": f"https://example.com/result{i+1}",
            "snippet": f"This is a sample result for the query '{query}'. Install duckduckgo-search for real results."
        })
    
    elapsed = time.time() - start_time
    
    return {
        "success": True,
        "query": query,
        "results": results,
        "count": len(results),
        "time_ms": round(elapsed * 1000, 2),
        "note": "Using mock data - install duckduckgo-search for real results"
    }

if __name__ == "__main__":
    query = sys.argv[1] if len(sys.argv) > 1 else "test"
    result = search_web(query)
    print(json.dumps(result))
