# migrate-workers.ps1
param([switch]$DryRun)
$ErrorActionPreference = "Stop"
$workersDir = "G:\okiru\app builder\Cognitive Kernel\src\workers"
$importLine = "from lib.gpu_manager import sovereign_generate`n"

Write-Host "Migrating workers to GPU backend..." -ForegroundColor Cyan
Write-Host ""

Get-ChildItem "$workersDir\*_worker.py" -ErrorAction SilentlyContinue | ForEach-Object {
    $file = $_.FullName
    $name = $_.Name
    try {
        $content = Get-Content $file -Raw -Encoding UTF8
        if ($content -match "from lib.gpu_manager") {
            Write-Host "  [SKIP] $name - already migrated" -ForegroundColor Gray
            return
        }
        $newContent = $importLine + $content
        if ($DryRun) {
            Write-Host "  [DRY] $name - would add import" -ForegroundColor Yellow
        } else {
            $writer = [System.IO.StreamWriter]::new($file, $false, [System.Text.Encoding]::UTF8)
            $writer.Write($newContent)
            $writer.Close()
            Write-Host "  [OK]  $name - migrated" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [ERR] $name - $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host ""
Write-Host "Migration complete!" -ForegroundColor Green