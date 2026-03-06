# ╔═══════════════════════════════════════════════════════════════════════╗
# ║                    SOVEREIGN OS - PREMIUM UI INSTALLER                 ║
# ║                         Version 2.0.0 - Enterprise Tier                ║
# ║                    Investment Grade: $100,000+ Project                 ║
# ╚═══════════════════════════════════════════════════════════════════════╝

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("violet", "cyan", "emerald", "rose", "amber")]
    [string]$Theme = "violet",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# ═══════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════

$Script:StartTime = Get-Date
$Script:ProjectRoot = Get-Location
$Script:BackupPath = Join-Path $Script:ProjectRoot "backups\ui-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$Script:Errors = @()
$Script:Warnings = @()
$Script:Success = @()

# Color codes for premium output
$Colors = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'Gray'
    Accent    = 'Magenta'
}

# ═══════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════

function Write-Premium {
    param([string]$Message, [string]$Color = $Colors.Info, [string]$Prefix = "║")
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $symbol = switch ($Color) {
        $Colors.Success { "✓" }
        $Colors.Warning { "⚠" }
        $Colors.Error   { "✗" }
        $Colors.Accent  { "★" }
        default         { "•" }
    }
    
    Write-Host "[$timestamp] $Prefix " -NoNewline -ForegroundColor Gray
    Write-Host "$symbol " -NoNewline -ForegroundColor $Color
    Write-Host $Message -ForegroundColor $Color
}

function Write-Section {
    param([string]$Title)
    
    Write-Host "`n╔$("$("=" * 75))╗" -ForegroundColor Cyan
    Write-Host "║  $Title" -ForegroundColor Cyan
    Write-Host "╚$("$("=" * 75))╝" -ForegroundColor Cyan
}

function Test-Command {
    param([string]$Command)
    return Get-Command $Command -ErrorAction SilentlyContinue
}

function Backup-File {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        if (-not $SkipBackup) {
            $relativePath = $FilePath.Replace($Script:ProjectRoot, "").TrimStart('\')
            $backupFile = Join-Path $Script:BackupPath $relativePath
            $backupDir = Split-Path $backupFile -Parent
            
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            
            Copy-Item $FilePath $backupFile -Force
            Write-Premium "Backed up: $relativePath" $Colors.Info
        }
    }
}

function Install-NpmPackage {
    param(
        [string]$Package,
        [string]$Version = "latest",
        [switch]$Dev
    )
    
    Write-Premium "Installing: $Package@$Version" $Colors.Primary
    
    $params = @("install", $Package)
    if ($Version -ne "latest") { $params += "@$Version" }
    if ($Dev) { $params += "--save-dev" }
    
    try {
        npm @params --silent | Out-Null
        Write-Premium "✓ Installed: $Package" $Colors.Success
        return $true
    }
    catch {
        Write-Premium "✗ Failed: $Package - $_" $Colors.Error
        $Script:Errors += "Failed to install $Package"
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════
# MAIN INSTALLATION
# ═══════════════════════════════════════════════════════════════════════

Clear-Host
Write-Host "`n"
Write-Host "  ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗" -ForegroundColor Cyan
Write-Host "  ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║" -ForegroundColor Cyan
Write-Host "  ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔██████║" -ForegroundColor Cyan
Write-Host "  ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║" -ForegroundColor White
Write-Host "  ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║" -ForegroundColor White
Write-Host "  ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝" -ForegroundColor White
Write-Host "`n  Premium UI Installation System v2.0.0" -ForegroundColor Magenta
Write-Host "  Enterprise Tier - $100K Project Standard" -ForegroundColor Gray
Write-Host "`n"

Write-Section "PRE-INSTALLATION CHECKS"

# Check Node.js
if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Premium "Node.js detected: $nodeVersion" $Colors.Success
}
else {
    Write-Premium "Node.js not found. Please install Node.js 18+ first." $Colors.Error
    exit 1
}

# Check npm
if (Test-Command "npm") {
    $npmVersion = npm --version
    Write-Premium "npm detected: v$npmVersion" $Colors.Success
}
else {
    Write-Premium "npm not found." $Colors.Error
    exit 1
}

# Check if package.json exists
if (Test-Path "package.json") {
    Write-Premium "Project configuration found" $Colors.Success
}
else {
    Write-Premium "package.json not found. Are you in the project root?" $Colors.Error
    exit 1
}

Write-Section "INSTALLING DEPENDENCIES"

$packages = @(
    @{Name="framer-motion"; Version="latest"},
    @{Name="lucide-react"; Version="latest"},
    @{Name="@radix-ui/react-slot"; Version="latest"},
    @{Name="clsx"; Version="latest"},
    @{Name="tailwind-merge"; Version="latest"},
    @{Name="tailwindcss"; Version="latest"; Dev=$true},
    @{Name="postcss"; Version="latest"; Dev=$true},
    @{Name="autoprefixer"; Version="latest"; Dev=$true}
)

foreach ($pkg in $packages) {
    Install-NpmPackage -Package $pkg.Name -Version $pkg.Version -Dev:$pkg.Dev
}

Write-Section "CREATING DESIGN SYSTEM"

# Create styles directory
$stylesDir = Join-Path $Script:ProjectRoot "src\styles"
if (-not (Test-Path $stylesDir)) {
    New-Item -ItemType Directory -Path $stylesDir -Force | Out-Null
    Write-Premium "Created styles directory" $Colors.Success
}

# Create globals.css
$globalsCss = @"
/* ═══════════════════════════════════════════════════════════════════
   SOVEREIGN OS - PREMIUM DESIGN SYSTEM
   Enterprise Tier v2.0.0
   ═══════════════════════════════════════════════════════════════════ */

:root {
  /* Core Colors - Obsidian Premium */
  --bg-primary: #0a0a0f;
  --bg-secondary: #12121a;
  --bg-tertiary: #1a1a25;
  --bg-elevated: #1e1e2e;
  
  /* Accent Colors - $($Theme.Substring(0,1).ToUpper() + $Theme.Substring(1)) Theme */
$(switch ($Theme) {
    "violet" { "  --accent-primary: #8b5cf6;`n  --accent-secondary: #a78bfa;`n  --accent-glow: rgba(139, 92, 246, 0.3);" }
    "cyan" { "  --accent-primary: #06b6d4;`n  --accent-secondary: #22d3ee;`n  --accent-glow: rgba(6, 182, 212, 0.3);" }
    "emerald" { "  --accent-primary: #10b981;`n  --accent-secondary: #34d399;`n  --accent-glow: rgba(16, 185, 129, 0.3);" }
    "rose" { "  --accent-primary: #f43f5e;`n  --accent-secondary: #fb7185;`n  --accent-glow: rgba(244, 63, 94, 0.3);" }
    "amber" { "  --accent-primary: #f59e0b;`n  --accent-secondary: #fbbf24;`n  --accent-glow: rgba(245, 158, 11, 0.3);" }
})
  
  /* Text Colors */
  --text-primary: #f1f5f9;
  --text-secondary: #94a3b8;
  --text-tertiary: #64748b;
  
  /* Border & Dividers */
  --border-color: rgba(148, 163, 184, 0.1);
  --border-hover: var(--accent-glow);
  
  /* Status Colors */
  --success: #10b981;
  --warning: #f59e0b;
  --error: #ef4444;
  --info: #3b82f6;
  
  /* Spacing System */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
  --spacing-2xl: 3rem;
  
  /* Border Radius */
  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 14px;
  --radius-xl: 20px;
  --radius-2xl: 28px;
  
  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.4);
  --shadow-lg: 0 8px 24px rgba(0, 0, 0, 0.5);
  --shadow-xl: 0 12px 48px rgba(0, 0, 0, 0.6);
  --shadow-glow: 0 0 20px var(--accent-glow);
  --shadow-inner: inset 0 2px 4px rgba(0, 0, 0, 0.3);
  
  /* Transitions */
  --transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1);
  --transition-base: 250ms cubic-bezier(0.4, 0, 0.2, 1);
  --transition-slow: 350ms cubic-bezier(0.4, 0, 0.2, 1);
  --transition-bounce: 500ms cubic-bezier(0.68, -0.55, 0.265, 1.55);
  
  /* Typography */
  --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;
}

/* Reset & Base */
*, *::before, *::after {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html {
  font-size: 16px;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
}

body {
  font-family: var(--font-sans);
  background: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.6;
  overflow: hidden;
  min-height: 100vh;
}

/* Scrollbar Styling */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: var(--bg-secondary);
  border-radius: var(--radius-sm);
}

::-webkit-scrollbar-thumb {
  background: var(--bg-tertiary);
  border-radius: var(--radius-sm);
  transition: background var(--transition-fast);
}

::-webkit-scrollbar-thumb:hover {
  background: var(--accent-primary);
}

/* Selection */
::selection {
  background: var(--accent-glow);
  color: var(--text-primary);
}

/* Focus Visible */
:focus-visible {
  outline: 2px solid var(--accent-primary);
  outline-offset: 2px;
}

/* Animations */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes slideInRight {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

@keyframes glow {
  0%, 100% { box-shadow: 0 0 5px var(--accent-glow); }
  50% { box-shadow: 0 0 20px var(--accent-glow), 0 0 30px var(--accent-glow); }
}

@keyframes shimmer {
  0% { background-position: -1000px 0; }
  100% { background-position: 1000px 0; }
}

.animate-fade-in { animation: fadeIn 0.3s ease-out; }
.animate-slide-up { animation: slideUp 0.4s ease-out; }
.animate-slide-right { animation: slideInRight 0.3s ease-out; }
.animate-pulse { animation: pulse 2s infinite; }
.animate-glow { animation: glow 2s infinite; }

/* Utility Classes */
.glass {
  background: rgba(18, 18, 26, 0.8);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.glass-strong {
  background: rgba(18, 18, 26, 0.95);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
}

.gradient-text {
  background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.shadow-glow {
  box-shadow: var(--shadow-glow);
}

.shadow-premium {
  box-shadow: var(--shadow-lg), var(--shadow-glow);
}

/* Loading Shimmer */
.shimmer {
  background: linear-gradient(
    90deg,
    var(--bg-secondary) 0%,
    var(--bg-tertiary) 50%,
    var(--bg-secondary) 100%
  );
  background-size: 1000px 100%;
  animation: shimmer 2s infinite;
}

/* Responsive */
@media (max-width: 768px) {
  :root {
    --spacing-xl: 1.5rem;
    --spacing-2xl: 2rem;
  }
}
"@

$globalsPath = Join-Path $stylesDir "globals.css"
Backup-File $globalsPath
$globalsCss | Out-File $globalsPath -Encoding UTF8 -Force
Write-Premium "Created: globals.css (Premium Design System)" $Colors.Success

Write-Section "CREATING COMPONENT STYLES"

# Create components.css
$componentsCss = @"
/* ═══════════════════════════════════════════════════════════════════
   SOVEREIGN OS - COMPONENT STYLES
   Enterprise Tier v2.0.0
   ═══════════════════════════════════════════════════════════════════ */

/* ===== LAYOUT ===== */
.sovereign-app {
  display: grid;
  grid-template-columns: 300px 1fr;
  grid-template-rows: 64px 1fr 32px;
  height: 100vh;
  background: var(--bg-primary);
  gap: 1px;
  background-color: var(--border-color);
}

/* ===== SIDEBAR ===== */
.sidebar {
  grid-row: 1 / -1;
  background: var(--bg-secondary);
  border-right: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
  padding: var(--spacing-md);
  gap: var(--spacing-lg);
  overflow-y: auto;
  transition: all var(--transition-base);
}

.sidebar-header {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
  padding: var(--spacing-sm);
  margin-bottom: var(--spacing-md);
}

.sidebar-logo {
  width: 42px;
  height: 42px;
  background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 1.4rem;
  color: white;
  box-shadow: var(--shadow-glow);
  transition: transform var(--transition-bounce);
}

.sidebar-logo:hover {
  transform: scale(1.1) rotate(5deg);
}

.sidebar-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

.sidebar-subtitle {
  font-size: 0.75rem;
  color: var(--text-tertiary);
  font-weight: 500;
}

/* Navigation */
.nav-section {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
}

.nav-section-title {
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--text-tertiary);
  padding: var(--spacing-sm) var(--spacing-md);
  margin-top: var(--spacing-md);
}

.nav-item {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--radius-md);
  color: var(--text-secondary);
  text-decoration: none;
  transition: all var(--transition-fast);
  cursor: pointer;
  border: 1px solid transparent;
  font-weight: 500;
  position: relative;
  overflow: hidden;
}

.nav-item::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: var(--accent-primary);
  transform: scaleY(0);
  transition: transform var(--transition-fast);
}

.nav-item:hover {
  background: var(--bg-tertiary);
  color: var(--text-primary);
  border-color: var(--border-hover);
  transform: translateX(4px);
}

.nav-item:hover::before {
  transform: scaleY(1);
}

.nav-item.active {
  background: var(--bg-elevated);
  color: var(--accent-secondary);
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-sm), var(--shadow-glow);
}

.nav-item.active::before {
  transform: scaleY(1);
}

.nav-icon {
  width: 20px;
  height: 20px;
  opacity: 0.8;
  transition: opacity var(--transition-fast);
}

.nav-item:hover .nav-icon,
.nav-item.active .nav-icon {
  opacity: 1;
}

.nav-badge {
  margin-left: auto;
  padding: 2px 8px;
  background: var(--accent-primary);
  color: white;
  font-size: 0.7rem;
  font-weight: 700;
  border-radius: 10px;
}

/* ===== MAIN CONTENT ===== */
.main-content {
  display: flex;
  flex-direction: column;
  background: var(--bg-primary);
  overflow: hidden;
}

.main-header {
  height: 64px;
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border-color);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--spacing-xl);
  backdrop-filter: blur(10px);
  z-index: 10;
}

.model-selector {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  padding: var(--spacing-sm) var(--spacing-lg);
  background: var(--bg-tertiary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  color: var(--text-primary);
  font-weight: 600;
  cursor: pointer;
  transition: all var(--transition-fast);
  font-size: 0.9rem;
}

.model-selector:hover {
  border-color: var(--accent-primary);
  background: var(--bg-elevated);
  box-shadow: var(--shadow-glow);
  transform: translateY(-1px);
}

.header-actions {
  display: flex;
  gap: var(--spacing-sm);
}

.header-button {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-md);
  border: 1px solid var(--border-color);
  background: var(--bg-tertiary);
  color: var(--text-secondary);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all var(--transition-fast);
}

.header-button:hover {
  background: var(--accent-primary);
  border-color: var(--accent-primary);
  color: white;
  transform: translateY(-2px);
  box-shadow: var(--shadow-glow);
}

/* ===== CHAT AREA ===== */
.chat-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: var(--spacing-2xl);
  display: flex;
  flex-direction: column;
  gap: var(--spacing-lg);
  scroll-behavior: smooth;
}

.message {
  display: flex;
  gap: var(--spacing-md);
  max-width: 85%;
  animation: slideUp 0.3s ease-out;
}

.message.user {
  align-self: flex-end;
  flex-direction: row-reverse;
}

.message.assistant {
  align-self: flex-start;
}

.message-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--bg-tertiary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  flex-shrink: 0;
  border: 2px solid var(--border-color);
  transition: all var(--transition-fast);
}

.message.user .message-avatar {
  background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
  color: white;
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-glow);
}

.message-content {
  background: var(--bg-secondary);
  padding: var(--spacing-md) var(--spacing-lg);
  border-radius: var(--radius-xl);
  border: 1px solid var(--border-color);
  line-height: 1.7;
  font-size: 0.95rem;
  transition: all var(--transition-fast);
}

.message.user .message-content {
  background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
  color: white;
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-md), var(--shadow-glow);
}

.message-content:hover {
  border-color: var(--border-hover);
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

/* Input Area */
.input-container {
  padding: var(--spacing-xl);
  background: var(--bg-secondary);
  border-top: 1px solid var(--border-color);
}

.input-wrapper {
  max-width: 900px;
  margin: 0 auto;
  position: relative;
}

.chat-input {
  width: 100%;
  padding: var(--spacing-md) var(--spacing-xl);
  padding-right: 140px;
  background: var(--bg-tertiary);
  border: 2px solid var(--border-color);
  border-radius: var(--radius-2xl);
  color: var(--text-primary);
  font-size: 0.95rem;
  resize: none;
  outline: none;
  transition: all var(--transition-base);
  font-family: var(--font-sans);
  min-height: 56px;
  max-height: 200px;
}

.chat-input:focus {
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-glow);
  background: var(--bg-elevated);
}

.chat-input::placeholder {
  color: var(--text-tertiary);
}

.input-actions {
  position: absolute;
  right: var(--spacing-md);
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  gap: var(--spacing-sm);
}

.input-button {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-lg);
  border: none;
  background: var(--bg-elevated);
  color: var(--text-secondary);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all var(--transition-fast);
}

.input-button:hover {
  background: var(--accent-primary);
  color: white;
  transform: scale(1.1);
  box-shadow: var(--shadow-glow);
}

.input-button.primary {
  background: var(--accent-primary);
  color: white;
}

.input-button.primary:hover {
  background: var(--accent-secondary);
  box-shadow: var(--shadow-glow);
}

.input-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none !important;
}

/* ===== WORKER GRID ===== */
.worker-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: var(--spacing-md);
  padding: var(--spacing-xl);
}

.worker-card {
  background: var(--bg-secondary);
  border: 2px solid var(--border-color);
  border-radius: var(--radius-xl);
  padding: var(--spacing-lg);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--spacing-sm);
  cursor: pointer;
  transition: all var(--transition-base);
  position: relative;
  overflow: hidden;
}

.worker-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--accent-primary), var(--accent-secondary));
  transform: scaleX(0);
  transition: transform var(--transition-base);
}

.worker-card:hover {
  border-color: var(--accent-primary);
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg), var(--shadow-glow);
}

.worker-card:hover::before {
  transform: scaleX(1);
}

.worker-card.active {
  border-color: var(--accent-primary);
  background: var(--bg-elevated);
  box-shadow: var(--shadow-lg), var(--shadow-glow);
}

.worker-card.active::before {
  transform: scaleX(1);
}

.worker-icon {
  width: 56px;
  height: 56px;
  background: var(--bg-tertiary);
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.8rem;
  transition: all var(--transition-base);
  border: 2px solid var(--border-color);
}

.worker-card:hover .worker-icon {
  background: var(--accent-primary);
  border-color: var(--accent-primary);
  color: white;
  transform: scale(1.1) rotate(5deg);
}

.worker-card.active .worker-icon {
  background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
  border-color: var(--accent-primary);
  color: white;
  box-shadow: var(--shadow-glow);
}

.worker-name {
  font-weight: 700;
  font-size: 0.95rem;
  color: var(--text-primary);
  text-align: center;
}

.worker-description {
  font-size: 0.8rem;
  color: var(--text-tertiary);
  text-align: center;
  line-height: 1.4;
}

.worker-status {
  font-size: 0.75rem;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
  margin-top: var(--spacing-xs);
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--success);
  animation: pulse 2s infinite;
  box-shadow: 0 0 8px var(--success);
}

.status-dot.busy {
  background: var(--warning);
  box-shadow: 0 0 8px var(--warning);
}

.status-dot.error {
  background: var(--error);
  box-shadow: 0 0 8px var(--error);
}

/* ===== STATUS BAR ===== */
.status-bar {
  height: 32px;
  background: var(--bg-secondary);
  border-top: 1px solid var(--border-color);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--spacing-md);
  font-size: 0.8rem;
  color: var(--text-tertiary);
  font-weight: 500;
}

.status-item {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.status-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--success);
  animation: pulse 2s infinite;
}

/* ===== TERMINAL ===== */
.terminal {
  background: #0d0d12;
  border: 2px solid var(--border-color);
  border-radius: var(--radius-lg);
  padding: var(--spacing-md);
  font-family: var(--font-mono);
  font-size: 0.85rem;
  overflow-y: auto;
  max-height: 400px;
}

.terminal-line {
  padding: var(--spacing-xs) 0;
  color: var(--text-secondary);
  font-family: var(--font-mono);
}

.terminal-line.success { color: var(--success); }
.terminal-line.error { color: var(--error); }
.terminal-line.warning { color: var(--warning); }
.terminal-line.info { color: var(--info); }
.terminal-line.accent { color: var(--accent-secondary); }

/* ===== BUTTONS ===== */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-sm);
  padding: var(--spacing-sm) var(--spacing-lg);
  border-radius: var(--radius-lg);
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all var(--transition-fast);
  border: 2px solid transparent;
  text-decoration: none;
}

.btn-primary {
  background: var(--accent-primary);
  color: white;
  border-color: var(--accent-primary);
}

.btn-primary:hover {
  background: var(--accent-secondary);
  border-color: var(--accent-secondary);
  box-shadow: var(--shadow-glow);
  transform: translateY(-2px);
}

.btn-secondary {
  background: var(--bg-tertiary);
  color: var(--text-primary);
  border-color: var(--border-color);
}

.btn-secondary:hover {
  background: var(--bg-elevated);
  border-color: var(--accent-primary);
  color: var(--accent-secondary);
}

.btn-ghost {
  background: transparent;
  color: var(--text-secondary);
  border-color: transparent;
}

.btn-ghost:hover {
  background: var(--bg-tertiary);
  color: var(--text-primary);
}

/* ===== CARDS ===== */
.card {
  background: var(--bg-secondary);
  border: 2px solid var(--border-color);
  border-radius: var(--radius-xl);
  padding: var(--spacing-lg);
  transition: all var(--transition-base);
}

.card:hover {
  border-color: var(--border-hover);
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}

.card-premium {
  background: linear-gradient(135deg, var(--bg-secondary), var(--bg-elevated));
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-glow);
}

/* ===== BADGES ===== */
.badge {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.badge-primary {
  background: var(--accent-glow);
  color: var(--accent-secondary);
  border: 1px solid var(--accent-primary);
}

.badge-success {
  background: rgba(16, 185, 129, 0.2);
  color: var(--success);
  border: 1px solid var(--success);
}

.badge-warning {
  background: rgba(245, 158, 11, 0.2);
  color: var(--warning);
  border: 1px solid var(--warning);
}

.badge-error {
  background: rgba(239, 68, 68, 0.2);
  color: var(--error);
  border: 1px solid var(--error);
}

/* ===== LOADING STATES ===== */
.loading-skeleton {
  background: linear-gradient(
    90deg,
    var(--bg-secondary) 25%,
    var(--bg-tertiary) 50%,
    var(--bg-secondary) 75%
  );
  background-size: 1000px 100%;
  animation: shimmer 2s infinite;
  border-radius: var(--radius-md);
}

.loading-dots {
  display: flex;
  gap: var(--spacing-xs);
}

.loading-dots span {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent-primary);
  animation: pulse 1.4s infinite;
}

.loading-dots span:nth-child(2) { animation-delay: 0.2s; }
.loading-dots span:nth-child(3) { animation-delay: 0.4s; }

/* ===== RESPONSIVE ===== */
@media (max-width: 1024px) {
  .sovereign-app {
    grid-template-columns: 260px 1fr;
  }
}

@media (max-width: 768px) {
  .sovereign-app {
    grid-template-columns: 1fr;
  }
  
  .sidebar {
    display: none;
  }
  
  .worker-grid {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  }
  
  .message {
    max-width: 95%;
  }
  
  .chat-messages {
    padding: var(--spacing-lg);
  }
}

@media (max-width: 480px) {
  .worker-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .input-actions {
    right: var(--spacing-sm);
  }
  
  .input-button {
    width: 36px;
    height: 36px;
  }
}
"@

$componentsPath = Join-Path $stylesDir "components.css"
Backup-File $componentsPath
$componentsCss | Out-File $componentsPath -Encoding UTF8 -Force
Write-Premium "Created: components.css (Component Styles)" $Colors.Success

Write-Section "UPDATING INDEX.HTML"

# Update index.html with fonts
$indexPath = Join-Path $Script:ProjectRoot "public\index.html"
if (-not (Test-Path $indexPath)) {
    $indexPath = Join-Path $Script:ProjectRoot "index.html"
}

if (Test-Path $indexPath) {
    Backup-File $indexPath
    
    $indexContent = Get-Content $indexPath -Raw
    
    # Add fonts if not present
    if ($indexContent -notmatch "fonts.googleapis.com") {
        $fontLink = @"
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
"@
        $indexContent = $indexContent.Replace('</head>', "$fontLink`n  </head>")
        $indexContent | Out-File $indexPath -Encoding UTF8 -Force
        Write-Premium "Added Google Fonts (Inter + JetBrains Mono)" $Colors.Success
    }
}
else {
    Write-Premium "index.html not found - skipping font update" $Colors.Warning
}

Write-Section "CREATING THEME CONFIGURATION"

# Create theme config
$themeConfig = @"
// Sovereign OS - Theme Configuration
// Enterprise Tier v2.0.0

export const themes = {
  violet: {
    name: 'Violet',
    colors: {
      primary: '#8b5cf6',
      secondary: '#a78bfa',
      glow: 'rgba(139, 92, 246, 0.3)'
    }
  },
  cyan: {
    name: 'Cyan',
    colors: {
      primary: '#06b6d4',
      secondary: '#22d3ee',
      glow: 'rgba(6, 182, 212, 0.3)'
    }
  },
  emerald: {
    name: 'Emerald',
    colors: {
      primary: '#10b981',
      secondary: '#34d399',
      glow: 'rgba(16, 185, 129, 0.3)'
    }
  },
  rose: {
    name: 'Rose',
    colors: {
      primary: '#f43f5e',
      secondary: '#fb7185',
      glow: 'rgba(244, 63, 94, 0.3)'
    }
  },
  amber: {
    name: 'Amber',
    colors: {
      primary: '#f59e0b',
      secondary: '#fbbf24',
      glow: 'rgba(245, 158, 11, 0.3)'
    }
  }
}

export const currentTheme = themes.$Theme
"@

$themePath = Join-Path $Script:ProjectRoot "src\lib\theme.ts"
if (-not (Test-Path (Split-Path $themePath -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $themePath -Parent) -Force | Out-Null
}
$themeConfig | Out-File $themePath -Encoding UTF8 -Force
Write-Premium "Created: theme.ts (Theme Configuration)" $Colors.Success

Write-Section "FINALIZING INSTALLATION"

# Update package.json if needed
if (Test-Path "package.json") {
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    
    # Add scripts if not present
    if (-not $packageJson.scripts.dev) {
        $packageJson.scripts |= @{"dev" = "next dev"}
    }
    if (-not $packageJson.scripts.build) {
        $packageJson.scripts |= @{"build" = "next build"}
    }
    
    $packageJson | ConvertTo-Json -Depth 10 | Out-File "package.json" -Encoding UTF8 -Force
    Write-Premium "Updated package.json scripts" $Colors.Success
}

# Create README for the UI
$readmeContent = @"
# Sovereign OS - Premium UI

## Design System

This installation includes the Enterprise Tier design system with:

### Features
- ✓ Premium color palette (Obsidian theme)
- ✓ 5 theme variants (Violet, Cyan, Emerald, Rose, Amber)
- ✓ Smooth animations & transitions
- ✓ Glass morphism effects
- ✓ Custom scrollbar styling
- ✓ Responsive design
- ✓ Accessibility features
- ✓ Professional typography

### Components Styled
- Sidebar navigation
- Chat interface
- Worker grid
- Status indicators
- Terminal/logs
- Buttons & cards
- Input fields
- Badges & tags

### Color Themes

Current Theme: **$($Theme.Substring(0,1).ToUpper() + $Theme.Substring(1))**

To change theme, run:
\`\`\`powershell
.\\install-ui.ps1 -Theme cyan
.\\install-ui.ps1 -Theme emerald
.\\install-ui.ps1 -Theme rose
.\\install-ui.ps1 -Theme amber
\`\`\`

### Files Modified
- \`src/styles/globals.css\` - Core design system
- \`src/styles/components.css\` - Component styles
- \`src/lib/theme.ts\` - Theme configuration
- \`public/index.html\` - Font imports

### Usage

Import styles in your main app file:
\`\`\`typescript
import '@/styles/globals.css'
import '@/styles/components.css'
\`\`\`

Apply classes:
\`\`\`tsx
<div className="sovereign-app">
  <div className="sidebar">...</div>
  <div className="main-content">...</div>
</div>
\`\`\`

---

**Version**: 2.0.0 Enterprise Tier  
**Installed**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Theme**: $Theme
"@

$readmePath = Join-Path $stylesDir "README.md"
$readmeContent | Out-File $readmePath -Encoding UTF8 -Force
Write-Premium "Created: styles/README.md (Documentation)" $Colors.Success

Write-Section "INSTALLATION COMPLETE"

$duration = (Get-Date) - $Script:StartTime
Write-Premium "✓ Premium UI installation completed successfully!" $Colors.Success
Write-Premium "  Duration: $($duration.TotalSeconds.ToString('0.0')) seconds" $Colors.Info
Write-Premium "  Theme: $($Theme.Substring(0,1).ToUpper() + $Theme.Substring(1))" $Colors.Info
Write-Premium "  Backup: $(if ($SkipBackup) { 'Skipped' } else { $Script:BackupPath })" $Colors.Info

Write-Host "`n╔$("$("=" * 75))╗" -ForegroundColor Green
Write-Host "║  NEXT STEPS" -ForegroundColor Green
Write-Host "╚$("$("=" * 75))╝" -ForegroundColor Green

Write-Host "`n1. Start development server:" -ForegroundColor Cyan
Write-Host "   npm run dev" -ForegroundColor White

Write-Host "`n2. Open browser:" -ForegroundColor Cyan
Write-Host "   http://localhost:3000" -ForegroundColor White

Write-Host "`n3. View documentation:" -ForegroundColor Cyan
Write-Host "   src/styles/README.md" -ForegroundColor White

Write-Host "`n4. Change theme (optional):" -ForegroundColor Cyan
Write-Host "   .\install-ui.ps1 -Theme cyan" -ForegroundColor White

Write-Host "`n"
Write-Host "  🦊 Enjoy your premium Sovereign OS interface!" -ForegroundColor Magenta
Write-Host "  ★ Enterprise Tier v2.0.0" -ForegroundColor Gray
Write-Host "`n"

# Summary
if ($Script:Errors.Count -gt 0) {
    Write-Section "WARNINGS & ERRORS"
    foreach ($error in $Script:Errors) {
        Write-Premium $error $Colors.Warning
    }
}

exit 0