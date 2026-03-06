# COMPLETE REINSTALL (Run this entire block)
cd D:\okiru-os\The\ Reztack\OS

# Kill everything
taskkill /F /IM node.exe 2>$null
taskkill /F /IM python.exe 2>$null

# Nuke node_modules
Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .next -ErrorAction SilentlyContinue

# Fresh install
npm init -y
npm install next@14.1.0 react@18.2.0 react-dom@18.2.0
npm install -D tailwindcss@3.4.17 postcss autoprefixer typescript @types/react @types/node

# Create a minimal pages directory
New-Item -ItemType Directory -Path "src/app" -Force
@'
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "REZ HIVE",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
'@ | Out-File "src/app/layout.tsx" -Encoding UTF8

@'
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold text-cyan-400">🏛️ REZ HIVE</h1>
      <p className="mt-4 text-gray-400">Sovereign AI Operating System</p>
    </main>
  );
}
'@ | Out-File "src/app/page.tsx" -Encoding UTF8

# Update package.json scripts
$pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
$pkg.scripts = @{
    dev = "next dev -p 3001"
    build = "next build"
    start = "next start -p 3001"
}
$pkg | ConvertTo-Json -Depth 10 | Out-File "package.json" -Encoding UTF8

# Start the app
Write-Host "`n✅ READY! Starting Next.js..." -ForegroundColor Green
npm run dev