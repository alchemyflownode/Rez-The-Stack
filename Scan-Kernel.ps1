$sourcePath = "G:\okiru\app builder\Cognitive Kernel\src"
$outputPath = "G:\okiru\app builder\Cognitive Kernel\kernel_full_scan.txt"

# 1. Clear or create the output file
"" | Out-File -FilePath $outputPath -Encoding utf8

# 2. Generate a visual Directory Tree
Add-Content -Path $outputPath -Value "=== DIRECTORY TREE ==="
Get-ChildItem -Path $sourcePath -Recurse | ForEach-Object {
    $depth = ($_.FullName.Replace($sourcePath, "").Split('\').Count) - 1
    $indent = "  " * $depth
    Add-Content -Path $outputPath -Value "$indent$($_.Name)"
}
Add-Content -Path $outputPath -Value "`n=== FILE CONTENTS ===`n"

# 3. List of extensions to include (add more if needed)
$extensions = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.json", "*.css", "*.ps1", "*.md")

# 4. Recursively get all files and append their content
Get-ChildItem -Path $sourcePath -Include $extensions -Recurse -File | ForEach-Object {
    $relativeName = $_.FullName.Replace($sourcePath, "src")
    
    Add-Content -Path $outputPath -Value "--- START OF FILE: $relativeName ---"
    Get-Content -Path $_.FullName | Add-Content -Path $outputPath
    Add-Content -Path $outputPath -Value "--- END OF FILE: $relativeName ---`n"
    
    Write-Host "Scanned: $relativeName" -ForegroundColor Cyan
}

Write-Host "`nScan complete! Output saved to: $outputPath" -ForegroundColor Green