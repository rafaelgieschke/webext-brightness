@echo off & pushd "%~dp0"

if "%1" == "" (
    reg ADD "HKCU\Software\Google\Chrome\NativeMessagingHosts\brightness_volume_changer" ^
    /f /ve /d "%~dp0nativemessaging.json" /t REG_SZ
    pause
) else (
    powershell -ExecutionPolicy Bypass -File ".\nativemessaging.ps1"
)
