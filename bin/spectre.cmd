@echo off
setlocal

if "%FAN_HOME%"=="" (
	echo Set %FAN_HOME% env variable to run Spectre
	exit /b 1
) 


rem =============================
rem  Finding Spectre install dir
rem =============================

set current_directory=%cd%
cd /D %~dp0
cd ..
set FAN_ENV=util::PathEnv
set FAN_ENV_PATH=%cd%


rem ================
rem  Returning back
rem ================

cd %current_directory%


rem ==================
rem  Starting Spectre
rem ==================

if "%1" == "startapp" (
	java -Xmx512M -cp %FAN_HOME%/lib/java/sys.jar -Dfan.home=%FAN_HOME% fanx.tools.Fan spectre::StartApp %2 %3 %4 %5 %6 %7 %8 %9
	goto end
)

if "%1" == "runserver" (
	java -Xmx512M -cp %FAN_HOME%/lib/java/sys.jar -Dfan.home=%FAN_HOME% fanx.tools.Fan spectre::RunServer %2 %3 %4 %5 %6 %7 %8 %9
	goto end
)

if "%1" == "rundevserver" (
	java -Xmx512M -cp %FAN_HOME%/lib/java/sys.jar -Dfan.home=%FAN_HOME% fanx.tools.Fan spectre::RunDevServer %2 %3 %4 %5 %6 %7 %8 %9
	goto end
)

echo Unknown command "%1", use "spectre (startapp|rundevserver|runserver) <arg>"
exit /b 1

:end