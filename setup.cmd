@echo OFF

:: THIS FIRST LINES IS TO AUTO ELEVATE TO ADMIN

:: BatchGotAdmin
:-------------------------------------
::  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

:: AUTO ELEVATION ENDS HERE.


:: Print Logo

:::
::: $g,_                               w$	
::: $$$$&w,      _, _   _ ,_    __,,g$$$$
::: _&$$$$$$$&,  _"*$r ,$P" __,g$$$$$$$$_			__          __             _____           _       _   		
:::  _'*&$&$$$$$,   _*_"_   ,$$$$$$&&P"_ 			\ \        / /            / ____|         (_)     | |     
:::         _"&$&r  j$$$E  _$&&*  _      			 \ \  /\  / __ _ ___ _ __| (___   ___ _ __ _ _ __ | |_ ___ 
:::             1$ $g'*"g& $&_           			  \ \/  \/ / _` / __| '_ \\___ \ / __| '__| | '_ \| __/ __|
:::              ] _&$$$$' L             			   \  /\  | (_| \__ | |_) ____) | (__| |  | | |_) | |_\__ \
:::         _,g&&&rg&,",gg &$$&w,        			    \/  \/ \__,_|___| .__|_____/ \___|_|  |_| .__/ \__|___/
:::       ,$$$$$F__$$$$$$$ _"$$$$$g      					            | |                     | | 
:::      g$$$$$F   "&$$$&"   _$$$$$&						    |_|                     |_| 
:::    _$$$$$&F    _,g*,,      $$$$$$r   
:::     _"*&*_      "$&$"      _"**"__   
:::                   $      


for /f "delims=: tokens=*" %%A in ('findstr /b ::: "%~f0"') do @echo(%%A

echo.
echo.
echo.
echo.

:: Set %SimbaPath% and %DesktopPath% for easy access.
set SimbaPath=%LocalAppData%\Simba
set DesktopPath=%USERPROFILE%\Desktop

:: Check if %SimbaPath% Exists and go to the respective label.
if exist %SimbaPath% goto :DIR_EXISTS 
goto :MAKE_DIRECTORY_TREE

:: If %SimbaPath% exists we are going to delete it.
:DIR_EXISTS
	echo An old Simba directory exists, it will be deleted.
	rmdir /S /Q %SimbaPath%
	
:: MAKE_DIRECTORY_TREE label will run wether DIR_EXISTS ran before or not.
:: Here we will build the directory tree.
:: Simba usually creates this when you open it but we need this directories to exist to download files to them.
:MAKE_DIRECTORY_TREE
	md %SimbaPath%
	md %SimbaPath%\Data
	md %SimbaPath%\Data\packages
	md %SimbaPath%\Includes
	md %SimbaPath%\Scripts

:: Download Simba to %SimbaPath%.
echo Downloading Simba
curl -L https://github.com/Villavu/Simba/releases/download/simba1400-release/Simba-Win32.exe > %SimbaPath%\Simba.exe

:: Check the Desktop for existing shortcuts to older Simba installs and delete them.
if exist %DesktopPath%\Simba (
	del /Q %DesktopPath%\Simba
)
if exist %DesktopPath%\SimbaFiles (
	rmdir /Q %DesktopPath%\SimbaFiles
)

:: Create Simba and SimbaFiles shortcuts on user's Desktop.
mklink %DesktopPath%\Simba %SimbaPath%\Simba.exe
mklink /d %DesktopPath%\SimbaFiles %SimbaPath%

:: Prompt the user which flavour of SRL he/she wants to install.
:: The unnoficial is the default which will be selected after 5 seconds without input.
echo.
echo.
echo.
choice /C YN /D Y /T 5 /M "Do you want to install the unofficial SRL?"
if %ERRORLEVEL% equ 1 goto :UNOFFICIAL_SRL
if %ERRORLEVEL% equ 2 goto :OFFICIAL_SRL

:: Set %SRLLink% and add the entry to packages.ini with unnoficial SRL.
:UNOFFICIAL_SRL
	echo Unoffical SRL is going to be installed.
	set SRLLink=https://github.com/Torwent/SRL/archive/refs/heads/master.zip
	echo [Torwent/SRL]>>%SimbaPath%\Data\packages\packages.ini
goto :INSTALL_SRL

:: Set %SRLLink% and add the entry to packages.ini with official SRL.
:OFFICIAL_SRL
	echo Official SRL is going to be installed.
	set SRLLink=https://github.com/Villavu/SRL-Development/archive/refs/heads/master.zip
	echo [ollydev/SRL-Development]>>%SimbaPath%\Data\packages\packages.ini
	
:: Wether we ran UNOFFICIAL_SRL or OFFICIAL_SRL we run INSTALL_SRL next.
:: This will finish writting the SRL entry to the packages.ini file,
:: download %SRLLink%, unzip it and move the contents to the includes directory.
:INSTALL_SRL
	echo Installing SRL...
	echo.
	echo.
	echo.
	echo Name=SRL>>%SimbaPath%\Data\packages\packages.ini
	curl -L %SRLLink% > srl.zip
	tar -xf srl.zip
	del srl.zip
	move SRL* %SimbaPath%\Includes\SRL

:: This will "install" WaspLib by writting the entry to the packages.ini file,
:: download it, unzip it and move the contents to the includes directory.	
:INSTALL_WL
	echo Installing WaspLib...
	echo.
	echo.
	echo.
	curl -L https://github.com/Torwent/WaspLib/archive/refs/heads/master.zip > wl.zip
	tar -xf wl.zip
	del wl.zip
	move WaspLib-master %SimbaPath%\Includes\WaspLib
	echo [Torwent/WaspLib]>>%SimbaPath%\Data\packages\packages.ini
	echo Name=WaspLib>>%SimbaPath%\Data\packages\packages.ini

:: At this point we are done but we prompt the user for optionally install wasp-free.
:: The default is to install them if there was no input in 5 seconds.
choice /C YN /D Y /T 5 /M "Do you want to install the free scripts?"
if %ERRORLEVEL% equ 1 goto :INSTALL_FREE_SCRIPTS
if %ERRORLEVEL% equ 2 goto :NEXT_CHOICE

:: We run this if the user chose to install wasp-free.
:: This does the same as the previous installs, make the entry in packages.ini,
:: download it, unzip it and move the contents to the Scripts directory.	
:INSTALL_FREE_SCRIPTS
	echo Installing Wasp Free Scripts...
	echo.
	echo.
	echo.
	curl -L https://github.com/Torwent/wasp-free/archive/refs/heads/master.zip > fwb.zip
	tar -xf fwb.zip
	del fwb.zip
	move wasp-free-master %SimbaPath%\Scripts\wasp-free
	echo [Torwent/wasp-free]>>%SimbaPath%\Data\packages\packages.ini
	echo Name=wasp-free>>%SimbaPath%\Data\packages\packages.ini
	md %SimbaPath%\Scripts\wasp-premium
	
:: Regardless of we running INSTALL_FREE_SCRIPTS or not, this runs next.
:: It will prompt the user if he/she wants to install wasp-mini as well. By default it will not and the script ends.
:NEXT_CHOICE
	choice /C YN /D N /T 5 /M "Do you want to install the mini scripts? This scripts are not maintaned, may have bugs and can get you banned."
	if %ERRORLEVEL% equ 1 goto :INSTALL_MINI_SCRIPTS
	if %ERRORLEVEL% equ 2 goto :EOF

:: If the user chose to install wasp-mini we run this.
:: This does the same as the previous installs, make the entry in packages.ini,
:: download it, unzip it and move the contents to the Scripts directory.		
:INSTALL_MINI_SCRIPTS
	echo Installing Wasp Mini Scripts...
	echo.
	echo.
	echo.
	curl -L https://github.com/Torwent/wasp-mini/archive/refs/heads/master.zip > mwb.zip
	tar -xf mwb.zip
	del mwb.zip
	move wasp-mini-master %SimbaPath%\Scripts\wasp-mini
	echo [Torwent/wasp-mini]>>%SimbaPath%\Data\packages\packages.ini
	echo Name=wasp-mini>>%SimbaPath%\Data\packages\packages.ini
