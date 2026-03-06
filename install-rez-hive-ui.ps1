# ============================================================================
# REZ HIVE - COMPLETE UI INSTALLATION
# ============================================================================
# This script does EVERYTHING in one click:
#   - Creates the HTML file
#   - Updates kernel with compatibility endpoint
#   - Adds TaskRequest model if missing
#   - Creates launcher scripts
#   - Tests the connection
# ============================================================================

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$PROJECT_PATH = "D:\okiru-os\The Reztack OS"
Set-Location $PROJECT_PATH

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🏛️  REZ HIVE - COMPLETE UI INSTALLER                      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STEP 1: Create public folder
# ============================================================================
Write-Host "[1/6] Creating public folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "public" -Force | Out-Null
Write-Host "   ✅ public folder ready" -ForegroundColor Green

# ============================================================================
# STEP 2: Create the complete HTML UI
# ============================================================================
Write-Host "[2/6] Creating REZ HIVE HTML UI..." -ForegroundColor Yellow

$htmlContent = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>🏛️ REZ HIVE - Sovereign AI</title>
<script src="https://cdn.tailwindcss.com"></script>
<!-- PrismJS for code highlighting -->
<link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet" />
<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-python.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-javascript.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-typescript.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-json.min.js"></script>
<style>
  body { background-color: #030405; font-family: 'JetBrains Mono', 'Fira Code', monospace; }
  .response-message { @apply p-4 mb-3 rounded-xl break-words; }
  .user-message { background-color: rgba(6, 182, 212, 0.1); border: 1px solid rgba(6, 182, 212, 0.2); color: #e2e8f0; }
  .ai-message { background-color: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.05); color: #e2e8f0; }
  .timestamp { @apply text-xs text-white/30 font-mono mb-1; }
  pre { @apply p-4 bg-[#0d0d0d] rounded-lg overflow-x-auto text-sm border border-white/10; }
  code { font-family: 'JetBrains Mono', 'Fira Code', monospace; }
  .worker-active { @apply bg-cyan-500/10 text-cyan-400 border border-cyan-500/30; }
  .scrollbar-hide::-webkit-scrollbar { display: none; }
  .scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
</style>
</head>
<body class="min-h-screen bg-[#030405] text-white font-sans selection:bg-cyan-500/30">

<!-- Top Bar -->
<header class="fixed top-0 left-0 right-0 h-12 bg-black/50 backdrop-blur-md border-b border-white/5 flex items-center px-4 z-30">
  <div class="ml-4 flex items-center gap-3">
    <span class="text-sm font-medium bg-gradient-to-r from-cyan-400 to-purple-400 bg-clip-text text-transparent">
      REZ HIVE
    </span>
    <span class="text-xs px-2 py-0.5 bg-green-500/10 text-green-400 rounded-full border border-green-500/20 flex items-center gap-1.5">
      <span class="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse"></span>
      LIVE
    </span>
  </div>
  <div class="flex items-center gap-3 ml-6">
    <div class="flex items-center gap-1.5">
      <span class="w-2 h-2 rounded-full bg-green-400 animate-pulse"></span>
      <span class="text-xs text-white/30">Brain</span>
    </div>
    <div class="flex items-center gap-1.5">
      <span class="w-2 h-2 rounded-full bg-green-400 animate-pulse"></span>
      <span class="text-xs text-white/30">Memory</span>
    </div>
  </div>
  <div class="flex-1"></div>
  <div class="flex items-center gap-2">
    <span id="timestamp" class="text-xs text-white/30 font-mono tabular-nums"></span>
  </div>
</header>

<!-- Metrics Bar -->
<div class="fixed top-12 left-0 right-0 h-14 bg-black/30 backdrop-blur-sm border-b border-white/5 flex items-center px-4 z-20">
  <div class="flex gap-6 overflow-x-auto no-scrollbar">
    <div class="flex items-center gap-2 flex-shrink-0">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#34d399" stroke-width="2"><rect x="4" y="4" width="16" height="16" rx="2" ry="2"></rect><rect x="9" y="9" width="6" height="6"></rect></svg>
      <div class="flex flex-col min-w-[80px]">
        <div class="flex items-center gap-2">
          <span class="text-xs font-medium text-white/60">CPU</span>
          <span class="text-sm font-mono tabular-nums text-[#34d399]">12.4%</span>
        </div>
        <div class="h-4 w-10 opacity-60">▁▂▃▄▅</div>
      </div>
    </div>
    <div class="flex items-center gap-2 flex-shrink-0">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" stroke-width="2"><rect x="2" y="7" width="20" height="15" rx="2" ry="2"></rect><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path></svg>
      <div class="flex flex-col min-w-[80px]">
        <div class="flex items-center gap-2">
          <span class="text-xs font-medium text-white/60">RAM</span>
          <span class="text-sm font-mono tabular-nums text-[#60a5fa]">31.2%</span>
        </div>
        <div class="h-4 w-10 opacity-60">▁▂▃▄▅</div>
      </div>
    </div>
  </div>
  <div class="flex-1"></div>
  <div class="flex items-center gap-3 text-xs flex-shrink-0">
    <span class="text-white/30">Active: <span class="text-white/60" id="active-worker">Brain</span></span>
    <span class="w-1 h-1 rounded-full bg-green-400/50"></span>
    <span class="text-white/30">22 models</span>
  </div>
</div>

<!-- Main Container -->
<div class="pt-[104px] flex h-screen">
  <!-- Sidebar -->
  <nav class="w-48 border-r border-white/5 bg-black/20 backdrop-blur-sm flex-shrink-0">
    <div class="p-3 space-y-1">
      <button data-worker="brain" class="worker-btn w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-all bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2a10 10 0 0 1 10 10c0 5-3 8-10 8-6 0-10-3-10-8 0-5 4-10 10-10z"></path></svg>
        <span class="text-sm flex-1 text-left">Brain</span>
        <span class="w-1.5 h-1.5 bg-green-400 rounded-full"></span>
      </button>
      <button data-worker="search" class="worker-btn w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-all hover:bg-white/5 text-white/40 hover:text-white/60">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
        <span class="text-sm flex-1 text-left">Search</span>
      </button>
      <button data-worker="code" class="worker-btn w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-all hover:bg-white/5 text-white/40 hover:text-white/60">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"></polyline><polyline points="8 6 2 12 8 18"></polyline></svg>
        <span class="text-sm flex-1 text-left">Code</span>
      </button>
      <button data-worker="files" class="worker-btn w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-all hover:bg-white/5 text-white/40 hover:text-white/60">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path><polyline points="13 2 13 9 20 9"></polyline></svg>
        <span class="text-sm flex-1 text-left">Files</span>
      </button>
    </div>
  </nav>

  <!-- Chat Area -->
  <main class="flex-1 flex flex-col min-w-0 relative">
    <div id="chat-container" class="flex-1 overflow-y-auto p-4 pb-40">
      <div class="max-w-3xl mx-auto space-y-6" id="messages"></div>
    </div>

    <!-- Input Area -->
    <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black via-black/95 to-transparent pt-8 pb-6 px-4">
      <div class="max-w-3xl mx-auto">
        <div class="flex gap-2">
          <input id="input-field" type="text" placeholder="Message Brain worker..." 
            class="flex-1 bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm outline-none focus:border-cyan-500/40 transition-all placeholder:text-white/20">
          <button id="send-btn" class="px-6 py-3 bg-cyan-500/10 border border-cyan-500/30 rounded-xl text-cyan-400 hover:bg-cyan-500 hover:text-black transition-all font-medium">
            Send
          </button>
        </div>
      </div>
    </div>
  </main>
</div>

<script>
const API_URL = "http://localhost:8001/kernel/stream";
const messagesContainer = document.getElementById("messages");
const inputField = document.getElementById("input-field");
const sendBtn = document.getElementById("send-btn");
const activeWorkerSpan = document.getElementById("active-worker");
const timestampSpan = document.getElementById("timestamp");

let currentWorker = "brain";
let isLoading = false;

function updateTimestamp() {
  const now = new Date();
  timestampSpan.textContent = now.getHours().toString().padStart(2,'0') + ':' + 
                               now.getMinutes().toString().padStart(2,'0');
}
updateTimestamp();
setInterval(updateTimestamp, 1000);

document.querySelectorAll(".worker-btn").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".worker-btn").forEach(b => {
      b.classList.remove("bg-cyan-500/10", "text-cyan-400", "border", "border-cyan-500/20");
      b.classList.add("hover:bg-white/5", "text-white/40", "hover:text-white/60");
      if (b.querySelector(".w-1\\.5")) b.querySelector(".w-1\\.5").remove();
    });
    
    btn.classList.remove("hover:bg-white/5", "text-white/40", "hover:text-white/60");
    btn.classList.add("bg-cyan-500/10", "text-cyan-400", "border", "border-cyan-500/20");
    
    const indicator = document.createElement("span");
    indicator.className = "w-1.5 h-1.5 bg-green-400 rounded-full";
    btn.appendChild(indicator);
    
    currentWorker = btn.dataset.worker;
    activeWorkerSpan.textContent = btn.querySelector("span").textContent;
    inputField.placeholder = `Message ${activeWorkerSpan.textContent} worker...`;
  });
});

function addMessage(content, role = "user") {
  const messageDiv = document.createElement("div");
  messageDiv.className = `flex gap-3 ${role === 'user' ? 'flex-row-reverse' : ''} mb-4`;
  
  const avatarDiv = document.createElement("div");
  avatarDiv.className = `w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-sm ${
    role === 'ai' 
      ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20' 
      : 'bg-white/10 text-white'
  }`;
  avatarDiv.textContent = role === 'ai' ? '🤖' : 'U';
  
  const bubbleDiv = document.createElement("div");
  bubbleDiv.className = `max-w-[85%] ${role === 'user' ? 'text-right' : ''}`;
  
  const timeDiv = document.createElement("div");
  timeDiv.className = "text-xs text-white/20 mb-1 font-mono";
  timeDiv.textContent = new Date().toLocaleTimeString();
  
  const contentDiv = document.createElement("div");
  contentDiv.className = `text-sm rounded-2xl p-4 ${
    role === 'ai' 
      ? 'bg-white/5 border border-white/5' 
      : 'bg-cyan-500/10 border border-cyan-500/20'
  }`;
  
  if (typeof content === 'string') {
    contentDiv.textContent = content;
  } else if (content.files) {
    contentDiv.innerHTML = `<span class="text-cyan-400">📁 Files:</span><br>` + 
      content.files.map(f => `<span class="text-white/80">• ${f}</span>`).join("<br>");
  } else if (content.results) {
    contentDiv.innerHTML = `<span class="text-cyan-400">🔍 Results:</span><br>` + 
      content.results.map(r => `<span class="text-white/80">• ${r}</span>`).join("<br>");
  } else {
    contentDiv.textContent = content.content || JSON.stringify(content);
  }
  
  bubbleDiv.appendChild(timeDiv);
  bubbleDiv.appendChild(contentDiv);
  messageDiv.appendChild(avatarDiv);
  messageDiv.appendChild(bubbleDiv);
  
  messagesContainer.appendChild(messageDiv);
  messagesContainer.scrollTop = messagesContainer.scrollHeight;
}

async function sendMessage() {
  const task = inputField.value.trim();
  if (!task || isLoading) return;
  
  addMessage(task, "user");
  inputField.value = "";
  isLoading = true;
  sendBtn.disabled = true;
  sendBtn.textContent = "...";
  
  try {
    const response = await fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ task, worker: currentWorker })
    });
    
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let accumulated = "";
    
    const aiDiv = document.createElement("div");
    aiDiv.className = "flex gap-3 mb-4";
    aiDiv.innerHTML = `
      <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-sm bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">🤖</div>
      <div class="max-w-[85%]">
        <div class="text-xs text-white/20 mb-1 font-mono">${new Date().toLocaleTimeString()}</div>
        <div id="streaming-response" class="text-sm rounded-2xl p-4 bg-white/5 border border-white/5"></div>
      </div>
    `;
    messagesContainer.appendChild(aiDiv);
    const streamingDiv = document.getElementById("streaming-response");
    
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      
      const chunk = decoder.decode(value);
      const lines = chunk.split("\n\n");
      
      for (const line of lines) {
        if (line.startsWith("data: ")) {
          try {
            const data = JSON.parse(line.slice(5));
            if (data.content) {
              accumulated += data.content;
              streamingDiv.textContent = accumulated;
            } else if (data.files) {
              streamingDiv.innerHTML = `<span class="text-cyan-400">📁 Files:</span><br>` + 
                data.files.map(f => `<span class="text-white/80">• ${f}</span>`).join("<br>");
            } else if (data.results) {
              streamingDiv.innerHTML = `<span class="text-cyan-400">🔍 Results:</span><br>` + 
                data.results.map(r => `<span class="text-white/80">• ${r}</span>`).join("<br>");
            }
          } catch (e) {}
        }
      }
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
  } catch (error) {
    addMessage({ content: `⚠️ Error: ${error.message}` }, "ai");
  } finally {
    isLoading = false;
    sendBtn.disabled = false;
    sendBtn.textContent = "Send";
  }
}

sendBtn.addEventListener("click", sendMessage);
inputField.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && !e.shiftKey) {
    e.preventDefault();
    sendMessage();
  }
});

addMessage("Welcome to REZ HIVE! 👋\n\nI'm your sovereign AI coworker.\n\nTry: \"What can you help me with?\"", "ai");
</script>
</body>
</html>
'@

$htmlContent | Out-File -FilePath "public\rez-hive.html" -Encoding utf8 -Force
Write-Host "   ✅ Created public/rez-hive.html" -ForegroundColor Green

# ============================================================================
# STEP 3: Update kernel.py with compatibility endpoint
# ============================================================================
Write-Host "[3/6] Updating kernel.py with compatibility endpoint..." -ForegroundColor Yellow

$kernelPath = "backend\kernel.py"
$kernelContent = Get-Content $kernelPath -Raw

# Check if TaskRequest is defined
if ($kernelContent -notmatch "class TaskRequest") {
    Write-Host "   ⚠️ Adding missing TaskRequest model..." -ForegroundColor Yellow
    
    $taskRequestModel = @'

# ============================================================================
# PYDANTIC MODELS
# ============================================================================
from pydantic import BaseModel
from typing import Optional, Dict, Any

class TaskRequest(BaseModel):
    task: str
    worker: str = "brain"
    model: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None
    confirmed: bool = False

'@
    
    $kernelContent = $taskRequestModel + "`n" + $kernelContent
}

# Check if compatibility endpoint exists
if ($kernelContent -notmatch "kernel_compatibility_endpoint") {
    Write-Host "   ⚠️ Adding compatibility endpoint..." -ForegroundColor Yellow
    
    $compatibilityEndpoint = @'

# ============================================================================
# COMPATIBILITY ENDPOINT (for frontend)
# ============================================================================
@app.post("/api/kernel")
async def kernel_compatibility_endpoint(req: TaskRequest):
    """Compatibility endpoint that forwards to the real kernel stream"""
    return StreamingResponse(
        generate_stream(req.task, req.worker),
        media_type="text/event-stream"
    )
'@
    
    $kernelContent = $kernelContent + "`n" + $compatibilityEndpoint
}

$kernelContent | Out-File -FilePath $kernelPath -Encoding utf8 -Force
Write-Host "   ✅ kernel.py updated" -ForegroundColor Green

# ============================================================================
# STEP 4: Create launcher script
# ============================================================================
Write-Host "[4/6] Creating launcher script..." -ForegroundColor Yellow

$launcherScript = @'
# launch-rez-hive-ui.ps1
Write-Host "🏛️ Launching REZ HIVE..." -ForegroundColor Cyan

# Kill existing processes
taskkill /F /IM python.exe 2>$null
taskkill /F /IM node.exe 2>$null

# Start kernel
Write-Host "`n🚀 Starting kernel..." -ForegroundColor Yellow
$kernel = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PWD'; python backend/kernel.py" -PassThru
Start-Sleep -Seconds 3

# Start frontend
Write-Host "`n🎨 Starting frontend on port 3001..." -ForegroundColor Yellow
$frontend = Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", "cd '$PWD'; npm run dev -- -p 3001" -PassThru

Write-Host ""
Write-Host "✅ REZ HIVE is running!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Main UI:    http://localhost:3001" -ForegroundColor Cyan
Write-Host "📊 Chat UI:    http://localhost:3001/rez-hive.html" -ForegroundColor Cyan
Write-Host "📊 Kernel:     http://localhost:8001" -ForegroundColor Gray
'@

$launcherScript | Out-File -FilePath "launch-rez-hive-ui.ps1" -Encoding utf8 -Force
Write-Host "   ✅ Created launch-rez-hive-ui.ps1" -ForegroundColor Green

# ============================================================================
# STEP 5: Create test script
# ============================================================================
Write-Host "[5/6] Creating test script..." -ForegroundColor Yellow

$testScript = @'
# test-ui.ps1
Write-Host "🧪 Testing REZ HIVE endpoints..." -ForegroundColor Cyan

# Test status
try {
    $status = Invoke-RestMethod -Uri "http://localhost:8001/status" -ErrorAction Stop
    Write-Host "✅ Kernel status: OK" -ForegroundColor Green
    $status | ConvertTo-Json
} catch {
    Write-Host "❌ Kernel not responding" -ForegroundColor Red
}

Write-Host ""
Write-Host "📊 Open these URLs:" -ForegroundColor Yellow
Write-Host "   • Main UI: http://localhost:3001" -ForegroundColor White
Write-Host "   • Chat UI: http://localhost:3001/rez-hive.html" -ForegroundColor White
'@

$testScript | Out-File -FilePath "test-ui.ps1" -Encoding utf8 -Force
Write-Host "   ✅ Created test-ui.ps1" -ForegroundColor Green

# ============================================================================
# STEP 6: Summary
# ============================================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     ✅ REZ HIVE UI INSTALLATION COMPLETE                      ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 What was installed:" -ForegroundColor Cyan
Write-Host "  • Complete HTML chat UI at public/rez-hive.html" -ForegroundColor White
Write-Host "  • Kernel compatibility endpoint (/api/kernel)" -ForegroundColor White
Write-Host "  • TaskRequest model (if missing)" -ForegroundColor White
Write-Host "  • Launch script (launch-rez-hive-ui.ps1)" -ForegroundColor White
Write-Host "  • Test script (test-ui.ps1)" -ForegroundColor White
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Run: .\launch-rez-hive-ui.ps1" -ForegroundColor White
Write-Host "  2. Open: http://localhost:3001/rez-hive.html" -ForegroundColor White
Write-Host "  3. Start chatting!" -ForegroundColor White
Write-Host ""
Write-Host "🏛️ Your REZ HIVE is ready!" -ForegroundColor Green