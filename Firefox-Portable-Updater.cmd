:: =========================================================================
:: Firefox Portable Updater
:: Author: SeriousHoax
:: GitHub: https://github.com/SeriousHoax
:: License: MIT
::
:: Dependencies:
:: - 7zr.exe (Required for extraction)
:: - aria2c.exe (Optional for faster downloading)
:: =========================================================================

@echo off
setlocal EnableDelayedExpansion
set "TEMP_PS1=%~dp0.temp-firefox-portable.ps1"
(
echo $ErrorActionPreference = "Stop"
echo $URL = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
echo.
echo function Find-7Zip {
echo     $path = Join-Path $PSScriptRoot "Dependencies\7zr.exe"
echo     if ^(Test-Path $path^) { return $path }
echo     return $null
echo }
echo.
echo function Get-LocalVersion {
echo     param^($ExePath^)
echo     $ini = Join-Path $ExePath.Directory "application.ini"
echo     Write-Host "Debug Local: Checking '$ini'"
echo     if ^(Test-Path $ini^) {
echo         $content = Get-Content $ini -Raw -ErrorAction SilentlyContinue
echo         if ^($content -match 'Version=^(.+^)'  ^) {
echo             $ver = $matches[1].Trim^(^)
echo             Write-Host "Debug Local: Found version '$ver'"
echo             return $ver
echo         } else {
echo             Write-Host "Debug Local: No Version= line found"
echo         }
echo     } else {
echo         Write-Host "Debug Local: File not found"
echo     }
echo     return $null
echo }
echo.
echo function Get-RemoteVersion {
echo     param^($Url^)
echo     try {
echo         $request = [System.Net.HttpWebRequest]::Create^($Url^)
echo         $request.UserAgent = "Mozilla/5.0"
echo         $request.Method = "HEAD"
echo         $request.Timeout = 10000
echo         $request.AllowAutoRedirect = $true
echo         $response = $request.GetResponse^(^)
echo         $finalUrl = $response.ResponseUri.AbsoluteUri
echo         $response.Close^(^)
echo         Write-Host "Debug Remote: URL='$finalUrl'"
echo         if ^($finalUrl -match '^(\d+\.\d+^(?:\.\d+^)?^)'^) {
echo             $ver = $matches[1]
echo             Write-Host "Debug Remote: Found version '$ver'"
echo             return $ver
echo         } else {
echo             Write-Host "Debug Remote: Regex did not match"
echo         }
echo     } catch {
echo         Write-Host "Debug Remote: Error - $_"
echo     }
echo     return $null
echo }
echo.
echo function Compare-Versions {
echo     param^($Ver1, $Ver2^)
echo     if ^(-not $Ver1 -or -not $Ver2^) { return $false }
echo     $v1Parts = $Ver1 -split '\.' ^| ForEach-Object { [int]$_ }
echo     $v2Parts = $Ver2 -split '\.' ^| ForEach-Object { [int]$_ }
echo     $maxLen = [Math]::Max^($v1Parts.Length, $v2Parts.Length^)
echo     for ^($i = 0; $i -lt $maxLen; $i++^) {
echo         $p1 = if ^($i -lt $v1Parts.Length^) { $v1Parts[$i] } else { 0 }
echo         $p2 = if ^($i -lt $v2Parts.Length^) { $v2Parts[$i] } else { 0 }
echo         if ^($p1 -ne $p2^) { return $false }
echo     }
echo     return $true
echo }
echo.
echo function Find-Aria2 {
echo     $path = Join-Path $PSScriptRoot "Dependencies\aria2c.exe"
echo     if ^(Test-Path $path^) { return $path }
echo     return $null
echo }
echo.
echo function Invoke-Aria2Download {
echo     param^($Url, $Dest, $Aria2Path^)
echo     try {
echo         $arguments = @^(
echo             $Url,
echo             "-o", ^(Split-Path $Dest -Leaf^),
echo             "-d", ^(Split-Path $Dest -Parent^),
echo             "-x", "8",
echo             "-s", "8",
echo             "-k", "1M",
echo             "--file-allocation=none",
echo             "--allow-overwrite=true",
echo             "--auto-file-renaming=false",
echo             "--summary-interval=0",
echo             "--user-agent=Mozilla/5.0"
echo         ^)
echo         Write-Host "Downloading with aria2 ^(8 connections^)...`n"
echo         $process = Start-Process -FilePath $Aria2Path -ArgumentList $arguments -NoNewWindow -Wait -PassThru
echo         return $process.ExitCode -eq 0
echo     } catch {
echo         Write-Host "aria2 download failed: $_"
echo         return $false
echo     }
echo }
echo.
echo function Get-FileDownload {
echo     param^($Url, $Dest, $Aria2Path = $null^)
echo     if ^($Aria2Path -and ^(Invoke-Aria2Download $Url $Dest $Aria2Path^)^) {
echo         return
echo     }
echo     if ^($Aria2Path^) { Write-Host "Falling back to default download method..." }
echo     $request = [System.Net.HttpWebRequest]::Create^($Url^)
echo     $request.UserAgent = "Mozilla/5.0"
echo     $request.Timeout = 60000
echo     $response = $request.GetResponse^(^)
echo     $total = $response.ContentLength
echo     $stream = $response.GetResponseStream^(^)
echo     $fileStream = [System.IO.File]::Create^($Dest^)
echo     $buffer = New-Object byte[] 8192
echo     $downloaded = 0
echo     while ^($true^) {
echo         $read = $stream.Read^($buffer, 0, $buffer.Length^)
echo         if ^($read -eq 0^) { break }
echo         $fileStream.Write^($buffer, 0, $read^)
echo         $downloaded += $read
echo         if ^($total -gt 0^) {
echo             $percent = [int]^(^($downloaded / $total^) * 100^)
echo             Write-Host "`rDownloading: $percent%%" -NoNewline
echo         }
echo     }
echo     Write-Host ""
echo     $fileStream.Close^(^)
echo     $stream.Close^(^)
echo     $response.Close^(^)
echo }
echo.
echo function Disable-Updates {
echo     param^($BaseDir^)
echo     $coreDir = Join-Path $BaseDir "Firefox\core"
echo     $profileDir = Join-Path $BaseDir "Firefox\profile"
echo     $distDir = Join-Path $coreDir "distribution"
echo     New-Item -ItemType Directory -Force -Path $distDir ^| Out-Null
echo     $policies = @{
echo         policies = @{
echo             DisableAppUpdate = $true
echo             ManualAppUpdateOnly = $true
echo         }
echo     } ^| ConvertTo-Json -Depth 3
echo     Set-Content -Path ^(Join-Path $distDir "policies.json"^) -Value $policies
echo     Write-Host "Enterprise policies configured ^(updates disabled^)"
echo     $prefsContent = @'
echo user_pref^("browser.shell.checkDefaultBrowser", false^);
echo user_pref^("app.update.enabled", false^);
echo user_pref^("app.update.auto", false^);
echo user_pref^("app.update.checkInstallTime", false^);
echo user_pref^("app.update.service.enabled", false^);
echo user_pref^("app.update.staging.enabled", false^);
echo user_pref^("app.update.silent", false^);
echo '@
echo     $prefsJs = Join-Path $profileDir "prefs.js"
echo     if ^(Test-Path $prefsJs^) {
echo         $existing = Get-Content $prefsJs -Raw
echo         if ^($existing -notmatch "app.update.enabled"^) {
echo             Add-Content -Path $prefsJs -Value "`n$prefsContent"
echo         }
echo     } else {
echo         Set-Content -Path $prefsJs -Value $prefsContent
echo     }
echo     Write-Host "Profile preferences configured ^(updates disabled^)"
echo }
echo.
echo function New-Shortcut {
echo     param^($BaseDir^)
echo     $shortcutPath = Join-Path $BaseDir "Firefox Portable.lnk"
echo     $exePath = Join-Path $BaseDir "Firefox\core\firefox.exe"
echo     $profilePath = Join-Path $BaseDir "Firefox\profile"
echo     if ^(-not ^(Test-Path $exePath^)^) { return }
echo     $ws = New-Object -ComObject WScript.Shell
echo     $shortcut = $ws.CreateShortcut^($shortcutPath^)
echo     $shortcut.TargetPath = $exePath
echo     $shortcut.Arguments = "-profile `"$profilePath`" -no-remote"
echo     $shortcut.WorkingDirectory = Split-Path $exePath
echo     $shortcut.IconLocation = $exePath
echo     $shortcut.Save^(^)
echo     Write-Host "Shortcut created: $shortcutPath"
echo }
echo.
echo function Install-Firefox {
echo     param^($BaseDir, $SevenZip, $Aria2Path = $null^)
echo     $installDir = Join-Path $BaseDir "Firefox"
echo     $coreDir = Join-Path $installDir "core"
echo     $profileDir = Join-Path $installDir "profile"
echo     $exe = Join-Path $coreDir "firefox.exe"
echo     $currentVer = if ^(Test-Path $exe^) { Get-LocalVersion ^(Get-Item $exe^) } else { $null }
echo     $remoteVer = Get-RemoteVersion $URL
echo     Write-Host "Debug: Current='$currentVer' Remote='$remoteVer'"
echo     if ^($currentVer^) {
echo         Write-Host "Installed: $currentVer, Remote: $remoteVer"
echo         $match = Compare-Versions $currentVer $remoteVer
echo         Write-Host "Debug: Version match = $match"
echo         if ^($match^) {
echo             Write-Host "Firefox is up to date"
echo             Disable-Updates $BaseDir
echo             return $true
echo         }
echo         Write-Host "Updating Firefox..."
echo     } else {
echo         Write-Host "Installing Firefox..."
echo     }
echo     $tempDir = Join-Path $BaseDir "temp"
echo     New-Item -ItemType Directory -Force -Path $tempDir ^| Out-Null
echo     $installer = Join-Path $tempDir "installer.exe"
echo     try {
echo         Get-FileDownload $URL $installer $Aria2Path
echo         Write-Host "Extracting..."
echo         $extractDir = Join-Path $tempDir "extract"
echo         New-Item -ItemType Directory -Force -Path $extractDir ^| Out-Null
echo         ^& $SevenZip x $installer ^("-o" + $extractDir^) -y ^| Out-Null
echo         $firefoxCore = Get-ChildItem -Path $extractDir -Recurse -Filter "firefox.exe" ^| Select-Object -First 1
echo         if ^(-not $firefoxCore^) {
echo             Write-Host "Error: Firefox core not found"
echo             return $false
echo         }
echo         $firefoxCoreDir = $firefoxCore.Directory.FullName
echo         if ^(Test-Path $coreDir^) {
echo             $backup = Join-Path $installDir "core_backup"
echo             if ^(Test-Path $backup^) { Remove-Item $backup -Recurse -Force }
echo             Move-Item $coreDir $backup
echo         }
echo         New-Item -ItemType Directory -Force -Path $installDir ^| Out-Null
echo         Move-Item $firefoxCoreDir $coreDir
echo         New-Item -ItemType Directory -Force -Path $profileDir ^| Out-Null
echo         $newVer = Get-LocalVersion ^(Get-Item $exe^)
echo         Write-Host "Success! Firefox version: $newVer"
echo         Disable-Updates $BaseDir
echo         $backupPath = Join-Path $installDir "core_backup"
echo         if ^(Test-Path $backupPath^) {
echo             Remove-Item $backupPath -Recurse -Force
echo         }
echo         return $true
echo     } catch {
echo         Write-Host "Error: $_"
echo         if ^(^(Test-Path $coreDir^) -and ^(Test-Path ^(Join-Path $installDir "core_backup"^)^)^) {
echo             Remove-Item $coreDir -Recurse -Force -ErrorAction SilentlyContinue
echo             Move-Item ^(Join-Path $installDir "core_backup"^) $coreDir
echo         }
echo         return $false
echo     } finally {
echo         if ^(Test-Path $tempDir^) {
echo             Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
echo         }
echo     }
echo }
echo.
echo $psVersion = if ^($PSVersionTable.PSVersion.Major -ge 7^) { "PowerShell 7+" } else { "Windows PowerShell" }
echo Write-Host "Using: $psVersion`n"
echo $sevenZip = Find-7Zip
echo if ^(-not $sevenZip^) {
echo     Write-Host "Error: 7zr.exe not found in Dependencies folder." -ForegroundColor Red
echo     Read-Host "Press Enter to exit"
echo     exit 1
echo }
echo $aria2Path = Find-Aria2
echo if ^($aria2Path^) {
echo     Write-Host "Found aria2: $aria2Path"
echo } else {
echo     Write-Host "aria2 not found, using default download method"
echo }
echo $baseDir = "%~dp0".TrimEnd^('\'^)
echo Write-Host "Working directory: $baseDir`n"
echo $success = Install-Firefox $baseDir $sevenZip $aria2Path
echo New-Shortcut $baseDir
echo if ^($success^) {
echo     Write-Host "`nSuccess! Closing in 3 seconds..." -ForegroundColor Green
echo     Write-Host "Press Enter to close immediately" -ForegroundColor Gray
echo     for ^($i = 3; $i -gt 0; $i--^) {
echo         Write-Host "$i..." -NoNewline
echo         $timeout = [DateTime]::Now.AddSeconds^(1^)
echo         while ^([DateTime]::Now -lt $timeout^) {
echo             if ^([Console]::KeyAvailable^) {
echo                 $key = [Console]::ReadKey^($true^)
echo                 if ^($key.Key -eq 'Enter'^) {
echo                     Write-Host "`nClosing now..."
echo                     exit 0
echo                 }
echo             }
echo             Start-Sleep -Milliseconds 50
echo         }
echo     }
echo     Write-Host ""
echo } else {
echo     Write-Host "`nErrors occurred. Press Enter to exit." -ForegroundColor Red
echo     Read-Host
echo }
echo Remove-Item "%TEMP_PS1%" -Force -ErrorAction SilentlyContinue
) > "%TEMP_PS1%"
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    pwsh -ExecutionPolicy Bypass -NoProfile -File "%TEMP_PS1%"
) else (
    powershell -ExecutionPolicy Bypass -NoProfile -File "%TEMP_PS1%"
)
del "%TEMP_PS1%" >nul 2>&1
endlocal