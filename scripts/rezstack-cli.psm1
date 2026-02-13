function Write-Sovereign {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Message,
        [ValidateSet('Sovereign','Success','Warning','Error','Info','Debug','Accent')]
        [string]$Level = 'Info',
        [switch]$NoNewline
    )

    $colors = @{
        Sovereign = @{ FG = 'Magenta';   Prefix = '🦊 '; BG = $null }
        Success   = @{ FG = 'Green';     Prefix = '✅ '; BG = $null }
        Warning   = @{ FG = 'Yellow';    Prefix = '⚠️  '; BG = $null }
        Error     = @{ FG = 'Red';       Prefix = '❌ '; BG = 'Black' }
        Info      = @{ FG = 'Cyan';      Prefix = 'ℹ️  '; BG = $null }
        Debug     = @{ FG = 'Blue';      Prefix = '🔍 '; BG = $null }
        Accent    = @{ FG = 'DarkMagenta'; Prefix = '✨ '; BG = $null }
    }

    $style = $colors[$Level]
    $prefix = $style.Prefix
    $fg = $style.FG
    $bg = $style.BG
    
    if ($bg -eq $null) {
        if ($NoNewline) { Write-Host -NoNewline "${prefix}${Message}" -ForegroundColor $fg }
        else { Write-Host "${prefix}${Message}" -ForegroundColor $fg }
    } else {
        if ($NoNewline) { Write-Host -NoNewline "${prefix}${Message}" -ForegroundColor $fg -BackgroundColor $bg }
        else { Write-Host "${prefix}${Message}" -ForegroundColor $fg -BackgroundColor $bg }
    }
}

# Safe aliases (functions for emoji commands)
function sov { param($m, $l='Sovereign') Write-Sovereign $m -Level $l }
function success { param($m) Write-Sovereign $m -Level Success }
function error { param($m) Write-Sovereign $m -Level Error }
function info { param($m) Write-Sovereign $m -Level Info }
function warn { param($m) Write-Sovereign $m -Level Warning }
function debug { param($m) Write-Sovereign $m -Level Debug }
function accent { param($m) Write-Sovereign $m -Level Accent }

# Export public API
Export-ModuleMember -Function Write-Sovereign, sov, success, error, info, warn, debug, accent
