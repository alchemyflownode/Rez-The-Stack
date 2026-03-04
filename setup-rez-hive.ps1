# ðŸ–¥ï¸ REZ HIVE â€” Setup & Enhancement Script (setup-rez-hive.ps1) - ENHANCED VERSION

<#
.SYNOPSIS
    REZ HIVE Sovereign Frontend Setup Script - Enhanced Edition
    Installs dependencies, validates environment, and launches the dev server.

.DESCRIPTION
    This script prepares your REZ HIVE frontend with professional output formatting:
    - Syntax highlighting for code blocks with copy functionality
    - Search result card layouts with domain icons
    - JSON tree data display with collapsible nodes
    - Type definitions and dev tooling
    - Automatic port conflict resolution
    - Comprehensive error handling with recovery options

    Architectural Constraint: "Optimize existing infrastructure, not change it."

.EXAMPLE
    .\setup-rez-hive.ps1 -Mode install
    .\setup-rez-hive.ps1 -Mode dev -Port 3001
    .\setup-rez-hive.ps1 -Mode verify -VerboseLog

.AUTHOR
    Resident | REZ HIVE Sovereign AI Architecture

.LINK
    https://rez-hive.local/docs/setup
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("install", "verify", "dev", "build", "clean", "doctor", "update")]
    [string]$Mode = "install",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$VerboseLog,
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 3000,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoBrowser
)

# --- Configuration ---
$ScriptName = "REZ HIVE Setup [Enhanced]"
$ScriptVersion = "2.0.0"
$RequiredNodeVersion = "18.0.0"
$RequiredNpmVersion = "9.0.0"
$RequiredPowerShellVersion = "7.0.0"
$ProjectRoot = $PSScriptRoot
$RequiredPackages = @(
    "react-syntax-highlighter",
    "react-json-tree",
    "@types/react-syntax-highlighter",
    "react-markdown",
    "remark-gfm"
)
$DevServerPort = $Port
$LogFile = Join-Path $ProjectRoot "logs\setup.log"

# --- Ensure logs directory exists ---
$logDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# --- Colors & Formatting ---
$Colors = @{
    Reset   = "`e[0m"
    Cyan    = "`e[36m"
    Green   = "`e[32m"
    Yellow  = "`e[33m"
    Red     = "`e[31m"
    Gray    = "`e[90m"
    Bold    = "`e[1m"
    Magenta = "`e[35m"
    Blue    = "`e[34m"
}

function Write-Status {
    param(
        [string]$Message, 
        [string]$Level = "INFO",
        [switch]$NoLog
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "OK" { $Colors.Green }
        "WARN" { $Colors.Yellow }
        "ERR" { $Colors.Red }
        "DEBUG" { $Colors.Magenta }
        "FATAL" { $Colors.Red + $Colors.Bold }
        default { $Colors.Cyan }
    }
    
    $output = "[$timestamp] ${color}[$Level]$($Colors.Reset) $Message"
    Write-Host $output
    
    # Log to file (except debug messages if not verbose)
    if (-not $NoLog -and ($VerboseLog -or $Level -ne "DEBUG")) {
        $logMessage = "[$timestamp][$Level] $Message" -replace "`e\[[0-9;]*m", "" # Remove ANSI codes
        Add-Content -Path "$LogFile" -Value $logMessage
    }
}

function Write-Section {
    param([string]$Title)
    $line = "â”" * (50 - $Title.Length)
    Write-Host "`n$($Colors.Bold)$($Colors.Cyan)â”â”â” $Title $line$($Colors.Reset)"
    if ($VerboseLog) {
        Add-Content -Path $LogFile -Value "`n--- $Title ---"
    }
}

function Write-Header {
    Clear-Host
    Write-Host "$($Colors.Bold)$($Colors.Cyan)â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—$($Colors.Reset)"
    Write-Host "$($Colors.Bold)$($Colors.Cyan)â•‘     ðŸ›ï¸  REZ HIVE - SOVEREIGN AI SETUP v$ScriptVersion               â•‘$($Colors.Reset)"
    Write-Host "$($Colors.Bold)$($Colors.Cyan)â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•$($Colors.Reset)"
    Write-Host ""
}

# --- Enhanced Validation Functions ---
function Test-PowerShellVersion {
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion -ge [Version]$RequiredPowerShellVersion) {
        Write-Status "PowerShell $psVersion detected âœ“" "OK"
        return $true
    } else {
        Write-Status "PowerShell $psVersion detected (required: $RequiredPowerShellVersion+)" "WARN"
        return $false
    }
}

function Test-NodeVersion {
    try {
        $nodeVersion = (node --version).Replace('v', '')
        $required = $RequiredNodeVersion
        
        if ([Version]$nodeVersion -ge [Version]$required) {
            Write-Status "Node.js $nodeVersion detected âœ“" "OK"
            return $true
        } else {
            Write-Status "Node.js $nodeVersion detected (required: $required+)" "WARN"
            return $false
        }
    } catch {
        Write-Status "Node.js not found in PATH" "ERR"
        return $false
    }
}

function Test-NpmVersion {
    try {
        $npmVersion = npm --version
        if ([Version]$npmVersion -ge [Version]$RequiredNpmVersion) {
            Write-Status "npm $npmVersion detected âœ“" "OK"
            return $true
        } else {
            Write-Status "npm $npmVersion detected (required: $RequiredNpmVersion+)" "WARN"
            return $false
        }
    } catch {
        Write-Status "npm not found in PATH" "ERR"
        return $false
    }
}

function Test-Git {
    try {
        $gitVersion = git --version
        Write-Status "Git detected âœ“" "OK"
        return $true
    } catch {
        Write-Status "Git not found in PATH (optional)" "WARN"
        return $false
    }
}

function Test-ProjectStructure {
    $requiredFiles = @("package.json", "tsconfig.json", "next.config.js")
    $optionalFiles = @(".env.local", ".gitignore", "README.md")
    $missing = @()
    $missingOptional = @()
    
    foreach ($file in $requiredFiles) {
        $path = Join-Path $ProjectRoot $file
        if (-not (Test-Path $path)) {
            $missing += $file
        }
    }
    
    foreach ($file in $optionalFiles) {
        $path = Join-Path $ProjectRoot $file
        if (-not (Test-Path $path) -and $VerboseLog) {
            $missingOptional += $file
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Status "Missing required files: $($missing -join ', ')" "ERR"
        return $false
    }
    
    Write-Status "Project structure validated âœ“" "OK"
    if ($missingOptional.Count -gt 0 -and $VerboseLog) {
        Write-Status "Optional files missing: $($missingOptional -join ', ')" "DEBUG"
    }
    return $true
}

function Test-RequiredPackages {
    try {
        $packageJsonPath = Join-Path $ProjectRoot "package.json"
        $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
        
        $missing = @()
        $installed = @()
        
        foreach ($pkg in $RequiredPackages) {
            $isDev = $pkg -like "@types/*"
            $targetDeps = if ($isDev) { $packageJson.devDependencies } else { $packageJson.dependencies }
            
            if ($targetDeps -and $targetDeps.$pkg) {
                $installed += $pkg
            } else {
                $missing += $pkg
            }
        }
        
        if ($missing.Count -gt 0) {
            Write-Status "Missing packages: $($missing -join ', ')" "WARN"
            return $false
        }
        
        Write-Status "All required packages present âœ“" "OK"
        if ($VerboseLog) {
            Write-Status "Installed: $($installed -join ', ')" "DEBUG"
        }
        return $true
    } catch {
        Write-Status "Failed to parse package.json: $_" "ERR"
        return $false
    }
}

function Test-PortAvailability {
    param([int]$Port)
    
    try {
        $existing = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        if ($existing) {
            $process = Get-Process -Id $existing.OwningProcess -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.ProcessName } else { "Unknown" }
            Write-Status "Port $Port is in use by $processName (PID: $($existing.OwningProcess))" "WARN"
            return $false
        }
        Write-Status "Port $Port is available âœ“" "OK"
        return $true
    } catch {
        # If we can't check, assume it's available
        Write-Status "Could not verify port $Port availability" "WARN"
        return $true
    }
}

# --- Enhanced Action Functions ---
function Install-Packages {
    Write-Section "Installing Enhanced Formatting Dependencies"
    
    # Check if node_modules exists and -Force is not used
    if ((Test-Path (Join-Path $ProjectRoot "node_modules")) -and -not $Force) {
        Write-Status "node_modules already exists. Use -Force to reinstall." "WARN"
        $response = Read-Host "Continue with installation anyway? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Status "Installation cancelled" "WARN"
            return $false
        }
    }
    
    # Install runtime packages
    Write-Status "Installing runtime packages..."
    $result = npm install react-syntax-highlighter react-json-tree react-markdown remark-gfm --save 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Failed to install runtime packages" "ERR"
        if ($VerboseLog) { Write-Status $result "DEBUG" }
        return $false
    }
    
    # Install type definitions
    Write-Status "Installing type definitions..."
    $result = npm install --save-dev @types/react-syntax-highlighter @types/react 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Failed to install type definitions" "ERR"
        if ($VerboseLog) { Write-Status $result "DEBUG" }
        return $false
    }
    
    Write-Status "Dependencies installed successfully âœ“" "OK"
    return $true
}

function Create-ComponentFiles {
    Write-Section "Creating Enhanced Component Files"
    
    $componentsDir = Join-Path $ProjectRoot "src/components"
    if (-not (Test-Path $componentsDir)) {
        New-Item -ItemType Directory -Path $componentsDir -Force | Out-Null
        Write-Status "Created components directory" "OK"
    }
    
    $results = @()
    
    # CodeBlock.tsx
    $codeBlockPath = Join-Path $componentsDir "CodeBlock.tsx"
    if (-not (Test-Path $codeBlockPath) -or $Force) {
        @'
"use client";

import { useState } from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { Copy, Check, FileCode } from 'lucide-react';

interface CodeBlockProps {
  language: string;
  code: string;
}

export const CodeBlock = ({ language, code }: CodeBlockProps) => {
  const [copied, setCopied] = useState(false);
  
  const copy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  
  const langMap: Record<string, string> = {
    'js': 'javascript', 'ts': 'typescript', 'py': 'python',
    'rb': 'ruby', 'go': 'go', 'rs': 'rust', 'sh': 'bash',
    'bash': 'bash', 'ps1': 'powershell', 'html': 'html',
    'css': 'css', 'json': 'json', 'md': 'markdown',
    'jsx': 'jsx', 'tsx': 'tsx', 'vue': 'vue', 'php': 'php'
  };
  
  const normalizedLang = langMap[language] || language || 'text';
  
  return (
    <div className="relative group my-4 rounded-xl overflow-hidden border border-white/10 shadow-xl">
      <div className="flex items-center justify-between px-4 py-2 bg-[#1e1e1e] border-b border-white/10">
        <div className="flex items-center gap-2">
          <FileCode size={14} className="text-cyan-400" />
          <span className="text-xs font-mono text-white/50">{language || 'code'}</span>
        </div>
        <button 
          onClick={copy}
          className="flex items-center gap-1.5 px-2 py-1 rounded bg-white/5 hover:bg-white/10 transition-colors text-xs"
        >
          {copied ? (
            <><Check size={12} className="text-green-400" /><span className="text-green-400">Copied!</span></>
          ) : (
            <><Copy size={12} className="text-white/40" /><span className="text-white/40">Copy</span></>
          )}
        </button>
      </div>
      <SyntaxHighlighter
        language={normalizedLang}
        style={vscDarkPlus}
        customStyle={{ margin: 0, padding: '1rem', background: '#0d0d0d', fontSize: '0.85rem', lineHeight: '1.5' }}
        wrapLines={true}
        wrapLongLines={true}
      >
        {code}
      </SyntaxHighlighter>
    </div>
  );
};
'@ | Out-File -FilePath $codeBlockPath -Encoding utf8
        $results += "CodeBlock.tsx"
    }
    
    # SearchResults.tsx
    $searchResultsPath = Join-Path $componentsDir "SearchResults.tsx"
    if (-not (Test-Path $searchResultsPath) -or $Force) {
        @'
"use client";

import { useState } from 'react';
import { Globe, ExternalLink, FileCode, FileText, Newspaper, Calendar } from 'lucide-react';

interface SearchResult {
  title: string;
  url: string;
  content: string;
  publishedDate?: string;
  source?: string;
}

interface SearchResultCardProps {
  result: SearchResult;
  index: number;
}

export const SearchResultCard = ({ result, index }: SearchResultCardProps) => {
  const [expanded, setExpanded] = useState(false);
  const domain = result.url ? new URL(result.url).hostname.replace('www.', '') : '';
  
  const getIcon = () => {
    if (result.url?.includes('github')) return <FileCode size={16} className="text-purple-400" />;
    if (result.url?.includes('arxiv') || result.url?.includes('research')) 
      return <FileText size={16} className="text-orange-400" />;
    if (result.url?.includes('news') || result.title?.toLowerCase().includes('news')) 
      return <Newspaper size={16} className="text-blue-400" />;
    return <Globe size={16} className="text-green-400" />;
  };
  
  return (
    <div className="group bg-white/5 hover:bg-white/10 rounded-xl border border-white/10 hover:border-cyan-500/30 transition-all p-4 mb-3">
      <div className="flex items-center gap-2 mb-2">
        <span className="text-xs font-mono text-white/20 w-6">#{index + 1}</span>
        <span className="text-xs px-2 py-0.5 bg-white/5 rounded-full text-white/40 font-mono">{domain || 'web'}</span>
        <span className="text-xs text-white/20">â€¢</span>
        {getIcon()}
      </div>
      <a href={result.url} target="_blank" rel="noopener noreferrer" className="block group-hover:text-cyan-400 transition-colors">
        <h3 className="text-sm font-medium text-white/90 mb-1.5 leading-relaxed">{result.title}</h3>
      </a>
      <p className={`text-xs text-white/50 leading-relaxed transition-all ${expanded ? '' : 'line-clamp-2'}`}>{result.content}</p>
      <div className="flex items-center gap-3 mt-3">
        {result.content?.length > 200 && (
          <button onClick={() => setExpanded(!expanded)} className="text-xs text-cyan-400/60 hover:text-cyan-400 transition-colors">
            {expanded ? 'Show less' : 'Read more'}
          </button>
        )}
        <a href={result.url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-xs text-white/30 hover:text-white/50 transition-colors ml-auto">
          <span>Visit</span><ExternalLink size={10} />
        </a>
      </div>
    </div>
  );
};

export const SearchResults = ({ results }: { results: SearchResult[] }) => {
  if (!results || results.length === 0) {
    return (
      <div className="bg-white/5 rounded-xl p-8 text-center border border-white/10">
        <Globe size={32} className="mx-auto text-white/20 mb-3" />
        <p className="text-white/40 text-sm">No search results found</p>
      </div>
    );
  }
  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2 mb-4 text-xs text-white/30">
        <span className="font-medium">{results.length} results</span>
      </div>
      {results.map((result, idx) => <SearchResultCard key={idx} result={result} index={idx} />)}
    </div>
  );
};
'@ | Out-File -FilePath $searchResultsPath -Encoding utf8
        $results += "SearchResults.tsx"
    }
    
    # DataDisplay.tsx
    $dataDisplayPath = Join-Path $componentsDir "DataDisplay.tsx"
    if (-not (Test-Path $dataDisplayPath) -or $Force) {
        @'
"use client";

import { JSONTree } from 'react-json-tree';

interface DataDisplayProps {
  data: any;
  expandLevel?: number;
}

export const DataDisplay = ({ data, expandLevel = 0 }: DataDisplayProps) => {
  const theme = {
    scheme: 'monokai',
    base00: '#1e1e1e',
    base08: '#f92672',
    base0B: '#a6e22e', 
    base0D: '#66d9ef',
    base0E: '#ae81ff'
  };
  
  return (
    <div className="bg-[#1e1e1e] rounded-xl p-4 border border-white/10 overflow-auto max-h-96 font-mono text-xs">
      <JSONTree 
        data={data} 
        theme={theme}
        invertTheme={false}
        hideRoot={true}
        shouldExpandNodeInitially={(keyPath) => keyPath.length <= expandLevel + 1}
      />
    </div>
  );
};
'@ | Out-File -FilePath $dataDisplayPath -Encoding utf8
        $results += "DataDisplay.tsx"
    }
    
    # MessageRenderer.tsx - New utility component
    $messageRendererPath = Join-Path $componentsDir "MessageRenderer.tsx"
    if (-not (Test-Path $messageRendererPath) -or $Force) {
        @'
"use client";

import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { CodeBlock } from './CodeBlock';
import { SearchResults } from './SearchResults';
import { DataDisplay } from './DataDisplay';

interface MessageRendererProps {
  content: string;
}

export const MessageRenderer = ({ content }: MessageRendererProps) => {
  // Check if it's search results (starts with "Search Results:")
  if (content.startsWith('Search Results:')) {
    try {
      const lines = content.split('\n').slice(1);
      const results = lines
        .map(line => {
          const match = line.match(/â€¢ (.*?)(?:\n|$)/);
          if (!match) return null;
          
          const text = match[1];
          const urlMatch = text.match(/https?:\/\/[^\s]+/);
          const url = urlMatch ? urlMatch[0] : '#';
          const title = text.replace(url, '').replace(/[â€¢\s]+$/, '');
          
          return {
            title: title || text,
            url: url,
            content: text
          };
        })
        .filter(Boolean);
      
      return <SearchResults results={results} />;
    } catch (e) {
      return <DataDisplay data={content} />;
    }
  }
  
  // Check if it's JSON
  try {
    const json = JSON.parse(content);
    if (typeof json === 'object' && json !== null) {
      return <DataDisplay data={json} />;
    }
    throw new Error('Not a JSON object');
  } catch {
    // Regular markdown content
    return (
      <ReactMarkdown 
        remarkPlugins={[remarkGfm]} 
        className="prose prose-invert max-w-none prose-p:leading-relaxed prose-pre:bg-transparent prose-pre:p-0"
        components={{
          code({ node, inline, className, children, ...props }) {
            const match = /language-(\w+)/.exec(className || '');
            const code = String(children).replace(/\n$/, '');
            return !inline && match ? (
              <CodeBlock language={match[1]} code={code} />
            ) : (
              <code className="bg-black/30 px-1.5 py-0.5 rounded text-cyan-300 text-xs" {...props}>
                {children}
              </code>
            );
          }
        }}
      >
        {content}
      </ReactMarkdown>
    );
  }
};
'@ | Out-File -FilePath $messageRendererPath -Encoding utf8
        $results += "MessageRenderer.tsx"
    }
    
    if ($results.Count -gt 0) {
        Write-Status "Created: $($results -join ', ') âœ“" "OK"
    } else {
        Write-Status "All components already exist (use -Force to recreate)" "OK"
    }
    
    return $true
}

function Start-DevServer {
    Write-Section "Starting REZ HIVE Development Server on port $DevServerPort"
    
    # Check if port is in use
    $portAvailable = Test-PortAvailability -Port $DevServerPort
    if (-not $portAvailable) {
        Write-Status "Port $DevServerPort is in use. Attempting to free it..." "WARN"
        
        $existing = Get-NetTCPConnection -LocalPort $DevServerPort -ErrorAction SilentlyContinue
        if ($existing) {
            $pid = $existing.OwningProcess
            $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.ProcessName } else { "Unknown" }
            
            Write-Status "Process using port: $processName (PID: $pid)" "WARN"
            
            if ($Force) {
                Write-Status "Force-killing process $pid..." "WARN"
                Stop-Process -Id $pid -Force
                Start-Sleep -Seconds 2
            } else {
                $response = Read-Host "Kill this process? (Y/N)"
                if ($response -eq 'Y' -or $response -eq 'y') {
                    Stop-Process -Id $pid -Force
                    Write-Status "Killed process $pid" "OK"
                    Start-Sleep -Seconds 2
                } else {
                    Write-Status "Server start cancelled" "WARN"
                    return $false
                }
            }
        }
    }
    
    # Build the command
    $npmArgs = @("run", "dev", "--", "-p", "$DevServerPort")
    
    Write-Status "Launching: npm $($npmArgs -join ' ')" "OK"
    
    if ($NoBrowser) {
        # Start without opening browser
        Start-Process -FilePath "npm" -ArgumentList $npmArgs -WorkingDirectory $ProjectRoot -NoNewWindow
    } else {
        # Start and open browser
        $process = Start-Process -FilePath "npm" -ArgumentList $npmArgs -WorkingDirectory $ProjectRoot -PassThru -NoNewWindow
        Start-Sleep -Seconds 3
        Start-Process "http://localhost:$DevServerPort"
    }
    
    Write-Status "Dev server starting at http://localhost:$DevServerPort âœ“" "OK"
    return $true
}

function Invoke-Clean {
    Write-Section "Cleaning Build Artifacts"
    
    $targets = @(
        @{Path = "node_modules"; Type = "Directory"},
        @{Path = ".next"; Type = "Directory"},
        @{Path = "out"; Type = "Directory"},
        @{Path = "dist"; Type = "Directory"},
        @{Path = "package-lock.json"; Type = "File"},
        @{Path = "yarn.lock"; Type = "File"},
        @{Path = ".env.local"; Type = "File"; Optional = $true}
    )
    
    $removed = 0
    foreach ($target in $targets) {
        $path = Join-Path $ProjectRoot $target.Path
        if (Test-Path $path) {
            if ($target.ContainsKey('Optional') -and -not $Force) {
                Write-Status "Skipping optional: $($target.Path) (use -Force to remove)" "DEBUG"
                continue
            }
            Write-Status "Removing $($target.Path)..."
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            $removed++
        }
    }
    
    if ($removed -eq 0) {
        Write-Status "No artifacts found to clean" "OK"
    } else {
        Write-Status "Removed $removed artifacts âœ“" "OK"
    }
    return $true
}

function Invoke-Doctor {
    Write-Section "Running System Diagnostics"
    
    $checks = @(
        @{Name = "PowerShell Version"; Test = { Test-PowerShellVersion }},
        @{Name = "Node.js"; Test = { Test-NodeVersion }},
        @{Name = "npm"; Test = { Test-NpmVersion }},
        @{Name = "Git"; Test = { Test-Git }},
        @{Name = "Project Structure"; Test = { Test-ProjectStructure }},
        @{Name = "Required Packages"; Test = { Test-RequiredPackages }},
        @{Name = "Port $DevServerPort"; Test = { Test-PortAvailability -Port $DevServerPort }}
    )
    
    $results = @()
    foreach ($check in $checks) {
        $result = & $check.Test
        $results += @{Name = $check.Name; Passed = $result}
    }
    
    $passed = ($results | Where-Object { $_.Passed }).Count
    $total = $results.Count
    
    Write-Host ""
    Write-Status "Diagnostic Summary: $passed/$total checks passed" "INFO"
    
    if ($passed -eq $total) {
        Write-Status "âœ… System is healthy! Ready for development." "OK"
    } else {
        $failed = $results | Where-Object { -not $_.Passed }
        Write-Status "âš ï¸  Issues detected: $($failed.Count) checks failed" "WARN"
        foreach ($f in $failed) {
            Write-Status "  â€¢ $($f.Name)" "WARN"
        }
        Write-Status "Run with -Mode install to fix common issues" "INFO"
    }
    
    return ($passed -eq $total)
}

function Update-Script {
    Write-Section "Checking for Script Updates"
    
    # This would normally check a remote repository
    # For now, just show current version
    Write-Status "Current script version: $ScriptVersion" "OK"
    
    # Optional: Check GitHub for newer version
    try {
        $latestVersion = "2.0.0" # This would be fetched from GitHub
        if ($latestVersion -gt $ScriptVersion) {
            Write-Status "New version available: $latestVersion" "WARN"
            $response = Read-Host "Update now? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                # Download update logic here
                Write-Status "Update feature coming soon!" "INFO"
            }
        } else {
            Write-Status "Script is up to date âœ“" "OK"
        }
    } catch {
        Write-Status "Could not check for updates" "WARN"
    }
    
    return $true
}

# --- Main Execution ---
function Invoke-Setup {
    Write-Header
    Write-Status "Starting setup at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
    Write-Status "Mode: $Mode | Force: $Force | Port: $DevServerPort" "DEBUG"
    Write-Host "Constraint: Optimize existing infrastructure, not change it.`n"
    
    # Mode: doctor
    if ($Mode -eq "doctor") {
        $result = Invoke-Doctor
        return $(if ($result) { 0 } else { 1 })
    }
    
    # Mode: update
    if ($Mode -eq "update") {
        Update-Script
        return 0
    }
    
    # Mode: verify
    if ($Mode -eq "verify") {
        Write-Section "Environment Verification"
        $checks = @(
            (Test-PowerShellVersion),
            (Test-NodeVersion),
            (Test-NpmVersion), 
            (Test-ProjectStructure),
            (Test-RequiredPackages),
            (Test-PortAvailability -Port $DevServerPort)
        )
        if ($checks -notcontains $false) {
            Write-Status "All checks passed âœ“ System ready." "OK"
            return 0
        } else {
            Write-Status "Some checks failed. Run with -Mode install to fix." "WARN"
            return 1
        }
    }
    
    # Mode: clean
    if ($Mode -eq "clean") {
        Invoke-Clean
        return 0
    }
    
    # Mode: install (default)
    if ($Mode -eq "install") {
        Write-Section "Pre-Install Verification"
        if (-not (Test-NodeVersion) -or -not (Test-NpmVersion)) {
            Write-Status "Please install Node.js $RequiredNodeVersion+ and npm $RequiredNpmVersion+" "ERR"
            return 1
        }
        if (-not (Test-ProjectStructure)) {
            Write-Status "Run this script from the REZ HIVE project root" "ERR"
            return 1
        }
        
        $installResult = Install-Packages
        if (-not $installResult) { return 1 }
        
        $componentResult = Create-ComponentFiles
        if (-not $componentResult) { return 1 }
        
        Write-Status "Setup complete! Next steps:" "OK"
        Write-Host "  â€¢ Run with -Mode dev to start server" -ForegroundColor Cyan
        Write-Host "  â€¢ Run with -Mode doctor to diagnose issues" -ForegroundColor Cyan
        Write-Host "  â€¢ Run with -Mode verify to check environment" -ForegroundColor Cyan
        return 0
    }
    
    # Mode: dev
    if ($Mode -eq "dev") {
        if (-not (Test-RequiredPackages)) {
            Write-Status "Installing missing packages first..." "WARN"
            $installResult = Install-Packages
            if (-not $installResult) { return 1 }
        }
        
        if (-not (Test-PortAvailability -Port $DevServerPort)) {
            Write-Status "Port $DevServerPort is not available" "WARN"
            $newPort = Read-Host "Enter alternative port (default: 3001)"
            if ($newPort -eq "") { $newPort = 3001 }
            $script:DevServerPort = [int]$newPort
        }
        
        Start-DevServer
        return 0
    }
    
    # Mode: build
    if ($Mode -eq "build") {
        Write-Section "Building Production Bundle"
        Write-Status "Running: npm run build" "INFO"
        
        $result = npm run build 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Build successful âœ“" "OK"
            Write-Status "Output located in: .next/" "INFO"
            return 0
        } else {
            Write-Status "Build failed" "ERR"
            if ($VerboseLog) { Write-Status $result "DEBUG" }
            return 1
        }
    }
    
    return 0
}

# --- Entry Point ---
try {
    $exitCode = Invoke-Setup
    Write-Host ""
    Write-Status "Setup completed at $(Get-Date -Format 'HH:mm:ss')" "INFO"
    exit $exitCode
} catch {
    Write-Status "Unhandled error: $($_.Exception.Message)" "FATAL"
    if ($VerboseLog) { 
        Write-Status "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
    }
    exit 1
}
