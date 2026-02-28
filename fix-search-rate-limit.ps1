# ================================================================
# 🦊 FIX: SEARCH LIBRARY UPDATE & RATE LIMIT HANDLING
# ================================================================

Write-Host "Updating Search Harvester..." -ForegroundColor Cyan

# 1. Install the NEW library
Write-Host "Installing new 'ddgs' library..." -ForegroundColor Yellow
pip install ddgs --quiet

# 2. Update Python Script to use new library + Better Error Handling
 $searchHarvesterCode = @'
try:
    from ddgs import DDGS
except ImportError:
    from duckduckgo_search import DDGS

import json
import sys
import time

def harvest(query, max_text=5, max_images=4):
    try:
        # Add delay to prevent rate limits
        time.sleep(1) 
        
        with DDGS() as ddgs:
            # 1. Text Results
            text_results = []
            try:
                for r in ddgs.text(query, max_results=max_text):
                    text_results.append({
                        "title": r.get("title", ""),
                        "href": r.get("href", ""),
                        "body": r.get("body", "")
                    })
            except Exception as e:
                # Handle rate limit specifically
                if "403" in str(e) or "Ratelimit" in str(e):
                    return {
                        "success": False,
                        "error": "Search Provider Rate Limit Hit. Please wait a moment and try again.",
                        "query": query
                    }
                raise e

            # 2. Image Results
            image_results = []
            try:
                for r in ddgs.images(query, max_results=max_images):
                    image_results.append({
                        "image": r.get("image", ""),
                        "thumbnail": r.get("thumbnail", ""),
                        "title": r.get("title", ""),
                        "source": r.get("source", "")
                    })
            except:
                pass # Images are optional, continue without them

            return {
                "success": True,
                "query": query,
                "results": text_results,
                "images": image_results,
                "answer": f"Found {len(text_results)} sources.",
                "meta": {}
            }
            
    except Exception as e:
        return {"success": False, "error": str(e), "query": query}

if __name__ == "__main__":
    query = sys.argv[1] if len(sys.argv) > 1 else "test"
    print(json.dumps(harvest(query), indent=2))
'@

Set-Content -Path "src\api\workers\search_harvester.py" -Value $searchHarvesterCode -Encoding UTF8
Write-Host "   ✅ Search Harvester updated to DDGS" -ForegroundColor Green

Write-Host "`nTesting..." -ForegroundColor Yellow
python "src\api\workers\search_harvester.py" "AI News"

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  🏆 FIX DEPLOYED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta