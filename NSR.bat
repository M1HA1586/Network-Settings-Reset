@echo off
setlocal EnableExtensions
color 07
set "VER=1.0"
title NSR v%VER% - Network Settings Reset
set "NEEDS_RESTART=0"
set "BK=%USERPROFILE%\NSR_Backup"
set "HR=  ============================================================================"
set "SR=  ----------------------------------------------------------------------------"

rem ============================================================================
rem  STARTUP CHECKS
rem ============================================================================
where powershell >nul 2>&1
if errorlevel 1 (
    cls
    echo.
    echo   [!] PowerShell was not found on this PC.
    echo       NSR needs PowerShell to work. Install it and run the script again.
    echo.
    pause
    exit /b 1
)

fltmc >nul 2>&1
if errorlevel 1 (
    cls
    echo.
    echo   Administrator rights are required.
    echo   Asking Windows for permission, please click Yes...
    set "NSR_SELF=%~f0"
    powershell -NoProfile -Command "Start-Process -FilePath $env:NSR_SELF -Verb RunAs" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo   [!] Could not get administrator rights.
        echo       Right-click NSR.bat and choose Run as administrator.
        echo.
        pause
    )
    exit /b
)

for /f "delims=" %%V in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"') do set "PSVER=%%V"

rem ============================================================================
rem  MAIN MENU
rem ============================================================================
:mainMenu
call :header "MAIN MENU"
echo    Administrator: YES          PowerShell: %PSVER%
echo.
echo    [1]  Network Maintenance      Fix connection problems (recommended)
echo    [2]  Change DNS               Use a faster or safer DNS provider
echo    [3]  DNS Speed Test           See which DNS answers the fastest
echo    [4]  PC Information           CPU, RAM, GPU, disks, network
echo    [5]  About NSR                Version, links and credits
echo    [6]  Bufferbloat Optimizer    Advanced: less lag when the line is busy
echo.
echo    [7]  Exit
echo.
echo %SR%
choice /c 1234567 /n /m "   Press a number key [1-7]: "
if errorlevel 7 goto :exitMenu
if errorlevel 6 goto :bufferbloat
if errorlevel 5 goto :infoScript
if errorlevel 4 goto :infoPC
if errorlevel 3 goto :pingMenu
if errorlevel 2 goto :dnsMenu
goto :networkMaintenance

rem ============================================================================
rem  [1] NETWORK MAINTENANCE
rem ============================================================================
:networkMaintenance
call :header "NETWORK MAINTENANCE"
echo    [1]  Quick Fix     Flush the DNS cache and renew the IP address
echo                       Safe. The Internet drops for a few seconds.
echo.
echo    [2]  Full Reset    Quick Fix + reset Winsock and the TCP/IP stack
echo                       For serious problems. Needs a restart.
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 120 /n /m "   Press a key [1, 2 or 0]: "
if errorlevel 3 goto :mainMenu
if errorlevel 2 (set "MAINT=FULL") else (set "MAINT=QUICK")
echo.
echo   Your connection will drop for a few seconds.
echo   Save your work and close downloads and remote sessions first.
echo.
choice /c YN /n /m "   Continue? [Y/N]: "
if errorlevel 2 goto :networkMaintenance

call :header "NETWORK MAINTENANCE - RUNNING"
call :task "Flushing DNS cache"
ipconfig /flushdns >nul 2>&1
call :status
call :task "Renewing IP address"
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
call :done
if "%MAINT%"=="FULL" call :fullReset
call :connectionTest
echo.
if "%MAINT%"=="FULL" (
    echo   IMPORTANT: restart your PC to finish the reset.
) else (
    echo   Still no Internet? Try the Full Reset, or unplug your router for 30 seconds.
)
call :pauseBack
goto :mainMenu

:fullReset
call :task "Resetting Winsock"
netsh winsock reset >nul 2>&1
call :status
call :task "Resetting TCP/IP stack"
netsh int ip reset "%TEMP%\nsr_ipreset.log" >nul 2>&1
call :done
set "NEEDS_RESTART=1"
exit /b 0

rem ============================================================================
rem  [2] CHANGE DNS
rem ============================================================================
:dnsMenu
call :header "CHANGE DNS"
echo    Active network adapters and their current IPv4 DNS:
echo.
call :showDNS
echo.
echo %SR%
echo.
echo    [1]  Recommended providers
echo    [2]  Enter my own DNS
echo    [3]  Reset to automatic       Use the router / ISP DNS again
echo.
echo    [0]  Back
echo.
choice /c 1230 /n /m "   Press a key [1-3, 0 = back]: "
if errorlevel 4 goto :mainMenu
if errorlevel 3 goto :dnsReset
if errorlevel 2 goto :dnsCustom

:dnsRecommended
call :header "RECOMMENDED DNS PROVIDERS"
echo    [1]  Cloudflare       1.1.1.1           Fast, privacy focused
echo    [2]  Cisco OpenDNS    208.67.222.222    Stable, has filtering options
echo    [3]  GCore            95.85.95.85       Alternative provider
echo    [4]  Quad9            9.9.9.9           Blocks known malicious sites
echo    [5]  Google           8.8.8.8           Very popular and reliable
echo.
echo    [0]  Back
echo.
echo    Order is based on DNSPerf data. Real speed depends on your location.
echo    Use [3] DNS Speed Test in the main menu to see what is fastest for you.
echo.
echo %SR%
choice /c 123450 /n /m "   Press a key [1-5, 0 = back]: "
if errorlevel 6 goto :dnsMenu
if errorlevel 5 goto :prov5
if errorlevel 4 goto :prov4
if errorlevel 3 goto :prov3
if errorlevel 2 goto :prov2
goto :prov1

:prov1
set "DNS_NAME=Cloudflare"
set "DNS4_1=1.1.1.1"
set "DNS4_2=1.0.0.1"
set "DNS6_1=2606:4700:4700::1111"
set "DNS6_2=2606:4700:4700::1001"
goto :dnsApply

:prov2
set "DNS_NAME=Cisco OpenDNS"
set "DNS4_1=208.67.222.222"
set "DNS4_2=208.67.220.220"
set "DNS6_1=2620:119:35::35"
set "DNS6_2=2620:119:53::53"
goto :dnsApply

:prov3
set "DNS_NAME=GCore"
set "DNS4_1=95.85.95.85"
set "DNS4_2=2.56.220.2"
set "DNS6_1=2a03:90c0:999d::1"
set "DNS6_2=2a03:90c0:9992::1"
goto :dnsApply

:prov4
set "DNS_NAME=Quad9"
set "DNS4_1=9.9.9.9"
set "DNS4_2=149.112.112.112"
set "DNS6_1=2620:fe::fe"
set "DNS6_2=2620:fe::9"
goto :dnsApply

:prov5
set "DNS_NAME=Google"
set "DNS4_1=8.8.8.8"
set "DNS4_2=8.8.4.4"
set "DNS6_1=2001:4860:4860::8888"
set "DNS6_2=2001:4860:4860::8844"
goto :dnsApply

:dnsCustom
call :header "CUSTOM DNS"
echo    Type your DNS addresses. Only the first IPv4 address is required.
echo    Press Enter to skip the others.
echo.
set "DNS_NAME=Custom"
set "DNS4_1="
set "DNS4_2="
set "DNS6_1="
set "DNS6_2="
call :askIP DNS4_1 "   Primary IPv4 DNS   (required) : " 4 Y
call :askIP DNS4_2 "   Secondary IPv4 DNS (optional) : " 4 N
call :askIP DNS6_1 "   Primary IPv6 DNS   (optional) : " 6 N
if defined DNS6_1 call :askIP DNS6_2 "   Secondary IPv6 DNS (optional) : " 6 N
goto :dnsApply

:dnsApply
call :header "APPLY DNS"
echo    Provider : %DNS_NAME%
echo    IPv4     : %DNS4_1%   %DNS4_2%
if defined DNS6_1 echo    IPv6     : %DNS6_1%   %DNS6_2%
echo.
echo    It will be set on these active adapters:
echo.
call :showDNS
echo.
choice /c YN /n /m "   Apply now? [Y/N]: "
if errorlevel 2 goto :dnsMenu
set "NSR_V4=%DNS4_1%"
if defined DNS4_2 set "NSR_V4=%NSR_V4%,%DNS4_2%"
set "NSR_V6="
if defined DNS6_1 set "NSR_V6=%DNS6_1%"
if defined DNS6_2 set "NSR_V6=%NSR_V6%,%DNS6_2%"
echo.
call :psSetDNS
ipconfig /flushdns >nul 2>&1
call :connectionTest
echo.
echo   If something stops working, choose [3] in the DNS menu
echo   to go back to automatic DNS.
call :pauseBack
goto :dnsMenu

:dnsReset
call :header "RESET DNS TO AUTOMATIC"
echo    DNS servers will come from your router / ISP again.
echo.
choice /c YN /n /m "   Reset now? [Y/N]: "
if errorlevel 2 goto :dnsMenu
echo.
powershell -NoProfile -Command "$n=0; Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $a=$_; try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction Stop; Write-Host ('   [ OK ]  ' + $a.Name); $n++ } catch { Write-Host ('   [FAIL]  ' + $a.Name) } }; if($n -eq 0){ Write-Host '   No active adapter was changed.'; exit 1 }"
ipconfig /flushdns >nul 2>&1
call :connectionTest
call :pauseBack
goto :dnsMenu

rem ============================================================================
rem  [3] DNS SPEED TEST
rem ============================================================================
:pingMenu
call :header "DNS SPEED TEST"
echo    Sends 10 small test packets and measures the response time.
echo    Lower ms = faster. Lost packets = unstable connection.
echo.
echo    [1]  Test all recommended providers     takes about 20 seconds
echo    [2]  Test my own IP address or domain
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 120 /n /m "   Press a key [1, 2 or 0]: "
if errorlevel 3 goto :mainMenu
if errorlevel 2 goto :pingCustom
set "NSR_HOSTS=Cloudflare=1.1.1.1,Cisco OpenDNS=208.67.222.222,GCore=95.85.95.85,Quad9=9.9.9.9,Google=8.8.8.8"
call :header "DNS SPEED TEST - RUNNING"
call :psPing
call :pauseBack
goto :pingMenu

:pingCustom
call :header "DNS SPEED TEST - CUSTOM"
set "NSR_HOSTS="
set /p "NSR_HOSTS=   IP address or domain (Enter = cancel): "
if not defined NSR_HOSTS goto :pingMenu
echo.
call :psPing
call :pauseBack
goto :pingMenu

rem ============================================================================
rem  [4] PC INFORMATION
rem ============================================================================
:infoPC
call :header "PC INFORMATION"
call :psInfo
echo.
echo %SR%
choice /c YN /n /m "   Open the full Windows report in Notepad? [Y/N]: "
if errorlevel 2 goto :infoPCend
echo.
echo   Collecting data, please wait...
systeminfo > "%TEMP%\NSR_systeminfo.txt" 2>&1
start "" notepad "%TEMP%\NSR_systeminfo.txt"
:infoPCend
call :pauseBack
goto :mainMenu

rem ============================================================================
rem  [5] ABOUT
rem ============================================================================
:infoScript
call :header "ABOUT NSR"
echo    Name      : NSR - Network Settings Reset
echo    Version   : %VER%
echo    Author    : M1HA1586
echo.
echo    [1]  Open NSR on GitHub
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 10 /n /m "   Press a key [1 or 0]: "
if errorlevel 2 goto :mainMenu
start "" "https://github.com/M1HA1586/Network-Settings-Reset"
goto :infoScript

rem ============================================================================
rem  [6] BUFFERBLOAT OPTIMIZER
rem ============================================================================
:bufferbloat
call :header "BUFFERBLOAT OPTIMIZER - ADVANCED"
echo    What is bufferbloat?
echo    Lag spikes in games and calls when the line is busy
echo    (someone downloads, streams or uploads).
echo.
echo    What this does:
echo     - Changes some Windows network registry values and TCP settings
echo     - Turns off some network card offloads (LSO, checksum, RSS, RSC)
echo.
echo    Warning:
echo     - It can LOWER your download / upload speed and raise CPU usage
echo     - A restart is needed afterwards
echo     - The old values are saved first in: %BK%
echo.
echo    Tip: the best fix is Smart Queue / SQM on your router, if it has it.
echo.
echo    [1]  Apply optimizations
echo    [2]  Restore Windows defaults
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 120 /n /m "   Press a key [1, 2 or 0]: "
if errorlevel 3 goto :mainMenu
if errorlevel 2 goto :bbRestore

:bbApply
echo.
choice /c YN /n /m "   Apply the optimizations now? [Y/N]: "
if errorlevel 2 goto :bufferbloat
call :header "BUFFERBLOAT - APPLYING"
echo    Saving a backup of the current values...
if not exist "%BK%" mkdir "%BK%" >nul 2>&1
if not exist "%BK%\Tcpip_Parameters.reg" reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "%BK%\Tcpip_Parameters.reg" /y >nul 2>&1
if not exist "%BK%\Tcpip_ServiceProvider.reg" reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "%BK%\Tcpip_ServiceProvider.reg" /y >nul 2>&1
if not exist "%BK%\SystemProfile.reg" reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "%BK%\SystemProfile.reg" /y >nul 2>&1
if not exist "%BK%\tcp_global_before.txt" netsh int tcp show global > "%BK%\tcp_global_before.txt" 2>&1
echo.
echo    Registry:
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "LocalPriority" 4 "Local lookup priority"
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "HostsPriority" 5 "Hosts lookup priority"
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "DnsPriority" 6 "DNS lookup priority"
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "NetbtPriority" 7 "NetBT lookup priority"
call :regSet "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff "Network throttling: off"
call :regSet "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0 "System responsiveness: 0"
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpTimedWaitDelay" 30 "TCP timed wait delay: 30 s"
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DefaultTTL" 64 "Default TTL: 64"
echo.
echo    TCP settings:
call :psRun "TCP auto-tuning: disabled" "Set-NetTCPSetting -SettingName Internet -AutoTuningLevelLocal Disabled"
call :psRun "Scaling heuristics: disabled" "Set-NetTCPSetting -SettingName Internet -ScalingHeuristics Disabled"
call :psRun "ECN: enabled" "Set-NetTCPSetting -SettingName Internet -EcnCapability Enabled"
call :psRun "TCP timestamps: enabled" "Set-NetTCPSetting -SettingName Internet -Timestamps Enabled"
call :psRun "SYN retransmissions: 2" "Set-NetTCPSetting -SettingName Internet -MaxSynRetransmissions 2"
call :psRun "Non-SACK RTT resiliency: disabled" "Set-NetTCPSetting -SettingName Internet -NonSackRttResiliency Disabled"
call :psRun "Initial RTO: 2000 ms" "Set-NetTCPSetting -SettingName Internet -InitialRtoMs 2000"
call :psRun "Minimum RTO: 300 ms" "Set-NetTCPSetting -SettingName Internet -MinRtoMs 300"
call :task "Congestion provider: CTCP"
netsh int tcp set supplemental template=internet congestionprovider=ctcp >nul 2>&1
call :skip
echo.
echo    Network card offloads:
call :psRun "Receive Segment Coalescing: off" "Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled"
call :psRun "Receive Side Scaling: off" "Set-NetOffloadGlobalSetting -ReceiveSideScaling Disabled"
call :psRun "Large Send Offload: off" "Disable-NetAdapterLso -Name * -ErrorAction SilentlyContinue"
call :psRun "Checksum offload: off" "Disable-NetAdapterChecksumOffload -Name * -ErrorAction SilentlyContinue"
set "NEEDS_RESTART=1"
echo.
echo %SR%
echo    Done. Restart your PC so everything takes effect.
echo    [SKIP] = your Windows version does not allow that setting. This is normal.
echo    Backup of the old values: %BK%
call :pauseBack
goto :mainMenu

:bbRestore
echo.
choice /c YN /n /m "   Restore Windows default values now? [Y/N]: "
if errorlevel 2 goto :bufferbloat
call :header "BUFFERBLOAT - RESTORING DEFAULTS"
echo    Registry:
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "LocalPriority" 499 "Local lookup priority"
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "HostsPriority" 500 "Hosts lookup priority"
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "DnsPriority" 2000 "DNS lookup priority"
call :regSet "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "NetbtPriority" 2001 "NetBT lookup priority"
call :regSet "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10 "Network throttling: default"
call :regSet "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 20 "System responsiveness: default"
call :regDel "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpTimedWaitDelay" "TCP timed wait delay: default"
call :regDel "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DefaultTTL" "Default TTL: default"
call :regDel "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "MaxUserPort" "Max user port: default"
echo.
echo    TCP settings:
call :psRun "TCP auto-tuning: normal" "Set-NetTCPSetting -SettingName Internet -AutoTuningLevelLocal Normal"
call :psRun "Scaling heuristics: disabled" "Set-NetTCPSetting -SettingName Internet -ScalingHeuristics Disabled"
call :psRun "ECN: disabled" "Set-NetTCPSetting -SettingName Internet -EcnCapability Disabled"
call :psRun "TCP timestamps: disabled" "Set-NetTCPSetting -SettingName Internet -Timestamps Disabled"
call :psRun "SYN retransmissions: 2" "Set-NetTCPSetting -SettingName Internet -MaxSynRetransmissions 2"
call :psRun "Non-SACK RTT resiliency: disabled" "Set-NetTCPSetting -SettingName Internet -NonSackRttResiliency Disabled"
call :psRun "Initial RTO: 1000 ms" "Set-NetTCPSetting -SettingName Internet -InitialRtoMs 1000"
call :psRun "Minimum RTO: 300 ms" "Set-NetTCPSetting -SettingName Internet -MinRtoMs 300"
call :task "Congestion provider: CUBIC"
netsh int tcp set supplemental template=internet congestionprovider=cubic >nul 2>&1
call :skip
echo.
echo    Network card offloads:
call :psRun "Receive Segment Coalescing: on" "Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Enabled"
call :psRun "Receive Side Scaling: on" "Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled"
call :psRun "Large Send Offload: on" "Enable-NetAdapterLso -Name * -ErrorAction SilentlyContinue"
call :psRun "Checksum offload: on" "Enable-NetAdapterChecksumOffload -Name * -ErrorAction SilentlyContinue"
set "NEEDS_RESTART=1"
echo.
echo %SR%
echo    Done. Restart your PC so everything takes effect.
echo    These are the usual Windows 10 and 11 defaults.
echo    [SKIP] = your Windows version does not allow that setting. This is normal.
call :pauseBack
goto :mainMenu

rem ============================================================================
rem  EXIT
rem ============================================================================
:exitMenu
if not "%NEEDS_RESTART%"=="1" goto :bye
call :header "EXIT"
echo    Some changes only take effect after a restart.
echo.
choice /c YN /n /m "   Restart the PC now? [Y/N]: "
if errorlevel 2 goto :bye
echo.
echo   Restarting in 10 seconds. Save your work!
echo   To cancel, open CMD and type: shutdown /a
shutdown /r /t 10
exit /b 0

:bye
cls
echo.
echo   Thanks for using NSR v%VER%.
timeout /t 2 /nobreak >nul
exit /b 0

rem ============================================================================
rem  HELPERS (subroutines)
rem ============================================================================

:header
cls
echo.
echo %HR%
echo    N S R   -   Network Settings Reset                                 v%VER%
echo %HR%
echo.
echo    %~1
echo %SR%
echo.
exit /b 0

:pauseBack
echo.
echo %SR%
echo    Press any key to go back to the menu...
pause >nul
exit /b 0

rem  Prints a step name followed by dots (no new line). Result comes next.
:task
set "NSR_T=%~1 ..............................................."
call set "NSR_T=%%NSR_T:~0,44%%"
<nul set /p "=   %NSR_T% "
exit /b 0

:status
if errorlevel 1 (echo [FAIL]) else (echo [ OK ])
exit /b 0

:skip
if errorlevel 1 (echo [SKIP]) else (echo [ OK ])
exit /b 0

:done
echo [ DONE ]
exit /b 0

rem  %1 = registry key, %2 = value name, %3 = number, %4 = label
:regSet
call :task "%~4"
reg add "%~1" /v "%~2" /t REG_DWORD /d %~3 /f >nul 2>&1
call :status
exit /b 0

rem  %1 = registry key, %2 = value name, %3 = label
:regDel
call :task "%~3"
reg delete "%~1" /v "%~2" /f >nul 2>&1
echo [ OK ]
exit /b 0

rem  %1 = label, %2 = PowerShell command
:psRun
call :task "%~1"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; try { %~2 } catch { exit 1 }" >nul 2>&1
call :skip
exit /b 0

rem  Asks for an IP address and checks it.
rem  %1 = variable name, %2 = prompt, %3 = 4 or 6, %4 = Y if required
:askIP
:askIPagain
set "NSR_IP="
set /p "NSR_IP=%~2"
if not defined NSR_IP (
    if /i "%~4"=="Y" (
        echo   [!] This one is required.
        goto :askIPagain
    )
    set "%~1="
    exit /b 0
)
call :checkIP%~3
if errorlevel 1 (
    echo   [!] That is not a valid IPv%~3 address. Try again.
    goto :askIPagain
)
set "%~1=%NSR_IP%"
exit /b 0

:checkIP4
powershell -NoProfile -Command "$a=$null; if(($env:NSR_IP -match '^\d{1,3}(\.\d{1,3}){3}$') -and [System.Net.IPAddress]::TryParse($env:NSR_IP,[ref]$a)){exit 0}else{exit 1}"
exit /b %errorlevel%

:checkIP6
powershell -NoProfile -Command "$a=$null; if(($env:NSR_IP -match '^[0-9a-fA-F:.]+$') -and [System.Net.IPAddress]::TryParse($env:NSR_IP,[ref]$a) -and ($a.AddressFamily -eq 'InterNetworkV6')){exit 0}else{exit 1}"
exit /b %errorlevel%

rem  Shows active adapters with their IPv4 DNS servers
:showDNS
powershell -NoProfile -Command "$a=@(Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'}); if($a.Count -eq 0){ Write-Host '   No active network adapter found.' }; foreach($n in $a){ $d=(Get-DnsClientServerAddress -InterfaceIndex $n.ifIndex -AddressFamily IPv4).ServerAddresses -join ', '; if(-not $d){ $d='none' }; Write-Host ('   ' + $n.Name + '  :  ' + $d) }"
exit /b 0

rem  Sets DNS (values come from NSR_V4 and NSR_V6) on every active physical adapter
:psSetDNS
powershell -NoProfile -Command "$v4=$env:NSR_V4; $v6=$env:NSR_V6; $n=0; Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $a=$_; try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ($v4 -split ',') -ErrorAction Stop; Write-Host ('   [ OK ]  ' + $a.Name); $n++; if($v6){ try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ($v6 -split ',') -ErrorAction Stop } catch { Write-Host '           IPv6 DNS skipped on this adapter' } } } catch { Write-Host ('   [FAIL]  ' + $a.Name + '  ' + $_.Exception.Message) } }; if($n -eq 0){ Write-Host '   No active adapter was changed.'; exit 1 }"
exit /b 0

rem  Checks the Internet connection and name resolution
:connectionTest
echo.
echo   Checking the connection, please wait...
timeout /t 4 /nobreak >nul
echo.
call :task "Internet connection"
ping -n 2 -w 1500 1.1.1.1 | find "TTL=" >nul
call :status
call :task "Name resolution (DNS)"
powershell -NoProfile -Command "try { Resolve-DnsName example.com -DnsOnly -ErrorAction Stop | Out-Null } catch { exit 1 }" >nul 2>&1
call :status
exit /b 0

rem  Pings the hosts in NSR_HOSTS (name=address,name=address) 10 times each
:psPing
powershell -NoProfile -Command "$p=New-Object System.Net.NetworkInformation.Ping; $res=@(); foreach($e in ($env:NSR_HOSTS -split ',')){ $x=$e -split '=',2; if($x.Count -eq 2){$nm=$x[0]; $h=$x[1]}else{$nm=$e; $h=$e}; Write-Host ('   Testing ' + $nm + ' ...'); $t=@(); for($i=0;$i -lt 10;$i++){ try{ $r=$p.Send($h,1000); if($r.Status -eq 'Success'){ $t+=[int]$r.RoundtripTime } }catch{}; Start-Sleep -Milliseconds 100 }; if($t.Count -gt 0){ $m=$t | Measure-Object -Average -Minimum -Maximum; $res+=[pscustomobject]@{N=$nm;A=$m.Average;Mn=$m.Minimum;Mx=$m.Maximum;L=(10-$t.Count)} }else{ Write-Host ('   ' + $nm + ': no response') } }; Write-Host ''; foreach($q in ($res | Sort-Object A)){ Write-Host ('   {0,-16} avg {1,6:N1} ms   min {2,4}   max {3,4}   lost {4}/10' -f $q.N,$q.A,$q.Mn,$q.Mx,$q.L) }; if($res.Count -gt 0){ Write-Host ''; Write-Host ('   Fastest: ' + ($res | Sort-Object A | Select-Object -First 1).N) }"
exit /b 0

rem  Short hardware summary
:psInfo
powershell -NoProfile -Command "$o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor | Select-Object -First 1; $b=Get-CimInstance Win32_BaseBoard; $up=(Get-Date) - $o.LastBootUpTime; $f='   {0,-11}: {1}'; Write-Host ($f -f 'Windows',($o.Caption + ' (build ' + $o.BuildNumber + ')')); Write-Host ($f -f 'CPU',($c.Name.Trim() + ' - ' + $c.NumberOfCores + ' cores, ' + $c.NumberOfLogicalProcessors + ' threads')); Write-Host ($f -f 'RAM',([math]::Round($o.TotalVisibleMemorySize/1MB,1).ToString() + ' GB total, ' + [math]::Round($o.FreePhysicalMemory/1MB,1) + ' GB free')); foreach($g in Get-CimInstance Win32_VideoController){ Write-Host ($f -f 'GPU',$g.Name) }; Write-Host ($f -f 'Mainboard',($b.Manufacturer + ' ' + $b.Product)); foreach($d in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3'){ Write-Host ($f -f ('Disk ' + $d.DeviceID),([math]::Round($d.FreeSpace/1GB,0).ToString() + ' GB free of ' + [math]::Round($d.Size/1GB,0) + ' GB')) }; Write-Host ($f -f 'Uptime',('{0}d {1}h {2}m' -f $up.Days,$up.Hours,$up.Minutes))"
powershell -NoProfile -Command "$f='   {0,-11}: {1}'; Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { Write-Host ($f -f 'IP address',($_.IPAddress + '  (' + $_.InterfaceAlias + ')')) }"
exit /b 0