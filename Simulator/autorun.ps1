param(
    [int]$Runs    = 5,
    [int]$Warmup  = 8,
    [int]$Reset   = 3
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$AlgoExe    = "$PSScriptRoot\Algo.exe"
$BotJavaDir = Resolve-Path "$PSScriptRoot\..\Bot_Java"
$OutDir     = "Build\Release"

# 사전 확인
if (-not (Test-Path $AlgoExe)) {
    Write-Error "Algo.exe not found: $AlgoExe"
    exit 1
}

# java.exe / javac.exe 탐색 (PATH → JAVA_HOME → 일반 설치 경로 순)
$JavaExe = "java"
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    $candidates = @(
        "$env:JAVA_HOME\bin\java.exe",
        "C:\Program Files\Java\jdk*\bin\java.exe",
        "C:\Program Files\Eclipse Adoptium\*\bin\java.exe",
        "C:\Program Files\Microsoft\jdk*\bin\java.exe",
        "C:\Program Files\JetBrains\*\jbr\bin\java.exe"
    )
    $found = $null
    foreach ($pattern in $candidates) {
        $found = Get-Item $pattern -ErrorAction SilentlyContinue | Select-Object -Last 1
        if ($found) { $JavaExe = $found.FullName; break }
    }
    if (-not $found) {
        Write-Error "java.exe를 찾을 수 없습니다. JAVA_HOME 환경변수를 설정하거나 Java를 PATH에 추가하세요."
        exit 1
    }
}
$JavacExe = if ($JavaExe -eq "java") { "javac" } else { Join-Path (Split-Path $JavaExe) "javac.exe" }
Write-Host "Using java : $JavaExe"
Write-Host "Using javac: $JavacExe"

# 빌드
Write-Host "Building MyCar..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$BotJavaDir\$OutDir" -Force | Out-Null
$build = Start-Process -FilePath $JavacExe `
                       -ArgumentList "-encoding UTF-8 -cp . -d `"$OutDir`" MyCar.java DrivingInterface\DrivingInterface.java" `
                       -WorkingDirectory $BotJavaDir `
                       -NoNewWindow -Wait -PassThru
if ($build.ExitCode -ne 0) {
    Write-Error "빌드 실패 (exit code $($build.ExitCode)). MyCar.java 컴파일 오류를 확인하세요."
    exit 1
}
Write-Host "Build OK." -ForegroundColor Green

# Algo.exe 1회 시작
Write-Host "Starting Algo.exe..." -ForegroundColor Yellow
Stop-Process -Name "Algo" -Force -ErrorAction SilentlyContinue
$algo = Start-Process -FilePath $AlgoExe `
                      -ArgumentList "-ResX=640 -ResY=480 -windowed" `
                      -PassThru
Write-Host "Waiting ${Warmup}s for simulator to load..."
Start-Sleep -Seconds $Warmup

$wshell = New-Object -ComObject WScript.Shell

# 실행 루프 — Algo.exe 재시작 없이 Backspace 리셋만 사용
try {
    for ($i = 1; $i -le $Runs; $i++) {
        Write-Host "=== Run $i/$Runs ===" -ForegroundColor Cyan

        # MyCar 실행 (종료될 때까지 대기)
        $java = Start-Process -FilePath $JavaExe `
                              -ArgumentList "-cp `"$OutDir`" -Djava.library.path=DrivingInterface MyCar" `
                              -WorkingDirectory $BotJavaDir `
                              -NoNewWindow -Wait -PassThru
        Write-Host "Exit code: $($java.ExitCode)"
        if ($java.ExitCode -ne 0) {
            Write-Warning "Run $i ended with non-zero exit code: $($java.ExitCode)"
        }

        # 마지막 run이면 리셋 불필요
        if ($i -eq $Runs) { break }

        # Backspace로 시뮬레이터 리셋 (Algo.exe 재시작 없음)
        Write-Host "Resetting simulator..."
        $wshell.AppActivate($algo.Id) | Out-Null
        Start-Sleep -Milliseconds 300
        $wshell.SendKeys("{BACKSPACE}")
        Start-Sleep -Seconds $Reset
    }
} finally {
    Stop-Process -Name "Algo" -Force -ErrorAction SilentlyContinue
}

Write-Host "All $Runs runs complete." -ForegroundColor Green
