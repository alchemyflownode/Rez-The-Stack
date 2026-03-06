@echo off
cd /d "%~dp0"
echo ?? Starting REZ HIVE...
start cmd /k "npm run dev"
timeout /t 3 >nul
start http://localhost:3000
echo ? Server starting at http://localhost:3000
