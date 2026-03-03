@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0agent-working.ps1" -Model "phi3:latest" -Goal "Create a file called test.txt with the text 'Primordial lives'"
