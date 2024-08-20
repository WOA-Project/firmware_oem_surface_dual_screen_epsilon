@echo off

echo.
echo.  _______        __  _____      _                  _             
echo. ^|  ___\ \      / / ^| ____^|_  _^| ^|_ _ __ __ _  ___^| ^|_ ___  _ __ 
echo. ^| ^|_   \ \ /\ / /  ^|  _^| \ \/ / __^| '__/ _` ^|/ __^| __/ _ \^| '__^|
echo. ^|  _^|   \ V  V /   ^| ^|___ ^>  ^<^| ^|_^| ^| ^| ^(_^| ^| ^(__^| ^|^| ^(_^) ^| ^|   
echo. ^|_^|      \_/\_/    ^|_____/_/\_\\__^|_^|  \__,_^|\___^|\__\___/^|_^|   
echo.                                                                 

REM OEMB1 Root Key Hash
set RKH=34046EF5E08C14E01BE8883BFBE0E5C31A8E407B5B3B98C88F8A86C8D98C1235

echo.
echo Target: OEMB1
echo SoC   : SM8150
echo RKH   : %RKH% (Microsoft Andromeda Attestation PCA 2017) (From: 11/1/2017 To: 11/1/2032)
echo.

echo Checking MBN files validity... (This may take a while!)

for /f %%f in ('dir /b /s extracted\*.mbn') do (
    call :checkRKH %%f
)

echo Checking ELF files validity... (This may take a while!)

for /f %%f in ('dir /b /s extracted\*.elf') do (
    call :checkRKH %%f
)

echo Checking BIN files validity... (This may take a while!)

for /f %%f in ('dir /b /s extracted\*.bin') do (
    call :checkRKH %%f
)

echo Checking IMG files validity... (This may take a while!)

for /f %%f in ('dir /b /s extracted\*.img') do (
    call :checkRKH %%f
)

echo Cleaning up Output Directory...
rmdir /Q /S output

echo Cleaning up PIL Squasher Directory...
rmdir /Q /S pil-squasher

echo Cloning PIL Squasher...

git clone https://github.com/linux-msm/pil-squasher

echo Building PIL Squasher...

cd pil-squasher
bash.exe -c make
cd ..

mkdir output
mkdir output\Subsystems

mkdir output\Subsystems\ADSP
mkdir output\Subsystems\ADSP\ADSP

echo Converting Analog DSP Image...
bash.exe -c "./pil-squasher/pil-squasher ./output/Subsystems/ADSP/qcadsp8150.mbn ./extracted/modem/image/adsp.mdt"

echo Copying ADSP Protection Domain Registry Config files...
xcopy /qchky /-i extracted\modem\image\adspr.jsn output\Subsystems\ADSP\adspr.jsn
xcopy /qchky /-i extracted\modem\image\adspua.jsn output\Subsystems\ADSP\adspua.jsn

echo Copying ADSP lib files...
xcopy /qcheriky extracted\vendor\lib\rfsa\adsp output\Subsystems\ADSP\ADSP
xcopy /qcheriky extracted\dsp\adsp output\Subsystems\ADSP\ADSP

echo Generating ADSP FASTRPC INF Configuration...
tools\SuBExtInfUpdater-ADSP.exe output\Subsystems\ADSP\ADSP > output\Subsystems\ADSP\inf_configuration.txt

mkdir output\Subsystems\CDSP
mkdir output\Subsystems\CDSP\CDSP

echo Converting Compute DSP Image...
bash.exe -c "./pil-squasher/pil-squasher ./output/Subsystems/CDSP/qccdsp8150.mbn ./extracted/modem/image/cdsp.mdt"

echo Copying CDSP Protection Domain Registry Config files...
xcopy /qchky /-i extracted\modem\image\cdspr.jsn output\Subsystems\CDSP\cdspr.jsn

echo Copying CDSP lib files...
xcopy /qcheriky extracted\dsp\cdsp output\Subsystems\CDSP\CDSP

echo Generating CDSP FASTRPC INF Configuration...
tools\SuBExtInfUpdater-CDSP.exe output\Subsystems\CDSP\CDSP > output\Subsystems\CDSP\inf_configuration.txt

mkdir output\Subsystems\SLPI
mkdir output\Subsystems\SLPI\SDSP

echo Converting Sensor Low Power Interface DSP Image...
bash.exe -c "./pil-squasher/pil-squasher ./output/Subsystems/SLPI/qcslpi8150.mbn ./extracted/modem/image/slpi.mdt"

echo Copying SDSP Protection Domain Registry Config files...
xcopy /qchky /-i extracted\modem\image\slpir.jsn output\Subsystems\SLPI\slpir.jsn
xcopy /qchky /-i extracted\modem\image\slpius.jsn output\Subsystems\SLPI\slpius.jsn

echo Copying SDSP lib files...
xcopy /qcheriky extracted\dsp\sdsp output\Subsystems\SLPI\SDSP

echo Generating SDSP FASTRPC INF Configuration...
tools\SuBExtInfUpdater-SDSP.exe output\Subsystems\SLPI\SDSP > output\Subsystems\SLPI\inf_configuration.txt

mkdir output\Subsystems\ICP

xcopy /qchky /-i extracted\vendor\firmware\CAMERA_ICP.elf output\Subsystems\ICP\CAMERA_ICP_AAAAAA.elf

mkdir output\Subsystems\IPA

xcopy /qchky /-i extracted\vendor\firmware\ipa_fws.elf output\Subsystems\IPA\ipa_fws.elf
xcopy /qchky /-i extracted\vendor\firmware\ipa_uc.elf output\Subsystems\IPA\ipa_uc.elf

mkdir output\Subsystems\MCFG
mkdir output\Subsystems\MCFG\MCFG

echo Generating MCFG TFTP INF Configuration...
tools\SuBExtInfUpdater-MCFG.exe extracted\modem\image\modem_pr output\Subsystems\MCFG\MCFG > output\Subsystems\MCFG\inf_configuration.txt

xcopy /qchky /-i extracted\modem\image\qdsp6m.qdb output\Subsystems\MCFG\qdsp6m.qdb

mkdir output\Subsystems\MPSS

echo Copying MPSS Protection Domain Registry Config files...
xcopy /qchky /-i extracted\modem\image\modemr.jsn output\Subsystems\MPSS\modemr.jsn
xcopy /qchky /-i extracted\modem\image\modemuw.jsn output\Subsystems\MPSS\modemuw.jsn

echo Converting Modem Processor Subsystem DSP Image...
bash.exe -c "./pil-squasher/pil-squasher ./output/Subsystems/MPSS/qcmpss8150.mbn ./extracted/modem/image/modem.mdt"

mkdir output\Subsystems\SPSS

xcopy /qchky /-i extracted\modem\image\spss1p.mbn output\Subsystems\SPSS\spss8150v1p.mbn
xcopy /qchky /-i extracted\modem\image\spss2p.mbn output\Subsystems\SPSS\spss8150v2p.mbn

xcopy /qchky /-i extracted\modem\image\asym1p.sig output\Subsystems\SPSS\asymw1p.sig
xcopy /qchky /-i extracted\modem\image\crypt1p.sig output\Subsystems\SPSS\cryptw1p.sig
xcopy /qchky /-i extracted\modem\image\keym1p.sig output\Subsystems\SPSS\keymw1p.sig

xcopy /qchky /-i extracted\modem\image\asym2p.sig output\Subsystems\SPSS\asymw2p.sig
xcopy /qchky /-i extracted\modem\image\crypt2p.sig output\Subsystems\SPSS\cryptw2p.sig
xcopy /qchky /-i extracted\modem\image\keym2p.sig output\Subsystems\SPSS\keymw2p.sig

mkdir output\Subsystems\VENUS

echo Converting Video Encoding Subsystem DSP Image...
bash.exe -c "./pil-squasher/pil-squasher ./output/Subsystems/VENUS/qcvss8150.mbn ./extracted/modem/image/venus.mdt"

mkdir output\Subsystems\ZAP

xcopy /qchky /-i extracted\vendor\firmware\a640_zap.elf output\Subsystems\ZAP\qcdxkmsuc8150.mbn

mkdir output\Subsystems\WCNSS

xcopy /qchky /-i extracted\modem\image\wlanmdsp.mbn output\Subsystems\WCNSS\WLANMDSP.mbn
xcopy /qchky /-i extracted\modem\image\bdwlan.bin output\Subsystems\WCNSS\bdwlan.bin
xcopy /qchky /-i extracted\modem\image\data.msc output\Subsystems\WCNSS\Data.msc

mkdir output\Subsystems\WDSP

echo Converting Wave DSP Image...
bash.exe -c "./pil-squasher/pil-squasher ./output/Subsystems/WDSP/qcwdsp8150.mbn ./extracted/modem/image/cpe_9340.mdt"

mkdir output\Camera

mkdir output\Camera\Front

xcopy /qchky /-i extracted\vendor\lib64\camera\com.qti.sensormodule.sony_front_imx351.bin output\Camera\Front\com.qti.sensormodule.sony_front_imx351.bin
xcopy /qchky /-i extracted\vendor\lib64\camera\com.qti.tuned.sony_front_imx351.bin output\Camera\Front\com.qti.tuned.sony_front_imx351.bin

mkdir output\Camera\Rear

xcopy /qchky /-i extracted\vendor\lib64\camera\com.qti.sensormodule.sony_imx351.bin output\Camera\Rear\com.qti.sensormodule.sony_imx351.bin
xcopy /qchky /-i extracted\vendor\lib64\camera\com.qti.tuned.sony_imx351.bin output\Camera\Rear\com.qti.tuned.sony_imx351.bin

mkdir output\Touch
mkdir output\Touch\Config

echo Extracting N-Trig Digitizer Project Configuration Databases...
tools\PSCFGDataReader.exe output\Touch\Config extracted\vendor\lib64\libsurfacetouch.so

mkdir output\Touch\FW

xcopy /qchky /-i extracted\sftpfw.img output\Touch\FW\SurfaceTouchFw_4.0.306.139.bin

mkdir output\BT

echo Copying Blueooth Firmware Files...
xcopy /qcheriky extracted\bluetooth\image output\BT

mkdir output\Sensors
mkdir output\Sensors\Config

xcopy /qchky /-i extracted\vendor\etc\sensors\sns_reg_config output\Sensors\Config\sns_reg_config
xcopy /qcheriky extracted\vendor\etc\sensors\config output\Sensors\Config

echo Generating SLPI FASTRPC INF Configuration...
tools\SuBExtInfUpdater-SLPI.exe output\Sensors\Config > output\Sensors\inf_configuration.txt
move output\Sensors\inf_configuration.txt output\Sensors\Config\inf_configuration.txt

mkdir output\Sensors\Proto

xcopy /qcheriky extracted\vendor\etc\sensors\proto output\Sensors\Proto

mkdir output\Audio
mkdir output\Audio\Cal

xcopy /qchky /-i extracted\vendor\etc\acdbdata\adsp_avs_config.acdb output\Audio\Cal\adsp_avs_config.acdb
xcopy /qcheriky extracted\vendor\etc\acdbdata\Surface\region\a output\Audio\Cal
xcopy /qcheriky extracted\vendor\etc\acdbdata\Surface\region\b output\Audio\Cal

mkdir output\Regulatory

REM TODO: Remember where this is stored again

mkdir output\TrEE

echo Copying rtic (n=rtic;p=8:c47728cf3e4289,60:30080400a3001,b4;s=46;u=6238333e1eb7ea11b3de0242ac130004) QSEE Applet...
xcopy /qchky /-i extracted\modem\image\rtic.mbn output\TrEE\rtic.mbn

echo Converting voiceprint (n=voiceprint;p=b:9ea409f7c90031,82:6) QSEE Applet...
bash.exe -c "./pil-squasher/pil-squasher ./output/TrEE/voicepri.mbn ./extracted/modem/image/voicepri.mdt"
echo Converting hdcpsrm (n=hdcpsrm;p=8:c47728cf3e4089,5d:8,82:6004,b4;s=5e) QSEE Applet...
bash.exe -c "./pil-squasher/pil-squasher ./output/TrEE/hdcpsrm.mbn ./extracted/modem/image/hdcpsrm.mdt"
echo Converting qcom.tz.hdcp2p2 (n=qcom.tz.hdcp2p2;p=8:c47728cf3e408911,5a:94,82:6004,b4;s=43,56) QSEE Applet...
bash.exe -c "./pil-squasher/pil-squasher ./output/TrEE/hdcp2p2.mbn ./extracted/modem/image/hdcp2p2.mdt"
echo Converting hdcp1 (n=hdcp1;p=8:c477a8cf3e40893,61,82:6004,b4;s=55) QSEE Applet...
bash.exe -c "./pil-squasher/pil-squasher ./output/TrEE/hdcp1.mbn ./extracted/modem/image/hdcp1.mdt"
echo Converting fingerprint (m=x;n=fingerprint;p=b:9fa409f7e90031,82:6) QSEE Applet...
bash.exe -c "./pil-squasher/pil-squasher ./output/TrEE/fpctzrel.mbn ./extracted/modem/image/fpctzrel.mdt"
echo Converting cppf (n=cppf;p=b:9ea409f7c90031,5a,82:6) QSEE Applet...
bash.exe -c "./pil-squasher/pil-squasher ./output/TrEE/cppf.mbn ./extracted/vendor/firmware/cppf.mdt"


REM START: Do we need those? They should already be loaded in UEFI.

REM TODO: Trim
echo Copying qcom.tz.uefisecapp (n=qcom.tz.uefisecapp;p=b:9ea409f7c90031,82:6) QSEE Applet...
xcopy /qchky /-i extracted\uefisecapp.img output\TrEE\uefisecapp.mbn

REM TODO: Trim
echo keymaster64 (n=keymaster64;p=8:c47728cf3e4489,61,82:6024,b4;s=96) QSEE Applet...
xcopy /qchky /-i extracted\keymaster.img output\TrEE\keymaster.mbn

echo Converting widevine (C=true;n=widevine;p=8:c47728cf3e4089,5a:24,82:68048,b4,32b,4b1,dac;s=dac) QSEE Applet...
bash.exe -c "./pil-squasher/pil-squasher ./output/TrEE/widevine.mbn ./extracted/vendor/firmware/widevine.mdt"

REM END: Do we need those? They should already be loaded in UEFI.


mkdir output\UEFI

echo Extracting XBL Image...
tools\UEFIReader.exe extracted\XBL.img output\UEFI

mkdir output\UEFI\ABL

echo Extracting ABL Image...
tools\UEFIReader.exe extracted\abl.img output\UEFI\ABL

echo Cleaning up PIL Squasher Directory...
rmdir /Q /S pil-squasher

REM TODO: Get list of supported PM resources from AOP directly
REM TODO: Extract QUP FW individual files
REM TODO: devcfg parser?

:eof
exit /b 0

:checkRKH
set x=INVALID
for /F "eol=; tokens=1-2 delims=" %%a in ('tools\RKHReader.exe %1 2^>^&1') do (set x=%%a)

echo.
echo File: %1
echo RKH : %x%
echo.
set directory=%~dp1
call set directory=%%directory:%cd%=%%

if %x%==%RKH% (
    exit /b 1
)

if %x%==FAIL! (
    exit /b 2
)

if %x%==EXCEPTION! (
    exit /b 2
)

echo %1 is a valid MBN file and is not production signed (%x%). Moving...
mkdir unsigned\%directory%
move %1 unsigned\%directory%
exit /b 0