@echo off
REM Forge System - Windows Batch Wrapper
REM Calls PowerShell script with arguments

PowerShell.exe -ExecutionPolicy Bypass -File "%~dp0forge.ps1" %*
