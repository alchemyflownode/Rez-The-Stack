# Detect CPU and NPU capability
Write-Host "--- CPU INFO ---" -ForegroundColor Cyan
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, Manufacturer

Write-Host "`n--- GPU INFO ---" -ForegroundColor Cyan
Get-CimInstance Win32_VideoController | Select-Object Name, AdapterRAM

Write-Host "`n--- PYTHON PLATFORM ---" -ForegroundColor Cyan
python -c "import platform; print(f'Processor: {platform.processor()}'); print(f'Machine: {platform.machine()}')"