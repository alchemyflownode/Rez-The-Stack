# 🏛️ Build Docker Worker Images
Write-Host "Building Docker worker images..." -ForegroundColor Cyan

# Build code worker
docker build -t rez-worker-code -f Dockerfile.code .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Code worker image built" -ForegroundColor Green
} else {
    Write-Host "❌ Code worker build failed" -ForegroundColor Red
}

# Build harvester
docker build -t rez-worker-harvester -f Dockerfile.harvester .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Harvester image built" -ForegroundColor Green
} else {
    Write-Host "❌ Harvester build failed" -ForegroundColor Red
}

# Build vision worker
docker build -t rez-worker-vision -f Dockerfile.vision .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Vision worker image built" -ForegroundColor Green
} else {
    Write-Host "❌ Vision worker build failed" -ForegroundColor Red
}

Write-Host "`nAll worker images ready!" -ForegroundColor Magenta
Write-Host "Run with: `$env:USE_DOCKER='true'; .\rez-up.ps1 -Code -Vision" -ForegroundColor Cyan
