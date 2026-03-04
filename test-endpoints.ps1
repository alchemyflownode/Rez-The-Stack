# test-endpoints.ps1
Write-Host "Testing REZ HIVE Endpoints..." -ForegroundColor Cyan

$endpoints = @(
    @{Method="GET"; Url="http://localhost:3000/api/status"},
    @{Method="GET"; Url="http://localhost:3000/api/health"},
    @{Method="GET"; Url="http://localhost:3000/api/system/vitals"},
    @{Method="GET"; Url="http://localhost:3000/api/system/info"},
    @{Method="GET"; Url="http://localhost:3000/api/apps/list"},
    @{Method="GET"; Url="http://localhost:3000/api/rag/documents"},
    @{Method="POST"; Url="http://localhost:3000/api/notes"; Body=@{"content"="Test note from endpoint tester"}},
    @{Method="POST"; Url="http://localhost:3000/api/tasks"; Body=@{"title"="Test Task"}}
)

foreach ($ep in $endpoints) {
    try {
        if ($ep.Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $ep.Url -Method Get
            Write-Host "âœ… $($ep.Method) $($ep.Url)" -ForegroundColor Green
        } else {
            $json = $ep.Body | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $ep.Url -Method Post -Body $json -ContentType "application/json"
            Write-Host "âœ… $($ep.Method) $($ep.Url)" -ForegroundColor Green
        }
    } catch {
        Write-Host "âŒ $($ep.Method) $($ep.Url)" -ForegroundColor Red
    }
}
