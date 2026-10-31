@echo off
setlocal EnableExtensions
color 07
set "VER=1.3"
title NSR v%VER% - Network Settings Reset
set "NEEDS_RESTART=0"
set "BK=%USERPROFILE%\NSR_Backup"
set "NSR_SELF=%~f0"
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
rem  Same keys on every screen: number keys pick an item and 0 always goes
rem  back (on this screen 0 closes NSR).
rem ============================================================================
:mainMenu
call :logo
echo.
call :psBlock dash
echo.
echo %SR%
echo.
echo    FIX
echo     [1]  Fix My Connection       Quick Fix, adapter restart, Full Reset
echo.
echo    DNS
echo     [2]  DNS Center              Change, check and undo your DNS
echo     [3]  DNS Speed Test          Find the fastest DNS for your line
echo.
echo    TEST
echo     [4]  Network Diagnostics     Find out where the problem is
echo     [5]  Speed and Lag Test      NEW  Speed, ping, bufferbloat grade
echo     [6]  Wi-Fi Tools             NEW  Signal, channels, saved passwords
echo.
echo    TOOLS
echo     [7]  Network Toolbox         NEW  Ping, trace, ports, MTU, report
echo     [8]  Bufferbloat Optimizer   Advanced: less lag on a busy line
echo     [9]  About and Updates       Version, news, links
call :foot Exit
choice /c 1234567890 /n /m "   Choose [1-9, 0 = Exit]: "
if errorlevel 10 goto :exitMenu
if errorlevel 9 goto :infoScript
if errorlevel 8 goto :bufferbloat
if errorlevel 7 goto :toolMenu
if errorlevel 6 goto :wifiMenu
if errorlevel 5 goto :speedMenu
if errorlevel 4 goto :diag
if errorlevel 3 goto :pingMenu
if errorlevel 2 goto :dnsMenu
goto :fixMenu

rem ============================================================================
rem  [1] FIX MY CONNECTION
rem ============================================================================
:fixMenu
call :header "Home / Fix My Connection"
echo    Pick the strength. Start with [1]. Go higher only if it does not help.
echo.
echo     [1]  Quick Fix               Flush DNS, clear ARP, renew the IP
echo                                  Safe. The Internet drops a few seconds.
echo.
echo     [2]  Restart Adapters        Quick Fix + restart the network cards
echo                                  Helps when Wi-Fi or a cable acts up.
echo.
echo     [3]  Full Reset              Quick Fix + reset Winsock and TCP/IP
echo                                  For serious problems. Needs a restart.
call :foot Back
choice /c 1230 /n /m "   Choose [1-3, 0 = Back]: "
if errorlevel 4 goto :mainMenu
if errorlevel 3 (set "MAINT=FULL") else if errorlevel 2 (set "MAINT=ADAPTER") else (set "MAINT=QUICK")
echo.
echo   Your connection will drop for a few seconds.
echo   Save your work and close downloads and remote sessions first.
echo.
choice /c YN /n /m "   Continue? [Y/N]: "
if errorlevel 2 goto :fixMenu

call :header "Home / Fix My Connection / Running"
call :task "Flushing DNS cache"
ipconfig /flushdns >nul 2>&1
call :status
call :task "Clearing ARP cache"
netsh interface ip delete arpcache >nul 2>&1
call :status
if "%MAINT%"=="ADAPTER" call :adapterFix
call :task "Renewing IP address"
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
call :done
if "%MAINT%"=="FULL" call :fullReset
call :log "Fix My Connection: %MAINT%"
call :connectionTest
echo.
if "%MAINT%"=="FULL" (
    echo   IMPORTANT: restart your PC to finish the reset.
) else (
    echo   Still no Internet? Try the next level, or unplug your router for 30 seconds.
)
call :pauseBack
goto :fixMenu

:adapterFix
call :task "Restarting network adapters"
call :psBlock adapterrestart >nul 2>&1
call :status
timeout /t 6 /nobreak >nul
exit /b 0

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
rem  [2] DNS CENTER
rem ============================================================================
:dnsMenu
call :header "Home / DNS Center"
echo    Active network adapters and their current DNS:
echo.
call :showDNS
echo.
echo %SR%
echo.
echo     [1]  Recommended Providers   Fast, private, safe, ads, family
echo     [2]  My Own DNS              Type your own addresses
echo     [3]  Reset to Automatic      Use the router / ISP DNS again
echo     [4]  Undo Last Change        Go back to your DNS from before NSR
echo     [5]  DNS Check               Who really answers? Is it rewritten?
call :foot Back
choice /c 123450 /n /m "   Choose [1-5, 0 = Back]: "
if errorlevel 6 goto :mainMenu
if errorlevel 5 goto :dnsCheck
if errorlevel 4 goto :dnsUndo
if errorlevel 3 goto :dnsReset
if errorlevel 2 goto :dnsCustom

:dnsRecommended
call :header "Home / DNS Center / Recommended Providers"
echo    Pick a type of DNS. IPv4, IPv6 and encrypted DNS [DoH] data of every
echo    provider comes from its official page.
echo.
echo     [1]  Fast and Reliable       Big, stable networks
echo     [2]  Private                 Nothing is blocked. Privacy focused
echo     [3]  Safe                    Blocks malware and phishing
echo     [4]  Ads and Family          Blocks ads, trackers or adult sites
echo.
echo    Real speed depends on your location. Use DNS Speed Test in the main
echo    menu to see what is fastest for you.
call :foot Back
choice /c 12340 /n /m "   Choose [1-4, 0 = Back]: "
if errorlevel 5 goto :dnsMenu
if errorlevel 4 goto :catAds
if errorlevel 3 goto :catSafe
if errorlevel 2 goto :catPrivate

:catFast
call :header "Home / DNS Center / Recommended / Fast and Reliable"
echo     [1]  Cloudflare              1.1.1.1         Fast, privacy focused
echo     [2]  Google                  8.8.8.8         Very popular and reliable
echo     [3]  Cisco OpenDNS           208.67.222.222  Stable, has filter options
echo     [4]  GCore                   95.85.95.85     Alternative provider
call :foot Back
choice /c 12340 /n /m "   Choose [1-4, 0 = Back]: "
set "K=%errorlevel%"
if %K%==5 goto :dnsRecommended
set /a PICK=%K%+0
goto :provPick

:catPrivate
call :header "Home / DNS Center / Recommended / Private"
echo    These do not filter anything. Pick one for privacy, not for protection.
echo.
echo     [1]  DNS.SB                  185.222.222.222 No filtering, DNSSEC
echo     [2]  Control D               76.76.2.0       Free, no filtering
echo     [3]  Mullvad                 194.242.2.2     Privacy focused, Sweden
echo     [4]  DNS4EU Unfiltered       86.54.11.100    European, no filtering
echo     [5]  UncensoredDNS           91.239.100.100  Danish, no filtering
call :foot Back
choice /c 123450 /n /m "   Choose [1-5, 0 = Back]: "
set "K=%errorlevel%"
if %K%==6 goto :dnsRecommended
set /a PICK=%K%+4
goto :provPick

:catSafe
call :header "Home / DNS Center / Recommended / Safe"
echo    They block dangerous sites on purpose. A blocked site is not a bug.
echo.
echo     [1]  Quad9                   9.9.9.9         Non-profit, no personal logs
echo     [2]  Cloudflare Security     1.1.1.2         Fast, blocks malware
echo     [3]  DNS4EU Protective       86.54.11.1      European, blocks threats
echo     [4]  CleanBrowsing Security  185.228.168.9   Blocks malware, phishing
echo     [5]  Mullvad Base            194.242.2.4     Blocks ads, trackers, malware
call :foot Back
choice /c 123450 /n /m "   Choose [1-5, 0 = Back]: "
set "K=%errorlevel%"
if %K%==6 goto :dnsRecommended
set /a PICK=%K%+9
goto :provPick

:catAds
call :header "Home / DNS Center / Recommended / Ads and Family"
echo    They block ads, trackers or adult sites on purpose.
echo.
echo     [1]  AdGuard DNS             94.140.14.14    Blocks ads, trackers, malware
echo     [2]  AdGuard Family          94.140.14.15    Also blocks adult sites
echo     [3]  Mullvad Adblock         194.242.2.3     Blocks ads and trackers
echo     [4]  DNS4EU Ads Block        86.54.11.13     European, blocks threats, ads
echo     [5]  Control D Family        76.76.2.4       Blocks adult sites, malware
echo     [6]  CleanBrowsing Family    185.228.168.168 Strict, blocks adult sites
call :foot Back
choice /c 1234560 /n /m "   Choose [1-6, 0 = Back]: "
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
call :header "Home / DNS Center / My Own DNS"
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
call :header "Home / DNS Center / Apply"
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
echo   If something stops working, use Undo Last Change in the DNS Center,
echo   or Reset to Automatic.
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
call :header "Home / DNS Center / Reset to Automatic"
echo    DNS servers will come from your router / ISP again.
echo.
choice /c YN /n /m "   Reset now? [Y/N]: "
if errorlevel 2 goto :dnsMenu
echo.
call :backupDNS
powershell -NoProfile -Command "$n=0; Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $a=$_; try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction Stop; Write-Host ('   [ OK ]  ' + $a.Name); $n++ } catch { Write-Host ('   [FAIL]  ' + $a.Name) } }; if($n -eq 0){ Write-Host '   No active adapter was changed.'; exit 1 }"
ipconfig /flushdns >nul 2>&1
call :log "DNS reset to automatic"
call :connectionTest
call :pauseBack
goto :dnsMenu

:dnsUndo
call :header "Home / DNS Center / Undo Last Change"
echo    This puts back the DNS you had before the last change made with NSR.
echo.
choice /c YN /n /m "   Undo now? [Y/N]: "
if errorlevel 2 goto :dnsMenu
echo.
call :psBlock dnsrestore
set "RC=%errorlevel%"
ipconfig /flushdns >nul 2>&1
if "%RC%"=="0" call :log "DNS restored from backup"
if "%RC%"=="0" call :connectionTest
call :pauseBack
goto :dnsMenu

:dnsCheck
call :header "Home / DNS Center / DNS Check"
echo    Looks at which DNS server really asks the Internet, and if your DNS
echo    rewrites answers for names that do not exist.
echo.
call :psBlock dnscheck
call :log "DNS check run"
call :pauseBack
goto :dnsMenu

rem ============================================================================
rem  [3] DNS SPEED TEST
rem ============================================================================
:pingMenu
call :header "Home / DNS Speed Test"
echo    Sends real DNS requests to each provider and measures the answer time.
echo    Lower ms = faster. Failed = the server did not answer in time.
echo.
echo     [1]  Test All Providers      All 20 recommended, about 1 minute
echo     [2]  Test My Own DNS         Enter an IPv4 address
call :foot Back
choice /c 120 /n /m "   Choose [1-2, 0 = Back]: "
if errorlevel 3 goto :mainMenu
if errorlevel 2 goto :pingCustom
call :buildHosts
goto :pingRun

:pingCustom
call :header "Home / DNS Speed Test / My Own DNS"
echo    Type the IPv4 address of the DNS server you want to test.
echo.
set "NSR_CIP="
call :askIP NSR_CIP "   DNS server IPv4 (Enter = cancel): " 4 N
if not defined NSR_CIP goto :pingMenu
set "NSR_HOSTS=99=Custom DNS=%NSR_CIP%"

:pingRun
call :header "Home / DNS Speed Test / Running"
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
call :header "Home / Network Diagnostics"
echo    Checking router, Internet, IPv6, DNS and web access...
echo.
call :psDiag
call :log "Network diagnostics run"
call :pauseBack
goto :mainMenu

rem ============================================================================
rem  [5] SPEED AND LAG TEST
rem ============================================================================
:speedMenu
call :header "Home / Speed and Lag Test"
echo    Measures your real download and upload speed, your ping, and how much
echo    your ping grows when the line is busy [bufferbloat].
echo.
echo    It uses speed.cloudflare.com and moves data for about 20 seconds:
echo    roughly 200 MB on a 100 Mbps line, over 1 GB on a very fast one.
echo    Do not run it on mobile data or a metered connection.
echo.
echo     [1]  Start the Test          Takes about 30 seconds
echo     [2]  Previous Results        Your last tests, to compare
call :foot Back
choice /c 120 /n /m "   Choose [1-2, 0 = Back]: "
if errorlevel 3 goto :mainMenu
if errorlevel 2 goto :speedHist
call :header "Home / Speed and Lag Test / Running"
echo    Close downloads, streams and games first for a fair result.
echo.
call :psBlock speed
call :log "Speed and lag test run"
call :pauseBack
goto :speedMenu

:speedHist
call :header "Home / Speed and Lag Test / Previous Results"
call :psBlock speedhist
call :pauseBack
goto :speedMenu

rem ============================================================================
rem  [6] WI-FI TOOLS
rem ============================================================================
:wifiMenu
call :header "Home / Wi-Fi Tools"
echo    Tools for wireless connections.
echo.
echo     [1]  This Connection         Signal, speed and details
echo     [2]  Nearby Networks         Channel traffic, best channel
echo     [3]  Saved Passwords         Passwords stored on this PC
echo     [4]  History Report          Disconnects and errors, last days
call :foot Back
choice /c 12340 /n /m "   Choose [1-4, 0 = Back]: "
if errorlevel 5 goto :mainMenu
if errorlevel 4 goto :wifiReport
if errorlevel 3 goto :wifiPass
if errorlevel 2 goto :wifiScan
call :header "Home / Wi-Fi Tools / This Connection"
call :psBlock wifinow
call :wifiAfter
goto :wifiMenu

:wifiScan
call :header "Home / Wi-Fi Tools / Nearby Networks"
call :psBlock wifiscan
call :wifiAfter
goto :wifiMenu

:wifiPass
call :header "Home / Wi-Fi Tools / Saved Passwords"
echo    This shows the password of every Wi-Fi network saved on this PC.
echo    It is printed on the screen. Make sure nobody is looking.
echo.
choice /c YN /n /m "   Show the passwords? [Y/N]: "
if errorlevel 2 goto :wifiMenu
echo.
call :psBlock wifipass
call :pauseBack
goto :wifiMenu

:wifiReport
call :header "Home / Wi-Fi Tools / History Report"
echo    Windows builds an HTML report with your Wi-Fi history. About 20 seconds.
echo.
call :task "Building the Wi-Fi report"
netsh wlan show wlanreport >nul 2>&1
set "RC=%errorlevel%"
if "%RC%"=="0" (echo [ OK ]) else (echo [FAIL])
if not "%RC%"=="0" (
    echo.
    echo   No report. Is there a Wi-Fi adapter on this PC?
    call :pauseBack
    goto :wifiMenu
)
echo.
echo   Opening the report in your browser...
start "" "%ProgramData%\Microsoft\Windows\WlanReport\wlan-report-latest.html"
call :pauseBack
goto :wifiMenu

rem  Called right after a Wi-Fi block. Exit code 2 = Windows did not allow it.
:wifiAfter
set "RC=%errorlevel%"
if "%RC%"=="2" call :locHint
call :pauseBack
exit /b 0

:locHint
echo.
echo   Windows 11 lets programs read Wi-Fi details only when Location services
echo   are turned on. NSR does not use or store your location.
echo.
choice /c YN /n /m "   Open the Windows Location settings? [Y/N]: "
if errorlevel 2 exit /b 0
start "" "ms-settings:privacy-location"
exit /b 0

rem ============================================================================
rem  [7] NETWORK TOOLBOX
rem ============================================================================
:toolMenu
call :header "Home / Network Toolbox"
echo    TEST
echo     [1]  Ping and Packet Loss    Is the line stable?
echo     [2]  Trace Route             Where does it slow down?
echo     [3]  Port Checker            Is a port open on a host?
echo.
echo    LOOK
echo     [4]  Active Connections      Which programs use the Internet?
echo     [5]  Proxy and VPN Check     Find hidden proxies, turn them off
echo     [6]  Hosts File              Sites blocked? Check or reset the file
echo.
echo    TUNE AND SHARE
echo     [7]  Best MTU                Find the best packet size for your line
echo     [8]  Network Report          Save everything in one file for support
echo     [9]  PC Information          CPU, RAM, GPU, disks, network
call :foot Back
choice /c 1234567890 /n /m "   Choose [1-9, 0 = Back]: "
if errorlevel 10 goto :mainMenu
if errorlevel 9 goto :infoPC
if errorlevel 8 goto :tbReport
if errorlevel 7 goto :mtuMenu
if errorlevel 6 goto :hostsMenu
if errorlevel 5 goto :tbProxy
if errorlevel 4 goto :tbConns
if errorlevel 3 goto :tbPort
if errorlevel 2 goto :tbTrace

:tbPing
call :header "Home / Network Toolbox / Ping and Packet Loss"
echo    Sends 30 pings and shows the speed, the stability and lost packets.
echo.
echo    Choose a target:
echo.
echo     [1]  My Router               Tests the Wi-Fi or cable at home
echo     [2]  Cloudflare              1.1.1.1
echo     [3]  Google                  8.8.8.8
echo     [4]  Another Host            Type a name or an IP address
call :foot Back
choice /c 12340 /n /m "   Choose [1-4, 0 = Back]: "
if errorlevel 5 goto :toolMenu
if errorlevel 4 goto :tbPingHost
if errorlevel 3 (set "NSR_TARGET=8.8.8.8") else if errorlevel 2 (set "NSR_TARGET=1.1.1.1") else (set "NSR_TARGET=GATEWAY")
goto :tbPingRun

:tbPingHost
echo.
call :askHost NSR_TARGET "   Host or IP [Enter = cancel]: "
if not defined NSR_TARGET goto :tbPing

:tbPingRun
call :header "Home / Network Toolbox / Ping and Packet Loss / Running"
call :psBlock ping
call :log "Ping test: %NSR_TARGET%"
call :pauseBack
goto :tbPing

:tbTrace
call :header "Home / Network Toolbox / Trace Route"
echo    Shows every stop between your PC and a server. A stop where the time
echo    jumps up is where the connection slows down.
echo.
call :askHost NSR_HOST "   Host or IP, for example 1.1.1.1 [Enter = cancel]: "
if not defined NSR_HOST goto :toolMenu
call :header "Home / Network Toolbox / Trace Route / Running"
echo    Tracing the route to %NSR_HOST% ...
echo.
tracert -d -h 20 -w 1500 "%NSR_HOST%"
call :log "Trace route: %NSR_HOST%"
call :pauseBack
goto :toolMenu

:tbPort
call :header "Home / Network Toolbox / Port Checker"
echo    Checks if a TCP port answers on a host. Useful for game servers,
echo    remote desktop, web servers or port forwarding.
echo.
call :askHost NSR_HOST "   Host or IP [Enter = cancel]: "
if not defined NSR_HOST goto :toolMenu
call :askPort
if not defined NSR_PORT goto :toolMenu
echo.
call :psBlock port
call :log "Port check: %NSR_HOST% %NSR_PORT%"
call :pauseBack
goto :toolMenu

:tbConns
call :header "Home / Network Toolbox / Active Connections"
echo    Which programs talk to the Internet right now:
echo.
call :psBlock conns
call :pauseBack
goto :toolMenu

:tbProxy
call :header "Home / Network Toolbox / Proxy and VPN Check"
call :psBlock proxy
set "RC=%errorlevel%"
if not "%RC%"=="1" (
    echo.
    echo   No manual proxy is set.
    call :pauseBack
    goto :toolMenu
)
echo.
echo %SR%
echo   A proxy is set. If you did not set it yourself, turn it off.
echo   Some VPN and security programs set it on purpose and may set it again.
echo.
choice /c YN /n /m "   Turn the proxy off now? [Y/N]: "
if errorlevel 2 goto :toolMenu
echo.
call :regSet "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" "ProxyEnable" 0 "Manual proxy: off"
call :regDel "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" "ProxyServer" "Proxy server address: removed"
call :regDel "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" "AutoConfigURL" "Setup script: removed"
call :task "WinHTTP proxy: reset"
netsh winhttp reset proxy >nul 2>&1
call :status
call :log "Proxy settings turned off"
call :pauseBack
goto :toolMenu

:hostsMenu
call :header "Home / Network Toolbox / Hosts File"
call :psBlock hosts
echo.
echo %SR%
echo.
echo     [1]  Open in Notepad         Look at the whole file
echo     [2]  Reset to Default        Windows default. A backup is saved.
call :foot Back
choice /c 120 /n /m "   Choose [1-2, 0 = Back]: "
if errorlevel 3 goto :toolMenu
if errorlevel 2 goto :hostsReset
start "" notepad "%windir%\System32\drivers\etc\hosts"
goto :hostsMenu

:hostsReset
echo.
echo   This replaces the hosts file with the empty Windows default.
echo   Your old file is saved in %BK%
echo   Programs that added lines on purpose, like dev tools, may stop working.
echo.
choice /c YN /n /m "   Reset the hosts file now? [Y/N]: "
if errorlevel 2 goto :hostsMenu
echo.
call :psBlock hostsreset
if not errorlevel 1 call :log "Hosts file reset to default"
call :pauseBack
goto :hostsMenu

:mtuMenu
call :header "Home / Network Toolbox / Best MTU"
echo    MTU is the biggest packet your connection sends in one piece. A wrong
echo    value can make pages load slowly or break some connections. Most lines
echo    use 1500. Some, like PPPoE lines, need a little less.
echo.
echo     [1]  Find the Best MTU       Tests your line, offers to set it
echo     [2]  Back to Windows Default Sets the MTU to 1500
call :foot Back
choice /c 120 /n /m "   Choose [1-2, 0 = Back]: "
if errorlevel 3 goto :toolMenu
if errorlevel 2 goto :mtuDefault
echo.
call :psBlock mtu
set "MTU=%errorlevel%"
if %MTU% GEQ 576 goto :mtuOffer
call :pauseBack
goto :mtuMenu

:mtuOffer
echo.
choice /c YN /n /m "   Set the MTU to %MTU% now? [Y/N]: "
if errorlevel 2 goto :mtuMenu
set "NSR_MTU=%MTU%"
echo.
call :psBlock mtuset
call :log "MTU set to %MTU%"
echo.
echo   Run the Speed and Lag Test to see if it helped.
echo   To undo: Best MTU, then Back to Windows Default.
call :pauseBack
goto :mtuMenu

:mtuDefault
echo.
choice /c YN /n /m "   Set the MTU back to 1500? [Y/N]: "
if errorlevel 2 goto :mtuMenu
set "NSR_MTU=1500"
echo.
call :psBlock mtuset
call :log "MTU set to 1500"
call :pauseBack
goto :mtuMenu

:tbReport
call :header "Home / Network Toolbox / Network Report"
echo    Saves your network details, ping and DNS tests in one text file on your
echo    Desktop. Useful to send to your ISP or to a friend who helps you.
echo.
choice /c YN /n /m "   Create the report now? [Y/N]: "
if errorlevel 2 goto :toolMenu
echo.
call :psBlock report
set "RC=%errorlevel%"
if not "%RC%"=="0" (
    call :pauseBack
    goto :toolMenu
)
call :log "Network report saved"
echo.
choice /c YN /n /m "   Open the Desktop folder? [Y/N]: "
if errorlevel 2 goto :toolMenu
start "" explorer "shell:Desktop"
goto :toolMenu

:infoPC
call :header "Home / Network Toolbox / PC Information"
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
goto :toolMenu

rem ============================================================================
rem  [9] ABOUT AND UPDATES
rem ============================================================================
:infoScript
call :header "Home / About and Updates"
echo    Name      : NSR - Network Settings Reset
echo    Version   : %VER%
echo    Author    : M1HA1586
echo    Website   : getnsr.xyz
echo.
echo    What is new in v%VER%:
echo     - Same keys everywhere. 0 is always Back, or Exit on the main screen
echo     - New main screen with the live status of your connection
echo     - Speed and Lag Test with a bufferbloat grade
echo     - Wi-Fi Tools: nearby networks, best channel, saved passwords
echo     - Network Toolbox: ping, trace, ports, connections, proxy, hosts, MTU
echo     - DNS Center: undo the last change, check who answers
echo     - Fix My Connection: new Restart Adapters step
echo.
echo     [1]  Open NSR on GitHub
echo     [2]  Open the NSR Website
echo     [3]  Check for Updates
echo     [4]  Open Backup and Log Folder
call :foot Back
choice /c 12340 /n /m "   Choose [1-4, 0 = Back]: "
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
rem  [8] BUFFERBLOAT OPTIMIZER
rem ============================================================================
:bufferbloat
call :header "Home / Bufferbloat Optimizer - Advanced"
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
echo    Tip: measure first. Run the Speed and Lag Test before and after. With
echo    grade A or B you do not need this. The best fix is Smart Queue / SQM
echo    on your router, if it has it.
echo.
echo     [1]  Apply Optimizations
echo     [2]  Restore Windows Defaults
call :foot Back
choice /c 120 /n /m "   Choose [1-2, 0 = Back]: "
if errorlevel 3 goto :mainMenu
if errorlevel 2 goto :bbRestore

:bbApply
echo.
choice /c YN /n /m "   Apply the optimizations now? [Y/N]: "
if errorlevel 2 goto :bufferbloat
call :header "Home / Bufferbloat Optimizer / Applying"
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
call :header "Home / Bufferbloat Optimizer / Restoring Defaults"
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
call :header "Home / Exit"
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

rem  Big banner. Only the main screen uses it.
:logo
cls
echo.
echo %HR%
echo.
echo      #   #    ####   ####      Network Settings Reset
echo      ##  #   #       #   #     Fix, tune and test your network
echo      # # #    ###    ####
echo      #  ##       #   #  #      Version %VER%
echo      #   #   ####    #   #      getnsr.xyz
echo.
echo %HR%
exit /b 0

rem  Small header for every other screen. %1 = where you are
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

rem  Bottom of every menu. The key is always 0. %1 = Back or Exit
:foot
echo.
echo    [0]  %~1
echo.
echo %SR%
exit /b 0

:pauseBack
echo.
echo %SR%
echo    Press any key to go back...
pause >nul
exit /b 0

rem  Runs a PowerShell block stored at the end of this file. %1 = block name
rem  The "common" block is added in front of every block.
:psBlock
set "NSR_BLOCK=%~1"
powershell -NoProfile -Command "$t=[IO.File]::ReadAllText($env:NSR_SELF); $c=[regex]::Match($t,'(?s)#BEGIN common\r?\n(.*?)\r?\n#END common').Groups[1].Value; $m=[regex]::Match($t,'(?s)#BEGIN '+$env:NSR_BLOCK+'\r?\n(.*?)\r?\n#END '+$env:NSR_BLOCK+'(\r?\n|$)'); if(-not $m.Success){ Write-Host '   Internal error: block not found.'; exit 9 }; & ([scriptblock]::Create($c + [char]10 + $m.Groups[1].Value))"
exit /b %errorlevel%

rem  Asks for a host name or an IP address and checks the characters.
rem  %1 = variable name, %2 = prompt. Enter alone clears the variable.
:askHost
:askHostAgain
set "NSR_IP="
set /p "NSR_IP=%~2"
if not defined NSR_IP (
    set "%~1="
    exit /b 0
)
powershell -NoProfile -Command "if($env:NSR_IP -match '^[A-Za-z0-9][A-Za-z0-9.:-]{0,250}$'){exit 0}else{exit 1}"
if errorlevel 1 (
    echo   [!] Use only letters, numbers, dots, colons and dashes.
    goto :askHostAgain
)
set "%~1=%NSR_IP%"
exit /b 0

rem  Asks for a TCP port in NSR_PORT. Enter alone clears it.
:askPort
:askPortAgain
set "NSR_PORT="
set /p "NSR_PORT=   Port number 1-65535 [Enter = cancel]: "
if not defined NSR_PORT exit /b 0
powershell -NoProfile -Command "$p=0; if([int]::TryParse($env:NSR_PORT,[ref]$p) -and $p -ge 1 -and $p -le 65535){exit 0}else{exit 1}"
if errorlevel 1 (
    echo   [!] Type a number from 1 to 65535.
    goto :askPortAgain
)
exit /b 0

rem  Writes one line with date and time in the NSR log file. %1 = text
:log
if not exist "%BK%" mkdir "%BK%" >nul 2>&1
>>"%BK%\NSR_log.txt" echo %date% %time:~0,8%  %~1
exit /b 0

rem  Saves the current DNS in the backup folder before NSR changes it.
rem  DNS_before.txt is for reading, DNS_last.json is used by Undo Last Change.
:backupDNS
if not exist "%BK%" mkdir "%BK%" >nul 2>&1
>>"%BK%\DNS_before.txt" echo [%date% %time:~0,8%]
>>"%BK%\DNS_before.txt" call :showDNS
call :psBlock dnsbackup >nul 2>&1
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

rem ============================================================================
rem  POWERSHELL BLOCKS
rem  CMD never runs the text below. :psBlock reads it from this file and hands
rem  it to PowerShell. Every block sits between a #BEGIN and an #END line.
rem ============================================================================
exit /b 0

#BEGIN common
$ErrorActionPreference='SilentlyContinue'
$ProgressPreference='SilentlyContinue'
$global:NSRPing=New-Object System.Net.NetworkInformation.Ping
function Say($t){ Write-Host ('   ' + $t) }
function Hr(){ Write-Host '  ----------------------------------------------------------------------------' }
function F1($x){ return ([double]$x).ToString('0.0',[Globalization.CultureInfo]::InvariantCulture) }
function Ping1($h,$ms){ if(-not $ms){ $ms=1500 }; try{ $r=$global:NSRPing.Send($h,$ms); if($r.Status -eq 'Success'){ return [double]$r.RoundtripTime } }catch{}; return -1.0 }
function Med($a){ $s=@($a | Sort-Object); if($s.Count -eq 0){ return -1.0 }; $m=[int][math]::Floor($s.Count/2); if(($s.Count % 2) -eq 1){ return [double]$s[$m] }; return (([double]$s[$m-1]+[double]$s[$m])/2) }
function Jit($a){ $a=@($a); if($a.Count -lt 2){ return 0.0 }; $t=0.0; for($i=1;$i -lt $a.Count;$i++){ $t+=[math]::Abs($a[$i]-$a[$i-1]) }; return ($t/($a.Count-1)) }
function Gw(){ $r=Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric | Select-Object -First 1; if($r){ return [string]$r.NextHop }; return '' }
#END common

#BEGIN dash
$nic=$null
foreach($n in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()){
    if($n.OperationalStatus -ne 'Up'){ continue }
    if($n.NetworkInterfaceType -eq 'Loopback' -or $n.NetworkInterfaceType -eq 'Tunnel'){ continue }
    $g=@($n.GetIPProperties().GatewayAddresses | Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' -and $_.Address.ToString() -ne '0.0.0.0' })
    if($g.Count -gt 0){ $nic=$n; break }
}
if(-not $nic){
    Say 'Connection : NO NETWORK     No adapter with a gateway was found'
    Say 'DNS        : -'
    exit 0
}
$p=$nic.GetIPProperties()
$type=[string]$nic.NetworkInterfaceType
if($type -eq 'Wireless80211'){ $type='Wi-Fi' }
$ip='-'
$u=@($p.UnicastAddresses | Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1)
if($u.Count -gt 0){ $ip=$u[0].Address.ToString() }
$dns=@($p.DnsAddresses | ForEach-Object { $_.ToString() } | Where-Object { $_ -notlike 'fec0:*' })
$state='NO INTERNET'
$pt=''
$v=Ping1 '1.1.1.1' 800
if($v -ge 0){
    $state='ONLINE'
    $pt='     Ping ' + [int]$v + ' ms'
} else {
    try{
        $c=New-Object Net.Sockets.TcpClient
        $a=$c.BeginConnect('1.1.1.1',443,$null,$null)
        if($a.AsyncWaitHandle.WaitOne(1000,$false) -and $c.Connected){ $state='ONLINE' }
        $c.Close()
    }catch{}
}
Say ('Connection : ' + $state + '     ' + $type + '  ' + $ip + $pt)
$d='-'
if($dns.Count -gt 0){ $d=(($dns | Select-Object -First 3) -join ', ') }
Say ('DNS        : ' + $d)
exit 0
#END dash

#BEGIN dnsbackup
$o=@()
foreach($a in @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })){
    $v4=@((Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4).ServerAddresses | Where-Object { $_ })
    $v6=@((Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv6).ServerAddresses | Where-Object { $_ -and $_ -notlike 'fec0:*' })
    $m4=(Get-ItemProperty ('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\' + $a.InterfaceGuid)).NameServer
    $m6=(Get-ItemProperty ('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\' + $a.InterfaceGuid)).NameServer
    if(-not $m4){ $v4=@() }
    if(-not $m6){ $v6=@() }
    $o+=[pscustomobject]@{ Name=[string]$a.Name; Guid=[string]$a.InterfaceGuid; V4=$v4; V6=$v6 }
}
if(-not (Test-Path $env:BK)){ New-Item -ItemType Directory -Path $env:BK -Force | Out-Null }
ConvertTo-Json -InputObject @($o) -Depth 4 | Set-Content -Path (Join-Path $env:BK 'DNS_last.json') -Encoding UTF8
exit 0
#END dnsbackup

#BEGIN dnsrestore
$f=Join-Path $env:BK 'DNS_last.json'
if(-not (Test-Path $f)){
    Say 'No saved DNS was found. NSR saves it before every DNS change.'
    exit 3
}
$o=@(Get-Content -Path $f -Raw | ConvertFrom-Json)
$n=0
foreach($e in $o){
    $a=Get-NetAdapter -Physical | Where-Object { $_.InterfaceGuid -eq $e.Guid -and $_.Status -eq 'Up' } | Select-Object -First 1
    if(-not $a){ continue }
    try{
        Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction Stop
        $v4=@($e.V4 | Where-Object { $_ })
        $v6=@($e.V6 | Where-Object { $_ })
        if($v4.Count -gt 0){ Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $v4 -ErrorAction Stop }
        if($v6.Count -gt 0){ Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $v6 -ErrorAction Stop }
        $what='automatic (router / ISP)'
        if(($v4.Count + $v6.Count) -gt 0){ $what=(($v4 + $v6) -join ', ') }
        Say ('[ OK ]  ' + $a.Name + '  ->  ' + $what)
        $n++
    }catch{
        Say ('[FAIL]  ' + $a.Name + '  ' + $_.Exception.Message)
    }
}
if($n -eq 0){
    Say 'No matching active adapter was found.'
    exit 1
}
exit 0
#END dnsrestore

#BEGIN dnscheck
Say 'Check 1 of 2 - Which DNS server really asks the Internet?'
Write-Host ''
$a=''
$g=''
try{
    $r=Resolve-DnsName 'whoami.akamai.net' -Type A -DnsOnly -NoHostsFile -ErrorAction Stop | Where-Object { $_.IPAddress } | Select-Object -First 1
    if($r){ $a=[string]$r.IPAddress }
}catch{}
try{
    $r=Resolve-DnsName 'o-o.myaddr.l.google.com' -Type TXT -DnsOnly -NoHostsFile -ErrorAction Stop | Where-Object { $_.Strings } | Select-Object -First 1
    if($r){
        foreach($s in @($r.Strings)){
            $x=$null
            if([Net.IPAddress]::TryParse([string]$s,[ref]$x)){ $g=[string]$s; break }
        }
    }
}catch{}
$set=@()
foreach($ad in @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })){
    $set+=@((Get-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4).ServerAddresses)
}
$set=@($set | Where-Object { $_ } | Select-Object -Unique)
$sv='none'
if($set.Count -gt 0){ $sv=($set -join ', ') }
$av='no answer'
if($a){ $av=$a }
$gv='no answer'
if($g){ $gv=$g }
Say ('DNS set on this PC     : ' + $sv)
Say ('Seen by Akamai         : ' + $av)
Say ('Seen by Google         : ' + $gv)
Write-Host ''
Say 'The last two are the addresses the Internet sees when your DNS asks.'
Say 'Router or ISP DNS : you see an address of your ISP.'
Say 'Public DNS        : you see an address of that company.'
Write-Host ''
Hr
Write-Host ''
Say 'Check 2 of 2 - Does your DNS rewrite answers for names that do not exist?'
Write-Host ''
$rnd='nsr-' + (Get-Random -Minimum 100000 -Maximum 999999) + '.invalid'
$hij=$false
try{
    $r=Resolve-DnsName $rnd -Type A -DnsOnly -NoHostsFile -ErrorAction Stop
    if($r | Where-Object { $_.IPAddress }){ $hij=$true }
}catch{}
if($hij){
    Say '[WARN] A name that cannot exist got an answer.'
    Say '       Your ISP or router may redirect mistyped addresses to ad pages.'
    Say '       Use Change DNS to pick a provider that does not do this.'
} else {
    Say '[ OK ] Names that do not exist are answered correctly [no such name].'
}
exit 0
#END dnscheck

#BEGIN adapterrestart
$n=0
foreach($a in @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })){
    try{
        Restart-NetAdapter -Name $a.Name -Confirm:$false -ErrorAction Stop
        Say ('[ OK ]  ' + $a.Name)
        $n++
    }catch{
        Say ('[FAIL]  ' + $a.Name)
    }
}
if($n -eq 0){ exit 1 }
exit 0
#END adapterrestart

#BEGIN speed
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::DefaultConnectionLimit=64
[Net.ServicePointManager]::Expect100Continue=$false
$base=$env:NSR_SPEEDBASE
if(-not $base){ $base='https://speed.cloudflare.com' }
$ph=$env:NSR_SPEEDPING
if(-not $ph){ $ph='1.1.1.1' }
$ramp=2
$win=7

$loc=''
try{
    $w=Invoke-WebRequest ($base + '/cdn-cgi/trace') -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop
    $colo=''
    $cc=''
    $txt=$w.Content
    if($txt -is [byte[]]){ $txt=[Text.Encoding]::UTF8.GetString($txt) }
    foreach($l in ([string]$txt -split "`n")){
        if($l -like 'colo=*'){ $colo=$l.Substring(5).Trim() }
        if($l -like 'loc=*'){ $cc=$l.Substring(4).Trim() }
    }
    $loc=('Cloudflare ' + $colo + ' ' + $cc).Trim()
}catch{}
if(-not $loc){
    Say '[FAIL] Cannot reach speed.cloudflare.com.'
    Say '       Check your Internet, firewall, VPN or proxy and try again.'
    exit 1
}
Say ('Test server : ' + $loc)
Say ('Ping target : ' + $ph)
Write-Host ''

$workerDown={
    param($S,$k,$url)
    $buf=New-Object byte[] 65536
    while(-not $S.Stop){
        try{
            $r=[Net.HttpWebRequest]::Create($url)
            $r.Timeout=15000
            $r.ReadWriteTimeout=15000
            $r.UserAgent='NSR'
            $resp=$r.GetResponse()
            $st=$resp.GetResponseStream()
            while(-not $S.Stop){
                $n=$st.Read($buf,0,$buf.Length)
                if($n -le 0){ break }
                $S[$k]+=$n
            }
            $r.Abort()
        }catch{
            Start-Sleep -Milliseconds 200
        }
    }
}

$workerUp={
    param($S,$k,$url)
    $chunk=New-Object byte[] 65536
    $size=4000000
    while(-not $S.Stop){
        try{
            $r=[Net.HttpWebRequest]::Create($url)
            $r.Method='POST'
            $r.Timeout=20000
            $r.ReadWriteTimeout=20000
            $r.UserAgent='NSR'
            $r.ContentType='application/octet-stream'
            $r.AllowWriteStreamBuffering=$false
            $r.ContentLength=$size
            $w=$r.GetRequestStream()
            $left=$size
            while($left -gt 0 -and -not $S.Stop){
                $c=[math]::Min($left,$chunk.Length)
                $w.Write($chunk,0,$c)
                $S[$k]+=$c
                $left-=$c
            }
            if($S.Stop){ $r.Abort(); break }
            $w.Close()
            $resp=$r.GetResponse()
            $resp.Close()
        }catch{
            Start-Sleep -Milliseconds 200
        }
    }
}

function SumB($S,$n){ $t=[long]0; for($i=0;$i -lt $n;$i++){ $t+=[long]$S['b' + $i] }; return $t }

function RunLoad($code,$url,$threads){
    $S=[hashtable]::Synchronized(@{ Stop=$false })
    for($i=0;$i -lt $threads;$i++){ $S['b' + $i]=[long]0 }
    $pool=[runspacefactory]::CreateRunspacePool(1,$threads)
    $pool.Open()
    $jobs=@()
    for($i=0;$i -lt $threads;$i++){
        $p=[powershell]::Create()
        $p.RunspacePool=$pool
        [void]$p.AddScript($code.ToString())
        [void]$p.AddArgument($S)
        [void]$p.AddArgument('b' + $i)
        [void]$p.AddArgument($url)
        $jobs+=[pscustomobject]@{ P=$p; H=$p.BeginInvoke() }
    }
    Start-Sleep -Seconds $ramp
    $b0=SumB $S $threads
    $sw=[Diagnostics.Stopwatch]::StartNew()
    $lat=@()
    while($sw.Elapsed.TotalSeconds -lt $win){
        if($haveping){
            $v=Ping1 $ph 1500
            if($v -lt 0){ $v=1500.0 }
            $lat+=$v
        }
        Start-Sleep -Milliseconds 120
    }
    $b1=SumB $S $threads
    $secs=$sw.Elapsed.TotalSeconds
    $S.Stop=$true
    foreach($j in $jobs){
        try{ [void]$j.H.AsyncWaitHandle.WaitOne(3000) }catch{}
        try{ $j.P.Stop() }catch{}
        try{ $j.P.Dispose() }catch{}
    }
    try{ $pool.Close(); $pool.Dispose() }catch{}
    $mb=0.0
    if($secs -gt 0){ $mb=(($b1-$b0)*8.0/$secs)/1000000.0 }
    return [pscustomobject]@{ Mbps=$mb; Lat=(Med $lat); N=$lat.Count }
}

function Grade($ms){
    if($ms -lt 5){ return 'A+' }
    if($ms -lt 30){ return 'A' }
    if($ms -lt 60){ return 'B' }
    if($ms -lt 200){ return 'C' }
    if($ms -lt 400){ return 'D' }
    return 'F'
}

Say 'Step 1 of 3 - Idle ping [about 3 seconds]...'
$idle=@()
for($i=0;$i -lt 12;$i++){
    $v=Ping1 $ph 1500
    if($v -ge 0){ $idle+=$v }
    Start-Sleep -Milliseconds 150
}
$haveping=($idle.Count -gt 0)
$idleMed=0.0
$jit=0.0
if($haveping){
    $idleMed=Med $idle
    $jit=Jit $idle
} else {
    Say '[WARN] No ping answer. ICMP may be blocked on this network.'
    Say '       Speed will be measured, the bufferbloat grade will be skipped.'
}

Say 'Step 2 of 3 - Download [about 9 seconds]...'
$dl=RunLoad $workerDown ($base + '/__down?bytes=25000000') 4
Say 'Step 3 of 3 - Upload [about 9 seconds]...'
$ul=RunLoad $workerUp ($base + '/__up') 3

if($dl.Mbps -lt 0.05 -and $ul.Mbps -lt 0.05){
    Write-Host ''
    Say '[FAIL] No data went through. A firewall, VPN or proxy may block the test.'
    exit 1
}

$dB=0.0
$uB=0.0
if($haveping -and $dl.N -gt 0){ $dB=[math]::Max(0.0,$dl.Lat-$idleMed) }
if($haveping -and $ul.N -gt 0){ $uB=[math]::Max(0.0,$ul.Lat-$idleMed) }
$worst=[math]::Max($dB,$uB)

Write-Host ''
Hr
Write-Host ''
if($haveping){
    Say ('Idle ping    : {0,8} ms      jitter {1} ms' -f (F1 $idleMed),(F1 $jit))
    Say ('Download     : {0,8} Mbps    ping under load {1} ms  [+{2} ms]' -f (F1 $dl.Mbps),(F1 $dl.Lat),(F1 $dB))
    Say ('Upload       : {0,8} Mbps    ping under load {1} ms  [+{2} ms]' -f (F1 $ul.Mbps),(F1 $ul.Lat),(F1 $uB))
} else {
    Say ('Download     : {0,8} Mbps' -f (F1 $dl.Mbps))
    Say ('Upload       : {0,8} Mbps' -f (F1 $ul.Mbps))
}
$grade='-'
if($haveping){
    $grade=Grade $worst
    Write-Host ''
    Say ('Bufferbloat  : grade ' + $grade)
    Write-Host ''
    switch($grade){
        'A+' { Say 'Excellent. Your ping stays low even when the line is busy.' }
        'A'  { Say 'Very good. Games and calls stay smooth when the line is busy.' }
        'B'  { Say 'Good. Small lag spikes can appear when someone downloads.' }
        'C'  { Say 'Noticeable lag when the line is busy. Smart Queue [SQM] on the router helps most.' }
        'D'  { Say 'Heavy lag when the line is busy. Smart Queue [SQM] on the router is the best fix.' }
        'F'  { Say 'Severe lag when the line is busy. Smart Queue [SQM] on the router is the best fix.' }
    }
    Say 'Bufferbloat = how much your ping grows while the line is full.'
}
Write-Host ''
Say 'On Wi-Fi the result includes your Wi-Fi. Test on a cable for the real line.'
try{
    $d=$env:BK
    if($d){
        if(-not (Test-Path $d)){ New-Item -ItemType Directory -Path $d -Force | Out-Null }
        $line=('{0:yyyy-MM-dd HH:mm}   down {1} Mbps   up {2} Mbps   idle {3} ms   bloat +{4} ms   grade {5}' -f (Get-Date),(F1 $dl.Mbps),(F1 $ul.Mbps),(F1 $idleMed),(F1 $worst),$grade)
        Add-Content -Path (Join-Path $d 'SpeedTests.txt') -Value $line
    }
}catch{}
exit 0
#END speed

#BEGIN speedhist
$f=Join-Path $env:BK 'SpeedTests.txt'
if(-not (Test-Path $f)){
    Say 'No results yet. Run the test first.'
    exit 0
}
Say 'Your last tests [newest at the bottom]:'
Write-Host ''
foreach($l in @(Get-Content -Path $f -Tail 10)){ Say $l }
Write-Host ''
Say 'Tip: run the test before and after a change to see if it helped.'
exit 0
#END speedhist

#BEGIN wifinow
$o=@(netsh wlan show interfaces 2>&1 | ForEach-Object { [string]$_ })
$ok=@($o | Where-Object { $_ -match '^\s+\S[^:]*:\s*\S' }).Count
if($ok -lt 3){
    Say 'No Wi-Fi information was found.'
    Say 'Reasons: no Wi-Fi adapter, Wi-Fi is off, or Windows 11 needs Location'
    Say 'services turned on to let programs read Wi-Fi details.'
    Write-Host ''
    foreach($l in $o){ if($l.Trim()){ Say $l.Trim() } }
    exit 2
}
$sig=-1
foreach($l in $o){
    if($l -match '^\s+[^:]+:\s*(\d{1,3})%\s*$'){ $sig=[int]$Matches[1]; break }
}
foreach($l in $o){ if($l.Trim()){ Say $l.TrimEnd() } }
Write-Host ''
if($sig -ge 0){
    $t='Poor. Move closer to the router.'
    if($sig -ge 80){ $t='Excellent.' } elseif($sig -ge 60){ $t='Good.' } elseif($sig -ge 40){ $t='Weak. Move closer to the router or use 5 GHz.' }
    Say ('Signal quality : ' + $sig + ' percent   ' + $t)
} else {
    Say 'You are not connected to a Wi-Fi network right now.'
}
exit 0
#END wifinow

#BEGIN wifiscan
Say 'Scanning nearby Wi-Fi networks, please wait...'
Write-Host ''
$o=@(netsh wlan show networks mode=bssid 2>&1 | ForEach-Object { [string]$_ })
$list=@()
$cur=$null
$ssid=''
foreach($l in $o){
    if($l -match '^SSID\s+\d+\s*:\s*(.*)$'){
        if($cur){ $list+=$cur; $cur=$null }
        $ssid=$Matches[1].Trim()
        if(-not $ssid){ $ssid='(hidden)' }
        continue
    }
    if($l -match '^\s+BSSID\s+\d+\s*:'){
        if($cur){ $list+=$cur }
        $cur=[pscustomobject]@{ S=$ssid; Sig=-1; Ch=0; Band='' }
        continue
    }
    if($cur -and ($l -match '^\s+[^:]+:\s*(.*)$')){
        $v=$Matches[1].Trim()
        if($cur.Sig -lt 0 -and $v -match '^(\d{1,3})%$'){ $cur.Sig=[int]$Matches[1]; continue }
        if(-not $cur.Band -and $v -match 'GHz'){ $cur.Band=$v; continue }
        if($cur.Sig -ge 0 -and $cur.Ch -eq 0 -and $v -match '^\d{1,3}$'){ $cur.Ch=[int]$v; continue }
    }
}
if($cur){ $list+=$cur }
$list=@($list | Where-Object { $_.Ch -gt 0 })
if($list.Count -eq 0){
    Say 'No networks were found.'
    Say 'Reasons: Wi-Fi is off, no Wi-Fi adapter, or Windows 11 needs Location'
    Say 'services turned on to let programs scan Wi-Fi.'
    exit 2
}
foreach($n in $list){
    if(-not $n.Band){ if($n.Ch -le 14){ $n.Band='2.4 GHz' } else { $n.Band='5 GHz' } }
}
Say ('{0,-28} {1,7} {2,8}   {3}' -f 'Network','Signal','Channel','Band')
Hr
foreach($n in ($list | Sort-Object Sig -Descending | Select-Object -First 20)){
    $nm=$n.S
    if($nm.Length -gt 27){ $nm=$nm.Substring(0,27) }
    Say ('{0,-28} {1,6}% {2,8}   {3}' -f $nm,$n.Sig,$n.Ch,$n.Band)
}
if($list.Count -gt 20){ Say ('... and ' + ($list.Count - 20) + ' more') }
Write-Host ''
Say 'Networks on each channel [more = more crowded]:'
Write-Host ''
$g=$list | Group-Object Ch | Sort-Object { [int]$_.Name }
foreach($x in $g){
    $bar='#' * [math]::Min(30,$x.Count)
    Say ('   Channel {0,3}   {1,-30} {2}' -f $x.Name,$bar,$x.Count)
}
$b24=@($list | Where-Object { $_.Ch -le 14 })
Write-Host ''
if($b24.Count -gt 0){
    $best=1
    $bs=9999
    foreach($c in 1,6,11){
        $sc=@($b24 | Where-Object { [math]::Abs($_.Ch - $c) -le 4 }).Count
        if($sc -lt $bs){ $bs=$sc; $best=$c }
    }
    Say ('Best 2.4 GHz channel for your router: ' + $best + '   [least crowded of 1, 6 and 11]')
    Say 'Change it in your router page. 5 GHz is faster and calmer if your devices support it.'
} else {
    Say 'No 2.4 GHz networks were seen. 5 GHz channels are usually less crowded.'
}
exit 0
#END wifiscan

#BEGIN wifipass
$dir=Join-Path $env:windir 'Temp\NSR_wifi'
$rows=@()
try{
    if(Test-Path $dir){ Remove-Item -Path $dir -Recurse -Force }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    & netsh wlan export profile key=clear folder=$dir 2>&1 | Out-Null
    foreach($f in @(Get-ChildItem -Path $dir -Filter '*.xml')){
        try{
            [xml]$x=Get-Content -LiteralPath $f.FullName -Raw
            $p=$x.WLANProfile
            $sec=$p.MSM.security
            $auth=[string]$sec.authEncryption.authentication
            $key=[string]$sec.sharedKey.keyMaterial
            $pw=$key
            if($auth -eq 'open'){ $pw='[open network - no password]' }
            elseif($sec.authEncryption.useOneX -eq 'true'){ $pw='[802.1X - no password stored]' }
            elseif(-not $key){ $pw='[not stored]' }
            $rows+=[pscustomobject]@{ N=[string]$p.name; A=$auth; P=$pw }
        }catch{}
    }
}catch{}
try{ Remove-Item -Path $dir -Recurse -Force }catch{}
if($rows.Count -eq 0){
    Say 'No saved Wi-Fi networks were found on this PC.'
    exit 0
}
Say ('{0,-30} {1,-12} {2}' -f 'Network','Security','Password')
Hr
foreach($r in ($rows | Sort-Object N)){
    $nm=$r.N
    if($nm.Length -gt 29){ $nm=$nm.Substring(0,29) }
    Say ('{0,-30} {1,-12} {2}' -f $nm,$r.A,$r.P)
}
Write-Host ''
Say ('Saved networks: ' + $rows.Count)
exit 0
#END wifipass

#BEGIN ping
$t=$env:NSR_TARGET
if($t -eq 'GATEWAY'){
    $t=Gw
    if(-not $t){
        Say '[FAIL] No router [gateway] was found. Are you connected?'
        exit 1
    }
}
$count=30
Say ('Target : ' + $t)
Say ('Sending ' + $count + ' pings, one every 200 ms...')
Write-Host ''
$ok=@()
$lost=0
$bad=$false
for($i=1;$i -le $count;$i++){
    try{
        $r=$global:NSRPing.Send($t,1500)
        if($r.Status -eq 'Success'){ $ok+=[double]$r.RoundtripTime } else { $lost++ }
    }catch{
        $lost++
        if($i -eq 1){ $bad=$true }
    }
    if($bad){ break }
    Start-Sleep -Milliseconds 200
}
if($bad){
    Say '[FAIL] Cannot find that host. Check the name or the address.'
    exit 1
}
$loss=[math]::Round(100.0*$lost/$count,1)
Hr
if($ok.Count -eq 0){
    Say ('Sent {0}   Received 0   Lost {1} [100 percent]' -f $count,$lost)
    Write-Host ''
    Say 'No answer at all. The host may block ping, or the connection is down.'
    exit 0
}
$m=$ok | Measure-Object -Minimum -Maximum -Average
$jit=Jit $ok
Say ('Sent {0}   Received {1}   Lost {2} [{3} percent]' -f $count,$ok.Count,$lost,(F1 $loss))
Say ('Ping   min {0} ms   avg {1} ms   max {2} ms' -f (F1 $m.Minimum),(F1 $m.Average),(F1 $m.Maximum))
Say ('Jitter {0} ms   [how much the ping jumps around]' -f (F1 $jit))
Write-Host ''
if($lost -eq 0 -and $jit -lt 15 -and $m.Average -lt 80){
    Say 'Excellent. Stable and fast. Good for games and calls.'
} elseif($lost -eq 0){
    Say 'No lost packets, but the ping is slow or jumpy.'
    Say 'Try again on a cable, or when nobody else uses the Internet.'
} elseif($loss -lt 5){
    Say 'A few packets were lost. Wi-Fi interference or a weak signal can do this.'
} else {
    Say 'Many packets were lost. Check the cable or the Wi-Fi signal, then restart the router.'
}
if($env:NSR_TARGET -eq 'GATEWAY' -and $lost -gt 0){
    Say 'The loss is between this PC and your router. The problem is inside your home.'
}
exit 0
#END ping

#BEGIN conns
$priv='^(10\.|127\.|192\.168\.|169\.254\.|172\.(1[6-9]|2\d|3[01])\.|0\.|::1|fe80|fc|fd)'
$c=@(Get-NetTCPConnection -State Established | Where-Object { $_.RemoteAddress -notmatch $priv })
if($c.Count -eq 0){
    Say 'No active Internet connections were found.'
    exit 0
}
$names=@{}
foreach($p in @(Get-Process)){ $names[[int]$p.Id]=[string]$p.ProcessName }
$rows=@($c | ForEach-Object {
    $nm=$names[[int]$_.OwningProcess]
    if(-not $nm){ $nm='(unknown)' }
    [pscustomobject]@{ App=$nm; R=([string]$_.RemoteAddress + ':' + [string]$_.RemotePort) }
} | Group-Object App | ForEach-Object {
    [pscustomobject]@{ App=$_.Name; Count=$_.Count; Example=($_.Group | Select-Object -First 1).R }
} | Sort-Object Count -Descending | Select-Object -First 15)
Say ('{0,-26} {1,12}   {2}' -f 'Program','Connections','Example remote address')
Hr
foreach($r in $rows){ Say ('{0,-26} {1,12}   {2}' -f $r.App,$r.Count,$r.Example) }
Write-Host ''
Say ('Total Internet connections: ' + $c.Count)
Say 'A program with many connections that you do not know is worth a look.'
exit 0
#END conns

#BEGIN port
$h=$env:NSR_HOST
$p=[int]$env:NSR_PORT
Say ('Checking ' + $h + ' port ' + $p + ' ...')
Write-Host ''
$c=New-Object Net.Sockets.TcpClient
$sw=[Diagnostics.Stopwatch]::StartNew()
try{
    $iar=$c.BeginConnect($h,$p,$null,$null)
    $done=$iar.AsyncWaitHandle.WaitOne(4000,$false)
    if($done){
        try{
            $c.EndConnect($iar)
            Say ('[ OPEN ]  The port answered in ' + [int]$sw.Elapsed.TotalMilliseconds + ' ms.')
        }catch{
            Say '[CLOSED]  The host answered, but nothing listens on that port.'
        }
    } else {
        Say '[NO ANSWER]  Timeout. The port is closed or a firewall blocks it.'
    }
}catch{
    Say '[FAIL]  Cannot find that host. Check the name or the address.'
}
try{ $c.Close() }catch{}
exit 0
#END port

#BEGIN mtu
$h='1.1.1.1'
$opt=New-Object System.Net.NetworkInformation.PingOptions(64,$true)
function Fits($size){
    try{
        $b=New-Object byte[] $size
        $r=$global:NSRPing.Send($h,1500,$b,$opt)
        return ($r.Status -eq 'Success')
    }catch{ return $false }
}
Say 'Testing the largest packet your line carries without splitting it...'
Write-Host ''
if(-not (Fits 100) -and -not (Fits 100)){
    Say '[FAIL] No answer from 1.1.1.1. Are you online? Ping may be blocked.'
    exit 1
}
if(Fits 1472){
    $best=1472
} else {
    $lo=100
    $hi=1472
    while(($hi-$lo) -gt 1){
        $mid=[int](($lo+$hi)/2)
        if(Fits $mid){ $lo=$mid } else { $hi=$mid }
    }
    $best=$lo
}
$mtu=$best+28
$cur=0
$ad=Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
if($ad){
    $ni=Get-NetIPInterface -InterfaceIndex $ad.ifIndex -AddressFamily IPv4
    if($ni){ $cur=[int]$ni.NlMtu }
}
Say ('Best MTU for your line : ' + $mtu)
if($cur -gt 0){ Say ('Windows uses now       : ' + $cur) }
Write-Host ''
if($cur -gt 0 -and $mtu -lt $cur){
    Say 'Your line carries smaller packets than Windows sends.'
    Say 'Lowering the MTU can fix slow pages and broken connections on some lines.'
    exit $mtu
}
Say 'Nothing to change. Windows already uses a good value.'
exit 0
#END mtu

#BEGIN mtuset
$m=[int]$env:NSR_MTU
$n=0
foreach($a in @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })){
    try{
        Set-NetIPInterface -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -NlMtuBytes $m -ErrorAction Stop
        Say ('[ OK ]  ' + $a.Name + '  MTU ' + $m)
        $n++
    }catch{
        Say ('[FAIL]  ' + $a.Name + '  ' + $_.Exception.Message)
    }
}
if($n -eq 0){ exit 1 }
exit 0
#END mtuset

#BEGIN proxy
$k='HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
$s=Get-ItemProperty -Path $k
$found=$false
Say 'Windows proxy for your user:'
if($s.ProxyEnable -eq 1){ Say ('   Manual proxy  : ON   ' + $s.ProxyServer); $found=$true } else { Say '   Manual proxy  : off' }
if($s.AutoConfigURL){ Say ('   Setup script  : ' + $s.AutoConfigURL); $found=$true } else { Say '   Setup script  : none' }
Write-Host ''
Say 'WinHTTP proxy [used by system services]:'
foreach($l in @(netsh winhttp show proxy 2>&1)){
    $t=([string]$l).Trim()
    if($t){ Say ('   ' + $t) }
}
Write-Host ''
Say 'VPN and virtual adapters:'
$v=@(Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'VPN|TAP-|WireGuard|Wintun|OpenVPN|Fortinet|Nord|Proton|Mullvad|AnyConnect|Hyper-V|VMware|VirtualBox|Virtual' })
if($v.Count -eq 0){
    Say '   none found'
} else {
    foreach($a in $v){ Say ('   ' + $a.Name + '   ' + $a.Status + '   ' + $a.InterfaceDescription) }
}
if($found){ exit 1 }
exit 0
#END proxy

#BEGIN hosts
$f=Join-Path $env:windir 'System32\drivers\etc\hosts'
$e=@(Get-Content -Path $f | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') })
Say ('File : ' + $f)
Write-Host ''
if($e.Count -eq 0){
    Say 'Active entries : none. The hosts file is clean.'
} else {
    Say ('Active entries : ' + $e.Count)
    Write-Host ''
    foreach($l in ($e | Select-Object -First 25)){ Say ('   ' + $l.Trim()) }
    if($e.Count -gt 25){ Say '   ...' }
    Write-Host ''
    Say 'Each line sends a name to the address in front of it.'
    Say 'If you do not know a line, it can be the reason a site is blocked.'
}
exit 0
#END hosts

#BEGIN hostsreset
$f=Join-Path $env:windir 'System32\drivers\etc\hosts'
$d=$env:BK
if(-not (Test-Path $d)){ New-Item -ItemType Directory -Path $d -Force | Out-Null }
$bk=Join-Path $d ('hosts_backup_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.txt')
$default=@'
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host
#
# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost
'@
try{
    Copy-Item -Path $f -Destination $bk -Force -ErrorAction Stop
    Set-Content -Path $f -Value $default -Encoding ASCII -ErrorAction Stop
    Say '[ OK ]  The hosts file is back to the Windows default.'
    Say ('        Backup of the old file: ' + $bk)
}catch{
    Say '[FAIL]  Could not change the hosts file.'
    Say '        Your security program may protect it.'
    exit 1
}
exit 0
#END hostsreset

#BEGIN report
$d=[Environment]::GetFolderPath('Desktop')
if(-not $d -or -not (Test-Path $d)){ $d=$env:USERPROFILE }
$f=Join-Path $d ('NSR_Report_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.txt')
$L=New-Object System.Collections.Generic.List[string]
function Add($t){ $L.Add([string]$t) }
function PStat($h,$n){
    $ok=@()
    $lost=0
    for($i=0;$i -lt $n;$i++){
        $v=Ping1 $h 1000
        if($v -ge 0){ $ok+=$v } else { $lost++ }
        Start-Sleep -Milliseconds 150
    }
    if($ok.Count -eq 0){ return ('{0,-18} sent {1}   lost {2}   no answer' -f $h,$n,$lost) }
    $m=$ok | Measure-Object -Minimum -Maximum -Average
    return ('{0,-18} sent {1}   lost {2}   min {3} ms   avg {4} ms   max {5} ms' -f $h,$n,$lost,(F1 $m.Minimum),(F1 $m.Average),(F1 $m.Maximum))
}
Say 'Collecting data, about 15 seconds...'
$os=Get-CimInstance Win32_OperatingSystem
Add ('NSR Network Report    ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') + '    NSR v' + $env:VER)
Add ('Windows : ' + $os.Caption + '  build ' + $os.BuildNumber)
Add ''
Add '== Adapters =='
Add ((Get-NetAdapter -Physical | Select-Object Name,InterfaceDescription,Status,LinkSpeed | Format-Table -AutoSize | Out-String).TrimEnd())
Add ''
Add '== IP configuration =='
Add ((Get-NetIPConfiguration | Out-String).TrimEnd())
Add ''
Add '== Ping tests [10 pings each] =='
$gw=Gw
if($gw){ Add (PStat $gw 10) }
Add (PStat '1.1.1.1' 10)
Add (PStat '8.8.8.8' 10)
Add (PStat 'google.com' 10)
Add ''
Add '== DNS lookup time =='
foreach($n in 'google.com','wikipedia.org','amazon.com'){
    $sw=[Diagnostics.Stopwatch]::StartNew()
    $r=$null
    try{ $r=Resolve-DnsName $n -Type A -DnsOnly -NoHostsFile -ErrorAction Stop }catch{}
    $res='FAILED'
    if($r){ $res=(F1 $sw.Elapsed.TotalMilliseconds) + ' ms' }
    Add ('{0,-18} {1}' -f $n,$res)
}
Add ''
Add '== Public connection =='
try{
    $w=Invoke-WebRequest 'https://www.cloudflare.com/cdn-cgi/trace' -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop
    $txt=$w.Content
    if($txt -is [byte[]]){ $txt=[Text.Encoding]::UTF8.GetString($txt) }
    foreach($l in ([string]$txt -split "`n")){
        if($l -like 'ip=*' -or $l -like 'loc=*' -or $l -like 'colo=*'){ Add $l.Trim() }
    }
}catch{ Add 'Could not reach cloudflare.com' }
Add ''
Add '== Proxy =='
$s=Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
if($s.ProxyEnable -eq 1){ Add ('Manual proxy ON: ' + $s.ProxyServer) } else { Add 'Manual proxy: off' }
if($s.AutoConfigURL){ Add ('Setup script: ' + $s.AutoConfigURL) }
$he=@(Get-Content -Path (Join-Path $env:windir 'System32\drivers\etc\hosts') | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') })
Add ('Active hosts file entries: ' + $he.Count)
$sf=Join-Path $env:BK 'SpeedTests.txt'
if(Test-Path $sf){
    Add ''
    Add '== Last speed tests =='
    foreach($l in @(Get-Content -Path $sf -Tail 5)){ Add $l }
}
$L | Out-File -FilePath $f -Encoding UTF8
Write-Host ''
Say '[ OK ]  Report saved:'
Say ('        ' + $f)
Write-Host ''
Say 'It holds your IP addresses and network name. Read it before you share it.'
exit 0
#END report
