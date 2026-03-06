# 🏛️ REZ HIVE - DEEP SEARCH INSTALLER
# ================================================
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  INSTALLING DEEP SEARCH CAPABILITIES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

# ================================================
# 1. CREATE WORKER DIRECTORY
# ================================================
Write-Host "`n📁 Creating worker directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "src\app\api\workers\deepsearch" -Force | Out-Null
Write-Host "   ✅ Directory created" -ForegroundColor Green

# ================================================
# 2. CREATE FIXED HARVESTER.PY
# ================================================
Write-Host "`n🐍 Updating harvester with URL decoding..." -ForegroundColor Yellow

$harvesterPython = @'
import sys
import json
import urllib.request
import urllib.parse
from html.parser import HTMLParser

class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.in_link = False
        self.current_url = ""
        self.current_title = ""
        
    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            for attr in attrs:
                # DuckDuckGo embeds real links in 'uddg' parameter inside the href
                if attr[0] == 'href':
                    href = attr[1]
                    if 'uddg=' in href:
                        # Extract and decode the real URL from the redirect
                        try:
                            # Grab the part after 'uddg='
                            raw_url = href.split('uddg=')[1].split('&')[0]
                            decoded_url = urllib.parse.unquote(raw_url)
                            self.current_url = decoded_url
                            self.in_link = True
                        except:
                            pass
                    elif 'http' in href or 'https' in href:
                        # Fallback for direct links (ads, nav, etc)
                        self.current_url = href
                        self.in_link = True
                    
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
        # Search DuckDuckGo
        url = f"https://html.duckduckgo.com/html/?q={urllib.parse.quote(query)}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req, timeout=10)
        html = response.read().decode('utf-8')
        
        parser = LinkParser()
        parser.feed(html)
        
        results = []
        seen = set()
        for link in parser.links:
            # Filter out ddg internal links and duplicates
            if link['url'] not in seen and 'duckduckgo.com' not in link['url']:
                seen.add(link['url'])
                results.append(link)
                if len(results) >= 10: break
                
        return json.dumps({'status': 'success', 'results': results})
        
    except Exception as e:
        return json.dumps({'status': 'error', 'message': str(e)})

if __name__ == "__main__":
    query = sys.argv[1] if len(sys.argv) > 1 else "cyberpunk"
    print(search(query))
'@

Set-Content -Path "src\workers\harvester.py" -Value $harvesterPython -Encoding UTF8
Write-Host "   ✅ Harvester updated with URL decoding" -ForegroundColor Green

# ================================================
# 3. CREATE DEEP SEARCH WORKER
# ================================================
Write-Host "`n🔧 Creating Deep Search worker..." -ForegroundColor Yellow

$deepSearchWorker = @'
import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);
const HARVESTER_PATH = path.join(process.cwd(), 'src/workers/harvester.py');
const OLLAMA_URL = 'http://localhost:11434/api/generate';

export async function POST(request: NextRequest) {
  try {
    const { task } = await request.json();
    
    // Step 1: Extract search query
    let query = task.toLowerCase()
      .replace('deep search', '')
      .replace('research', '')
      .replace('search the web for', '')
      .replace('search for', '')
      .trim();
    
    if (!query) query = 'latest AI developments';
    
    console.log(`[DeepSearch] Researching: ${query}`);
    
    // Step 2: Get search results
    const { stdout } = await execAsync(`python "${HARVESTER_PATH}" "${query}"`, { timeout: 15000 });
    const searchData = JSON.parse(stdout);
    
    if (searchData.status !== 'success') {
      throw new Error('Search failed');
    }
    
    // Step 3: Format results for AI
    const searchContext = searchData.results.map((r: any, i: number) => 
      `${i+1}. ${r.title}\n   URL: ${r.url}`
    ).join('\n\n');
    
    // Step 4: Ask LLM to synthesize
    const synthesisPrompt = `
Based on the following search results for "${query}", provide a comprehensive, well-structured answer.

Search Results:
${searchContext}

Instructions:
1. Synthesize the key information into a coherent answer
2. Cite sources using [1], [2], etc.
3. Organize with clear sections if appropriate
4. Be accurate and informative

Answer:
`;
    
    const synthesisResponse = await fetch(OLLAMA_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'llama3.2:3b',
        prompt: synthesisPrompt,
        stream: false,
        options: { temperature: 0.3 }
      })
    });
    
    const synthesisData = await synthesisResponse.json();
    
    return NextResponse.json({
      status: 'success',
      worker: 'deepsearch',
      query,
      answer: synthesisData.response,
      sources: searchData.results.map((r: any) => ({
        title: r.title,
        url: r.url
      }))
    });

  } catch (error: any) {
    console.error('[DeepSearch] Error:', error);
    return NextResponse.json({ 
      status: 'error', 
      message: error.message 
    }, { status: 500 });
  }
}
'@

Set-Content -Path "src\app\api\workers\deepsearch\route.ts" -Value $deepSearchWorker -Encoding UTF8
Write-Host "   ✅ Deep Search worker created" -ForegroundColor Green

# ================================================
# 4. UPDATE UI SEARCH RESULTS COMPONENT
# ================================================
Write-Host "`n🎨 Updating UI SearchResults component..." -ForegroundColor Yellow

$uiPath = "src\app\page.tsx"
$uiContent = Get-Content $uiPath -Raw

# Check if we need to update the SearchResults component
if ($uiContent -notmatch "Deep Search Results") {
    Write-Host "   ⚠️ UI needs manual update for Deep Search display" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Add this to your SearchResults component:" -ForegroundColor Cyan
    Write-Host @'

  // Deep Search mode (synthesized answer)
  if (answer) {
    return (
      <div className="space-y-4">
        <div className="text-xs font-bold text-purple-400 flex items-center gap-1">
          <Sparkles className="w-3 h-3" />
          <span>DEEP SEARCH RESULTS</span>
        </div>
        
        <div className="prose prose-invert prose-sm max-w-none">
          <div className="text-gray-200 whitespace-pre-wrap text-sm leading-relaxed">
            {answer}
          </div>
        </div>
        
        {sources && sources.length > 0 && (
          <div className="mt-4 pt-3 border-t border-white/10">
            <div className="text-[10px] text-gray-500 mb-2">Sources:</div>
            <div className="flex flex-wrap gap-2">
              {sources.map((src, i) => (
                <a
                  key={i}
                  href={src.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[10px] text-cyan-400 hover:underline bg-cyan-950/20 px-2 py-1 rounded-full border border-cyan-800/30"
                >
                  [{i+1}] {src.title.substring(0, 30)}...
                </a>
              ))}
            </div>
          </div>
        )}
      </div>
    );
  }
'@ -ForegroundColor White
} else {
    Write-Host "   ✅ UI already has Deep Search support" -ForegroundColor Green
}

# Add Sparkles import if missing
if ($uiContent -notmatch "Sparkles") {
    $uiContent = $uiContent -replace 'from .lucide-react.;', 'from "lucide-react";'
    $uiContent = $uiContent -replace '(import {[^}]+)}', '$1, Sparkles}'
    Set-Content -Path $uiPath -Value $uiContent -Encoding UTF8
    Write-Host "   ✅ Added Sparkles icon import" -ForegroundColor Green
}

# ================================================
# 5. UPDATE ROUTER
# ================================================
Write-Host "`n🔄 Updating router with Deep Search priority..." -ForegroundColor Yellow

$routerPath = "src\lib\okiru-engine.ts"
if (Test-Path $routerPath) {
    $routerContent = Get-Content $routerPath -Raw
    
    # Check if deepsearch already in router
    if ($routerContent -notmatch "worker.*deepsearch") {
        $deepSearchRule = @'

  // PRIORITY 2.1: DEEP SEARCH (Synthesized Research)
  if (t.includes('deep search') || t.includes('research') || t.includes('synthesize')) {
    return { worker: 'deepsearch', intent: task };
  }
'@
        
        # Insert after PRIORITY 2
        if ($routerContent -match '(PRIORITY 2:.*?\n.*?\n)') {
            $routerContent = $routerContent -replace $matches[1], $matches[1] + $deepSearchRule
            Set-Content -Path $routerPath -Value $routerContent -Encoding UTF8
            Write-Host "   ✅ Deep Search added to router" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ Could not auto-update router" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ✅ Deep Search already in router" -ForegroundColor Green
    }
}

# ================================================
# 6. UPDATE SAMPLE COMMANDS
# ================================================
Write-Host "`n📝 Adding Deep Search to sample commands..." -ForegroundColor Yellow

if ($uiContent -match "const SAMPLE_COMMANDS = \[([^\]]*)\]") {
    $commands = $matches[1]
    if ($commands -notmatch "Deep Research") {
        Write-Host "   ⚠️ Add this to your SAMPLE_COMMANDS array:" -ForegroundColor Yellow
        Write-Host '   { label: "Deep Research", icon: <Sparkles className="w-3 h-3" />, prompt: "Deep search: " },' -ForegroundColor Cyan
    } else {
        Write-Host "   ✅ Deep Search already in commands" -ForegroundColor Green
    }
}

# ================================================
# 7. TEST SCRIPT
# ================================================
Write-Host "`n🧪 Creating test script..." -ForegroundColor Yellow

$testScript = @'
# 🧪 Test Deep Search
Write-Host "Testing Deep Search..." -ForegroundColor Cyan

$body = @{task="Deep search: latest developments in quantum computing"} | ConvertTo-Json

try {
    $result = Invoke-RestMethod -Uri "http://localhost:3001/api/kernel" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 30
    
    if ($result.worker -eq 'deepsearch') {
        Write-Host "✅ Deep Search routed correctly" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 ANSWER:" -ForegroundColor Magenta
        Write-Host $result.result.answer -ForegroundColor White
        Write-Host ""
        Write-Host "📚 SOURCES:" -ForegroundColor Yellow
        $result.result.sources | ForEach-Object { Write-Host "   • $($_.title)" -ForegroundColor Cyan }
    } else {
        Write-Host "❌ Router used: $($result.worker)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Test failed: $_" -ForegroundColor Red
}
'@

Set-Content -Path "test-deepsearch.ps1" -Value $testScript -Encoding UTF8
Write-Host "   ✅ Test script created: test-deepsearch.ps1" -ForegroundColor Green

# ================================================
# 8. FINAL SUMMARY
# ================================================
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  🏆 DEEP SEARCH INSTALLED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "   ✅ Fixed harvester.py with URL decoding"
Write-Host "   ✅ Deep Search worker created"
Write-Host "   ✅ Router updated"
Write-Host "   ✅ Test script created"
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   1. Restart your server:" -ForegroundColor White
Write-Host "      `$env:NEXT_TURBOPACK=0; bun run next dev -p 3001 --webpack" -ForegroundColor Cyan
Write-Host ""
Write-Host "   2. Test Deep Search:" -ForegroundColor White
Write-Host "      .\test-deepsearch.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "   3. Or try in UI:" -ForegroundColor White
Write-Host '      "Deep search: quantum computing breakthroughs"' -ForegroundColor Cyan
Write-Host ""
Write-Host "   4. Manual UI updates needed (if any):" -ForegroundColor Yellow
Write-Host "      • Add Deep Search to SAMPLE_COMMANDS"
Write-Host "      • Update SearchResults component for answer display"
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta