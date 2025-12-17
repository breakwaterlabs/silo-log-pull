@echo off
REM ==============================================================================
REM silo-log-pull Setup Script for Windows
REM ==============================================================================
REM This batch file launches the PowerShell setup script
REM
REM Usage: setup.bat

powershell -ExecutionPolicy Bypass -File "%~dpn0.ps1"
