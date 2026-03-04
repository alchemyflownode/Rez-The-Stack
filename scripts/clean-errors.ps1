# clean-errors.ps1
Write-Host "🧹 Cleaning up problematic files..." -ForegroundColor Cyan

# 1. Delete the PowerShell-script-as-TS file
$badFiles = @(
    "src/components/intimacyFactory.tsx",
    "src/mcp/server.ts"
)
foreach ($file in $badFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "  ✅ Deleted $file" -ForegroundColor Green
    }
}

# 2. Replace event-bus.ts with clean version
$eventBusPath = "src/lib/kernel/event-bus.ts"
if (Test-Path $eventBusPath) {
    $cleanCode = @'
// src/lib/kernel/event-bus.ts
type EventCallback = (...args: any[]) => void;

export class EventBus {
  private events: Map<string, EventCallback[]> = new Map();

  on(event: string, callback: EventCallback) {
    if (!this.events.has(event)) {
      this.events.set(event, []);
    }
    this.events.get(event)!.push(callback);
  }

  off(event: string, callback: EventCallback) {
    if (!this.events.has(event)) return;
    const callbacks = this.events.get(event)!.filter(cb => cb !== callback);
    if (callbacks.length === 0) {
      this.events.delete(event);
    } else {
      this.events.set(event, callbacks);
    }
  }

  emit(event: string, ...args: any[]) {
    if (!this.events.has(event)) return;
    this.events.get(event)!.forEach(cb => cb(...args));
  }

  clear() {
    this.events.clear();
  }
}

export const globalEventBus = new EventBus();
'@
    $cleanCode | Out-File $eventBusPath -Encoding UTF8
    Write-Host "  ✅ Replaced $eventBusPath with clean version" -ForegroundColor Green
}

# 3. Update tsconfig.json to exclude all backup folders
$tsconfigPath = "tsconfig.json"
if (Test-Path $tsconfigPath) {
    $ts = Get-Content $tsconfigPath -Raw | ConvertFrom-Json
    $ts.exclude = @("node_modules", ".next", "backup-*", "src-backup-*", "src_backup_*", "logs", "chroma_data")
    $ts | ConvertTo-Json -Depth 10 | Out-File $tsconfigPath -Encoding UTF8
    Write-Host "  ✅ Updated tsconfig.json to exclude backup folders" -ForegroundColor Green
}

# 4. Remove any remaining backup folders
Get-ChildItem -Directory -Path "." -Filter "backup-*" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem -Directory -Path "." -Filter "src-backup-*" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem -Directory -Path "." -Filter "src_backup_*" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  ✅ Deleted any leftover backup directories" -ForegroundColor Green

# 5. Clear Next.js cache and re-check
Remove-Item -Path ".next" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "`n🚀 Now run: npm run dev" -ForegroundColor Cyan