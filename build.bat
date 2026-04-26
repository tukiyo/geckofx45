@echo off
setlocal
set EXE_NAME=Program.exe
set STOP_FILE=stop.data
set LIB_DIR=lib
set RUNTIME_DIR=%LIB_DIR%\Runtime
set ZIP_NAME=Runtime.zip

echo ========================================
echo 1. 既存プロセスの停止
echo ========================================
REM 停止命令をファイルで送り、少し待ってから強制終了
echo stop > "%STOP_FILE%"
timeout /t 2 /nobreak > nul
taskkill /IM "%EXE_NAME%" /F >nul 2>&1
if exist "%STOP_FILE%" del "%STOP_FILE%"

echo.
echo ========================================
echo 2. Runtimeフォルダの準備
echo ========================================

REM lib\Runtime フォルダが存在するかどうかだけで判定
if exist "%RUNTIME_DIR%\" (
    echo [INFO] %RUNTIME_DIR% フォルダが既に存在するため、結合と解凍をスキップします。
) else (
    REM libフォルダ内の分割ファイルを結合
    if exist "%LIB_DIR%\Runtime.001" (
        echo [INFO] %LIB_DIR% 内の分割ファイルを結合中...
        copy /b "%LIB_DIR%\Runtime.001" + "%LIB_DIR%\Runtime.002" "%ZIP_NAME%" > nul
    )

    REM ZIPの解凍
    if exist "%ZIP_NAME%" (
        echo [INFO] %ZIP_NAME% を %LIB_DIR% 内に展開しています...
        powershell -NoProfile -Command "Expand-Archive -Path '.\%ZIP_NAME%' -DestinationPath '.\%LIB_DIR%' -Force"
        echo [INFO] 展開完了。
        
        REM 展開が終わったらルートに作成された一時ZIPは削除
        del "%ZIP_NAME%"
    ) else (
        echo [ERROR] %RUNTIME_DIR% が見つからず、分割ファイルも存在しません。
    )
)

echo.
echo ========================================
echo 3. ビルド実行 (csc.exe)
echo ========================================
REM C# 5.0相当のコンパイラパスを指定
set CSC_PATH=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe

if not exist "%CSC_PATH%" (
    echo [ERROR] csc.exe が見つかりません。
    pause
    exit /b 1
)

REM libフォルダ内のDLLを参照してビルド
"%CSC_PATH%" /nologo /target:winexe /platform:x64 /out:%EXE_NAME% /reference:"%LIB_DIR%\Geckofx-Core.dll" /reference:"%LIB_DIR%\Geckofx-Winforms.dll" Program.cs

if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] ビルドが正常に完了しました: %EXE_NAME%
    REM startコマンドで別プロセスとして起動し、このバッチを終了する
    start "" "%EXE_NAME%"
    exit
) else (
    echo [ERROR] ビルドに失敗しました。
    pause
)