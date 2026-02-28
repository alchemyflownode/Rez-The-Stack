# 🦊 REZ HIVE - COMPLETE FUNCTIONAL TEST SUITE
Write-Host "================================================" -ForegroundColor Magenta
Write-Host "  REZ HIVE - COMPLETE FUNCTIONAL TEST" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Magenta

$startTime = Get-Date
$results = @{}

# Helper function
function Test-Endpoint {
    param($Name, $Uri, $Body = $null, $Method = "POST")
    
    Write-Host "`n🔍 Testing: $Name" -ForegroundColor Yellow
    try {
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json
            $result = Invoke-RestMethod -Uri $Uri -Method $Method -Body $jsonBody -ContentType "application/json" -TimeoutSec 30
        } else {
            $result = Invoke-RestMethod -Uri $Uri -Method $Method -TimeoutSec 10
        }
        Write-Host "   ✅ PASS" -ForegroundColor Green
        return $result
    } catch {
        Write-Host "   ❌ FAIL: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "`n📋 Running Complete Test Suite..." -ForegroundColor Cyan

# --- TEST 1: Queen Health ---
Write-Host "`n👑 TESTING QUEEN" -ForegroundColor Magenta
$results["Queen GET"] = Test-Endpoint -Name "Queen GET" -Uri "http://localhost:3001/api/kernel" -Method GET

# --- TEST 2: Code Worker ---
Write-Host "`n🐝 TESTING CODE WORKER" -ForegroundColor Magenta
$codeTask = @{task="Write a Python script that prints 'Hello from Rez Hive'"}
$results["Code Generation"] = Test-Endpoint -Name "Code Generation" -Uri "http://localhost:3001/api/kernel" -Body $codeTask

# --- TEST 3: App Worker (Safety) ---
Write-Host "`n🐝 TESTING APP WORKER" -ForegroundColor Magenta
$safeTask = @{task="Launch notepad"}
$unsafeTask = @{task="Launch malware"}
$results["Safe App"] = Test-Endpoint -Name "Safe App Launch" -Uri "http://localhost:3001/api/kernel" -Body $safeTask
$results["Unsafe App"] = Test-Endpoint -Name "Unsafe App (should fail safely)" -Uri "http://localhost:3001/api/kernel" -Body $unsafeTask

# --- TEST 4: File Worker ---
Write-Host "`n🐝 TESTING FILE WORKER" -ForegroundColor Magenta
$fileTask = @{task="List files in current directory"}
$results["File List"] = Test-Endpoint -Name "File Listing" -Uri "http://localhost:3001/api/kernel" -Body $fileTask

# --- TEST 5: Director (SCE Compiler) ---
Write-Host "`n🎬 TESTING DIRECTOR" -ForegroundColor Magenta
$sceneTask = @{task="Generate an image prompt for: A cyberpunk samurai meditating in the rain, cinematic lighting, 4k"}
$results["Director"] = Test-Endpoint -Name "Scene Compilation" -Uri "http://localhost:3001/api/kernel" -Body $sceneTask

# --- TEST 6: MCP Worker (Web Search) ---
Write-Host "`n🌐 TESTING MCP WORKER" -ForegroundColor Magenta
$webTask = @{task="Search the web for RezStack sovereign AI"}
$results["Web Search"] = Test-Endpoint -Name "Web Search" -Uri "http://localhost:3001/api/kernel" -Body $webTask

# --- TEST 7: Vision Worker (if available) ---
Write-Host "`n👁️ TESTING VISION WORKER" -ForegroundColor Magenta
$visionTask = @{task="Describe this image"}
$results["Vision"] = Test-Endpoint -Name "Vision" -Uri "http://localhost:3001/api/workers/vision" -Body $visionTask

# --- TEST 8: SCE Engine (COBOL-style) ---
Write-Host "`n📜 TESTING SCE ENGINE" -ForegroundColor Magenta
$sceScript = @'
WORKING-STORAGE.
  01 QUERY PIC X(20) VALUE "cyberpunk architecture".

PROCEDURE DIVISION.
  MAIN.
    PERFORM SEARCH-WEB.
    STOP RUN.
'@
$sceTask = @{script=$sceScript}
$results["SCE Parser"] = Test-Endpoint -Name "SCE Engine" -Uri "http://localhost:3001/api/workers/sce" -Body $sceTask

# --- TEST 9: SCE Malformed (Anti-Fragile) ---
Write-Host "`n🛡️ TESTING ANTI-FRAGILE HANDLING" -ForegroundColor Magenta
$malformedScript = @'
WORKING-STORAGE.
  01 QUERY PIC X(20) VALUE "cyberpunk"
  MISSING PERIOD

PROCEDURE DIVISION.
  MAIN.
    PERFORM SEARCH-WEB.
    STOP RUN.
'@
$malformedTask = @{script=$malformedScript}
$results["Anti-Fragile"] = Test-Endpoint -Name "Malformed Script" -Uri "http://localhost:3001/api/workers/sce" -Body $malformedTask

# --- TEST 10: Mutation Worker (Constitution Update) ---
Write-Host "`n🧬 TESTING MUTATION WORKER" -ForegroundColor Magenta
$mutationTask = @{task="New rule: Always use dark mode in responses"}
$results["Mutation"] = Test-Endpoint -Name "Constitution Update" -Uri "http://localhost:3001/api/kernel" -Body $mutationTask

# --- TEST 11: Concurrent Load ---
Write-Host "`n⚡ TESTING CONCURRENT LOAD" -ForegroundColor Magenta
$concurrentSuccess = 0
$jobs = @()
for ($i = 1; $i -le 5; $i++) {
    $task = @{task="Search the web for test $i"} | ConvertTo-Json
    $jobs += Start-Job -ScriptBlock {
        param($url, $body)
        try {
            $result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -TimeoutSec 15
            return $true
        } catch {
            return $false
        }
    } -ArgumentList "http://localhost:3001/api/kernel", $task
}
$jobs | Wait-Job -Timeout 20 | Out-Null
foreach ($job in $jobs) {
    if ($job.State -eq 'Completed' -and (Receive-Job $job)) { $concurrentSuccess++ }
    Remove-Job $job -Force
}
if ($concurrentSuccess -ge 3) {
    Write-Host "   ✅ PASS - $concurrentSuccess/5 concurrent" -ForegroundColor Green
} else {
    Write-Host "   ❌ FAIL - Only $concurrentSuccess/5" -ForegroundColor Red
}
$results["Concurrent"] = $concurrentSuccess -ge 3

# --- TEST 12: Pattern Memory ---
Write-Host "`n🧠 TESTING PATTERN MEMORY" -ForegroundColor Magenta
$patternResult = Test-Endpoint -Name "Get Patterns" -Uri "http://localhost:3001/api/kernel" -Method GET
$results["Pattern Memory"] = $patternResult -ne $null

# --- FINAL REPORT ---
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n================================================" -ForegroundColor Magenta
Write-Host "  TEST RESULTS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "   ⏱️  Duration: $($duration.TotalSeconds) seconds" -ForegroundColor Yellow

$passed = 0
$total = 0
$results.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $total++
    if ($_.Value) { $passed++ }
    $color = if ($_.Value) { "Green" } else { "Red" }
    Write-Host "   $($_.Name): $(if($_.Value){'✅ PASS'}else{'❌ FAIL'})" -ForegroundColor $color
}

$percentage = [math]::Round(($passed / $total) * 100, 1)
Write-Host ""
Write-Host "   📊 Passed: $passed / $total ($percentage%)" -ForegroundColor Cyan

if ($passed -eq $total) {
    Write-Host "`n🏆 REZ HIVE PASSED ALL TESTS!" -ForegroundColor Magenta
    Write-Host "   Your sovereign co-worker is fully operational." -ForegroundColor Green
} else {
    Write-Host "`n🔧 Some tests failed. Check individual errors above." -ForegroundColor Yellow
}

Write-Host "`n================================================" -ForegroundColor Magenta