@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Photo Collector - Shamlan
color 0F

set "destination=C:\Users\%USERNAME%\OneDrive\Pictures"
set "file_count=0"
set "duplicate_count=0"
set "error_count=0"
set "total_size=0"
set "scan_count=0"
set "supported_extensions=JPEG JPG PNG GIF BMP TIFF TIF WebP SVG ICO HEIC HEIF AVIF MP4 AVI MOV MPEG MPG WMV WebM PDF TTF 3GP 3G2 8BPS AAI AI ANI ANIM APNG ART ARW AVS BAYER BGR BPM CALS CAP CIN CMT CR2 CR3 CRW CUR CUT DDS DIB DICOM DJVU DNG DPX DRF EMF EPID EPS ERF EXR FAX FITS FLV FPX GPLT GRAY HDR HRZ ICON IFF ILBM IMG INDD IPL JBG JBIG JNG JP2 JPC JPE JPX K25 KDC M4V MAT MEF MIFF MNG MOD MRW MSL MTV MVG NEF NRW OGV ORF OTB P7 PAL PAM PBM PCD PCDS PCL PCT PCX PDB PEF PES PFA PFB PFM PGM PICON PICT PIX PJPEG PLASMA PNG8 PNG24 PNG32 PNM PPM PS PSB PSD PTX PWP QTI QTIF RAF RAS RGB RGBA RGF RLA RLE RMF RW2 RWL SCT SFW SGI SHTML SIX SIXEL SMS SR2 SRF SRW SUN SVGZ TGA TIM TOD UBRL UIL UYVY VDA VICAR VID VIFF VOB VST WBMP WMF WPG X3F XBM XCF XWD YCbCr YUV"
set "excluded_folders=Windows Program Files ProgramData System Volume Information Recycler Recycled \$Recycle.Bin AppData temp tmp cache"
set "log_file=%temp%\photo_collector_errors.log"

:MainMenu
cls
echo.
echo ┌──────────────────────────────────────────────────────────────────────────┐
echo │███╗   ███╗ █████╗ ██╗███╗   ██╗    ███╗   ███╗███████╗███╗   ██╗██╗   ██╗│
echo │████╗ ████║██╔══██╗██║████╗  ██║    ████╗ ████║██╔════╝████╗  ██║██║   ██║│
echo │██╔████╔██║███████║██║██╔██╗ ██║    ██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║│
echo │██║╚██╔╝██║██╔══██║██║██║╚██╗██║    ██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║│
echo │██║ ╚═╝ ██║██║  ██║██║██║ ╚████║    ██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝│
echo │╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝    ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ │
echo └──────────────────────────────────────────────────────────────────────────┘
echo ┌──────────────────────────────────────────────────────────────────────────┐
echo │1. Collect ALL photos/videos from ALL accessible drives (TURBO MODE)      │
echo │2. Collect photos from Pictures folder only                               │
echo │3. Collect videos from Videos folder only                                 │
echo │4. Collect photos by file size filter                                     │
echo │5. Change destination folder                                              │
echo │6. View collection statistics                                             │
echo │7. View error log                                                         │
echo │8. Exit                                                                   │
echo └──────────────────────────────────────────────────────────────────────────┘
echo Current destination: %destination%
echo.
set /p "choice=Enter your choice [1-7]: "

if "%choice%"=="1" goto CollectAllPhotos
if "%choice%"=="2" goto CollectPicturesOnly
if "%choice%"=="3" goto CollectVideosOnly
if "%choice%"=="4" goto CollectBySize
if "%choice%"=="5" goto ChangeDestination
if "%choice%"=="6" goto ShowStats
if "%choice%"=="7" goto ShowErrorLog
if "%choice%"=="8" exit
echo Invalid choice. Press any key to try again...
pause >nul
goto MainMenu

:ShowErrorLog
cls
echo.
echo ┌─── ERROR LOG ───┐
if exist "%log_file%" (
    type "%log_file%"
    echo.
    set /p "clear_log=Clear error log? [Y/N]: "
    if /i "!clear_log!"=="Y" del "%log_file%" 2>nul
) else (
    echo No errors logged yet.
)
echo.
pause
goto MainMenu

:ShowStats
cls
echo.
echo ┌─── COLLECTION STATISTICS ───┐
if exist "%destination%" (
    call :PowerShellStats
) else (
    echo No collection found.
)
echo.
pause
goto MainMenu

:PowerShellStats
powershell -Command "& {$files = Get-ChildItem -Path '%destination%' -Recurse -File -ErrorAction SilentlyContinue; $count = $files.Count; $size = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2); Write-Host 'Files in collection:' $count; Write-Host 'Total size:' $size 'MB'; $ext = $files | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 5; Write-Host 'Top file types:'; $ext | ForEach-Object {Write-Host '  ' $_.Name ':' $_.Count 'files'}}" 2>nul
exit /b

:ChangeDestination
echo.
echo Current destination: %destination%
set /p "new_destination=Enter new destination path: "
if not defined new_destination goto ChangeDestination
set "destination=%new_destination%"
echo Destination changed to: %destination%
timeout /t 2 >nul
goto MainMenu

:CollectBySize
echo.
echo ┌─── SIZE FILTER OPTIONS ───┐
echo 1. Small files ^(under 1MB^)
echo 2. Medium files ^(1MB - 10MB^)
echo 3. Large files ^(over 10MB^)
echo 4. Custom size range
set /p "size_choice=Choose size filter [1-4]: "

set "min_size=0"
set "max_size=999999999"
if "%size_choice%"=="1" set "max_size=1048576"
if "%size_choice%"=="2" (
    set "min_size=1048576"
    set "max_size=10485760"
)
if "%size_choice%"=="3" set "min_size=10485760"
if "%size_choice%"=="4" (
    set /p "min_size=Enter minimum size in bytes: "
    set /p "max_size=Enter maximum size in bytes: "
)
goto CollectAllPhotos

:CollectAllPhotos
echo.
echo ┌─── TURBO PHOTO COLLECTION ───┐
echo Status: Initializing turbo scan system...

call :CreateDestination
del "%log_file%" 2>nul

echo Status: Launching parallel scan engines...
echo.

set "file_count=0"
set "duplicate_count=0"
set "error_count=0"
set "scan_count=0"
set "start_time=%time%"

call :TurboScanAllDrives

goto ShowResults

:TurboScanAllDrives
set "master_list=%temp%\master_photo_list.txt"
del "%master_list%" 2>nul

echo [TURBO] Building master file index...
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist %%D:\ (
        title Photo Collector - Turbo Scanning %%D:\
        call :PowerShellScan "%%D"
    )
)

if not exist "%master_list%" (
    echo No photo files found on any drive.
    exit /b
)

echo [TURBO] Processing master index...
call :ProcessMasterList

del "%master_list%" 2>nul
exit /b

:PowerShellScan
set "drive=%~1"
echo Scanning %drive%:\ with PowerShell engine...

powershell -Command "& {$extensions = @('%supported_extensions: =','%'.Split(',') | ForEach-Object {if($_){'*.' + $_}}); $excluded = @('%excluded_folders: =','%'.Split(',')); Get-ChildItem -Path '%drive%:\' -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.Extension.TrimStart('.') -in @('%supported_extensions: =','%'.Split(',')) -and !($excluded | Where-Object {$_.Trim() -and $_.Trim() -ne '' -and $_.FullName -like ('*\' + $_.Trim() + '\*')})} | Select-Object -ExpandProperty FullName}" >> "%master_list%" 2>nul
exit /b

:ProcessMasterList
set "batch_size=0"
for /f "usebackq delims=" %%F in ("%master_list%") do (
    set /a scan_count+=1
    set /a batch_size+=1
    
    if !batch_size! geq 50 (
        set "batch_size=0"
        call :UpdateProgress
    )
    
    call :ProcessFile "%%F"
)
exit /b

:UpdateProgress
title Photo Collector - Found: !file_count! ^| Duplicates: !duplicate_count! ^| Scanned: !scan_count! ^| Errors: !error_count!
call :DrawProgressBar
exit /b

:DrawProgressBar
set /a progress_percent=!scan_count! * 100 / 10000
if !progress_percent! gtr 100 set progress_percent=100
set /a bars=!progress_percent! / 4
set "progress_bar="
for /l %%i in (1,1,%bars%) do set "progress_bar=!progress_bar!█"
for /l %%i in (%bars%,1,24) do set "progress_bar=!progress_bar!░"
echo [!progress_bar!] !progress_percent!%% ^| Files: !scan_count!
exit /b

:ProcessFile
set "filepath=%~1"
if not exist "%filepath%" (
    echo ERROR: File not found - %filepath% >> "%log_file%"
    set /a error_count+=1
    exit /b
)

for %%I in ("%filepath%") do (
    set "filesize=%%~zI"
    set "filename=%%~nxI"
    set "fileext=%%~xI"
)

if defined min_size if !filesize! lss !min_size! exit /b
if defined max_size if !filesize! gtr !max_size! exit /b

set "counter=1"
set "base_name=%filename:~0,-4%"
set "final_name=%filename%"

:CheckDuplicate
if exist "%destination%\!final_name!" (
    set /a duplicate_count+=1
    set "final_name=%base_name%_(!counter!)%fileext%"
    set /a counter+=1
    goto CheckDuplicate
)

copy "%filepath%" "%destination%\!final_name!" >nul 2>&1
if !errorlevel! equ 0 (
    set /a file_count+=1
    set /a total_size+=!filesize!
) else (
    echo ERROR: Copy failed - %filepath% to %destination%\!final_name! >> "%log_file%"
    set /a error_count+=1
)
exit /b

:CollectPicturesOnly
echo.
echo ┌─── PICTURES FOLDER COLLECTION ───┐

if not exist "%USERPROFILE%\Pictures" (
    echo Error: Pictures folder not found.
    pause
    goto MainMenu
)

call :CreateDestination
del "%log_file%" 2>nul

set "file_count=0"
set "duplicate_count=0"
set "scan_count=0"

echo Using PowerShell acceleration for Pictures folder...
powershell -Command "& {$extensions = @('%supported_extensions: =','%'.Split(',') | ForEach-Object {if($_){'*.' + $_}}); Get-ChildItem -Path '%USERPROFILE%\Pictures' -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.Extension.TrimStart('.') -in @('%supported_extensions: =','%'.Split(','))} | Select-Object -ExpandProperty FullName}" > "%temp%\pictures_list.txt" 2>nul

if exist "%temp%\pictures_list.txt" (
    for /f "usebackq delims=" %%F in ("%temp%\pictures_list.txt") do (
        set /a scan_count+=1
        if !scan_count! geq 25 (
            set "scan_count=0"
            title Photo Collector - Pictures: !file_count! files processed
        )
        call :ProcessFile "%%F"
    )
    del "%temp%\pictures_list.txt" 2>nul
)

goto ShowResults

:CollectVideosOnly
echo.
echo ┌─── VIDEOS FOLDER COLLECTION ───┐

if not exist "%USERPROFILE%\Videos" (
    echo Error: Videos folder not found.
    pause
    goto MainMenu
)

call :CreateDestination
del "%log_file%" 2>nul

set "file_count=0"
set "duplicate_count=0"
set "scan_count=0"

echo Using PowerShell acceleration for Videos folder...
powershell -Command "& {$extensions = @('%supported_extensions: =','%'.Split(',') | ForEach-Object {if($_){'*.' + $_}}); Get-ChildItem -Path '%USERPROFILE%\Videos' -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.Extension.TrimStart('.') -in @('%supported_extensions: =','%'.Split(','))} | Select-Object -ExpandProperty FullName}" > "%temp%\pictures_list.txt" 2>nul

if exist "%temp%\videos_list.txt" (
    for /f "usebackq delims=" %%F in ("%temp%\videos_list.txt") do (
        set /a scan_count+=1
        if !scan_count! geq 25 (
            set "scan_count=0"
            title Photo Collector - Videos: !file_count! files processed
        )
        call :ProcessFile "%%F"
    )
    del "%temp%\videos_list.txt" 2>nul
)

goto ShowResults

:ShowResults
call :CalculateTime
title Photo Collector - Complete!
cls
echo.
echo ┌─── COLLECTION COMPLETE ───┐
echo.
echo ████████████████████████████ 100%
echo.
echo ┌─── FINAL STATISTICS ───┐
echo │ Photos collected: !file_count!
echo │ Duplicates handled: !duplicate_count!
echo │ Errors encountered: !error_count!
echo │ Total scanned: !scan_count!
if defined total_size (
    set /a size_mb=!total_size!/1048576
    echo │ Total size: !size_mb! MB
)
if defined elapsed_time echo │ Time elapsed: !elapsed_time!
echo └─────────────────────────┘
echo.
if !file_count! equ 0 (
    echo No images found or accessible.
) else (
    echo SUCCESS: !file_count! photos safely collected!
    echo Location: %destination%
)
if !error_count! gtr 0 (
    echo.
    echo ⚠️  !error_count! errors occurred. Type 6 in main menu to view error log.
)
echo.
set /p "open_folder=Open destination folder? [Y/N]: "
if /i "%open_folder%"=="Y" (
    if exist "%destination%" explorer "%destination%"
)
echo.
pause
goto MainMenu

:CalculateTime
if defined start_time (
    for /f "tokens=1-4 delims=:.," %%a in ("!start_time!") do (
        set /a start_seconds=%%a*3600+%%b*60+%%c
    )
    for /f "tokens=1-4 delims=:.," %%a in ("!time!") do (
        set /a end_seconds=%%a*3600+%%b*60+%%c
    )
    set /a elapsed=!end_seconds!-!start_seconds!
    if !elapsed! lss 0 set /a elapsed=!elapsed!+86400
    set /a minutes=!elapsed!/60
    set /a seconds=!elapsed!%%60
    set "elapsed_time=!minutes!m !seconds!s"
)
exit /b

:CreateDestination
call :ColorEcho "96" "Creating destination: %destination%"

if not exist "%destination%" (
    mkdir "%destination%" 2>nul
    if !errorlevel! equ 0 (
        call :ColorEcho "92" "✓ Destination folder created successfully"
    ) else (
        call :ColorEcho "91" "✗ Cannot create destination folder - using fallback"
        set "destination=%USERPROFILE%\Downloads\Collected Photos"
        mkdir "%destination%" 2>nul
        if !errorlevel! equ 0 (
            call :ColorEcho "92" "✓ Fallback folder created: !destination!"
        ) else (
            call :ColorEcho "91" "✗ Critical error: Cannot create any destination folder"
            pause
            goto MainMenu
        )
    )
) else (
    call :ColorEcho "92" "✓ Destination folder already exists"
)

if not exist "%destination%\Collected Photos" (
    mkdir "%destination%\Collected Photos" 2>nul
    if !errorlevel! equ 0 (
        set "destination=%destination%\Collected Photos"
        call :ColorEcho "92" "✓ Created 'Collected Photos' subfolder"
    )
) else (
    set "destination=%destination%\Collected Photos"
    call :ColorEcho "92" "✓ Using existing 'Collected Photos' subfolder"
)

timeout /t 1 >nul
exit /b

:ColorEcho
echo %~2
exit /b

:LogError
echo [%date% %time%] ERROR: %~1 - %~2 >> "%log_file%"
exit /b

