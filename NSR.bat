@echo off
setlocal EnableExtensions
color 07
set "VER=1.2"
title NSR v%VER% - Network Settings Reset
set "NEEDS_RESTART=0"
set "BK=%USERPROFILE%\NSR_Backup"
set "HR=  ============================================================================"
set "SR=  ----------------------------------------------------------------------------"
set "PCOUNT=20"

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

set "PSVER="
set "WINBUILD="
for /f "delims=" %%V in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.ToString(); [Environment]::OSVersion.Version.Build"') do (
    if not defined PSVER (set "PSVER=%%V") else set "WINBUILD=%%V"
)
if not defined PSVER set "PSVER=?"
if not defined WINBUILD set "WINBUILD=0"

rem ============================================================================
rem  MAIN MENU
rem ============================================================================
:mainMenu
call :header "MAIN MENU"
echo    Administrator: YES     PowerShell: %PSVER%     Windows build: %WINBUILD%
echo.
echo    [1]  Network Maintenance      Fix connection problems (recommended)
echo    [2]  Change DNS               Faster, safer or family-friendly DNS
echo    [3]  DNS Speed Test           Find the fastest DNS for your line
echo    [4]  Network Diagnostics      Find out where the problem is
echo    [5]  PC Information           CPU, RAM, GPU, disks, network
echo    [6]  Bufferbloat Optimizer    Advanced: less lag when the line is busy
echo    [7]  About NSR                Version, what's new, links
echo.
echo    [8]  Exit
echo.
echo %SR%
choice /c 12345678 /n /m "   Press a number key [1-8]: "
if errorlevel 8 goto :exitMenu
if errorlevel 7 goto :infoScript
if errorlevel 6 goto :bufferbloat
if errorlevel 5 goto :infoPC
if errorlevel 4 goto :diag
if errorlevel 3 goto :pingMenu
if errorlevel 2 goto :dnsMenu
goto :networkMaintenance

rem ============================================================================
rem  [1] NETWORK MAINTENANCE
rem ============================================================================
:networkMaintenance
call :header "NETWORK MAINTENANCE"
echo    [1]  Quick Fix     Flush the DNS cache, renew the IP address, clear ARP
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
call :task "Clearing ARP cache"
netsh interface ip delete arpcache >nul 2>&1
call :status
call :task "Renewing IP address"
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
call :done
if "%MAINT%"=="FULL" call :fullReset
call :log "Network maintenance: %MAINT%"
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
echo    Active network adapters and their current DNS:
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
echo    Pick a type of DNS. IPv4, IPv6 and encrypted DNS [DoH] data of every
echo    provider comes from its official page.
echo.
echo    [1]  Fast and reliable     Big, stable networks
echo    [2]  Private               Nothing is blocked. Privacy focused
echo    [3]  Safe                  Blocks malware and phishing
echo    [4]  Ads and family        Blocks ads, trackers or adult sites
echo.
echo    [0]  Back
echo.
echo    Real speed depends on your location. Use [3] DNS Speed Test in the
echo    main menu to see what is fastest for you.
echo.
echo %SR%
choice /c 12340 /n /m "   Press a key [1-4, 0 = back]: "
if errorlevel 5 goto :dnsMenu
if errorlevel 4 goto :catAds
if errorlevel 3 goto :catSafe
if errorlevel 2 goto :catPrivate

:catFast
call :header "FAST AND RELIABLE"
echo    [1]  Cloudflare              1.1.1.1           Fast, privacy focused
echo    [2]  Google                  8.8.8.8           Very popular and reliable
echo    [3]  Cisco OpenDNS           208.67.222.222    Stable, has filtering options
echo    [4]  GCore                   95.85.95.85       Alternative provider
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 12340 /n /m "   Press a key [1-4, 0 = back]: "
set "K=%errorlevel%"
if %K%==5 goto :dnsRecommended
set /a PICK=%K%+0
goto :provPick

:catPrivate
call :header "PRIVATE - NOTHING IS BLOCKED"
echo    These do not filter anything. Pick one for privacy, not for protection.
echo.
echo    [1]  DNS.SB                  185.222.222.222   No filtering, DNSSEC
echo    [2]  Control D               76.76.2.0         Free, no filtering
echo    [3]  Mullvad                 194.242.2.2       Privacy focused, Sweden
echo    [4]  DNS4EU Unfiltered       86.54.11.100      European, no filtering
echo    [5]  UncensoredDNS           91.239.100.100    Danish, no filtering
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 123450 /n /m "   Press a key [1-5, 0 = back]: "
set "K=%errorlevel%"
if %K%==6 goto :dnsRecommended
set /a PICK=%K%+4
goto :provPick

:catSafe
call :header "SAFE - BLOCKS MALWARE AND PHISHING"
echo    They block dangerous sites on purpose. A blocked site is not a bug.
echo.
echo    [1]  Quad9                   9.9.9.9           Non-profit, no personal logs
echo    [2]  Cloudflare Security     1.1.1.2           Fast, blocks malware
echo    [3]  DNS4EU Protective       86.54.11.1        European, blocks threats
echo    [4]  CleanBrowsing Security  185.228.168.9     Blocks malware, phishing
echo    [5]  Mullvad Base            194.242.2.4       Blocks ads, trackers, malware
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 123450 /n /m "   Press a key [1-5, 0 = back]: "
set "K=%errorlevel%"
if %K%==6 goto :dnsRecommended
set /a PICK=%K%+9
goto :provPick

:catAds
call :header "ADS AND FAMILY"
echo    They block ads, trackers or adult sites on purpose.
echo.
echo    [1]  AdGuard DNS             94.140.14.14      Blocks ads, trackers, malware
echo    [2]  AdGuard Family          94.140.14.15      Also blocks adult sites
echo    [3]  Mullvad Adblock         194.242.2.3       Blocks ads and trackers
echo    [4]  DNS4EU Ads Block        86.54.11.13       European, blocks threats, ads
echo    [5]  Control D Family        76.76.2.4         Blocks adult sites, malware
echo    [6]  CleanBrowsing Family    185.228.168.168   Strict, blocks adult sites
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 1234560 /n /m "   Press a key [1-6, 0 = back]: "
set "K=%errorlevel%"
if %K%==7 goto :dnsRecommended
set /a PICK=%K%+14
goto :provPick

rem  Loads provider number PICK, then goes to the apply screen
:provPick
call :prov%PICK%
goto :dnsApply

rem  Provider data. One label per provider. They only set variables.

rem  FAST
:prov1
set "DNS_NAME=Cloudflare"
set "DNS4_1=1.1.1.1"
set "DNS4_2=1.0.0.1"
set "DNS6_1=2606:4700:4700::1111"
set "DNS6_2=2606:4700:4700::1001"
set "DOH_URL=https://cloudflare-dns.com/dns-query"
set "DNS_NOTE="
exit /b 0

rem  FAST
:prov2
set "DNS_NAME=Google"
set "DNS4_1=8.8.8.8"
set "DNS4_2=8.8.4.4"
set "DNS6_1=2001:4860:4860::8888"
set "DNS6_2=2001:4860:4860::8844"
set "DOH_URL=https://dns.google/dns-query"
set "DNS_NOTE="
exit /b 0

rem  FAST
:prov3
set "DNS_NAME=Cisco OpenDNS"
set "DNS4_1=208.67.222.222"
set "DNS4_2=208.67.220.220"
set "DNS6_1=2620:119:35::35"
set "DNS6_2=2620:119:53::53"
set "DOH_URL=https://doh.opendns.com/dns-query"
set "DNS_NOTE="
exit /b 0

rem  FAST
:prov4
set "DNS_NAME=GCore"
set "DNS4_1=95.85.95.85"
set "DNS4_2=2.56.220.2"
set "DNS6_1=2a03:90c0:999d::1"
set "DNS6_2=2a03:90c0:9992::1"
set "DOH_URL="
set "DNS_NOTE="
exit /b 0

rem  PRIVATE
:prov5
set "DNS_NAME=DNS.SB"
set "DNS4_1=185.222.222.222"
set "DNS4_2=45.11.45.11"
set "DNS6_1=2a09::"
set "DNS6_2=2a11::"
set "DOH_URL=https://doh.dns.sb/dns-query"
set "DNS_NOTE="
exit /b 0

rem  PRIVATE
:prov6
set "DNS_NAME=Control D"
set "DNS4_1=76.76.2.0"
set "DNS4_2=76.76.10.0"
set "DNS6_1=2606:1a40::"
set "DNS6_2=2606:1a40:1::"
set "DOH_URL=https://freedns.controld.com/p0"
set "DNS_NOTE="
exit /b 0

rem  PRIVATE
:prov7
set "DNS_NAME=Mullvad"
set "DNS4_1=194.242.2.2"
set "DNS4_2="
set "DNS6_1=2a07:e340::2"
set "DNS6_2="
set "DOH_URL=https://dns.mullvad.net/dns-query"
set "DNS_NOTE=Mullvad gives one address only, no backup server."
exit /b 0

rem  PRIVATE
:prov8
set "DNS_NAME=DNS4EU Unfiltered"
set "DNS4_1=86.54.11.100"
set "DNS4_2=86.54.11.200"
set "DNS6_1=2a13:1001::86:54:11:100"
set "DNS6_2=2a13:1001::86:54:11:200"
set "DOH_URL=https://unfiltered.joindns4.eu/dns-query"
set "DNS_NOTE=DNS4EU is meant for personal use."
exit /b 0

rem  PRIVATE
:prov9
set "DNS_NAME=UncensoredDNS"
set "DNS4_1=91.239.100.100"
set "DNS4_2=89.233.43.71"
set "DNS6_1=2001:67c:28a4::"
set "DNS6_2=2a01:3a0:53:53::"
set "DOH_URL=https://anycast.uncensoreddns.org/dns-query"
set "DNS_NOTE=Run by one person in Denmark."
exit /b 0

rem  SAFE
:prov10
set "DNS_NAME=Quad9"
set "DNS4_1=9.9.9.9"
set "DNS4_2=149.112.112.112"
set "DNS6_1=2620:fe::fe"
set "DNS6_2=2620:fe::9"
set "DOH_URL=https://dns.quad9.net/dns-query"
set "DNS_NOTE="
exit /b 0

rem  SAFE
:prov11
set "DNS_NAME=Cloudflare Security"
set "DNS4_1=1.1.1.2"
set "DNS4_2=1.0.0.2"
set "DNS6_1=2606:4700:4700::1112"
set "DNS6_2=2606:4700:4700::1002"
set "DOH_URL=https://security.cloudflare-dns.com/dns-query"
set "DNS_NOTE="
exit /b 0

rem  SAFE
:prov12
set "DNS_NAME=DNS4EU Protective"
set "DNS4_1=86.54.11.1"
set "DNS4_2=86.54.11.201"
set "DNS6_1=2a13:1001::86:54:11:1"
set "DNS6_2=2a13:1001::86:54:11:201"
set "DOH_URL=https://protective.joindns4.eu/dns-query"
set "DNS_NOTE=DNS4EU is meant for personal use."
exit /b 0

rem  SAFE
:prov13
set "DNS_NAME=CleanBrowsing Security"
set "DNS4_1=185.228.168.9"
set "DNS4_2=185.228.169.9"
set "DNS6_1=2a0d:2a00:1::2"
set "DNS6_2=2a0d:2a00:2::2"
set "DOH_URL=https://doh.cleanbrowsing.org/doh/security-filter/"
set "DNS_NOTE="
exit /b 0

rem  SAFE
:prov14
set "DNS_NAME=Mullvad Base"
set "DNS4_1=194.242.2.4"
set "DNS4_2="
set "DNS6_1=2a07:e340::4"
set "DNS6_2="
set "DOH_URL=https://base.dns.mullvad.net/dns-query"
set "DNS_NOTE=Mullvad gives one address only, no backup server."
exit /b 0

rem  ADS
:prov15
set "DNS_NAME=AdGuard DNS"
set "DNS4_1=94.140.14.14"
set "DNS4_2=94.140.15.15"
set "DNS6_1=2a10:50c0::ad1:ff"
set "DNS6_2=2a10:50c0::ad2:ff"
set "DOH_URL=https://dns.adguard-dns.com/dns-query"
set "DNS_NOTE="
exit /b 0

rem  ADS
:prov16
set "DNS_NAME=AdGuard Family"
set "DNS4_1=94.140.14.15"
set "DNS4_2=94.140.15.16"
set "DNS6_1=2a10:50c0::bad1:ff"
set "DNS6_2=2a10:50c0::bad2:ff"
set "DOH_URL=https://family.adguard-dns.com/dns-query"
set "DNS_NOTE="
exit /b 0

rem  ADS
:prov17
set "DNS_NAME=Mullvad Adblock"
set "DNS4_1=194.242.2.3"
set "DNS4_2="
set "DNS6_1=2a07:e340::3"
set "DNS6_2="
set "DOH_URL=https://adblock.dns.mullvad.net/dns-query"
set "DNS_NOTE=Mullvad gives one address only, no backup server."
exit /b 0

rem  ADS
:prov18
set "DNS_NAME=DNS4EU Ads Block"
set "DNS4_1=86.54.11.13"
set "DNS4_2=86.54.11.213"
set "DNS6_1=2a13:1001::86:54:11:13"
set "DNS6_2=2a13:1001::86:54:11:213"
set "DOH_URL=https://noads.joindns4.eu/dns-query"
set "DNS_NOTE=DNS4EU is meant for personal use."
exit /b 0

rem  ADS
:prov19
set "DNS_NAME=Control D Family"
set "DNS4_1=76.76.2.4"
set "DNS4_2=76.76.10.4"
set "DNS6_1=2606:1a40::4"
set "DNS6_2=2606:1a40:1::4"
set "DOH_URL=https://freedns.controld.com/family"
set "DNS_NOTE="
exit /b 0

rem  ADS
:prov20
set "DNS_NAME=CleanBrowsing Family"
set "DNS4_1=185.228.168.168"
set "DNS4_2=185.228.169.168"
set "DNS6_1=2a0d:2a00:1::"
set "DNS6_2=2a0d:2a00:2::"
set "DOH_URL=https://doh.cleanbrowsing.org/doh/family-filter/"
set "DNS_NOTE=Strict. Also blocks VPN sites and Reddit."
exit /b 0

:dnsCustom
call :header "CUSTOM DNS"
echo    Type your DNS addresses. Only the first IPv4 address is required.
echo    Press Enter to skip the others.
echo.
set "DNS_NAME=Custom"
set "DNS_NOTE="
set "DNS4_1="
set "DNS4_2="
set "DNS6_1="
set "DNS6_2="
set "DOH_URL="
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
if defined DNS_NOTE echo    Note     : %DNS_NOTE%
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
call :backupDNS
call :psSetDNS
ipconfig /flushdns >nul 2>&1
call :log "DNS set to %DNS_NAME%"
if defined DOH_URL if %WINBUILD% GEQ 22000 call :askDoH
if defined DOH_URL if %WINBUILD% LSS 22000 (
    echo.
    echo    Encrypted DNS [DoH] needs Windows 11. Normal DNS was set.
)
echo.
echo    New DNS settings:
echo.
call :showDNS
call :connectionTest
echo.
echo   If something stops working, choose [3] in the DNS menu
echo   to go back to automatic DNS.
call :pauseBack
goto :dnsMenu

rem  Offers encrypted DNS (DNS over HTTPS). Windows 11 only.
:askDoH
echo.
echo    This provider supports encrypted DNS [DNS over HTTPS].
echo    Your DNS requests are hidden from your ISP and from public Wi-Fi.
echo    If DoH is blocked on a network, Windows falls back to normal DNS.
echo.
choice /c YN /n /m "   Turn on encrypted DNS? [Y/N]: "
if errorlevel 2 exit /b 0
set "NSR_DOH=%DOH_URL%"
echo.
call :psDoH
call :log "Encrypted DNS [DoH] turned on for %DNS_NAME%"
exit /b 0

:dnsReset
call :header "RESET DNS TO AUTOMATIC"
echo    DNS servers will come from your router / ISP again.
echo.
choice /c YN /n /m "   Reset now? [Y/N]: "
if errorlevel 2 goto :dnsMenu
echo.
powershell -NoProfile -Command "$n=0; Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $a=$_; try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction Stop; Write-Host ('   [ OK ]  ' + $a.Name); $n++ } catch { Write-Host ('   [FAIL]  ' + $a.Name) } }; if($n -eq 0){ Write-Host '   No active adapter was changed.'; exit 1 }"
ipconfig /flushdns >nul 2>&1
call :log "DNS reset to automatic"
call :connectionTest
call :pauseBack
goto :dnsMenu

rem ============================================================================
rem  [3] DNS SPEED TEST
rem ============================================================================
:pingMenu
call :header "DNS SPEED TEST"
echo    Sends real DNS requests to each provider and measures the answer time.
echo    Lower ms = faster. Failed = the server did not answer in time.
echo.
echo    [1]  Test all 20 recommended providers  takes about 1 minute
echo    [2]  Test my own DNS server             Enter an IPv4 address
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 120 /n /m "   Press a key [1, 2 or 0]: "
if errorlevel 3 goto :mainMenu
if errorlevel 2 goto :pingCustom
call :buildHosts
goto :pingRun

:pingCustom
call :header "DNS SPEED TEST - CUSTOM"
echo    Type the IPv4 address of the DNS server you want to test.
echo.
set "NSR_CIP="
call :askIP NSR_CIP "   DNS server IPv4 (Enter = cancel): " 4 N
if not defined NSR_CIP goto :pingMenu
set "NSR_HOSTS=99=Custom DNS=%NSR_CIP%"

:pingRun
call :header "DNS SPEED TEST - RUNNING"
echo    Asking 8 popular websites, 2 rounds for each server. Please wait...
echo.
ipconfig /flushdns >nul 2>&1
call :psDnsTest
set "FAST=%errorlevel%"
echo.
echo %SR%
if %FAST% LSS 1 goto :pingDone
if %FAST% GTR %PCOUNT% goto :pingDone
echo    Speed is not everything. The SAFE providers also block threats.
echo.
choice /c YN /n /m "   Use the fastest DNS now? [Y/N]: "
if errorlevel 2 goto :pingDone
set "PICK=%FAST%"
goto :provPick

:pingDone
call :pauseBack
goto :pingMenu

rem ============================================================================
rem  [4] NETWORK DIAGNOSTICS
rem ============================================================================
:diag
call :header "NETWORK DIAGNOSTICS"
echo    Checking router, Internet, IPv6, DNS and web access...
echo.
call :psDiag
call :log "Network diagnostics run"
call :pauseBack
goto :mainMenu

rem ============================================================================
rem  [5] PC INFORMATION
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
rem  [7] ABOUT
rem ============================================================================
:infoScript
call :header "ABOUT NSR"
echo    Name      : NSR - Network Settings Reset
echo    Version   : %VER%
echo    Author    : M1HA1586
echo    Website   : getnsr.xyz
echo.
echo    What's new in v%VER%:
echo     - 20 DNS providers in 4 groups: fast, private, safe, ads and family
echo     - New: DNS.SB, Control D, Mullvad, UncensoredDNS, CleanBrowsing, DNS4EU
echo     - Speed test shows progress and ranks every provider
echo     - The DNS view shows [DoH] when encrypted DNS is on
echo     - Your old DNS is saved before every change
echo     - Check for updates from this screen
echo.
echo    [1]  Open NSR on GitHub
echo    [2]  Open the NSR website
echo    [3]  Check for updates
echo    [4]  Open the backup and log folder
echo.
echo    [0]  Back
echo.
echo %SR%
choice /c 12340 /n /m "   Press a key [1-4, 0 = back]: "
if errorlevel 5 goto :mainMenu
if errorlevel 4 goto :openBK
if errorlevel 3 goto :updCheck
if errorlevel 2 goto :openWeb
start "" "https://github.com/M1HA1586/Network-Settings-Reset"
goto :infoScript

:openWeb
start "" "https://getnsr.xyz"
goto :infoScript

:updCheck
echo.
echo   Checking GitHub for a newer version...
echo.
call :psUpdate
call :pauseBack
goto :infoScript

:openBK
if not exist "%BK%" mkdir "%BK%" >nul 2>&1
start "" explorer "%BK%"
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
call :log "Bufferbloat optimizations applied"
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
call :log "Bufferbloat defaults restored"
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

rem  Writes one line with date and time in the NSR log file. %1 = text
:log
if not exist "%BK%" mkdir "%BK%" >nul 2>&1
>>"%BK%\NSR_log.txt" echo %date% %time:~0,8%  %~1
exit /b 0

rem  Saves the current DNS in the backup folder before NSR changes it
:backupDNS
if not exist "%BK%" mkdir "%BK%" >nul 2>&1
>>"%BK%\DNS_before.txt" echo [%date% %time:~0,8%]
>>"%BK%\DNS_before.txt" call :showDNS
exit /b 0

rem  Builds NSR_HOSTS for the speed test from the provider labels
rem  Format: id=name=ip,id=name=ip,...
:buildHosts
set "NSR_HOSTS="
set "HI=0"
:buildLoop
set /a HI+=1
call :prov%HI%
set "NSR_HOSTS=%NSR_HOSTS%%HI%=%DNS_NAME%=%DNS4_1%,"
if %HI% LSS %PCOUNT% goto :buildLoop
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

rem  Shows active adapters with their IPv4 and IPv6 DNS servers.
rem  [manual] = set by the user, [auto] = comes from the router / ISP
:showDNS
powershell -NoProfile -Command "$doh=@{}; try{ Get-DnsClientDohServerAddress -ErrorAction Stop | Where-Object { $_.AutoUpgrade } | ForEach-Object { $doh[[string]$_.ServerAddress]=1 } }catch{}; function Sd($i,$f,$k){ $s=@((Get-DnsClientServerAddress -InterfaceIndex $i.ifIndex -AddressFamily $f).ServerAddresses | Where-Object { $_ -notlike 'fec0:*' }); if($s.Count -eq 0){ return 'none' }; $m=(Get-ItemProperty ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $k + '\Parameters\Interfaces\' + $i.InterfaceGuid)).NameServer; $t='[auto]'; if($m){ $t='[manual]' }; $e=@($s | Where-Object { $doh.ContainsKey($_) }).Count; if($e -gt 0){ $t += ' [DoH]' }; return (($s -join ', ') + '  ' + $t) }; $a=@(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }); if($a.Count -eq 0){ Write-Host '   No active network adapter found.' }; foreach($n in $a){ Write-Host ('   ' + $n.Name); Write-Host ('      IPv4 : ' + (Sd $n IPv4 Tcpip)); Write-Host ('      IPv6 : ' + (Sd $n IPv6 Tcpip6)) }"
exit /b 0

rem  Sets DNS (values come from NSR_V4 and NSR_V6) on every active physical adapter
:psSetDNS
powershell -NoProfile -Command "$v4=$env:NSR_V4; $v6=$env:NSR_V6; $n=0; Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $a=$_; try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ($v4 -split ',') -ErrorAction Stop; Write-Host ('   [ OK ]  ' + $a.Name); $n++; if($v6){ try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ($v6 -split ',') -ErrorAction Stop } catch { Write-Host '           IPv6 DNS skipped on this adapter' } } } catch { Write-Host ('   [FAIL]  ' + $a.Name + '  ' + $_.Exception.Message) } }; if($n -eq 0){ Write-Host '   No active adapter was changed.'; exit 1 }"
exit /b 0

rem  Turns on DNS over HTTPS for the servers in NSR_V4 / NSR_V6 (template in NSR_DOH)
:psDoH
powershell -NoProfile -Command "$t=$env:NSR_DOH; $ips=@(($env:NSR_V4 + ',' + $env:NSR_V6) -split ',' | Where-Object { $_ }); $ok=0; foreach($ip in $ips){ try { if(Get-DnsClientDohServerAddress -ServerAddress $ip -ErrorAction SilentlyContinue){ Set-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $t -AutoUpgrade $true -AllowFallbackToUdp $true -ErrorAction Stop } else { Add-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $t -AutoUpgrade $true -AllowFallbackToUdp $true -ErrorAction Stop }; Write-Host ('   [ OK ]  DoH  ' + $ip); $ok++ } catch { Write-Host ('   [FAIL]  DoH  ' + $ip + '  ' + $_.Exception.Message) } }; if($ok -eq 0){ exit 1 }"
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
call :task "IPv6 connection (if available)"
powershell -NoProfile -Command "try { $r=(New-Object System.Net.NetworkInformation.Ping).Send('2606:4700:4700::1111',1500); if($r.Status -eq 'Success'){ exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
call :skip
call :task "Name resolution (DNS)"
powershell -NoProfile -Command "try { Resolve-DnsName example.com -DnsOnly -ErrorAction Stop | Out-Null } catch { exit 1 }" >nul 2>&1
call :status
exit /b 0

rem  Real DNS speed test. NSR_HOSTS = id=name=ip,id=name=ip ...
rem  Adds the current DNS for comparison. Exit code = id of the fastest provider.
:psDnsTest
powershell -NoProfile -Command "$d='google.com','youtube.com','facebook.com','wikipedia.org','amazon.com','microsoft.com','instagram.com','netflix.com'; $L=@(); foreach($e in ($env:NSR_HOSTS -split ',')){ $x=$e -split '=',3; if($x.Count -eq 3){ $L+=[pscustomobject]@{I=[int]$x[0];N=$x[1];H=$x[2]} } }; $ad=Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1; if($ad){ $c=@((Get-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4).ServerAddresses)[0]; if($c -and -not ($L | Where-Object {$_.H -eq $c})){ $L=@([pscustomobject]@{I=0;N='Your current DNS';H=$c}) + $L } }; $tot=$L.Count; $k=0; $Z=@(); $NA=@(); foreach($s in $L){ $k++; Write-Host -NoNewline ([string][char]13 + ('   [{0}/{1}] Testing {2}' -f $k,$tot,$s.N).PadRight(60)); $t=@(); $f=0; $up=$true; try{ Resolve-DnsName google.com -Server $s.H -Type A -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop | Out-Null }catch{ $up=$false; $NA+=$s.N }; if($up){ for($r=0;$r -lt 2;$r++){ foreach($n in $d){ $w=[Diagnostics.Stopwatch]::StartNew(); try{ Resolve-DnsName $n -Server $s.H -Type A -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop | Out-Null; $t+=$w.Elapsed.TotalMilliseconds }catch{ $f++ } } }; if($t.Count -gt 0){ $m=$t | Measure-Object -Average -Minimum -Maximum; $Z+=[pscustomobject]@{I=$s.I;N=$s.N;A=$m.Average;B=$m.Minimum;W=$m.Maximum;F=$f} } } }; Write-Host ([string][char]13 + ''.PadRight(60)); Write-Host '   Times are in ms. Top 10 and your current DNS:'; Write-Host ''; $o=@($Z | Sort-Object A); for($i=0;$i -lt $o.Count;$i++){ $q=$o[$i]; if($i -lt 10 -or $q.I -eq 0){ Write-Host ('   {0,2}. {1,-22} avg {2,6:N1}  best {3,5:N1}  worst {4,6:N1}  fail {5}/16' -f ($i+1),$q.N,$q.A,$q.B,$q.W,$q.F) } elseif($i -eq 10){ Write-Host '       ...' } }; if($NA.Count -gt 0){ Write-Host ''; Write-Host ('   No answer: ' + ($NA -join ', ')) }; if($o.Count -gt 0){ $b=$o[0]; Write-Host ''; Write-Host ('   Fastest: ' + $b.N); exit $b.I }; exit 0"
exit /b %errorlevel%

rem  Checks GitHub for a newer release. Only runs when the user chooses it.
:psUpdate
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $r=Invoke-RestMethod 'https://api.github.com/repos/M1HA1586/Network-Settings-Reset/releases/latest' -TimeoutSec 8 -ErrorAction Stop; $n=([string]$r.tag_name) -replace '^[vV]',''; if([version]$n -gt [version]$env:VER){ Write-Host ('   A newer version is out: v' + $n); Write-Host '   Download it from https://getnsr.xyz' } else { Write-Host ('   You have the latest version [v' + $env:VER + '].') } } catch { Write-Host '   Could not check. Are you online?' }"
exit /b 0

rem  Network diagnostics: shows the connection and tells where the problem is
:psDiag
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; function Ln($a,$b){ Write-Host ('   {0,-15}: {1}' -f $a,$b) }; function Ms($v){ if($v -ge 0){ return ([string]$v + ' ms') }; return 'no answer' }; function Ok($n,$g,$d){ $s='[ OK ]'; if(-not $g){ $s='[FAIL]' }; Write-Host ('   {0,-22} {1}  {2}' -f $n,$s,$d) }; function Pg($h){ $p=New-Object System.Net.NetworkInformation.Ping; $m=@(); for($i=0;$i -lt 3;$i++){ try{ $r=$p.Send($h,1500); if($r.Status -eq 'Success'){ $m+=[int]$r.RoundtripTime } }catch{} }; if($m.Count -gt 0){ return [int][math]::Round(($m | Measure-Object -Average).Average) }; return -1 }; $c=Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway } | Select-Object -First 1; if(-not $c){ Write-Host '   No connected adapter with a gateway was found.'; Write-Host '   Check the cable or the Wi-Fi first.'; exit 0 }; $gw=$c.IPv4DefaultGateway.NextHop; $ip4=($c.IPv4Address | Select-Object -First 1).IPAddress; $ip6=@($c.IPv6Address | ForEach-Object { $_.IPAddress } | Where-Object { $_ -notlike 'fe80*' }); $i6='none'; if($ip6.Count -gt 0){ $i6=$ip6[0] }; $dn=(@($c.DNSServer | ForEach-Object { $_.ServerAddresses } | Where-Object { $_ -notlike 'fec0:*' })) -join ', '; Ln 'Adapter' ($c.InterfaceAlias + '  ' + $c.NetAdapter.LinkSpeed); Ln 'Local IPv4' $ip4; Ln 'Local IPv6' $i6; Ln 'Gateway' $gw; Ln 'DNS servers' $dn; Write-Host ''; $g=Pg $gw; Ok 'Router (gateway)' ($g -ge 0) (Ms $g); $a=Pg '1.1.1.1'; Ok 'Internet IPv4' ($a -ge 0) (Ms $a); $b=Pg '2606:4700:4700::1111'; $d6='not available on this line'; if($b -ge 0){ $d6=Ms $b }; Ok 'Internet IPv6' ($b -ge 0) $d6; $dns=$false; $t=-1; $sw=[Diagnostics.Stopwatch]::StartNew(); try{ Resolve-DnsName example.com -DnsOnly -QuickTimeout -ErrorAction Stop | Out-Null; $dns=$true; $t=[int]$sw.Elapsed.TotalMilliseconds }catch{}; Ok 'DNS lookup' $dns (Ms $t); $web=$false; $pub='-'; $loc=''; try{ $w=Invoke-WebRequest 'https://www.cloudflare.com/cdn-cgi/trace' -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop; $web=$true; foreach($l in ([string]$w.Content -split '\s+')){ if($l -like 'ip=*'){ $pub=$l.Substring(3) }; if($l -like 'loc=*'){ $loc=$l.Substring(4) } } }catch{}; $wd='no answer'; if($web){ $wd='reachable' }; Ok 'Web access (HTTPS)' $web $wd; Write-Host ''; Ln 'Public IP' ($pub + '  ' + $loc); Write-Host ''; Write-Host '   Result:'; $net=(($a -ge 0) -or $web); if($net -and $dns){ Write-Host '   Everything looks fine.'; if($g -lt 0){ Write-Host '   Your router does not answer ping. This is normal on some routers.' } } elseif($net){ Write-Host '   The Internet works, but DNS does not.'; Write-Host '   Use Change DNS from the main menu, or run the Quick Fix.' } elseif($g -ge 0){ Write-Host '   Your router answers, but there is no Internet.'; Write-Host '   Restart the router. If it stays down, call your ISP.' } else { Write-Host '   No answer from your router.'; Write-Host '   Check the cable or the Wi-Fi, then run Network Maintenance.' }"
exit /b 0

rem  Short hardware summary
:psInfo
powershell -NoProfile -Command "$o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor | Select-Object -First 1; $b=Get-CimInstance Win32_BaseBoard; $up=(Get-Date) - $o.LastBootUpTime; $f='   {0,-11}: {1}'; Write-Host ($f -f 'Windows',($o.Caption + ' (build ' + $o.BuildNumber + ')')); Write-Host ($f -f 'CPU',($c.Name.Trim() + ' - ' + $c.NumberOfCores + ' cores, ' + $c.NumberOfLogicalProcessors + ' threads')); Write-Host ($f -f 'RAM',([math]::Round($o.TotalVisibleMemorySize/1MB,1).ToString() + ' GB total, ' + [math]::Round($o.FreePhysicalMemory/1MB,1) + ' GB free')); foreach($g in Get-CimInstance Win32_VideoController){ Write-Host ($f -f 'GPU',$g.Name) }; Write-Host ($f -f 'Mainboard',($b.Manufacturer + ' ' + $b.Product)); foreach($d in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3'){ Write-Host ($f -f ('Disk ' + $d.DeviceID),([math]::Round($d.FreeSpace/1GB,0).ToString() + ' GB free of ' + [math]::Round($d.Size/1GB,0) + ' GB')) }; Write-Host ($f -f 'Uptime',('{0}d {1}h {2}m' -f $up.Days,$up.Hours,$up.Minutes))"
powershell -NoProfile -Command "$f='   {0,-11}: {1}'; Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { Write-Host ($f -f 'IPv4 address',($_.IPAddress + '  (' + $_.InterfaceAlias + ')')) }; Get-NetIPAddress -AddressFamily IPv6 | Where-Object { $_.IPAddress -notlike 'fe80*' -and $_.IPAddress -ne '::1' } | ForEach-Object { Write-Host ($f -f 'IPv6 address',($_.IPAddress + '  (' + $_.InterfaceAlias + ')')) }"
exit /b 0
