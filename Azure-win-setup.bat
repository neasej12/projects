@echo off
if not "%1" == "max" start /MAX cmd /c %0 max & exit/b

goto check_Permissions

:check_Permissions
    echo Administrative permissions required. Detecting permissions...	
    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Success: Administrative permissions confirmed.
		
		GOTO :PRE_MAIN
    ) else (
        echo Failed: Run as Administrator Right click - Run as Administrator
		pause
		exit
    )

pause

:PRE_MAIN


echo #########################################################
echo #::: To be installed:
echo #########################################################
echo - Chocolatey
echo - Chrome
echo - Notepad++
echo - WinRAR
echo - firefox
echo - 7Zip
echo - Vim
echo - iTunes
echo - slack
echo - connectwise
echo - Putty
echo - Zoom
echo - Webroot
echo - Installs office365business
echo - Enabled Bitlocker
echo - Domainjoin
echo #########################################################

:MAIN

cd "%~dp0" 
%~d0%

SET has_chocolatey=0

IF EXIST "%ProgramFiles(x86)%\chocolatey" (
	SET has_chocolatey=1
	REM echo Chocolatey Exists... 32-Bit
)
IF EXIST "%ProgramFiles%\chocolatey" (
	SET has_chocolatey=1
	REM echo Chocolatey Exists... 64-Bit
)
IF %has_chocolatey% == 0 (
	echo Installing chocolatey...
	
	@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
)

SET has_winrar=0

IF EXIST "%ProgramFiles(x86)%\WinRAR" (
	SET has_winrar=1
	REM echo WinRAR Exists... 32-Bit
)
IF EXIST "%ProgramFiles%\WinRAR" (
	SET has_winrar=1
	REM echo WinRAR Exists... 64-Bit
)
IF %has_winrar% == 0 (
	echo Installing WinRAR...
	
	choco install winrar -y
)

SET has_7zip=0

IF EXIST "%ProgramFiles(x86)%\7zip" (
	SET has_7zip=1
	REM echo 7zip Exists... 32-Bit
)
IF EXIST "%ProgramFiles%\7zip" (
	SET has_7zip=1
	REM echo 7zip Exists... 64-Bit
)
IF %has_7zip% == 0 (
	echo Installing 7zip...
	
	choco install 7zip -y
)

SET has_chrome=0

IF EXIST "%ProgramFiles(x86)%\chrome" (
	SET has_chrome=1
	REM echo chrome Exists... 32-Bit
)
IF EXIST "%ProgramFiles%\chrome" (
	SET has_chrome=1
	REM echo chrome Exists... 64-Bit
)
IF %has_chrome% == 0 (
	echo Installing chrome...
	
	choco install googlechrome -y
	
)

SET has_notepadplusplus=0

IF EXIST "%ProgramFiles(x86)%\notepadplusplus" (
	SET has_notepadplusplus=1
	REM echo notepadplusplus Exists... 32-Bit
)
IF EXIST "%ProgramFiles%\notepadplusplus" (
	SET has_notepadplusplus=1
	REM echo notepadplusplus Exists... 64-Bit
)
IF %has_notepadplusplus% == 0 (
	echo Installing notepadplusplus...
	
	choco install notepadplusplus -y
)

SET has_firefox=0

IF EXIST "%ProgramFiles(x86)%\firefox" (
	SET has_firefox=1
	REM echo firefox Exists... 32-Bit
)
IF EXIST "%ProgramFiles%\firefox" (
	SET has_firefox=1
	REM echo firefox Exists... 64-Bit
)
IF %has_firefox% == 0 (
	echo Installing firefox...
	
	choco install firefox -y 
)

SET has_gitforwindows=0

IF EXIST "%ProgramFiles(x86)%\gitforwindows" (
	SET has_gitforwindows=1
	REM echo gitforwindows Exists... 32-Bit
)
IF EXIST "%ProgramFiles%\gitforwindows" (
	SET has_gitforwindows=1
	REM echo gitforwindows Exists... 64-Bit
)
IF %has_gitforwindows% == 0 (
	echo Installing gitforwindows...
	
	choco install git.install -y
)

SET has_office365business=0

IF EXIST "%ProgramFiles(x86)%\office365business" (
	SET has_office365business=1
	REM echo office365business Exists... 32-Bit
)
IF EXIST "%ProgramFiles%\office365business" (
	SET has_office365business=1
	REM echo office365business Exists... 64-Bit
)
IF %has_office365business% == 0 (
	echo Installing office365business...
	
	  choco install office365business
)

SET has_vcredist2017=0

IF EXIST "%ProgramFiles%\vcredist2017" (
	SET has_vcredist2017=1
	REM echo CPP RUNTIME Exists... 64-Bit
)
IF %has_vcredist2017% == 0 (
	echo Installing CPP Runtimes...
	
	  choco install vcredist2017 -y
	  
	  choco install vcredist2010 -y
)

SET has_slack=0

IF EXIST "%ProgramFiles%\slack" (
	SET has_slack=1
	REM echo slack Exists... 64-Bit
)
IF %has_slack% == 0 (
	echo Installing slack...
	
     choco install slack -y
)

SET has_putty=0

IF EXIST "%ProgramFiles%\putty" (
	SET has_putty=1
	REM echo putty Exists... 64-Bit
)
IF %has_putty% == 0 (
	echo Installing putty...
	
     choco install putty -y
)

SET has_connectwise=0

IF EXIST "%ProgramFiles%\connectwise" (
	SET has_connectwise=1
	REM echo connectwise Exists... 64-Bit
)
IF %has_connectwise% == 0 (
	echo Installing connectwise...
	
     choco install connectwise -y
)

SET has_zoom=0

IF EXIST "%ProgramFiles%\zoom" (
	SET has_zoom=1
	REM echo zoom Exists... 64-Bit
)
IF %has_zoom% == 0 (
	echo Installing zoom...
	
     choco install zoom -y
     choco install zoom-outlook -y
)

SET has_itunes=0

IF EXIST "%ProgramFiles%\itunes" (
	SET has_itunes=1
	REM echo itunes Exists... 64-Bit
)
IF %has_itunes% == 0 (
	echo Installing itunes...
	
     choco install itunes -y
     
)



REM Administrative tasks

	  ECHO Turning firewall OFF...
	  REM Turns all firewalls off
	  netsh advfirewall set  allprofiles state off
	  	   
	
	  
	  ECHO Installing Webroot Agent...
	  REM installs antivirus agents
	  mkdir C:\temp2
	  powershell Invoke-WebRequest -Uri 'https://anywhere.webrootcloudav.com/zerol/wsainstall.exe' -OutFile 'c:\temp2\wsainstall.exe'
	  cd C:\temp2
	  .\wsainstall.exe /key=KEY1 /silent /S /TargetPath="C:\Program Files\webroot" /TempPath="C:\ProgramData\webroot"
      rmdir /Q /S "C:\temp2"	  
	  
	  @Echo Off
	  
	  
	  ECHO Enabling bitlocker
	  REM Turns on bitlocker and generates key
	  manage-bde -on C: -RecoveryKey D: -RecoveryPassword
	  manage-bde -status
	 
	 ECHO domain join
	 Join PC to Azure AD
	 mkdir C:\packages
	 cd C:\packages 
	 
     powershell Invoke-WebRequest -Uri 'https://anywhere/windows10join.7z' -OutFile 'c:\packages\windows10join.7z'
     powershell Invoke-WebRequest -Uri 'https://anywhere/unzip.ps1' -OutFile 'c:\packages\unzip.ps1' 	 
     powershell Add-ProvisioningPackage -Path "C:\packages\windows10join.ppkg" -ForceInstall
	 
	 REM rmdir /Q /S "C:\packages"




		 		  
		  
		  shutdown.exe /r /t 300
	 

pause

GOTO :EXIT

	
	GOTO :MAIN
	
:EXIT
	exit
